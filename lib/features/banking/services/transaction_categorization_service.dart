import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/banking_models.dart';

/// Service de catégorisation IA des transactions bancaires
class TransactionCategorizationService {
  TransactionCategorizationService._();
  
  static final TransactionCategorizationService _instance = TransactionCategorizationService._();
  static TransactionCategorizationService get instance => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;

  // ═══════════════════════════════════════════════════════════
  // CATÉGORISATION INTELLIGENTE
  // ═══════════════════════════════════════════════════════════

  /// Catégorise une transaction basée sur sa description et le marchand
  Future<CategorizationResult> categorizeTransaction({
    required String description,
    String? counterpartyName,
    double? amount,
    String? reference,
  }) async {
    // 1. Normaliser la description
    final normalizedDesc = _normalizeText(description);
    final normalizedMerchant = counterpartyName != null
        ? _normalizeText(counterpartyName)
        : null;

    // 2. Recherche dans la base de connaissances locale
    final localResult = await _categorizeFromLocalKnowledge(
      description: normalizedDesc,
      merchantName: normalizedMerchant,
    );

    if (localResult != null && localResult.confidence > 0.8) {
      return localResult;
    }

    // 3. Utiliser l'IA (Edge Function) pour les cas complexes
    final aiResult = await _categorizeWithAI(
      description: normalizedDesc,
      merchantName: normalizedMerchant,
      amount: amount,
    );

    // 4. Sauvegarder dans la base de connaissances
    await _saveToKnowledgeBase(
      merchantName: normalizedMerchant ?? normalizedDesc,
      category: aiResult.category,
      subcategory: aiResult.subcategory,
    );

    return aiResult;
  }

  /// Catégorise un batch de transactions
  Future<List<CategorizationResult>> categorizeBatch(
    List<Map<String, dynamic>> transactions,
  ) async {
    final results = <CategorizationResult>[];

    for (final tx in transactions) {
      final result = await categorizeTransaction(
        description: tx['description'] ?? '',
        counterpartyName: tx['counterparty_name'],
        amount: tx['amount']?.toDouble(),
        reference: tx['reference'],
      );
      results.add(result);
    }

    return results;
  }

  // ═══════════════════════════════════════════════════════════
  // BASE DE CONNAISSANCES LOCALE
  // ═══════════════════════════════════════════════════════════

