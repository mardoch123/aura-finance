import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/banking_models.dart';

/// Service de détection des doublons de transactions
class DuplicateDetectionService {
  DuplicateDetectionService._();
  
  static final DuplicateDetectionService _instance = DuplicateDetectionService._();
  static DuplicateDetectionService get instance => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;

  // ═══════════════════════════════════════════════════════════
  // DÉTECTION DE DOUBLONS
  // ═══════════════════════════════════════════════════════════

  /// Vérifie si une transaction est un doublon
  Future<DuplicateCheckResult> checkForDuplicate({
    required String userId,
    required double amount,
    required DateTime date,
    required String description,
    String? source, // 'banking', 'manual', 'scan'
    String? externalId,
    int toleranceDays = 3,
    double toleranceAmount = 0.01,
  }) async {
    // 1. Recherche par ID externe exact (pour les imports bancaires)
    if (externalId != null && externalId.isNotEmpty) {
      final existingById = await _findByExternalId(userId, externalId);
      if (existingById != null) {
        return DuplicateCheckResult(
          isDuplicate: true,
          duplicateTransactionId: existingById['id'],
          similarityScore: 1.0,
          matchingFields: ['external_id'],
        );
      }
    }

    // 2. Recherche par montant + date approximative
    final candidates = await _findCandidates(
      userId: userId,
      amount: amount,
      date: date,
      toleranceDays: toleranceDays,
      toleranceAmount: toleranceAmount,
    );

    if (candidates.isEmpty) {
      return const DuplicateCheckResult(
        isDuplicate: false,
        similarityScore: 0.0,
        matchingFields: [],
      );
    }

    // 3. Calculer la similarité pour chaque candidat
    DuplicateCheckResult? bestMatch;
    double bestScore = 0.0;

    for (final candidate in candidates) {
      final similarity = _calculateSimilarity(
        newDescription: description,
        newAmount: amount,
        newDate: date,
        existingTransaction: candidate,
      );

      if (similarity.score > bestScore && similarity.score > 0.7) {
        bestScore = similarity.score;
        bestMatch = DuplicateCheckResult(
          isDuplicate: true,
          duplicateTransactionId: candidate['id'],
          similarityScore: similarity.score,
          matchingFields: similarity.matchingFields,
        );
      }
    }

    return bestMatch ??
        const DuplicateCheckResult(
          isDuplicate: false,
          similarityScore: 0.0,
          matchingFields: [],
        );
  }

  /// Vérifie un batch de transactions
  Future<List<DuplicateCheckResult>> checkBatch({
    required String userId,
    required List<Map<String, dynamic>> transactions,
  }) async {
    final results = <DuplicateCheckResult>[];

    for (final tx in transactions) {
      final result = await checkForDuplicate(
        userId: userId,
        amount: tx['amount']?.toDouble() ?? 0,
        date: DateTime.parse(tx['date'] ?? DateTime.now().toIso8601String()),
        description: tx['description'] ?? '',
        source: tx['source'],
        externalId: tx['external_id'],
      );
      results.add(result);
    }

    return results;
  }

