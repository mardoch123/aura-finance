/// Core: Subscription & Feature Gating
/// 
/// Gestion des accès aux features selon le plan (Free vs Pro).
/// 
/// Usage:
/// ```dart
/// import 'package:aura_finance/core/subscription/subscription.dart';
/// 
/// // Vérifier l'accès
/// final result = await featureGateService.checkScanLimit(isPro: false);
/// 
/// // Widget avec contrôle d'accès
/// AuraFeatureGate(
///   feature: AuraFeature.scanner,
///   isPro: false,
///   child: ScannerButton(),
///   onLocked: () => showPaywall(context),
/// )
/// ```

export 'aura_feature_gate.dart';
export 'feature_gate_service.dart';
