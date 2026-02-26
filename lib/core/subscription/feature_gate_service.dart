import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/analytics_service.dart';

/// Limites du plan gratuit
class FreeLimits {
  FreeLimits._();

  static const int scanPerMonth = 5;
  static const int coachMessagesPerMonth = 10;
  static const int predictionDays = 7;
  static const bool exportEnabled = false;
  static const int multiAccounts = 1;
}

/// Types de features protégées
enum AuraFeature {
  scanner,
  coach,
  predictions,
  export,
  multiAccounts,
}

/// Extension pour les infos des features
extension AuraFeatureInfo on AuraFeature {
  String get displayName {
    switch (this) {
      case AuraFeature.scanner:
        return 'Scanner IA';
      case AuraFeature.coach:
        return 'Coach IA';
      case AuraFeature.predictions:
        return 'Prédictions';
      case AuraFeature.export:
        return 'Export';
      case AuraFeature.multiAccounts:
        return 'Comptes multiples';
    }
  }

  String get icon {
    switch (this) {
      case AuraFeature.scanner:
        return '🔭';
      case AuraFeature.coach:
        return '🤖';
      case AuraFeature.predictions:
        return '📈';
      case AuraFeature.export:
        return '📤';
      case AuraFeature.multiAccounts:
        return '🏦';
    }
  }

  int? get freeLimit {
    switch (this) {
      case AuraFeature.scanner:
        return FreeLimits.scanPerMonth;
      case AuraFeature.coach:
        return FreeLimits.coachMessagesPerMonth;
      default:
        return null;
    }
  }
}

/// Résultat d'une vérification de feature
class FeatureGateResult {
  /// Si la feature est accessible
  final bool allowed;

  /// Raison si non accessible
  final FeatureGateReason reason;

  /// Usage actuel (pour les features comptées)
  final int currentUsage;

  /// Limite totale (gratuit + bonus)
  final int limit;

  /// Restant
  int get remaining => limit - currentUsage;

  /// Si l'utilisateur est Pro
  final bool isPro;

  /// Si un bonus est disponible
  final bool hasBonus;

  const FeatureGateResult({
    required this.allowed,
    required this.reason,
    required this.currentUsage,
    required this.limit,
    required this.isPro,
    this.hasBonus = false,
  });

  /// Factory pour accès autorisé
  factory FeatureGateResult.allowed({
    required int currentUsage,
    required int limit,
    required bool isPro,
    bool hasBonus = false,
  }) {
    return FeatureGateResult(
      allowed: true,
      reason: FeatureGateReason.allowed,
      currentUsage: currentUsage,
      limit: limit,
      isPro: isPro,
      hasBonus: hasBonus,
    );
  }

  /// Factory pour limite atteinte
  factory FeatureGateResult.limitReached({
    required int currentUsage,
    required int limit,
    required bool isPro,
  }) {
    return FeatureGateResult(
      allowed: false,
      reason: FeatureGateReason.limitReached,
      currentUsage: currentUsage,
      limit: limit,
      isPro: isPro,
    );
  }

  /// Factory pour Pro uniquement
  factory FeatureGateResult.proOnly() {
    return const FeatureGateResult(
      allowed: false,
      reason: FeatureGateReason.proOnly,
      currentUsage: 0,
      limit: 0,
      isPro: false,
    );
  }

  @override
  String toString() {
    return 'FeatureGateResult(allowed: $allowed, reason: $reason, usage: $currentUsage/$limit)';
  }
}

/// Raisons de blocage
enum FeatureGateReason {
  allowed,
  limitReached,
  proOnly,
}

/// Modèle de données d'usage
class UsageData {
  final int scanCount;
  final int coachCount;
  final int scanBonus;
  final int coachBonus;
  final DateTime? bonusExpiresAt;

  const UsageData({
    required this.scanCount,
    required this.coachCount,
    required this.scanBonus,
    required this.coachBonus,
    this.bonusExpiresAt,
  });

