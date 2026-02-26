import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../services/supabase_service.dart';
import '../haptics/haptic_service.dart';
import 'ad_config.dart';

/// Service d'initialisation des publicités et achats in-app
/// 
/// Gère:
/// - Le consentement RGPD via UMP (User Messaging Platform)
/// - L'initialisation de Google Mobile Ads
/// - L'initialisation de RevenueCat pour les achats in-app
/// 
/// À appeler dans main() AVANT runApp()
class AdsInitializer {
  static final AdsInitializer _instance = AdsInitializer._internal();
  factory AdsInitializer() => _instance;
  AdsInitializer._internal();

  /// État du consentement
  bool _canRequestAds = false;
  bool get canRequestAds => _canRequestAds;

  /// État d'initialisation de RevenueCat
  bool _revenueCatInitialized = false;
  bool get revenueCatInitialized => _revenueCatInitialized;

  // ═══════════════════════════════════════════════════════════
  // INITIALISATION PRINCIPALE
  // ═══════════════════════════════════════════════════════════

  /// Initialise tous les services de monétisation
  /// 
  /// Cette méthode doit être appelée dans main() avant runApp()
  Future<void> initialize() async {
    if (kDebugMode) {
      print('🔧 Initialisation des services de monétisation...');
    }

    try {
      // 1. Vérifier et demander le consentement RGPD
      await _requestConsent();

      // 2. Initialiser Google Mobile Ads si le consentement le permet
      if (_canRequestAds) {
        await _initializeMobileAds();
      }

      // 3. Initialiser RevenueCat (toujours, indépendamment des pubs)
      await _initializeRevenueCat();

      if (kDebugMode) {
        print('✅ Services de monétisation initialisés avec succès');
        print('   - Consentement: $_canRequestAds');
        print('   - RevenueCat: $_revenueCatInitialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de l\'initialisation: $e');
      }
      // Ne pas bloquer l'app en cas d'erreur
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CONSENTEMENT RGPD (UMP)
  // ═══════════════════════════════════════════════════════════

  /// Demande le consentement RGPD via UMP
  /// 
  /// Affiche le formulaire de consentement si:
  /// - L'utilisateur est dans l'EEA (Europe)
  /// - Le consentement n'a pas encore été donné
  Future<void> _requestConsent() async {
    try {
      // Utiliser l'API UMP de Google Mobile Ads
      final params = ConsentRequestParameters();
      
      // Demander les informations de consentement
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          // Vérifier si le formulaire est disponible
          if (await ConsentInformation.instance.isConsentFormAvailable()) {
            // Charger et afficher le formulaire
            _loadAndShowConsentForm();
          } else {
            // Pas de formulaire nécessaire
            _canRequestAds = true;
          }
        },
        (FormError error) {
          if (kDebugMode) {
            print('⚠️ Erreur consentement: ${error.message}');
          }
          // En cas d'erreur, on permet quand même les pubs (mode test)
          _canRequestAds = true;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erreur consentement: $e');
      }
      // En cas d'erreur, on permet quand même les pubs (mode test)
      _canRequestAds = true;
    }
  }

  /// Charge et affiche le formulaire de consentement
  Future<void> _loadAndShowConsentForm() async {
    try {
      ConsentForm.loadConsentForm(
        (ConsentForm consentForm) async {
          // Afficher le formulaire
          consentForm.show(
            (FormError? formError) {
              if (formError != null) {
                if (kDebugMode) {
                  print('⚠️ Erreur formulaire: ${formError.message}');
                }
              }
              // Vérifier le statut après fermeture du formulaire
              _checkConsentStatus();
            },
          );
        },
        (FormError error) {
          if (kDebugMode) {
            print('⚠️ Erreur chargement formulaire: ${error.message}');
          }
          _canRequestAds = true;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Exception formulaire: $e');
      }
      _canRequestAds = true;
    }
  }

  /// Vérifie le statut du consentement
  Future<void> _checkConsentStatus() async {
    try {
      final status = await ConsentInformation.instance.getConsentStatus();
      
      if (kDebugMode) {
        print('📋 Statut consentement: $status');
      }

      // Autoriser les pubs si le consentement est obtenu ou non requis
      _canRequestAds = status == ConsentStatus.obtained || 
                       status == ConsentStatus.notRequired;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erreur vérification statut: $e');
      }
      _canRequestAds = true;
    }
  }

  /// Réinitialise le consentement (pour tests)
  Future<void> resetConsent() async {
    await ConsentInformation.instance.reset();
    _canRequestAds = false;
  }

  // ═══════════════════════════════════════════════════════════
  // GOOGLE MOBILE ADS
  // ═══════════════════════════════════════════════════════════

  /// Initialise Google Mobile Ads
  Future<void> _initializeMobileAds() async {
    try {
      await MobileAds.instance.initialize();
      
      // Configurer le mode test si nécessaire
      if (AdConfig.isTestMode) {
        await _configureTestDevices();
      }

      if (kDebugMode) {
        print('✅ Google Mobile Ads initialisé');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur Mobile Ads: $e');
      }
      rethrow;
    }
  }

  /// Configure les appareils de test pour éviter les invalid clicks
  Future<void> _configureTestDevices() async {
    // Ajoutez ici les IDs de vos appareils de test
    // Vous pouvez obtenir l'ID dans les logs lors du premier lancement
    const testDeviceIds = <String>[
      // 'YOUR_DEVICE_ID_HERE',
    ];

    if (testDeviceIds.isNotEmpty) {
      final requestConfiguration = RequestConfiguration(
        testDeviceIds: testDeviceIds,
      );
      await MobileAds.instance.updateRequestConfiguration(requestConfiguration);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // REVENUECAT (In-App Purchases)
  // ═══════════════════════════════════════════════════════════

  /// Initialise RevenueCat pour les achats in-app
  Future<void> _initializeRevenueCat() async {
    try {
      final userId = SupabaseService.instance.currentUser?.id;

      final configuration = PurchasesConfiguration(AdConfig.revenueCatPublicKey)
        ..appUserID = userId;

      await Purchases.configure(configuration);

      // Activer les logs en debug
      if (AdConfig.isTestMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      _revenueCatInitialized = true;

      if (kDebugMode) {
        print('✅ RevenueCat initialisé (UserID: $userId)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur RevenueCat: $e');
      }
      _revenueCatInitialized = false;
    }
  }

  /// Met à jour l'ID utilisateur RevenueCat après connexion
  /// 
  /// À appeler après la connexion/déconnexion de l'utilisateur
  Future<void> updateUserId(String? userId) async {
    if (!_revenueCatInitialized) return;

    try {
      if (userId != null) {
        await Purchases.logIn(userId);
        if (kDebugMode) {
          print('👤 RevenueCat: utilisateur lié ($userId)');
        }
      } else {
        await Purchases.logOut();
        if (kDebugMode) {
          print('👤 RevenueCat: utilisateur déconnecté');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur RevenueCat login: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // UTILITAIRES
  // ═══════════════════════════════════════════════════════════

  /// Vérifie si les publicités peuvent être affichées
  bool get areAdsEnabled => _canRequestAds;

  /// Définit manuellement l'état du consentement (pour tests)
  void setTestConsent(bool value) {
    if (AdConfig.isTestMode) {
      _canRequestAds = value;
    }
  }
}

/// Instance globale de l'initialiseur
final adsInitializer = AdsInitializer();
