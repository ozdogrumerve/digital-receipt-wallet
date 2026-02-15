import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:path_provider/path_provider.dart';

class ReceiptScannerPage extends StatefulWidget {
  const ReceiptScannerPage({super.key});

  @override
  State<ReceiptScannerPage> createState() => _ReceiptScannerPageState();
}

class _ReceiptScannerPageState extends State<ReceiptScannerPage> {
  File? _originalImage;
  File? _enhancedImage;
  Map<String, String>? _totalItem;
  bool _isProcessing = false;

  final List<String> targetKeywords = [
    'satış tutar',
    'satış',
    'tutar',
    'toplam',
    'ödenecek',
    'kdv dahil',
    'genel toplam',
    'ödeme tutarı',
  ];

  final RegExp amountRegex = RegExp(r'([\d]+[.,]\d{2})');

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.camera);

    if (pickedImage == null) return;

    setState(() {
      _isProcessing = true;
      _originalImage = File(pickedImage.path);
      _enhancedImage = null;
      _totalItem = null;
    });

    try {
      // 1️⃣ Orijinal OCR
      final originalResult = await _processImage(_originalImage!);

      // 2️⃣ İyileştir
      final enhanced = await _enhanceImage(_originalImage!);

      // Enhanced her zaman set edilir
      setState(() {
        _enhancedImage = enhanced;
      });

      // 3️⃣ Enhanced OCR
      final enhancedResult = await _processImage(enhanced);

      setState(() {
        _totalItem = enhancedResult ?? originalResult;
      });
    } catch (e) {
      debugPrint("PROCESS ERROR: $e");
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<File> _enhanceImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();

    // Decode
    cv.Mat image = cv.imdecode(bytes, cv.IMREAD_COLOR);

    // Resize
    cv.Mat resized = cv.resize(image, (800, 1200));

    // Gray
    cv.Mat gray = cv.cvtColor(resized, cv.COLOR_BGR2GRAY);

    // CLAHE (adaptive contrast)
    final clahe = cv.createCLAHE(clipLimit: 2.0, tileGridSize: (8, 8));
    cv.Mat contrasted = clahe.apply(gray);

    // Blur (sharpen için)
    cv.Mat blurred = cv.gaussianBlur(contrasted, (0, 0), 3);

    // Sharpen using addWeighted
    cv.Mat sharpened = cv.addWeighted(
      contrasted,
      1.5,
      blurred,
      -0.5,
      0,
    );

    final encoded = cv.imencode('.jpg', sharpened);
    Uint8List enhancedBytes = encoded.$2;

    final tempDir = await getTemporaryDirectory();
    final enhancedPath =
        '${tempDir.path}/enhanced_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final enhancedFile = File(enhancedPath);
    await enhancedFile.writeAsBytes(enhancedBytes);

    return enhancedFile;
  }

  Future<Map<String, String>?> _processImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);

      final recognizedText =
          await textRecognizer.processImage(inputImage).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw Exception("OCR Timeout");
        },
      );

      final lines = recognizedText.text.split('\n');

      Map<String, String>? foundItem;

      for (int i = 0; i < lines.length; i++) {
        final lowerLine = lines[i].toLowerCase();

        if (targetKeywords.any((keyword) => lowerLine.contains(keyword))) {
          final matchSameLine = amountRegex.firstMatch(lines[i]);

          if (matchSameLine != null) {
            foundItem = {
              'label': lines[i],
              'amount': matchSameLine.group(1)!.trim(),
            };
            break;
          }

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

      await textRecognizer.close();
      return foundItem;
    } catch (e) {
      debugPrint("OCR ERROR: $e");
      return null;
    }
  }

  Widget _buildImagePreview(String title, File file) {
    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Image.file(file, fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fiş OCR + Görüntü İyileştirme')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _pickImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Fotoğraf Çek"),
            ),
            const SizedBox(height: 16),
            if (_isProcessing) const CircularProgressIndicator(),
            const SizedBox(height: 16),
            if (_originalImage != null)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text("Orijinal"),
                        const SizedBox(height: 8),
                        Image.file(_originalImage!, fit: BoxFit.cover),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: [
                        const Text("İyileştirilmiş"),
                        const SizedBox(height: 8),
                        _enhancedImage != null
                            ? Image.file(_enhancedImage!, fit: BoxFit.cover)
                            : const Text("Henüz oluşturulmadı"),
                      ],
                    ),
                  ),
                ],
              ),
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
                      fontSize: 22,
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
