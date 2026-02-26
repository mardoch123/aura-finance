import 'package:flutter/material.dart';
import '../theme/aura_colors.dart';
import '../theme/aura_typography.dart';
import '../theme/aura_dimensions.dart';
import '../haptics/haptic_service.dart';
import 'glass_card.dart';

/// Chip de catégorie avec icône et couleur
///
/// Usage:
/// ```dart
/// CategoryChip(
///   category: 'food',
///   isSelected: true,
///   onTap: () {},
/// )
/// ```
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    this.isSelected = false,
    this.onTap,
    this.showLabel = true,
    this.size = CategoryChipSize.medium,
  });

  final String category;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showLabel;
  final CategoryChipSize size;

  @override
  Widget build(BuildContext context) {
    final categoryData = CategoryData.get(category);
    final color = categoryData.color;

    final chipSize = switch (size) {
      CategoryChipSize.small => 28.0,
      CategoryChipSize.medium => 36.0,
      CategoryChipSize.large => 48.0,
    };

    final iconSize = switch (size) {
      CategoryChipSize.small => 14.0,
      CategoryChipSize.medium => 18.0,
      CategoryChipSize.large => 24.0,
    };

    final textStyle = switch (size) {
      CategoryChipSize.small => AuraTypography.labelSmall,
      CategoryChipSize.medium => AuraTypography.labelMedium,
      CategoryChipSize.large => AuraTypography.labelLarge,
    };

    Widget chip = GestureDetector(
      onTap: () {
        HapticService.selection();
        onTap?.call();
      },
      child: AnimatedContainer(
        duration: AuraDimensions.durationFast,
        padding: showLabel
            ? EdgeInsets.symmetric(
                horizontal: size == CategoryChipSize.small
                    ? AuraDimensions.spaceS
                    : AuraDimensions.spaceM,
                vertical: size == CategoryChipSize.small
                    ? AuraDimensions.spaceXS
                    : AuraDimensions.spaceS,
              )
            : EdgeInsets.all(size == CategoryChipSize.small
                ? AuraDimensions.spaceXS
                : AuraDimensions.spaceS),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              categoryData.icon,
              size: iconSize,
              color: isSelected ? Colors.white : color,
            ),
            if (showLabel) ...[
              const SizedBox(width: AuraDimensions.spaceXS),
              Text(
                categoryData.label,
                style: textStyle.copyWith(
                  color: isSelected ? Colors.white : AuraColors.auraTextDark,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return chip;
  }
}

/// Version glassmorphism du chip
class CategoryChipGlass extends StatelessWidget {
  const CategoryChipGlass({
    super.key,
    required this.category,
    this.isSelected = false,
    this.onTap,
    this.showLabel = true,
  });

  final String category;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final categoryData = CategoryData.get(category);
    final color = categoryData.color;

    return GestureDetector(
      onTap: () {
        HapticService.selection();
        onTap?.call();
      },
      child: GlassCard(
        padding: showLabel
            ? const EdgeInsets.symmetric(
                horizontal: AuraDimensions.spaceM,
                vertical: AuraDimensions.spaceS,
              )
            : AuraDimensions.paddingS,
        borderRadius: AuraDimensions.radiusS,
        gradient: isSelected
            ? LinearGradient(
                colors: [color.withOpacity(0.5), color.withOpacity(0.3)],
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              categoryData.icon,
              size: 18,
              color: isSelected ? Colors.white : AuraColors.auraTextPrimary,
            ),
            if (showLabel) ...[
              const SizedBox(width: AuraDimensions.spaceXS),
              Text(
                categoryData.label,
                style: AuraTypography.labelMedium.copyWith(
                  color: isSelected
                      ? Colors.white
                      : AuraColors.auraTextPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Icône de catégorie seule
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 40.0,
    this.isGlass = false,
  });

  final String category;
  final double size;
  final bool isGlass;

  @override
  Widget build(BuildContext context) {
    final categoryData = CategoryData.get(category);
    final color = categoryData.color;

    if (isGlass) {
      return GlassCard(
        width: size,
        height: size,
        borderRadius: size / 2,
        gradient: LinearGradient(
          colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
        ),
        child: Center(
          child: Icon(
            categoryData.icon,
            size: size * 0.5,
            color: AuraColors.auraTextPrimary,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          categoryData.icon,
          size: size * 0.5,
          color: color,
        ),
      ),
    );
  }
}

/// Données des catégories
class CategoryData {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const CategoryData({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  static final Map<String, CategoryData> _data = {
    'food': const CategoryData(
      key: 'food',
      label: 'Alimentation',
      icon: Icons.restaurant,
      color: AuraColors.auraAmber,
    ),
    'transport': const CategoryData(
      key: 'transport',
      label: 'Transport',
      icon: Icons.directions_car,
      color: AuraColors.auraGreen,
    ),
    'housing': const CategoryData(
      key: 'housing',
      label: 'Logement',
      icon: Icons.home,
      color: AuraColors.auraDeep,
    ),
    'entertainment': const CategoryData(
      key: 'entertainment',
      label: 'Loisirs',
      icon: Icons.movie,
      color: AuraColors.auraAccentGold,
    ),
    'shopping': const CategoryData(
      key: 'shopping',
      label: 'Shopping',
      icon: Icons.shopping_bag,
      color: AuraColors.auraRed,
    ),
    'health': const CategoryData(
      key: 'health',
      label: 'Santé',
      icon: Icons.favorite,
      color: Color(0xFF7EC8E3),
    ),
    'education': const CategoryData(
      key: 'education',
      label: 'Éducation',
      icon: Icons.school,
      color: Color(0xFFB8A9C9),
    ),
    'travel': const CategoryData(
      key: 'travel',
      label: 'Voyage',
      icon: Icons.flight,
      color: Color(0xFF98D8C8),
    ),
    'utilities': const CategoryData(
      key: 'utilities',
      label: 'Factures',
      icon: Icons.bolt,
      color: AuraColors.auraYellow,
    ),
    'subscriptions': const CategoryData(
      key: 'subscriptions',
      label: 'Abonnements',
      icon: Icons.subscriptions,
      color: Color(0xFFD4A5A5),
    ),
    'income': const CategoryData(
      key: 'income',
      label: 'Revenus',
      icon: Icons.trending_up,
      color: AuraColors.auraGreen,
    ),
    'other': const CategoryData(
      key: 'other',
      label: 'Autre',
      icon: Icons.more_horiz,
      color: Color(0xFFB0B0B0),
    ),
  };

  static CategoryData get(String key) {
    return _data[key] ?? _data['other']!;
  }

  static List<CategoryData> get all => _data.values.toList();

  static List<String> get keys => _data.keys.toList();
}

/// Taille des chips
enum CategoryChipSize {
  small,
  medium,
  large,
}
