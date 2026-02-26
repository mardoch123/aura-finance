import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/ads/interstitial_ad_service.dart';
import '../../../../core/ads/interstitial_ad_manager.dart';
import '../../../../services/usage_limit_service.dart';

/// Mixin pour gérer les publicités dans le scanner
/// 
/// À utiliser avec le ScannerScreen pour :
/// - Afficher une interstitielle après confirmation de scan
/// - Gérer les limites d'usage
/// - Tracker les sessions
/// 
/// Usage:
/// ```dart
/// class _ScannerScreenState extends ConsumerState<ScannerScreen>
///     with WidgetsBindingObserver, ScannerAdMixin {
///   @override
///   void initState() {
///     super.initState();
///     initializeScannerAds();
///   }
///   
///   @override
///   void didChangeAppLifecycleState(AppLifecycleState state) {
///     super.didChangeAppLifecycleState(state);
///     handleAppLifecycleChange(state);
///   }
/// }
/// ```
mixin ScannerAdMixin<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  bool _isAdShowing = false;

  /// Initialise les publicités pour le scanner
  void initializeScannerAds() {
    // Précharger une interstitielle
    interstitialAdService.loadAd();
    
    // Marquer le début de session
    interstitialAdService.markSessionStart();
  }

  /// Gère les changements de cycle de vie de l'app
  void handleAppLifecycleChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // L'app passe en arrière-plan
        _onAppBackgrounded();
        break;
      case AppLifecycleState.resumed:
        // L'app revient au premier plan
        _onAppResumed();
        break;
      default:
        break;
    }
  }

  Future<void> _onAppBackgrounded() async {
    // Afficher une interstitielle si session > 5 minutes
    if (!_isAdShowing) {
      _isAdShowing = true;
      await interstitialAdService.showOnAppBackground();
      _isAdShowing = false;
    }
  }

  void _onAppResumed() {
    // Réinitialiser le début de session
    interstitialAdService.markSessionStart();
    
    // Précharger une nouvelle interstitielle
    interstitialAdService.loadAd();
  }

  /// À appeler après confirmation d'un scan
  /// 
  /// Incrémente le compteur et affiche une interstitielle si applicable
  Future<void> onScanConfirmed() async {
    // Incrémenter le compteur de scans
    await usageLimitService.incrementScanCount();

    // Afficher l'interstitielle (avec délai automatique de 500ms)
    if (!_isAdShowing) {
      _isAdShowing = true;
      await interstitialAdService.showAfterScan();
      _isAdShowing = false;
    }
  }

  /// Vérifie si l'utilisateur peut scanner
  /// 
  /// Affiche un dialog si la limite est atteinte
  Future<bool> checkCanScan(BuildContext context) async {
    // TODO: Récupérer le statut Pro depuis le provider
    const isPro = false; // Remplacer par ref.read(isProProvider)
    
    final result = await usageLimitService.canScan(isPro: isPro);
    
    if (result.allowed) {
      return true;
    }

    // Limite atteinte, afficher le dialog
    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildLimitReachedDialog(context),
      );
    }

    return false;
  }

  Widget _buildLimitReachedDialog(BuildContext context) {
    return AlertDialog(
      title: const Text('Limite atteinte'),
      content: const Text(
        'Vous avez atteint votre limite de scans gratuits ce mois-ci. '
        'Regardez une publicité pour obtenir 3 scans supplémentaires '
        'ou passez à Aura Pro pour un accès illimité.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            final rewarded = await rewardedAdService.showForScanBonus();
            if (rewarded == RewardResult.rewarded && mounted) {
              // Rafraîchir l'UI
              setState(() {});
            }
          },
          child: const Text('Regarder une pub'),
        ),
      ],
    );
  }

  /// Libère les ressources
  void disposeScannerAds() {
    // Synchroniser les compteurs avec Supabase
    usageLimitService.syncWithSupabase();
  }
}

/// Extension pratique pour le contexte
extension ScannerAdContext on BuildContext {
  /// Vérifie les limites avant d'exécuter une action
  Future<bool> checkScanLimit() async {
    // TODO: Implémenter avec le provider
    return true;
  }
}
