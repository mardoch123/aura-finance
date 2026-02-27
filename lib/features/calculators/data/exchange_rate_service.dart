import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/calculator_models.dart';

/// Service de taux de change
class ExchangeRateService {
  ExchangeRateService._();
  
  static final ExchangeRateService _instance = ExchangeRateService._();
  static ExchangeRateService get instance => _instance;

  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';
  static const String _cacheKey = 'exchange_rates_cache';
  static const String _lastUpdateKey = 'exchange_rates_last_update';
  static const Duration _cacheValidity = Duration(hours: 1);

  Map<String, double> _rates = {};
  DateTime? _lastUpdate;
  String _baseCurrency = 'EUR';

  /// Initialise le service
  Future<void> initialize() async {
    await _loadCachedRates();
    if (_shouldRefresh()) {
      await refreshRates();
    }
  }

  /// Récupère les taux depuis l'API
  Future<void> refreshRates({String baseCurrency = 'EUR'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$baseCurrency'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _rates = Map<String, double>.from(
          data['rates'].map((k, v) => MapEntry(k, v.toDouble())),
        );
        _baseCurrency = baseCurrency;
        _lastUpdate = DateTime.now();
        await _cacheRates();
      } else {
        throw Exception('Failed to fetch rates: ${response.statusCode}');
      }
    } catch (e) {
      // En cas d'erreur, utiliser les taux en cache
      if (_rates.isEmpty) {
        _loadFallbackRates();
      }
    }
  }

  /// Convertit un montant
  Future<CurrencyConversion> convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    if (_shouldRefresh()) {
      await refreshRates();
    }

    double rate;
    if (fromCurrency == _baseCurrency) {
      rate = _rates[toCurrency] ?? 1.0;
    } else if (toCurrency == _baseCurrency) {
      rate = 1 / (_rates[fromCurrency] ?? 1.0);
    } else {
      // Conversion via la devise de base
      final fromRate = _rates[fromCurrency] ?? 1.0;
      final toRate = _rates[toCurrency] ?? 1.0;
      rate = toRate / fromRate;
    }

    return CurrencyConversion(
      amount: amount,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      convertedAmount: amount * rate,
      rate: rate,
      timestamp: _lastUpdate ?? DateTime.now(),
    );
  }

  /// Récupère le taux entre deux devises
  double getRate(String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return 1.0;
    if (fromCurrency == _baseCurrency) {
      return _rates[toCurrency] ?? 1.0;
    }
    if (toCurrency == _baseCurrency) {
      return 1 / (_rates[fromCurrency] ?? 1.0);
    }
    final fromRate = _rates[fromCurrency] ?? 1.0;
    final toRate = _rates[toCurrency] ?? 1.0;
    return toRate / fromRate;
  }

  /// Liste toutes les devises disponibles
  List<String> get availableCurrencies {
    final currencies = _rates.keys.toList();
    if (!currencies.contains(_baseCurrency)) {
      currencies.add(_baseCurrency);
    }
    return currencies..sort();
  }

  /// Vérifie si une devise est supportée
  bool isCurrencySupported(String currency) {
    return currency == _baseCurrency || _rates.containsKey(currency);
  }

  /// Récupère l'historique des taux (simulé - en production, utiliser une API historique)
  Future<List<Map<String, dynamic>>> getHistoricalRates({
    required String currency,
    required int days,
  }) async {
    // Simuler des données historiques avec variation
    final currentRate = getRate('EUR', currency);
    final historical = <Map<String, dynamic>>[];
    
    final random = DateTime.now().millisecondsSinceEpoch;
    
    for (int i = days; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      // Simuler une variation de ±2%
      final variation = ((random + i) % 100 - 50) / 2500;
      historical.add({
        'date': date.toIso8601String().split('T')[0],
        'rate': currentRate * (1 + variation),
      });
    }
    
    return historical;
  }

  /// Détecte si l'utilisateur est à l'étranger (à appeler avec la localisation)
  Future<TravelDetectionResult?> detectTravel({
    required String currentCountry,
    required String homeCountry,
  }) async {
    if (currentCountry == homeCountry) return null;

    // Mapping pays -> devise
    final countryCurrency = _getCurrencyForCountry(currentCountry);
    final homeCurrency = _getCurrencyForCountry(homeCountry);

    if (countryCurrency == null || homeCurrency == null) return null;

    return TravelDetectionResult(
      isTraveling: true,
      currentCountry: currentCountry,
      currentCurrency: countryCurrency,
      homeCurrency: homeCurrency,
      exchangeRate: getRate(homeCurrency, countryCurrency),
    );
  }

  /// Cache les taux localement
  Future<void> _cacheRates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(_rates));
    await prefs.setString(_lastUpdateKey, _lastUpdate?.toIso8601String() ?? '');
    await prefs.setString('base_currency', _baseCurrency);
  }

  /// Charge les taux depuis le cache
  Future<void> _loadCachedRates() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    final lastUpdateStr = prefs.getString(_lastUpdateKey);
    
    if (cached != null) {
      _rates = Map<String, double>.from(
        jsonDecode(cached).map((k, v) => MapEntry(k, v.toDouble())),
      );
    }
    
    if (lastUpdateStr != null && lastUpdateStr.isNotEmpty) {
      _lastUpdate = DateTime.tryParse(lastUpdateStr);
    }
    
    _baseCurrency = prefs.getString('base_currency') ?? 'EUR';
  }

  /// Vérifie si le cache doit être rafraîchi
  bool _shouldRefresh() {
    if (_lastUpdate == null) return true;
    return DateTime.now().difference(_lastUpdate!) > _cacheValidity;
  }

  /// Taux de secours si l'API échoue
  void _loadFallbackRates() {
    _rates = {
      'USD': 1.08,
      'GBP': 0.85,
      'CHF': 0.94,
      'JPY': 162.0,
      'CAD': 1.47,
      'AUD': 1.65,
      'CNY': 7.8,
      'SEK': 11.4,
      'NOK': 11.6,
      'DKK': 7.45,
      'PLN': 4.3,
      'CZK': 25.0,
      'HUF': 395.0,
      'RON': 4.97,
      'BGN': 1.96,
      'HRK': 7.5,
      'TRY': 35.0,
      'BRL': 5.4,
      'MXN': 18.5,
      'INR': 90.0,
      'KRW': 1450.0,
      'SGD': 1.46,
      'HKD': 8.45,
      'NZD': 1.78,
      'ZAR': 20.5,
      'AED': 3.97,
      'SAR': 4.05,
      'THB': 39.0,
      'MYR': 5.1,
      'IDR': 17000.0,
      'PHP': 60.0,
      'VND': 27000.0,
    };
    _baseCurrency = 'EUR';
    _lastUpdate = DateTime.now();
  }

  /// Mapping pays -> devise
  String? _getCurrencyForCountry(String countryCode) {
    final mapping = {
      'FR': 'EUR', 'DE': 'EUR', 'ES': 'EUR', 'IT': 'EUR', 'NL': 'EUR',
      'BE': 'EUR', 'AT': 'EUR', 'PT': 'EUR', 'IE': 'EUR', 'FI': 'EUR',
      'GR': 'EUR', 'SK': 'EUR', 'SI': 'EUR', 'EE': 'EUR', 'LV': 'EUR',
      'LT': 'EUR', 'LU': 'EUR', 'MT': 'EUR', 'CY': 'EUR',
      'US': 'USD', 'GB': 'GBP', 'CH': 'CHF', 'JP': 'JPY',
      'CA': 'CAD', 'AU': 'AUD', 'CN': 'CNY', 'SE': 'SEK',
      'NO': 'NOK', 'DK': 'DKK', 'PL': 'PLN', 'CZ': 'CZK',
      'HU': 'HUF', 'RO': 'RON', 'BG': 'BGN', 'HR': 'HRK',
      'TR': 'TRY', 'BR': 'BRL', 'MX': 'MXN', 'IN': 'INR',
      'KR': 'KRW', 'SG': 'SGD', 'HK': 'HKD', 'NZ': 'NZD',
      'ZA': 'ZAR', 'AE': 'AED', 'SA': 'SAR', 'TH': 'THB',
      'MY': 'MYR', 'ID': 'IDR', 'PH': 'PHP', 'VN': 'VND',
    };
    return mapping[countryCode.toUpperCase()];
  }

  /// Dernière mise à jour
  DateTime? get lastUpdate => _lastUpdate;

  /// Devise de base
  String get baseCurrency => _baseCurrency;
}

/// Résultat de détection de voyage
class TravelDetectionResult {
  final bool isTraveling;
  final String currentCountry;
  final String currentCurrency;
  final String homeCurrency;
  final double exchangeRate;

  TravelDetectionResult({
    required this.isTraveling,
    required this.currentCountry,
    required this.currentCurrency,
    required this.homeCurrency,
    required this.exchangeRate,
  });

  String get formattedRate => '1 $homeCurrency = ${exchangeRate.toStringAsFixed(4)} $currentCurrency';
}
