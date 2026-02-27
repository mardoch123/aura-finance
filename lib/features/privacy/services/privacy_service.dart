import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service de gestion de la confidentialité et du mode discret
class PrivacyService {
  PrivacyService._();
  
  static final PrivacyService _instance = PrivacyService._();
  static PrivacyService get instance => _instance;

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Clés de stockage
  static const String _stealthModeKey = 'privacy_stealth_mode';
  static const String _biometricLockKey = 'privacy_biometric_lock';
  static const String _hideBalanceKey = 'privacy_hide_balance';
  static const String _fakeAppIconKey = 'privacy_fake_app_icon';
  static const String _screenshotBlockKey = 'privacy_block_screenshots';
  static const String _autoLockTimeoutKey = 'privacy_auto_lock_timeout';
  static const String _lastAuthTimeKey = 'privacy_last_auth_time';
  static const String _disguiseModeKey = 'privacy_disguise_mode';

  // Stream pour notifier les changements
  final _privacyController = StreamController<PrivacySettings>.broadcast();
  Stream<PrivacySettings> get privacyStream => _privacyController.stream;

  PrivacySettings _currentSettings = const PrivacySettings();
  PrivacySettings get currentSettings => _currentSettings;

  // ═══════════════════════════════════════════════════════════
  // INITIALISATION
  // ═══════════════════════════════════════════════════════════

  /// Initialise le service et charge les paramètres
  Future<void> initialize() async {
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    _currentSettings = PrivacySettings(
      stealthModeEnabled: prefs.getBool(_stealthModeKey) ?? false,
      biometricLockEnabled: prefs.getBool(_biometricLockKey) ?? false,
      hideBalanceEnabled: prefs.getBool(_hideBalanceKey) ?? false,
      fakeAppIconEnabled: prefs.getBool(_fakeAppIconKey) ?? false,
      screenshotBlockEnabled: prefs.getBool(_screenshotBlockKey) ?? false,
      autoLockTimeoutMinutes: prefs.getInt(_autoLockTimeoutKey) ?? 5,
      disguiseMode: DisguiseMode.values[prefs.getInt(_disguiseModeKey) ?? 0],
    );
    
    _privacyController.add(_currentSettings);
  }

  // ═══════════════════════════════════════════════════════════
  // AUTHENTIFICATION BIOMÉTRIQUE
  // ═══════════════════════════════════════════════════════════

