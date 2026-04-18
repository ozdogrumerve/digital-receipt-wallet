import 'package:digital_receipt_wallet/models/user_model.dart';
import 'package:digital_receipt_wallet/providers/notifications_provider.dart';
import 'package:digital_receipt_wallet/services/notification_service.dart';
import 'package:digital_receipt_wallet/services/statement_service.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:digital_receipt_wallet/services/firestore_service.dart';
import 'package:digital_receipt_wallet/models/receipt_model.dart';
import 'package:digital_receipt_wallet/models/expense_item_model.dart';
import 'package:digital_receipt_wallet/screens/analytics_screen.dart';
import 'package:provider/provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final List<Color> chartColors = [
    const Color(0xFF805AD5),
    const Color(0xFF9F7AEA),
    const Color(0xFFB794F4),
    const Color(0xFFD6BCFA),
    const Color(0xFF6B46C1),
  ];

  final FirestoreService firestoreService = FirestoreService();
  String selectedMonthKey = DateFormat('yyyy-MM').format(DateTime.now());

  DateTime get selectedMonth => DateFormat('yyyy-MM').parse(selectedMonthKey);

  String? _errorMessage;
  bool _isGeneratingStatement = false;

  final List<String> availableMonths = List.generate(
    12,
    (index) {
      final now = DateTime.now();
      final date = DateTime(now.year, now.month - index);
      return DateFormat('yyyy-MM').format(date);
    },
  );

  double? alertPercentage;
  bool alertTriggered = false;
  bool _isAlertSet = false;

  void checkAlert(double totalAmount, double budget, BuildContext context) {
    if (budget <= 0 || alertPercentage == null) return;

    final percentage = totalAmount / budget;

    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    if (percentage >= alertPercentage!) {
      if (notificationProvider.isEnabled && !alertTriggered) {
        NotificationService.showNotification(
          "Budget Alert",
          "%${(alertPercentage! * 100).toInt()} harcamaya ulasstiniz",
        );
      }

      alertTriggered = true;
    }
  }

  void _showBudgetBottomSheet() {
    final TextEditingController budgetController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
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
                    TextPosition(offset: budgetController.text.length));
              }
            });

            return Padding(
              padding: EdgeInsets.fromLTRB(
                  24,
                  32, 
                  24, 
                  MediaQuery.of(context).viewInsets.bottom + 34
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baslik ve Kapatma Ikonu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Aylik Butce Ayarla",
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Mevcut butce bilgisi (varsa)
                  if (currentBudget > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        "Mevcut: ₺${currentBudget.toStringAsFixed(0)}",
                        style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                            color: Theme.of(context).colorScheme.primary
                        ),
                      ),
                    ),

                  TextField(
                    controller: budgetController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    autofocus: false,
                    decoration: InputDecoration(
                      labelText: "Yeni Bütçe (₺)",
                      prefixText: "₺ ",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Kaydet Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        FocusScope.of(context).unfocus();

                        final input =
                            budgetController.text.trim().replaceAll(',', '.');
                        if (input.isEmpty) {
                          setState(() =>
                              _errorMessage = "Please enter a budget amount");
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) setState(() => _errorMessage = null);
                          });
                          return;
                        }

                        final newBudget = double.tryParse(input);
                        if (newBudget == null || newBudget <= 0) {
                          setState(() =>
                              _errorMessage = "Please enter a valid amount");
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) setState(() => _errorMessage = null);
                          });
                          return;
                        }

                        try {
                          await firestoreService.updateMonthlyBudget(newBudget);

                          if (!context.mounted) return;
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                "Budget updated to ₺${newBudget.toStringAsFixed(0)}"),
                            backgroundColor: Colors.green,
                          ));

                          // Ana ekranı yenilemek için
                          setState(() {});
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Hata: $e")));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("Kaydet",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(38),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(
                                  _errorMessage!,
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 14)
                                  )
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

  void _showAlertBottomSheet() {
    double selectedPercentage = 50;
    final parentSetState = setState;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// TITLE
                const Text("Alert Ayarla",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                /// DESCRIPTION
                Text(
                    "%${selectedPercentage.toInt()} harcamaya ulastigimda bildir"),

                const SizedBox(height: 20),

                /// PERCENTAGE SLIDER
                Slider(
                  value: selectedPercentage,
                  min: 10,
                  max: 100,
                  divisions: 9,
                  label: "${selectedPercentage.toInt()}%",
                  onChanged: (value) =>
                      setState(() => selectedPercentage = value),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    // CANCEL BUTTON
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          parentSetState(() {
                            alertPercentage = null;
                            alertTriggered = false;
                            _isAlertSet = false;
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Alert kaldirildi"),
                                  backgroundColor: Colors.orange));
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                            foregroundColor: Colors.black87),
                        child: const Text("Iptal Et"),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // SAVE BUTTON
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          parentSetState(() {
                            alertPercentage = selectedPercentage / 100;
                            alertTriggered = false;
                            _isAlertSet = true;
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                "%${selectedPercentage.toInt()} icin alert kuruldu"),
                            backgroundColor: Colors.green,
                          ));
                        },
                        child: const Text("Kaydet"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Reports")),
      body: SafeArea(
        child: StreamBuilder<UserModel?>(
          stream: firestoreService.getUserStream(),
          builder: (context, userSnapshot) {
            return StreamBuilder<List<ReceiptModel>>(
              stream: firestoreService.getTransactions(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final receipts = snapshot.data!;

                /// 🔹 1️⃣ Seçili Aya Göre Filtrele
                final monthlyReceipts = receipts
                    .where((r) =>
                        r.date.year == selectedMonth.year &&
                        r.date.month == selectedMonth.month)
                    .toList();

                /// 🔹 2️⃣ Toplam Harcama
                double totalAmount = 0;
                for (var r in monthlyReceipts) {
                  totalAmount += r.totalAmount;
                }

                final monthlyBudget = userSnapshot.data?.monthlyBudget ?? 0;
                checkAlert(totalAmount, monthlyBudget, context);


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
                  expenses.add(ExpenseItem(
                    title: entry.key,
                    amount: entry.value,
                    percentage: percentage,
                    date: DateTime.now(),
                    color: chartColors[i % chartColors.length],
                  ));
                }

                // Others kategorisi
                if (othersTotal > 0) {
                  final percentage = totalAmount == 0
                      ? 0.0
                      : (othersTotal / totalAmount) * 100;
                  expenses.add(ExpenseItem(
                    title: "Others",
                    amount: othersTotal,
                    percentage: percentage,
                    date: DateTime.now(),
                    color: chartColors[expenses.length % chartColors.length],
                  ));
                }

                /// 🔹 5️⃣ Daily Average
                final daysInMonth = DateUtils.getDaysInMonth(
                    selectedMonth.year, selectedMonth.month);

                final dailyAverage =
                    totalAmount == 0 ? 0.0 : totalAmount / daysInMonth;

                final currentMonth =
                    DateFormat('MMMM yyyy').format(selectedMonth);

                final currentMonthExpenses = receipts
                    .where(
                      (e) =>
                          e.date.year == selectedMonth.year &&
                          e.date.month == selectedMonth.month,
                    )
                    .toList();

                final previousMonthDate = DateTime(selectedMonth.year, selectedMonth.month - 1);

                final previousMonthExpenses = receipts
                    .where(
                      (e) =>
                          e.date.year == previousMonthDate.year &&
                          e.date.month == previousMonthDate.month,
                    )
                    .toList();

                final double currentMonthTotal =
                    currentMonthExpenses.fold<double>(
                  0,
                  (sum, item) => sum + item.totalAmount,
                );

                final double previousMonthTotal =
                    previousMonthExpenses.fold<double>(
                  0,
                  (sum, item) => sum + item.totalAmount,
                );

                final double changePercent = previousMonthTotal == 0
                    ? 0
                    : ((currentMonthTotal - previousMonthTotal) /
                            previousMonthTotal) *
                        100;

                final bool isIncrease = changePercent > 0;
                final bool isDecrease = changePercent < 0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // MONTH SELECTOR
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Spacer(), // ortadaki boşluğu doldur
                            Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 16, color: colorScheme.primary),
                                const SizedBox(width: 4),
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedMonthKey,
                                    icon: Icon(Icons.arrow_drop_down,
                                        color: colorScheme.primary),
                                    dropdownColor:
                                        theme.scaffoldBackgroundColor,
                                    style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600),
                                    items: availableMonths.map((monthKey) {
                                      final parsedDate =
                                          DateFormat('yyyy-MM').parse(monthKey);
                                      return DropdownMenuItem<String>(
                                        value: monthKey,
                                        child: Text(DateFormat('MMMM yyyy')
                                            .format(parsedDate)),
                                      );
                                    }).toList(),
                                    onChanged: (newMonth) {
                                      if (newMonth != null) {
                                        setState(
                                            () => selectedMonthKey = newMonth);
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
                                          color: Colors.grey
                                              .withAlpha(51), // 20% opacity
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
                                  'TL ${totalAmount.toStringAsFixed(0)}',
                                  style: textTheme.headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(currentMonth, 
                                    style: textTheme.bodySmall),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isIncrease
                                  ? Icons.trending_up
                                  : isDecrease
                                      ? Icons.trending_down
                                      : Icons.remove,
                              color: isIncrease
                                  ? Colors.red
                                  : isDecrease
                                      ? Colors.green
                                      : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              previousMonthTotal == 0
                                  ? 'No data for previous month'
                                  : isIncrease
                                      ? '%${changePercent.abs().toStringAsFixed(1)} increase'
                                      : isDecrease
                                          ? '%${changePercent.abs().toStringAsFixed(1)} decrease'
                                          : 'No change',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isIncrease
                                    ? Colors.red
                                    : isDecrease
                                        ? Colors.green
                                        : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      /// 🔹 CATEGORY LIST
                      ...expenses.map((expense) => Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                CircleAvatar(
                                    radius: 6,
                                    backgroundColor: expense.color),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(expense.title,
                                        style: textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '%${expense.percentage.toStringAsFixed(0)} of total',
                                      style: textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  '₺${expense.amount.toStringAsFixed(0)}',
                                  style: textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )),

                      const SizedBox(height: 10),

                      Text(
                        'DAILY AVERAGE: ₺${dailyAverage.toStringAsFixed(2)}',
                        style: textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.2, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 20),

                      Divider(
                        color: colorScheme.secondary,
                        thickness: 1.5,
                      ),

                      const SizedBox(height: 20),

                      /// 🔹 Analytics Screen
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AnalyticsScreen(),
                              ),
                            );
                          },
                          icon: Icon(Icons.analytics_outlined,
                              color: colorScheme.onPrimaryContainer,),
                          label: Text(
                            'Analytics',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// 🔹 SECONDARY BUTTONS ROW
                      /// EXPORT STATEMENT — tam genişlik, mor
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
                          onPressed: _isGeneratingStatement
                              ? null
                              : () async {
                                  setState(
                                    () => _isGeneratingStatement = true);
                                  try {
                                    await StatementService.generateAndShare(
                                      context: context,
                                      receipts: receipts,
                                      month: selectedMonth,
                                      monthlyBudget: monthlyBudget,
                                    );
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(
                                            "Statement oluşturulamadı: $e"),
                                        backgroundColor: Colors.red,
                                      ));
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(
                                          () => _isGeneratingStatement = false);
                                    }
                                  }
                                },
                          icon: _isGeneratingStatement
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                )
                              : Icon(Icons.picture_as_pdf_outlined,
                                  color: colorScheme.onPrimaryContainer),
                          label: Text(
                            _isGeneratingStatement
                                ? 'Generating...'
                                : 'Export Statement',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// BUDGET + ALERT — yan yana, soluk
                      Row(
                        children: [
                          // ADJUST BUDGET
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
                                  setState(() => _errorMessage = null);
                                  _showBudgetBottomSheet();
                                },
                                icon: Icon(Icons.tune,
                                    color: colorScheme.onSurface),
                                label: Text(
                                  'Budget',
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // SET ALERT
                          Expanded(
                            child: SizedBox(
                              height: 55,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    height: 55,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorScheme.surface,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                      ),
                                      onPressed: () {
                                        final notifProvider =
                                            Provider.of<NotificationProvider>(
                                                context,
                                                listen: false);
                                        if (!notifProvider.isEnabled) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content: Text(
                                                "Bildirimler kapalı. Ayarlardan açmalısınız."),
                                            backgroundColor: Colors.red,
                                          ));
                                          return;
                                        }
                                        _showAlertBottomSheet();
                                      },
                                      child: Center(
                                        child: Text(
                                          'Set Alert',
                                          style: TextStyle(
                                            color: colorScheme.onSurface,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_isAlertSet && alertPercentage != null)
                                    Positioned(
                                      top: -6,
                                      right: -6,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: colorScheme.surface,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.alarm_on_rounded,
                                          size: 20,
                                          color: colorScheme.primary,
                                          weight: 700,
                                        ),
                                      ),
                                    ),
                                ],
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
            );
          },
        ),
      ),
    );
  }
}
