import 'package:flutter/material.dart';

class ExpenseItem {
  final String title;
  final double amount;
  final double percentage;
  final Color color;

  ExpenseItem({
    required this.title,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

class ChartPoint {
  final int day; // 0: Tue, 1: Wed...
  final double value;

  ChartPoint(this.day, this.value);
}

class BudgetCategory {
  final String title;
  final double spentPercentage;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  BudgetCategory({
    required this.title,
    required this.spentPercentage,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}