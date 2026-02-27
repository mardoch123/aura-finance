import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/app_localizations_extension.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../data/models/challenge_models.dart';
import '../widgets/streak_widget.dart';
import '../widgets/badge_grid.dart';
import '../widgets/leaderboard_preview.dart';

/// Écran principal des Challenges & Gamification
class ChallengesScreen extends ConsumerStatefulWidget {
  static const routeName = '/challenges';

  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraColors.auraBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header avec XP et niveau
            _buildHeader(),

            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceM),
              decoration: BoxDecoration(
                color: AuraColors.auraGlass,
                borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AuraColors.auraAmber, AuraColors.auraDeep],
                  ),
                  borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AuraColors.auraTextDarkSecondary,
                labelStyle: AuraTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(text: context.l10n.challenges),
                  Tab(text: 'Badges'),
                  Tab(text: 'Séries'),
                  Tab(text: 'Classement'),
                ],
              ),
            ),

            const SizedBox(height: AuraDimensions.spaceM),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildChallengesTab(),
                  _buildBadgesTab(),
                  _buildStreaksTab(),
                  _buildLeaderboardTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // TODO: Connect to actual provider
    final mockLevel = 5;
    final mockXP = 1250;
    final mockNextLevelXP = 1500;
    final progress = mockXP / mockNextLevelXP;

    return Padding(
      padding: const EdgeInsets.all(AuraDimensions.spaceL),
      child: Column(
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AuraDimensions.spaceM,
                  vertical: AuraDimensions.spaceS,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AuraColors.auraAmber, AuraColors.auraDeep],
                  ),
                  borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$mockXP XP',
                      style: AuraTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AuraDimensions.spaceL),

          // Niveau et progression
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
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
                child: Center(
                  child: Text(
                    '$mockLevel',
                    style: AuraTypography.hero.copyWith(
                      color: Colors.white,
                      fontSize: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AuraDimensions.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${context.l10n.level} $mockLevel • ${context.l10n.financier}',
                      style: AuraTypography.h4.copyWith(
                        color: AuraColors.auraTextDark,
                      ),
                    ),
                    const SizedBox(height: AuraDimensions.spaceS),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AuraColors.auraGlass,
                        valueColor: const AlwaysStoppedAnimation(AuraColors.auraAmber),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.xpForNextLevel.replaceAll('{current}', mockXP.toString()).replaceAll('{next}', mockNextLevelXP.toString()).replaceAll('{level}', (mockLevel + 1).toString()),
                      style: AuraTypography.bodySmall.copyWith(
                        color: AuraColors.auraTextDarkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesTab() {
    // TODO: Connect to actual provider
    final mockChallenges = [
      _MockChallenge(
        title: 'Semaine sans café',
        description: '0 dépense café pendant 7 jours',
        progress: 0.4,
        daysLeft: 4,
        xpReward: 200,
        icon: Icons.coffee,
        color: '#8B5A3A',
      ),
      _MockChallenge(
        title: 'Objectif 100€',
        description: 'Épargnez 100€ cette semaine',
        progress: 0.75,
        daysLeft: 2,
        xpReward: 300,
        icon: Icons.savings,
        color: '#7DC983',
      ),
      _MockChallenge(
        title: 'Semaine parfaite',
        description: 'Restez sous budget 7 jours',
        progress: 0.85,
        daysLeft: 1,
        xpReward: 250,
        icon: Icons.check_circle,
        color: '#E8A86C',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceM),
      children: [
        // Section "En cours"
        Text(
          context.l10n.currentChallenges,
          style: AuraTypography.h4.copyWith(
            color: AuraColors.auraTextDark,
          ),
        ),
        const SizedBox(height: AuraDimensions.spaceM),
        ...mockChallenges.map((c) => _buildChallengeCard(c)),

        const SizedBox(height: AuraDimensions.spaceXL),

        // Section "Disponibles"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.newChallenges,
              style: AuraTypography.h4.copyWith(
                color: AuraColors.auraTextDark,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                context.l10n.viewAll,
                style: AuraTypography.labelMedium.copyWith(
                  color: AuraColors.auraDeep,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AuraDimensions.spaceM),
        _buildAvailableChallengeCard(
          title: 'Chef économe',
          description: 'Réduisez vos dépenses alimentaires de 20%',
          difficulty: 'Difficile',
          xpReward: 400,
          icon: Icons.restaurant,
          color: '#C4714A',
        ),
      ],
    );
  }

  Widget _buildChallengeCard(_MockChallenge challenge) {
    final color = Color(int.parse(challenge.color.replaceFirst('#', '0xFF')));

    return GlassCard(
      margin: const EdgeInsets.only(bottom: AuraDimensions.spaceM),
      borderRadius: AuraDimensions.radiusXL,
      padding: const EdgeInsets.all(AuraDimensions.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
                ),
                child: Icon(
                  challenge.icon,
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
                      challenge.title,
                      style: AuraTypography.labelLarge.copyWith(
                        color: AuraColors.auraTextDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      challenge.description,
                      style: AuraTypography.bodySmall.copyWith(
                        color: AuraColors.auraTextDarkSecondary,
                      ),
                    ),
                  ],
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      color: AuraColors.auraAmber,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${challenge.xpReward}',
                      style: AuraTypography.labelSmall.copyWith(
                        color: AuraColors.auraAmber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AuraDimensions.spaceM),

          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
            child: LinearProgressIndicator(
              value: challenge.progress,
              backgroundColor: AuraColors.auraGlass,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceS),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(challenge.progress * 100).toInt()}% ${context.l10n.completed}',
                style: AuraTypography.bodySmall.copyWith(
                  color: AuraColors.auraTextDarkSecondary,
                ),
              ),
              Text(
                challenge.daysLeft == 1 
                    ? context.l10n.daysLeft_one.replaceAll('{count}', challenge.daysLeft.toString())
                    : context.l10n.daysLeft_other.replaceAll('{count}', challenge.daysLeft.toString()),
                style: AuraTypography.bodySmall.copyWith(
                  color: AuraColors.auraRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableChallengeCard({
    required String title,
    required String description,
    required String difficulty,
    required int xpReward,
    required IconData icon,
    required String color,
  }) {
    final parsedColor = Color(int.parse(color.replaceFirst('#', '0xFF')));

    return GlassCard(
      borderRadius: AuraDimensions.radiusXL,
      padding: const EdgeInsets.all(AuraDimensions.spaceM),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: parsedColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
            ),
            child: Icon(
              icon,
              color: parsedColor,
              size: 28,
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AuraColors.auraRed.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        difficulty,
                        style: AuraTypography.labelSmall.copyWith(
                          color: AuraColors.auraRed,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.star,
                      color: AuraColors.auraAmber,
                      size: 14,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '+$xpReward XP',
                      style: AuraTypography.labelSmall.copyWith(
                        color: AuraColors.auraAmber,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticService.mediumTap();
              // TODO: Join challenge
            },
            child: Container(
              padding: const EdgeInsets.all(AuraDimensions.spaceS),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AuraColors.auraAmber, AuraColors.auraDeep],
                ),
                borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesTab() {
    return const BadgeGrid();
  }

  Widget _buildStreaksTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceM),
      children: [
        Text(
          context.l10n.yourStreaks,
          style: AuraTypography.h4.copyWith(
            color: AuraColors.auraTextDark,
          ),
        ),
        const SizedBox(height: AuraDimensions.spaceM),

        // Streak principale (sous budget)
        const StreakWidget(
          type: StreakType.underBudget,
          currentStreak: 12,
          longestStreak: 28,
          nextMilestone: 30,
        ),

        const SizedBox(height: AuraDimensions.spaceM),

        // Autres streaks
        Row(
          children: [
            Expanded(
              child: _buildSmallStreakCard(
                icon: Icons.receipt_long,
                label: 'Transactions',
                streak: 45,
                color: AuraColors.auraAmber,
              ),
            ),
            const SizedBox(width: AuraDimensions.spaceM),
            Expanded(
              child: _buildSmallStreakCard(
                icon: Icons.login,
                label: 'Connexions',
                streak: 67,
                color: AuraColors.auraGreen,
              ),
            ),
          ],
        ),

        const SizedBox(height: AuraDimensions.spaceXL),

        // Calendrier de streak
        Text(
          context.l10n.calendar,
          style: AuraTypography.h4.copyWith(
            color: AuraColors.auraTextDark,
          ),
        ),
        const SizedBox(height: AuraDimensions.spaceM),
        _buildStreakCalendar(),
      ],
    );
  }

  Widget _buildSmallStreakCard({
    required IconData icon,
    required String label,
    required int streak,
    required Color color,
  }) {
    return GlassCard(
      borderRadius: AuraDimensions.radiusL,
      padding: const EdgeInsets.all(AuraDimensions.spaceM),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AuraDimensions.spaceS),
          Text(
            '$streak',
            style: AuraTypography.h3.copyWith(
              color: AuraColors.auraTextDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            context.l10n.days,
            style: AuraTypography.bodySmall.copyWith(
              color: AuraColors.auraTextDarkSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AuraTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCalendar() {
    // Générer les 30 derniers jours
    final days = List.generate(30, (index) {
      final date = DateTime.now().subtract(Duration(days: 29 - index));
      // Simuler des jours actifs/inactifs
      final isActive = index % 7 != 5; // Un jour sur 7 inactif
      return _CalendarDay(
        date: date,
        isActive: isActive,
        isToday: index == 29,
      );
    });

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: days.map((day) {
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: day.isToday
                ? AuraColors.auraAmber
                : day.isActive
                    ? AuraColors.auraGreen.withOpacity(0.3)
                    : AuraColors.auraGlass,
            borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
            border: day.isToday
                ? Border.all(color: AuraColors.auraAmber, width: 2)
                : null,
          ),
          child: Center(
            child: Text(
              '${day.date.day}',
              style: AuraTypography.labelSmall.copyWith(
                color: day.isToday
                    ? Colors.white
                    : day.isActive
                        ? AuraColors.auraGreen
                        : AuraColors.auraTextDarkSecondary,
                fontWeight: day.isToday ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLeaderboardTab() {
    return const LeaderboardPreview();
  }
}

// Classes mock pour le développement
class _MockChallenge {
  final String title;
  final String description;
  final double progress;
  final int daysLeft;
  final int xpReward;
  final IconData icon;
  final String color;

  _MockChallenge({
    required this.title,
    required this.description,
    required this.progress,
    required this.daysLeft,
    required this.xpReward,
    required this.icon,
    required this.color,
  });
}

class _CalendarDay {
  final DateTime date;
  final bool isActive;
  final bool isToday;

  _CalendarDay({
    required this.date,
    required this.isActive,
    required this.isToday,
  });
}
