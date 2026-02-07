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
  List<Map<String, String>> _items = [];
  bool _isProcessing = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.camera);

    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path);
        _isProcessing = true;
        _items.clear();
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

    final List<Map<String, String>> parsedItems = [];

    final regex = RegExp(r'(.+?)\s+([\d]+[.,]\d{2})');

    for (final line in lines) {
      final match = regex.firstMatch(line);
      if (match != null) {
        parsedItems.add({
          'name': match.group(1)!.trim(),
          'price': match.group(2)!.trim(),
        });
      }
    }

    setState(() {
      _items = parsedItems;
      _isProcessing = false;
    });

    await textRecognizer.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fiş OCR Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Fotoğraf Çek"),
            ),
            if (_isProcessing) const CircularProgressIndicator(),
            if (_imageFile != null) Image.file(_imageFile!),
            const SizedBox(height: 16),
            Expanded(
              child: _items.isEmpty
                  ? const Text('Hiçbir ürün algılanmadı.')
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return ListTile(
                          title: Text(item['name']!),
                          trailing: Text('${item['price']} ₺'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