  /// Vérifie si l'authentification biométrique est disponible
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Liste les biométries disponibles
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Authentifie l'utilisateur
  Future<bool> authenticate({
    String localizedReason = 'Veuillez vous authentifier pour accéder à Aura Finance',
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    if (!_currentSettings.biometricLockEnabled) return true;

    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return true;

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Authentification requise',
            cancelButton: 'Annuler',
            biometricHint: 'Vérifiez votre identité',
            biometricNotRecognized: 'Non reconnu, réessayez',
            biometricRequiredTitle: 'Authentification biométrique requise',
            deviceCredentialsRequiredTitle: 'Identifiants requis',
            deviceCredentialsSetupDescription: 'Veuillez configurer un verrouillage',
            goToSettingsButton: 'Paramètres',
            goToSettingsDescription: 'Veuillez configurer l\'authentification',
          ),
          IOSAuthMessages(
            cancelButton: 'Annuler',
            goToSettingsButton: 'Paramètres',
            goToSettingsDescription: 'Veuillez configurer Face ID/Touch ID',
            lockOut: 'Veuillez réactiver Face ID/Touch ID',
          ),
        ],
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: false,
        ),
      );

      if (didAuthenticate) {
        await _updateLastAuthTime();
      }

      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }

  /// Vérifie si une ré-authentification est nécessaire
  Future<bool> needsReauthentication() async {
    if (!_currentSettings.biometricLockEnabled) return false;

    final prefs = await SharedPreferences.getInstance();
    final lastAuthStr = prefs.getString(_lastAuthTimeKey);
    
    if (lastAuthStr == null) return true;

    final lastAuth = DateTime.tryParse(lastAuthStr);
    if (lastAuth == null) return true;

    final elapsed = DateTime.now().difference(lastAuth);
    return elapsed.inMinutes >= _currentSettings.autoLockTimeoutMinutes;
  }

  Future<void> _updateLastAuthTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastAuthTimeKey, DateTime.now().toIso8601String());
  }

  // ═══════════════════════════════════════════════════════════
  // MODE DISCRET (STEALTH)
  // ═══════════════════════════════════════════════════════════

  /// Active/désactive le mode discret
  Future<void> setStealthMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_stealthModeKey, enabled);
    
    _currentSettings = _currentSettings.copyWith(stealthModeEnabled: enabled);
    _privacyController.add(_currentSettings);
  }

  /// Change le mode de déguisement
  Future<void> setDisguiseMode(DisguiseMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_disguiseModeKey, mode.index);
    
    _currentSettings = _currentSettings.copyWith(disguiseMode: mode);
    _privacyController.add(_currentSettings);
  }

  /// Active le mode calculatrice (déguisement)
  Future<void> enableCalculatorDisguise() async {
    await setDisguiseMode(DisguiseMode.calculator);
    await setStealthMode(true);
  }

  /// Active le mode notes (déguisement)
  Future<void> enableNotesDisguise() async {
    await setDisguiseMode(DisguiseMode.notes);
    await setStealthMode(true);
  }

  /// Active le mode météo (déguisement)
  Future<void> enableWeatherDisguise() async {
    await setDisguiseMode(DisguiseMode.weather);
    await setStealthMode(true);
  }

  // ═══════════════════════════════════════════════════════════
  // MASQUAGE DU SOLDE
  // ═══════════════════════════════════════════════════════════

  /// Active/désactive le masquage du solde
  Future<void> setHideBalance(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hideBalanceKey, enabled);
    
    _currentSettings = _currentSettings.copyWith(hideBalanceEnabled: enabled);
    _privacyController.add(_currentSettings);
  }

  /// Bascule le masquage du solde
  Future<void> toggleHideBalance() async {
    await setHideBalance(!_currentSettings.hideBalanceEnabled);
  }

  /// Formate un montant selon les paramètres de confidentialité
  String formatAmount(double amount, {String symbol = '€'}) {
    if (_currentSettings.hideBalanceEnabled) {
      return '•••• $symbol';
    }
    return '${amount.toStringAsFixed(2)} $symbol';
  }

  // ═══════════════════════════════════════════════════════════
  // VERROUILLAGE BIOMÉTRIQUE
  // ═══════════════════════════════════════════════════════════

  /// Active/désactive le verrouillage biométrique
  Future<void> setBiometricLock(bool enabled) async {
    if (enabled) {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        throw PrivacyException('L\'authentification biométrique n\'est pas disponible');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricLockKey, enabled);
    
    _currentSettings = _currentSettings.copyWith(biometricLockEnabled: enabled);
    _privacyController.add(_currentSettings);

    if (enabled) {
      await _updateLastAuthTime();
    }
  }

  /// Définit le délai de verrouillage automatique
  Future<void> setAutoLockTimeout(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_autoLockTimeoutKey, minutes);
    
    _currentSettings = _currentSettings.copyWith(autoLockTimeoutMinutes: minutes);
    _privacyController.add(_currentSettings);
  }

  // ═══════════════════════════════════════════════════════════
  // BLOCAGE CAPTURES D'ÉCRAN
  // ═══════════════════════════════════════════════════════════

  /// Active/désactive le blocage des captures d'écran
  Future<void> setScreenshotBlock(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_screenshotBlockKey, enabled);
    
    _currentSettings = _currentSettings.copyWith(screenshotBlockEnabled: enabled);
    _privacyController.add(_currentSettings);

    // Appliquer le flag sur l'app
    if (enabled) {
      await _enableSecureFlag();
    } else {
      await _disableSecureFlag();
    }
  }

  Future<void> _enableSecureFlag() async {
    // Note: Cette fonctionnalité nécessite une configuration native
    // Sur Android: FLAG_SECURE
    // Sur iOS: UITextField avec secureTextEntry
    // Pour Flutter, on utilise une méthode channel
    try {
      const platform = MethodChannel('com.aura.finance/privacy');
      await platform.invokeMethod('enableSecureFlag');
    } catch (e) {
      // La méthode native n'est peut-être pas implémentée
    }
  }

  Future<void> _disableSecureFlag() async {
    try {
      const platform = MethodChannel('com.aura.finance/privacy');
      await platform.invokeMethod('disableSecureFlag');
    } catch (e) {
      // La méthode native n'est peut-être pas implémentée
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ICÔNE D'APPLICATION FAUSSE
  // ═══════════════════════════════════════════════════════════

  /// Active/désactive l'icône d'application fausse
  /// Note: Cette fonctionnalité nécessite une configuration spécifique
  /// sur iOS (alternate app icons) et Android (activity-alias)
  Future<void> setFakeAppIcon(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fakeAppIconKey, enabled);
    
    _currentSettings = _currentSettings.copyWith(fakeAppIconEnabled: enabled);
    _privacyController.add(_currentSettings);

    // Changer l'icône de l'app
    await _changeAppIcon(enabled);
  }

  Future<void> _changeAppIcon(bool useFakeIcon) async {
    try {
      const platform = MethodChannel('com.aura.finance/privacy');
      await platform.invokeMethod('changeAppIcon', {
        'iconName': useFakeIcon ? 'calculator' : 'default',
      });
    } catch (e) {
      // La méthode native n'est peut-être pas implémentée
    }
  }

  // ═══════════════════════════════════════════════════════════
  // UTILITAIRES
  // ═══════════════════════════════════════════════════════════

  /// Réinitialise tous les paramètres de confidentialité
  Future<void> resetAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stealthModeKey);
    await prefs.remove(_biometricLockKey);
    await prefs.remove(_hideBalanceKey);
    await prefs.remove(_fakeAppIconKey);
    await prefs.remove(_screenshotBlockKey);
    await prefs.remove(_autoLockTimeoutKey);
    await prefs.remove(_disguiseModeKey);
    
    _currentSettings = const PrivacySettings();
    _privacyController.add(_currentSettings);
  }

  /// Efface toutes les données sensibles en cas d'urgence
  Future<void> emergencyDataWipe() async {
    // Effacer le stockage sécurisé
    await _secureStorage.deleteAll();
    
    // Réinitialiser les paramètres
    await resetAllSettings();
    
    // Notifier
    _privacyController.add(_currentSettings);
  }

  void dispose() {
    _privacyController.close();
  }
}

