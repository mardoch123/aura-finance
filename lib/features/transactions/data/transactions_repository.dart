import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';
import '../domain/transaction_model.dart';

/// Repository pour la gestion des transactions
class TransactionsRepository {
  final SupabaseClient _client;

  TransactionsRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.instance.client;

  /// Récupère toutes les transactions de l'utilisateur
  Future<List<Transaction>> getTransactions({
    int limit = 50,
    int offset = 0,
    TransactionFilter filter = TransactionFilter.all,
    TransactionPeriod period = TransactionPeriod.month,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    // Construire la requête de base
    var builder = _client
        .from('transactions')
        .select()
        .eq('user_id', userId);

    // Appliquer le filtre de période
    final startDate = customStartDate ?? period.startDate;
    final endDate = customEndDate ?? period.endDate;
    builder = builder.gte('date', startDate.toIso8601String()).lte('date', endDate.toIso8601String());

    // Appliquer le filtre de type
    switch (filter) {
      case TransactionFilter.income:
        builder = builder.gt('amount', 0);
        break;
      case TransactionFilter.expense:
        builder = builder.lt('amount', 0);
        break;
      case TransactionFilter.recurring:
        builder = builder.eq('is_recurring', true);
        break;
      case TransactionFilter.all:
        break;
    }

    final response = await builder
        .order('date', ascending: false)
        .range(offset, offset + limit - 1);
    return (response as List).map((json) => Transaction.fromJson(json)).toList();
  }

  /// Récupère une transaction par son ID
  Future<Transaction?> getTransactionById(String id) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    final response = await _client
        .from('transactions')
        .select()
        .eq('id', id)
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return Transaction.fromJson(response);
  }

  /// Crée une nouvelle transaction
  Future<Transaction> createTransaction({
    required double amount,
    required String category,
    required DateTime date,
    String? accountId,
    String? subcategory,
    String? merchant,
    String? description,
    String source = 'manual',
    String? scanImageUrl,
    double? aiConfidence,
    bool isRecurring = false,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    final data = {
      'user_id': userId,
      'account_id': accountId,
      'amount': amount,
      'category': category,
      'subcategory': subcategory,
      'merchant': merchant,
      'description': description,
      'date': date.toIso8601String(),
      'source': source,
      'scan_image_url': scanImageUrl,
      'ai_confidence': aiConfidence,
      'is_recurring': isRecurring,
      'tags': tags,
      'metadata': metadata,
    };

    final response = await _client
        .from('transactions')
        .insert(data)
        .select()
        .single();

    return Transaction.fromJson(response);
  }

  /// Met à jour une transaction existante
  Future<Transaction> updateTransaction(
    String id, {
    double? amount,
    String? category,
    String? subcategory,
    String? merchant,
    String? description,
    DateTime? date,
    String? accountId,
    bool? isRecurring,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    final updates = <String, dynamic>{
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (subcategory != null) 'subcategory': subcategory,
      if (merchant != null) 'merchant': merchant,
      if (description != null) 'description': description,
      if (date != null) 'date': date.toIso8601String(),
      if (accountId != null) 'account_id': accountId,
      if (isRecurring != null) 'is_recurring': isRecurring,
      if (tags != null) 'tags': tags,
      if (metadata != null) 'metadata': metadata,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _client
        .from('transactions')
        .update(updates)
        .eq('id', id)
        .eq('user_id', userId)
        .select()
        .single();

    return Transaction.fromJson(response);
  }

  /// Supprime une transaction
  Future<void> deleteTransaction(String id) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    await _client
        .from('transactions')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }

  /// Récupère les statistiques des transactions
  Future<TransactionStats> getStats({
    TransactionPeriod period = TransactionPeriod.month,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    final start = startDate ?? period.startDate;
    final end = endDate ?? period.endDate;

    final response = await _client.rpc('get_monthly_stats', params: {
      'user_uuid': userId,
      'start_date': start.toIso8601String().split('T')[0],
      'end_date': end.toIso8601String().split('T')[0],
    });

    if (response == null || (response as List).isEmpty) {
      return TransactionStats.empty();
    }

    final data = response[0] as Map<String, dynamic>;
    return TransactionStats(
      totalIncome: (data['total_income'] as num?)?.toDouble() ?? 0.0,
      totalExpense: (data['total_expense'] as num?)?.toDouble() ?? 0.0,
      netAmount: (data['net_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Récupère les dépenses par catégorie
  Future<List<CategoryExpense>> getExpensesByCategory({
    TransactionPeriod period = TransactionPeriod.month,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    final response = await _client.rpc('get_expenses_by_category', params: {
      'user_uuid': userId,
      'start_date': period.startDate.toIso8601String().split('T')[0],
      'end_date': period.endDate.toIso8601String().split('T')[0],
    });

    if (response == null) return [];

    return (response as List).map((json) => CategoryExpense(
      category: json['category'] as String,
      amount: (json['total_amount'] as num).toDouble(),
      count: json['transaction_count'] as int,
    )).toList();
  }

  /// Recherche des transactions
  Future<List<Transaction>> searchTransactions(String query) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    final response = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .or('merchant.ilike.%$query%,description.ilike.%$query%')
        .order('date', ascending: false)
        .limit(20);

    return (response as List).map((json) => Transaction.fromJson(json)).toList();
  }
}

/// Statistiques des transactions
class TransactionStats {
  final double totalIncome;
  final double totalExpense;
  final double netAmount;

  const TransactionStats({
    required this.totalIncome,
    required this.totalExpense,
    required this.netAmount,
  });

  factory TransactionStats.empty() => const TransactionStats(
        totalIncome: 0.0,
        totalExpense: 0.0,
        netAmount: 0.0,
      );
}

/// Dépense par catégorie
class CategoryExpense {
  final String category;
  final double amount;
  final int count;

  const CategoryExpense({
    required this.category,
    required this.amount,
    required this.count,
  });
}
