import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/banking_models.dart';

/// Interface pour les providers Open Banking
abstract class OpenBankingProvider {
  String get name;
  String get baseUrl;
  
  /// Initialise la connexion OAuth
  Future<String> initializeConnection(String institutionId);
  
  /// Échange le code contre un token
  Future<ConnectionToken> exchangeCode(String code);
  
  /// Rafraîchit le token
  Future<ConnectionToken> refreshToken(String refreshToken);
  
  /// Récupère les comptes
  Future<List<BankAccountInfo>> getAccounts(String accessToken);
  
  /// Récupère les transactions
  Future<List<BankTransactionInfo>> getTransactions(
    String accessToken,
    String accountId, {
    DateTime? fromDate,
    DateTime? toDate,
  });
  
  /// Récupère le solde
  Future<AccountBalance> getBalance(String accessToken, String accountId);
  
  /// Supprime la connexion
  Future<void> deleteConnection(String accessToken);
}

/// Token de connexion
class ConnectionToken {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String scope;

  ConnectionToken({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.scope,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Info compte bancaire
class BankAccountInfo {
  final String id;
  final String name;
  final String type;
  final String currency;
  final String? iban;
  final String? bic;

  BankAccountInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    this.iban,
    this.bic,
  });
}

/// Info transaction
class BankTransactionInfo {
  final String id;
  final DateTime date;
  final DateTime bookingDate;
  final double amount;
  final String currency;
  final String description;
  final String? counterpartyName;
  final String? reference;

  BankTransactionInfo({
    required this.id,
    required this.date,
    required this.bookingDate,
    required this.amount,
    required this.currency,
    required this.description,
    this.counterpartyName,
    this.reference,
  });
}

/// Solde compte
class AccountBalance {
  final double current;
  final double? available;
  final String currency;

  AccountBalance({
    required this.current,
    this.available,
    required this.currency,
  });
}

/// Implémentation Bridge (recommandé pour la France)
class BridgeProvider implements OpenBankingProvider {
  @override
  String get name => 'Bridge';
  
  @override
  String get baseUrl => 'https://api.bridgeapi.io/v2';

  final String _clientId;
  final String _clientSecret;
  final String _redirectUri;

  BridgeProvider({
    required String clientId,
    required String clientSecret,
    required String redirectUri,
  })  : _clientId = clientId,
        _clientSecret = clientSecret,
        _redirectUri = redirectUri;

  Map<String, String> get _headers => {
    'Client-Id': _clientId,
    'Client-Secret': _clientSecret,
    'Content-Type': 'application/json',
  };

  @override
  Future<String> initializeConnection(String institutionId) async {
    // Créer un utilisateur Bridge
    final userResponse = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: _headers,
    );

    if (userResponse.statusCode != 200) {
      throw Exception('Failed to create Bridge user: ${userResponse.body}');
    }

    final userData = jsonDecode(userResponse.body);
    final userId = userData['id'];
    final accessToken = userData['access_token'];

    // Créer la connexion
    final connectResponse = await http.post(
      Uri.parse('$baseUrl/connect/items/add'),
      headers: {..._headers, 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({
        'country': 'fr',
        'prefill_email': '', // Optionnel
      }),
    );

    if (connectResponse.statusCode != 200) {
      throw Exception('Failed to initialize connection: ${connectResponse.body}');
    }

    final connectData = jsonDecode(connectResponse.body);
    return connectData['redirect_url'];
  }

  @override
  Future<ConnectionToken> exchangeCode(String code) async {
    // Bridge utilise un mécanisme différent avec webhook
    // Cette méthode serait appelée par le webhook
    throw UnimplementedError('Bridge uses webhooks for authentication');
  }

  @override
  Future<ConnectionToken> refreshToken(String refreshToken) async {
    // Bridge gère le refresh automatiquement
    throw UnimplementedError('Bridge handles token refresh automatically');
  }

