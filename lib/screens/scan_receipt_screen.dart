import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../models/receipt_model.dart';
import '../services/firestore_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  final FirestoreService _service = FirestoreService();
  final ImagePicker _picker = ImagePicker();

  File? _image;

  late TextEditingController _storeController;
  late TextEditingController _totalController;

  DateTime _selectedDate = DateTime.now();
  late String _category;
  late List<ProductModel> _products;

  bool _isEditing = false;

  final formKey = GlobalKey<FormState>();

  final List<String> categories = [
    "Food",
    "Clothing",
    "Tech",
    "Transportation",
    "Bills",
    "Rent",
    "Education",
    "Healthcare",
    "Personal Care",
    "Entertainment",
    "Household / Furniture",
    "Stationery",
    "Vacation / Travel",
    "Taxes / Official Payments",
    "Other"
  ];

  @override
  void initState() {
    super.initState();

    _products = List.from(widget.detectedProducts);
    _category = widget.category;

    _storeController = TextEditingController();

    _totalController = TextEditingController(text: total.toStringAsFixed(2));
  }

  double get total => _products.fold(0, (sum, p) => sum + p.total);

  String formatTL(double amount) => "₺${amount.toStringAsFixed(2)}";

  Future<void> _pickImage() async {

    final picked = await _picker.pickImage(source: ImageSource.camera);

    if (picked == null) return;

    final imageFile = File(picked.path);

    setState(() {
      _image = imageFile;
    });

    await _scanReceipt(imageFile);

  }

  Future<void> _scanReceipt(File imageFile) async {

    try {

      final bytes = await imageFile.readAsBytes();
      final base64Data = base64Encode(bytes);

      const prompt = """Bu fiş fotoğrafından SADECE alışveriş ürünleri ve fiyatlarını çıkar. Market adı, adres, tarih, ödeme türü gibi bilgileri ürün olarak alma! Sadece şu yapıda temiz JSON dön, başka hiçbir metin yazma:
  {
    "market": "market adı (varsa)",
    "tarih": "gg.aa.yyyy (varsa)",
    "toplam": sayı,
    "urunler": [
      {"urun": "ürün ismi", "fiyat": sayı, "miktar": "miktar varsa"},
      ...
    ]
  }
  Fiyatlar her zaman sayı olsun (virgül nokta olarak), ürün isimleri tam ve doğru olsun. Adres, kasiyer adı, fiş numarası vb. ürün olarak ekleme!""";

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${dotenv.env['GROQ_API_KEY']}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "meta-llama/llama-4-scout-17b-16e-instruct",
          "messages": [
            {
              "role": "user",
              "content": [
                {"type": "text", "text": prompt},
                {
                  "type": "image_url",
                  "image_url": {"url": "data:image/jpeg;base64,$base64Data"}
                }
              ]
            }
          ],
          "temperature": 0.1,
          "max_tokens": 1024,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("API Error ${response.statusCode}");
      }

      final decoded = jsonDecode(response.body);
      final content = decoded['choices'][0]['message']['content'];
      final cleaned = content
        .replaceAll("```json", "")
        .replaceAll("```", "")
        .trim();

      final data = jsonDecode(cleaned);

      final market = data["market"] ?? "";
      final total = (data["toplam"] ?? 0).toDouble();

      final List productsJson = data["urunler"];

      final scannedProducts = productsJson.map((e) {
        return ProductModel(
          id: '',
          name: e["urun"],
          price: (e["fiyat"] ?? 0).toDouble(),
          quantity: int.tryParse(e["miktar"]?.toString() ?? "1") ?? 1,
        );
      }).toList();

      setState(() {

        _products = scannedProducts;

        if (market.isNotEmpty) {
          _storeController.text = market;
        }

        _totalController.text = total.toStringAsFixed(2);

      });

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Scan error: $e")),
      );

    }

  }

  Future<void> _save() async {
    if (_storeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Store name cannot be empty")),
      );
      return;
    }

    final totalAmount = double.tryParse(_totalController.text) ?? 0;

    if (totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Total amount must be greater than 0")),
      );
      return;
    }

    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Add at least one product")),
      );
      return;
    }

    await _service.addTransaction(
      receipt: ReceiptModel(
        id: '',
        storeName: _storeController.text,
        storeNameLower: _storeController.text.toLowerCase(),
        totalAmount: double.tryParse(_totalController.text) ?? 0,
        date: _selectedDate,
        category: _category.toLowerCase(),
        createdAt: DateTime.now(),
        source: 'scan',
      ),
      products: _products,
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  void _addManualProduct({ProductModel? product, int? index}) {
    final theme = Theme.of(context);

    final nameController = TextEditingController(text: product?.name ?? "");
    final priceController = TextEditingController(
      text: product != null ? product.price.toString() : "",
    );
    final qtyController = TextEditingController(
      text: product != null ? product.quantity.toString() : "1",
    );

    Widget input({
      required IconData icon,
      required String hint,
      required TextEditingController controller,
      TextInputType? type, 
      String? Function(String?)? validator,
    }) {
      return Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                validator: validator,
                controller: controller,
                keyboardType: type,
                decoration: InputDecoration(
                  hintText: hint,
                  border: InputBorder.none,
                ),
              ),
            )
          ],
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
                children: [
                  /// handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  Text(
                    product == null ? "Add Item Manually" : "Edit Item",
                    style: theme.textTheme.titleMedium,
                  ),

                  const SizedBox(height: 20),

                  input(
                    icon: Icons.inventory_2_outlined,
                    hint: "Product name",
                    controller: nameController,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Name required";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  input(
                    icon: Icons.attach_money,
                    hint: "Price",
                    controller: priceController,
                    type: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final price = double.tryParse(v ?? "") ?? 0;
                      if (price <= 0) {
                        return "Price must be > 0";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  input(
                    icon: Icons.format_list_numbered,
                    hint: "Quantity",
                    controller: qtyController,
                    type: TextInputType.number,
                    validator: (v) {
                      final qty = int.tryParse(v ?? "") ?? 0;
                      if (qty <= 0) {
                        return "Qty must be > 0";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: 120,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {

                        if (!formKey.currentState!.validate()) {
                           return;
                        }
                      
                        final price = double.tryParse(priceController.text) ?? 0;
                        final qty = int.tryParse(qtyController.text) ?? 0;

                        setState(() {
                          if (product == null) {
                            _products.add(
                              ProductModel(
                                id: '',
                                name: nameController.text,
                                price: price,
                                quantity: qty,
                              ),
                            );
                          } else {
                            _products[index!] = ProductModel(
                              id: product.id,
                              name: nameController.text,
                              price: price,
                              quantity: qty,
                            );
                          }

                          _totalController.text = total.toStringAsFixed(2);
                        });

                        Navigator.pop(context);
                      },
                      icon: product == null ? Icon(Icons.add) : Icon(Icons.save),
                      label: Text(product == null ? "Add" : "Save"),
                    ),
                  ),

                  const SizedBox(height: 10)
                ],
            )
          ),
        );
      },
    );
  }

  Widget inputBox({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.labelSmall!
                .copyWith(color: theme.colorScheme.onSurface.withAlpha(0x99))),
        const SizedBox(height: 6),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 10),
              Expanded(child: child),
            ],
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Scan Receipt")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// RECEIPT PREVIEW
            SizedBox(
              height: 230,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        color: theme.colorScheme.surface,
                        child: _image == null
                            ? const Center(child: Text("No Image Captured"))
                            : Image.file(
                                _image!,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 14,
                    left: 14,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _pickImage,
                      icon: _image == null
                          ? Icon(Icons.camera_alt)
                          : Icon(Icons.refresh),
                      label: Text(_image == null ? "Take Photo" : "Retake"),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Extraction Results",
                  style: theme.textTheme.titleMedium,
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isEditing = !_isEditing;
                    });
                  },
                  icon: _isEditing ? Icon(Icons.check) : Icon(Icons.edit),
                  label: Text(
                    _isEditing ? "Done" : "Edit",
                  ),
                )
              ],
            ),

            const SizedBox(height: 20),

            /// STORE NAME
            inputBox(
              context: context,
              label: "Store Name",
              icon: Icons.store,
              child: TextField(
                controller: _storeController,
                enabled: _isEditing,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Whole Foods Market",
                ),
              ),
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                /// DATE
                Expanded(
                  child: inputBox(
                    context: context,
                    label: "Date",
                    icon: Icons.calendar_today,
                    child: InkWell(
                      onTap: _isEditing
                          ? () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );

                              if (picked != null) {
                                setState(() {
                                  _selectedDate = picked;
                                });
                              }
                            }
                          : null,
                      child: Text(
                        "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                        style: TextStyle(
                          color: _isEditing
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withAlpha(0x99),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                /// TOTAL
                Expanded(
                  child: inputBox(
                      context: context,
                      label: "Total Amount",
                      icon: Icons.attach_money,
                      child: TextField(
                        controller: _totalController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "0.00",
                        ),
                      )),
                )
              ],
            ),

            const SizedBox(height: 18),

            /// CATEGORY
            inputBox(
              context: context,
              label: "Category",
              icon: Icons.sell_outlined,
              child: DropdownButton<String>(
                value: categories.contains(_category)
                    ? _category
                    : categories.first,
                isExpanded: true,
                underline: const SizedBox(),
                items: categories
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ),
                    )
                    .toList(),
                onChanged: _isEditing
                    ? (v) {
                        setState(() {
                          _category = v!;
                        });
                      }
                    : null,
              ),
            ),

            const SizedBox(height: 30),

            /// PRODUCTS
            Text("Detected Products", style: theme.textTheme.titleMedium),

            const SizedBox(height: 4),

            Text(
              "Tap item to edit • Swipe left to delete",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.surface,
              ),
              child: _products.isEmpty
                  ? const Center(
                      child: Text(
                        "No products detected",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(10),
                    itemCount: _products.length,
                    itemBuilder: (_, i) {
                      final p = _products[i];
                      return Dismissible(
                        key: UniqueKey(),
                        direction: DismissDirection.endToStart,

                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),

                        onDismissed: (_) {
                          setState(() {
                            _products.removeAt(i);
                            _totalController.text = total.toStringAsFixed(2);
                          });
                        },

                        child: GestureDetector(
                          onTap: () {
                            _addManualProduct(
                              product: p,
                              index: i,
                            );
                          },

                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(0xEE),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [

                                      Text(
                                        p.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      Text(
                                        "Qty: ${p.quantity}",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),

                                    ],
                                  ),
                                ),

                                Text(
                                  "₺${p.total.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                )

                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  )
            ),
            const SizedBox(height: 12),

            Center(
              child: TextButton(
                onPressed: _addManualProduct,
                child: const Text("+ Add Item Manually"),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: Icon(Icons.save),
                label: const Text("Save Receipt"),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
