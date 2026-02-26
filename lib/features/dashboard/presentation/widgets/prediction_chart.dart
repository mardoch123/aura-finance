import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/animations/pulse_ring.dart';
import '../../domain/models/dashboard_models.dart';

/// Graphique de prédiction du solde sur 30 jours
/// Affiche une courbe Bézier avec zone de gradient
class PredictionChart extends StatefulWidget {
  const PredictionChart({
    super.key,
    required this.prediction,
    this.height = 220,
    this.onPointSelected,
  });

  final PredictionResult prediction;
  final double height;
  final Function(BalancePredictionPoint point, int index)? onPointSelected;

  @override
  State<PredictionChart> createState() => _PredictionChartState();
}

class _PredictionChartState extends State<PredictionChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.prediction.points;
    if (points.isEmpty) return const SizedBox.shrink();

    final minY = points.map((p) => p.predictedBalance).reduce((a, b) => a < b ? a : b);
    final maxY = points.map((p) => p.predictedBalance).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.compass_calibration_outlined,
              size: 18,
              color: AuraColors.auraAccentGold,
            ),
            const SizedBox(width: 8),
            Text(
              'Prévision 30 jours',
              style: AuraTypography.labelLarge.copyWith(
                color: AuraColors.auraTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AuraDimensions.spaceM),

        // Graphique
        SizedBox(
          height: widget.height,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return LineChart(
                _buildChartData(
                  points,
                  minY - padding,
                  maxY + padding,
                ),
                duration: const Duration(milliseconds: 250),
              );
            },
          ),
        ),

        // Avertissement si risque de découvert
        if (widget.prediction.criticalDate != null) ...[
          const SizedBox(height: AuraDimensions.spaceM),
          _buildWarningWidget(),
        ],
      ],
    );
  }

  LineChartData _buildChartData(
    List<BalancePredictionPoint> points,
    double minY,
    double maxY,
  ) {
    final spots = points.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.predictedBalance);
    }).toList();

    // Trouver le point critique (solde le plus bas)
    final criticalIndex = points.indexWhere(
      (p) => p.predictedBalance == widget.prediction.lowestBalance,
    );

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (maxY - minY) / 4,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: AuraColors.auraGlassBorder,
            strokeWidth: 0.5,
            dashArray: [5, 5],
          );
        },
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}€',
                style: AuraTypography.labelSmall.copyWith(
                  color: AuraColors.auraTextSecondary,
                  fontSize: 10,
                ),
              );
            },
            interval: (maxY - minY) / 3,
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index % 7 != 0) return const SizedBox.shrink();
              
              final date = points[index].date;
              return Text(
                'J+${index + 1}',
                style: AuraTypography.labelSmall.copyWith(
                  color: AuraColors.auraTextSecondary,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: points.length - 1.toDouble(),
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        // Zone de risque (solde < 0)
        if (widget.prediction.lowestBalance != null &&
            widget.prediction.lowestBalance! < 0)
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            barWidth: 0,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AuraColors.auraRed.withOpacity(0.3),
                  AuraColors.auraRed.withOpacity(0.0),
                ],
                stops: const [0.0, 0.5],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              cutOffY: 0,
              applyCutOffY: true,
            ),
            dotData: const FlDotData(show: false),
          ),

        // Ligne principale
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          barWidth: 2.5,
          isStrokeCapRound: true,
          gradient: const LinearGradient(
            colors: [
              AuraColors.auraAccentGold,
              AuraColors.auraAmber,
            ],
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AuraColors.auraAccentGold.withOpacity(0.3),
                AuraColors.auraAccentGold.withOpacity(0.0),
              ],
              stops: const [0.0, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) {
              // Point aujourd'hui (index 0)
              if (index == 0) {
                return FlDotCirclePainter(
                  radius: 6,
                  color: Colors.white,
                  strokeWidth: 3,
                  strokeColor: AuraColors.auraAccentGold,
                );
              }
              // Point critique
              if (index == criticalIndex) {
                return FlDotCirclePainter(
                  radius: 6,
                  color: AuraColors.auraRed,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              }
              return FlDotCirclePainter(
                radius: 0,
                color: Colors.transparent,
              );
            },
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: AuraColors.auraDark.withOpacity(0.9),
          tooltipRoundedRadius: AuraDimensions.radiusM,
          tooltipPadding: const EdgeInsets.all(12),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final point = points[spot.x.toInt()];
              final date = point.date;
              final dayLabel = 'J+${spot.x.toInt() + 1}';
              
              return LineTooltipItem(
                '$dayLabel\n',
                AuraTypography.labelSmall.copyWith(
                  color: AuraColors.auraTextSecondary,
                ),
                children: [
                  TextSpan(
                    text: '${point.predictedBalance.toStringAsFixed(0)}€',
                    style: AuraTypography.labelLarge.copyWith(
                      color: AuraColors.auraTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
        getTouchedSpotIndicator: (barData, spotIndexes) {
          return spotIndexes.map((index) {
            return TouchedSpotIndicatorData(
              FlLine(
                color: AuraColors.auraGlassBorder,
                strokeWidth: 1,
                dashArray: [5, 5],
              ),
              FlDotData(
                getDotPainter: (spot, percent, bar, index) {
                  return FlDotCirclePainter(
                    radius: 8,
                    color: AuraColors.auraAccentGold,
                    strokeWidth: 3,
                    strokeColor: Colors.white,
                  );
                },
              ),
            );
          }).toList();
        },
      ),
    );
  }

  Widget _buildWarningWidget() {
    final criticalDate = widget.prediction.criticalDate!;
    final daysUntil = criticalDate.difference(DateTime.now()).inDays;
    
    return Container(
      padding: AuraDimensions.paddingM,
      decoration: BoxDecoration(
        color: AuraColors.auraRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
        border: Border.all(
          color: AuraColors.auraRed.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AuraColors.auraRed,
            size: 20,
          ),
          const SizedBox(width: AuraDimensions.spaceS),
          Expanded(
            child: Text(
              '⚠️ Risque de découvert le ${criticalDate.day}/${criticalDate.month} si tendance maintenue',
              style: AuraTypography.bodySmall.copyWith(
                color: AuraColors.auraRed,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher le point "Aujourd'hui" avec halo pulsant
class TodayIndicator extends StatelessWidget {
  const TodayIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return PulseRing(
      size: 24,
      color: AuraColors.auraAccentGold,
      ringWidth: 2,
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
      ),
    );
  }
}
