import 'dart:io';
import 'package:flutter/foundation.dart';

/// Configuration des identifiants publicitaires AdMob
/// 
/// IMPORTANT: En production, remplacez les IDs de test par vos vrais IDs AdMob
/// Obtenez vos IDs sur: https://apps.admob.com
class AdConfig {
  /// Mode test - true en debug, false en production
  static const bool isTestMode = kDebugMode;

  // ═══════════════════════════════════════════════════════════
  // IDs DE TEST (à utiliser uniquement en développement)
  // ═══════════════════════════════════════════════════════════
  
  static const String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedId = 'ca-app-pub-3940256099942544/5224354917';

  //═══════════════════════════════════════════════════════════
  // IDs ANDROID (REMPLACEZ PAR VOS VRAIS IDS AD MOB)
  //═══════════════════════════════════════════════════════════
    
  static const String _androidBannerDashboard = 'ca-app-pub-YOUR_ANDROID_ID/BANNER_DASH';
  static const String _androidBannerTransactions = 'ca-app-pub-YOUR_ANDROID_ID/BANNER_TRANS';
  static const String _androidInterstitial = 'ca-app-pub-YOUR_ANDROID_ID/INTERSTITIAL';
  static const String _androidRewarded = 'ca-app-pub-YOUR_ANDROID_ID/REWARDED';

  // ═══════════════════════════════════════════════════════════
  // IDs iOS (REMPLACEZ PAR VOS VRAIS IDS AD MOB)
  // ═══════════════════════════════════════════════════════════
  
  static const String _iosBannerDashboard = 'ca-app-pub-YOUR_IOS_ID/IOS_BANNER_DASH';
  static const String _iosBannerTransactions = 'ca-app-pub-YOUR_IOS_ID/IOS_BANNER_TRANS';
  static const String _iosInterstitial = 'ca-app-pub-YOUR_IOS_ID/IOS_INTERSTITIAL';
  static const String _iosRewarded = 'ca-app-pub-YOUR_IOS_ID/IOS_REWARDED';

  // ═══════════════════════════════════════════════════════════
  // GETTERS PUBLICS
  // ═══════════════════════════════════════════════════════════

  /// ID du banner pour le dashboard
  static String get bannerDashboardId => isTestMode
      ? _testBannerId
      : Platform.isIOS
          ? _iosBannerDashboard
          : _androidBannerDashboard;

  /// ID du banner pour l'écran des transactions
  static String get bannerTransactionsId => isTestMode
      ? _testBannerId
      : Platform.isIOS
          ? _iosBannerTransactions
          : _androidBannerTransactions;

  /// ID de l'interstitiel
  static String get interstitialId => isTestMode
      ? _testInterstitialId
      : Platform.isIOS
          ? _iosInterstitial
          : _androidInterstitial;

  /// ID de la publicité récompensée
  static String get rewardedId => isTestMode
      ? _testRewardedId
      : Platform.isIOS
          ? _iosRewarded
          : _androidRewarded;

  // ═══════════════════════════════════════════════════════════
  // CONFIGURATION REVENUECAT
  // ═══════════════════════════════════════════════════════════

  /// Clé publique RevenueCat pour iOS
  /// REMPLACEZ PAR VOTRE CLÉ DEPUIS LE DASHBOARD REVENUECAT
  static const String revenueCatPublicKeyIOS = 'REVENUECAT_PUBLIC_SDK_KEY_IOS';

  /// Clé publique RevenueCat pour Android
  /// REMPLACEZ PAR VOTRE CLÉ DEPUIS LE DASHBOARD REVENUECAT
  static const String revenueCatPublicKeyAndroid = 'REVENUECAT_PUBLIC_SDK_KEY_ANDROID';

  /// ID de l'entitlement Pro
  static const String proEntitlementId = 'aura_pro';

  /// Récupère la clé RevenueCat appropriée selon la plateforme
  static String get revenueCatPublicKey =>
      Platform.isIOS ? revenueCatPublicKeyIOS : revenueCatPublicKeyAndroid;

  // ═══════════════════════════════════════════════════════════
  // LIMITES ET CONFIGURATIONS
  // ═══════════════════════════════════════════════════════════

  /// Nombre minimum de transactions avant d'afficher une interstitielle
  static const int minTransactionsForInterstitial = 5;

  /// Intervalle minimum entre deux interstitielles (en secondes)
  static const int interstitialCooldownSeconds = 120;

  /// Nombre de scans gratuits avant de demander la version Pro
  static const int freeScansLimit = 3;

  /// Nombre d'insights IA gratuits par mois
  static const int freeInsightsPerMonth = 5;
}
