import 'package:digital_receipt_wallet/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:digital_receipt_wallet/services/firestore_service.dart';
import 'package:digital_receipt_wallet/models/receipt_model.dart';
import 'package:digital_receipt_wallet/models/expense_item_model.dart';
import 'package:digital_receipt_wallet/screens/analytics_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final List<Color> chartColors = [
    const Color(0xFF805AD5), // mor
    const Color(0xFF9F7AEA),
    const Color(0xFFB794F4),
    const Color(0xFFD6BCFA),
    const Color(0xFF6B46C1),
  ];

  final FirestoreService firestoreService = FirestoreService();
  String selectedMonthKey =
    DateFormat('yyyy-MM').format(DateTime.now());

  DateTime get selectedMonth =>
      DateFormat('yyyy-MM').parse(selectedMonthKey);

  String? _errorMessage;

  final List<String> availableMonths = List.generate(
    12,
    (index) {
      final now = DateTime.now();
      final date = DateTime(now.year, now.month - index);
      return DateFormat('yyyy-MM').format(date);
    },
  );

  void _showBudgetBottomSheet() {
    final TextEditingController budgetController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        return FutureBuilder<UserModel?>(
          future: firestoreService.getUser(),
          builder: (context, snapshot) {
            double currentBudget = 0.0;

            if (snapshot.hasData && snapshot.data != null) {
              currentBudget = snapshot.data!.monthlyBudget;
            }

            // TextField'ı doldur (rebuild döngüsü yaratmadan)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (budgetController.text.isEmpty && currentBudget > 0) {
                budgetController.text = currentBudget.toStringAsFixed(0);
                budgetController.selection = TextSelection.fromPosition(
                  TextPosition(offset: budgetController.text.length),
                );
              }
            });

            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                32,
                24,
                MediaQuery.of(context).viewInsets.bottom + 34,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Aylık Bütçe Ayarla",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Mevcut bütçe
                  if (currentBudget > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        "Mevcut: ₺${currentBudget.toStringAsFixed(0)}",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),

                  TextField(
                    controller: budgetController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: false, 
                    decoration: InputDecoration(
                      labelText: "Yeni Bütçe (₺)",
                      prefixText: "₺ ",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Kaydet butonu
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        
                        final input = budgetController.text.trim().replaceAll(',', '.');
                        if (input.isEmpty) {
                          setState(() => _errorMessage = "Lütfen bir tutar girin");
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) {
                              setState(() => _errorMessage = null);
                            }
                          });
                          return;
                        }

                        final newBudget = double.tryParse(input);
                        if (newBudget == null || newBudget <= 0) {
                          setState(() => _errorMessage = "Lütfen geçerli bir tutar girin");
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) {
                              setState(() => _errorMessage = null);
                            }
                          });
                          return;
                        }

                        try {
                          await firestoreService.updateMonthlyBudget(newBudget);

                          if (!context.mounted) return;
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Bütçe ₺${newBudget.toStringAsFixed(0)} olarak güncellendi"),
                              backgroundColor: Colors.green,
                            ),
                          );

                          // Ana ekranı yenile
                          setState(() {});
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Hata: $e")),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Kaydet",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(38), // 0.15 * 255 = 38
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Reports"),
      ),
      body: SafeArea(
        child: StreamBuilder<List<ReceiptModel>>(
          stream: firestoreService.getTransactions(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final receipts = snapshot.data!;

            /// 🔹 1️⃣ Seçili Aya Göre Filtrele
            final monthlyReceipts = receipts.where((r) =>
                r.date.year == selectedMonth.year &&
                r.date.month == selectedMonth.month).toList();

            /// 🔹 2️⃣ Toplam Harcama
            double totalAmount = 0;
            for (var r in monthlyReceipts) {
              totalAmount += r.totalAmount;
            }

            /// 🔹 3️⃣ Kategoriye Göre Grupla
            final Map<String, double> categoryTotals = {};
            for (var r in monthlyReceipts) {
              categoryTotals[r.category] =
                  (categoryTotals[r.category] ?? 0) + r.totalAmount;
            }

            /// 🔹 4️⃣ Top 4 + Others Mantığı Expense Listesi Oluştur

            // 1. Kategorileri büyükten küçüğe sırala
            final sortedEntries = categoryTotals.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            // 2. İlk 4 kategoriyi al
            final topCategories = sortedEntries.take(4).toList();

            // 3. Geri kalanları topla
            double othersTotal = 0;
            if (sortedEntries.length > 4) {
              for (var entry in sortedEntries.skip(4)) {
                othersTotal += entry.value;
              }
            }

            // 4. Expense listesi oluştur
            final List<ExpenseItem> expenses = [];

            // Top 4 kategoriler
            for (int i = 0; i < topCategories.length; i++) {
              final entry = topCategories[i];

              final percentage = totalAmount == 0
                  ? 0.0
                  : (entry.value / totalAmount) * 100;

              expenses.add(
                ExpenseItem(
                  title: entry.key,
                  amount: entry.value,
                  percentage: percentage,
                  date: DateTime.now(),
                  color: chartColors[i % chartColors.length],
                ),
              );
            }

            // Others ekle (varsa)
            if (othersTotal > 0) {
              final percentage = totalAmount == 0
                  ? 0.0
                  : (othersTotal / totalAmount) * 100;

              expenses.add(
                ExpenseItem(
                  title: "Others",
                  amount: othersTotal,
                  percentage: percentage,
                  date: DateTime.now(),
                  color: chartColors[expenses.length % chartColors.length],
                ),
              );
            }

            /// 🔹 5️⃣ Daily Average
            final daysInMonth = DateUtils.getDaysInMonth(
                selectedMonth.year, selectedMonth.month);

            final dailyAverage =
                totalAmount == 0 ? 0 : totalAmount / daysInMonth;

            final currentMonth =
                DateFormat('MMMM yyyy').format(selectedMonth);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24),
              child: Column(
                children: [

                  /// HEADER
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start, // ← sola yasla
                      children: [
                        const Spacer(), // ortadaki boşluğu doldur
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 16,
                                color: colorScheme.primary),
                            const SizedBox(width: 4),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedMonthKey,
                                icon: Icon(Icons.arrow_drop_down,
                                    color: colorScheme.primary),
                                dropdownColor: theme.scaffoldBackgroundColor,
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                items: availableMonths.map((monthKey) {
                                  final parsedDate =
                                      DateFormat('yyyy-MM').parse(monthKey);

                                  return DropdownMenuItem<String>(
                                    value: monthKey,
                                    child: Text(
                                      DateFormat('MMMM yyyy')
                                          .format(parsedDate),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newMonth) {
                                  if (newMonth != null) {
                                    setState(() {
                                      selectedMonthKey = newMonth;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// 🔹 DONUT CHART
                  SizedBox(
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 4,
                            centerSpaceRadius: 80,
                            sections: expenses.isEmpty || totalAmount == 0
                                ? [
                                    PieChartSectionData(
                                      color: Colors.grey.withAlpha(51), // 20% opacity
                                      value: 1,
                                      title: '',
                                      radius: 25,
                                    )
                                  ]
                                : expenses
                                    .where((e) => e.percentage > 0)
                                    .map((e) => PieChartSectionData(
                                          color: e.color,
                                          value: e.percentage,
                                          title: '',
                                          radius: 25,
                                        ))
                                    .toList(),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₺${totalAmount.toStringAsFixed(0)}',
                              style: textTheme.headlineMedium
                                  ?.copyWith(
                                      fontWeight:
                                          FontWeight.bold),
                            ),
                            Text(currentMonth,
                                style: textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// 🔹 CATEGORY LIST
                  ...expenses.map((expense) => Padding(
                        padding:
                            const EdgeInsets.symmetric(
                                vertical: 10),
                        child: Row(
                          children: [
                            CircleAvatar(
                                radius: 6,
                                backgroundColor:
                                    expense.color),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(expense.title,
                                    style: textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                            fontWeight:
                                                FontWeight
                                                    .bold)),
                                const SizedBox(height: 2),
                                Text(
                                  '%${expense.percentage.toStringAsFixed(0)} of total',
                                  style:
                                      textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              '₺${expense.amount.toStringAsFixed(0)}',
                              style: textTheme.bodyLarge
                                  ?.copyWith(
                                      fontWeight:
                                          FontWeight.bold),
                            ),
                          ],
                        ),
                      )),

                  const SizedBox(height: 10),

                  /// 🔹 DAILY AVERAGE
                  Text(
                    'DAILY AVERAGE: ₺${dailyAverage.toStringAsFixed(2)}',
                    style: textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  Divider(
                    color: colorScheme.secondary,
                    thickness: 1.5,
                  ),

                  const SizedBox(height: 20),

                  /// 🔹 ADJUST BUDGET BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        setState(() {
                          _errorMessage = null; // Hata mesajını temizle
                        });
                        _showBudgetBottomSheet();
                      },
                      icon: Icon(Icons.tune,
                          color: colorScheme.onPrimaryContainer),
                      label: Text(
                        'Adjust Budget',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// 🔹 SECONDARY BUTTONS ROW
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 55,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AnalyticsScreen(),
                                ),
                              );
                            },
                            icon: Icon(Icons.analytics_outlined,
                                color: colorScheme.onSurface),
                            label: Text(
                              'Analytics',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 55,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              // future alert logic
                            },
                            icon: Icon(Icons.notifications_none,
                                color: colorScheme.onSurface),
                            label: Text(
                              'Set Alert',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}