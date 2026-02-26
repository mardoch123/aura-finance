import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/ads/ad_config.dart';
import '../../core/haptics/haptic_service.dart';
import '../../services/supabase_service.dart';

part 'subscription_provider.freezed.dart';
part 'subscription_provider.g.dart';

// ═══════════════════════════════════════════════════════════
// ÉTATS
// ═══════════════════════════════════════════════════════════

/// État de l'abonnement utilisateur
@freezed
class SubscriptionState with _$SubscriptionState {
  const factory SubscriptionState.loading() = _Loading;
  const factory SubscriptionState.purchasing() = _Purchasing;
  const factory SubscriptionState.restoring() = _Restoring;
  const factory SubscriptionState.data({
    required bool isPro,
    CustomerInfo? customerInfo,
    Offerings? offerings,
  }) = _Data;
  const factory SubscriptionState.error({
    required String message,
    SubscriptionErrorType? errorType,
  }) = _Error;
}

/// Types d'erreurs d'abonnement
enum SubscriptionErrorType {
  networkError,
  purchaseCancelled,
  productNotFound,
  alreadyPurchased,
  paymentFailed,
  unknown,
}

// ═══════════════════════════════════════════════════════════
// NOTIFIER
// ═══════════════════════════════════════════════════════════

/// Gestionnaire d'abonnement et achats in-app
/// 
/// Utilise RevenueCat pour gérer les abonnements et synchronise
/// l'état Pro avec Supabase pour les Edge Functions IA.
@riverpod
class SubscriptionNotifier extends _$SubscriptionNotifier {
  @override
  SubscriptionState build() => const SubscriptionState.loading();

  // ═══════════════════════════════════════════════════════════
  // INITIALISATION
  // ═══════════════════════════════════════════════════════════