  factory UsageData.fromJson(Map<String, dynamic> json) {
    return UsageData(
      scanCount: json['scan_count'] ?? 0,
      coachCount: json['coach_message_count'] ?? 0,
      scanBonus: json['scan_bonus'] ?? 0,
      coachBonus: json['coach_bonus'] ?? 0,
      bonusExpiresAt: json['bonus_expires_at'] != null
          ? DateTime.parse(json['bonus_expires_at'])
          : null,
    );
  }

  int get totalScanLimit => FreeLimits.scanPerMonth + scanBonus;
  int get totalCoachLimit => FreeLimits.coachMessagesPerMonth + coachBonus;
  int get scanRemaining => totalScanLimit - scanCount;
  int get coachRemaining => totalCoachLimit - coachCount;

  bool get hasActiveBonus {
    if (bonusExpiresAt == null) return false;
    return DateTime.now().isBefore(bonusExpiresAt!);
  }
}

/// Service de contrôle d'accès aux features
/// 
/// Gère les limites freemium et les accès Pro.
class FeatureGateService {
  static final FeatureGateService _instance = FeatureGateService._internal();
  factory FeatureGateService() => _instance;
  FeatureGateService._internal();

  final _supabase = Supabase.instance.client;
  String? _userId;

  /// Initialise le service
  void initialize(String userId) {
    _userId = userId;
  }

  // ═══════════════════════════════════════════════════════════
  // VÉRIFICATIONS
  // ═══════════════════════════════════════════════════════════

  /// Vérifie si l'utilisateur peut utiliser le scanner
  Future<FeatureGateResult> checkScanLimit({required bool isPro}) async {
    if (isPro) {
      return FeatureGateResult.allowed(
        currentUsage: 0,
        limit: -1,
        isPro: true,
      );
    }

    final usage = await _getUsage();
    final limit = usage.totalScanLimit;
    final remaining = usage.scanRemaining;

    if (remaining > 0) {
      return FeatureGateResult.allowed(
        currentUsage: usage.scanCount,
        limit: limit,
        isPro: false,
        hasBonus: usage.scanBonus > 0 && usage.hasActiveBonus,
      );
    }

    // Limite atteinte
    analyticsService.logLimitReached(
      feature: 'scanner',
      limit: FreeLimits.scanPerMonth,
    );

    return FeatureGateResult.limitReached(
      currentUsage: usage.scanCount,
      limit: limit,
      isPro: false,
    );
  }

  /// Vérifie si l'utilisateur peut envoyer un message Coach
  Future<FeatureGateResult> checkCoachLimit({required bool isPro}) async {
    if (isPro) {
      return FeatureGateResult.allowed(
        currentUsage: 0,
        limit: -1,
        isPro: true,
      );
    }

    final usage = await _getUsage();
    final limit = usage.totalCoachLimit;
    final remaining = usage.coachRemaining;

    if (remaining > 0) {
      return FeatureGateResult.allowed(
        currentUsage: usage.coachCount,
        limit: limit,
        isPro: false,
        hasBonus: usage.coachBonus > 0 && usage.hasActiveBonus,
      );
    }

    analyticsService.logLimitReached(
      feature: 'coach',
      limit: FreeLimits.coachMessagesPerMonth,
    );

    return FeatureGateResult.limitReached(
      currentUsage: usage.coachCount,
      limit: limit,
      isPro: false,
    );
  }

  /// Vérifie l'accès aux prédictions
  FeatureGateResult checkPredictions({required bool isPro}) {
    if (isPro) {
      return FeatureGateResult.allowed(
        currentUsage: 30,
        limit: 30,
        isPro: true,
      );
    }

    return FeatureGateResult.allowed(
      currentUsage: FreeLimits.predictionDays,
      limit: FreeLimits.predictionDays,
      isPro: false,
    );
  }

