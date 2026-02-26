import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/aura_button.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../features/auth/presentation/auth_controller.dart';
import '../../../../features/subscription/subscription_provider.dart';

/// Écran de profil utilisateur
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final subscriptionState = ref.watch(subscriptionProvider);

    return Scaffold(
      backgroundColor: AuraColors.auraBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AuraDimensions.spaceM),
                child: Column(
                  children: [
                    // Carte profil
                    _buildProfileCard(authState),

                    const SizedBox(height: AuraDimensions.spaceL),

                    // Statut Pro
                    _buildProCard(subscriptionState),

                    const SizedBox(height: AuraDimensions.spaceL),

                    // Menu
                    _buildMenu(context, ref),

                    const SizedBox(height: AuraDimensions.spaceXL),

                    // Version
                    Text(
                      'Aura Finance v1.0.0',
                      style: AuraTypography.caption.copyWith(
                        color: AuraColors.auraTextDarkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AuraDimensions.spaceM),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.goBack(),
            icon: const Icon(Icons.arrow_back_ios, color: AuraColors.auraTextDark),
          ),
          Expanded(
            child: Text(
              'Profil',
              style: AuraTypography.h3.copyWith(color: AuraColors.auraTextDark),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: () {
              HapticService.lightTap();
              context.goToSettings();
            },
            icon: const Icon(Icons.settings, color: AuraColors.auraTextDark),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(AuthState authState) {
    return authState.when(
      data: (user) => GlassCard(
        padding: const EdgeInsets.all(AuraDimensions.spaceXL),
        child: Column(
          children: [
            // Avatar
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AuraColors.auraAmber, width: 3),
                image: DecorationImage(
                  image: NetworkImage(
                    user?.userMetadata?['avatar_url'] ??
                        'https://api.dicebear.com/7.x/avataaars/svg?seed=${user?.id ?? 'aura'}',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: AuraDimensions.spaceM),

            // Nom
            Text(
              user?.userMetadata?['full_name'] ?? 'Utilisateur',
              style: AuraTypography.h3.copyWith(color: AuraColors.auraTextDark),
            ),

            // Email
            Text(
              user?.email ?? '',
              style: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.auraTextDarkSecondary,
              ),
            ),

            const SizedBox(height: AuraDimensions.spaceM),

            // Badge vérifié
            if (user?.emailConfirmedAt != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AuraDimensions.spaceM,
                  vertical: AuraDimensions.spaceXS,
                ),
                decoration: BoxDecoration(
                  color: AuraColors.auraGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified,
                      size: 16,
                      color: AuraColors.auraGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Email vérifié',
                      style: AuraTypography.labelSmall.copyWith(
                        color: AuraColors.auraGreen,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildProCard(SubscriptionState state) {
    final isPro = state.isPro;

    return GlassCard(
      onTap: isPro ? null : () {}, // TODO: Navigation vers paywall
      padding: const EdgeInsets.all(AuraDimensions.spaceM),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AuraColors.auraAmber, AuraColors.auraDeep],
              ),
              borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
            ),
            child: const Icon(
              Icons.diamond,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: AuraDimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPro ? 'Aura Pro' : 'Passer à Pro',
                  style: AuraTypography.h4.copyWith(
                    color: AuraColors.auraTextDark,
                  ),
                ),
                Text(
                  isPro
                      ? 'Abonnement actif'
                      : 'Débloquez toutes les fonctionnalités',
                  style: AuraTypography.bodySmall.copyWith(
                    color: AuraColors.auraTextDarkSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (!isPro)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AuraDimensions.spaceM,
                vertical: AuraDimensions.spaceXS,
              ),
              decoration: BoxDecoration(
                color: AuraColors.auraAmber,
                borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
              ),
              child: Text(
                'Upgrade',
                style: AuraTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenu(BuildContext context, WidgetRef ref) {
    final menuItems = [
      _MenuItem(
        icon: Icons.account_balance_wallet,
        label: 'Mes comptes',
        onTap: () => context.goToAccounts(),
      ),
      _MenuItem(
        icon: Icons.flag,
        label: 'Objectifs',
        onTap: () => context.goToBudgets(),
      ),
      _MenuItem(
        icon: Icons.subscriptions,
        label: 'Abonnements',
        onTap: () => context.goToSubscriptions(),
      ),
      _MenuItem(
        icon: Icons.notifications,
        label: 'Notifications',
        onTap: () {}, // TODO: Écran notifications
      ),
      _MenuItem(
        icon: Icons.security,
        label: 'Sécurité',
        onTap: () {}, // TODO: Écran sécurité
      ),
      _MenuItem(
        icon: Icons.help_outline,
        label: 'Aide & Support',
        onTap: () {}, // TODO: Aide
      ),
      _MenuItem(
        icon: Icons.logout,
        label: 'Déconnexion',
        color: AuraColors.auraRed,
        onTap: () => _confirmLogout(context, ref),
      ),
    ];

    return GlassCard(
      child: Column(
        children: menuItems.asMap().entries.map((entry) {
          final item = entry.value;
          final isLast = entry.key == menuItems.length - 1;

          return Column(
            children: [
              ListTile(
                leading: Icon(item.icon, color: item.color ?? AuraColors.auraTextDark),
                title: Text(
                  item.label,
                  style: AuraTypography.bodyLarge.copyWith(
                    color: item.color ?? AuraColors.auraTextDark,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: AuraColors.auraTextDarkSecondary,
                ),
                onTap: () {
                  HapticService.lightTap();
                  item.onTap();
                },
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 56,
                  color: AuraColors.auraGlassBorder,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AuraColors.auraGlassStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AuraDimensions.radiusXL),
        ),
        title: Text(
          'Déconnexion',
          style: AuraTypography.h4.copyWith(color: AuraColors.auraTextDark),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: AuraTypography.bodyMedium.copyWith(
            color: AuraColors.auraTextDarkSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: AuraTypography.labelMedium.copyWith(
                color: AuraColors.auraTextDarkSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              HapticService.success();
              ref.read(authControllerProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AuraColors.auraRed,
            ),
            child: Text(
              'Déconnexion',
              style: AuraTypography.labelMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });
}
