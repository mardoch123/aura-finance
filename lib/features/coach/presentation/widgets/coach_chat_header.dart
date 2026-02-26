import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/animations/pulse_ring.dart';

/// Header du chat avec avatar et statut du coach
class CoachChatHeader extends StatelessWidget {
  const CoachChatHeader({
    super.key,
    this.onSettingsPressed,
    this.isOnline = true,
  });

  final VoidCallback? onSettingsPressed;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AuraDimensions.spaceM,
        vertical: AuraDimensions.spaceS,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AuraColors.auraBackground.withOpacity(0.9),
            AuraColors.auraBackground.withOpacity(0.0),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Avatar du coach avec gradient
            _buildAvatar(),
            
            const SizedBox(width: AuraDimensions.spaceM),
            
            // Info du coach
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coach Aura',
                    style: AuraTypography.labelLarge.copyWith(
                      color: AuraColors.auraTextDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      // Indicateur de statut
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isOnline 
                              ? AuraColors.auraGreen 
                              : AuraColors.auraTextDarkSecondary,
                          shape: BoxShape.circle,
                          boxShadow: isOnline
                              ? [
                                  BoxShadow(
                                    color: AuraColors.auraGreen.withOpacity(0.4),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOnline ? 'En ligne' : 'Hors ligne',
                        style: AuraTypography.labelSmall.copyWith(
                          color: AuraColors.auraTextDarkSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Bouton paramètres
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onSettingsPressed?.call();
              },
              icon: const Icon(
                Icons.more_horiz,
                color: AuraColors.auraTextDark,
              ),
              style: IconButton.styleFrom(
                backgroundColor: AuraColors.auraGlass,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        // Avatar avec gradient
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AuraColors.gradientAmber,
            shape: BoxShape.circle,
            boxShadow: AuraDimensions.shadowMedium,
          ),
          child: const Center(
            child: Icon(
              Icons.auto_awesome,
              color: AuraColors.auraTextPrimary,
              size: 28,
            ),
          ),
        ),
        
        // Anneau pulsant quand en ligne
        if (isOnline)
          const Positioned.fill(
            child: PulseRing(
              color: AuraColors.auraAmber,
              size: 56,
            ),
          ),
      ],
    );
  }
}
