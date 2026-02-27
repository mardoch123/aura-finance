import 'package:freezed_annotation/freezed_annotation.dart';

part 'banking_models.freezed.dart';
part 'banking_models.g.dart';

/// Institution bancaire supportée
@freezed
class BankInstitution with _$BankInstitution {
  const factory BankInstitution({
    required String id,
    required String name,
    required String countryCode,
    required String logoUrl,
    required List<String> supportedFeatures,
    required List<String> availableScopes,
    String? bic,
    String? website,
  }) = _BankInstitution;

  factory BankInstitution.fromJson(Map<String, dynamic> json) =>
      _$BankInstitutionFromJson(json);
}

/// Compte bancaire connecté
@freezed
class ConnectedBankAccount with _$ConnectedBankAccount {
  const factory ConnectedBankAccount({
    required String id,
    required String userId,
    required String institutionId,
    required String institutionName,
    required String accountId,
    required String accountName,
    required String accountType,
    required String currency,
    required String iban,
    double? currentBalance,
    double? availableBalance,
    DateTime? lastSyncAt,
    required String connectionStatus,
    required DateTime createdAt,
    String? logoUrl,
    String? provider, // truelayer, bridge, plaid
    String? providerConnectionId,
    @Default(true) bool isActive,
    @Default(false) bool isDefault,
  }) = _ConnectedBankAccount;

  factory ConnectedBankAccount.fromJson(Map<String, dynamic> json) =>
      _$ConnectedBankAccountFromJson(json);
}

/// Transaction bancaire importée
@freezed
class BankTransaction with _$BankTransaction {
  const factory BankTransaction({
    required String id,
    required String accountId,
    required String userId,
    required String externalId,
    required DateTime transactionDate,
    required DateTime bookingDate,
    required double amount,
    required String currency,
    required String description,
    String? counterpartyName,
    String? counterpartyAccount,
    String? reference,
    String? merchantName,
    String? merchantCategory,
    String? transactionType,
    String? status,
    String? source, // banking, manual, scan
    DateTime? importedAt,
    String? auraTransactionId, // Lien vers transaction interne
    @Default(false) bool isCategorized,
    String? suggestedCategory,
    double? categorizationConfidence,
    @Default(false) bool isDuplicate,
    String? duplicateOfId,
  }) = _BankTransaction;

  factory BankTransaction.fromJson(Map<String, dynamic> json) =>
      _$BankTransactionFromJson(json);
}

/// Résultat de synchronisation
@freezed
class SyncResult with _$SyncResult {
  const factory SyncResult({
    required bool success,
    required int transactionsImported,
    required int transactionsUpdated,
    required int duplicatesDetected,
    required int categorizedByAI,
    required DateTime syncDate,
    String? errorMessage,
    List<String>? warnings,
  }) = _SyncResult;

  factory SyncResult.fromJson(Map<String, dynamic> json) =>
      _$SyncResultFromJson(json);
}

/// Statut de connexion bancaire
enum BankConnectionStatus {
  pending,
  connected,
  expired,
  error,
  disconnected,
}

extension BankConnectionStatusInfo on BankConnectionStatus {
  String get displayName {
    switch (this) {
      case BankConnectionStatus.pending:
        return 'En attente';
      case BankConnectionStatus.connected:
        return 'Connecté';
      case BankConnectionStatus.expired:
        return 'Expiré';
      case BankConnectionStatus.error:
        return 'Erreur';
      case BankConnectionStatus.disconnected:
        return 'Déconnecté';
    }
  }

  String get icon {
    switch (this) {
      case BankConnectionStatus.pending:
        return '⏳';
      case BankConnectionStatus.connected:
        return '✅';
      case BankConnectionStatus.expired:
        return '⏰';
      case BankConnectionStatus.error:
        return '❌';
      case BankConnectionStatus.disconnected:
        return '🔌';
    }
  }
}

/// Types de comptes bancaires
enum BankAccountType {
  checking,
  savings,
  creditCard,
  loan,
  investment,
  unknown,
}

extension BankAccountTypeInfo on BankAccountType {
  String get displayName {
    switch (this) {
      case BankAccountType.checking:
        return 'Compte courant';
      case BankAccountType.savings:
        return 'Livret d\'épargne';
      case BankAccountType.creditCard:
        return 'Carte de crédit';
      case BankAccountType.loan:
        return 'Prêt';
      case BankAccountType.investment:
        return 'Compte titre';
      case BankAccountType.unknown:
        return 'Autre';
    }
  }

  String get icon {
    switch (this) {
      case BankAccountType.checking:
        return '💳';
      case BankAccountType.savings:
        return '🏦';
      case BankAccountType.creditCard:
        return '💳';
      case BankAccountType.loan:
        return '📄';
      case BankAccountType.investment:
        return '📈';
      case BankAccountType.unknown:
        return '🏛️';
    }
  }
}

