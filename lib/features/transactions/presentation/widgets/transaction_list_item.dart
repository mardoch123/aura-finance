import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/transaction_model.dart';

/// Item de liste pour une transaction
class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('dd MMM', 'fr_FR');

    return Dismissible(
      key: Key(transaction.id),
      direction: onDelete != null ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        decoration: BoxDecoration(
          color: AuraColors.auraRed,
          borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AuraDimensions.spaceM),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AuraDimensions.spaceM),
        child: Row(
          children: [
            // Icône de catégorie
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _parseColor(transaction.categoryColor).withOpacity(0.15),
                borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
              ),
              child: Center(
                child: Text(
                  transaction.categoryIcon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),

            const SizedBox(width: AuraDimensions.spaceM),

            // Informations
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.merchant ?? transaction.category,
                    style: AuraTypography.labelLarge.copyWith(
                      color: AuraColors.auraTextDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        dateFormat.format(transaction.date),
                        style: AuraTypography.bodySmall.copyWith(
                          color: AuraColors.auraTextDarkSecondary,
                        ),
                      ),
                      if (transaction.isRecurring) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AuraColors.auraAmber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Récurent',
                            style: AuraTypography.caption.copyWith(
                              color: AuraColors.auraAmber,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Montant
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(transaction.amount),
                  style: AuraTypography.amountSmall.copyWith(
                    color: transaction.isExpense
                        ? AuraColors.auraRed
                        : AuraColors.auraGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (transaction.aiConfidence != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: AuraColors.auraAmber.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(transaction.aiConfidence! * 100).toInt()}%',
                        style: AuraTypography.caption.copyWith(
                          color: AuraColors.auraTextDarkSecondary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AuraColors.auraAmber;
    }
  }
}

/// Widget shimmer pour le chargement
class TransactionListShimmer extends StatelessWidget {
  const TransactionListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceM),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: AuraDimensions.spaceS),
        child: GlassCard(
          height: 72,
          padding: const EdgeInsets.all(AuraDimensions.spaceM),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AuraColors.auraGlass,
                  borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
                ),
              ),
              const SizedBox(width: AuraDimensions.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AuraColors.auraGlass,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AuraColors.auraGlass,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 20,
                decoration: BoxDecoration(
                  color: AuraColors.auraGlass,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
