import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/ads/interstitial_ad_service.dart';

/// Service de gestion des limites d'usage (freemium)
/// 
/// Gère les quotas pour les utilisateurs non-Pro :
/// - Scans IA: 5/mois
/// - Messages Coach: 10/mois
/// 
/// Les bonus de pubs récompensées sont pris en compte.
class UsageLimitService {
  static final UsageLimitService _instance = UsageLimitService._internal();
  factory UsageLimitService() => _instance;
  UsageLimitService._internal();

  // ═══════════════════════════════════════════════════════════
  // LIMITES FREEMIUM
  // ═══════════════════════════════════════════════════════════

  static const int _freeScansPerMonth = 5;
  static const int _freeCoachMessagesPerMonth = 10;

  // ═══════════════════════════════════════════════════════════
  // CLÉS SHARED PREFERENCES
  // ═══════════════════════════════════════════════════════════

  static const String _prefScanCount = 'usage_scan_count';
  static const String _prefScanMonth = 'usage_scan_month';
  static const String _prefCoachCount = 'usage_coach_count';
  static const String _prefCoachMonth = 'usage_coach_month';

  // ═══════════════════════════════════════════════════════════
  // VÉRIFICATIONS
  // ═══════════════════════════════════════════════════════════

  /// Vérifie si l'utilisateur peut effectuer un scan
  /// 
  /// [isPro] Si l'utilisateur a un abonnement Pro
  /// Retourne un [LimitCheckResult] avec le statut et les infos
  Future<LimitCheckResult> canScan({required bool isPro}) async {
    // Vérifier si Pro
    if (isPro) {
      return const LimitCheckResult(
        allowed: true,
        currentUsage: 0,
        limit: -1, // Illimité
        isPro: true,
      );
    }

    // Vérifier les bonus de pub récompensée
    final bonusScans = await rewardedAdService.getActiveScanBonus();

    // Récupérer l'usage actuel
    final usage = await _getCurrentMonthUsage(_prefScanCount, _prefScanMonth);
    final totalAvailable = _freeScansPerMonth + bonusScans;

    if (kDebugMode) {
      print('📊 Scans: ${usage.count}/$_freeScansPerMonth (bonus: $bonusScans)');
    }

    return LimitCheckResult(
      allowed: usage.count < totalAvailable,
      currentUsage: usage.count,
      limit: totalAvailable,
      isPro: false,
      bonusAvailable: bonusScans > 0,
      bonusAmount: bonusScans,
    );
  }

  /// Vérifie si l'utilisateur peut envoyer un message au Coach
  Future<LimitCheckResult> canSendCoachMessage({required bool isPro}) async {
    // Vérifier si Pro
    if (isPro) {
      return const LimitCheckResult(
        allowed: true,
        currentUsage: 0,
        limit: -1,
        isPro: true,
      );
    }

    // Vérifier les bonus
    final bonusMessages = await rewardedAdService.getActiveCoachBonus();

    // Récupérer l'usage actuel
    final usage = await _getCurrentMonthUsage(_prefCoachCount, _prefCoachMonth);
    final totalAvailable = _freeCoachMessagesPerMonth + bonusMessages;

    if (kDebugMode) {
      print('📊 Coach: ${usage.count}/$_freeCoachMessagesPerMonth (bonus: $bonusMessages)');
    }

    return LimitCheckResult(
      allowed: usage.count < totalAvailable,
      currentUsage: usage.count,
      limit: totalAvailable,
      isPro: false,
      bonusAvailable: bonusMessages > 0,
      bonusAmount: bonusMessages,
    );
  }

  /// Vérifie si le rapport mensuel est disponible
  Future<bool> canAccessMonthlyReport({required bool isPro}) async {
    if (isPro) return true;

    return await rewardedAdService.isMonthlyReportUnlocked();
  }

  // ═══════════════════════════════════════════════════════════
  // INCRÉMENTATION
  // ═══════════════════════════════════════════════════════════

  /// Incrémente le compteur de scans
  Future<void> incrementScanCount() async {
    await _incrementUsage(_prefScanCount, _prefScanMonth);
  }

  /// Incrémente le compteur de messages Coach
  Future<void> incrementCoachMessageCount() async {
    await _incrementUsage(_prefCoachCount, _prefCoachMonth);
  }

  // ═══════════════════════════════════════════════════════════
  // MÉTHODES PRIVÉES
  // ═══════════════════════════════════════════════════════════

