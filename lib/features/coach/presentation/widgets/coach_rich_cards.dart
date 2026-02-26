import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/coach_message.dart';

/// Carte de graphique sparkline
class MiniChartCard extends StatelessWidget {
  const MiniChartCard({
    super.key,
    required this.data,
    this.title,
    this.subtitle,
  });

  final List<double> data;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: AuraDimensions.radiusL,
      padding: AuraDimensions.paddingM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: AuraTypography.labelMedium.copyWith(
                color: AuraColors.auraTextDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AuraDimensions.spaceXS),
          ],
          if (subtitle != null) ...[
            Text(
              subtitle!,
              style: AuraTypography.labelSmall.copyWith(
                color: AuraColors.auraTextDarkSecondary,
              ),
            ),
            const SizedBox(height: AuraDimensions.spaceM),
          ],
          SizedBox(
            height: 80,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: data.length.toDouble() - 1,
                minY: data.reduce((a, b) => a < b ? a : b) * 0.9,
                maxY: data.reduce((a, b) => a > b ? a : b) * 1.1,
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value);
                    }).toList(),
                    isCurved: true,
                    color: AuraColors.auraAmber,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AuraColors.auraAmber.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte de transaction
class TransactionCard extends StatelessWidget {
  const TransactionCard({
    super.key,
    required this.merchant,
    required this.amount,
    required this.category,
    this.date,
    this.icon,
  });