/// Paramètres de confidentialité
class PrivacySettings {
  final bool stealthModeEnabled;
  final bool biometricLockEnabled;
  final bool hideBalanceEnabled;
  final bool fakeAppIconEnabled;
  final bool screenshotBlockEnabled;
  final int autoLockTimeoutMinutes;
  final DisguiseMode disguiseMode;

  const PrivacySettings({
    this.stealthModeEnabled = false,
    this.biometricLockEnabled = false,
    this.hideBalanceEnabled = false,
    this.fakeAppIconEnabled = false,
    this.screenshotBlockEnabled = false,
    this.autoLockTimeoutMinutes = 5,
    this.disguiseMode = DisguiseMode.none,
  });

  PrivacySettings copyWith({
    bool? stealthModeEnabled,
    bool? biometricLockEnabled,
    bool? hideBalanceEnabled,
    bool? fakeAppIconEnabled,
    bool? screenshotBlockEnabled,
    int? autoLockTimeoutMinutes,
    DisguiseMode? disguiseMode,
  }) {
    return PrivacySettings(
      stealthModeEnabled: stealthModeEnabled ?? this.stealthModeEnabled,
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
      hideBalanceEnabled: hideBalanceEnabled ?? this.hideBalanceEnabled,
      fakeAppIconEnabled: fakeAppIconEnabled ?? this.fakeAppIconEnabled,
      screenshotBlockEnabled: screenshotBlockEnabled ?? this.screenshotBlockEnabled,
      autoLockTimeoutMinutes: autoLockTimeoutMinutes ?? this.autoLockTimeoutMinutes,
      disguiseMode: disguiseMode ?? this.disguiseMode,
    );
  }
}

/// Modes de déguisement
enum DisguiseMode {
  none,
  calculator,
  notes,
  weather,
  calendar,
}

extension DisguiseModeInfo on DisguiseMode {
  String get displayName {
    switch (this) {
      case DisguiseMode.none:
        return 'Normal (Aura Finance)';
      case DisguiseMode.calculator:
        return '🧮 Calculatrice';
      case DisguiseMode.notes:
        return '📝 Notes';
      case DisguiseMode.weather:
        return '🌤️ Météo';
      case DisguiseMode.calendar:
        return '📅 Calendrier';
    }
  }

  String get iconName {
    switch (this) {
      case DisguiseMode.none:
        return 'aura';
      case DisguiseMode.calculator:
        return 'calculator';
      case DisguiseMode.notes:
        return 'notes';
      case DisguiseMode.weather:
        return 'weather';
      case DisguiseMode.calendar:
        return 'calendar';
    }
  }
}

/// Exception de confidentialité
class PrivacyException implements Exception {
  final String message;
  PrivacyException(this.message);

  @override
  String toString() => 'PrivacyException: $message';
}

/// Widget pour afficher un montant masquable
class PrivacyProtectedAmount extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final String symbol;

  const PrivacyProtectedAmount({
    super.key,
    required this.amount,
    this.style,
    this.symbol = '€',
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PrivacySettings>(
      stream: PrivacyService.instance.privacyStream,
      initialData: PrivacyService.instance.currentSettings,
      builder: (context, snapshot) {
        final settings = snapshot.data ?? const PrivacySettings();
        final displayText = settings.hideBalanceEnabled
            ? '•••• $symbol'
            : '${amount.toStringAsFixed(2)} $symbol';

        return Text(
          displayText,
          style: style,
        );
      },
    );
  }
}
