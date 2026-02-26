import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/subscription/presentation/paywall_screen.dart';
import '../ads/interstitial_ad_service.dart';
import '../subscription/feature_gate_service.dart';

/// Service d'analytics dédié à la monétisation
/// 
/// Track tous les événements liés aux revenus :
/// - Paywall (affichage, fermeture, conversion)
/// - Achats (démarré, complété, échoué)
/// - Publicités (interstitielles, récompensées)
/// - Feature gating (limites atteintes)
/// 
/// Les events sont envoyés à Supabase (table analytics_events)
/// et peuvent aussi être forwardés à Firebase Analytics.
class MonetizationAnalytics {
  static final MonetizationAnalytics _instance = MonetizationAnalytics._internal();
  factory MonetizationAnalytics() => _instance;
  MonetizationAnalytics._internal();

  final _supabase = Supabase.instance.client;
  String? _userId;

  /// Initialise le service
  void initialize(String userId) {
    _userId = userId;
  }

  // ═══════════════════════════════════════════════════════════
  // PAYWALL EVENTS
  // ═══════════════════════════════════════════════════════════

  /// Track quand le paywall est affiché
  Future<void> logPaywallShown({
    required PaywallTrigger trigger,
    String? planPreselected,
  }) async {
    await _track('paywall_shown', {
      'trigger': trigger.name,
      'plan_preselected': planPreselected,
      'screen': 'paywall_screen',
    });
  }

  /// Track quand le paywall est fermé sans achat
  Future<void> logPaywallDismissed({
    required PaywallTrigger trigger,
    required Duration timeOnScreen,
  }) async {
    await _track('paywall_dismissed', {
      'trigger': trigger.name,
      'time_on_screen_ms': timeOnScreen.inMilliseconds,
      'time_on_screen_seconds': timeOnScreen.inSeconds,
    });
  }

  /// Track quand l'utilisateur sélectionne un plan
  Future<void> logPlanSelected({
    required String planId,
    required String price,
    required String period, // 'weekly' | 'annual'
  }) async {
    await _track('plan_selected', {
      'plan_id': planId,
      'price': price,
      'period': period,
    });
  }

  // ═══════════════════════════════════════════════════════════
  // PURCHASE EVENTS
  // ═══════════════════════════════════════════════════════════

  /// Track début d'un achat
  Future<void> logPurchaseStarted({
    required String planId,
    required String price,
    bool hasTrial = true,
  }) async {
    await _track('purchase_started', {
      'plan_id': planId,
      'price': price,
      'has_trial': hasTrial,
      'currency': 'USD', // TODO: Adapter selon la locale
    });
  }

  /// Track achat complété avec succès
  Future<void> logPurchaseCompleted({
    required String planId,
    required String revenueCatId,
    required double revenue,
    required String period,
    String? trialConverted,
  }) async {
    await _track('purchase_completed', {
      'plan_id': planId,
      'revenuecat_id': revenueCatId,
      'revenue': revenue,
      'period': period,
      'currency': 'USD',
      if (trialConverted != null) 'trial_converted': trialConverted,
    });
  }

  /// Track échec d'achat
  Future<void> logPurchaseFailed({
    required String planId,
    required String error,
    String? errorCode,
  }) async {
    await _track('purchase_failed', {
      'plan_id': planId,
      'error': error,
      if (errorCode != null) 'error_code': errorCode,
    });
  }

  /// Track restauration d'achat
  Future<void> logRestorePurchaseTapped() async {
    await _track('restore_purchase_tapped', {});
  }

  /// Track résultat de la restauration
  Future<void> logRestorePurchaseResult({
    required bool success,
    String? error,
    int? productsRestored,
  }) async {
    await _track('restore_purchase_result', {
      'success': success,
      if (error != null) 'error': error,
      if (productsRestored != null) 'products_restored': productsRestored,
    });
  }

  // ═══════════════════════════════════════════════════════════
  // REWARDED AD EVENTS
  // ═══════════════════════════════════════════════════════════

  /// Track affichage d'une pub récompensée
  Future<void> logRewardedAdShown({
    required RewardType context,
    String? placement,
  }) async {
    await _track('rewarded_ad_shown', {
      'context': context.name,
      'reward_type': context.displayName,
      if (placement != null) 'placement': placement,
    });
  }

  /// Track pub récompensée complétée (utilisateur a regardé jusqu'au bout)
  Future<void> logRewardedAdCompleted({
    required RewardType context,
    required int rewardAmount,
  }) async {
    await _track('rewarded_ad_completed', {
      'context': context.name,
      'reward_amount': rewardAmount,
      'reward_type': context.displayName,
    });
  }

  /// Track pub récompensée ignorée (fermée avant la fin)
  Future<void> logRewardedAdSkipped({
    required RewardType context,
    int? watchDurationSeconds,
  }) async {
    await _track('rewarded_ad_skipped', {
      'context': context.name,
      if (watchDurationSeconds != null)
        'watch_duration_seconds': watchDurationSeconds,
    });
  }

