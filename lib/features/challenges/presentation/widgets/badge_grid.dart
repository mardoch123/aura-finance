import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../data/models/challenge_models.dart';

/// Grille de badges avec filtrage par catégorie
class BadgeGrid extends ConsumerStatefulWidget {
  const BadgeGrid({super.key});

  @override
  ConsumerState<BadgeGrid> createState() => _BadgeGridState();
}

class _BadgeGridState extends ConsumerState<BadgeGrid> {
  BadgeCategory? _selectedCategory;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Tous', 'value': null, 'icon': Icons.apps},
    {'label': 'Épargne', 'value': BadgeCategory.saving, 'icon': Icons.savings},
    {'label': 'Dépenses', 'value': BadgeCategory.spending, 'icon': Icons.shopping_bag},
    {'label': 'Séries', 'value': BadgeCategory.streak, 'icon': Icons.local_fire_department},
    {'label': 'Social', 'value': BadgeCategory.social, 'icon': Icons.share},
    {'label': 'Exploration', 'value': BadgeCategory.exploration, 'icon': Icons.explore},
    {'label': 'Spécial', 'value': BadgeCategory.special, 'icon': Icons.star},
  ];

  @override
  Widget build(BuildContext context) {
    // TODO: Connect to actual provider
    final mockBadges = _getMockBadges();

    final filteredBadges = _selectedCategory == null
        ? mockBadges
        : mockBadges.where((b) => b.category == _selectedCategory).toList();

    return Column(
      children: [
        // Filtres par catégorie
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceM),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category['value'];

              return GestureDetector(
                onTap: () {
                  HapticService.lightTap();
                  setState(() {
                    _selectedCategory = category['value'] as BadgeCategory?;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: AuraDimensions.spaceS),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AuraDimensions.spaceM,
                    vertical: AuraDimensions.spaceS,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [AuraColors.auraAmber, AuraColors.auraDeep],
                          )
                        : null,
                    color: isSelected ? null : AuraColors.auraGlass,
                    borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        category['icon'] as IconData,
                        color: isSelected
                            ? Colors.white
                            : AuraColors.auraTextDarkSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        category['label'] as String,
                        style: AuraTypography.labelMedium.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AuraColors.auraTextDark,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: AuraDimensions.spaceM),

        // Stats
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceM),
          child: Row(
            children: [
              _buildStatCard(
                label: 'Débloqués',
                value: '${mockBadges.where((b) => b.isUnlocked).length}',
                color: AuraColors.auraGreen,
              ),
              const SizedBox(width: AuraDimensions.spaceM),
              _buildStatCard(
                label: 'Secrets',
                value: '${mockBadges.where((b) => b.badge.isSecret).length}',
                color: AuraColors.auraAccentGold,
              ),
              const SizedBox(width: AuraDimensions.spaceM),
              _buildStatCard(
                label: 'Total',
                value: '${mockBadges.length}',
                color: AuraColors.auraAmber,
              ),
            ],
          ),
        ),

        const SizedBox(height: AuraDimensions.spaceM),

        // Grille de badges
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceM),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.75,
              crossAxisSpacing: AuraDimensions.spaceM,
              mainAxisSpacing: AuraDimensions.spaceM,
            ),
            itemCount: filteredBadges.length,
            itemBuilder: (context, index) {
              final userBadge = filteredBadges[index];
              return _buildBadgeCard(userBadge);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: GlassCard(
        borderRadius: AuraDimensions.radiusL,
        padding: const EdgeInsets.symmetric(vertical: AuraDimensions.spaceM),
        child: Column(
          children: [
            Text(
              value,
              style: AuraTypography.h3.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: AuraTypography.labelSmall.copyWith(
                color: AuraColors.auraTextDarkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeCard(_MockUserBadge userBadge) {
    final badge = userBadge.badge;
    final isUnlocked = userBadge.isUnlocked;
    final tierColor = _getTierColor(badge.tier);

    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        _showBadgeDetail(userBadge);
      },
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.5,
        child: GlassCard(
          borderRadius: AuraDimensions.radiusL,
          padding: const EdgeInsets.all(AuraDimensions.spaceS),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Badge icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: isUnlocked
                      ? LinearGradient(
                          colors: badge.backgroundGradient
                              .map((c) => Color(int.parse(c.replaceFirst('#', '0xFF'))))
                              .toList(),
                        )
                      : null,
                  color: isUnlocked ? null : AuraColors.auraGlass,
                  shape: BoxShape.circle,
                  boxShadow: isUnlocked
                      ? [
                          BoxShadow(
                            color: tierColor.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isUnlocked
                    ? Icon(
                        _getIconData(badge.icon),
                        color: Colors.white,
                        size: 32,
                      )
                    : Icon(
                        Icons.lock_outline,
                        color: AuraColors.auraTextDarkSecondary,
                        size: 24,
                      ),
              ),
              const SizedBox(height: AuraDimensions.spaceS),

              // Nom
              Text(
                badge.name,
                style: AuraTypography.labelSmall.copyWith(
                  color: AuraColors.auraTextDark,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),

              // Tier
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? tierColor.withOpacity(0.15)
                      : AuraColors.auraGlass,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge.tierLabel,
                  style: AuraTypography.labelSmall.copyWith(
                    color: isUnlocked ? tierColor : AuraColors.auraTextDarkSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Indicateur "Nouveau"
              if (isUnlocked && userBadge.isNew) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AuraColors.auraGreen,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'NOUVEAU',
                    style: AuraTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showBadgeDetail(_MockUserBadge userBadge) {
    final badge = userBadge.badge;
    final isUnlocked = userBadge.isUnlocked;
    final tierColor = _getTierColor(badge.tier);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AuraDimensions.spaceXL),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AuraColors.auraBackground,
              AuraColors.auraBackground.withOpacity(0.95),
            ],
          ),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AuraDimensions.radiusXXL),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AuraColors.auraTextDarkSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AuraDimensions.spaceXL),

            // Badge
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: isUnlocked
                    ? LinearGradient(
                        colors: badge.backgroundGradient
                            .map((c) => Color(int.parse(c.replaceFirst('#', '0xFF'))))
                            .toList(),
                      )
                    : null,
                color: isUnlocked ? null : AuraColors.auraGlass,
                shape: BoxShape.circle,
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: tierColor.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ]
                    : null,
              ),
              child: isUnlocked
                  ? Icon(
                      _getIconData(badge.icon),
                      color: Colors.white,
                      size: 56,
                    )
                  : Icon(
                      Icons.lock_outline,
                      color: AuraColors.auraTextDarkSecondary,
                      size: 40,
                    ),
            ),
            const SizedBox(height: AuraDimensions.spaceL),

            // Nom
            Text(
              badge.name,
              style: AuraTypography.h2.copyWith(
                color: AuraColors.auraTextDark,
              ),
            ),
            const SizedBox(height: AuraDimensions.spaceS),

            // Tier
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AuraDimensions.spaceM,
                vertical: AuraDimensions.spaceS,
              ),
              decoration: BoxDecoration(
                color: tierColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
              ),
              child: Text(
                '${badge.tierLabel} • ${badge.categoryLabel}',
                style: AuraTypography.labelLarge.copyWith(
                  color: tierColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: AuraDimensions.spaceM),

            // Description
            Text(
              badge.description,
              style: AuraTypography.bodyLarge.copyWith(
                color: AuraColors.auraTextDarkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuraDimensions.spaceM),

            // Condition de déblocage
            if (!isUnlocked) ...[
              Container(
                padding: const EdgeInsets.all(AuraDimensions.spaceM),
                decoration: BoxDecoration(
                  color: AuraColors.auraGlass,
                  borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
                ),
                child: Column(
                  children: [
                    Text(
                      'Condition de déblocage',
                      style: AuraTypography.labelLarge.copyWith(
                        color: AuraColors.auraTextDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AuraDimensions.spaceS),
                    Text(
                      _getUnlockCondition(badge),
                      style: AuraTypography.bodyMedium.copyWith(
                        color: AuraColors.auraTextDarkSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            if (isUnlocked && userBadge.unlockedAt != null) ...[
              Text(
                'Débloqué le ${_formatDate(userBadge.unlockedAt!)}',
                style: AuraTypography.bodyMedium.copyWith(
                  color: AuraColors.auraGreen,
                ),
              ),
            ],

            const SizedBox(height: AuraDimensions.spaceXL),

            // Bouton partager (si débloqué)
            if (isUnlocked)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticService.mediumTap();
                    // TODO: Share badge
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Partager'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuraColors.auraAmber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: AuraDimensions.spaceL),
          ],
        ),
      ),
    );
  }

  Color _getTierColor(BadgeTier tier) {
    return switch (tier) {
      BadgeTier.bronze => const Color(0xFFCD7F32),
      BadgeTier.silver => const Color(0xFFC0C0C0),
      BadgeTier.gold => const Color(0xFFFFD700),
      BadgeTier.platinum => const Color(0xFFE5E4E2),
      BadgeTier.diamond => const Color(0xFFB9F2FF),
    };
  }

  IconData _getIconData(String icon) {
    return switch (icon) {
      'savings' => Icons.savings,
      'local_fire_department' => Icons.local_fire_department,
      'shopping_bag' => Icons.shopping_bag,
      'share' => Icons.share,
      'document_scanner' => Icons.document_scanner,
      'smart_toy' => Icons.smart_toy,
      'trending_up' => Icons.trending_up,
      'visibility_off' => Icons.visibility_off,
      'wb_sunny' => Icons.wb_sunny,
      'emoji_events' => Icons.emoji_events,
      'coffee' => Icons.coffee,
      'check_circle' => Icons.check_circle,
      'restaurant' => Icons.restaurant,
      'receipt_long' => Icons.receipt_long,
      'explore' => Icons.explore,
      'star' => Icons.star,
      _ => Icons.emoji_events,
    };
  }

  String _getUnlockCondition(Badge badge) {
    return switch (badge.unlockType) {
      BadgeUnlockType.challengeCompletion => 'Complétez le défi associé',
      BadgeUnlockType.streakDays => 'Maintenez une série de ${badge.unlockRequirement['days'] ?? 7} jours',
      BadgeUnlockType.amountSaved => 'Épargnez ${badge.unlockRequirement['amount'] ?? 100}€',
      BadgeUnlockType.transactionCount => 'Enregistrez ${badge.unlockRequirement['count'] ?? 10} transactions',
      BadgeUnlockType.featureUsage => 'Utilisez la feature ${badge.unlockRequirement['feature'] ?? ''}',
      BadgeUnlockType.socialShare => 'Partagez ${badge.unlockRequirement['count'] ?? 1} accomplissements',
      BadgeUnlockType.specialEvent => 'Événement spécial',
    };
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  List<_MockUserBadge> _getMockBadges() {
    return [
      _MockUserBadge(
        badge: Badge(
          id: '1',
          code: 'first_saving',
          name: 'Premier Pas',
          description: 'Épargnez votre premier euro',
          category: BadgeCategory.saving,
          tier: BadgeTier.bronze,
          unlockType: BadgeUnlockType.amountSaved,
          unlockRequirement: {'amount': 1},
          icon: 'savings',
          createdAt: DateTime.now(),
        ),
        isUnlocked: true,
        isNew: false,
        unlockedAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      _MockUserBadge(
        badge: Badge(
          id: '2',
          code: 'saving_100',
          name: 'Centurion',
          description: 'Épargnez 100€',
          category: BadgeCategory.saving,
          tier: BadgeTier.bronze,
          unlockType: BadgeUnlockType.amountSaved,
          unlockRequirement: {'amount': 100},
          icon: 'savings',
          createdAt: DateTime.now(),
        ),
        isUnlocked: true,
        isNew: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      _MockUserBadge(
        badge: Badge(
          id: '3',
          code: 'streak_7',
          name: 'Semaine parfaite',
          description: '7 jours consécutifs sous budget',
          category: BadgeCategory.streak,
          tier: BadgeTier.bronze,
          unlockType: BadgeUnlockType.streakDays,
          unlockRequirement: {'days': 7},
          icon: 'local_fire_department',
          createdAt: DateTime.now(),
        ),
        isUnlocked: true,
        isNew: false,
        unlockedAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      _MockUserBadge(
        badge: Badge(
          id: '4',
          code: 'streak_30',
          name: 'Mois discipliné',
          description: '30 jours consécutifs sous budget',
          category: BadgeCategory.streak,
          tier: BadgeTier.silver,
          unlockType: BadgeUnlockType.streakDays,
          unlockRequirement: {'days': 30},
          icon: 'local_fire_department',
          createdAt: DateTime.now(),
        ),
        isUnlocked: false,
        isNew: false,
      ),
      _MockUserBadge(
        badge: Badge(
          id: '5',
          code: 'saving_1000',
          name: 'Millénaire',
          description: 'Épargnez 1 000€',
          category: BadgeCategory.saving,
          tier: BadgeTier.silver,
          unlockType: BadgeUnlockType.amountSaved,
          unlockRequirement: {'amount': 1000},
          icon: 'savings',
          createdAt: DateTime.now(),
        ),
        isUnlocked: false,
        isNew: false,
      ),
      _MockUserBadge(
        badge: Badge(
          id: '6',
          code: 'vampire_hunter',
          name: 'Chasseur de vampires',
          description: 'Détectez et résiliez un abonnement caché',
          category: BadgeCategory.special,
          tier: BadgeTier.gold,
          unlockType: BadgeUnlockType.specialEvent,
          unlockRequirement: {'event': 'vampire_detected'},
          icon: 'visibility_off',
          isSecret: true,
          createdAt: DateTime.now(),
        ),
        isUnlocked: false,
        isNew: false,
      ),
    ];
  }
}

// Mock class
class _MockUserBadge {
  final Badge badge;
  final bool isUnlocked;
  final bool isNew;
  final DateTime? unlockedAt;

  _MockUserBadge({
    required this.badge,
    required this.isUnlocked,
    this.isNew = false,
    this.unlockedAt,
  });
}
