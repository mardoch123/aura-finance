import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../haptics/haptic_service.dart';
import 'ad_config.dart';

/// Service de gestion des publicités interstitielles (plein écran)
/// 
/// Stratégie d'affichage non-intrusive:
/// - Après confirmation d'un scan (délai 500ms)
/// - À la fermeture de l'app après 5+ minutes de session
/// - À l'ouverture de l'app (1 fois toutes les 3 ouvertures)
/// 
/// Limites:
/// - Max 1 interstitielle toutes les 3 minutes
/// - Jamais pendant un scan ou une saisie
/// - Jamais si une bannière a été vue il y a < 30 secondes
class InterstitialAdService {
  static final InterstitialAdService _instance = InterstitialAdService._internal();
  factory InterstitialAdService() => _instance;
  InterstitialAdService._internal();

  InterstitialAd? _interstitialAd;
  int _numLoadAttempts = 0;
  static const int _maxFailedLoadAttempts = 3;

  // Tracking de fréquence
  DateTime? _lastShownAt;
  DateTime? _lastBannerShownAt;
  DateTime? _sessionStartTime;
  int _scanCount = 0;

  // Clés SharedPreferences
  static const String _prefAppOpenCount = 'interstitial_app_open_count';
  static const String _prefLastOpenDate = 'interstitial_last_open_date';

  // ═══════════════════════════════════════════════════════════
  // INITIALISATION
  // ═══════════════════════════════════════════════════════════

  /// Initialise le service et charge une première interstitielle
  Future<void> initialize() async {
    await _incrementAppOpenCount();
    _sessionStartTime = DateTime.now();
    await loadAd();
  }

  /// Incrémente le compteur d'ouvertures d'app (stocké par jour)
  Future<void> _incrementAppOpenCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final lastOpenDate = prefs.getString(_prefLastOpenDate);

      int count = 0;
      if (lastOpenDate == today) {
        count = prefs.getInt(_prefAppOpenCount) ?? 0;
      }

      count++;
      await prefs.setInt(_prefAppOpenCount, count);
      await prefs.setString(_prefLastOpenDate, today);

