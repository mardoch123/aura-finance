import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../domain/onboarding_state.dart';
import '../onboarding_controller.dart';

/// Slide 4: Méthode de gestion du budget
/// 4 grandes cartes GlassCard sélectionnables
class BudgetMethodSlide extends ConsumerStatefulWidget {
  const BudgetMethodSlide({super.key});

  @override
  ConsumerState<BudgetMethodSlide> createState() => _BudgetMethodSlideState();
}

class _BudgetMethodSlideState extends ConsumerState<BudgetMethodSlide>
    with TickerProviderStateMixin {
  late List<AnimationController> _cardControllers;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;
  
  final List<String> _methodKeys = [
    BudgetMethods.none,
    BudgetMethods.spreadsheet,
    BudgetMethods.otherApp,
    BudgetMethods.envelopes,
  ];

  @override
  void initState() {
    super.initState();
    
    _cardControllers = List.generate(
      _methodKeys.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    
    _slideAnimations = _cardControllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutCubic,
        ),
      );
    }).toList();
    
    _fadeAnimations = _cardControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOut,
        ),
      );
    }).toList();
    
    _startAnimations();
  }

  Future<void> _startAnimations() async {
    for (var i = 0; i < _cardControllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (mounted) {
        _cardControllers[i].forward();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _selectMethod(String method) {
    HapticService.mediumTap();
    ref.read(onboardingNotifierProvider.notifier).selectBudgetMethod(method);
  }

  @override
  Widget build(BuildContext context) {
    final selectedMethod = ref.watch(onboardingNotifierProvider).currentBudgetMethod;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AuraDimensions.spaceXL,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Titre
          Text(
            'Comment gérez-vous votre budget actuellement ?',
            style: AuraTypography.h2.copyWith(
              color: AuraColors.auraTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AuraDimensions.spaceXXL),
          
          // Grille de 4 cartes
          ...List.generate(_methodKeys.length, (index) {
            final method = _methodKeys[index];
            final isSelected = selectedMethod == method;
            
            return AnimatedBuilder(
              animation: _cardControllers[index],
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimations[index],
                  child: SlideTransition(
                    position: _slideAnimations[index],
                    child: Padding(
                      padding: const EdgeInsets.only(
                        bottom: AuraDimensions.spaceM,
                      ),
                      child: _BudgetMethodCard(
                        method: method,
                        isSelected: isSelected,
                        onTap: () => _selectMethod(method),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

/// Carte de méthode de budget individuelle
class _BudgetMethodCard extends StatelessWidget {
  final String method;
  final bool isSelected;
  final VoidCallback onTap;

  const _BudgetMethodCard({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = BudgetMethods.labels[method] ?? method;
    final icon = BudgetMethods.icons[method] ?? '📊';
    final description = BudgetMethods.descriptions[method] ?? '';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.all(AuraDimensions.spaceL),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    AuraColors.auraAmber,
                    AuraColors.auraDeep,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : LinearGradient(
                  colors: [
                    AuraColors.auraGlass,
                    AuraColors.auraGlass.withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
          border: Border.all(
            color: isSelected
                ? AuraColors.auraAccentGold.withOpacity(0.8)
                : AuraColors.auraTextPrimary.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AuraColors.auraAmber.withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Icône
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AuraColors.auraTextPrimary.withOpacity(0.2)
                    : AuraColors.auraTextPrimary.withOpacity(0.1),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: AuraDimensions.spaceL),
            
            // Texte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AuraTypography.labelLarge.copyWith(
                      color: isSelected
                          ? AuraColors.auraTextPrimary
                          : AuraColors.auraTextPrimary.withOpacity(0.95),
                    ),
                  ),
                  const SizedBox(height: AuraDimensions.spaceXS),
                  Text(
                    description,
                    style: AuraTypography.bodySmall.copyWith(
                      color: isSelected
                          ? AuraColors.auraTextPrimary.withOpacity(0.8)
                          : AuraColors.auraTextPrimary.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            
            // Indicateur de sélection
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AuraColors.auraTextPrimary
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AuraColors.auraTextPrimary
                      : AuraColors.auraTextPrimary.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: AuraColors.auraAmber,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