  @override
  Future<List<BankAccountInfo>> getAccounts(String accessToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/accounts'),
      headers: {..._headers, 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get accounts: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final accounts = data['resources'] as List;

    return accounts.map((account) => BankAccountInfo(
      id: account['id'].toString(),
      name: account['name'] ?? 'Compte',
      type: account['type'] ?? 'unknown',
      currency: account['currency_code'] ?? 'EUR',
      iban: account['iban'],
      bic: account['bic'],
    )).toList();
  }

  @override
  Future<List<BankTransactionInfo>> getTransactions(
    String accessToken,
    String accountId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final params = <String, String>{
      'limit': '500',
    };

    if (fromDate != null) {
      params['since'] = fromDate.toIso8601String().split('T')[0];
    }
    if (toDate != null) {
      params['until'] = toDate.toIso8601String().split('T')[0];
    }

    final uri = Uri.parse('$baseUrl/accounts/$accountId/transactions')
        .replace(queryParameters: params);

    final response = await http.get(
      uri,
      headers: {..._headers, 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get transactions: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final transactions = data['resources'] as List;

    return transactions.map((tx) => BankTransactionInfo(
      id: tx['id'].toString(),
      date: DateTime.parse(tx['date']),
      bookingDate: DateTime.parse(tx['date']),
      amount: (tx['amount'] as num).toDouble(),
      currency: tx['currency_code'] ?? 'EUR',
      description: tx['label'] ?? tx['raw_description'] ?? 'Transaction',
      counterpartyName: tx['label']?.toString().split(' ').first,
      reference: tx['id'].toString(),
    )).toList();
  }

  @override
  Future<AccountBalance> getBalance(String accessToken, String accountId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/accounts/$accountId'),
      headers: {..._headers, 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get balance: ${response.body}');
    }

    final data = jsonDecode(response.body);

    return AccountBalance(
      current: (data['balance'] as num).toDouble(),
      available: data['balance'] != null ? (data['balance'] as num).toDouble() : null,
      currency: data['currency_code'] ?? 'EUR',
    );
  }

  @override
  Future<void> deleteConnection(String accessToken) async {
    // Récupérer les items connectés
    final response = await http.get(
      Uri.parse('$baseUrl/items'),
      headers: {..._headers, 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['resources'] as List;

      // Supprimer chaque item
      for (final item in items) {
        await http.delete(
          Uri.parse('$baseUrl/items/${item['id']}'),
          headers: {..._headers, 'Authorization': 'Bearer $accessToken'},
        );
      }
    }
  }
}

/// Implémentation TrueLayer
class TrueLayerProvider implements OpenBankingProvider {
  @override
  String get name => 'TrueLayer';
  
  @override
  String get baseUrl => 'https://api.truelayer.com';

  final String _clientId;
  final String _clientSecret;
  final String _redirectUri;

  TrueLayerProvider({
    required String clientId,
    required String clientSecret,
    required String redirectUri,
  })  : _clientId = clientId,
        _clientSecret = clientSecret,
        _redirectUri = redirectUri;

  @override
  Future<String> initializeConnection(String institutionId) async {
    final params = {
      'response_type': 'code',
      'client_id': _clientId,
      'redirect_uri': _redirectUri,
      'scope': 'accounts balance transactions',
      'providers': 'uk-cs-mock', // Mock provider pour tests
      'disable_providers': '',
      'enable_open_banking_providers': 'true',
      'enable_credentials_sharing_providers': 'true',
    };

    final uri = Uri.parse('https://auth.truelayer.com/')
        .replace(queryParameters: params);

    return uri.toString();
  }

  @override
  Future<ConnectionToken> exchangeCode(String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/connect/token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'grant_type': 'authorization_code',
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'code': code,
        'redirect_uri': _redirectUri,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to exchange code: ${response.body}');
    }

    final data = jsonDecode(response.body);

    return ConnectionToken(
      accessToken: data['access_token'],
      refreshToken: data['refresh_token'],
      expiresAt: DateTime.now().add(Duration(seconds: data['expires_in'])),
      scope: data['scope'],
    );
  }

  @override
  Future<ConnectionToken> refreshToken(String refreshToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/connect/token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'grant_type': 'refresh_token',
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'refresh_token': refreshToken,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to refresh token: ${response.body}');
    }

    final data = jsonDecode(response.body);

    return ConnectionToken(
      accessToken: data['access_token'],
      refreshToken: data['refresh_token'],
      expiresAt: DateTime.now().add(Duration(seconds: data['expires_in'])),
      scope: data['scope'],
    );
  }

  @override
  Future<List<BankAccountInfo>> getAccounts(String accessToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/data/v1/accounts'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get accounts: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final accounts = data['results'] as List;

    return accounts.map((account) => BankAccountInfo(
      id: account['account_id'],
      name: account['display_name'] ?? 'Compte',
      type: account['account_type'] ?? 'unknown',
      currency: account['currency'] ?? 'EUR',
      iban: account['iban'],
      bic: account['swift_bic'],
    )).toList();
  }

  @override
  Future<List<BankTransactionInfo>> getTransactions(
    String accessToken,
    String accountId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final params = <String, String>{};
    if (fromDate != null) {
      params['from'] = fromDate.toIso8601String();
    }
    if (toDate != null) {
      params['to'] = toDate.toIso8601String();
    }

    var uri = Uri.parse('$baseUrl/data/v1/accounts/$accountId/transactions');
    if (params.isNotEmpty) {
      uri = uri.replace(queryParameters: params);
    }

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get transactions: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final transactions = data['results'] as List;

    return transactions.map((tx) => BankTransactionInfo(
      id: tx['transaction_id'],
      date: DateTime.parse(tx['timestamp']),
      bookingDate: DateTime.parse(tx['timestamp']),
      amount: (tx['amount'] as num).toDouble(),
      currency: tx['currency'] ?? 'EUR',
      description: tx['description'] ?? 'Transaction',
      counterpartyName: tx['merchant_name'] ?? tx['counterparty'],
      reference: tx['transaction_id'],
    )).toList();
  }

  @override
  Future<AccountBalance> getBalance(String accessToken, String accountId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/data/v1/accounts/$accountId/balance'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get balance: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final balance = data['results'][0];

    return AccountBalance(
      current: (balance['current'] as num).toDouble(),
      available: balance['available'] != null
          ? (balance['available'] as num).toDouble()
          : null,
      currency: balance['currency'] ?? 'EUR',
    );
  }

  @override
  Future<void> deleteConnection(String accessToken) async {
    await http.delete(
      Uri.parse('$baseUrl/api/v1/connection'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
  }
}

/// Factory pour créer le bon provider
class OpenBankingProviderFactory {
  static OpenBankingProvider create(String provider, {String? countryCode}) {
    switch (provider.toLowerCase()) {
      case 'bridge':
        return BridgeProvider(
          clientId: OpenBankingConfig.bridgeClientId,
          clientSecret: 'YOUR_BRIDGE_CLIENT_SECRET',
          redirectUri: OpenBankingConfig.bridgeRedirectUri,
        );
      case 'truelayer':
        return TrueLayerProvider(
          clientId: OpenBankingConfig.truelayerClientId,
          clientSecret: 'YOUR_TRUELAYER_CLIENT_SECRET',
          redirectUri: OpenBankingConfig.truelayerRedirectUri,
        );
      default:
        // Provider par défaut selon le pays
        final defaultProvider = countryCode != null
            ? OpenBankingConfig.getProviderForCountry(countryCode)
            : 'bridge';
        return create(defaultProvider);
    }
  }
}
