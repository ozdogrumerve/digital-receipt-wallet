import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../models/receipt_model.dart';
import '../services/firestore_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:digital_receipt_wallet/l10n/app_localizations.dart';

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
  bool _scanSuccessful = false;
  bool _isCategoryFromAI = false;

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
    _category = _category = categories.contains(widget.category)
    ? widget.category
    : "Food";

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

  DateTime? parseReceiptDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return null;

    try {
      String cleaned = rawDate.trim();

      // tüm ayraçları noktaya çevir
      cleaned = cleaned.replaceAll("/", ".");
      cleaned = cleaned.replaceAll("-", ".");

      final parts = cleaned.split(".");

      if (parts.length != 3) return null;

      int day;
      int month;
      int year;

      // yyyy.mm.dd formatı gelirse
      if (parts[0].length == 4) {
        year = int.parse(parts[0]);
        month = int.parse(parts[1]);
        day = int.parse(parts[2]);
      } else {
        // dd.mm.yyyy
        day = int.parse(parts[0]);
        month = int.parse(parts[1]);
        year = int.parse(parts[2]);
      }

      return DateTime(year, month, day);

    } catch (_) {
      return null;
    }
  }

  Future<void> _scanReceipt(File imageFile) async {
    final loc = AppLocalizations.of(context)!;

    try {

      final bytes = await imageFile.readAsBytes();
      final base64Data = base64Encode(bytes);

      const prompt = """Bu fiş fotoğrafından SADECE alışveriş ürünleri ve fiyatlarını çıkar. 

        Ek olarak:
        - Bu alışverişi en uygun kategoriye ata.
        - Kategori şu listeden biri olmalı:
        Food, Clothing, Tech, Transportation, Bills, Rent, Education, Healthcare, 
        Personal Care, Entertainment, Household / Furniture, Stationery, Vacation / Travel, 
        Taxes / Official Payments, Other

        Market adı, adres, tarih, ödeme türü gibi bilgileri ürün olarak alma! 
        Sadece şu yapıda temiz JSON dön, başka hiçbir metin yazma:
        {
          "market": "market adı (varsa)",
          "tarih": "gg.aa.yyyy (varsa)",
          "toplam": sayı,
          "kategori": "kategori adı",
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

      if (!cleaned.trim().startsWith("{")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.invalidReceiptScan),
          ),
        );
        return;
      }

      final data = jsonDecode(cleaned);

      final market = data["market"] ?? "";
      final total = (data["toplam"] ?? 0).toDouble();
      final dateString = data["tarih"];
      final categoryFromAI = data["kategori"];

      final parsedDate = parseReceiptDate(dateString);

      final List productsJson = (data["urunler"] as List?) ?? [];

      final scannedProducts = productsJson.map((e) {
        return ProductModel(
          id: '',
          name: e["urun"],
          price: (e["fiyat"] ?? 0).toDouble(),
          quantity: int.tryParse(e["miktar"]?.toString() ?? "1") ?? 1,
        );
      }).toList();

      if (scannedProducts.isEmpty || total <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.thisDoesntLookLikeAReceipt),
          ),
        );
        return;
      }

      setState(() {
        _products = scannedProducts;

        if (market.isNotEmpty) {
          _storeController.text = market;
        }

        if (parsedDate != null) {
          _selectedDate = parsedDate;
        }

        if (categoryFromAI != null && categories.contains(categoryFromAI)) {
          _category = categoryFromAI;
          _isCategoryFromAI = true;
        }

        _totalController.text = total.toStringAsFixed(2);

        _scanSuccessful = true;
      });

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$loc.scanError: $e")),
      );

    }

  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context)!;
    if (!_scanSuccessful) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.pleaseScanReceiptFirst),
        ),
      );
      return;
    }

    if (_storeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.storeNameCannotBeEmpty)),
      );
      return;
    }

    final totalAmount = double.tryParse(_totalController.text) ?? 0;

    if (totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.totalMustBeGreaterThanZero)),
      );
      return;
    }

    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.addAtLeastOneProduct)),
      );
      return;
    }

    await _service.addTransaction(
      receipt: ReceiptModel(
        id: '',
        storeName: _storeController.text,
        storeNameLower: _storeController.text.toLowerCase(),
        totalAmount: double.tryParse(_totalController.text) ?? 0,
        date: DateTime(
          _selectedDate.year, _selectedDate.month, _selectedDate.day,
          DateTime.now().hour, DateTime.now().minute, DateTime.now().second,
        ),
        category: _category,
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
        final loc = AppLocalizations.of(context)!;
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
                    product == null ? loc.addItemManually : loc.editItem,
                    style: theme.textTheme.titleMedium,
                  ),

                  const SizedBox(height: 20),

                  input(
                    icon: Icons.inventory_2_outlined,
                    hint: loc.productName,
                    controller: nameController,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return loc.nameRequired;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  input(
                    icon: Icons.attach_money,
                    hint: loc.price,
                    controller: priceController,
                    type: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final price = double.tryParse(v ?? "") ?? 0;
                      if (price <= 0) {
                        return loc.priceMustBeGreaterThanZero;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  input(
                    icon: Icons.format_list_numbered,
                    hint: loc.quantity,
                    controller: qtyController,
                    type: TextInputType.number,
                    validator: (v) {
                      final qty = int.tryParse(v ?? "") ?? 0;
                      if (qty <= 0) {
                        return loc.qtyMustBeGreaterThanZero;
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
                      label: Text(product == null ? loc.add : loc.save),
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
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(loc.scanReceipt)),
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
                            ? Center(child: Text(loc.noImageCaptured))
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
                      label: Text(_image == null ? loc.takePhoto : loc.retake),
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
                  loc.extractionResults,
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
                    _isEditing ? loc.done : loc.edit ,
                  ),
                )
              ],
            ),

            const SizedBox(height: 20),

            /// STORE NAME
            inputBox(
              context: context,
              label: loc.storeName,
              icon: Icons.store,
              child: TextField(
                controller: _storeController,
                enabled: _isEditing,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: loc.storeNameHint,
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
                    label: loc.date,
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
                      label: loc.totalAmount,
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
              label: loc.category,
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
                          _isCategoryFromAI = false;
                        });
                      }
                    : null,
              ),
            ),
            if (_isCategoryFromAI)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  loc.aiSuggested,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const SizedBox(height: 30),

            /// PRODUCTS
            Text(loc.detectedProducts, style: theme.textTheme.titleMedium),

            const SizedBox(height: 4),

            Text(
              loc.tapToEditSwipeToDelete,
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
                  ? Center(
                      child: Text(
                        loc.noProductsDetected,
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
                          child: Icon(Icons.delete, color: theme.colorScheme.onSurface),
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
                              color: theme.colorScheme.surface,
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
                                        "${loc.quantity}: ${p.quantity}",
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
                child: Text(loc.addItemManually),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: Icon(Icons.save),
                label: Text(loc.saveReceipt),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