      if (kDebugMode) {
        print('📱 Ouverture d\'app #$today: $count');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erreur compteur d\'ouvertures: $e');
      }
    }
  }

  /// Récupère le compteur d'ouvertures d'aujourd'hui
  Future<int> _getTodayAppOpenCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final lastOpenDate = prefs.getString(_prefLastOpenDate);

      if (lastOpenDate == today) {
        return prefs.getInt(_prefAppOpenCount) ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CHARGEMENT
  // ═══════════════════════════════════════════════════════════

  /// Charge une interstitielle
  Future<void> loadAd() async {
    if (_interstitialAd != null) return;

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
            _numLoadAttempts = 0;
            _setupAdCallbacks(ad);
          },
          onAdFailedToLoad: (error) {
            if (kDebugMode) {
              print('❌ Erreur chargement interstitielle: ${error.message}');
            }
            _interstitialAd = null;
            _numLoadAttempts++;

            // Retry avec backoff
            if (_numLoadAttempts < _maxFailedLoadAttempts) {
              final delay = Duration(seconds: _numLoadAttempts * 2);
              Future.delayed(delay, loadAd);
            }
          },
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Exception chargement interstitielle: $e');
      }
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
        loadAd(); // Précharger la prochaine
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        if (kDebugMode) {
          print('❌ Erreur affichage interstitielle: ${error.message}');
        }
        ad.dispose();
        _interstitialAd = null;
      },
      onAdImpression: (ad) {
        _lastShownAt = DateTime.now();
        if (kDebugMode) {
          print('📊 Impression interstitielle comptabilisée');
        }
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CONDITIONS D'AFFICHAGE
  // ═══════════════════════════════════════════════════════════

  /// Vérifie si l'affichage est autorisé (cooldown, etc.)
  bool _canShow() {
    // Vérifier le cooldown de 3 minutes
    if (_lastShownAt != null) {
      final elapsed = DateTime.now().difference(_lastShownAt!);
      if (elapsed < const Duration(minutes: 3)) {
        if (kDebugMode) {
          print('⏱️ Cooldown actif: ${3 - elapsed.inMinutes}min restantes');
        }
        return false;
      }
    }

    // Vérifier si une bannière a été vue récemment (< 30s)
    if (_lastBannerShownAt != null) {
      final elapsed = DateTime.now().difference(_lastBannerShownAt!);
      if (elapsed < const Duration(seconds: 30)) {
        if (kDebugMode) {
          print('⏱️ Bannière vue récemment, attente...');
        }
        return false;
      }
    }

    return true;
  }

  /// Affiche l'interstitielle si prête
  Future<bool> _showIfReady() async {
    if (!_canShow()) return false;
    if (_interstitialAd == null) {
      // Tenter de charger et attendre un peu
      await loadAd();
      await Future.delayed(const Duration(milliseconds: 500));
      if (_interstitialAd == null) return false;
    }

    try {
      await _interstitialAd!.show();
      _interstitialAd = null;
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur show interstitielle: $e');
      }
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // POINTS DE DÉCLENCHEMENT
  // ═══════════════════════════════════════════════════════════

  /// À appeler après confirmation d'un scan
  /// 
  /// Affiche l'interstitielle après le 2ème scan, puis 1/3 scans
  Future<bool> showAfterScan() async {
    _scanCount++;

    // Affiche seulement après le 2ème scan, puis tous les 3 scans
    if (_scanCount < 2 || _scanCount % 3 != 0) {
      return false;
    }

    // Délai de 500ms pour ne pas interrompre l'animation de confirmation
    await Future.delayed(const Duration(milliseconds: 500));

    return _showIfReady();
  }

  /// À appeler à l'ouverture de l'app
  /// 
  /// Affiche max 1 fois toutes les 3 ouvertures
  Future<bool> showOnAppOpen() async {
    final openCount = await _getTodayAppOpenCount();

    // Afficher aux ouvertures 1, 4, 7, 10... (tous les 3)
    if (openCount % 3 != 1) {
      return false;
    }

    return _showIfReady();
  }

  /// À appeler quand l'app passe en arrière-plan
  /// 
  /// Affiche si la session a duré plus de 5 minutes
  Future<bool> showOnAppBackground() async {
    if (_sessionStartTime == null) return false;

    final sessionDuration = DateTime.now().difference(_sessionStartTime!);
    if (sessionDuration < const Duration(minutes: 5)) {
      return false;
    }

    return _showIfReady();
  }

  // ═══════════════════════════════════════════════════════════
  // UTILITAIRES
  // ═══════════════════════════════════════════════════════════

  /// Signale qu'une bannière a été affichée (pour le cooldown)
  void notifyBannerShown() {
    _lastBannerShownAt = DateTime.now();
  }

  /// Réinitialise le compteur de scans (nouvelle session)
  void resetScanCount() {
    _scanCount = 0;
  }

  /// Définit le début de session (pour le calcul de durée)
  void markSessionStart() {
    _sessionStartTime = DateTime.now();
  }

  /// Vérifie si une interstitielle est prête à être affichée
  bool get isReady => _interstitialAd != null && _canShow();

  /// Dispose la ressource
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}

/// Instance globale du service
final interstitialAdService = InterstitialAdService();

// ═══════════════════════════════════════════════════════════
// REWARDED ADS (Publicités récompensées)
// ═══════════════════════════════════════════════════════════

/// Résultat d'une publicité récompensée
enum RewardResult {
  /// L'utilisateur a regardé la pub et reçu la récompense
  rewarded,
  /// L'utilisateur a fermé la pub sans regarder jusqu'au bout
  skipped,
  /// La pub n'était pas prête
  adNotReady,
  /// Erreur lors de l'affichage
  error,
}

/// Types de bonus disponibles
enum RewardType {
  /// +3 scans IA
  scanBonus,
  /// +5 messages Coach IA
  coachBonus,
  /// Déverrouiller le rapport mensuel
  monthlyReport,
}

/// Extension pour obtenir le nombre de bonus
extension RewardTypeExtension on RewardType {
  int get bonusAmount {
    switch (this) {
      case RewardType.scanBonus:
        return 3;
      case RewardType.coachBonus:
        return 5;
      case RewardType.monthlyReport:
        return 1;
    }
  }

  String get displayName {
    switch (this) {
      case RewardType.scanBonus:
        return '+3 scans IA';
      case RewardType.coachBonus:
        return '+5 messages Coach';
      case RewardType.monthlyReport:
        return 'Rapport mensuel';
    }
  }

  String get description {
    switch (this) {
      case RewardType.scanBonus:
        return 'Scanner IA (5/5 ce mois)';
      case RewardType.coachBonus:
        return 'Messages Coach (10/10 ce mois)';
      case RewardType.monthlyReport:
        return 'Rapport détaillé bloqué';
    }
  }
}

/// Service de gestion des publicités récompensées
/// 
/// L'utilisateur CHOISIT de regarder une pub pour débloquer une récompense.
/// Format le moins intrusif et le plus apprécié.
class RewardedAdService {
  static final RewardedAdService _instance = RewardedAdService._internal();
  factory RewardedAdService() => _instance;
  RewardedAdService._internal();

  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  // ═══════════════════════════════════════════════════════════
  // CHARGEMENT
  // ═══════════════════════════════════════════════════════════

  /// Charge une publicité récompensée
  Future<void> loadAd() async {
    if (_isLoading || _rewardedAd != null) return;
    _isLoading = true;

    try {
      await RewardedAd.load(
        adUnitId: AdConfig.rewardedId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (kDebugMode) {
              print('✅ Rewarded ad chargée');
            }
            _rewardedAd = ad;
            _isLoading = false;
          },
          onAdFailedToLoad: (error) {
            if (kDebugMode) {
              print('❌ Erreur chargement rewarded: ${error.message}');
            }
            _rewardedAd = null;
            _isLoading = false;
          },
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Exception chargement rewarded: $e');
      }
      _isLoading = false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // AFFICHAGE
  // ═══════════════════════════════════════════════════════════

  /// Affiche une pub récompensée pour obtenir un bonus
  /// 
  /// [type] Détermine le type de récompense
  /// Retourne le résultat de l'opération
  Future<RewardResult> showForReward(RewardType type) async {
    if (_rewardedAd == null) {
      await loadAd();
      await Future.delayed(const Duration(milliseconds: 500));
      if (_rewardedAd == null) return RewardResult.adNotReady;
    }

    final completer = Completer<RewardResult>();

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        if (kDebugMode) {
          print('📱 Rewarded ad affichée');
        }
      },
      onAdDismissedFullScreenContent: (ad) {
        if (kDebugMode) {
          print('📱 Rewarded ad fermée');
        }
        ad.dispose();
        _rewardedAd = null;
        loadAd(); // Précharger la prochaine

        // Si pas encore complété = utilisateur a quitté sans regarder
        if (!completer.isCompleted) {
          completer.complete(RewardResult.skipped);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        if (kDebugMode) {
          print('❌ Erreur show rewarded: ${error.message}');
        }
        ad.dispose();
        _rewardedAd = null;
        if (!completer.isCompleted) {
          completer.complete(RewardResult.error);
        }
      },
    );

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          if (kDebugMode) {
            print('🎁 Récompense gagnée: ${reward.amount} ${reward.type}');
          }
          _grantReward(type);
          HapticService.success();
          if (!completer.isCompleted) {
            completer.complete(RewardResult.rewarded);
          }
        },
      );
      _rewardedAd = null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Exception show rewarded: $e');
      }
      if (!completer.isCompleted) {
        completer.complete(RewardResult.error);
      }
    }

    return completer.future;
  }

  /// Méthode pratique pour les scans
  Future<RewardResult> showForScanBonus() => showForReward(RewardType.scanBonus);

  /// Méthode pratique pour le Coach
  Future<RewardResult> showForCoachBonus() => showForReward(RewardType.coachBonus);

  /// Méthode pratique pour le rapport mensuel
  Future<RewardResult> showForMonthlyReport() => showForReward(RewardType.monthlyReport);

  // ═══════════════════════════════════════════════════════════
  // RÉCOMPENSES
  // ═══════════════════════════════════════════════════════════

  /// Accorde la récompense à l'utilisateur
  /// 
  /// Stocke le bonus dans SharedPreferences (expire à minuit)
  Future<void> _grantReward(RewardType type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day + 1);

      switch (type) {
        case RewardType.scanBonus:
          await prefs.setInt('rewarded_scan_bonus', type.bonusAmount);
          await prefs.setString('rewarded_scan_expires', midnight.toIso8601String());
          break;
        case RewardType.coachBonus:
          await prefs.setInt('rewarded_coach_bonus', type.bonusAmount);
          await prefs.setString('rewarded_coach_expires', midnight.toIso8601String());
          break;
        case RewardType.monthlyReport:
          await prefs.setBool('rewarded_monthly_report_unlocked', true);
          await prefs.setString('rewarded_report_expires', midnight.toIso8601String());
          break;
      }

      if (kDebugMode) {
        print('✅ Bonus accordé: ${type.displayName} (expire à minuit)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur attribution bonus: $e');
      }
    }
  }

  /// Vérifie si un bonus de scan est actif
  Future<int> getActiveScanBonus() async {
    return _getActiveBonus('rewarded_scan_bonus', 'rewarded_scan_expires');
  }

  /// Vérifie si un bonus de coach est actif
  Future<int> getActiveCoachBonus() async {
    return _getActiveBonus('rewarded_coach_bonus', 'rewarded_coach_expires');
  }

  /// Vérifie si le rapport mensuel est déverrouillé
  Future<bool> isMonthlyReportUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    final unlocked = prefs.getBool('rewarded_monthly_report_unlocked') ?? false;
    if (!unlocked) return false;

    final expiresStr = prefs.getString('rewarded_report_expires');
    if (expiresStr == null) return false;

    final expires = DateTime.tryParse(expiresStr);
    if (expires == null) return false;

    if (DateTime.now().isAfter(expires)) {
      // Expiré, nettoyer
      await prefs.remove('rewarded_monthly_report_unlocked');
      await prefs.remove('rewarded_report_expires');
      return false;
    }

    return true;
  }

  Future<int> _getActiveBonus(String bonusKey, String expiryKey) async {
    final prefs = await SharedPreferences.getInstance();
    final bonus = prefs.getInt(bonusKey) ?? 0;
    if (bonus == 0) return 0;

    final expiresStr = prefs.getString(expiryKey);
    if (expiresStr == null) return 0;

    final expires = DateTime.tryParse(expiresStr);
    if (expires == null) return 0;

    if (DateTime.now().isAfter(expires)) {
      // Expiré, nettoyer
      await prefs.remove(bonusKey);
      await prefs.remove(expiryKey);
      return 0;
    }

    return bonus;
  }

  // ═══════════════════════════════════════════════════════════
  // UTILITAIRES
  // ═══════════════════════════════════════════════════════════

  /// Vérifie si une pub récompensée est prête
  bool get isReady => _rewardedAd != null;

  /// Dispose la ressource
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}

/// Instance globale du service
final rewardedAdService = RewardedAdService();
