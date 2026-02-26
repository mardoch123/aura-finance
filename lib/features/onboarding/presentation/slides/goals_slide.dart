import 'dart:math' show pi, sin;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../domain/onboarding_state.dart';
import '../onboarding_controller.dart';

/// Slide 2: Objectifs financiers
/// Bulles flottantes avec sélection multi-choice
class GoalsSlide extends ConsumerStatefulWidget {
  const GoalsSlide({super.key});

  @override
  ConsumerState<GoalsSlide> createState() => _GoalsSlideState();
}

class _GoalsSlideState extends ConsumerState<GoalsSlide>
    with TickerProviderStateMixin {
  late List<AnimationController> _bubbleControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _bounceAnimations;
  
  final List<String> _goalKeys = [
    FinancialGoals.save,
    FinancialGoals.travel,
    FinancialGoals.debt,
    FinancialGoals.invest,
    FinancialGoals.retirement,
    FinancialGoals.house,
    FinancialGoals.emergency,
    FinancialGoals.freedom,
  ];

  @override
  void initState() {
    super.initState();
    
    // Crée les controllers pour chaque bulle avec un délai staggered
    _bubbleControllers = List.generate(
      _goalKeys.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    
    _scaleAnimations = _bubbleControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.elasticOut,
        ),
      );
    }).toList();
    
    _bounceAnimations = _bubbleControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
        ),
      );
    }).toList();
    
    // Démarre les animations avec un délai
    _startAnimations();
  }

  Future<void> _startAnimations() async {
    for (var i = 0; i < _bubbleControllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 40));
      if (mounted) {
        _bubbleControllers[i].forward();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _bubbleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleGoal(String goal) {
    HapticService.selection();
    ref.read(onboardingNotifierProvider.notifier).toggleGoal(goal);
  }

  @override
  Widget build(BuildContext context) {
    final selectedGoals = ref.watch(onboardingNotifierProvider).selectedGoals;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AuraDimensions.spaceXL,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Titre
          Text(
            'Quels sont vos objectifs ?',
            style: AuraTypography.h2.copyWith(
              color: AuraColors.auraTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AuraDimensions.spaceS),
          Text(
            'Sélectionnez ceux qui vous parlent',
            style: AuraTypography.bodyLarge.copyWith(
              color: AuraColors.auraTextPrimary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AuraDimensions.spaceXXL),
          
          // Grille de bulles
          Wrap(
            spacing: AuraDimensions.spaceM,
            runSpacing: AuraDimensions.spaceM,
            alignment: WrapAlignment.center,
            children: List.generate(_goalKeys.length, (index) {
              final goal = _goalKeys[index];
              final isSelected = selectedGoals.contains(goal);
              
              return AnimatedBuilder(
                animation: _bubbleControllers[index],
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimations[index].value,
                    child: Opacity(
                      opacity: _bounceAnimations[index].value,
                      child: _GoalBubble(
                        goal: goal,
                        isSelected: isSelected,
                        onTap: () => _toggleGoal(goal),
                        delay: index * 0.04,
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          
          const SizedBox(height: AuraDimensions.spaceXXL),
          
          // Compteur de sélection
          if (selectedGoals.isNotEmpty)
            Text(
              '${selectedGoals.length} objectif${selectedGoals.length > 1 ? 's' : ''} sélectionné${selectedGoals.length > 1 ? 's' : ''}',
              style: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.auraTextPrimary.withOpacity(0.6),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bulle d'objectif individuelle
class _GoalBubble extends StatefulWidget {
  final String goal;
  final bool isSelected;
  final VoidCallback onTap;
  final double delay;

  const _GoalBubble({
    required this.goal,
    required this.isSelected,
    required this.onTap,
    required this.delay,
  });

  @override
  State<_GoalBubble> createState() => _GoalBubbleState();
}

class _GoalBubbleState extends State<_GoalBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = FinancialGoals.labels[widget.goal] ?? widget.goal;
    final icon = FinancialGoals.icons[widget.goal] ?? '🎯';

    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final offset = sin(_floatController.value * 2 * pi + widget.delay * 10) * 3;
        
        return Transform.translate(
          offset: Offset(0, offset),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              padding: const EdgeInsets.symmetric(
                horizontal: AuraDimensions.spaceL,
                vertical: AuraDimensions.spaceM,
              ),
              decoration: BoxDecoration(
                gradient: widget.isSelected
                    ? const LinearGradient(
                        colors: [
                          AuraColors.auraAmber,
                          AuraColors.auraDeep,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          AuraColors.auraGlass,
                          AuraColors.auraGlass.withOpacity(0.5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(AuraDimensions.radiusXXL),
                border: Border.all(
                  color: widget.isSelected
                      ? AuraColors.auraAccentGold.withOpacity(0.8)
                      : AuraColors.auraTextPrimary.withOpacity(0.2),
                  width: widget.isSelected ? 2 : 1,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: AuraColors.auraAmber.withOpacity(0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              transform: widget.isSelected
                  ? (Matrix4.identity()..scale(1.05))
                  : Matrix4.identity(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: AuraDimensions.spaceS),
                  Text(
                    label,
                    style: AuraTypography.labelLarge.copyWith(
                      color: widget.isSelected
                          ? AuraColors.auraTextPrimary
                          : AuraColors.auraTextPrimary.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