/// Banques françaises populaires
class FrenchBanks {
  static const List<Map<String, dynamic>> banks = [
    {
      'id': 'bnpparibas',
      'name': 'BNP Paribas',
      'logo': 'https://logo.clearbit.com/bnpparibas.fr',
      'features': ['accounts', 'transactions', 'balance'],
    },
    {
      'id': 'sg',
      'name': 'Société Générale',
      'logo': 'https://logo.clearbit.com/particuliers.societegenerale.fr',
      'features': ['accounts', 'transactions', 'balance'],
    },
    {
      'id': 'creditagricole',
      'name': 'Crédit Agricole',
      'logo': 'https://logo.clearbit.com/credit-agricole.fr',
      'features': ['accounts', 'transactions', 'balance'],
    },
    {
      'id': 'lcl',
      'name': 'LCL',
      'logo': 'https://logo.clearbit.com/lcl.fr',
      'features': ['accounts', 'transactions', 'balance'],
    },
    {
      'id': 'caissedepargne',
      'name': 'Caisse d\'Épargne',
      'logo': 'https://logo.clearbit.com/caisse-epargne.fr',
      'features': ['accounts', 'transactions', 'balance'],
    },
    {
      'id': 'banquepopulaire',
      'name': 'Banque Populaire',
      'logo': 'https://logo.clearbit.com/banquepopulaire.fr',
      'features': ['accounts', 'transactions', 'balance'],
    },
    {
      'id': 'boursorama',
      'name': 'Boursorama Banque',
      'logo': 'https://logo.clearbit.com/boursorama-banque.com',
      'features': ['accounts', 'transactions', 'balance'],
    },
    {
      'id': 'hellobank',
      'name': 'Hello bank!',
      'logo': 'https://logo.clearbit.com/hellobank.fr',
      'features': ['accounts', 'transactions', 'balance'],
    },
    {
      'id': 'monabanq',
      'name': 'Monabanq',
      'logo': 'https://logo.clearbit.com/monabanq.fr',
      'features': ['accounts', 'transactions', 'balance'],
    },
    {
      'id': 'fortuneo',
      'name': 'Fortuneo',
      'logo': 'https://logo.clearbit.com/fortuneo.fr',
      'features': ['accounts', 'transactions', 'balance'],
    },
    {
      'id': 'ingdirect',
      'name': 'ING Direct',
      'logo': 'https://logo.clearbit.com/ing.fr',
      'features': ['accounts', 'transactions', 'balance'],
    },
    {
      'id': 'n26',
      'name': 'N26',
      'logo': 'https://logo.clearbit.com/n26.com',
      'features': ['accounts', 'transactions', 'balance'],
    },
    {
      'id': 'revolut',
      'name': 'Revolut',
      'logo': 'https://logo.clearbit.com/revolut.com',
      'features': ['accounts', 'transactions', 'balance'],
    },
    {
      'id': 'boursobank',
      'name': 'BoursoBank',
      'logo': 'https://logo.clearbit.com/boursobank.com',
      'features': ['accounts', 'transactions', 'balance'],
    },
    {
      'id': 'orangebank',
      'name': 'Orange Bank',
      'logo': 'https://logo.clearbit.com/orangebank.fr',
      'features': ['accounts', 'transactions', 'balance'],
    },
    {
      'id': 'hsbc',
      'name': 'HSBC France',
      'logo': 'https://logo.clearbit.com/hsbc.fr',
      'features': ['accounts', 'transactions', 'balance'],
    },
    {
      'id': 'barclays',
      'name': 'Barclays France',
      'logo': 'https://logo.clearbit.com/barclays.fr',
      'features': ['accounts', 'transactions', 'balance'],
    },
    {
      'id': 'comptenickel',
      'name': 'Compte Nickel',
      'logo': 'https://logo.clearbit.com/compte-nickel.fr',
      'features': ['accounts', 'transactions', 'balance'],
    },
  ];

  static List<Map<String, dynamic>> search(String query) {
    final lowerQuery = query.toLowerCase();
    return banks
        .where((bank) =>
            bank['name'].toString().toLowerCase().contains(lowerQuery) ||
            bank['id'].toString().toLowerCase().contains(lowerQuery))
        .toList();
  }
}

/// Configuration des providers Open Banking
class OpenBankingConfig {
  // TrueLayer (Europe)
  static const String truelayerClientId = 'YOUR_TRUELAYER_CLIENT_ID';
  static const String truelayerRedirectUri = 'aura.finance://callback/truelayer';
  static const List<String> truelayerScopes = [
    'accounts',
    'balance',
    'transactions',
    'offline_access',
  ];

  // Bridge (France/Europe)
  static const String bridgeClientId = 'YOUR_BRIDGE_CLIENT_ID';
  static const String bridgeRedirectUri = 'aura.finance://callback/bridge';

  // Plaid (US/UK/Europe)
  static const String plaidClientId = 'YOUR_PLAID_CLIENT_ID';
  static const String plaidEnvironment = 'sandbox'; // sandbox, development, production

  static String getProviderForCountry(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'FR':
      case 'DE':
      case 'ES':
      case 'IT':
      case 'NL':
      case 'BE':
        return 'bridge'; // Bridge a une excellente couverture en Europe
      case 'GB':
      case 'IE':
        return 'truelayer';
      case 'US':
      case 'CA':
        return 'plaid';
      default:
        return 'bridge';
    }
  }
}

/// Résultat de catégorisation IA
@freezed
class CategorizationResult with _$CategorizationResult {
  const factory CategorizationResult({
    required String category,
    required String subcategory,
    required double confidence,
    required List<String> keywords,
    String? merchantLogo,
    String? merchantWebsite,
  }) = _CategorizationResult;

  factory CategorizationResult.fromJson(Map<String, dynamic> json) =>
      _$CategorizationResultFromJson(json);
}

/// Détection de doublon
@freezed
class DuplicateCheckResult with _$DuplicateCheckResult {
  const factory DuplicateCheckResult({
    required bool isDuplicate,
    String? duplicateTransactionId,
    required double similarityScore,
    required List<String> matchingFields,
  }) = _DuplicateCheckResult;

  factory DuplicateCheckResult.fromJson(Map<String, dynamic> json) =>
      _$DuplicateCheckResultFromJson(json);
}
