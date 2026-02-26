/// Feature: Subscription & In-App Purchases
/// 
/// Gère les abonnements Aura Pro via RevenueCat et les paywalls.
/// 
/// Usage:
/// ```dart
/// import 'package:aura_finance/features/subscription/subscription.dart';
/// 
/// // Afficher le paywall
/// await PaywallService.show(context, trigger: PaywallTrigger.scanLimitReached);
/// ```

export 'subscription_provider.dart';
export 'presentation/paywall_screen.dart';
