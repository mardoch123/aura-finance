import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/notification_service.dart';
import '../domain/banking_models.dart';
import 'open_banking_provider.dart';
import 'transaction_categorization_service.dart';
import 'duplicate_detection_service.dart';

/// Service principal de synchronisation bancaire
class BankingService {
  BankingService._();
  
  static final BankingService _instance = BankingService._();
  static BankingService get instance => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;
  final TransactionCategorizationService _categorization = 
      TransactionCategorizationService.instance;
  final DuplicateDetectionService _duplicateDetection = 
      DuplicateDetectionService.instance;

  // Stream pour notifier les changements
  final _syncController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStream => _syncController.stream;

  SyncStatus _currentStatus = const SyncStatus.idle();
  SyncStatus get currentStatus => _currentStatus;

  // ═══════════════════════════════════════════════════════════
  // CONNEXION BANCAIRE
  // ═══════════════════════════════════════════════════════════

  /// Initialise la connexion avec une banque
  Future<String> connectBank({
    required String institutionId,
    String provider = 'bridge',
    String? userId,
  }) async {
    try {
      _updateStatus(const SyncStatus.connecting());

      final uid = userId ?? _supabase.auth.currentUser?.id;
      if (uid == null) throw Exception('User not authenticated');

      // Créer le provider Open Banking
      final openBanking = OpenBankingProviderFactory.create(provider);

      // Initialiser la connexion OAuth
      final authUrl = await openBanking.initializeConnection(institutionId);

      _updateStatus(const SyncStatus.awaitingAuth());

      return authUrl;
    } catch (e) {
      _updateStatus(SyncStatus.error(e.toString()));
      rethrow;
    }
  }

  /// Gère le callback OAuth après connexion
  Future<ConnectedBankAccount> handleOAuthCallback({
    required String code,
    required String institutionId,
    required String provider,
    String? userId,
  }) async {
    try {
      _updateStatus(const SyncStatus.authenticating());

      final uid = userId ?? _supabase.auth.currentUser?.id;
      if (uid == null) throw Exception('User not authenticated');

      // Échanger le code contre un token
      final openBanking = OpenBankingProviderFactory.create(provider);
      final token = await openBanking.exchangeCode(code);

      // Récupérer les comptes
      final accounts = await openBanking.getAccounts(token.accessToken);

      if (accounts.isEmpty) {
        throw Exception('No accounts found');
      }

      // Sauvegarder la connexion (premier compte par défaut)
      final account = accounts.first;
      final balance = await openBanking.getBalance(token.accessToken, account.id);

      final connectedAccount = ConnectedBankAccount(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: uid,
        institutionId: institutionId,
        institutionName: _getInstitutionName(institutionId),
        accountId: account.id,
        accountName: account.name,
        accountType: account.type,
        currency: account.currency,
        iban: account.iban ?? '',
        currentBalance: balance.current,
        availableBalance: balance.available,
        connectionStatus: 'connected',
        createdAt: DateTime.now(),
        provider: provider,
        providerConnectionId: token.accessToken,
        isActive: true,
        logoUrl: _getInstitutionLogo(institutionId),
      );

      // Sauvegarder dans Supabase
      await _saveConnectedAccount(connectedAccount);

      _updateStatus(const SyncStatus.connected());

      // Lancer la première sync
      await syncTransactions(accountId: connectedAccount.id);

      return connectedAccount;
    } catch (e) {
      _updateStatus(SyncStatus.error(e.toString()));
      rethrow;
    }
  }

