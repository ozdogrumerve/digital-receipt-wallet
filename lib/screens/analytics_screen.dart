import 'package:digital_receipt_wallet/models/expense_item_model.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; 


class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  
  // Dinamik Bütçe Kategorileri Listesi
  final List<BudgetCategory> budgetCategories = [
    BudgetCategory(title: 'Food', spentPercentage: 65, icon: Icons.coffee, iconColor: Colors.orangeAccent, bgColor: Colors.orange.shade50),
    BudgetCategory(title: 'Clothing', spentPercentage: 40, icon: Icons.shopping_bag_outlined, iconColor: Colors.blueAccent, bgColor: Colors.blue.shade50),
    BudgetCategory(title: 'Tech', spentPercentage: 30, icon: Icons.laptop_outlined, iconColor: Colors.tealAccent, bgColor: Colors.teal.shade50),
    BudgetCategory(title: 'Transportation', spentPercentage: 20, icon: Icons.directions_car_outlined, iconColor: Colors.greenAccent, bgColor: Colors.green.shade50),
    BudgetCategory(title: 'Bills', spentPercentage: 50, icon: Icons.account_balance_outlined, iconColor: Colors.grey, bgColor: Colors.grey.shade50),
    BudgetCategory(title: 'Rent', spentPercentage: 70, icon: Icons.home_outlined, iconColor: Colors.brown, bgColor: Colors.brown.shade50),
    BudgetCategory(title: 'Education', spentPercentage: 25, icon: Icons.school_outlined, iconColor: Colors.indigoAccent, bgColor: const Color.fromARGB(255, 193, 201, 246)),
    BudgetCategory(title: 'Healthcare', spentPercentage: 15, icon: Icons.health_and_safety_outlined, iconColor: Colors.redAccent, bgColor: Colors.red.shade50),
    BudgetCategory(title: 'Personal Care', spentPercentage: 35, icon: Icons.account_circle_outlined, iconColor: Colors.pinkAccent, bgColor: Colors.pink.shade50),
    BudgetCategory(title: 'Entertainment', spentPercentage: 80, icon: Icons.movie_outlined, iconColor: Colors.purpleAccent, bgColor: Colors.purple.shade50),
    BudgetCategory(title: 'Household & Furniture', spentPercentage: 45, icon: Icons.home_outlined, iconColor: Colors.brown, bgColor: Colors.brown.shade50),
    BudgetCategory(title: 'Stationery', spentPercentage: 10, icon: Icons.edit_outlined, iconColor: Colors.grey, bgColor: Colors.grey.shade50),
    BudgetCategory(title: 'Vacation & Travel', spentPercentage: 25, icon: Icons.airplanemode_active_outlined, iconColor: Colors.deepPurpleAccent, bgColor: const Color.fromARGB(255, 210, 201, 224)),
    BudgetCategory(title: 'Taxes & Official Payments', spentPercentage: 15, icon: Icons.account_balance_outlined, iconColor: Colors.brown, bgColor: Colors.brown.shade50),
    BudgetCategory(title: 'Others', spentPercentage: 10, icon: Icons.other_houses_outlined, iconColor: Colors.grey, bgColor: Colors.grey.shade50)
  ];

  Stream<List<ExpenseItem>>? _expensesStream;

    @override
    void initState() {
      super.initState();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return;
      }

      // Bu hafta başı ve sonu hesapla (Pazartesi başlangıç)
      final now = DateTime.now();
      final daysToMonday = now.weekday - 1;
      final weekStart = DateTime(now.year, now.month, now.day - daysToMonday);
      final weekEnd = weekStart.add(const Duration(days: 7));

      final Timestamp startTs = Timestamp.fromDate(weekStart);
      final Timestamp endTs = Timestamp.fromDate(weekEnd);

      // Stream'i başlatıyoruz – tüm transactions altındaki products'ları filtreliyoruz
      _expensesStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: startTs)
        .where('date', isLessThanOrEqualTo: endTs)
        .snapshots()
        .asyncMap((transSnapshot) async {
      List<ExpenseItem> allExpenses = [];

      for (final trans in transSnapshot.docs) {
        final transData = trans.data();
        final transDate =
            (transData['date'] as Timestamp).toDate();

        final productsSnap =
            await trans.reference.collection('products').get();

        for (final productDoc in productsSnap.docs) {
          final data = productDoc.data();

          final price = (data['price'] as num?)?.toDouble() ?? 0;
          final quantity =
              (data['quantity'] as num?)?.toDouble() ?? 1;

          final amount = price * quantity;

          allExpenses.add(
            ExpenseItem(
              title: data['name'] ?? 'Unknown',
              amount: amount,
              date: transDate,
              percentage: 0,
              color: Colors.grey,
            ),
          );
        }
      }

      return allExpenses;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Analytics', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Spending Trend', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // --- DİNAMİK ÇİZGİ GRAFİK ---
            Container(
              height: 220,
              padding: const EdgeInsets.only(top: 16, right: 16, left: 16, bottom: 8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Weekly', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<List<ExpenseItem>>(
                      stream: _expensesStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasData) {
                          print('Ürün sayısı geldi: ${snapshot.data!.length}');
                          for (final exp in snapshot.data!) {
                            print('→ amount: ${exp.amount} | date: ${exp.date.toString()}');
                          }
                        } else if (snapshot.hasError) {
                          print('Stream hatası: ${snapshot.error}');
                        } else {
                          print('Veri yok veya bekleniyor');
                        }

                        if (snapshot.hasError) {
                          return Center(child: Text('Hata: ${snapshot.error}'));
                        }

                        final expenses = snapshot.data ?? [];

                        // Haftanın 7 günü için toplam harcama
                        final dailyTotals = List<double>.filled(7, 0.0);

                        final now = DateTime.now();
                        final monday = now.subtract(Duration(days: now.weekday - 1));
                        final weekStart = DateTime(monday.year, monday.month, monday.day);

                        for (final exp in expenses) {
                          final diff = exp.date.difference(weekStart).inDays;
                          if (diff >= 0 && diff < 7) {
                            dailyTotals[diff] += exp.amount;
                          }
                        }

                        final spots = List.generate(7, (i) => FlSpot(i.toDouble(), dailyTotals[i]));

                        return LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 22,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                                    final index = value.toInt();
                                    if (index >= 0 && index < days.length) {
                                      return Text(days[index], style: textTheme.bodySmall);
                                    }
                                    return const Text('');
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
                                  color: colorScheme.primary.withAlpha(0x26),
                                ),
                              ),
                            ],
                            minY: 0,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            Text('Monthly Budgets', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // --- DİNAMİK YATAY LİSTE (ListView.builder) ---
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: budgetCategories.length,
                itemBuilder: (context, index) {
                  final cat = budgetCategories[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Container(
                      width: 130,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: cat.bgColor, shape: BoxShape.circle),
                            child: Icon(cat.icon, color: cat.iconColor),
                          ),
                          const Spacer(),
                          Text(cat.title, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('%${cat.spentPercentage.toInt()} spent', style: textTheme.bodySmall),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),

            Text('MONTHLY INSIGHTS', style: textTheme.labelSmall?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Dinamik Insight verileri (Değişkenlere atanabilir)
            Text('HIGHEST SPENDING CATEGORY', style: textTheme.bodySmall),
            const SizedBox(height: 4),
            Text('Groceries & Dining (₺1,450)', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            Text('AVERAGE DAILY SPEND', style: textTheme.bodySmall),
            const SizedBox(height: 4),
            Text('₺138.00 / day', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),

            Text('Top Merchant', style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            // Top Merchant Container'ı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.shopping_bag_outlined, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Whole Foods Market', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('12 transactions', style: textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Text('₺580.00', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