  final String merchant;
  final double amount;
  final String category;
  final DateTime? date;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: AuraDimensions.radiusL,
      padding: AuraDimensions.paddingM,
      child: Row(
        children: [
          // Icône de catégorie
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AuraColors.gradientAmber,
              borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
            ),
            child: Icon(
              icon ?? Icons.receipt,
              color: AuraColors.auraTextPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: AuraDimensions.spaceM),
          
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchant,
                  style: AuraTypography.labelLarge.copyWith(
                    color: AuraColors.auraTextDark,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  category,
                  style: AuraTypography.labelSmall.copyWith(
                    color: AuraColors.auraTextDarkSecondary,
                  ),
                ),
                if (date != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(date!),
                    style: AuraTypography.labelSmall.copyWith(
                      color: AuraColors.auraTextDarkSecondary.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Montant
          Text(
            '-${amount.toStringAsFixed(2)}€',
            style: AuraTypography.labelLarge.copyWith(
              color: AuraColors.auraRed,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}

/// Carte de progression d'objectif
class GoalProgressCard extends StatelessWidget {
  const GoalProgressCard({
    super.key,
    required this.name,
    required this.currentAmount,
    required this.targetAmount,
    this.deadline,
    this.color,
  });

  final String name;
  final double currentAmount;
  final double targetAmount;
  final DateTime? deadline;
  final Color? color;

  double get progress => (currentAmount / targetAmount).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AuraColors.auraAmber;
    
    return GlassCard(
      borderRadius: AuraDimensions.radiusL,
      padding: AuraDimensions.paddingM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: effectiveColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
                ),
                child: Icon(
                  Icons.flag,
                  color: effectiveColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AuraDimensions.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AuraTypography.labelLarge.copyWith(
                        color: AuraColors.auraTextDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (deadline != null)
                      Text(
                        'Échéance: ${_formatDate(deadline!)}',
                        style: AuraTypography.labelSmall.copyWith(
                          color: AuraColors.auraTextDarkSecondary,
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
            borderRadius: BorderRadius.circular(AuraDimensions.radiusXS),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AuraColors.auraGlass,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceS),
          
          // Montants
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currentAmount.toStringAsFixed(0)}€',
                style: AuraTypography.labelMedium.copyWith(
                  color: AuraColors.auraTextDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${targetAmount.toStringAsFixed(0)}€',
                style: AuraTypography.labelSmall.copyWith(
                  color: AuraColors.auraTextDarkSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// Carte d'alerte Vampire
class VampireAlertCard extends StatelessWidget {
  const VampireAlertCard({
    super.key,
    required this.subscriptionName,
    required this.oldAmount,
    required this.newAmount,
    this.onActionPressed,
  });

  final String subscriptionName;
  final double oldAmount;
  final double newAmount;
  final VoidCallback? onActionPressed;

  double get increase => newAmount - oldAmount;
  double get increasePercentage => ((newAmount - oldAmount) / oldAmount) * 100;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: AuraDimensions.radiusL,
      padding: AuraDimensions.paddingM,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AuraColors.auraRed.withOpacity(0.2),
          AuraColors.auraGlass,
        ],
      ),
      borderColor: AuraColors.auraRed.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AuraColors.auraRed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AuraColors.auraRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: AuraDimensions.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hausse détectée',
                      style: AuraTypography.labelSmall.copyWith(
                        color: AuraColors.auraRed,
                      ),
                    ),
                    Text(
                      subscriptionName,
                      style: AuraTypography.labelLarge.copyWith(
                        color: AuraColors.auraTextDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AuraDimensions.spaceM),
          
          // Détails de la hausse
          Row(
            children: [
              Text(
                '${oldAmount.toStringAsFixed(2)}€',
                style: AuraTypography.bodyMedium.copyWith(
                  color: AuraColors.auraTextDarkSecondary,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: AuraDimensions.spaceS),
              const Icon(
                Icons.arrow_forward,
                size: 16,
                color: AuraColors.auraTextDarkSecondary,
              ),
              const SizedBox(width: AuraDimensions.spaceS),
              Text(
                '${newAmount.toStringAsFixed(2)}€',
                style: AuraTypography.bodyMedium.copyWith(
                  color: AuraColors.auraRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AuraDimensions.spaceS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AuraDimensions.spaceXS,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AuraColors.auraRed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AuraDimensions.radiusXS),
                ),
                child: Text(
                  '+${increasePercentage.toStringAsFixed(0)}%',
                  style: AuraTypography.labelSmall.copyWith(
                    color: AuraColors.auraRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AuraDimensions.spaceM),
          
          // Bouton d'action
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onActionPressed,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Voir les options'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AuraColors.auraRed.withOpacity(0.2),
                foregroundColor: AuraColors.auraRed,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  vertical: AuraDimensions.spaceS,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Factory pour créer les cartes enrichies selon le type
class CoachRichCardFactory {
  static Widget build(MessageContent content) {
    switch (content.type) {
      case MessageContentType.chart:
        return MiniChartCard(
          data: (content.data['values'] as List?)?.cast<double>() ?? [],
          title: content.data['title'] as String?,
          subtitle: content.data['subtitle'] as String?,
        );
      
      case MessageContentType.transaction:
        return TransactionCard(
          merchant: content.data['merchant'] as String? ?? 'Inconnu',
          amount: (content.data['amount'] as num?)?.toDouble() ?? 0,
          category: content.data['category'] as String? ?? 'Autre',
          date: content.data['date'] != null
              ? DateTime.parse(content.data['date'] as String)
              : null,
          icon: _parseIcon(content.data['icon'] as String?),
        );
      
      case MessageContentType.goal:
        return GoalProgressCard(
          name: content.data['name'] as String? ?? 'Objectif',
          currentAmount: (content.data['currentAmount'] as num?)?.toDouble() ?? 0,
          targetAmount: (content.data['targetAmount'] as num?)?.toDouble() ?? 100,
          deadline: content.data['deadline'] != null
              ? DateTime.parse(content.data['deadline'] as String)
              : null,
          color: content.data['color'] != null
              ? Color(int.parse(content.data['color'] as String))
              : null,
        );
      
      case MessageContentType.alert:
        return VampireAlertCard(
          subscriptionName: content.data['subscriptionName'] as String? ?? 'Abonnement',
          oldAmount: (content.data['oldAmount'] as num?)?.toDouble() ?? 0,
          newAmount: (content.data['newAmount'] as num?)?.toDouble() ?? 0,
        );
      
      default:
        return const SizedBox.shrink();
    }
  }

  static IconData? _parseIcon(String? iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'shopping':
        return Icons.shopping_bag;
      case 'transport':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.health_and_safety;
      default:
        return Icons.receipt;
    }
  }
}
