import 'package:digital_receipt_wallet/models/expense_item_model.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
// import 'models.dart';

class AnalyticsScreen extends StatelessWidget {
  // Dinamik Grafik Verisi (Provider'dan gelebilir)
  final List<ChartPoint> weeklyData = [
    ChartPoint(0, 2), ChartPoint(1, 1.8), ChartPoint(2, 3),
    ChartPoint(3, 2.2), ChartPoint(4, 4), ChartPoint(5, 3.5), ChartPoint(6, 2),
  ];

  // Dinamik Bütçe Kategorileri Listesi
  final List<BudgetCategory> budgetCategories = [
    BudgetCategory(title: 'Food & Drinks', spentPercentage: 65, icon: Icons.coffee, iconColor: Colors.orangeAccent, bgColor: Colors.orange.shade50),
    BudgetCategory(title: 'Shopping', spentPercentage: 40, icon: Icons.shopping_bag_outlined, iconColor: Colors.blueAccent, bgColor: Colors.blue.shade50),
    BudgetCategory(title: 'Transport', spentPercentage: 20, icon: Icons.directions_car_outlined, iconColor: Colors.greenAccent, bgColor: Colors.green.shade50),
  ];

  AnalyticsScreen({super.key});

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
                    child: LineChart(
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
                                const days = ['Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                if (value.toInt() >= 0 && value.toInt() < days.length) {
                                  return Text(days[value.toInt()], style: textTheme.bodySmall);
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            // Veriyi modelden map'liyoruz
                            spots: weeklyData.map((p) => FlSpot(p.day.toDouble(), p.value)).toList(),
                            isCurved: true,
                            color: colorScheme.primary,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: colorScheme.primary.withOpacity(0.15),
                            ),
                          ),
                        ],
                      ),
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