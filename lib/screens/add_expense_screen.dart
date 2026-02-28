import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/receipt_model.dart';
import '../services/firestore_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final FirestoreService _service = FirestoreService();

  final TextEditingController storeController = TextEditingController();
  final TextEditingController productController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController qtyController =
      TextEditingController(text: "1");

  DateTime selectedDate = DateTime.now();
  String category = "General";

  final List<ProductModel> products = [];

  double get total =>
      products.fold(0, (sum, p) => sum + p.total);

  String formatTL(double amount) =>
      "₺${amount.toStringAsFixed(2)}";

  void addProduct() {
    final name = productController.text.trim();
    final price = double.tryParse(priceController.text) ?? 0;
    final qty = int.tryParse(qtyController.text) ?? 1;

    if (name.isEmpty) return;

    setState(() {
      products.add(ProductModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        price: price,
        quantity: qty,
      ));
    });

    productController.clear();
    priceController.clear();
    qtyController.text = "1";
  }

  Future<void> save() async {
  await _service.addTransaction(
    receipt: ReceiptModel(
      id: '',
      storeName: storeController.text,
      storeNameLower: storeController.text.toLowerCase(),
      totalAmount: total,
      date: selectedDate,
      category: category,
      createdAt: DateTime.now(),
      source: 'manual',
    ),
    products: products, // List<ProductModel>
  );

  if (!mounted) return;
  Navigator.pop(context);
}

  InputDecoration inputStyle(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F3FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: const Text(
          "Add Expense",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C7BCF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: save,
              child: const Text(
                "Save Transaction",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 10),

              /// TRANSACTION DETAILS
              Text(
                "TRANSACTION DETAILS",
                style: theme.textTheme.labelMedium!
                    .copyWith(color: Colors.grey),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: storeController,
                decoration: inputStyle(
                  "Store name",
                  icon: Icons.storefront_outlined,
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDate: selectedDate,
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.label_outline, size: 18),
                          const SizedBox(width: 10),
                          Text(category),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              /// ADD ITEM CARD
              Text(
                "ADD ITEM",
                style: theme.textTheme.labelMedium!
                    .copyWith(color: Colors.grey),
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: productController,
                      decoration:
                          inputStyle("What did you buy?"),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            decoration:
                                inputStyle("₺ 0.00"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: qtyController,
                            keyboardType: TextInputType.number,
                            decoration:
                                inputStyle("Qty"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFB89AD9),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: addProduct,
                        child: const Text("+ Add to List"),
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// PURCHASE LIST
              Text(
                "PURCHASE LIST (${products.length})",
                style: theme.textTheme.labelMedium!
                    .copyWith(color: Colors.grey),
              ),

              const SizedBox(height: 12),

              if (products.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      "No items added yet",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),

              ...products.map((p) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(
                                    fontWeight:
                                        FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${p.quantity} x ${formatTL(p.price)}",
                                style: TextStyle(
                                  color:
                                      Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatTL(p.total),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      ],
                    ),
                  )),

              const SizedBox(height: 20),

              if (products.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE7F6),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Amount",
                        style: TextStyle(
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        formatTL(total),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}