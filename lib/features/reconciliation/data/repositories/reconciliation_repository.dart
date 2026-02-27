import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reconciliation_models.dart';

class ReconciliationRepository {
  final SupabaseClient _supabase;

  ReconciliationRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  /// Récupérer les relevés bancaires
  Future<List<BankStatement>> getBankStatements(String accountId) async {
    final userId = _userId;
    if (userId == null) return [];

    final response = await _supabase
        .from('bank_statements')
        .select()
        .eq('account_id', accountId)
        .eq('user_id', userId)
        .order('statement_period_start', ascending: false);

    return (response as List)
        .map((e) => BankStatement.fromJson(e))
        .toList();
  }

  /// Uploader un relevé bancaire
  Future<BankStatement> uploadStatement({
    required String accountId,
    required DateTime periodStart,
    required DateTime periodEnd,
    required String fileName,
    required String filePath,
    required double openingBalance,
    required double closingBalance,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Non authentifié');

    // Upload du fichier
    final fileBytes = await _supabase.storage
        .from('bank-statements')
        .upload('$userId/$fileName', filePath as List<int>);

    final publicUrl = _supabase.storage
        .from('bank-statements')
        .getPublicUrl('$userId/$fileName');

    final response = await _supabase
        .from('bank_statements')
        .insert({
          'user_id': userId,
          'account_id': accountId,
          'statement_period_start': periodStart.toIso8601String(),
          'statement_period_end': periodEnd.toIso8601String(),
          'file_name': fileName,
          'file_url': publicUrl,
          'opening_balance': openingBalance,
          'closing_balance': closingBalance,
          'status': 'processing',
        })
        .select()
        .single();

    return BankStatement.fromJson(response);
  }

  /// Récupérer les transactions d'un relevé
  Future<List<BankStatementTransaction>> getStatementTransactions(
    String statementId, {
    String? status,
  }) async {
    var query = _supabase
        .from('bank_statement_transactions')
        .select()
        .eq('statement_id', statementId)
        .order('transaction_date', ascending: false);

    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query;

    return (response as List)
        .map((e) => BankStatementTransaction.fromJson(e))
        .toList();
  }

  /// Lancer le matching automatique
  Future<List<MatchResult>> autoMatchTransactions(String statementId) async {
    final response = await _supabase.rpc(
      'auto_match_transactions',
      params: {'p_statement_id': statementId},
    );

    return (response as List)
        .map((e) => MatchResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Matcher manuellement deux transactions
  Future<void> manualMatch({
    required String statementTransactionId,
    required String appTransactionId,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Non authentifié');

    await _supabase
        .from('bank_statement_transactions')
        .update({
          'matched_transaction_id': appTransactionId,
          'match_confidence': 1.0,
          'match_method': 'manual',
          'matched_at': DateTime.now().toIso8601String(),
          'matched_by': userId,
          'status': 'matched',
          'has_discrepancy': false,
          'discrepancy_type': null,
          'discrepancy_details': null,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', statementTransactionId);
  }

  /// Dissocier une transaction
  Future<void> unmatchTransaction(String statementTransactionId) async {
    await _supabase
        .from('bank_statement_transactions')
        .update({
          'matched_transaction_id': null,
          'match_confidence': null,
          'match_method': null,
          'matched_at': null,
          'matched_by': null,
          'status': 'unmatched',
          'has_discrepancy': false,
          'discrepancy_type': null,
          'discrepancy_details': null,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', statementTransactionId);
  }

  /// Créer une transaction à partir du relevé
  Future<void> createTransactionFromStatement(
    String statementTransactionId,
    String accountId,
  ) async {
    final userId = _userId;
    if (userId == null) throw Exception('Non authentifié');

    final stmtTxn = await _supabase
        .from('bank_statement_transactions')
        .select()
        .eq('id', statementTransactionId)
        .single();

    // Créer la transaction
    final txnResponse = await _supabase
        .from('transactions')
        .insert({
          'user_id': userId,
          'account_id': accountId,
          'amount': stmtTxn['amount'],
          'description': stmtTxn['description'],
          'date': stmtTxn['transaction_date'],
          'category': stmtTxn['category'] ?? 'other',
          'merchant': stmtTxn['merchant_name'],
          'source': 'import',
        })
        .select()
        .single();

    // Mettre à jour le lien
    await _supabase
        .from('bank_statement_transactions')
        .update({
          'matched_transaction_id': txnResponse['id'],
          'match_confidence': 1.0,
          'match_method': 'manual',
          'status': 'created',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', statementTransactionId);
  }

  /// Ignorer une transaction du relevé
  Future<void> ignoreTransaction(
    String statementTransactionId, {
    String? reason,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    await _supabase
        .from('bank_statement_transactions')
        .update({
          'status': 'ignored',
          'user_action': 'ignore',
          'user_action_at': DateTime.now().toIso8601String(),
          'user_action_by': userId,
          'user_notes': reason,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', statementTransactionId);
  }

  /// Créer une session de rapprochement
  Future<ReconciliationSession> createSession({
    required String accountId,
    String? statementId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Non authentifié');

    final response = await _supabase
        .from('reconciliation_sessions')
        .insert({
          'user_id': userId,
          'account_id': accountId,
          'statement_id': statementId,
          'period_start': periodStart.toIso8601String(),
          'period_end': periodEnd.toIso8601String(),
          'status': 'in_progress',
        })
        .select()
        .single();

    return ReconciliationSession.fromJson(response);
  }

  /// Récupérer la vue d'ensemble du rapprochement
  Future<ReconciliationOverview> getReconciliationOverview(
    String statementId,
  ) async {
    final statementResponse = await _supabase
        .from('bank_statements')
        .select()
        .eq('id', statementId)
        .single();

    final statement = BankStatement.fromJson(statementResponse);

    final transactions = await getStatementTransactions(statementId);

    final actionsResponse = await _supabase
        .from('reconciliation_actions')
        .select()
        .eq('session_id', statementId)
        .order('performed_at', ascending: false)
        .limit(20);

    final recentActions = (actionsResponse as List)
        .map((e) => ReconciliationAction.fromJson(e))
        .toList();

    // Compter par statut
    final statusCounts = <String, int>{};
    for (final txn in transactions) {
      statusCounts[txn.status] = (statusCounts[txn.status] ?? 0) + 1;
    }

    // Calculer les montants
    final totalMatched = transactions
        .where((t) => t.status == StatementTransactionStatus.matched)
        .fold<double>(0, (sum, t) => sum + t.amount.abs());

    final totalUnmatched = transactions
        .where((t) => t.status == StatementTransactionStatus.unmatched)
        .fold<double>(0, (sum, t) => sum + t.amount.abs());

    // Écarts
    final discrepancies = <DiscrepancySummary>[];
    final discrepancyTypes = <String, List<BankStatementTransaction>>{};

    for (final txn in transactions.where((t) => t.hasDiscrepancy)) {
      final type = txn.discrepancyType ?? 'unknown';
      discrepancyTypes.putIfAbsent(type, () => []).add(txn);
    }

    for (final entry in discrepancyTypes.entries) {
      final total = entry.value.fold<double>(
        0,
        (sum, t) => sum + (t.discrepancyDetails?['difference'] ?? 0).abs(),
      );
      discrepancies.add(DiscrepancySummary(
        type: entry.key,
        count: entry.value.length,
        totalAmount: total,
        transactions: entry.value,
      ));
    }

    // Progression
    final progress = transactions.isEmpty
        ? 0.0
        : (transactions.where((t) => t.status != StatementTransactionStatus.unmatched).length /
            transactions.length);

    return ReconciliationOverview(
      statement: statement,
      transactions: transactions,
      recentActions: recentActions,
      statusCounts: statusCounts,
      totalMatchedAmount: totalMatched,
      totalUnmatchedAmount: totalUnmatched,
      discrepancies: discrepancies,
      progressPercentage: progress * 100,
    );
  }

  /// Récupérer les règles de matching
  Future<List<MatchingRule>> getMatchingRules() async {
    final userId = _userId;
    if (userId == null) return [];

    final response = await _supabase
        .from('matching_rules')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('priority', ascending: false);

    return (response as List)
        .map((e) => MatchingRule.fromJson(e))
        .toList();
  }

  /// Créer une règle de matching
  Future<MatchingRule> createMatchingRule({
    required String name,
    String? description,
    String? bankDescriptionPattern,
    double amountTolerance = 0.01,
    int dateToleranceDays = 2,
    bool autoMatch = false,
    String? autoCategorize,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Non authentifié');

    final response = await _supabase
        .from('matching_rules')
        .insert({
          'user_id': userId,
          'name': name,
          'description': description,
          'bank_description_pattern': bankDescriptionPattern,
          'amount_tolerance': amountTolerance,
          'date_tolerance_days': dateToleranceDays,
          'auto_match': autoMatch,
          'auto_categorize': autoCategorize,
        })
        .select()
        .single();

    return MatchingRule.fromJson(response);
  }
}