  /// Déconnecte un compte bancaire
  Future<void> disconnectAccount(String accountId) async {
    try {
      final account = await getConnectedAccount(accountId);
      if (account == null) return;

      // Supprimer la connexion chez le provider
      if (account.providerConnectionId != null) {
        final openBanking = OpenBankingProviderFactory.create(account.provider!);
        await openBanking.deleteConnection(account.providerConnectionId!);
      }

      // Marquer comme déconnecté dans Supabase
      await _supabase.from('connected_bank_accounts').update({
        'connection_status': 'disconnected',
        'is_active': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', accountId);

      NotificationService.instance.showNotification(
        id: 3001,
        title: '🔌 Banque déconnectée',
        body: '${account.institutionName} a été déconnectée',
      );
    } catch (e) {
      print('Error disconnecting account: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SYNCHRONISATION DES TRANSACTIONS
  // ═══════════════════════════════════════════════════════════

  /// Synchronise les transactions d'un compte
  Future<SyncResult> syncTransactions({
    String? accountId,
    DateTime? fromDate,
    DateTime? toDate,
    bool categorize = true,
    bool detectDuplicates = true,
  }) async {
    try {
      _updateStatus(const SyncStatus.syncing(progress: 0));

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Récupérer les comptes à synchroniser
      final accounts = accountId != null
          ? [await getConnectedAccount(accountId)].whereType<ConnectedBankAccount>()
          : await getConnectedAccounts(userId);

      if (accounts.isEmpty) {
        return const SyncResult(
          success: true,
          transactionsImported: 0,
          transactionsUpdated: 0,
          duplicatesDetected: 0,
          categorizedByAI: 0,
          syncDate: null,
        );
      }

      int totalImported = 0;
      int totalUpdated = 0;
      int totalDuplicates = 0;
      int totalCategorized = 0;
      final warnings = <String>[];

      for (int i = 0; i < accounts.length; i++) {
        final account = accounts.elementAt(i);
        
        // Mettre à jour la progression
        final progress = (i / accounts.length * 100).round();
        _updateStatus(SyncStatus.syncing(progress: progress));

        // Vérifier si le token est valide
        if (account.providerConnectionId == null) {
          warnings.add('Token manquant pour ${account.institutionName}');
          continue;
        }

        try {
          final openBanking = OpenBankingProviderFactory.create(account.provider!);

          // Déterminer la date de début
          final syncFromDate = fromDate ?? await _getLastSyncDate(account.id);

          // Récupérer les transactions
          final transactions = await openBanking.getTransactions(
            account.providerConnectionId!,
            account.accountId,
            fromDate: syncFromDate,
            toDate: toDate,
          );

          // Traiter les transactions
          for (final tx in transactions) {
            // Vérifier les doublons
            if (detectDuplicates) {
              final duplicateCheck = await _duplicateDetection.checkForDuplicate(
                userId: userId,
                amount: tx.amount,
                date: tx.date,
                description: tx.description,
                externalId: tx.id,
                source: 'banking',
              );

              if (duplicateCheck.isDuplicate) {
                totalDuplicates++;
                continue;
              }
            }

            // Catégoriser
            String? category;
            String? subcategory;
            double? confidence;

            if (categorize) {
              final catResult = await _categorization.categorizeTransaction(
                description: tx.description,
                counterpartyName: tx.counterpartyName,
                amount: tx.amount,
                reference: tx.reference,
              );

              category = catResult.category;
              subcategory = catResult.subcategory;
              confidence = catResult.confidence;
              totalCategorized++;
            }

            // Sauvegarder la transaction
            final existing = await _findExistingTransaction(userId, tx.id);
            
            if (existing != null) {
              // Mettre à jour
              await _updateTransaction(existing['id'], {
                'amount': tx.amount,
                'description': tx.description,
                'merchant': tx.counterpartyName,
                'category': category ?? existing['category'],
                'updated_at': DateTime.now().toIso8601String(),
              });
              totalUpdated++;
            } else {
              // Créer
              await _createTransaction({
                'user_id': userId,
                'account_id': account.id,
                'external_id': tx.id,
                'amount': tx.amount,
                'currency': tx.currency,
                'description': tx.description,
                'merchant': tx.counterpartyName,
                'date': tx.date.toIso8601String(),
                'category': category ?? 'other',
                'subcategory': subcategory,
                'source': 'banking',
                'ai_confidence': confidence,
                'is_categorized': categorize,
                'created_at': DateTime.now().toIso8601String(),
              });
              totalImported++;
            }
          }

          // Mettre à jour la date de dernière sync
          await _updateLastSyncDate(account.id);

        } catch (e) {
          warnings.add('Erreur ${account.institutionName}: $e');
        }
      }

      _updateStatus(const SyncStatus.completed());

      // Notification de succès
      if (totalImported > 0) {
        NotificationService.instance.showNotification(
          id: 3002,
          title: '✅ Sync bancaire',
          body: '$totalImported transactions importées',
        );
      }

      return SyncResult(
        success: true,
        transactionsImported: totalImported,
        transactionsUpdated: totalUpdated,
        duplicatesDetected: totalDuplicates,
        categorizedByAI: totalCategorized,
        syncDate: DateTime.now(),
        warnings: warnings.isNotEmpty ? warnings : null,
      );

    } catch (e) {
      _updateStatus(SyncStatus.error(e.toString()));
      return SyncResult(
        success: false,
        transactionsImported: 0,
        transactionsUpdated: 0,
        duplicatesDetected: 0,
        categorizedByAI: 0,
        syncDate: DateTime.now(),
        errorMessage: e.toString(),
      );
    }
  }

  /// Synchronisation automatique en arrière-plan
  Future<void> scheduleAutoSync({
    Duration interval = const Duration(hours: 6),
  }) async {
    // Cette méthode serait appelée par un work manager
    // Pour l'instant, on simule la planification
    Timer.periodic(interval, (timer) async {
      await syncTransactions();
    });
  }

  // ═══════════════════════════════════════════════════════════
  // GESTION DES COMPTES
  // ═══════════════════════════════════════════════════════════

  /// Récupère tous les comptes connectés d'un utilisateur
  Future<List<ConnectedBankAccount>> getConnectedAccounts(String userId) async {
    try {
      final result = await _supabase
          .from('connected_bank_accounts')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return result.map((json) => ConnectedBankAccount.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Récupère un compte spécifique
  Future<ConnectedBankAccount?> getConnectedAccount(String accountId) async {
    try {
      final result = await _supabase
          .from('connected_bank_accounts')
          .select()
          .eq('id', accountId)
          .maybeSingle();

      return result != null ? ConnectedBankAccount.fromJson(result) : null;
    } catch (e) {
      return null;
    }
  }

  /// Définit le compte par défaut
  Future<void> setDefaultAccount(String accountId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Retirer le statut par défaut des autres comptes
    await _supabase.from('connected_bank_accounts')
        .update({'is_default': false})
        .eq('user_id', userId);

    // Définir le nouveau défaut
    await _supabase.from('connected_bank_accounts')
        .update({'is_default': true})
        .eq('id', accountId);
  }

  // ═══════════════════════════════════════════════════════════
  // MÉTHODES PRIVÉES
  // ═══════════════════════════════════════════════════════════

  Future<void> _saveConnectedAccount(ConnectedBankAccount account) async {
    await _supabase.from('connected_bank_accounts').insert(account.toJson());
  }

  Future<DateTime?> _getLastSyncDate(String accountId) async {
    final account = await getConnectedAccount(accountId);
    return account?.lastSyncAt ?? DateTime.now().subtract(const Duration(days: 30));
  }

  Future<void> _updateLastSyncDate(String accountId) async {
    await _supabase.from('connected_bank_accounts').update({
      'last_sync_at': DateTime.now().toIso8601String(),
    }).eq('id', accountId);
  }

  Future<Map<String, dynamic>?> _findExistingTransaction(
    String userId,
    String externalId,
  ) async {
    return await _supabase
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .eq('external_id', externalId)
        .maybeSingle();
  }

  Future<void> _createTransaction(Map<String, dynamic> data) async {
    await _supabase.from('transactions').insert(data);
  }

  Future<void> _updateTransaction(String id, Map<String, dynamic> data) async {
    await _supabase.from('transactions').update(data).eq('id', id);
  }

  String _getInstitutionName(String institutionId) {
    final bank = FrenchBanks.banks.firstWhere(
      (b) => b['id'] == institutionId,
      orElse: () => {'name': 'Banque'},
    );
    return bank['name'];
  }

  String _getInstitutionLogo(String institutionId) {
    final bank = FrenchBanks.banks.firstWhere(
      (b) => b['id'] == institutionId,
      orElse: () => {'logo': ''},
    );
    return bank['logo'] ?? '';
  }

  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _syncController.add(status);
  }

  void dispose() {
    _syncController.close();
  }
}

/// Statut de synchronisation
class SyncStatus {
  final SyncState state;
  final int? progress;
  final String? error;

  const SyncStatus._({
    required this.state,
    this.progress,
    this.error,
  });

  const SyncStatus.idle() : this._(state: SyncState.idle);
  const SyncStatus.connecting() : this._(state: SyncState.connecting);
  const SyncStatus.awaitingAuth() : this._(state: SyncState.awaitingAuth);
  const SyncStatus.authenticating() : this._(state: SyncState.authenticating);
  const SyncStatus.connected() : this._(state: SyncState.connected);
  const SyncStatus.syncing({required int progress})
      : this._(state: SyncState.syncing, progress: progress);
  const SyncStatus.completed() : this._(state: SyncState.completed);
  const SyncStatus.error(String message)
      : this._(state: SyncState.error, error: message);

  bool get isIdle => state == SyncState.idle;
  bool get isConnecting => state == SyncState.connecting;
  bool get isSyncing => state == SyncState.syncing;
  bool get isCompleted => state == SyncState.completed;
  bool get hasError => state == SyncState.error;
}

enum SyncState {
  idle,
  connecting,
  awaitingAuth,
  authenticating,
  connected,
  syncing,
  completed,
  error,
}
