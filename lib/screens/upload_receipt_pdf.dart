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
import 'package:digital_receipt_wallet/l10n/app_localizations.dart';

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
  bool _isCategoryFromAI = false;
  bool _scanSuccessful = false;
  bool isGallery = true;
  File? _pdf;

  // PDF için yeni alanlar
  List<_Transaction> _transactions = [];
  double _pdfTotalIn = 0;
  double _pdfTotalOut = 0;
  String _pdfBanka = "";
  String _pdfDonem = "";

  final formKey = GlobalKey<FormState>();

  final Map<String, String> _selectedCategories = {};
  
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

  // ─── _processPdf ──────────────────────────────────────────────────────────────
  Future<void> _processPdf() async {
    if (_pdf == null) return;
    setState(() => _isEditing = true);
    final loc = AppLocalizations.of(context)!;

    try {
      final document = await PdfDocument.openFile(_pdf!.path);
      final page = await document.getPage(1);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.jpeg,
        backgroundColor: '#ffffff',
      );
      final base64Data = base64Encode(pageImage!.bytes);
      await page.close();
      await document.close();

      const prompt = """
  Bu bir banka hesap ekstresi fotoğrafıdır. SADECE hesap hareketlerini çıkar.

    Ek olarak:
  - Her işlem için uygun bir kategori tahmini yap.
  - Kategori şu listeden biri olmalı:
  Food, Clothing, Tech, Transportation, Bills, Rent, Education, Healthcare, 
  Personal Care, Entertainment, Household / Furniture, Stationery, 
  Vacation / Travel, Taxes / Official Payments, Other


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
      "kategori": "kategori adı"
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
          "temperature": 0.2,
          "max_tokens": 4096,
        }),
      );

      final decoded = jsonDecode(response.body);
      final content = decoded['choices'][0]['message']['content']
          .replaceAll("```json", "")
          .replaceAll("```", "")
          .trim();

      final data = jsonDecode(content);

      _pdfBanka = data["banka"] ?? "";
      _pdfDonem = data["donem"] ?? "";

      final List movements = data["hareketler"] ?? [];

      double totalIn = 0;
      double totalOut = 0;

      final parsed = movements.map<_Transaction>((e) {
        final amount = (e["tutar"] ?? 0).toDouble();
        
        if (amount >= 0) {
          totalIn += amount;
        } else {
          totalOut += amount.abs();
        }

        final tx = _Transaction(
          name: e["aciklama_yorumlu"] ?? "Bilinmeyen işlem",
          amount: amount,
          date: parseReceiptDate(e["tarih"]?.toString()) ?? DateTime.now(),
        );

        final categoryFromAI = e["kategori"];

        if (categoryFromAI != null && categories.contains(categoryFromAI)) {
          _selectedCategories[tx.name] = categoryFromAI;
        }

        return tx;

      }).toList();

      // Tarihe göre azalan sırayla sırala
      parsed.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _transactions = parsed;
        _pdfTotalIn = totalIn;
        _pdfTotalOut = totalOut;
        _scanSuccessful = true;
        _isEditing = false;
      });
    } catch (e) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${loc.pdfError}$e")),
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
    final loc = AppLocalizations.of(context)!;
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Data = base64Encode(bytes);

      const prompt =
          """Bu fiş fotoğrafından SADECE alışveriş ürünleri ve fiyatlarını çıkar. 

          Ek olarak:
          - Bu alışverişi en uygun kategoriye ata.
          - Kategori şu listeden biri olmalı:
          Food, Clothing, Tech, Transportation, Bills, Rent, Education, Healthcare, 
          Personal Care, Entertainment, Household / Furniture, Stationery, 
          Vacation / Travel, Taxes / Official Payments, Other

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
          Fiyatlar her zaman sayı olsun (virgül nokta olarak), ürün isimleri 
          tam ve doğru olsun. Adres, kasiyer adı, fiş numarası vb. 
          ürün olarak ekleme!""";

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
        SnackBar(content: Text("${loc.pdfError}$e")),
      );
    }
  }

  // Receipt Save
  Future<void> _save() async {
    final loc =  AppLocalizations.of(context)!;
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
    final loc = AppLocalizations.of(context)!;
    if (_transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.noTransactionsFound)),
      );
      return;
    }

    for (final tx in _transactions) {
      if (!_selectedCategories.containsKey(tx.name)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.pleaseSelectAllCategories)),
        );
        return;
      }
    }

    for (final tx in _transactions) {
      await _service.addTransaction(
        receipt: ReceiptModel(
          id: '',
          storeName: tx.name,
          storeNameLower: tx.name.toLowerCase(),
          totalAmount: tx.amount.abs(),
          date: tx.date,
          category: _selectedCategories[tx.name]!,
          createdAt: DateTime.now(),
          source: 'pdf',
        ),
        products: [],
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  void _addManualProduct({ProductModel? product, int? index}) {
    final loc = AppLocalizations.of(context)!;
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
                      label: Text(product == null ? loc.add : loc.save),
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
    final loc = AppLocalizations.of(context)!;

    // İşlemleri ay-yıl'a göre grupla
    final Map<String, List<_Transaction>> grouped = {};
    for (final tx in _transactions) {
      final key =
          '${_monthName(tx.date.month)} ${tx.date.year}';
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── PDF YÜKLEME KARTI ──────────────────────────
          GestureDetector(
            onTap: _pickPDF,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.primary.withAlpha(40),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.picture_as_pdf,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _pdf == null
                              ? loc.uploadEkstre
                              : _pdf!.path.split('/').last,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _pdf == null
                              ? loc.selectBankStatement
                              : loc.changePdf,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(0x80),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurface.withAlpha(0x60),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── ANALİZ BUTONU ──────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: (_pdf == null || _isEditing) ? null : _processPdf,
              icon: _isEditing
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onSurface,
                      ),
                    )
                  : const Icon(Icons.auto_fix_high, size: 18),
              label: Text(_isEditing ? loc.analyzing : loc.analyze),
            ),
          ),

          // ── SONUÇLAR ───────────────────────────────────
          if (_transactions.isNotEmpty) ...[

            const SizedBox(height: 24),

            // Özet kart
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _summaryItem(
                          context: context,
                          label: loc.totalExpense,
                          value: "₺${_pdfTotalOut.toStringAsFixed(2)}",
                          valueColor: const Color(0xFF993C1D),
                        ),
                      ),
                      Expanded(
                        child: _summaryItem(
                          context: context,
                          label: loc.totalIncome,
                          value: "₺${_pdfTotalIn.toStringAsFixed(2)}",
                          valueColor: const Color(0xFF3B6D11),
                        ),
                      ),
                    ],
                  ),
                  if (_pdfBanka.isNotEmpty || _pdfDonem.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Divider(height: 1, color: theme.colorScheme.onSurface.withAlpha(0x18)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (_pdfBanka.isNotEmpty)
                          Expanded(
                            child: _summaryItem(
                              context: context,
                              label: loc.bank,
                              value: _pdfBanka,
                            ),
                          ),
                        if (_pdfDonem.isNotEmpty)
                          Expanded(
                            child: _summaryItem(
                              context: context,
                              label: loc.period,
                              value: _pdfDonem,
                            ),
                          ),
                      ],
                    ),
                  ]
                ],
              ),
            ),

            const SizedBox(height: 20),

            // İşlem başlığı
            Row(
              children: [
                Text(loc.transactions, style: theme.textTheme.titleMedium),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withAlpha(0x20),
                    ),
                  ),
                  child: Text(
                    "${_transactions.length}",
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(0x80),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Ay gruplu işlem listesi
            ...grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      entry.key.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(0x70),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  ...entry.value.asMap().entries.map((e) {
                    final tx = e.value;
                    final isOut = tx.amount < 0;

                    return Dismissible(
                      key: ValueKey('${tx.name}_${tx.date}_${e.key}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child:  Icon(Icons.delete, color: theme.colorScheme.onSurface),
                      ),
                      onDismissed: (_) {
                        setState(() {
                          _transactions.remove(tx);
                          _selectedCategories.remove(tx.name);
                          _pdfTotalOut = _transactions
                              .where((t) => t.amount < 0)
                              .fold(0, (s, t) => s + t.amount.abs());
                          _pdfTotalIn = _transactions
                              .where((t) => t.amount >= 0)
                              .fold(0, (s, t) => s + t.amount);
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Row(
                              children: [
                                // İşlem ikonu
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isOut
                                        ? const Color(0xFFFAECE7)
                                        : const Color(0xFFEAF3DE),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isOut
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    size: 16,
                                    color: isOut
                                        ? const Color(0xFF993C1D)
                                        : const Color(0xFF3B6D11),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // İsim + tarih
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${tx.date.day} ${_monthName(tx.date.month)} ${tx.date.year}",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme.colorScheme.onSurface
                                              .withAlpha(0x70),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Tutar
                                Text(
                                  "${isOut ? '-' : '+'}₺${tx.amount.abs().toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isOut
                                        ? const Color(0xFF993C1D)
                                        : const Color(0xFF3B6D11),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Kategori seçimi (chip'ler)
                            SizedBox(
                              height: 28,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: categories.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 6),
                                itemBuilder: (context, ci) {
                                  final cat = categories[ci];
                                  final selected =
                                      _selectedCategories[tx.name] == cat;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedCategories[tx.name] = cat;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? theme.colorScheme.primary
                                                .withAlpha(0x22)
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                          color: selected
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.onSurface
                                                  .withAlpha(0x28),
                                          width: selected ? 1.2 : 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        cat,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: selected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: selected
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.onSurface
                                                  .withAlpha(0xAA),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            }),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _savePdf,
                icon: const Icon(Icons.save, size: 18),
                label: Text(loc.saveTransactions),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Özet item widget'ı
  Widget _summaryItem({
    required BuildContext context,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(0x80),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  // Ay adı yardımcı fonksiyonu
  String _monthName(int month) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[month];
  }

  Widget _buildGalleryContent() {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

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
                          ? Center(child: Text(loc.noImageSelected))
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
                        ? loc.selectFromGallery
                        : loc.changeImage),
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
                  _isEditing ? loc.done : loc.edit,
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
                            child:
                                Icon(Icons.delete, color: theme.colorScheme.onSurface),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.uploadReceipt),
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
                        child: Text(loc.gallery, 
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
                        child: Text(loc.pdf, 
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

// PDF işlemleri için basit model
class _Transaction {
  final String name;
  final double amount;
  final DateTime date;

  _Transaction({
    required this.name,
    required this.amount,
    required this.date,
  });
}