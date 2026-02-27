import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/aura_colors.dart';
import '../theme/aura_dimensions.dart';
import '../theme/aura_typography.dart';
import '../felix/felix_animation_type.dart';
import '../felix/widgets/felix_mascot.dart';
import 'glass_card.dart';

/// Empty state animé avec Félix la mascotte
/// Utilisé quand il n'y a pas de données à afficher
class FelixEmptyState extends ConsumerWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;
  final FelixAnimationType felixAnimation;
  final double felixSize;
  final bool showConfetti;

  const FelixEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onAction,
    this.actionLabel,
    this.felixAnimation = FelixAnimationType.empty,
    this.felixSize = 150,
    this.showConfetti = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AuraDimensions.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Félix
            FelixMascot(
              animationType: felixAnimation,
              size: felixSize,
              message: title,
              subMessage: subtitle,
            ),
            
            const SizedBox(height: AuraDimensions.spaceXXL),
            
            // Bouton d'action
            if (onAction != null)
              _buildActionButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AuraDimensions.spaceXL,
        vertical: AuraDimensions.spaceL,
      ),
      child: GestureDetector(
        onTap: onAction,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AuraColors.auraAmber,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              actionLabel ?? 'Commencer',
              style: AuraTypography.labelLarge.copyWith(
                color: AuraColors.auraAmber,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state pour les transactions
class TransactionsEmptyState extends StatelessWidget {
  final VoidCallback onAddTransaction;

  const TransactionsEmptyState({
    super.key,
    required this.onAddTransaction,
  });

  @override
  Widget build(BuildContext context) {
    return FelixEmptyState(
      title: 'Aucune transaction',
      subtitle: 'Commence par ajouter ta première dépense',
      icon: Icons.add,
      actionLabel: 'Ajouter une transaction',
      onAction: onAddTransaction,
      felixAnimation: FelixAnimationType.empty,
    );
  }
}

/// Empty state pour les comptes
class AccountsEmptyState extends StatelessWidget {
  final VoidCallback onAddAccount;

  const AccountsEmptyState({
    super.key,
    required this.onAddAccount,
  });

  @override
  Widget build(BuildContext context) {
    return FelixEmptyState(
      title: 'Aucun compte',
      subtitle: 'Ajoute ton compte bancaire pour commencer',
      icon: Icons.account_balance_wallet,
      actionLabel: 'Ajouter un compte',
      onAction: onAddAccount,
      felixAnimation: FelixAnimationType.thinking,
    );
  }
}

/// Empty state pour les objectifs
class GoalsEmptyState extends StatelessWidget {
  final VoidCallback onCreateGoal;

  const GoalsEmptyState({
    super.key,
    required this.onCreateGoal,
  });

  @override
  Widget build(BuildContext context) {
    return FelixEmptyState(
      title: 'Aucun objectif',
      subtitle: 'Définis tes objectifs financiers',
      icon: Icons.add_task,
      actionLabel: 'Créer un objectif',
      onAction: onCreateGoal,
      felixAnimation: FelixAnimationType.thinking,
    );
  }
}

/// Empty state pour les insights
class InsightsEmptyState extends StatelessWidget {
  final VoidCallback onScanReceipt;

  const InsightsEmptyState({
    super.key,
    required this.onScanReceipt,
  });

  @override
  Widget build(BuildContext context) {
    return FelixEmptyState(
      title: 'Aucun insight',
      subtitle: 'Scanne des reçus pour obtenir des analyses',
      icon: Icons.camera_alt,
      actionLabel: 'Scanner un reçu',
      onAction: onScanReceipt,
      felixAnimation: FelixAnimationType.thinking,
    );
  }
}

/// Empty state pour les abonnements
class SubscriptionsEmptyState extends StatelessWidget {
  final VoidCallback onAddSubscription;

  const SubscriptionsEmptyState({
    super.key,
    required this.onAddSubscription,
  });

  @override
  Widget build(BuildContext context) {
    return FelixEmptyState(
      title: 'Aucun abonnement',
      subtitle: 'Ajoute tes abonnements pour les surveiller',
      icon: Icons.subscriptions,
      actionLabel: 'Ajouter un abonnement',
      onAction: onAddSubscription,
      felixAnimation: FelixAnimationType.thinking,
    );
  }
}

/// Empty state pour les défis
class ChallengesEmptyState extends StatelessWidget {
  final VoidCallback onCreateChallenge;

  const ChallengesEmptyState({
    super.key,
    required this.onCreateChallenge,
  });

  @override
  Widget build(BuildContext context) {
    return FelixEmptyState(
      title: 'Aucun défi',
      subtitle: 'Crée un défi pour motiver tes amis',
      icon: Icons.group_add,
      actionLabel: 'Créer un défi',
      onAction: onCreateChallenge,
      felixAnimation: FelixAnimationType.idle,
    );
  }
}

/// Empty state générique avec illustration
class GenericEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;
  final Color? iconColor;

  const GenericEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onAction,
    this.actionLabel,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AuraDimensions.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: (iconColor ?? AuraColors.auraAmber).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 50,
                color: iconColor ?? AuraColors.auraAmber,
              ),
            ),
            
            const SizedBox(height: AuraDimensions.spaceL),
            
            // Titre
            Text(
              title,
              style: AuraTypography.h3.copyWith(
                color: AuraColors.auraTextDark,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: AuraDimensions.spaceS),
            
            // Sous-titre
            Text(
              subtitle,
              style: AuraTypography.bodyLarge.copyWith(
                color: AuraColors.auraTextDarkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: AuraDimensions.spaceXXL),
            
            // Bouton d'action
            if (onAction != null)
              _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AuraDimensions.spaceXL,
        vertical: AuraDimensions.spaceL,
      ),
      child: GestureDetector(
        onTap: onAction,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add,
              color: AuraColors.auraAmber,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              actionLabel ?? 'Ajouter',
              style: AuraTypography.labelLarge.copyWith(
                color: AuraColors.auraAmber,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget pour afficher un état vide avec recherche
class SearchEmptyState extends StatelessWidget {
  final String query;
  final String title;
  final String subtitle;

  const SearchEmptyState({
    super.key,
    required this.query,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AuraDimensions.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône de recherche
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AuraColors.auraGlass,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off,
                size: 40,
                color: AuraColors.auraTextDarkSecondary,
              ),
            ),
            
            const SizedBox(height: AuraDimensions.spaceL),
            
            // Message
            Text(
              title,
              style: AuraTypography.h4.copyWith(
                color: AuraColors.auraTextDark,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: AuraDimensions.spaceS),
            
            Text(
              subtitle,
              style: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.auraTextDarkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              '"$query"',
              style: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.auraAmber,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
