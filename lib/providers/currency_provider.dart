import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider extends ChangeNotifier {
  String _currencyCode = 'TRY';

  String get currencyCode => _currencyCode;

  String get symbol => currencySymbols[_currencyCode] ?? '₺';

  static const Map<String, String> currencySymbols = {
    'TRY': '₺',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'CHF': 'CHF',
    'CAD': 'C\$',
    'AUD': 'A\$',
    'CNY': '¥',
    'SAR': '﷼',
  };

  static const Map<String, String> currencyNames = {
    'TRY': 'Turkish Lira',
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'JPY': 'Japanese Yen',
    'CHF': 'Swiss Franc',
    'CAD': 'Canadian Dollar',
    'AUD': 'Australian Dollar',
    'CNY': 'Chinese Yuan',
    'SAR': 'Saudi Riyal',
  };

  // true: sembol başta (₺50), false: sembol sonda (50 CHF)
  static const Map<String, bool> _symbolBefore = {
    'TRY': true,
    'USD': true,
    'EUR': true,
    'GBP': true,
    'JPY': true,
    'CHF': false,
    'CAD': true,
    'AUD': true,
    'CNY': true,
    'SAR': false,
  };

  CurrencyProvider() {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _currencyCode = prefs.getString('currency') ?? 'TRY';
    notifyListeners();
  }

  Future<void> setCurrency(String code) async {
    _currencyCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', code);
  }

  String _place(String numberStr) {
    final before = _symbolBefore[_currencyCode] ?? true;
    if (before) {
      // Sembol ile sayı arasında boşluk yok: ₺50, $50
      return '$symbol$numberStr';
    } else {
      // Sembol sondaysa boşluklu: 50 CHF, 50 ﷼
      return '$numberStr $symbol';
    }
  }

  String format(double amount) => _place(amount.toStringAsFixed(2));

  String formatNoDecimal(double amount) => _place(amount.toStringAsFixed(0));
}