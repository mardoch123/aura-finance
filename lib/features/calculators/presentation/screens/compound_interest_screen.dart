import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../data/calculators_service.dart';
import '../../domain/calculator_models.dart';

/// Calculateur d'intérêts composés
class CompoundInterestScreen extends ConsumerStatefulWidget {
  const CompoundInterestScreen({super.key});

  @override
  ConsumerState<CompoundInterestScreen> createState() => _CompoundInterestScreenState();
}

class _CompoundInterestScreenState extends ConsumerState<CompoundInterestScreen> {
  final _initialController = TextEditingController(text: '10000');
  final _monthlyController = TextEditingController(text: '200');
  final _rateController = TextEditingController(text: '7');
  final _yearsController = TextEditingController(text: '20');
  
  CompoundInterestResult? _result;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    final initial = double.tryParse(_initialController.text.replaceAll(' ', '')) ?? 0;
    final monthly = double.tryParse(_monthlyController.text.replaceAll(' ', '')) ?? 0;
    final rate = double.tryParse(_rateController.text.replaceAll(',', '.')) ?? 0;
    final years = int.tryParse(_yearsController.text) ?? 20;

    if (years > 0) {
      setState(() {
        _result = CalculatorsService.instance.calculateCompoundInterest(
          initialInvestment: initial,
          monthlyContribution: monthly,
          annualRate: rate,
          years: years,
        );
      });
      HapticService.lightTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: AuraColors.background.withOpacity(0.9),
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            ),
            title: Text(
              'Intérêts Composés',
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AuraColors.amber.withOpacity(0.2),
                      AuraColors.background,
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInputSection(),
                  const SizedBox(height: 24),
                  
                  if (_result != null) ...[
                    _buildResultCard(),
                    const SizedBox(height: 24),
                    _buildChart(),
                    const SizedBox(height: 24),
                    _buildBreakdownSection(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  label: 'Départ',
                  controller: _initialController,
                  suffix: '€',
                  onChanged: (_) => _calculate(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputField(
                  label: '/mois',
                  controller: _monthlyController,
                  suffix: '€',
                  onChanged: (_) => _calculate(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  label: 'Rendement',
                  controller: _rateController,
                  suffix: '%',
                  onChanged: (_) => _calculate(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputField(
                  label: 'Années',
                  controller: _yearsController,
                  suffix: 'ans',
                  onChanged: (_) => _calculate(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String suffix,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: AuraColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            suffixText: suffix,
            suffixStyle: GoogleFonts.dmSans(
              fontSize: 14,
              color: AuraColors.amber,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: onChanged,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d\s,.]')),
          ],
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Montant final',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AuraColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_result!.finalAmount.toStringAsFixed(0)} €',
            style: GoogleFonts.dmSans(
              fontSize: 48,
              fontWeight: FontWeight.w300,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildResultItem(
                label: 'Versements',
                value: '${_result!.totalContributions.toStringAsFixed(0)} €',
                color: AuraColors.amber,
              ),
              Container(width: 1, height: 40, color: Colors.white12),
              _buildResultItem(
                label: 'Intérêts gagnés',
                value: '${_result!.totalInterest.toStringAsFixed(0)} €',
                color: AuraColors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: AuraColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    final spots = _result!.yearlyBreakdown.map((y) {
      return FlSpot(y.year.toDouble(), y.endBalance);
    }).toList();

    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Évolution sur ${_result!.years} ans',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (_result!.years / 4).ceil().toDouble(),
                      getTitlesWidget: (value, meta) {
                        return Text(
                          'A${value.toInt()}',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: AuraColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AuraColors.amber,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AuraColors.amber.withOpacity(0.2),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 12,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(0)} €',
                          GoogleFonts.dmSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Détail par année',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ..._result!.yearlyBreakdown.take(5).map((year) => _buildYearRow(year)),
        if (_result!.yearlyBreakdown.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '+ ${_result!.yearlyBreakdown.length - 5} autres années...',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AuraColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildYearRow(YearlyGrowth year) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AuraColors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  'A${year.year}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AuraColors.amber,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${year.endBalance.toStringAsFixed(0)} €',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '+${year.interest.toStringAsFixed(0)} € d\'intérêts',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AuraColors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _initialController.dispose();
    _monthlyController.dispose();
    _rateController.dispose();
    _yearsController.dispose();
    super.dispose();
  }
}
