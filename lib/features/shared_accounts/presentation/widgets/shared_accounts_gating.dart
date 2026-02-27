import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/aura_button.dart';
import '../../../../core/haptics/haptic_service.dart';

/// Widget de gating pour la feature Pro des comptes partagés
/// Affiché quand l'utilisateur atteint la limite de membres gratuits
class SharedAccountsProGating extends ConsumerWidget {
  final int currentMembers;
  final int maxFreeMembers;
  final VoidCallback? onUpgrade;

  const SharedAccountsProGating({
    super.key,
    required this.currentMembers,
    this.maxFreeMembers = 2,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(AuraDimensions.spaceM),
      padding: const EdgeInsets.all(AuraDimensions.spaceL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AuraColors.auraAmber.withOpacity(0.1),
            AuraColors.auraDeep.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AuraDimensions.radiusXL),
        border: Border.all(
          color: AuraColors.auraAmber.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          // Icône Pro
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AuraColors.auraAmber, AuraColors.auraDeep],
              ),
              borderRadius: BorderRadius.circular(AuraDimensions.radiusXL),
              boxShadow: [
                BoxShadow(
                  color: AuraColors.auraAmber.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceL),

          // Titre
          Text(
            'Passez à Aura Pro',
            style: AuraTypography.h3.copyWith(
              color: AuraColors.auraTextDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AuraDimensions.spaceS),

          // Description
          Text(
            'Vous avez atteint la limite de $maxFreeMembers membres en version gratuite. Passez Pro pour ajouter autant de membres que vous voulez !',
            style: AuraTypography.bodyMedium.copyWith(
              color: AuraColors.auraTextDarkSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AuraDimensions.spaceL),

          // Compteur
          _buildMemberCounter(),
          const SizedBox(height: AuraDimensions.spaceXL),

          // Avantages Pro
          _buildProFeatures(),
          const SizedBox(height: AuraDimensions.spaceXL),

          // CTA
          AuraButton(
            onPressed: () {
              HapticService.mediumTap();
              onUpgrade?.call();
              // TODO: Navigate to paywall
            },
            text: 'Passer à Pro • 4,99€/mois',
            icon: Icons.workspace_premium,
          ),
          const SizedBox(height: AuraDimensions.spaceM),

          // Note
          Text(
            'Annulation à tout moment',
            style: AuraTypography.bodySmall.copyWith(
              color: AuraColors.auraTextDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AuraDimensions.spaceL,
        vertical: AuraDimensions.spaceM,
      ),
      decoration: BoxDecoration(
        color: AuraColors.auraGlass,
        borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline,
            color: AuraColors.auraTextDarkSecondary,
            size: 24,
          ),
          const SizedBox(width: AuraDimensions.spaceM),
          Text(
            '$currentMembers',
            style: AuraTypography.h2.copyWith(
              color: AuraColors.auraTextDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            ' / $maxFreeMembers',
            style: AuraTypography.h3.copyWith(
              color: AuraColors.auraTextDarkSecondary,
            ),
          ),
          const SizedBox(width: AuraDimensions.spaceM),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AuraColors.auraRed.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AuraDimensions.radiusXS),
            ),
            child: Text(
              'Limite atteinte',
              style: AuraTypography.labelSmall.copyWith(
                color: AuraColors.auraRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProFeatures() {
    final features = [
      'Membres illimités',
      'Transactions illimitées',
      'Export PDF mensuel',
      'Support prioritaire',
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AuraDimensions.spaceS),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AuraColors.auraGreen.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: AuraColors.auraGreen,
                  size: 16,
                ),
              ),
              const SizedBox(width: AuraDimensions.spaceM),
              Text(
                feature,
                style: AuraTypography.bodyMedium.copyWith(
                  color: AuraColors.auraTextDark,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Badge Pro affiché sur les comptes qui nécessitent un upgrade
class ProRequiredBadge extends StatelessWidget {
  const ProRequiredBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AuraColors.auraAmber, AuraColors.auraDeep],
        ),
        borderRadius: BorderRadius.circular(AuraDimensions.radiusXS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.workspace_premium,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            'PRO',
            style: AuraTypography.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog de confirmation pour l'upgrade Pro
class ProUpgradeDialog extends StatelessWidget {
  final VoidCallback onUpgrade;
  final VoidCallback onCancel;

  const ProUpgradeDialog({
    super.key,
    required this.onUpgrade,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AuraDimensions.spaceXL),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AuraColors.auraGlassStrong,
              AuraColors.auraGlass,
            ],
          ),
          borderRadius: BorderRadius.circular(AuraDimensions.radiusXXL),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animation ou icône
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AuraColors.auraAmber, AuraColors.auraDeep],
                ),
                borderRadius: BorderRadius.circular(AuraDimensions.radiusXXL),
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: AuraDimensions.spaceL),

            Text(
              'Débloquez les comptes partagés illimités',
              style: AuraTypography.h3.copyWith(
                color: AuraColors.auraTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuraDimensions.spaceM),

            Text(
              'Passez à Aura Pro pour inviter autant de membres que vous voulez dans vos comptes partagés.',
              style: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.auraTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuraDimensions.spaceXL),

            AuraButton(
              onPressed: onUpgrade,
              text: 'Passer à Pro',
              icon: Icons.workspace_premium,
            ),
            const SizedBox(height: AuraDimensions.spaceM),

            TextButton(
              onPressed: onCancel,
              child: Text(
                'Plus tard',
                style: AuraTypography.labelLarge.copyWith(
                  color: AuraColors.auraTextSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
