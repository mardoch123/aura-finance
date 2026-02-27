import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/animations/staggered_animator.dart';
import '../../data/models/shared_account_model.dart';
import '../providers/shared_accounts_provider.dart';
import '../widgets/shared_account_card.dart';
import 'create_shared_account_screen.dart';

/// Écran liste des comptes partagés
class SharedAccountsListScreen extends ConsumerStatefulWidget {
  static const routeName = '/shared-accounts';

  const SharedAccountsListScreen({super.key});

  @override
  ConsumerState<SharedAccountsListScreen> createState() => _SharedAccountsListScreenState();
}

class _SharedAccountsListScreenState extends ConsumerState<SharedAccountsListScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les données au démarrage
    Future.microtask(() {
      ref.read(sharedAccountsListProvider.notifier).refresh();
      ref.read(receivedInvitationsProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(sharedAccountsListProvider);
    final invitationsAsync = ref.watch(receivedInvitationsProvider);

    return Scaffold(
      backgroundColor: AuraColors.auraBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: _buildAppBar(),
            ),

            // Invitations en attente
            invitationsAsync.when(
              data: (invitations) {
                if (invitations.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                return SliverToBoxAdapter(
                  child: _buildInvitationsSection(invitations),
                );
              },
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // Liste des comptes
            accountsAsync.when(
              data: (accounts) {
                if (accounts.isEmpty) {
                  return SliverFillRemaining(
                    child: _buildEmptyState(),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(AuraDimensions.spaceM),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final account = accounts[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AuraDimensions.spaceM),
                          child: SharedAccountCard(
                            account: account,
                            onTap: () => _navigateToAccountDetail(account),
                          ),
                        );
                      },
                      childCount: accounts.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AuraColors.auraAmber,
                  ),
                ),
              ),
              error: (error, _) => SliverFillRemaining(
                child: _buildErrorState(error.toString()),
              ),
            ),

            // Espace pour le FAB
            const SliverPadding(
              padding: EdgeInsets.only(bottom: 100),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(AuraDimensions.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(AuraDimensions.spaceS),
                  decoration: BoxDecoration(
                    color: AuraColors.auraGlass,
                    borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: AuraColors.auraTextDark,
                    size: 20,
                  ),
                ),
              ),
              const Spacer(),
              // Bouton notifications
              GestureDetector(
                onTap: () => _showInvitationsSheet(),
                child: Container(
                  padding: const EdgeInsets.all(AuraDimensions.spaceS),
                  decoration: BoxDecoration(
                    color: AuraColors.auraGlass,
                    borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
                  ),
                  child: Stack(
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        color: AuraColors.auraTextDark,
                        size: 24,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AuraColors.auraRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AuraDimensions.spaceL),
          Text(
            'Comptes Partagés',
            style: AuraTypography.h1.copyWith(
              color: AuraColors.auraTextDark,
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceXS),
          Text(
            'Gérez vos finances en famille ou à plusieurs',
            style: AuraTypography.bodyLarge.copyWith(
              color: AuraColors.auraTextDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationsSection(List<dynamic> invitations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceM),
      padding: const EdgeInsets.all(AuraDimensions.spaceM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AuraColors.auraAmber.withOpacity(0.15),
            AuraColors.auraDeep.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
        border: Border.all(
          color: AuraColors.auraAmber.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.mail_outline,
                color: AuraColors.auraAmber,
                size: 20,
              ),
              const SizedBox(width: AuraDimensions.spaceS),
              Text(
                '${invitations.length} invitation${invitations.length > 1 ? 's' : ''} en attente',
                style: AuraTypography.labelLarge.copyWith(
                  color: AuraColors.auraAmber,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showInvitationsSheet(),
                child: Text(
                  'Voir',
                  style: AuraTypography.labelMedium.copyWith(
                    color: AuraColors.auraDeep,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AuraDimensions.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AuraColors.auraGlass,
                borderRadius: BorderRadius.circular(AuraDimensions.radiusXXL),
              ),
              child: Icon(
                Icons.people_outline,
                size: 60,
                color: AuraColors.auraTextDarkSecondary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: AuraDimensions.spaceXL),
            Text(
              'Aucun compte partagé',
              style: AuraTypography.h3.copyWith(
                color: AuraColors.auraTextDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuraDimensions.spaceM),
            Text(
              'Créez un compte partagé pour gérer vos finances en couple, en famille ou avec vos colocataires.',
              style: AuraTypography.bodyLarge.copyWith(
                color: AuraColors.auraTextDarkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuraDimensions.spaceXL),
            _buildModeOption(
              icon: Icons.favorite_outline,
              title: 'Mode Couple',
              description: 'Partagez toutes vos finances avec votre partenaire',
              color: AuraColors.auraAccentGold,
            ),
            const SizedBox(height: AuraDimensions.spaceM),
            _buildModeOption(
              icon: Icons.family_restroom_outlined,
              title: 'Mode Famille',
              description: 'Gérez le budget familial avec vos enfants',
              color: AuraColors.auraGreen,
            ),
            const SizedBox(height: AuraDimensions.spaceM),
            _buildModeOption(
              icon: Icons.home_outlined,
              title: 'Mode Colocataires',
              description: 'Partagez les dépenses communes',
              color: AuraColors.auraAmber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return GlassCard(
      borderRadius: AuraDimensions.radiusL,
      padding: const EdgeInsets.all(AuraDimensions.spaceM),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: AuraDimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AuraTypography.labelLarge.copyWith(
                    color: AuraColors.auraTextDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AuraTypography.bodySmall.copyWith(
                    color: AuraColors.auraTextDarkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AuraDimensions.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AuraColors.auraRed.withOpacity(0.5),
            ),
            const SizedBox(height: AuraDimensions.spaceL),
            Text(
              'Une erreur est survenue',
              style: AuraTypography.h3.copyWith(
                color: AuraColors.auraTextDark,
              ),
            ),
            const SizedBox(height: AuraDimensions.spaceM),
            Text(
              error,
              style: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.auraTextDarkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuraDimensions.spaceL),
            ElevatedButton(
              onPressed: () {
                ref.read(sharedAccountsListProvider.notifier).refresh();
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      margin: const EdgeInsets.all(AuraDimensions.spaceM),
      child: FloatingActionButton.extended(
        onPressed: () => _showCreateOptions(),
        backgroundColor: AuraColors.auraAmber,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Créer',
          style: AuraTypography.labelLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _navigateToAccountDetail(SharedAccount account) {
    context.push('/shared-accounts/${account.id}');
  }

  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const CreateSharedAccountScreen(),
    );
  }

  void _showInvitationsSheet() {
    // TODO: Show invitations bottom sheet
  }
}