  /// Vérifie l'accès à l'export
  FeatureGateResult checkExport({required bool isPro}) {
    if (isPro) {
      return FeatureGateResult.allowed(
        currentUsage: 0,
        limit: -1,
        isPro: true,
      );
    }

    return FeatureGateResult.proOnly();
  }

  /// Vérifie le nombre de comptes autorisés
  FeatureGateResult checkMultiAccounts({
    required bool isPro,
    required int currentAccounts,
  }) {
    if (isPro) {
      return FeatureGateResult.allowed(
        currentUsage: currentAccounts,
        limit: -1,
        isPro: true,
      );
    }

    if (currentAccounts < FreeLimits.multiAccounts) {
      return FeatureGateResult.allowed(
        currentUsage: currentAccounts,
        limit: FreeLimits.multiAccounts,
        isPro: false,
      );
    }

    return FeatureGateResult.proOnly();
  }

  // ═══════════════════════════════════════════════════════════
  // INCRÉMENTATION
  // ═══════════════════════════════════════════════════════════

  /// Incrémente le compteur de scans
  Future<void> incrementScanCount() async {
    try {
      await _supabase.rpc('increment_scan_count', params: {
        'p_user_id': _userId,
      });

      analyticsService.logFeatureUsed(
        feature: 'scanner',
        count: 1,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur incrémentation scan: $e');
      }
    }
  }

  /// Incrémente le compteur de messages Coach
  Future<void> incrementCoachCount() async {
    try {
      await _supabase.rpc('increment_coach_count', params: {
        'p_user_id': _userId,
      });

      analyticsService.logFeatureUsed(
        feature: 'coach',
        count: 1,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur incrémentation coach: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // BONUS (PUBS RÉCOMPENSÉES)
  // ═══════════════════════════════════════════════════════════

  /// Ajoute des bonus après une pub récompensée
  Future<void> addBonus({
    int scanBonus = 0,
    int coachBonus = 0,
  }) async {
    try {
      await _supabase.rpc('add_usage_bonus', params: {
        'p_user_id': _userId,
        'p_scan_bonus': scanBonus,
        'p_coach_bonus': coachBonus,
      });

      if (kDebugMode) {
        print('✅ Bonus ajouté: +$scanBonus scans, +$coachBonus messages');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur ajout bonus: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // MÉTHODES PRIVÉES
  // ═══════════════════════════════════════════════════════════

  Future<UsageData> _getUsage() async {
    try {
      final response = await _supabase.rpc('get_or_create_usage', params: {
        'p_user_id': _userId,
      });

      return UsageData.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erreur récupération usage: $e');
      }
      // Retourner des valeurs par défaut
      return const UsageData(
        scanCount: 0,
        coachCount: 0,
        scanBonus: 0,
        coachBonus: 0,
      );
    }
  }

  /// Récupère les limites complètes
  Future<Map<String, dynamic>> checkAllLimits({required bool isPro}) async {
    if (isPro) {
      return {
        'scanner': {'used': 0, 'limit': -1, 'remaining': -1},
        'coach': {'used': 0, 'limit': -1, 'remaining': -1},
        'predictions': {'days': 30},
        'export': {'enabled': true},
        'multi_accounts': {'limit': -1},
      };
    }

    final usage = await _getUsage();

    return {
      'scanner': {
        'used': usage.scanCount,
        'limit': usage.totalScanLimit,
        'remaining': usage.scanRemaining,
        'has_bonus': usage.scanBonus > 0 && usage.hasActiveBonus,
      },
      'coach': {
        'used': usage.coachCount,
        'limit': usage.totalCoachLimit,
        'remaining': usage.coachRemaining,
        'has_bonus': usage.coachBonus > 0 && usage.hasActiveBonus,
      },
      'predictions': {'days': FreeLimits.predictionDays},
      'export': {'enabled': false},
      'multi_accounts': {'limit': FreeLimits.multiAccounts},
    };
  }
}

/// Instance globale
final featureGateService = FeatureGateService();
