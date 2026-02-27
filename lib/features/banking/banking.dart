/// Feature Synchronisation Bancaire (Open Banking) - Export public
///
/// Intégration TrueLayer, Bridge, Plaid pour synchronisation automatique
/// des transactions bancaires avec catégorisation IA.
///
/// Usage:
/// ```dart
/// import 'package:aura_finance/features/banking/banking.dart';
///
/// // Connecter une banque
/// await BankingService.instance.connectBank('bnpparibas');
///
/// // Sync transactions
/// await BankingService.instance.syncTransactions();
/// ```

// Presentation
export 'presentation/screens/banking_screen.dart';
export 'presentation/screens/bank_connection_screen.dart';
export 'presentation/screens/connected_accounts_screen.dart';
export 'presentation/widgets/bank_connection_button.dart';

// Domain
export 'domain/banking_models.dart';

// Services
export 'services/banking_service.dart';
export 'services/open_banking_provider.dart';
export 'services/transaction_categorization_service.dart';
export 'services/duplicate_detection_service.dart';
