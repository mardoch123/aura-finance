import '../../../services/supabase_service.dart';
import '../../../core/constants/api_endpoints.dart';
import '../domain/transaction_draft.dart';

/// Repository pour les transactions
/// Gère la persistence des transactions scannées
class TransactionRepository {
  TransactionRepository._();
  
  static final TransactionRepository _instance = TransactionRepository._();
  static TransactionRepository get instance => _instance;
  
  final _supabase = SupabaseService.instance;
  
  /// Sauvegarde un brouillon de transaction
  Future<Map<String, dynamic>> saveDraft(TransactionDraft draft) async {
    final userId = _supabase.currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    final data = {
      'user_id': userId,
      'amount': draft.amount,
      'merchant': draft.merchant,
      'category': draft.category,
      'subcategory': draft.subcategory,
      'description': draft.description,
      'date': (draft.date ?? DateTime.now()).toIso8601String(),
      'currency': draft.currency,
      'source': draft.source,
      'scan_image_url': draft.scanImageUrl,
      'ai_confidence': draft.confidence,
      'metadata': {
        'items': draft.items.map((i) => {
          'name': i.name,
          'amount': i.amount,
          'quantity': i.quantity,
        }).toList(),
      },
    };
    
    final response = await _supabase.transactions.insert(data).select().single();
    return response;
  }
  
  /// Récupère les transactions récentes
  Future<List<Map<String, dynamic>>> getRecentTransactions({int limit = 10}) async {
    final response = await _supabase.transactions
        .forCurrentUser()
        .order('created_at', ascending: false)
        .limit(limit);
    
    return response;
  }
  
  /// Récupère une transaction par ID
  Future<Map<String, dynamic>?> getTransaction(String id) async {
    final response = await _supabase.transactions
        .forCurrentUser()
        .eq('id', id)
        .maybeSingle();
    
    return response;
  }
  
  /// Met à jour une transaction
  Future<Map<String, dynamic>> updateTransaction(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');
    
    final response = await _supabase.transactions
        .update(updates)
        .eq('id', id)
        .eq('user_id', userId)
        .select()
        .single();
    
    return response;
  }
  
  /// Supprime une transaction
  Future<void> deleteTransaction(String id) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');
    
    await _supabase.transactions
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }
  
  /// Récupère le nombre de scans effectués aujourd'hui
  Future<int> getTodayScanCount() async {
    final userId = _supabase.currentUserId;
    if (userId == null) return 0;
    
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
    
    final response = await _supabase.client
        .from('transactions')
        .select('id')
        .eq('user_id', userId)
        .eq('source', 'scan')
        .gte('created_at', startOfDay);
    
    return response.length;
  }
  
  /// Vérifie si l'utilisateur a atteint la limite de scans quotidienne
  Future<bool> hasReachedDailyLimit() async {
    final count = await getTodayScanCount();
    return count >= 50; // Limite: 50 scans/jour
  }
}


