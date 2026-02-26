import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../onboarding_controller.dart';

/// Slide 1: Revenu mensuel
/// Clavier numérique custom avec style Apple
class IncomeSlide extends ConsumerStatefulWidget {
  const IncomeSlide({super.key});

  @override
  ConsumerState<IncomeSlide> createState() => _IncomeSlideState();
}

class _IncomeSlideState extends ConsumerState<IncomeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _colorController;
  String _displayValue = '';

  @override
  void initState() {
    super.initState();
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    // Initialise avec la valeur existante
    final currentIncome = ref.read(onboardingNotifierProvider).monthlyIncome;
    if (currentIncome > 0) {
      _displayValue = currentIncome.toInt().toString();
    }
  }

  @override
  void dispose() {
    _colorController.dispose();
    super.dispose();
  }

  void _onNumberPressed(String number) {
    HapticService.lightTap();
    if (_displayValue.length < 6) {
      setState(() {
        _displayValue += number;
      });
      _updateIncome();
    }
  }

  void _onBackspace() {
    HapticService.lightTap();
    if (_displayValue.isNotEmpty) {
      setState(() {
        _displayValue = _displayValue.substring(0, _displayValue.length - 1);
      });
      _updateIncome();
    }
  }

  void _updateIncome() {
    final value = _displayValue.isEmpty ? 0.0 : double.parse(_displayValue);
    ref.read(onboardingNotifierProvider.notifier).updateMonthlyIncome(value);
    
    // Anime la couleur de fond selon le montant
    if (value > 0) {
      final progress = (value / 10000).clamp(0.0, 1.0);
      _colorController.animateTo(progress);
    }
  }

  Color _getBackgroundColor() {
    final income = ref.watch(onboardingNotifierProvider).monthlyIncome;
    if (income < 1500) {
      return AuraColors.auraAmber;
    } else if (income < 3000) {
      return Color.lerp(
        AuraColors.auraAmber,
        AuraColors.auraGreen,
        (income - 1500) / 1500,
      )!;
    } else if (income < 5000) {
      return AuraColors.auraGreen;
    } else {
      return Color.lerp(
        AuraColors.auraGreen,
        AuraColors.auraAccentGold,
        ((income - 5000) / 5000).clamp(0.0, 1.0),
      )!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final income = ref.watch(onboardingNotifierProvider).monthlyIncome;
    final backgroundColor = _getBackgroundColor();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AuraDimensions.spaceXL,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Titre
          Text(
            'Quel est votre revenu mensuel net ?',
            style: AuraTypography.h2.copyWith(
              color: AuraColors.auraTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AuraDimensions.spaceXL),
          
          // Affichage du montant avec animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(
              horizontal: AuraDimensions.spaceXL,
              vertical: AuraDimensions.spaceL,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  backgroundColor.withOpacity(0.3),
                  backgroundColor.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AuraDimensions.radiusXL),
              border: Border.all(
                color: AuraColors.auraTextPrimary.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  income > 0 ? income.toStringAsFixed(0) : '0',
                  style: AuraTypography.hero.copyWith(
                    color: AuraColors.auraTextPrimary,
                    fontSize: 56,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(width: AuraDimensions.spaceS),
                Text(
                  '€',
                  style: AuraTypography.h1.copyWith(
                    color: AuraColors.auraTextPrimary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AuraDimensions.spaceXXL),
          
          // Clavier numérique custom
          GlassCard(
            borderRadius: AuraDimensions.radiusL,
            padding: const EdgeInsets.all(AuraDimensions.spaceM),
            child: Column(
              children: [
                _buildKeypadRow(['1', '2', '3']),
                const SizedBox(height: AuraDimensions.spaceM),
                _buildKeypadRow(['4', '5', '6']),
                const SizedBox(height: AuraDimensions.spaceM),
                _buildKeypadRow(['7', '8', '9']),
                const SizedBox(height: AuraDimensions.spaceM),
                _buildKeypadRow(['', '0', 'backspace'], isLastRow: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys, {bool isLastRow = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        if (key.isEmpty) {
          return const SizedBox(width: 72, height: 72);
        }
        if (key == 'backspace') {
          return _buildKeypadButton(
            icon: Icons.backspace_outlined,
            onPressed: _onBackspace,
          );
        }
        return _buildKeypadButton(
          label: key,
          onPressed: () => _onNumberPressed(key),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton({
    String? label,
    IconData? icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AuraColors.auraTextPrimary.withOpacity(0.1),
          border: Border.all(
            color: AuraColors.auraTextPrimary.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: label != null
              ? Text(
                  label,
                  style: AuraTypography.h2.copyWith(
                    color: AuraColors.auraTextPrimary,
                    fontWeight: FontWeight.w400,
                  ),
                )
              : Icon(
                  icon,
                  color: AuraColors.auraTextPrimary.withOpacity(0.7),
                  size: 28,
                ),
        ),
      ),
    );
  }
}