  /// Track récompense accordée
  Future<void> logRewardGranted({
    required RewardType type,
    required int amount,
  }) async {
    await _track('reward_granted', {
      'reward_type': type.name,
      'amount': amount,
    });
  }

  // ═══════════════════════════════════════════════════════════
  // INTERSTITIAL EVENTS
  // ═══════════════════════════════════════════════════════════

  /// Track affichage d'une interstitielle
  Future<void> logInterstitialShown({
    required String trigger,
    bool success = true,
    String? error,
  }) async {
    await _track('interstitial_shown', {
      'trigger': trigger,
      'success': success,
      if (error != null) 'error': error,
    });
  }

  /// Track impression d'une interstitielle (pub réellement vue)
  Future<void> logInterstitialImpression({
    required String trigger,
  }) async {
    await _track('interstitial_impression', {
      'trigger': trigger,
    });
  }

  /// Track fermeture d'une interstitielle
  Future<void> logInterstitialDismissed({
    required String trigger,
    required Duration displayDuration,
  }) async {
    await _track('interstitial_dismissed', {
      'trigger': trigger,
      'display_duration_ms': displayDuration.inMilliseconds,
    });
  }

  // ═══════════════════════════════════════════════════════════
  // FEATURE GATE EVENTS
  // ═══════════════════════════════════════════════════════════

  /// Track quand une limite de feature est atteinte
  Future<void> logFeatureGateHit({
    required AuraFeature feature,
    required int currentUsage,
    required int limit,
    bool hasBonus = false,
  }) async {
    await _track('feature_gate_hit', {
      'feature': feature.name,
      'feature_display': feature.displayName,
      'current_usage': currentUsage,
      'limit': limit,
      'has_bonus': hasBonus,
    });
  }

  /// Track quand l'utilisateur choisit de regarder une pub depuis le gate
  Future<void> logFeatureGateWatchAd({
    required AuraFeature feature,
  }) async {
    await _track('feature_gate_watch_ad', {
      'feature': feature.name,
    });
  }

  /// Track quand l'utilisateur choisit d'aller vers le paywall depuis le gate
  Future<void> logFeatureGateGoPro({
    required AuraFeature feature,
  }) async {
    await _track('feature_gate_go_pro', {
      'feature': feature.name,
    });
  }

  // ═══════════════════════════════════════════════════════════
  // SUBSCRIPTION LIFECYCLE
  // ═══════════════════════════════════════════════════════════

  /// Track conversion d'essai gratuit → payant
  Future<void> logTrialConverted({
    required String planId,
    required int trialDaysUsed,
    required double revenue,
  }) async {
    await _track('trial_converted', {
      'plan_id': planId,
      'trial_days_used': trialDaysUsed,
      'revenue': revenue,
    });
  }

  /// Track expiration d'un abonnement
  Future<void> logSubscriptionExpired({
    required String planId,
    required String reason, // 'cancellation' | 'billing_issue' | 'unknown'
  }) async {
    await _track('subscription_expired', {
      'plan_id': planId,
      'reason': reason,
    });
  }

  /// Track renouvellement d'abonnement
  Future<void> logSubscriptionRenewed({
    required String planId,
    required double revenue,
    required int renewalCount,
  }) async {
    await _track('subscription_renewed', {
      'plan_id': planId,
      'revenue': revenue,
      'renewal_count': renewalCount,
    });
  }

  // ═══════════════════════════════════════════════════════════
  // MÉTHODE PRIVÉE
  // ═══════════════════════════════════════════════════════════

  Future<void> _track(String eventName, Map<String, dynamic> params) async {
    try {
      final data = {
        'event_name': eventName,
        'user_id': _userId,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': defaultTargetPlatform.name,
        'params': params,
        // Champs dénormalisés pour faciliter les requêtes
        if (params['trigger'] != null) 'placement': params['trigger'],
        if (params['plan_id'] != null) 'plan_id': params['plan_id'],
        if (params['feature'] != null) 'feature': params['feature'],
        if (params['context'] != null) 'reward_type': params['context'],
      };

      // En mode debug, juste logguer
      if (kDebugMode) {
        print('📊 MonetizationAnalytics: $eventName');
        print('   Params: $params');
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
final monetizationAnalytics = MonetizationAnalytics();

/// Extension pour faciliter l'utilisation
extension MonetizationAnalyticsExtension on MonetizationAnalytics {
  /// Track un funnel complet de paywall
  Future<T> trackPaywallFunnel<T>({
    required PaywallTrigger trigger,
    required Future<T> Function() action,
    String? planPreselected,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    // Track affichage
    await logPaywallShown(
      trigger: trigger,
      planPreselected: planPreselected,
    );

    try {
      final result = await action();
      
      // Track fermeture (succès = achat ou fermeture volontaire)
      stopwatch.stop();
      await logPaywallDismissed(
        trigger: trigger,
        timeOnScreen: stopwatch.elapsed,
      );
      
      return result;
    } catch (e) {
      stopwatch.stop();
      await logPaywallDismissed(
        trigger: trigger,
        timeOnScreen: stopwatch.elapsed,
      );
      rethrow;
    }
  }
}
