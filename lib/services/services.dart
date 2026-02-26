/// Services globaux d'Aura Finance
/// 
/// Exporte tous les services pour faciliter l'import.
/// 
/// Usage:
/// ```dart
/// import 'package:aura_finance/services/services.dart';
/// 
/// // Vérifier les limites
/// final result = await usageLimitService.canScan(isPro: false);
/// 
/// // Tracker un événement
/// analyticsService.logPaywallShown(PaywallTrigger.scanLimitReached);
/// ```

export 'ai_service.dart';
export 'analytics_service.dart';
export 'notification_service.dart';
export 'supabase_service.dart';
export 'usage_limit_service.dart';
