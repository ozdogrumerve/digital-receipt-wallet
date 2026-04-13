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

  final _storeController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _category = "Food";
  final List<ProductModel> _products = [];
  final _formKey = GlobalKey<FormState>();

  static const List<String> _categories = [
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
    "Other",
  ];

  double get _total => _products.fold(0, (sum, p) => sum + p.total);
  String _formatTL(double amount) => "₺${amount.toStringAsFixed(2)}";

  // ─── Save ─────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (_storeController.text.trim().isEmpty) {
      _showSnack("Store name cannot be empty");
      return;
    }
    if (_products.isEmpty) {
      _showSnack("Add at least one product");
      return;
    }

    await _service.addTransaction(
      receipt: ReceiptModel(
        id: '',
        storeName: _storeController.text.trim(),
        storeNameLower: _storeController.text.trim().toLowerCase(),
        totalAmount: _total,
        date: _selectedDate,
        category: _category,
        createdAt: DateTime.now(),
        source: 'manual',
      ),
      products: _products,
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ─── Add / Edit product bottom sheet ─────────────────────────────────────
  void _openProductSheet({ProductModel? product, int? index}) {
    final theme = Theme.of(context);
    final nameCtrl =
        TextEditingController(text: product?.name ?? "");
    final priceCtrl = TextEditingController(
        text: product != null ? product.price.toString() : "");
    final qtyCtrl = TextEditingController(
        text: product != null ? product.quantity.toString() : "1");

    Widget sheetInput({
      required IconData icon,
      required String hint,
      required TextEditingController controller,
      TextInputType? keyboardType,
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
            Icon(icon, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                validator: validator,
                decoration: InputDecoration(
                  hintText: hint,
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                product == null ? "Add Item" : "Edit Item",
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              sheetInput(
                icon: Icons.inventory_2_outlined,
                hint: "Product name",
                controller: nameCtrl,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? "Name required"
                    : null,
              ),
              const SizedBox(height: 14),
              sheetInput(
                icon: Icons.attach_money,
                hint: "Price (₺)",
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                validator: (v) {
                  final val = double.tryParse(v ?? "") ?? 0;
                  return val <= 0 ? "Price must be > 0" : null;
                },
              ),
              const SizedBox(height: 14),
              sheetInput(
                icon: Icons.format_list_numbered,
                hint: "Quantity",
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                validator: (v) {
                  final val = int.tryParse(v ?? "") ?? 0;
                  return val <= 0 ? "Qty must be > 0" : null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C7BCF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    final price =
                        double.tryParse(priceCtrl.text) ?? 0;
                    final qty = int.tryParse(qtyCtrl.text) ?? 1;
                    setState(() {
                      if (product == null) {
                        _products.add(ProductModel(
                          id: DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),
                          name: nameCtrl.text.trim(),
                          price: price,
                          quantity: qty,
                        ));
                      } else {
                        _products[index!] = ProductModel(
                          id: product.id,
                          name: nameCtrl.text.trim(),
                          price: price,
                          quantity: qty,
                        );
                      }
                    });
                    Navigator.pop(context);
                  },
                  icon: Icon(product == null ? Icons.add : Icons.save),
                  label: Text(product == null ? "Add" : "Save"),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // ─── inputBox — ScanReceipt ile birebir aynı ─────────────────────────────
  Widget _inputBox({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall!.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(0x99)),
        ),
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
        ),
      ],
    );
  }

  // ─── Readonly preview field (ADD ITEM card içinde) ────────────────────────
  Widget _previewField({required String hint, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          hint,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        ),
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Add Expense Manually")),
      body: SafeArea(
        child: Column(
          children: [

            // ── Tüm içerik scroll edilebilir ──────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Store Name ────────────────────────────────────
                    _inputBox(
                      context: context,
                      label: "Store Name",
                      icon: Icons.store,
                      child: TextField(
                        controller: _storeController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "e.g. Migros, A101",
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── Date + Category row ───────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _inputBox(
                            context: context,
                            label: "Date",
                            icon: Icons.calendar_today,
                            child: InkWell(
                              onTap: () async {
                                final picked =
                                    await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(
                                      () => _selectedDate = picked);
                                }
                              },
                              child: Text(
                                "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _inputBox(
                            context: context,
                            label: "Category",
                            icon: Icons.sell_outlined,
                            child: DropdownButton<String>(
                              value: _category,
                              isExpanded: true,
                              underline: const SizedBox(),
                              items: _categories
                                  .map((e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(
                                          e,
                                          overflow:
                                              TextOverflow.ellipsis,
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _category = v);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // ── ADD ITEM section ──────────────────────────────
                    Text(
                      "ADD ITEM",
                      style: theme.textTheme.labelMedium!
                          .copyWith(color: Colors.grey),
                    ),

                    const SizedBox(height: 12),

                    // Fotoğraftaki gibi beyaz kart
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Product Name",
                            style: theme.textTheme.labelSmall!
                                .copyWith(
                                    color: theme
                                        .colorScheme.onSurface
                                        .withAlpha(0x99)),
                          ),
                          const SizedBox(height: 6),
                          _previewField(
                            hint: "What did you buy?",
                            onTap: _openProductSheet,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Price",
                                      style: theme.textTheme
                                          .labelSmall!
                                          .copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurface
                                                  .withAlpha(0x99)),
                                    ),
                                    const SizedBox(height: 6),
                                    _previewField(
                                      hint: "₺ 0.00",
                                      onTap: _openProductSheet,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Qty (Opt)",
                                      style: theme.textTheme
                                          .labelSmall!
                                          .copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurface
                                                  .withAlpha(0x99)),
                                    ),
                                    const SizedBox(height: 6),
                                    _previewField(
                                      hint: "1",
                                      onTap: _openProductSheet,
                                    ),
                                  ],
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
                              onPressed: _openProductSheet,
                              child: const Text("+ Add to List"),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ── PURCHASE LIST header ──────────────────────────
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "PURCHASE LIST",
                          style: theme.textTheme.labelMedium!
                              .copyWith(color: Colors.grey),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE7F6),
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${_products.length} ITEMS",
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6A3BB5),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "Tap item to edit  •  Swipe left to delete",
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500),
                    ),

                    const SizedBox(height: 12),

                    // ── Sabit yükseklikli scrollable liste ────────────
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: theme.colorScheme.surface,
                      ),
                      child: _products.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.shopping_basket_outlined,
                                    size: 36,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "No items yet",
                                    style: TextStyle(
                                        color:
                                            Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(10),
                              physics:
                                  const BouncingScrollPhysics(),
                              itemCount: _products.length,
                              itemBuilder: (_, i) {
                                final p = _products[i];
                                return Dismissible(
                                  key: ValueKey(p.id),
                                  direction: DismissDirection
                                      .endToStart,
                                  background: Container(
                                    margin: const EdgeInsets.only(
                                        bottom: 10),
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 20),
                                    alignment:
                                        Alignment.centerRight,
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade400,
                                      borderRadius:
                                          BorderRadius.circular(
                                              16),
                                    ),
                                    child: const Icon(
                                        Icons.delete,
                                        color: Colors.white),
                                  ),
                                  onDismissed: (_) => setState(
                                      () => _products.removeAt(i)),
                                  child: GestureDetector(
                                    onTap: () => _openProductSheet(
                                        product: p, index: i),
                                    child: Container(
                                      margin: const EdgeInsets.only(
                                          bottom: 10),
                                      padding:
                                          const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withAlpha(0xEE),
                                        borderRadius:
                                            BorderRadius.circular(
                                                16),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                              children: [
                                                Text(
                                                  p.name,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight:
                                                        FontWeight
                                                            .w600,
                                                  ),
                                                ),
                                                const SizedBox(
                                                    height: 4),
                                                Text(
                                                  "${p.quantity} x ${_formatTL(p.price)}",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors
                                                        .grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            _formatTL(p.total),
                                            style: const TextStyle(
                                              fontWeight:
                                                  FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: 16),

                    // ── Total Amount ──────────────────────────────────
                    if (_products.isNotEmpty)
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
                              _formatTL(_total),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6A3BB5),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ── Save butonu — ekranın altında sabit ───────────────────
            SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C7BCF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text(
                      "Save Transaction",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _storeController.dispose();
    super.dispose();
  }
}