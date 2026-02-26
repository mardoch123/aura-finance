import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/animations/staggered_animator.dart';
import '../../domain/models/dashboard_models.dart';

/// Liste des transactions récentes avec animation staggered
class RecentTransactionsList extends StatelessWidget {
  const RecentTransactionsList({
    super.key,
    required this.transactions,
    this.onTransactionTap,
    this.onViewAll,
    this.maxItems = 5,
  });

  final List<DashboardTransaction> transactions;
  final Function(DashboardTransaction transaction)? onTransactionTap;
  final VoidCallback? onViewAll;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final displayTransactions = transactions.take(maxItems).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AuraDimensions.spaceM,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transactions récentes',
                style: AuraTypography.h4.copyWith(
                  color: AuraColors.auraTextDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onViewAll != null)
                GestureDetector(
                  onTap: () {
                    HapticService.lightTap();
                    onViewAll!();
                  },
                  child: Text(
                    'Voir tout',
                    style: AuraTypography.labelMedium.copyWith(
                      color: AuraColors.auraAmber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: AuraDimensions.spaceM),
        
        // Liste
        if (displayTransactions.isEmpty)
          _buildEmptyState()
        else
          StaggeredAnimator(
            delay: const Duration(milliseconds: 60),
            duration: const Duration(milliseconds: 400),
            children: displayTransactions
                .asMap()
                .entries
                .map((entry) => _buildTransactionItem(
                      entry.value,
                      entry.key,
                      isLast: entry.key == displayTransactions.length - 1,
                    ))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: AuraDimensions.paddingL,
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AuraColors.auraTextDarkSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: AuraDimensions.spaceM),
            Text(
              'Aucune transaction récente',
              style: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.auraTextDarkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
    DashboardTransaction transaction,
    int index, {
    required bool isLast,
  }) {
    final isExpense = transaction.amount < 0;
    final absAmount = transaction.amount.abs();
    final categoryColors = TransactionCategories.getColors(transaction.category);
    final emoji = TransactionCategories.getEmoji(transaction.category);
    final dateFormat = DateFormat('dd MMM', 'fr_FR');

    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        onTransactionTap?.call(transaction);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AuraDimensions.spaceM,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AuraDimensions.spaceM,
              ),
              child: Row(
                children: [
                  // Icône catégorie
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(categoryColors.light),
                          Color(categoryColors.light).withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        AuraDimensions.radiusM,
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: AuraDimensions.spaceM),
                  
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.merchant ??
                              transaction.category.toUpperCase(),
                          style: AuraTypography.bodyMedium.copyWith(
                            color: AuraColors.auraTextDark,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateFormat.format(transaction.date),
                          style: AuraTypography.bodySmall.copyWith(
                            color: AuraColors.auraTextDarkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Montant
                  Text(
                    '${isExpense ? '-' : '+'}${absAmount.toStringAsFixed(2)}€',
                    style: AuraTypography.labelLarge.copyWith(
                      color: isExpense
                          ? AuraColors.auraRed
                          : AuraColors.auraGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            
            // Séparateur gradient
            if (!isLast)
              Container(
                height: 1,
                margin: const EdgeInsets.only(left: 60),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AuraColors.auraGlassBorder,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget de shimmer pour le chargement des transactions
class TransactionsShimmer extends StatelessWidget {
  const TransactionsShimmer({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AuraDimensions.spaceM,
          ),
          child: Container(
            width: 180,
            height: 24,
            decoration: BoxDecoration(
              color: AuraColors.auraGlass,
              borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
            ),
          ),
        ),
        const SizedBox(height: AuraDimensions.spaceM),
        ...List.generate(itemCount, (index) => _buildShimmerItem()),
      ],
    );
  }

  Widget _buildShimmerItem() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AuraDimensions.spaceM,
        vertical: AuraDimensions.spaceS,
      ),
      padding: const EdgeInsets.symmetric(
        vertical: AuraDimensions.spaceM,
      ),
      child: Row(
        children: [
          // Icône shimmer
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AuraColors.auraGlass,
              borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
            ),
          ),
          const SizedBox(width: AuraDimensions.spaceM),
          // Text shimmer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AuraColors.auraGlass,
                    borderRadius: BorderRadius.circular(AuraDimensions.radiusXS),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AuraColors.auraGlass,
                    borderRadius: BorderRadius.circular(AuraDimensions.radiusXS),
                  ),
                ),
              ],
            ),
          ),
          // Montant shimmer
          Container(
            width: 60,
            height: 18,
            decoration: BoxDecoration(
              color: AuraColors.auraGlass,
              borderRadius: BorderRadius.circular(AuraDimensions.radiusXS),
            ),
          ),
        ],
      ),
    );
  }
}
