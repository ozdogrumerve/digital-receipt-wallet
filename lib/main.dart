import 'package:flutter/material.dart';
import 'receipt_scanner_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fiş OCR Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ReceiptScannerPage(),
    );
  }
}
