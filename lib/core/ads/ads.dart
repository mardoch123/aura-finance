/// Core: Advertising & Monetization
/// 
/// Gère les publicités AdMob et l'initialisation des SDKs de monétisation.
/// 
/// Usage:
/// ```dart
/// import 'package:aura_finance/core/ads/ads.dart';
/// 
/// // Interstitielle après scan
/// await interstitialAdService.showAfterScan();
/// 
/// // Pub récompensée
/// final result = await rewardedAdService.showForScanBonus();
/// 
/// // Carte d'offre
/// AuraRewardedOfferCard(
///   type: RewardType.scanBonus,
///   onRewardEarned: () => reloadData(),
/// )
/// ```

export 'ad_config.dart';
export 'ads_initializer.dart';
export 'banner_ad_widget.dart';
export 'interstitial_ad_manager.dart';
export 'interstitial_ad_service.dart';
export 'rewarded_offer_card.dart';
