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

/// Calculateur de prêt immobilier
class MortgageCalculatorScreen extends ConsumerStatefulWidget {
  const MortgageCalculatorScreen({super.key});

  @override
  ConsumerState<MortgageCalculatorScreen> createState() => _MortgageCalculatorScreenState();
}

class _MortgageCalculatorScreenState extends ConsumerState<MortgageCalculatorScreen> {
  final _principalController = TextEditingController(text: '300000');
  final _rateController = TextEditingController(text: '3.5');
  final _yearsController = TextEditingController(text: '20');
  
  MortgageResult? _result;
  bool _showSchedule = false;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    final principal = double.tryParse(_principalController.text.replaceAll(' ', '')) ?? 0;
    final rate = double.tryParse(_rateController.text.replaceAll(',', '.')) ?? 0;
    final years = int.tryParse(_yearsController.text) ?? 20;

    if (principal > 0 && rate > 0 && years > 0) {
      setState(() {
        _result = CalculatorsService.instance.calculateMortgage(
          principal: principal,
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
            elevation: 0,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            ),
            title: Text(
              'Prêt Immobilier',
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
                  // Inputs
                  _buildInputSection(),
                  const SizedBox(height: 24),
                  
                  // Résultats
                  if (_result != null) ...[
                    _buildResultCard(),
                    const SizedBox(height: 16),
                    _buildSummaryCards(),
                    const SizedBox(height: 24),
                    _buildScheduleToggle(),
                    if (_showSchedule) _buildAmortizationSchedule(),
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
            label: 'Montant emprunté',
            controller: _principalController,
            suffix: '€',
            onChanged: (_) => _calculate(),
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Taux d\'intérêt annuel',
            controller: _rateController,
            suffix: '%',
            onChanged: (_) => _calculate(),
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Durée',
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
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Mensualité',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AuraColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_result!.monthlyPayment.toStringAsFixed(0)} €',
            style: GoogleFonts.dmSans(
              fontSize: 48,
              fontWeight: FontWeight.w300,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'par mois',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AuraColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            label: 'Coût total',
            value: '${_result!.totalCost.toStringAsFixed(0)} €',
            icon: '💰',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            label: 'Intérêts',
            value: '${_result!.totalInterest.toStringAsFixed(0)} €',
            icon: '📈',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required String icon,
  }) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AuraColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleToggle() {
    return GestureDetector(
      onTap: () {
        setState(() => _showSchedule = !_showSchedule);
        HapticService.lightTap();
      },
      child: GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Plan d\'amortissement',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            AnimatedRotation(
              turns: _showSchedule ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: AuraColors.amber,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmortizationSchedule() {
    final entries = _result!.schedule;
    final displayEntries = entries.take(12).toList(); // Premier année

    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Première année',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AuraColors.amber,
            ),
          ),
          const SizedBox(height: 12),
          ...displayEntries.map((entry) => _buildScheduleRow(entry)),
          if (entries.length > 12)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '+ ${entries.length - 12} autres mensualités...',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AuraColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(AmortizationEntry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              'M${entry.month}',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AuraColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: entry.principal / entry.payment,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(AuraColors.amber),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Capital: ${entry.principal.toStringAsFixed(0)}€',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AuraColors.amber,
                      ),
                    ),
                    Text(
                      'Intérêts: ${entry.interest.toStringAsFixed(0)}€',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AuraColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _principalController.dispose();
    _rateController.dispose();
    _yearsController.dispose();
    super.dispose();
  }
}
