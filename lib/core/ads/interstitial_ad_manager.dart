import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_config.dart';

/// Gestionnaire d'interstitielles
/// 
/// Gère le chargement et l'affichage des publicités interstitielles
/// avec un système de cooldown pour ne pas spammer l'utilisateur.
/// 
/// Usage:
/// ```dart
/// await InterstitialAdManager().showIfAllowed();
/// ```
class InterstitialAdManager {
  static final InterstitialAdManager _instance = InterstitialAdManager._internal();
  factory InterstitialAdManager() => _instance;
  InterstitialAdManager._internal();

  InterstitialAd? _interstitialAd;
  bool _isLoading = false;
  DateTime? _lastShownTime;
  int _transactionCount = 0;

  // ═══════════════════════════════════════════════════════════
  // CHARGEMENT
  // ═══════════════════════════════════════════════════════════

  /// Précharge une interstitielle
  Future<void> preload() async {
    if (_isLoading || _interstitialAd != null) return;

    _isLoading = true;

    try {
      await InterstitialAd.load(
        adUnitId: AdConfig.interstitialId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            if (kDebugMode) {
              print('✅ Interstitielle chargée');
            }
            _interstitialAd = ad;
            _isLoading = false;
            _setupAdCallbacks(ad);
          },
          onAdFailedToLoad: (error) {
            if (kDebugMode) {
              print('❌ Erreur chargement interstitielle: ${error.message}');
            }
            _isLoading = false;
            _interstitialAd = null;
          },
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Exception chargement interstitielle: $e');
      }
      _isLoading = false;
    }
  }

  void _setupAdCallbacks(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        if (kDebugMode) {
          print('📱 Interstitielle affichée');
        }
      },
      onAdDismissedFullScreenContent: (ad) {
        if (kDebugMode) {
          print('📱 Interstitielle fermée');
        }
        ad.dispose();
        _interstitialAd = null;
        // Précharger la prochaine
        preload();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        if (kDebugMode) {
          print('❌ Erreur affichage interstitielle: ${error.message}');
        }
        ad.dispose();
        _interstitialAd = null;
      },
      onAdImpression: (ad) {
        if (kDebugMode) {
          print('📊 Impression interstitielle comptabilisée');
        }
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // AFFICHAGE
  // ═══════════════════════════════════════════════════════════

  /// Affiche l'interstitielle si les conditions sont remplies
  /// 
  /// Conditions:
  /// - L'utilisateur a fait au moins [minTransactionsForInterstitial] transactions
  /// - Le cooldown de [interstitialCooldownSeconds] est respecté
  /// - Une pub est disponible
  /// 
  /// Retourne true si la pub a été affichée
  Future<bool> showIfAllowed() async {
    // Vérifier le nombre minimum de transactions
    if (_transactionCount < AdConfig.minTransactionsForInterstitial) {
      _transactionCount++;
      return false;
    }

    // Vérifier le cooldown
    if (_lastShownTime != null) {
      final elapsed = DateTime.now().difference(_lastShownTime!);
      if (elapsed.inSeconds < AdConfig.interstitialCooldownSeconds) {
        if (kDebugMode) {
          print('⏱️ Cooldown interstitielle: ${AdConfig.interstitialCooldownSeconds - elapsed.inSeconds}s restantes');
        }
        return false;
      }
    }

    // Charger si nécessaire
    if (_interstitialAd == null) {
      await preload();
      // Attendre un peu le chargement
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Afficher si disponible
    if (_interstitialAd != null) {
      await _interstitialAd!.show();
      _lastShownTime = DateTime.now();
      _transactionCount = 0;
      return true;
    }

    return false;
  }

  /// Force l'affichage d'une interstitielle (sans conditions)
  /// 
  /// À utiliser avec précaution (ex: après une action spécifique)
  Future<bool> show() async {
    if (_interstitialAd == null) {
      await preload();
      await Future.delayed(const Duration(seconds: 1));
    }

    if (_interstitialAd != null) {
      await _interstitialAd!.show();
      _lastShownTime = DateTime.now();
      return true;
    }

    return false;
  }

  // ═══════════════════════════════════════════════════════════
  // GESTION
  // ═══════════════════════════════════════════════════════════

  /// Incrémente le compteur de transactions
  void incrementTransactionCount() {
    _transactionCount++;
  }

  /// Réinitialise le compteur de transactions
  void resetTransactionCount() {
    _transactionCount = 0;
  }

  /// Dispose la pub actuelle
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }

  /// Vérifie si une pub est prête à être affichée
  bool get isReady => _interstitialAd != null;
}

/// Extension pratique pour les widgets
extension InterstitialAdExtension on InterstitialAdManager {
  /// Affiche une interstitielle après une action utilisateur
  /// 
  /// Exemple: après avoir ajouté une transaction
  Future<void> showAfterAction() async {
    incrementTransactionCount();
    await showIfAllowed();
  }
}
