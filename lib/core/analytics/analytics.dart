/// Core: Analytics
/// 
/// Services de tracking et d'analytics pour Aura Finance.
/// 
/// ## Monetization Analytics
/// 
/// Track tous les événements liés aux revenus :
/// - Paywall (affichage, fermeture, conversion)
/// - Achats (démarré, complété, échoué)
/// - Publicités (interstitielles, récompensées)
/// - Feature gating (limites atteintes)
/// 
/// Usage:
/// ```dart
/// import 'package:aura_finance/core/analytics/analytics.dart';
/// 
/// // Track affichage paywall
/// monetizationAnalytics.logPaywallShown(
///   trigger: PaywallTrigger.scanLimitReached,
/// );
/// 
/// // Track achat
/// monetizationAnalytics.logPurchaseCompleted(
///   planId: 'aura_pro_annual',
///   revenueCatId: '...',
///   revenue: 39.99,
///   period: 'annual',
/// );
/// ```

export 'monetization_analytics.dart';
