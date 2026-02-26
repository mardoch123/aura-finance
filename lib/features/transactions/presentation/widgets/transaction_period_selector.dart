import 'package:flutter/material.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../domain/transaction_model.dart';

/// Sélecteur de période pour les transactions
class TransactionPeriodSelector extends StatelessWidget {
  final TransactionPeriod selectedPeriod;
  final Function(TransactionPeriod) onPeriodChanged;

  const TransactionPeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AuraDimensions.spaceM,
        vertical: AuraDimensions.spaceS,
      ),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AuraColors.auraGlass,
        borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
      ),
      child: Row(
        children: [
          _PeriodButton(
            label: 'Jour',
            isSelected: selectedPeriod == TransactionPeriod.today,
            onTap: () => onPeriodChanged(TransactionPeriod.today),
          ),
          _PeriodButton(
            label: 'Semaine',
            isSelected: selectedPeriod == TransactionPeriod.week,
            onTap: () => onPeriodChanged(TransactionPeriod.week),
          ),
          _PeriodButton(
            label: 'Mois',
            isSelected: selectedPeriod == TransactionPeriod.month,
            onTap: () => onPeriodChanged(TransactionPeriod.month),
          ),
          _PeriodButton(
            label: 'Année',
            isSelected: selectedPeriod == TransactionPeriod.year,
            onTap: () => onPeriodChanged(TransactionPeriod.year),
          ),
        ],
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AuraDimensions.spaceS),
          decoration: BoxDecoration(
            color: isSelected
                ? AuraColors.auraAmber
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AuraTypography.labelSmall.copyWith(
              color: isSelected
                  ? Colors.white
                  : AuraColors.auraTextDarkSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
