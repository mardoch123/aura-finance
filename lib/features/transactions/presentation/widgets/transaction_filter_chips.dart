import 'package:flutter/material.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../domain/transaction_model.dart';

/// Chips de filtrage des transactions
class TransactionFilterChips extends StatelessWidget {
  final TransactionFilter selectedFilter;
  final Function(TransactionFilter) onFilterChanged;

  const TransactionFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceM),
      child: Row(
        children: TransactionFilter.values.map((filter) {
          final isSelected = filter == selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: AuraDimensions.spaceS),
            child: _FilterChip(
              label: filter.label,
              isSelected: isSelected,
              onTap: () => onFilterChanged(filter),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AuraDimensions.spaceM,
          vertical: AuraDimensions.spaceS,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AuraColors.auraAmber
              : AuraColors.auraGlass,
          borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
          border: isSelected
              ? null
              : Border.all(color: AuraColors.auraGlassBorder),
        ),
        child: Text(
          label,
          style: AuraTypography.labelMedium.copyWith(
            color: isSelected
                ? Colors.white
                : AuraColors.auraTextDark,
          ),
        ),
      ),
    );
  }
}
