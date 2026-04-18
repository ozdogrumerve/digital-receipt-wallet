import 'package:digital_receipt_wallet/models/expense_item_model.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/receipt_model.dart';
import 'package:digital_receipt_wallet/l10n/app_localizations.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {

  // Kategori meta verisi (ikon/renk sabit, yüzde dinamik gelecek)
  final Map<String, _CategoryMeta> _categoryMeta = {
    'Food':                     _CategoryMeta(Icons.coffee,                    Colors.orangeAccent,      Colors.orange.shade50),
    'Clothing':                 _CategoryMeta(Icons.shopping_bag_outlined,     Colors.blueAccent,        Colors.blue.shade50),
    'Tech':                     _CategoryMeta(Icons.laptop_outlined,           Colors.tealAccent,        Colors.teal.shade50),
    'Transportation':           _CategoryMeta(Icons.directions_car_outlined,   Colors.greenAccent,       Colors.green.shade50),
    'Bills':                    _CategoryMeta(Icons.account_balance_outlined,  Colors.grey,              Colors.grey.shade50),
    'Rent':                     _CategoryMeta(Icons.home_outlined,             Colors.brown,             Colors.brown.shade50),
    'Education':                _CategoryMeta(Icons.school_outlined,           Colors.indigoAccent,      const Color(0xFFC1C9F6)),
    'Healthcare':               _CategoryMeta(Icons.health_and_safety_outlined,Colors.redAccent,         Colors.red.shade50),
    'Personal Care':            _CategoryMeta(Icons.account_circle_outlined,   Colors.pinkAccent,        Colors.pink.shade50),
    'Entertainment':            _CategoryMeta(Icons.movie_outlined,            Colors.purpleAccent,      Colors.purple.shade50),
    'Household / Furniture':    _CategoryMeta(Icons.home_outlined,             Colors.brown,             Colors.brown.shade50),
    'Stationery':               _CategoryMeta(Icons.edit_outlined,             Colors.grey,              Colors.grey.shade50),
    'Vacation / Travel':        _CategoryMeta(Icons.airplanemode_active_outlined, Colors.deepPurpleAccent, const Color(0xFFD2C9E0)),
    'Taxes / Official Payments':_CategoryMeta(Icons.account_balance_outlined,  Colors.brown,             Colors.brown.shade50),
    'Other':                    _CategoryMeta(Icons.other_houses_outlined,     Colors.grey,              Colors.grey.shade50),
  };

  String _localizeCategory(String category, AppLocalizations loc) {
    switch (category) {
      case 'Food': return loc.food;
      case 'Clothing': return loc.clothing;
      case 'Tech': return loc.tech;
      case 'Transportation': return loc.transportation;
      case 'Bills': return loc.bills;
      case 'Rent': return loc.rent;
      case 'Education': return loc.education;
      case 'Healthcare': return loc.healthcare;
      case 'Personal Care': return loc.personalCare;
      case 'Entertainment': return loc.entertainment;
      case 'Household / Furniture': return loc.householdFurniture;
      case 'Stationery': return loc.stationery;
      case 'Vacation / Travel': return loc.vacationTravel;
      case 'Taxes / Official Payments': return loc.taxesOfficialPayments;
      case 'Other': return loc.other;
      default: return category;
    }
  }

  Stream<List<ExpenseItem>>? _weeklyExpensesStream;
  Stream<List<ReceiptModel>>? _monthlyTransactionsStream;

  late DateTime _weekStart;
  late DateTime _monthStart;
  late DateTime _monthEnd;
  DateTimeRange? _selectedRange;


  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();

    // Hafta başı (Pazartesi)
    final monday = now.subtract(Duration(days: now.weekday - 1));
    _weekStart = DateTime(monday.year, monday.month, monday.day);
    final weekEnd = _weekStart.add(const Duration(days: 7));

    // Ay başı/sonu
    _monthStart = DateTime(now.year, now.month, 1);
    _monthEnd = DateTime(now.year, now.month + 1, 1);

    _selectedRange = DateTimeRange(
      start: _monthStart,
      end: _monthEnd.subtract(const Duration(days: 1)),
    );

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions');

    // Haftalık stream → çizgi grafik
    _weeklyExpensesStream = ref
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_weekStart))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(weekEnd))
        .snapshots()
        .asyncMap((snap) async {
      final List<ExpenseItem> items = [];
      for (final doc in snap.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final products = await doc.reference.collection('products').get();
        for (final p in products.docs) {
          final pd = p.data();
          items.add(ExpenseItem(
            title: pd['name'] ?? '',
            amount: ((pd['price'] as num?)?.toDouble() ?? 0) *
                ((pd['quantity'] as num?)?.toDouble() ?? 1),
            date: date,
            percentage: 0,
            color: Colors.grey,
          ));
        }
      }
      return items;
    });

    // Aylık stream → budget kategoriler + insights + top merchant
    _monthlyTransactionsStream = ref
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_monthStart))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(_monthEnd))
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ReceiptModel.fromMap(d.id, d.data()))
            .toList());
  }

  // Filtreleme için tarih aralığı seçimi
  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _selectedRange,
    );

    if (picked == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final start = DateTime(
      picked.start.year,
      picked.start.month,
      picked.start.day,
    );

    final endExclusive = DateTime(
      picked.end.year,
      picked.end.month,
      picked.end.day + 1,
    );

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions');

    setState(() {
      _selectedRange = picked;
      _monthStart = start;
      _monthEnd = endExclusive;

      _monthlyTransactionsStream = ref
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_monthStart))
          .where('date', isLessThan: Timestamp.fromDate(_monthEnd))
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => ReceiptModel.fromMap(d.id, d.data()))
              .toList());
    });
  }

  // Aylık veriden türetilen analiz sonuçları
  _MonthlyAnalytics _computeAnalytics(List<ReceiptModel> transactions) {
    // Kategori bazlı toplam harcama
    final Map<String, double> categoryTotals = {};
    for (final tx in transactions) {
      categoryTotals[tx.category] =
          (categoryTotals[tx.category] ?? 0) + tx.totalAmount;
    }

    // Mağaza bazlı toplam + işlem sayısı
    final Map<String, double> merchantTotals = {};
    final Map<String, int> merchantCounts = {};
    for (final tx in transactions) {
      merchantTotals[tx.storeName] =
          (merchantTotals[tx.storeName] ?? 0) + tx.totalAmount;
      merchantCounts[tx.storeName] =
          (merchantCounts[tx.storeName] ?? 0) + 1;
    }

    // En yüksek kategorii
    String topCategory = '-';
    double topCategoryAmount = 0;
    categoryTotals.forEach((cat, amount) {
      if (amount > topCategoryAmount) {
        topCategoryAmount = amount;
        topCategory = cat;
      }
    });

    // En yüksek mağaza
    String topMerchant = '-';
    double topMerchantAmount = 0;
    int topMerchantCount = 0;
    merchantTotals.forEach((name, amount) {
      if (amount > topMerchantAmount) {
        topMerchantAmount = amount;
        topMerchant = name;
        topMerchantCount = merchantCounts[name] ?? 0;
      }
    });

    // Ortalama günlük harcama (bu ayki gün sayısına göre)
    final now = DateTime.now();
    final daysInMonth = _monthEnd.difference(_monthStart).inDays;
    final passedDays = now.day.clamp(1, daysInMonth);
    final totalSpent = transactions.fold(0.0, (s, t) => s + t.totalAmount);
    final avgDaily = passedDays > 0 ? totalSpent / passedDays : 0.0;

    // Budget yüzdeleri (sabit bütçe yoksa harcamayı max'a oranlıyoruz)
    final maxSpend =
        categoryTotals.values.fold(0.0, (m, v) => v > m ? v : m);

    return _MonthlyAnalytics(
      categoryTotals: categoryTotals,
      topCategory: topCategory,
      topCategoryAmount: topCategoryAmount,
      topMerchant: topMerchant,
      topMerchantAmount: topMerchantAmount,
      topMerchantCount: topMerchantCount,
      avgDailySpend: avgDaily,
      maxSpend: maxSpend,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(loc.analytics,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: StreamBuilder<List<ReceiptModel>>(
          stream: _monthlyTransactionsStream,
          builder: (context, monthlySnap) {
            final monthlyData = monthlySnap.data ?? [];
            final analytics = _computeAnalytics(monthlyData);

            // Toplam harcamayı 1 kez hesapla (map dışında)
            final totalSpent = analytics.categoryTotals.values
                .fold(0.0, (total, val) => total + val);

            // Kategori listesini hazırla
            final budgetCategories = _categoryMeta.entries.map((entry) {
              final spent = analytics.categoryTotals[entry.key] ?? 0.0;

              final pct = totalSpent > 0
                  ? (spent / totalSpent * 100).clamp(0.0, 100.0).toDouble()
                  : 0.0;

              return BudgetCategory(
                title: entry.key,
                spentPercentage: pct,
                icon: entry.value.icon,
                iconColor: entry.value.iconColor,
                bgColor: entry.value.bgColor,
              );
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Çizgi grafik ────────────────────────────────
                Text(loc.spendingTrend,
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                Container(
                  height: 220,
                  padding: const EdgeInsets.only(
                      top: 16, right: 16, left: 16, bottom: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.weekly,
                          style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                      const SizedBox(height: 10),
                      Expanded(
                        child: StreamBuilder<List<ExpenseItem>>(
                          stream: _weeklyExpensesStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            final expenses = snapshot.data ?? [];
                            final dailyTotals = List<double>.filled(7, 0.0);

                            for (final exp in expenses) {
                              final diff =
                                  exp.date.difference(_weekStart).inDays;
                              if (diff >= 0 && diff < 7) {
                                dailyTotals[diff] += exp.amount;
                              }
                            }

                            final spots = List.generate(
                                7,
                                (i) => FlSpot(
                                    i.toDouble(), dailyTotals[i]));

                            return LineChart(LineChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 22,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      final days = [loc.mon, loc.tue, loc.wed, 
                                      loc.thu, loc.fri, loc.sat, loc.sun];
                                      final i = value.toInt();
                                      return i >= 0 && i < days.length
                                          ? Text(days[i],
                                              style: textTheme.bodySmall)
                                          : const Text('');
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  color: colorScheme.primary,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: colorScheme.primary
                                        .withAlpha(0x26),
                                  ),
                                ),
                              ],
                              minY: 0,
                            ));
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // ── Monthly Budgets ──────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc.categoryBudgets,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    InkWell(
                      onTap: _pickDateRange,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outline.withAlpha(80)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.date_range_outlined,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedRange == null
                                  ? loc.selectRange
                                  : '${DateFormat('dd MMM').format(_selectedRange!.start)} - ${DateFormat('dd MMM').format(_selectedRange!.end)}',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                SizedBox(
                  height: 140,
                  child: monthlySnap.connectionState ==
                          ConnectionState.waiting
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: budgetCategories.length,
                          itemBuilder: (context, index) {
                            final cat = budgetCategories[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.only(right: 16.0),
                              child: Container(
                                width: 130,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius:
                                        BorderRadius.circular(16)),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                          color: cat.bgColor,
                                          shape: BoxShape.circle),
                                      child: Icon(cat.icon,
                                          color: cat.iconColor),
                                    ),
                                    const Spacer(),
                                    // Overflow düzeltmesi: maxLines + overflow
                                    Text(
                                      _localizeCategory(cat.title, loc),
                                      style: textTheme.bodyMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${cat.spentPercentage.toStringAsFixed(1)}%",
                                      style: textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                const SizedBox(height: 30),

                // ── Monthly Insights ─────────────────────────────
                Text(loc.monthlyInsights,
                    style: textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                Text(loc.highestSpendingCategory,
                    style: textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  analytics.topCategory == '-'
                      ? loc.noDataYet
                      : '${_localizeCategory(analytics.topCategory, loc)}'
                      ' (₺${analytics.topCategoryAmount.toStringAsFixed(2)})',
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),

                Text(loc.averageDailySpend,
                    style: textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  '₺${analytics.avgDailySpend.toStringAsFixed(2)} ${loc.perDay}',
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 30),

                // ── Top Merchant ─────────────────────────────────
                Text(loc.topMerchant,
                    style: textTheme.labelSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16)),
                  child: analytics.topMerchant == '-'
                      ? Center(
                          child: Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                          child: Text(loc.noDataYet,
                              style: textTheme.bodyMedium),
                        ))
                      : Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: colorScheme.primary
                                      .withAlpha(0x1A),
                                  borderRadius:
                                      BorderRadius.circular(12)),
                              child: Icon(
                                  Icons.shopping_bag_outlined,
                                  color: colorScheme.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    analytics.topMerchant,
                                    style: textTheme.bodyLarge
                                        ?.copyWith(
                                            fontWeight:
                                                FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${analytics.topMerchantCount}'
                                    ' ${loc.transactionsCount}',
                                    style: textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₺${analytics.topMerchantAmount.toStringAsFixed(2)}',
                              style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 30),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Yardımcı sınıflar ─────────────────────────────────────────────────────────

class _CategoryMeta {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  const _CategoryMeta(this.icon, this.iconColor, this.bgColor);
}

class _MonthlyAnalytics {
  final Map<String, double> categoryTotals;
  final String topCategory;
  final double topCategoryAmount;
  final String topMerchant;
  final double topMerchantAmount;
  final int topMerchantCount;
  final double avgDailySpend;
  final double maxSpend;

  _MonthlyAnalytics({
    required this.categoryTotals,
    required this.topCategory,
    required this.topCategoryAmount,
    required this.topMerchant,
    required this.topMerchantAmount,
    required this.topMerchantCount,
    required this.avgDailySpend,
    required this.maxSpend,
  });
}