  /// Vérifie le statut d'abonnement au démarrage de l'app
  Future<void> checkSubscriptionStatus() async {
    try {
      state = const SubscriptionState.loading();

      // Récupérer les informations client RevenueCat
      final customerInfo = await Purchases.getCustomerInfo();
      
      // Récupérer les offres disponibles
      Offerings? offerings;
      try {
        offerings = await Purchases.getOfferings();
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Impossible de récupérer les offres: $e');
        }
      }

      final isPro = _checkIsPro(customerInfo);

      // Synchroniser avec Supabase
      await _syncWithSupabase(isPro, customerInfo);

      state = SubscriptionState.data(
        isPro: isPro,
        customerInfo: customerInfo,
        offerings: offerings,
      );

      if (kDebugMode) {
        print('✅ Statut abonnement: ${isPro ? "PRO" : "Gratuit"}');
      }
    } on PurchasesErrorCode catch (e) {
      _handlePurchasesError(e);
    } catch (e) {
      state = SubscriptionState.error(
        message: 'Erreur lors de la vérification: $e',
        errorType: SubscriptionErrorType.unknown,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ACHATS
  // ═══════════════════════════════════════════════════════════

  /// Achète un package spécifique
  /// 
  /// [packageId] - L'identifiant du package (ex: 'aura_monthly', 'aura_yearly')
  /// Retourne true si l'achat a réussi et l'utilisateur est maintenant Pro
  Future<bool> purchasePackage(String packageId) async {
    try {
      state = const SubscriptionState.purchasing();
      HapticService.mediumTap();

      // Récupérer les offres
      final offerings = await Purchases.getOfferings();
      final offering = offerings.current;

      if (offering == null) {
        throw Exception('Aucune offre disponible');
      }

      // Trouver le package correspondant
      final package = offering.availablePackages.firstWhere(
        (p) => p.identifier == packageId,
        orElse: () => throw Exception('Plan introuvable: $packageId'),
      );

      // Effectuer l'achat
      final customerInfo = await Purchases.purchasePackage(package);
      final isPro = _checkIsPro(customerInfo);

      if (isPro) {
        HapticService.success();
        await _syncWithSupabase(isPro, customerInfo);
        
        // Mettre à jour l'état avec les nouvelles infos
        state = SubscriptionState.data(
          isPro: isPro,
          customerInfo: customerInfo,
          offerings: offerings,
        );
        
        return true;
      }

      // Achat effectué mais pas encore Pro (peut-être en attente)
      state = SubscriptionState.data(
        isPro: false,
        customerInfo: customerInfo,
        offerings: offerings,
      );
      return false;

    } on PurchasesErrorCode catch (e) {
      _handlePurchasesError(e);
      return false;
    } catch (e) {
      state = SubscriptionState.error(
        message: 'Erreur lors de l\'achat: $e',
        errorType: SubscriptionErrorType.unknown,
      );
      HapticService.error();
      return false;
    }
  }

  /// Achète un produit directement (alternative à purchasePackage)
  Future<bool> purchaseProduct(String productIdentifier) async {
    try {
      state = const SubscriptionState.purchasing();
      HapticService.mediumTap();

      final products = await Purchases.getProducts([productIdentifier]);
      
      if (products.isEmpty) {
        throw Exception('Produit non trouvé: $productIdentifier');
      }

      final customerInfo = await Purchases.purchaseProduct(products.first);
      final isPro = _checkIsPro(customerInfo);

      if (isPro) {
        HapticService.success();
        await _syncWithSupabase(isPro, customerInfo);
        await checkSubscriptionStatus(); // Rafraîchir l'état
        return true;
      }

      return false;

    } on PurchasesErrorCode catch (e) {
      _handlePurchasesError(e);
      return false;
    } catch (e) {
      state = SubscriptionState.error(
        message: 'Erreur lors de l\'achat: $e',
        errorType: SubscriptionErrorType.unknown,
      );
      HapticService.error();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // RESTAURATION
  // ═══════════════════════════════════════════════════════════

  /// Restaure les achats précédents
  /// 
  /// À appeler lorsque l'utilisateur change d'appareil ou
  /// réinstalle l'application
  Future<bool> restorePurchases() async {
    try {
      state = const SubscriptionState.restoring();

      final customerInfo = await Purchases.restorePurchases();
      final isPro = _checkIsPro(customerInfo);

      // Synchroniser avec Supabase
      await _syncWithSupabase(isPro, customerInfo);

      // Rafraîchir les offres
      Offerings? offerings;
      try {
        offerings = await Purchases.getOfferings();
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Impossible de récupérer les offres: $e');
        }
      }

      state = SubscriptionState.data(
        isPro: isPro,
        customerInfo: customerInfo,
        offerings: offerings,
      );

      HapticService.success();
      
      if (kDebugMode) {
        print('✅ Achats restaurés: ${isPro ? "PRO" : "Gratuit"}');
      }

      return isPro;
    } on PurchasesErrorCode catch (e) {
      _handlePurchasesError(e);
      return false;
    } catch (e) {
      state = SubscriptionState.error(
        message: 'Impossible de restaurer les achats: $e',
        errorType: SubscriptionErrorType.unknown,
      );
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // GESTION PRO
  // ═══════════════════════════════════════════════════════════

  /// Vérifie si l'utilisateur a un abonnement Pro actif
  bool _checkIsPro(CustomerInfo customerInfo) {
    final entitlement = customerInfo.entitlements.all[AdConfig.proEntitlementId];
    return entitlement != null && entitlement.isActive;
  }

  /// Synchronise le statut Pro avec Supabase
  /// 
  /// Nécessaire pour que les Edge Functions IA vérifient
  /// les permissions de l'utilisateur
  Future<void> _syncWithSupabase(bool isPro, CustomerInfo customerInfo) async {
    try {
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId == null) return;

      final entitlement = customerInfo.entitlements.all[AdConfig.proEntitlementId];
      
      final updateData = {
        'is_pro': isPro,
        'pro_entitlement_id': AdConfig.proEntitlementId,
        if (isPro && entitlement != null) ...{
          'pro_expires_at': entitlement.expirationDate?.toIso8601String(),
          'pro_purchase_date': entitlement.originalPurchaseDate?.toIso8601String(),
        },
        'updated_at': DateTime.now().toIso8601String(),
      };

      await SupabaseService.instance.client
          .from('profiles')
          .update(updateData)
          .eq('id', userId);

      if (kDebugMode) {
        print('✅ Statut Pro synchronisé avec Supabase');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erreur sync Supabase: $e');
      }
      // Ne pas bloquer en cas d'erreur de sync
    }
  }

  // ═══════════════════════════════════════════════════════════
  // GESTION DES ERREURS
  // ═══════════════════════════════════════════════════════════

  void _handlePurchasesError(PurchasesErrorCode error) {
    SubscriptionErrorType errorType;
    String message;

    switch (error) {
      case PurchasesErrorCode.purchaseCancelledError:
        errorType = SubscriptionErrorType.purchaseCancelled;
        message = 'Achat annulé';
        // Retourner à l'état précédent sans erreur
        checkSubscriptionStatus();
        return;
      case PurchasesErrorCode.productAlreadyPurchasedError:
        errorType = SubscriptionErrorType.alreadyPurchased;
        message = 'Vous avez déjà acheté ce produit';
        break;
      case PurchasesErrorCode.productNotAvailableForPurchaseError:
        errorType = SubscriptionErrorType.productNotFound;
        message = 'Ce produit n\'est pas disponible';
        break;
      case PurchasesErrorCode.paymentPendingError:
        errorType = SubscriptionErrorType.paymentFailed;
        message = 'Paiement en attente';
        break;
      case PurchasesErrorCode.storeProblemError:
      case PurchasesErrorCode.purchaseNotAllowedError:
        errorType = SubscriptionErrorType.paymentFailed;
        message = 'Problème avec le store. Veuillez réessayer.';
        break;
      case PurchasesErrorCode.networkError:
        errorType = SubscriptionErrorType.networkError;
        message = 'Problème de connexion. Vérifiez votre réseau.';
        break;
      default:
        errorType = SubscriptionErrorType.unknown;
        message = 'Une erreur est survenue: ${error.name}';
    }

    state = SubscriptionState.error(
      message: message,
      errorType: errorType,
    );
    HapticService.error();
  }

  // ═══════════════════════════════════════════════════════════
  // UTILITAIRES
  // ═══════════════════════════════════════════════════════════

  /// Présente la paywall personnalisée
  /// 
  /// Note: Cette méthode doit être appelée depuis un contexte UI
  /// en utilisant le PaywallScreen personnalisé d'Aura Finance
  Future<void> presentPaywall() async {
    // La navigation vers PaywallScreen doit être gérée par l'appelant
    // car nous n'avons pas accès au context ici
    await checkSubscriptionStatus();
  }

  /// Vérifie si l'utilisateur est Pro
  /// 
  /// À utiliser avant d'afficher la paywall personnalisée
  bool shouldShowPaywall() {
    return state.maybeWhen(
      data: (isPro, _, __) => !isPro,
      orElse: () => true,
    );
  }

  /// Récupère les packages disponibles pour l'achat
  List<Package>? getAvailablePackages() {
    return state.maybeWhen(
      data: (_, __, offerings) => offerings?.current?.availablePackages,
      orElse: () => null,
    );
  }

  /// Retourne le package mensuel (s'il existe)
  Package? getMonthlyPackage() {
    return getAvailablePackages()
        ?.firstWhere(
          (p) => p.packageType == PackageType.monthly,
          orElse: () => getAvailablePackages()!.first,
        );
  }

  /// Retourne le package annuel (s'il existe)
  Package? getYearlyPackage() {
    return getAvailablePackages()
        ?.firstWhere(
          (p) => p.packageType == PackageType.annual,
          orElse: () => null,
        );
  }
}

// ═══════════════════════════════════════════════════════════
// PROVIDERS UTILITAIRES
// ═══════════════════════════════════════════════════════════

/// Provider simple pour savoir si l'utilisateur est Pro
@riverpod
bool isPro(IsProRef ref) {
  final state = ref.watch(subscriptionNotifierProvider);
  return state.maybeWhen(
    data: (isPro, _, __) => isPro,
    orElse: () => false,
  );
}

/// Provider pour obtenir les informations client RevenueCat
@riverpod
CustomerInfo? customerInfo(CustomerInfoRef ref) {
  final state = ref.watch(subscriptionNotifierProvider);
  return state.maybeWhen(
    data: (_, info, __) => info,
    orElse: () => null,
  );
}

/// Provider pour obtenir les offres disponibles
@riverpod
Offerings? offerings(OfferingsRef ref) {
  final state = ref.watch(subscriptionNotifierProvider);
  return state.maybeWhen(
    data: (_, __, offerings) => offerings,
    orElse: () => null,
  );
}

/// Provider pour vérifier si les achats sont en cours
@riverpod
bool isPurchasing(IsPurchasingRef ref) {
  final state = ref.watch(subscriptionNotifierProvider);
  return state.maybeWhen(
    purchasing: () => true,
    restoring: () => true,
    orElse: () => false,
  );
}

/// Provider pour obtenir l'erreur actuelle (s'il y en a une)
@riverpod
SubscriptionState? subscriptionError(SubscriptionErrorRef ref) {
  final state = ref.watch(subscriptionNotifierProvider);
  return state is _Error ? state : null;
}
