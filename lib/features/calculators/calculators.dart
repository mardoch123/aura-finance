/// Feature Calculateurs Financiers - Export public
///
/// Simulateur prêt immobilier, calculateur intérêts composés,
/// ROI investissements, convertisseur devises temps réel.
///
/// Usage:
/// ```dart
/// import 'package:aura_finance/features/calculators/calculators.dart';
///
/// // Naviguer vers les calculateurs
/// context.goToCalculators();
/// ```

// Presentation
export 'presentation/screens/calculators_screen.dart';
export 'presentation/screens/mortgage_calculator_screen.dart';
export 'presentation/screens/compound_interest_screen.dart';
export 'presentation/screens/roi_calculator_screen.dart';
export 'presentation/screens/currency_converter_screen.dart';

// Domain
export 'domain/calculator_models.dart';

// Data
export 'data/calculators_service.dart';
export 'data/exchange_rate_service.dart';
