import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider pour le service de locale
final localeServiceProvider = Provider<LocaleService>((ref) {
  return LocaleService.instance;
});

/// Provider pour la locale actuelle (notifier)
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(LocaleService.instance);
});

/// Notifier pour gérer les changements de locale
class LocaleNotifier extends StateNotifier<Locale> {
  final LocaleService _localeService;

  LocaleNotifier(this._localeService) : super(_localeService.currentLocale) {
    _init();
  }

  Future<void> _init() async {
    await _localeService.initialize();
    state = _localeService.currentLocale;
  }

  /// Change la locale
  Future<void> setLocale(Locale locale) async {
    await _localeService.setLocale(locale);
    state = locale;
  }

  /// Détecte et applique la langue du téléphone
  Future<void> detectAndSetDeviceLocale() async {
    final deviceLocale = _localeService.getDeviceLocale();
    await setLocale(deviceLocale);
  }
}

/// Service de gestion des langues
class LocaleService {
  static final LocaleService _instance = LocaleService._internal();
  static LocaleService get instance => _instance;

  LocaleService._internal();

  static const String _localeKey = 'app_locale';
  
  late SharedPreferences _prefs;
  Locale _currentLocale = const Locale('fr', 'FR');
  bool _isInitialized = false;

  /// Locales supportées par l'application
  static const List<Locale> supportedLocales = [
    Locale('fr', 'FR'),
    Locale('en', 'US'),
    Locale('es', 'ES'),
    Locale('de', 'DE'),
    Locale('it', 'IT'),
    Locale('pt', 'PT'),
  ];

  /// Noms des langues pour l'affichage
  static const Map<String, String> localeNames = {
    'fr': 'Français',
    'en': 'English',
    'es': 'Español',
    'de': 'Deutsch',
    'it': 'Italiano',
    'pt': 'Português',
  };

  /// Drapeaux des langues
  static const Map<String, String> localeFlags = {
    'fr': '🇫🇷',
    'en': '🇺🇸',
    'es': '🇪🇸',
    'de': '🇩🇪',
    'it': '🇮🇹',
    'pt': '🇵🇹',
  };

  /// Initialise le service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    
    // Charger la locale sauvegardée ou détecter celle du téléphone
    final savedLocale = _prefs.getString(_localeKey);
    if (savedLocale != null) {
      _currentLocale = _parseLocale(savedLocale);
    } else {
      // Première ouverture : détecter la langue du téléphone
      _currentLocale = getDeviceLocale();
      await _prefs.setString(_localeKey, _localeToString(_currentLocale));
    }
    
    _isInitialized = true;
  }

  /// Récupère la locale actuelle
  Locale get currentLocale => _currentLocale;

  /// Détecte la langue du téléphone et retourne la locale correspondante
  Locale getDeviceLocale() {
    final deviceLocale = PlatformDispatcher.instance.locale;
    final languageCode = deviceLocale.languageCode;
    
    // Vérifier si la langue du téléphone est supportée
    for (final locale in supportedLocales) {
      if (locale.languageCode == languageCode) {
        return locale;
      }
    }
    
    // Par défaut, retourner l'anglais
    return const Locale('en', 'US');
  }

  /// Change la locale
  Future<void> setLocale(Locale locale) async {
    if (!_isSupported(locale)) {
      throw Exception('Locale non supportée: ${locale.languageCode}');
    }
    
    _currentLocale = locale;
    await _prefs.setString(_localeKey, _localeToString(locale));
  }

  /// Vérifie si une locale est supportée
  bool _isSupported(Locale locale) {
    return supportedLocales.any(
      (l) => l.languageCode == locale.languageCode,
    );
  }

  /// Parse une locale depuis une string
  Locale _parseLocale(String localeString) {
    final parts = localeString.split('_');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    }
    return Locale(parts[0]);
  }

  /// Convertit une locale en string
  String _localeToString(Locale locale) {
    if (locale.countryCode != null) {
      return '${locale.languageCode}_${locale.countryCode}';
    }
    return locale.languageCode;
  }

  /// Récupère le nom de la langue
  String getLocaleName(Locale locale) {
    return localeNames[locale.languageCode] ?? locale.languageCode;
  }

  /// Récupère le drapeau de la langue
  String getLocaleFlag(Locale locale) {
    return localeFlags[locale.languageCode] ?? '🌐';
  }
}
