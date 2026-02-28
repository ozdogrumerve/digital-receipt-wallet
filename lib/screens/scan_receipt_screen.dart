import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/receipt_model.dart';
import '../services/firestore_service.dart';

class ScanReceiptScreen extends StatefulWidget {
  final List<ProductModel> detectedProducts;
  final String storeName;
  final String category;

  const ScanReceiptScreen({
    super.key,
    required this.detectedProducts,
    required this.storeName,
    required this.category,
  });

  @override
  State<ScanReceiptScreen> createState() =>
      _ScanReceiptScreenState();
}

class _ScanReceiptScreenState
    extends State<ScanReceiptScreen> {
  final FirestoreService _service = FirestoreService();

  double get total =>
      widget.detectedProducts.fold(
          0, (sum, p) => sum + p.total);

  String formatTL(double amount) =>
      "₺${amount.toStringAsFixed(2)}";

  Future<void> save() async {
    await _service.addTransaction(
      receipt: ReceiptModel(
        id: '',
        storeName: widget.storeName,
        storeNameLower: widget.storeName.toLowerCase(),
        totalAmount: total,
        date: DateTime.now(),
        category: widget.category,
        createdAt: DateTime.now(),
        source: 'scan',
      ),
      products: widget.detectedProducts, // List<ProductModel>
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Scan Receipt")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// IMAGE PLACEHOLDER
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text("Receipt Preview"),
                ),
              ),

              const SizedBox(height: 30),

              Text("Extraction Results",
                  style: theme.textTheme.titleMedium),

              const SizedBox(height: 20),

              Text("Store Name"),
              const SizedBox(height: 6),
              Text(widget.storeName),

              const SizedBox(height: 20),

              Text("Detected Products"),
              const SizedBox(height: 12),

              ...widget.detectedProducts.map((p) => Card(
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      title: Text(p.name),
                      subtitle:
                          Text("Qty: ${p.quantity}"),
                      trailing:
                          Text(formatTL(p.total)),
                    ),
                  )),

              const SizedBox(height: 20),

              Text(
                "Total: ${formatTL(total)}",
                style: theme.textTheme.headlineSmall,
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: save,
                child: const Text("Save Receipt"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}