import 'package:flutter/material.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../domain/models/dashboard_models.dart';

/// Carte d'insight IA avec style selon le type
class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.insight,
    this.onTap,
    this.onDismiss,
  });

  final AiInsight insight;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final config = _getInsightConfig(insight.type);
    
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        onTap?.call();
      },
      child: GlassCard(
        width: 280,
        padding: AuraDimensions.paddingM,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            config.backgroundColor,
            config.backgroundColor.withOpacity(0.5),
          ],
        ),
        borderColor: config.borderColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec icône et type
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: config.iconBackground,
                    borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
                  ),
                  child: Text(
                    config.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: AuraDimensions.spaceS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.label,
                        style: AuraTypography.labelSmall.copyWith(
                          color: config.textColor.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        insight.title,
                        style: AuraTypography.labelLarge.copyWith(
                          color: config.textColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (onDismiss != null)
                  GestureDetector(
                    onTap: onDismiss,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: config.textColor.withOpacity(0.5),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: AuraDimensions.spaceM),
            
            // Corps
            Text(
              insight.body,
              style: AuraTypography.bodySmall.copyWith(
                color: config.textColor.withOpacity(0.9),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const Spacer(),
            
            // Bouton d'action
            if (config.actionLabel != null)
              _buildActionButton(config),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(InsightConfig config) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: config.actionColor,
        borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
      ),
      child: Text(
        config.actionLabel!,
        style: AuraTypography.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InsightConfig _getInsightConfig(String type) {
    switch (type) {
      case InsightType.vampire:
        return InsightConfig(
          emoji: '🧛',
          label: 'Vampire détecté',
          backgroundColor: AuraColors.auraRed.withOpacity(0.15),
          borderColor: AuraColors.auraRed.withOpacity(0.3),
          iconBackground: AuraColors.auraRed.withOpacity(0.2),
          textColor: AuraColors.auraRed,
          actionLabel: 'Voir l\'abonnement',
          actionColor: AuraColors.auraRed,
        );
      case InsightType.achievement:
        return InsightConfig(
          emoji: '🏆',
          label: 'Bonne habitude',
          backgroundColor: AuraColors.auraGreen.withOpacity(0.15),
          borderColor: AuraColors.auraGreen.withOpacity(0.3),
          iconBackground: AuraColors.auraGreen.withOpacity(0.2),
          textColor: AuraColors.auraGreen,
          actionLabel: null,
          actionColor: null,
        );
      case InsightType.tip:
        return InsightConfig(
          emoji: '💡',
          label: 'Conseil',
          backgroundColor: AuraColors.auraAccentGold.withOpacity(0.15),
          borderColor: AuraColors.auraAccentGold.withOpacity(0.3),
          iconBackground: AuraColors.auraAccentGold.withOpacity(0.2),
          textColor: AuraColors.auraDark,
          actionLabel: 'En savoir plus',
          actionColor: AuraColors.auraAccentGold,
        );
      case InsightType.alert:
        return InsightConfig(
          emoji: '⚠️',
          label: 'Alerte',
          backgroundColor: AuraColors.auraAmber.withOpacity(0.15),
          borderColor: AuraColors.auraAmber.withOpacity(0.3),
          iconBackground: AuraColors.auraAmber.withOpacity(0.2),
          textColor: AuraColors.auraDeep,
          actionLabel: 'Voir détails',
          actionColor: AuraColors.auraAmber,
        );
      case InsightType.prediction:
        return InsightConfig(
          emoji: '🔮',
          label: 'Prédiction',
          backgroundColor: AuraColors.auraAmber.withOpacity(0.1),
          borderColor: AuraColors.auraAmber.withOpacity(0.2),
          iconBackground: AuraColors.auraAmber.withOpacity(0.15),
          textColor: AuraColors.auraDark,
          actionLabel: null,
          actionColor: null,
        );
      default:
        return InsightConfig(
          emoji: '📌',
          label: 'Information',
          backgroundColor: AuraColors.auraGlass,
          borderColor: AuraColors.auraGlassBorder,
          iconBackground: AuraColors.auraGlassStrong,
          textColor: AuraColors.auraTextDark,
          actionLabel: null,
          actionColor: null,
        );
    }
  }
}

/// Configuration visuelle pour chaque type d'insight
class InsightConfig {
  final String emoji;
  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconBackground;
  final Color textColor;
  final String? actionLabel;
  final Color? actionColor;

  const InsightConfig({
    required this.emoji,
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconBackground,
    required this.textColor,
    this.actionLabel,
    this.actionColor,
  });
}

/// Carrousel horizontal d'insights avec animation staggered
class InsightsCarousel extends StatelessWidget {
  const InsightsCarousel({
    super.key,
    required this.insights,
    this.onInsightTap,
    this.onInsightDismiss,
  });

  final List<AiInsight> insights;
  final Function(AiInsight insight)? onInsightTap;
  final Function(AiInsight insight)? onInsightDismiss;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AuraDimensions.spaceM,
        ),
        itemCount: insights.length,
        itemBuilder: (context, index) {
          final insight = insights[index];
          
          return AnimatedSlide(
            offset: Offset.zero,
            duration: Duration(milliseconds: 400 + (index * 60)),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(milliseconds: 400 + (index * 60)),
              curve: Curves.easeOutCubic,
              child: Padding(
                padding: const EdgeInsets.only(
                  right: AuraDimensions.spaceM,
                ),
                child: InsightCard(
                  insight: insight,
                  onTap: () => onInsightTap?.call(insight),
                  onDismiss: () => onInsightDismiss?.call(insight),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
