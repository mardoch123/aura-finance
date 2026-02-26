import 'package:flutter/material.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';

/// Barre de progression pour l'onboarding
class OnboardingProgressBar extends StatelessWidget {
  final double progress; // 0.0 à 1.0

  const OnboardingProgressBar({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AuraDimensions.spaceXL,
        vertical: AuraDimensions.spaceM,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AuraDimensions.radiusXS),
        child: Stack(
          children: [
            // Fond
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: AuraColors.auraTextPrimary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AuraDimensions.radiusXS),
              ),
            ),
            // Progression animée
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              height: 4,
              width: MediaQuery.of(context).size.width *
                  progress *
                  0.85, // Ajustement pour le padding
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AuraColors.auraAccentGold,
                    AuraColors.auraTextPrimary,
                  ],
                ),
                borderRadius: BorderRadius.circular(AuraDimensions.radiusXS),
                boxShadow: [
                  BoxShadow(
                    color: AuraColors.auraAccentGold.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
