import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../data/calculators_service.dart';
import '../../domain/calculator_models.dart';

/// Calculateur de ROI
class ROICalculatorScreen extends ConsumerStatefulWidget {
  const ROICalculatorScreen({super.key});

  @override
  ConsumerState<ROICalculatorScreen> createState() => _ROICalculatorScreenState();
}

class _ROICalculatorScreenState extends ConsumerState<ROICalculatorScreen> {
  final _initialController = TextEditingController(text: '10000');
  final _finalController = TextEditingController(text: '15000');
  final _yearsController = TextEditingController(text: '5');
  
  ROIResult? _result;
  final List<double> _cashFlows = [];

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    final initial = double.tryParse(_initialController.text.replaceAll(' ', '')) ?? 0;
    final final_value = double.tryParse(_finalController.text.replaceAll(' ', '')) ?? 0;
    final years = int.tryParse(_yearsController.text) ?? 1;

    if (initial > 0 && years > 0) {
      setState(() {
        _result = CalculatorsService.instance.calculateROI(
          initialInvestment: initial,
          finalValue: final_value,
          holdingPeriodYears: years,
          cashFlows: _cashFlows.isNotEmpty ? _cashFlows : null,
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
              'ROI Investissement',
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
                    _buildComparisonSection(),
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
          _buildInputField(
            label: 'Investissement initial',
            controller: _initialController,
            suffix: '€',
            onChanged: (_) => _calculate(),
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Valeur finale',
            controller: _finalController,
            suffix: '€',
            onChanged: (_) => _calculate(),
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Durée de détention',
            controller: _yearsController,
            suffix: 'ans',
            onChanged: (_) => _calculate(),
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
            fontSize: 14,
            color: AuraColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.dmSans(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            suffixText: suffix,
            suffixStyle: GoogleFonts.dmSans(
              fontSize: 16,
              color: AuraColors.amber,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    final isPositive = (_result?.roi ?? 0) >= 0;
    final color = isPositive ? AuraColors.green : AuraColors.red;

    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Retour sur investissement',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AuraColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_result!.roi >= 0 ? '+' : ''}${_result!.roi.toStringAsFixed(1)}%',
            style: GoogleFonts.dmSans(
              fontSize: 56,
              fontWeight: FontWeight.w300,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'soit ${_result!.annualizedROI.toStringAsFixed(1)}% / an',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              color: AuraColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${isPositive ? '+' : ''}${_result!.netProfit.toStringAsFixed(0)} € net',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comparaison avec',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildComparisonCard(
          name: 'Livret A',
          rate: 3.0,
          icon: '🏦',
        ),
        const SizedBox(height: 12),
        _buildComparisonCard(
          name: 'ETF Monde (moyenne)',
          rate: 8.0,
          icon: '🌍',
        ),
        const SizedBox(height: 12),
        _buildComparisonCard(
          name: 'S&P 500 (historique)',
          rate: 10.0,
          icon: '📈',
        ),
      ],
    );
  }

  Widget _buildComparisonCard({
    required String name,
    required double rate,
    required String icon,
  }) {
    final years = int.tryParse(_yearsController.text) ?? 5;
    final initial = double.tryParse(_initialController.text.replaceAll(' ', '')) ?? 10000;
    
    // Calculer le résultat avec ce taux
    final compoundResult = CalculatorsService.instance.calculateCompoundInterest(
      initialInvestment: initial,
      monthlyContribution: 0,
      annualRate: rate,
      years: years,
    );

    final userResult = _result!.finalValue;
    final isBetter = userResult > compoundResult.finalAmount;

    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AuraColors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$rate% / an → ${compoundResult.finalAmount.toStringAsFixed(0)} €',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AuraColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isBetter ? AuraColors.green.withOpacity(0.2) : AuraColors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isBetter ? 'Meilleur' : 'Moins',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isBetter ? AuraColors.green : AuraColors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _initialController.dispose();
    _finalController.dispose();
    _yearsController.dispose();
    super.dispose();
  }
}
