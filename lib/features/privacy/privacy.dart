/// Feature Privacy / Mode Discret - Export public
///
/// Apparence fausse (icône calculatrice), Face ID obligatoire,
/// cache solde sur écran d'accueil.
///
/// Usage:
/// ```dart
/// import 'package:aura_finance/features/privacy/privacy.dart';
///
/// // Activer le mode discret
/// await PrivacyService.instance.enableStealthMode();
/// ```

// Services
export 'services/privacy_service.dart';

// Presentation
export 'presentation/screens/privacy_settings_screen.dart';
