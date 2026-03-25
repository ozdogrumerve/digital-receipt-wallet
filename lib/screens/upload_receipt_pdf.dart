import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../models/receipt_model.dart';
import '../services/firestore_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart'; // PDF'i image'e çevirmek için: pub add pdfx (sayfaları render et)

class UploadReceiptPdf extends StatefulWidget {
  const UploadReceiptPdf({super.key});

  @override
  State<UploadReceiptPdf> createState() => _UploadReceiptPdfState();
}

class _UploadReceiptPdfState extends State<UploadReceiptPdf> {
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
  bool isGallery = true;
  File? _pdf;

  final formKey = GlobalKey<FormState>();

  final Map<ProductModel, String> _selectedCategories = {};

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
    _products = [];
    _category = "Food";

    _storeController = TextEditingController();
    _totalController = TextEditingController(text: "0.00");
  }

  double get total => _products.fold(0, (sum, p) => sum + p.total);

  String formatTL(double amount) => "₺${amount.toStringAsFixed(2)}";

  Future<void> _processPdf() async {
    if (_pdf == null) return;

    setState(() {
      _isEditing = true;
    });

    try {
      String base64Data;
      final document = await PdfDocument.openFile(_pdf!.path);
        final page = await document.getPage(1);
        final pageImage = await page.render(
          width: page.width * 2, // Yüksek kaliteli render
          height: page.height * 2,
          format: PdfPageImageFormat.jpeg,
          backgroundColor: '#ffffff',
        );
        base64Data = base64Encode(pageImage!.bytes);
        await page.close();
        await document.close();
      const prompt = """
Bu bir banka hesap ekstresi fotoğrafıdır. SADECE hesap hareketlerini çıkar.

Öncelikle, her hareketin açıklamasını analiz et:
- Kısaltmaları genişlet (örn. 'ATM WD' → 'ATM'den para çekme', 'POS PUR' → 'POS ile alışveriş', 'EFT' → 'EFT havale').
- Eğer açıklama kodlu veya belirsizse (örn. 'TXN 1234', 'MERCH 5678'), olası anlamını tahmin et (örn. POS numarasıysa 'Kartlı alışveriş - Mağaza bilinmiyor').
- Eğer mağaza adı kısaltılmışsa (örn. 'MIGROS IST'), tam adını çıkar (örn. 'Migros İstanbul Şubesi').
- Bilinmeyen kodlar için 'Bilinmeyen işlem' diye belirt, ama mümkünse bağlamdan tahmin et (tutar negatifse çıkış, pozitifse giriş).

Şu temiz JSON formatında dön, başka hiçbir metin yazma:

{
  "banka": "banka adı (okuyabiliyorsan)",
  "hesap_turu": "vadesiz / kredi kartı vb.",
  "hesap_no_son4": "son 4 hane veya IBAN son kısmı",
  "donem": "başlangıç - bitiş tarihi",
  "doviz": "TL / USD vb.",
  "toplam_bakiye": sayı,
  "hareket_sayisi": sayı,
  "hareketler": [
    {
      "tarih": "gg.aa.yyyy",
      "aciklama_orijinal": "orijinal metin (kısaltmalı hali)",
      "aciklama_yorumlu": "genişletilmiş/anlaşılır hali",
      "tutar": sayı,          // pozitif = giriş, negatif = çıkış
      "bakiye": sayı
    },
    ...
  ]
}

Kurallar:
- Tutarlar her zaman nokta ile ondalık (örn. 1234.56)
- Sadece gerçek hareket satırlarını ekle
- Reklam, logo, başlık, dipnot, toplam satırları hareket olarak ekleme
- Mümkünse açıklamayı tam ve doğru tut
- Çok fazla hareket varsa son 40 hareketi al
SADECE GEÇERLİ JSON DÖN. 
JSON DIŞINDA HİÇBİR KARAKTER YAZMA.
STRING İÇİNDE TIRNAK KARAKTERLERİNİ KAÇIR (\" şeklinde).
""";

      // Groq API çağrısı
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${dotenv.env['GROQ_API_KEY']}', // SENİN KEY'İN
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
          "temperature": 0.2, // Ekstre için biraz daha esnek
          "max_tokens": 4096, // Ekstre daha uzun olabilir
        }),
      );

      final decoded = jsonDecode(response.body);
      final content = decoded['choices'][0]['message']['content']
          .replaceAll("```json", "")
          .replaceAll("```", "")
          .trim();

      final data = jsonDecode(content);

      final List movements = data["hareketler"] ?? [];

      final parsed = movements.map((e) {
        return ProductModel(
          id: '',
          name: e["aciklama_yorumlu"] ?? "Unknown",
          price: (e["tutar"] ?? 0).abs().toDouble(),
          quantity: 1,
        );
      }).toList();

      setState(() {
        _products = parsed;
        _scanSuccessful = true;
        _selectedCategories.clear();
        _isEditing = false;
      });

    } catch (e) {
      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF error: $e")),
      );
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    final imageFile = File(picked.path);

    setState(() {
      _image = imageFile;
    });

    await _scanReceipt(imageFile);
  }

  Future<void> _pickPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return;

    setState(() {
      _pdf = File(result.files.single.path!);
    });
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
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Data = base64Encode(bytes);

      const prompt =
          """Bu fiş fotoğrafından SADECE alışveriş ürünleri ve fiyatlarını çıkar. Market adı, adres, tarih, ödeme türü gibi bilgileri ürün olarak alma! Sadece şu yapıda temiz JSON dön, başka hiçbir metin yazma:
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

      // Groq API çağrısı
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${dotenv.env['GROQ_API_KEY']}', // SENİN KEY'İN
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
          "temperature": 0.2, // Ekstre için biraz daha esnek
          "max_tokens": 2048, // Ekstre daha uzun olabilir
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("API Error ${response.statusCode}");
      }

      final decoded = jsonDecode(response.body);
      final content = decoded['choices'][0]['message']['content'];
      final cleaned =
          content.replaceAll("```json", "").replaceAll("```", "").trim();

      if (!cleaned.trim().startsWith("{")) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid receipt scan"),
          ),
        );
        return;
      }

      final data = jsonDecode(cleaned);

      final market = data["market"] ?? "";
      final total = (data["toplam"] ?? 0).toDouble();
      final dateString = data["tarih"];

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
          const SnackBar(
            content: Text("This doesn't look like a receipt"),
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

        _totalController.text = total.toStringAsFixed(2);

        _scanSuccessful = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload error: $e")),
      );
    }
  }

  // Receipt Save
  Future<void> _save() async {
    if (!_scanSuccessful) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please upload a receipt first"),
        ),
      );
      return;
    }

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
        category: _category,
        createdAt: DateTime.now(),
        source: 'scan',
      ),
      products: _products,
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  // Ekstre Save
  Future<void> _savePdf() async {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No transactions found")),
      );
      return;
    }

    /// kategori kontrol
    for (int i = 0; i < _products.length; i++) {
      final p = _products[i];

      if (!_selectedCategories.containsKey(p)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select all categories")),
        );
        return;
      }
    }

    /// HER BİRİNİ AYRI KAYDET
    for (int i = 0; i < _products.length; i++) {
      final p = _products[i];

      await _service.addTransaction(
        receipt: ReceiptModel(
          id: '',
          storeName: p.name,
          storeNameLower: p.name.toLowerCase(),
          totalAmount: p.total,
          date: DateTime.now(), 
          category: _selectedCategories[p]!,
          createdAt: DateTime.now(),
          source: 'pdf',
        ),
        products: [], // PDF'de ürün yok
      );
    }

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

                        final price =
                            double.tryParse(priceController.text) ?? 0;
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
                      icon:
                          product == null ? Icon(Icons.add) : Icon(Icons.save),
                      label: Text(product == null ? "Add" : "Save"),
                    ),
                  ),

                  const SizedBox(height: 10)
                ],
              )),
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

  Widget _buildPdfContent() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// 📄 PDF CARD
          GestureDetector(
            onTap: _pickPDF,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _pdf == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.picture_as_pdf,
                            size: 42,
                            color: theme.colorScheme.primary),
                        const SizedBox(height: 12),
                        Text(
                          "Upload PDF Statement",
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Tap to select your bank statement",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.picture_as_pdf,
                            size: 42, color: Colors.red),
                        const SizedBox(height: 10),
                        Text(
                          _pdf!.path.split('/').last,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Tap to change file",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 20),

          /// ⚡ ANALYZE BUTTON
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _pdf == null ? null : _processPdf,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text("Analyze PDF"),
            ),
          ),

          const SizedBox(height: 24),

          /// LOADING
          if (_isEditing)
            const Center(child: CircularProgressIndicator()),

          /// RESULTS
          if (_products.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text("Detected Transactions",
                    style: theme.textTheme.titleMedium),

                const SizedBox(height: 10),

                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: _products.length,
                    itemBuilder: (_, i) {
                      final p = _products[i];

                      return Dismissible(
                        key: ValueKey(p.name + i.toString()),
                        direction: DismissDirection.endToStart,

                        background: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),

                        onDismissed: (_) {
                          setState(() {
                            _selectedCategories.remove(p);
                            _products.removeAt(i);
                          });
                        },

                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(230),
                            borderRadius: BorderRadius.circular(14),
                          ),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              /// NAME + PRICE
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.name,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Text(
                                    "₺${p.total.toStringAsFixed(2)}",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  )
                                ],
                              ),

                              const SizedBox(height: 8),

                              /// CATEGORY DROPDOWN
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButton<String>(
                                  value: _selectedCategories[p],
                                  hint: const Text("Select category"),
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: categories
                                      .map((e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(e),
                                          ))
                                      .toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      _selectedCategories[p] = v!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _savePdf,
                    icon: const Icon(Icons.save),
                    label: const Text("Save Transactions"),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildGalleryContent() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
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
                          ? const Center(child: Text("No Image Selected"))
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
                        ? Icon(Icons.photo_library)
                        : Icon(Icons.refresh),
                    label: Text(_image == null
                        ? "Select from Gallery"
                        : "Change Image"),
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
              value:
                  categories.contains(_category) ? _category : categories.first,
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
                            child:
                                const Icon(Icons.delete, color: Colors.white),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                    )),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Receipt"),
      ),
      body: Column(
        children: [
          /// TOGGLE
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(
                        () => isGallery = true),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isGallery
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text("Gallery", 
                          style: TextStyle(color: Colors.black),), 
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isGallery = false),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: !isGallery
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text("PDF", 
                          style: TextStyle(color: Colors.black)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: isGallery ? _buildGalleryContent() : _buildPdfContent(),
          ),
        ],
      ),
    );
  }
}