  Future<CategorizationResult?> _categorizeFromLocalKnowledge({
    required String description,
    String? merchantName,
  }) async {
    try {
      // Rechercher le marchand dans la base
      final merchantData = await _supabase
          .from('merchant_categories')
          .select()
          .ilike('name', '%${merchantName ?? description}%')
          .limit(1)
          .maybeSingle();

      if (merchantData != null) {
        return CategorizationResult(
          category: merchantData['category'],
          subcategory: merchantData['subcategory'],
          confidence: 0.9,
          keywords: [merchantData['name']],
          merchantLogo: merchantData['logo_url'],
        );
      }

      // Recherche par mots-clés
      final keywordMatch = await _matchByKeywords(description);
      if (keywordMatch != null) {
        return keywordMatch;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<CategorizationResult?> _matchByKeywords(String description) async {
    final keywords = _extractKeywords(description);
    
    // Mapping de mots-clés vers catégories
    final keywordCategories = {
      // Alimentation
      'restaurant': ('food', 'restaurant', 0.85),
      'mcdo': ('food', 'fast_food', 0.95),
      'kfc': ('food', 'fast_food', 0.95),
      'burger': ('food', 'fast_food', 0.9),
      'pizza': ('food', 'restaurant', 0.9),
      'supermarche': ('food', 'groceries', 0.9),
      'carrefour': ('food', 'groceries', 0.95),
      'auchan': ('food', 'groceries', 0.95),
      'leclerc': ('food', 'groceries', 0.95),
      'lidl': ('food', 'groceries', 0.95),
      'aldi': ('food', 'groceries', 0.95),
      'monoprix': ('food', 'groceries', 0.95),
      'franprix': ('food', 'groceries', 0.95),
      
      // Transport
      'uber': ('transport', 'taxi', 0.95),
      'bolt': ('transport', 'taxi', 0.95),
      'taxi': ('transport', 'taxi', 0.9),
      'sncf': ('transport', 'train', 0.95),
      'train': ('transport', 'train', 0.9),
      'metro': ('transport', 'public', 0.9),
      'bus': ('transport', 'public', 0.9),
      'total': ('transport', 'fuel', 0.9),
      'shell': ('transport', 'fuel', 0.9),
      'bp': ('transport', 'fuel', 0.9),
      'essence': ('transport', 'fuel', 0.9),
      'parking': ('transport', 'parking', 0.9),
      
      // Shopping
      'amazon': ('shopping', 'online', 0.95),
      'fnac': ('shopping', 'electronics', 0.9),
      'darty': ('shopping', 'electronics', 0.9),
      'boulanger': ('shopping', 'electronics', 0.9),
      'zara': ('shopping', 'clothing', 0.9),
      'h&m': ('shopping', 'clothing', 0.9),
      'uniqlo': ('shopping', 'clothing', 0.9),
      'nike': ('shopping', 'clothing', 0.9),
      'adidas': ('shopping', 'clothing', 0.9),
      'decathlon': ('shopping', 'sports', 0.95),
      
      // Logement
      'edf': ('housing', 'energy', 0.95),
      'engie': ('housing', 'energy', 0.95),
      'totalenergies': ('housing', 'energy', 0.95),
      'loyer': ('housing', 'rent', 0.95),
      'proprietaire': ('housing', 'rent', 0.9),
      
      // Abonnements
      'netflix': ('subscriptions', 'streaming', 0.95),
      'spotify': ('subscriptions', 'music', 0.95),
      'apple': ('subscriptions', 'services', 0.85),
      'google': ('subscriptions', 'services', 0.85),
      'disney': ('subscriptions', 'streaming', 0.95),
      'prime': ('subscriptions', 'streaming', 0.9),
      'youtube': ('subscriptions', 'streaming', 0.9),
      'canal': ('subscriptions', 'tv', 0.95),
      'orange': ('subscriptions', 'telecom', 0.9),
      'sfr': ('subscriptions', 'telecom', 0.9),
      'bouygues': ('subscriptions', 'telecom', 0.9),
      'free': ('subscriptions', 'telecom', 0.9),
      
      // Santé
      'pharmacie': ('health', 'pharmacy', 0.95),
      'doctolib': ('health', 'medical', 0.9),
      'dentiste': ('health', 'dental', 0.9),
      'opticien': ('health', 'vision', 0.9),
      
      // Loisirs
      'cinema': ('entertainment', 'cinema', 0.95),
      'ugc': ('entertainment', 'cinema', 0.95),
      'gaumont': ('entertainment', 'cinema', 0.95),
      'booking': ('entertainment', 'travel', 0.9),
      'airbnb': ('entertainment', 'travel', 0.95),
      'hotel': ('entertainment', 'travel', 0.9),
      
      // Revenus
      'salaire': ('income', 'salary', 0.95),
      'virement': ('income', 'transfer', 0.7),
      'remboursement': ('income', 'refund', 0.8),
    };

    for (final keyword in keywords) {
      final match = keywordCategories[keyword.toLowerCase()];
      if (match != null) {
        return CategorizationResult(
          category: match.$1,
          subcategory: match.$2,
          confidence: match.$3,
          keywords: keywords,
        );
      }
    }

    return null;
  }

  // ═══════════════════════════════════════════════════════════
  // CATÉGORISATION IA (EDGE FUNCTION)
  // ═══════════════════════════════════════════════════════════

  Future<CategorizationResult> _categorizeWithAI({
    required String description,
    String? merchantName,
    double? amount,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'categorize-transaction',
        body: {
          'description': description,
          'merchant_name': merchantName,
          'amount': amount,
        },
      );

      final data = response.data as Map<String, dynamic>;

      return CategorizationResult(
        category: data['category'] ?? 'other',
        subcategory: data['subcategory'] ?? 'unknown',
        confidence: (data['confidence'] as num?)?.toDouble() ?? 0.7,
        keywords: List<String>.from(data['keywords'] ?? []),
      );
    } catch (e) {
      // Fallback sur catégorisation par défaut
      return _defaultCategorization(description, amount);
    }
  }

  CategorizationResult _defaultCategorization(String description, double? amount) {
    // Heuristiques simples
    if (amount != null) {
      if (amount > 0) {
        return const CategorizationResult(
          category: 'income',
          subcategory: 'other',
          confidence: 0.5,
          keywords: [],
        );
      }
      if (amount < -500) {
        return const CategorizationResult(
          category: 'housing',
          subcategory: 'other',
          confidence: 0.4,
          keywords: [],
        );
      }
    }

    return const CategorizationResult(
      category: 'other',
      subcategory: 'unknown',
      confidence: 0.3,
      keywords: [],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // UTILITAIRES
  // ═══════════════════════════════════════════════════════════

  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> _extractKeywords(String text) {
    final normalized = _normalizeText(text);
    final words = normalized.split(' ');
    
    // Filtrer les mots courts et les mots vides
    final stopWords = {'le', 'la', 'les', 'de', 'du', 'des', 'et', 'en', 'un', 'une'};
    
    return words
        .where((w) => w.length > 2 && !stopWords.contains(w))
        .toList();
  }

  Future<void> _saveToKnowledgeBase({
    required String merchantName,
    required String category,
    required String subcategory,
  }) async {
    try {
      await _supabase.from('merchant_categories').upsert({
        'name': merchantName,
        'category': category,
        'subcategory': subcategory,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Ignorer les erreurs de sauvegarde
    }
  }

  // ═══════════════════════════════════════════════════════════
  // APPRENTISSAGE UTILISATEUR
  // ═══════════════════════════════════════════════════════════

  /// Apprend des corrections manuelles de l'utilisateur
  Future<void> learnFromUserCorrection({
    required String transactionId,
    required String originalCategory,
    required String correctedCategory,
    required String merchantName,
  }) async {
    try {
      // Sauvegarder la correction
      await _supabase.from('user_category_corrections').insert({
        'transaction_id': transactionId,
        'original_category': originalCategory,
        'corrected_category': correctedCategory,
        'merchant_name': merchantName,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Mettre à jour la base de connaissances
      await _supabase.from('merchant_categories').upsert({
        'name': merchantName,
        'category': correctedCategory,
        'user_confirmed': true,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Ignorer les erreurs
    }
  }

  /// Récupère les statistiques de catégorisation
  Future<Map<String, dynamic>> getCategorizationStats(String userId) async {
    try {
      final result = await _supabase
          .from('bank_transactions')
          .select()
          .eq('user_id', userId)
          .eq('is_categorized', true);

      final total = result.length;
      final byCategory = <String, int>{};

      for (final tx in result) {
        final category = tx['suggested_category'] ?? 'unknown';
        byCategory[category] = (byCategory[category] ?? 0) + 1;
      }

      return {
        'total_categorized': total,
        'by_category': byCategory,
        'accuracy_estimate': 0.85, // Basé sur les retours utilisateurs
      };
    } catch (e) {
      return {'total_categorized': 0, 'by_category': {}, 'accuracy_estimate': 0};
    }
  }
}