  // ═══════════════════════════════════════════════════════════
  // RECHERCHE DE CANDIDATS
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> _findByExternalId(
    String userId,
    String externalId,
  ) async {
    try {
      final result = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .eq('external_id', externalId)
          .maybeSingle();

      return result;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _findCandidates({
    required String userId,
    required double amount,
    required DateTime date,
    required int toleranceDays,
    required double toleranceAmount,
  }) async {
    try {
      final fromDate = date.subtract(Duration(days: toleranceDays));
      final toDate = date.add(Duration(days: toleranceDays));
      final minAmount = amount.abs() - toleranceAmount;
      final maxAmount = amount.abs() + toleranceAmount;

      // Rechercher dans les transactions existantes
      final result = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .gte('date', fromDate.toIso8601String())
          .lte('date', toDate.toIso8601String())
          .gte('amount', -maxAmount)
          .lte('amount', -minAmount);

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CALCUL DE SIMILARITÉ
  // ═══════════════════════════════════════════════════════════

  _SimilarityResult _calculateSimilarity({
    required String newDescription,
    required double newAmount,
    required DateTime newDate,
    required Map<String, dynamic> existingTransaction,
  }) {
    double score = 0.0;
    final matchingFields = <String>[];

    // 1. Similarité de montant (40%)
    final existingAmount = (existingTransaction['amount'] as num?)?.toDouble() ?? 0;
    final amountDiff = (newAmount - existingAmount).abs();
    if (amountDiff < 0.01) {
      score += 0.4;
      matchingFields.add('amount');
    } else if (amountDiff < 1.0) {
      score += 0.3;
    }

    // 2. Similarité de date (30%)
    final existingDate = DateTime.tryParse(existingTransaction['date'] ?? '');
    if (existingDate != null) {
      final daysDiff = newDate.difference(existingDate).inDays.abs();
      if (daysDiff == 0) {
        score += 0.3;
        matchingFields.add('date');
      } else if (daysDiff <= 1) {
        score += 0.2;
      } else if (daysDiff <= 3) {
        score += 0.1;
      }
    }

    // 3. Similarité de description (30%)
    final existingDescription = existingTransaction['description'] ?? '';
    final descriptionSimilarity = _calculateTextSimilarity(
      newDescription,
      existingDescription,
    );
    score += descriptionSimilarity * 0.3;
    if (descriptionSimilarity > 0.8) {
      matchingFields.add('description');
    }

    return _SimilarityResult(score: score, matchingFields: matchingFields);
  }

  double _calculateTextSimilarity(String text1, String text2) {
    final normalized1 = _normalizeText(text1);
    final normalized2 = _normalizeText(text2);

    if (normalized1 == normalized2) return 1.0;
    if (normalized1.isEmpty || normalized2.isEmpty) return 0.0;

    // Distance de Levenshtein simplifiée
    final words1 = normalized1.split(' ').toSet();
    final words2 = normalized2.split(' ').toSet();

    final intersection = words1.intersection(words2);
    final union = words1.union(words2);

    return intersection.length / union.length;
  }

  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ═══════════════════════════════════════════════════════════
  // GESTION DES DOUBLONS
  // ═══════════════════════════════════════════════════════════

  /// Marque une transaction comme doublon
  Future<void> markAsDuplicate({
    required String transactionId,
    required String duplicateOfId,
  }) async {
    await _supabase.from('transactions').update({
      'is_duplicate': true,
      'duplicate_of_id': duplicateOfId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', transactionId);
  }

  /// Fusionne deux transactions doublons
  Future<Map<String, dynamic>?> mergeDuplicates({
    required String keepId,
    required String mergeId,
  }) async {
    try {
      // Récupérer les deux transactions
      final keep = await _supabase
          .from('transactions')
          .select()
          .eq('id', keepId)
          .single();

      final merge = await _supabase
          .from('transactions')
          .select()
          .eq('id', mergeId)
          .single();

      // Fusionner les données (garder la plus complète)
      final merged = {
        ...keep,
        'description': keep['description']?.toString().length ?? 0 >
                merge['description']?.toString().length ?? 0
            ? keep['description']
            : merge['description'],
        'merchant': keep['merchant'] ?? merge['merchant'],
        'category': keep['category'] ?? merge['category'],
        'scan_image_url': keep['scan_image_url'] ?? merge['scan_image_url'],
        'ai_confidence': [keep['ai_confidence'], merge['ai_confidence']]
            .whereType<double>()
            .reduce((a, b) => a > b ? a : b),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Mettre à jour la transaction conservée
      await _supabase.from('transactions').update(merged).eq('id', keepId);

      // Marquer l'autre comme doublon
      await markAsDuplicate(transactionId: mergeId, duplicateOfId: keepId);

      return merged;
    } catch (e) {
      return null;
    }
  }

  /// Résout un conflit de doublon manuellement
  Future<void> resolveDuplicateConflict({
    required String transactionId,
    required bool isActuallyDuplicate,
    String? duplicateOfId,
  }) async {
    if (isActuallyDuplicate && duplicateOfId != null) {
      await markAsDuplicate(
        transactionId: transactionId,
        duplicateOfId: duplicateOfId,
      );
    } else {
      // Marquer comme non-doublon
      await _supabase.from('transactions').update({
        'is_duplicate': false,
        'duplicate_of_id': null,
        'duplicate_verified': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', transactionId);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ANALYSE ET STATISTIQUES
  // ═══════════════════════════════════════════════════════════

  /// Récupère tous les doublons potentiels d'un utilisateur
  Future<List<Map<String, dynamic>>> findPotentialDuplicates(String userId) async {
    try {
      // Récupérer toutes les transactions récentes
      final transactions = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .eq('is_duplicate', false)
          .gte('date', DateTime.now().subtract(const Duration(days: 90)).toIso8601String())
          .order('date', ascending: false);

      final duplicates = <Map<String, dynamic>>[];
      final processed = <String>{};

      for (final tx in transactions) {
        if (processed.contains(tx['id'])) continue;

        final check = await checkForDuplicate(
          userId: userId,
          amount: (tx['amount'] as num).toDouble(),
          date: DateTime.parse(tx['date']),
          description: tx['description'] ?? '',
        );

        if (check.isDuplicate && check.duplicateTransactionId != null) {
          duplicates.add({
            'transaction': tx,
            'duplicate_of': check.duplicateTransactionId,
            'similarity': check.similarityScore,
          });
          processed.add(tx['id']);
          processed.add(check.duplicateTransactionId!);
        }
      }

      return duplicates;
    } catch (e) {
      return [];
    }
  }

  /// Statistiques de doublons
  Future<Map<String, dynamic>> getDuplicateStats(String userId) async {
    try {
      final total = await _supabase
          .from('transactions')
          .count()
          .eq('user_id', userId);

      final duplicates = await _supabase
          .from('transactions')
          .count()
          .eq('user_id', userId)
          .eq('is_duplicate', true);

      final potential = await findPotentialDuplicates(userId);

      return {
        'total_transactions': total,
        'confirmed_duplicates': duplicates,
        'potential_duplicates': potential.length,
        'duplicate_rate': total > 0 ? (duplicates / total) * 100 : 0,
      };
    } catch (e) {
      return {
        'total_transactions': 0,
        'confirmed_duplicates': 0,
        'potential_duplicates': 0,
        'duplicate_rate': 0.0,
      };
    }
  }

  // ═══════════════════════════════════════════════════════════
  // DÉTECTION AVANCÉE (SCÉNARIOS SPÉCIFIQUES)
  // ═══════════════════════════════════════════════════════════

  /// Détecte les doublons scan vs bancaire
  Future<DuplicateCheckResult> checkScanVsBankDuplicate({
    required String userId,
    required double amount,
    required DateTime date,
    required String merchant,
  }) async {
    // Recherche plus stricte pour les scans
    final candidates = await _findCandidates(
      userId: userId,
      amount: amount,
      date: date,
      toleranceDays: 1, // Plus strict
      toleranceAmount: 0.05,
    );

    for (final candidate in candidates) {
      final candidateSource = candidate['source'];
      
      // Vérifier si c'est une transaction bancaire
      if (candidateSource == 'banking' || candidateSource == 'import') {
        final similarity = _calculateSimilarity(
          newDescription: merchant,
          newAmount: amount,
          newDate: date,
          existingTransaction: candidate,
        );

        if (similarity.score > 0.8) {
          return DuplicateCheckResult(
            isDuplicate: true,
            duplicateTransactionId: candidate['id'],
            similarityScore: similarity.score,
            matchingFields: [...similarity.matchingFields, 'scan_vs_bank'],
          );
        }
      }
    }

    return const DuplicateCheckResult(
      isDuplicate: false,
      similarityScore: 0.0,
      matchingFields: [],
    );
  }

  /// Détecte les abonnements en double
  Future<List<Map<String, dynamic>>> findDuplicateSubscriptions(String userId) async {
    try {
      // Récupérer les transactions récurrentes similaires
      final result = await _supabase.rpc('find_duplicate_subscriptions', params: {
        'p_user_id': userId,
      });

      return List<Map<String, dynamic>>.from(result ?? []);
    } catch (e) {
      return [];
    }
  }
}

class _SimilarityResult {
  final double score;
  final List<String> matchingFields;

  _SimilarityResult({
    required this.score,
    required this.matchingFields,
  });
}
