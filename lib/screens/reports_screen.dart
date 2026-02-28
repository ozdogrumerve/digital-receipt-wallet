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
  Color generateColor(String key) {
    final colors = [
      const Color(0xFFC6A9D9),
      const Color(0xFFB28DFF),
      const Color(0xFFA57AFF),
      const Color(0xFFD4B5FF),
      const Color(0xFFE6D6FF),
      const Color(0xFF9F7AEA),
      const Color(0xFF805AD5),
    ];

    return colors[key.hashCode.abs() % colors.length];
  }

  final FirestoreService firestoreService = FirestoreService();
  String selectedMonthKey =
    DateFormat('yyyy-MM').format(DateTime.now());

  DateTime get selectedMonth =>
      DateFormat('yyyy-MM').parse(selectedMonthKey);

  final List<String> availableMonths = List.generate(
    12,
    (index) {
      final now = DateTime.now();
      final date = DateTime(now.year, now.month - index);
      return DateFormat('yyyy-MM').format(date);
    },
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
            for (var entry in topCategories) {
              final percentage = totalAmount == 0
                  ? 0.0
                  : (entry.value / totalAmount) * 100;

              expenses.add(
                ExpenseItem(
                  title: entry.key,
                  amount: entry.value,
                  percentage: percentage,
                  color: generateColor(entry.key),
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
                  color: generateColor("Others"),
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
                  horizontal: 24, vertical: 16),
              child: Column(
                children: [

                  /// HEADER
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 80),
                      Text(
                        'Reports',
                        style: textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
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
                                      color: Colors.grey.withOpacity(0.2),
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
                  Divider(
                      color: colorScheme.surfaceContainerHighest,
                      thickness: 1.5),
                  const SizedBox(height: 8),

                  /// 🔹 DAILY AVERAGE
                  Text(
                    'DAILY AVERAGE: ₺${dailyAverage.toStringAsFixed(2)}',
                    style: textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  Divider(
                    color: colorScheme.surfaceContainerHighest,
                    thickness: 4.5,
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
                        // later bottom sheet
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