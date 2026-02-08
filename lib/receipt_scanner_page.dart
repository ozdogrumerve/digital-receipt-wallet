import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ReceiptScannerPage extends StatefulWidget {
  const ReceiptScannerPage({super.key});

  @override
  State<ReceiptScannerPage> createState() => _ReceiptScannerPageState();
}

class _ReceiptScannerPageState extends State<ReceiptScannerPage> {
  File? _imageFile;
  Map<String, String>? _totalItem;
  bool _isProcessing = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.camera);

    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path);
        _isProcessing = true;
        _totalItem = null;
      });
      await _processImage(File(pickedImage.path));
    }
  }

  Future<void> _processImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    final lines = recognizedText.text.split('\n');
    final targetKeywords = [
      'satış tutar',
      'satış',
      'tutar',
      'toplam',
      'ödenecek',
      'kdv dahil',
      'genel toplam',
      'ödeme tutarı',
    ];

    final amountRegex = RegExp(r'([\d]+[.,]\d{2})');

    Map<String, String>? foundItem;

    for (int i = 0; i < lines.length; i++) {
      final lowerLine = lines[i].toLowerCase();
      if (targetKeywords.any((keyword) => lowerLine.contains(keyword))) {
        // Aynı satırda rakam var mı?
        final matchSameLine = amountRegex.firstMatch(lines[i]);
        if (matchSameLine != null) {
          foundItem = {
            'label': lines[i],
            'amount': matchSameLine.group(1)!.trim(),
          };
          break;
        }
        // Alt satırda rakam var mı?
        if (i + 1 < lines.length) {
          final matchNextLine = amountRegex.firstMatch(lines[i + 1]);
          if (matchNextLine != null) {
            foundItem = {
              'label': lines[i],
              'amount': matchNextLine.group(1)!.trim(),
            };
            break;
          }
        }
      }
    }

    setState(() {
      _totalItem = foundItem;
      _isProcessing = false;
    });

    await textRecognizer.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fiş Tutar OCR')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Fotoğraf Çek"),
            ),
            const SizedBox(height: 16),
            if (_isProcessing) const CircularProgressIndicator(),
            if (_imageFile != null) ...[
              Image.file(_imageFile!),
              const SizedBox(height: 16),
            ],
            if (_totalItem != null)
              Card(
                elevation: 4,
                color: Colors.green.shade50,
                child: ListTile(
                  title: Text(
                    _totalItem!['label']!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Text(
                    '${_totalItem!['amount']} ₺',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              )
            else if (!_isProcessing)
              const Text('Toplam tutar bulunamadı.'),
          ],
        ),
      ),
    );
  }
}