  Future<_MonthlyUsage> _getCurrentMonthUsage(String countKey, String monthKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentMonth = DateTime.now().month;
      final storedMonth = prefs.getInt(monthKey);

      // Si changement de mois, réinitialiser
      if (storedMonth != currentMonth) {
        await prefs.setInt(countKey, 0);
        await prefs.setInt(monthKey, currentMonth);
        return _MonthlyUsage(count: 0, month: currentMonth);
      }

      final count = prefs.getInt(countKey) ?? 0;
      return _MonthlyUsage(count: count, month: currentMonth);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erreur récupération usage: $e');
      }
      return _MonthlyUsage(count: 0, month: DateTime.now().month);
    }
  }

  Future<void> _incrementUsage(String countKey, String monthKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentMonth = DateTime.now().month;
      final storedMonth = prefs.getInt(monthKey);

      int count = 0;
      if (storedMonth == currentMonth) {
        count = prefs.getInt(countKey) ?? 0;
      }

      count++;
      await prefs.setInt(countKey, count);
      await prefs.setInt(monthKey, currentMonth);

      if (kDebugMode) {
        print('📈 Usage incrémenté: $countKey = $count');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erreur incrémentation usage: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SYNCHRONISATION SUPABASE
  // ═══════════════════════════════════════════════════════════

  /// Synchronise les compteurs avec Supabase
  /// 
  /// À appeler régulièrement ou à la fermeture de l'app
  Future<void> syncWithSupabase() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final prefs = await SharedPreferences.getInstance();
      final scanCount = prefs.getInt(_prefScanCount) ?? 0;
      final coachCount = prefs.getInt(_prefCoachCount) ?? 0;

      await Supabase.instance.client.from('usage_limits').upsert({
        'user_id': userId,
        'scan_count': scanCount,
        'coach_message_count': coachCount,
        'month': DateTime.now().month,
        'year': DateTime.now().year,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('✅ Usage synchronisé avec Supabase');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erreur sync usage: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // RÉINITIALISATION
  // ═══════════════════════════════════════════════════════════

  /// Réinitialise tous les compteurs (nouveau mois ou test)
  Future<void> resetAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefScanCount);
      await prefs.remove(_prefScanMonth);
      await prefs.remove(_prefCoachCount);
      await prefs.remove(_prefCoachMonth);

      if (kDebugMode) {
        print('🔄 Compteurs réinitialisés');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erreur réinitialisation: $e');
      }
    }
  }
}

/// Instance globale
final usageLimitService = UsageLimitService();

/// Provider pour accéder au service
final usageLimitServiceProvider = Provider<UsageLimitService>((ref) {
  return usageLimitService;
});

// ═══════════════════════════════════════════════════════════
// MODÈLES
// ═══════════════════════════════════════════════════════════

/// Résultat d'une vérification de limite
class LimitCheckResult {
  /// Si l'action est autorisée
  final bool allowed;

  /// Usage actuel
  final int currentUsage;

  /// Limite totale (gratuit + bonus)
  final int limit;

  /// Si l'utilisateur est Pro
  final bool isPro;

  /// Si un bonus de pub est actif
  final bool bonusAvailable;

  /// Montant du bonus
  final int bonusAmount;

  /// Usage restant
  int get remaining => limit - currentUsage;

  /// Si la limite est atteinte
  bool get isLimitReached => !allowed;

  /// Pourcentage d'usage (0-100)
  double get usagePercentage => limit > 0 ? (currentUsage / limit) * 100 : 0;

  const LimitCheckResult({
    required this.allowed,
    required this.currentUsage,
    required this.limit,
    required this.isPro,
    this.bonusAvailable = false,
    this.bonusAmount = 0,
  });

  @override
  String toString() {
    return 'LimitCheckResult(allowed: $allowed, usage: $currentUsage/$limit, pro: $isPro)';
  }
}

/// Usage mensuel interne
class _MonthlyUsage {
  final int count;
  final int month;

  const _MonthlyUsage({required this.count, required this.month});
}

// ═══════════════════════════════════════════════════════════
// PROVIDERS RIVERPOD (seront complétés après génération du code)
// ═══════════════════════════════════════════════════════════

// Note: Ces providers dépendent de isProProvider qui est généré par build_runner
// Après avoir exécuté `flutter pub run build_runner build`, décommentez le code ci-dessous

/// Provider simple pour vérifier si l'utilisateur peut scanner
final canScanProvider = FutureProvider<LimitCheckResult>((ref) async {
  // TODO: Remplacer par ref.watch(isProProvider) après génération
  const isPro = false; // Valeur temporaire
  return await usageLimitService.canScan(isPro: isPro);
});

/// Provider pour vérifier si l'utilisateur peut envoyer un message Coach
final canSendCoachMessageProvider = FutureProvider<LimitCheckResult>((ref) async {
  // TODO: Remplacer par ref.watch(isProProvider) après génération
  const isPro = false; // Valeur temporaire
  return await usageLimitService.canSendCoachMessage(isPro: isPro);
});

/// Provider pour le nombre de scans restants
final remainingScansProvider = FutureProvider<int>((ref) async {
  // TODO: Remplacer par ref.watch(isProProvider) après génération
  const isPro = false; // Valeur temporaire
  final result = await usageLimitService.canScan(isPro: isPro);
  return result.remaining;
});

/// Provider pour le nombre de messages Coach restants
final remainingCoachMessagesProvider = FutureProvider<int>((ref) async {
  // TODO: Remplacer par ref.watch(isProProvider) après génération
  const isPro = false; // Valeur temporaire
  final result = await usageLimitService.canSendCoachMessage(isPro: isPro);
  return result.remaining;
});
