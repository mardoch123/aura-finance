/// Module Scanner Vision IA pour Aura Finance
/// 
/// Ce module fournit toutes les fonctionnalités de scan intelligent :
/// - Scan de tickets de caisse avec IA (GPT-4 Vision)
/// - Dictée vocale pour ajouter des transactions
/// - Analyse automatique des montants, marchands et catégories
/// 
/// Usage:
/// ```dart
/// import 'package:aura_finance/features/scanner/scanner_module.dart';
/// 
/// // Naviguer vers l'écran de scan
/// context.goToScan();
/// ```

// Domain
export 'domain/transaction_draft.dart';

// Data
export 'data/scanner_service.dart';
export 'data/transaction_repository.dart';

// Presentation
export 'presentation/screens/scanner_screen.dart';
export 'presentation/providers/scanner_provider.dart';

// Widgets
export 'presentation/widgets/viewfinder_overlay.dart';
export 'presentation/widgets/scan_controls.dart';
export 'presentation/widgets/voice_recorder.dart';
export 'presentation/widgets/confirmation_modal.dart';
export 'presentation/widgets/corner_animation.dart';
