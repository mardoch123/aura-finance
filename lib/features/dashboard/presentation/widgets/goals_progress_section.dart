import 'package:flutter/material.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/models/dashboard_models.dart';

/// Section de progression des objectifs budgétaires
class GoalsProgressSection extends StatelessWidget {
  const GoalsProgressSection({
    super.key,
    required this.goals,
    this.onGoalTap,
  });

  final List<BudgetGoal> goals;
  final Function(BudgetGoal goal)? onGoalTap;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AuraDimensions.spaceM,
          ),
          child: Text(
            'Objectifs',
            style: AuraTypography.h4.copyWith(
              color: AuraColors.auraTextDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        const SizedBox(height: AuraDimensions.spaceM),
        
        // Liste horizontale
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AuraDimensions.spaceM,
            ),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              return _buildGoalCard(goals[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard(BudgetGoal goal) {
    final progress = goal.targetAmount != null && goal.targetAmount! > 0
        ? (goal.currentAmount / goal.targetAmount!).clamp(0.0, 1.0)
        : 0.0;
    
    final color = _parseColor(goal.color) ?? AuraColors.auraAmber;
    final icon = goal.icon ?? '🎯';
    
    return GestureDetector(
      onTap: () => onGoalTap?.call(goal),
      child: GlassCard(
        width: 200,
        margin: const EdgeInsets.only(right: AuraDimensions.spaceM),
        padding: const EdgeInsets.all(AuraDimensions.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: AuraDimensions.spaceS),
                Expanded(
                  child: Text(
                    goal.name,
                    style: AuraTypography.labelMedium.copyWith(
                      color: AuraColors.auraTextDark,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const Spacer(),
            
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(AuraDimensions.radiusXS),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: progress),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AuraColors.auraGlass,
                      borderRadius: BorderRadius.circular(AuraDimensions.radiusXS),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getProgressColor(value, light: true),
                              _getProgressColor(value, light: false),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AuraDimensions.radiusXS),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: AuraDimensions.spaceXS),
            
            // Texte de progression
            Text(
              goal.targetAmount != null
                  ? '${goal.currentAmount.toStringAsFixed(0)}€ / ${goal.targetAmount!.toStringAsFixed(0)}€'
                  : '${goal.currentAmount.toStringAsFixed(0)}€ épargnés',
              style: AuraTypography.labelSmall.copyWith(
                color: AuraColors.auraTextDarkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double progress, {required bool light}) {
    if (progress < 0.3) {
      return light ? AuraColors.auraRed.withOpacity(0.7) : AuraColors.auraRed;
    } else if (progress < 0.7) {
      return light ? AuraColors.auraAmber.withOpacity(0.7) : AuraColors.auraAmber;
    } else {
      return light ? AuraColors.auraGreen.withOpacity(0.7) : AuraColors.auraGreen;
    }
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null) return null;
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (_) {
      return null;
    }
  }
}

/// Widget de progression circulaire pour un objectif
class CircularGoalProgress extends StatelessWidget {
  const CircularGoalProgress({
    super.key,
    required this.goal,
    this.size = 80,
  });

  final BudgetGoal goal;
  final double size;

  @override
  Widget build(BuildContext context) {
    final progress = goal.targetAmount != null && goal.targetAmount! > 0
        ? (goal.currentAmount / goal.targetAmount!).clamp(0.0, 1.0)
        : 0.0;
    
    final color = _parseColor(goal.color) ?? AuraColors.auraAmber;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cercle de fond
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 6,
              backgroundColor: AuraColors.auraGlass,
              valueColor: AlwaysStoppedAnimation<Color>(
                AuraColors.auraGlass,
              ),
            ),
          ),
          
          // Cercle de progression
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 6,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              );
            },
          ),
          
          // Contenu central
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                goal.icon ?? '🎯',
                style: const TextStyle(fontSize: 20),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: AuraTypography.labelSmall.copyWith(
                  color: AuraColors.auraTextDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null) return null;
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (_) {
      return null;
    }
  }
}
