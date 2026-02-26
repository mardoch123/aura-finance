import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/ads/interstitial_ad_service.dart';
import '../features/subscription/presentation/paywall_screen.dart';

/// Service d'analytics pour tracker les événements de monétisation
/// 
/// Envoie les événements à Supabase pour analyse.
/// En production, vous pouvez aussi ajouter Firebase Analytics.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final _supabase = Supabase.instance.client;
  String? _userId;

  /// Initialise le service avec l'ID utilisateur
  void initialize(String userId) {
    _userId = userId;
  }

  // ═══════════════════════════════════════════════════════════
  // PUBLICITÉS
  // ═══════════════════════════════════════════════════════════

  /// Track quand une interstitielle est affichée
  Future<void> logInterstitialShown({
    required String placement,
    required bool success,
  }) async {
    await _logEvent('interstitial_shown', {
      'placement': placement,
      'success': success,
    });
  }

  /// Track quand une pub récompensée est affichée
  Future<void> logRewardedAdShown({
    required RewardType type,
    required RewardResult result,
  }) async {
    await _logEvent('rewarded_ad_shown', {
      'reward_type': type.name,
      'result': result.name,
    });
  }

  /// Track quand une récompense est accordée
  Future<void> logRewardGranted(RewardType type) async {
    await _logEvent('reward_granted', {
      'reward_type': type.name,
      'bonus_amount': type.bonusAmount,
    });
  }

  // ═══════════════════════════════════════════════════════════
  // ABONNEMENTS
  // ═══════════════════════════════════════════════════════════

  /// Track quand le paywall est affiché
  Future<void> logPaywallShown(PaywallTrigger trigger) async {
    await _logEvent('paywall_shown', {
      'trigger': trigger.name,
    });
  }

  /// Track quand l'utilisateur achète
  Future<void> logSubscriptionStarted({
    required String planId,
    required String price,
    required bool hasTrial,
  }) async {
    await _logEvent('subscription_started', {
      'plan_id': planId,
      'price': price,
      'has_trial': hasTrial,
    });
  }

  /// Track quand l'achat est confirmé
  Future<void> logSubscriptionCompleted({
    required String planId,
    required String revenueCatId,
  }) async {
    await _logEvent('subscription_completed', {
      'plan_id': planId,
      'revenuecat_id': revenueCatId,
    });
  }

  /// Track quand l'achat échoue
  Future<void> logSubscriptionFailed({
    required String planId,
    required String error,
  }) async {
    await _logEvent('subscription_failed', {
      'plan_id': planId,
      'error': error,
    });
  }

  /// Track restauration d'achat
  Future<void> logPurchaseRestored({
    required bool success,
    String? error,
  }) async {
    await _logEvent('purchase_restored', {
      'success': success,
      if (error != null) 'error': error,
    });
  }

  // ═══════════════════════════════════════════════════════════
  // LIMITES D'USAGE
  // ═══════════════════════════════════════════════════════════

  /// Track quand une limite est atteinte
  Future<void> logLimitReached({
    required String feature,
    required int limit,
  }) async {
    await _logEvent('limit_reached', {
      'feature': feature,
      'limit': limit,
    });
  }

  /// Track utilisation d'une feature
  Future<void> logFeatureUsed({
    required String feature,
    required int count,
  }) async {
    await _logEvent('feature_used', {
      'feature': feature,
      'count': count,
    });
  }

  // ═══════════════════════════════════════════════════════════
  // MÉTHODE PRIVÉE
  // ═══════════════════════════════════════════════════════════

  Future<void> _logEvent(String eventName, Map<String, dynamic> params) async {
    try {
      final data = {
        'event_name': eventName,
        'user_id': _userId,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': defaultTargetPlatform.name,
        ...params,
      };

      // En mode debug, juste logguer
      if (kDebugMode) {
        print('📊 Analytics: $eventName - $params');
        return;
      }

      // Envoyer à Supabase
      await _supabase.from('analytics_events').insert(data);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erreur analytics: $e');
      }
    }
  }
}

/// Instance globale
final analyticsService = AnalyticsService();
