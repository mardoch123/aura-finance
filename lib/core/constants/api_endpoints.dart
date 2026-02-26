/// Endpoints API et configurations
class ApiEndpoints {
  ApiEndpoints._();

  // ═══════════════════════════════════════════════════════════
  // SUPABASE
  // ═══════════════════════════════════════════════════════════

  static const String supabaseUrl = 'https://jrxecafbflclmfyxrwul.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_A-BqyphR6NhVhPuzALiGJw_7DgCE7Bl';

  // ═══════════════════════════════════════════════════════════
  // EDGE FUNCTIONS
  // ═══════════════════════════════════════════════════════════

  static const String functionsBase = '/functions/v1';

  // Scan et OCR
  static const String scanReceipt = '$functionsBase/scan-receipt';
  static const String processVoice = '$functionsBase/process-voice';

  // IA et Prédictions
  static const String predictBalance = '$functionsBase/predict-balance';
  static const String detectVampires = '$functionsBase/detect-vampires';
  static const String generateInsights = '$functionsBase/generate-insights';
  static const String categorizeTransaction =
      '$functionsBase/categorize-transaction';

  // Coach IA
  static const String chatWithCoach = '$functionsBase/chat-coach';
  static const String getFinancialAdvice = '$functionsBase/financial-advice';

  // ═══════════════════════════════════════════════════════════
  // STORAGE
  // ═══════════════════════════════════════════════════════════

  static const String storageReceipts = 'receipts';
  static const String storageAvatars = 'avatars';
  static const String storageExports = 'exports';

  // ═══════════════════════════════════════════════════════════
  // API EXTERNES
  // ═══════════════════════════════════════════════════════════

  // Taux de change
  static const String exchangeRateApi =
      'https://api.exchangerate-api.com/v4/latest';

  // ═══════════════════════════════════════════════════════════
  // TIMEOUTS
  // ═══════════════════════════════════════════════════════════

  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 2);
  static const Duration aiTimeout = Duration(seconds: 60);

  // ═══════════════════════════════════════════════════════════
  // LIMITES
  // ═══════════════════════════════════════════════════════════

  static const int maxUploadSize = 10 * 1024 * 1024; // 10 MB
  static const int maxTransactionsPerPage = 50;
  static const int maxInsightsPerPage = 20;
}

/// Configuration de l'application
class AppConfig {
  AppConfig._();

  // ═══════════════════════════════════════════════════════════
  // APP INFO
  // ═══════════════════════════════════════════════════════════

  static const String appName = 'Aura Finance';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // ═══════════════════════════════════════════════════════════
  // FEATURE FLAGS
  // ═══════════════════════════════════════════════════════════

  static const bool enableAI = true;
  static const bool enableScan = true;
  static const bool enableVoice = true;
  static const bool enablePredictions = true;
  static const bool enableVampireDetection = true;
  static const bool enableCoach = true;
  static const bool enableNotifications = true;

  // ═══════════════════════════════════════════════════════════
  // LIMITES
  // ═══════════════════════════════════════════════════════════

  static const int maxAccounts = 10;
  static const int maxCategories = 20;
  static const int maxBudgets = 5;
  static const int transactionHistoryMonths = 24;

  // ═══════════════════════════════════════════════════════════
  // DEVISES
  // ═══════════════════════════════════════════════════════════

  static const String defaultCurrency = 'EUR';
  static const List<String> supportedCurrencies = [
    'EUR',
    'USD',
    'GBP',
    'CHF',
    'CAD',
    'AUD',
    'JPY',
  ];

  static const Map<String, String> currencySymbols = {
    'EUR': '€',
    'USD': '\$',
    'GBP': '£',
    'CHF': 'CHF',
    'CAD': 'C\$',
    'AUD': 'A\$',
    'JPY': '¥',
  };

  static String getCurrencySymbol(String currency) {
    return currencySymbols[currency] ?? currency;
  }

  // ═══════════════════════════════════════════════════════════
  // FORMATS
  // ═══════════════════════════════════════════════════════════

  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String monthYearFormat = 'MMMM yyyy';
  static const String shortDateFormat = 'dd/MM';
  static const String isoDateFormat = 'yyyy-MM-dd';
}

/// Messages d'erreur
class ErrorMessages {
  ErrorMessages._();

  static const String genericError =
      'Une erreur est survenue. Veuillez réessayer.';
  static const String networkError =
      'Problème de connexion. Vérifiez votre réseau.';
  static const String timeoutError =
      'La requête a pris trop de temps. Veuillez réessayer.';
  static const String authError = 'Identifiants incorrects.';
  static const String notFoundError = 'Ressource non trouvée.';
  static const String permissionError = 'Accès non autorisé.';
  static const String validationError = 'Veuillez vérifier vos informations.';
  static const String scanError =
      'Impossible de lire le document. Veuillez réessayer.';
  static const String uploadError =
      'Erreur lors du téléchargement. Vérifiez la taille du fichier.';
  static const String aiError =
      'Le service IA est temporairement indisponible.';
}

/// Messages de succès
class SuccessMessages {
  SuccessMessages._();

  static const String transactionAdded = 'Transaction ajoutée avec succès !';
  static const String transactionUpdated = 'Transaction mise à jour.';
  static const String transactionDeleted = 'Transaction supprimée.';
  static const String accountCreated = 'Compte créé avec succès.';
  static const String accountUpdated = 'Compte mis à jour.';
  static const String budgetCreated = 'Budget créé avec succès.';
  static const String settingsSaved = 'Paramètres enregistrés.';
  static const String profileUpdated = 'Profil mis à jour.';
  static const String scanSuccess = 'Document scanné avec succès !';
  static const String exportSuccess = 'Export réussi !';
  static const String subscriptionCancelled = 'Abonnement résilié.';
}
