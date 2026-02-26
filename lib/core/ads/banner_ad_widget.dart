import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../features/subscription/subscription_provider.dart';
import '../theme/aura_colors.dart';
import 'ad_config.dart';

/// Widget de bannière publicitaire adaptative
/// 
/// Affiche une bannière AdMob si:
/// - L'utilisateur n'est pas Pro
/// - Les publicités sont activées
/// 
/// Usage:
/// ```dart
/// BannerAdWidget(
///   adUnitId: AdConfig.bannerDashboardId,
///   onAdLoaded: () => print('Ad loaded'),
/// )
/// ```
class BannerAdWidget extends ConsumerStatefulWidget {
  /// ID de l'unité publicitaire
  final String adUnitId;

  /// Hauteur minimum de la bannière
  final double minHeight;

  /// Callback lorsque la pub est chargée
  final VoidCallback? onAdLoaded;

  /// Callback lorsque la pub échoue à charger
  final VoidCallback? onAdFailed;

  const BannerAdWidget({
    super.key,
    required this.adUnitId,
    this.minHeight = 50,
    this.onAdLoaded,
    this.onAdFailed,
  });

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = true;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadAd() async {
    // Ne pas charger si en mode test sans consentement
    if (!AdConfig.isTestMode && !await _canRequestAds()) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Attendre que la taille de l'écran soit disponible
      await WidgetsBinding.instance.endOfFrame;
      
      final width = MediaQuery.of(context).size.width.truncate();
      
      // Créer la bannière adaptative
      final adSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
        width,
      );

      if (adSize == null) {
        if (kDebugMode) {
          print('❌ Impossible de déterminer la taille de la bannière');
        }
        setState(() => _isLoading = false);
        widget.onAdFailed?.call();
        return;
      }

      _bannerAd = BannerAd(
        adUnitId: widget.adUnitId,
        size: adSize,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (kDebugMode) {
              print('✅ Bannière chargée: ${ad.responseInfo}');
            }
            setState(() {
              _isLoaded = true;
              _isLoading = false;
            });
            widget.onAdLoaded?.call();
          },
          onAdFailedToLoad: (ad, error) {
            if (kDebugMode) {
              print('❌ Erreur bannière: ${error.message}');
            }
            ad.dispose();
            setState(() {
              _isLoaded = false;
              _isLoading = false;
            });
            widget.onAdFailed?.call();
          },
          onAdOpened: (ad) {
            if (kDebugMode) {
              print('📱 Bannière ouverte');
            }
          },
          onAdClosed: (ad) {
            if (kDebugMode) {
              print('📱 Bannière fermée');
            }
          },
        ),
      );

      await _bannerAd!.load();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Exception lors du chargement de la bannière: $e');
      }
      setState(() => _isLoading = false);
      widget.onAdFailed?.call();
    }
  }

  Future<bool> _canRequestAds() async {
    // Vérifier si les pubs sont initialisées
    return true; // Simplifié pour l'exemple
  }

  @override
  Widget build(BuildContext context) {
    // Ne pas afficher si l'utilisateur est Pro
    final isPro = ref.watch(isProProvider);
    if (isPro) {
      return const SizedBox.shrink();
    }

    // Afficher un placeholder pendant le chargement
    if (_isLoading) {
      return Container(
        height: widget.minHeight,
        color: AuraColors.glass.withOpacity(0.1),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AuraColors.amber),
            ),
          ),
        ),
      );
    }

    // Ne rien afficher si la pub n'est pas chargée
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    // Afficher la bannière
    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

/// Bannière publicitaire pour le Dashboard
class DashboardBannerAd extends ConsumerWidget {
  const DashboardBannerAd({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BannerAdWidget(
      adUnitId: AdConfig.bannerDashboardId,
      onAdFailed: () {
        if (kDebugMode) {
          print('Dashboard banner failed to load');
        }
      },
    );
  }
}

/// Bannière publicitaire pour l'écran des Transactions
class TransactionsBannerAd extends ConsumerWidget {
  const TransactionsBannerAd({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BannerAdWidget(
      adUnitId: AdConfig.bannerTransactionsId,
      onAdFailed: () {
        if (kDebugMode) {
          print('Transactions banner failed to load');
        }
      },
    );
  }
}
