import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyModel {
  final String code;
  final String name;
  final String symbol;
  final String flag;
  final double rateFromEur; // 1 EUR = X currency

  const CurrencyModel({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
    required this.rateFromEur,
  });
}

class CurrencyService extends ChangeNotifier {
  static final CurrencyService _instance = CurrencyService._internal();
  static CurrencyService get instance => _instance;
  CurrencyService._internal();

  static const String _prefKey = 'selected_currency_code';

  String _currentCode = 'EUR';
  String get currentCode => _currentCode;

  CurrencyModel get currentCurrency => allCurrencies.firstWhere(
    (c) => c.code == _currentCode,
    orElse: () => allCurrencies.first,
  );

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentCode = prefs.getString(_prefKey) ?? 'EUR';
    notifyListeners();
  }

  Future<void> setCurrency(String code) async {
    if (_currentCode == code) return;
    _currentCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, code);
    notifyListeners();
  }

  /// Convert a price from EUR to the current currency
  double convert(num priceInEur) {
    return priceInEur * currentCurrency.rateFromEur;
  }

  /// Format a price (originally in EUR) into the current currency string
  String format(num priceInEur, {bool isRent = false}) {
    final converted = convert(priceInEur);
    final currency = currentCurrency;
    final suffix = isRent ? '/mois' : '';

    if (converted >= 1000000) {
      final m = (converted / 1000000).toStringAsFixed(1);
      return '${currency.symbol}${m}M$suffix';
    } else if (converted >= 1000) {
      final k = (converted / 1000).toStringAsFixed(0);
      return '${currency.symbol}${k}k$suffix';
    } else {
      return '${currency.symbol}${converted.toStringAsFixed(0)}$suffix';
    }
  }

  /// Format per-m² price
  String formatPerM2(num pricePerM2InEur) {
    final converted = convert(pricePerM2InEur);
    final currency = currentCurrency;
    if (converted >= 1000) {
      return '${currency.symbol}${(converted / 1000).toStringAsFixed(1)}k/m²';
    }
    return '${currency.symbol}${converted.toStringAsFixed(0)}/m²';
  }

  static const List<CurrencyModel> allCurrencies = [
    CurrencyModel(
      code: 'EUR',
      name: 'Euro',
      symbol: '€',
      flag: '🇪🇺',
      rateFromEur: 1.0,
    ),
    CurrencyModel(
      code: 'USD',
      name: 'Dollar américain',
      symbol: '\$',
      flag: '🇺🇸',
      rateFromEur: 1.08,
    ),
    CurrencyModel(
      code: 'GBP',
      name: 'Livre sterling',
      symbol: '£',
      flag: '🇬🇧',
      rateFromEur: 0.86,
    ),
    CurrencyModel(
      code: 'CHF',
      name: 'Franc suisse',
      symbol: 'CHF',
      flag: '🇨🇭',
      rateFromEur: 0.97,
    ),
    CurrencyModel(
      code: 'XOF',
      name: 'Franc CFA (UEMOA)',
      symbol: 'CFA',
      flag: '🌍',
      rateFromEur: 655.96,
    ),
    CurrencyModel(
      code: 'XAF',
      name: 'Franc CFA (CEMAC)',
      symbol: 'FCFA',
      flag: '🌍',
      rateFromEur: 655.96,
    ),
    CurrencyModel(
      code: 'MAD',
      name: 'Dirham marocain',
      symbol: 'MAD',
      flag: '🇲🇦',
      rateFromEur: 10.85,
    ),
    CurrencyModel(
      code: 'TND',
      name: 'Dinar tunisien',
      symbol: 'DT',
      flag: '🇹🇳',
      rateFromEur: 3.35,
    ),
    CurrencyModel(
      code: 'DZD',
      name: 'Dinar algérien',
      symbol: 'DA',
      flag: '🇩🇿',
      rateFromEur: 145.0,
    ),
    CurrencyModel(
      code: 'CAD',
      name: 'Dollar canadien',
      symbol: 'CA\$',
      flag: '🇨🇦',
      rateFromEur: 1.47,
    ),
    CurrencyModel(
      code: 'AED',
      name: 'Dirham émirati',
      symbol: 'AED',
      flag: '🇦🇪',
      rateFromEur: 3.97,
    ),
    CurrencyModel(
      code: 'SAR',
      name: 'Riyal saoudien',
      symbol: 'SAR',
      flag: '🇸🇦',
      rateFromEur: 4.05,
    ),
    CurrencyModel(
      code: 'GNF',
      name: 'Franc guinéen',
      symbol: 'GNF',
      flag: '🇬🇳',
      rateFromEur: 9300.0,
    ),
    CurrencyModel(
      code: 'SEN',
      name: 'Franc sénégalais',
      symbol: 'CFA',
      flag: '🇸🇳',
      rateFromEur: 655.96,
    ),
    CurrencyModel(
      code: 'NGN',
      name: 'Naira nigérian',
      symbol: '₦',
      flag: '🇳🇬',
      rateFromEur: 1650.0,
    ),
  ];
}
