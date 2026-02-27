/// Feature: Comptes Partagés / Familiaux
/// 
/// Cette feature permet aux utilisateurs de gérer leurs finances en groupe :
/// - Mode Couple : partage total avec son partenaire
/// - Mode Famille : gestion familiale avec contrôle parental
/// - Mode Colocataires : partage des dépenses communes

// Models
export 'data/models/shared_account_model.dart';

// Repository
export 'data/repositories/shared_accounts_repository.dart';

// Providers
export 'presentation/providers/shared_accounts_provider.dart';

// Screens
export 'presentation/screens/shared_accounts_list_screen.dart';
export 'presentation/screens/shared_account_detail_screen.dart';
export 'presentation/screens/create_shared_account_screen.dart';

// Widgets
export 'presentation/widgets/shared_account_card.dart';
export 'presentation/widgets/shared_accounts_gating.dart';
