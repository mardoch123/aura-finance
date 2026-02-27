import 'package:flutter/material.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../data/models/challenge_models.dart';

/// Widget affichant une série (streak) avec animation de flammes
class StreakWidget extends StatelessWidget {
  final StreakType type;
  final int currentStreak;
  final int longestStreak;
  final int nextMilestone;

  const StreakWidget({
    super.key,
    required this.type,
    required this.currentStreak,
    required this.longestStreak,
    required this.nextMilestone,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentStreak / nextMilestone;

    return GlassCard(
      borderRadius: AuraDimensions.radiusXL,
      padding: const EdgeInsets.all(AuraDimensions.spaceL),
      child: Column(
        children: [
          Row(
            children: [
              // Animation de flamme
              _FlameAnimation(streak: currentStreak),
              const SizedBox(width: AuraDimensions.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTypeLabel(type),
                      style: AuraTypography.labelLarge.copyWith(
                        color: AuraColors.auraTextDarkSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$currentStreak',
                          style: AuraTypography.hero.copyWith(
                            color: AuraColors.auraAmber,
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'jours',
                            style: AuraTypography.bodyLarge.copyWith(
                              color: AuraColors.auraTextDarkSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AuraDimensions.spaceM),

          // Barre de progression vers le prochain milestone
          ClipRRect(
            borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AuraColors.auraGlass,
              valueColor: const AlwaysStoppedAnimation(AuraColors.auraAmber),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceS),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Record: $longestStreak jours',
                style: AuraTypography.bodySmall.copyWith(
                  color: AuraColors.auraTextDarkSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AuraColors.auraAmber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AuraDimensions.radiusXS),
                ),
                child: Text(
                  'Prochain: $nextMilestone jours',
                  style: AuraTypography.labelSmall.copyWith(
                    color: AuraColors.auraAmber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(StreakType type) {
    return switch (type) {
      StreakType.dailyCheckIn => 'Connexion quotidienne',
      StreakType.underBudget => 'Sous budget',
      StreakType.transactionLogged => 'Transactions enregistrées',
      StreakType.noImpulseBuy => 'Pas d\'achat impulsif',
      StreakType.savingMade => 'Épargne quotidienne',
    };
  }
}

/// Animation de flamme pour les streaks
class _FlameAnimation extends StatefulWidget {
  final int streak;

  const _FlameAnimation({required this.streak});

  @override
  State<_FlameAnimation> createState() => _FlameAnimationState();
}

class _FlameAnimationState extends State<_FlameAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Couleur basée sur la streak
    final color = widget.streak >= 100
        ? AuraColors.auraAccentGold
        : widget.streak >= 30
            ? AuraColors.auraAmber
            : AuraColors.auraDeep;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  color.withOpacity(0.3),
                  color.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Cercle extérieur pulsant
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color,
                          color.withOpacity(0.7),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                  // Icône flamme
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                    size: 36,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Widget compact pour afficher une streak dans une liste
class StreakCompactWidget extends StatelessWidget {
  final StreakType type;
  final int streak;
  final VoidCallback? onTap;

  const StreakCompactWidget({
    super.key,
    required this.type,
    required this.streak,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: AuraDimensions.radiusL,
        padding: const EdgeInsets.symmetric(
          horizontal: AuraDimensions.spaceM,
          vertical: AuraDimensions.spaceS,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AuraColors.auraAmber,
                    AuraColors.auraDeep,
                  ],
                ),
                borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: AuraDimensions.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTypeLabel(type),
                    style: AuraTypography.labelMedium.copyWith(
                      color: AuraColors.auraTextDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$streak jours de suite',
                    style: AuraTypography.bodySmall.copyWith(
                      color: AuraColors.auraTextDarkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$streak',
              style: AuraTypography.h3.copyWith(
                color: AuraColors.auraAmber,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(StreakType type) {
    return switch (type) {
      StreakType.dailyCheckIn => 'Connexion',
      StreakType.underBudget => 'Sous budget',
      StreakType.transactionLogged => 'Transactions',
      StreakType.noImpulseBuy => 'Anti-impulsion',
      StreakType.savingMade => 'Épargne',
    };
  }
}
