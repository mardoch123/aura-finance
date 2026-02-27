import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/extensions/app_localizations_extension.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/animations/staggered_animator.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../domain/calculator_models.dart';

/// Écran principal des calculateurs financiers
class CalculatorsScreen extends ConsumerWidget {
  const CalculatorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AuraColors.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _buildHeader(context),
          ),
          
          // Grille des calculateurs
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverStaggeredAnimator(
              children: CalculatorType.values.map((type) => _buildCalculatorCard(
                context,
                type: type,
                onTap: () => _navigateToCalculator(context, type),
              )).toList(),
              staggerDelay: const Duration(milliseconds: 80),
            ),
          ),
          
          // Section outils rapides
          SliverToBoxAdapter(
            child: _buildQuickToolsSection(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AuraColors.amber.withOpacity(0.3),
            AuraColors.background,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '🧮 ${context.l10n.calculatorTitle}',
            style: GoogleFonts.playfairDisplay(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.calculatorSubtitle,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              color: AuraColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorCard(
    BuildContext context, {
    required CalculatorType type,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticService.mediumTap();
        onTap();
      },
      child: GlassCard(
        borderRadius: 24,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AuraColors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                type.icon,
                style: const TextStyle(fontSize: 28),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              type.displayName,
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              type.description,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AuraColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  context.l10n.calculate,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AuraColors.amber,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AuraColors.amber,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickToolsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.quickTools,
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildQuickToolTile(
                  icon: '⏱️',
                  title: context.l10n.ruleOf72,
                  subtitle: context.l10n.ruleOf72Desc,
                  onTap: () => _showRuleOf72Dialog(context),
                ),
                const Divider(color: Colors.white12, height: 24),
                _buildQuickToolTile(
                  icon: '📊',
                  title: context.l10n.investmentComparator,
                  subtitle: context.l10n.investmentComparatorDesc,
                  onTap: () => _showInvestmentComparator(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickToolTile({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AuraColors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AuraColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: AuraColors.textSecondary,
          ),
        ],
      ),
    );
  }

  void _navigateToCalculator(BuildContext context, CalculatorType type) {
    switch (type) {
      case CalculatorType.mortgage:
        context.push('/calculators/mortgage');
        break;
      case CalculatorType.compoundInterest:
        context.push('/calculators/compound');
        break;
      case CalculatorType.roi:
        context.push('/calculators/roi');
        break;
      case CalculatorType.currency:
        context.push('/calculators/currency');
        break;
    }
  }

  void _showRuleOf72Dialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const RuleOf72BottomSheet(),
    );
  }

  void _showInvestmentComparator(BuildContext context) {
    // TODO: Navigate to investment comparator
    HapticService.mediumTap();
  }
}

/// Bottom sheet pour la règle des 72
class RuleOf72BottomSheet extends StatefulWidget {
  const RuleOf72BottomSheet({super.key});

  @override
  State<RuleOf72BottomSheet> createState() => _RuleOf72BottomSheetState();
}

class _RuleOf72BottomSheetState extends State<RuleOf72BottomSheet> {
  double _rate = 7.0;

  @override
  Widget build(BuildContext context) {
    final years = 72 / _rate;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AuraColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '⏱️ ${context.l10n.ruleOf72}',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.timeToDouble,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AuraColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            '${_rate.toStringAsFixed(1)}%',
            style: GoogleFonts.dmSans(
              fontSize: 48,
              fontWeight: FontWeight.w300,
              color: AuraColors.amber,
            ),
          ),
          Slider(
            value: _rate,
            min: 1,
            max: 15,
            divisions: 28,
            activeColor: AuraColors.amber,
            inactiveColor: Colors.white12,
            onChanged: (value) => setState(() => _rate = value),
          ),
          const SizedBox(height: 24),
          GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  years.toStringAsFixed(1),
                  style: GoogleFonts.dmSans(
                    fontSize: 56,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                  ),
                ),
                Text(
                  context.l10n.yearsToDouble,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    color: AuraColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Sliver pour le staggered animator
class SliverStaggeredAnimator extends StatelessWidget {
  final List<Widget> children;
  final Duration staggerDelay;

  const SliverStaggeredAnimator({
    super.key,
    required this.children,
    required this.staggerDelay,
  });

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            child: children[index],
          );
        },
        childCount: children.length,
      ),
    );
  }
}
