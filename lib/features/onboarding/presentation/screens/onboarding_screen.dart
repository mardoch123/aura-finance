import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/widgets/aura_button.dart';
import '../onboarding_controller.dart';
import '../widgets/onboarding_progress_bar.dart';
import '../slides/income_slide.dart';
import '../slides/goals_slide.dart';
import '../slides/subscriptions_slide.dart';
import '../slides/budget_method_slide.dart';
import '../slides/notifications_slide.dart';

/// Écran principal d'onboarding avec les 5 slides
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingNotifierProvider);
    final progress = ref.watch(onboardingProgressProvider);

    // Navigation vers le dashboard quand l'onboarding est complété
    ref.listen(onboardingNotifierProvider, (previous, next) {
      if (next.isCompleted && !previous!.isCompleted) {
        HapticService.success();
        context.goToDashboard();
      }
    });

    return Scaffold(
      backgroundColor: AuraColors.auraBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AuraColors.auraAmber,
              AuraColors.auraDeep,
              AuraColors.auraDark,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Barre de progression
              OnboardingProgressBar(progress: progress),
              
              // Contenu des slides
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.1, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _buildCurrentSlide(state.currentStep),
                ),
              ),
              
              // Boutons de navigation
              _buildNavigationButtons(context, ref, state),
              
              const SizedBox(height: AuraDimensions.spaceXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentSlide(int step) {
    switch (step) {
      case 0:
        return const IncomeSlide(key: ValueKey('income'));
      case 1:
        return const GoalsSlide(key: ValueKey('goals'));
      case 2:
        return const SubscriptionsSlide(key: ValueKey('subscriptions'));
      case 3:
        return const BudgetMethodSlide(key: ValueKey('budget'));
      case 4:
        return const NotificationsSlide(key: ValueKey('notifications'));
      default:
        return const IncomeSlide(key: ValueKey('income'));
    }
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    WidgetRef ref,
    dynamic state,
  ) {
    final isLastStep = state.currentStep == 4;
    final canProceed = ref.read(onboardingNotifierProvider.notifier).isCurrentStepValid();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AuraDimensions.spaceXL,
      ),
      child: Row(
        children: [
          // Bouton retour (sauf à la première étape)
          if (state.currentStep > 0)
            AuraButton(
              onPressed: () {
                HapticService.lightTap();
                ref.read(onboardingNotifierProvider.notifier).previousStep();
              },
              variant: AuraButtonVariant.ghost,
              label: '',
              icon: Icons.arrow_back_rounded,
            )
          else
            const SizedBox(width: 56),
          
          const Spacer(),
          
          // Bouton continuer/terminer
          AuraButton(
            onPressed: state.isLoading
                ? null
                : canProceed
                    ? () async {
                        HapticService.lightTap();
                        if (isLastStep) {
                          await ref
                              .read(onboardingNotifierProvider.notifier)
                              .completeOnboarding();
                        } else {
                          await ref
                              .read(onboardingNotifierProvider.notifier)
                              .nextStep();
                        }
                      }
                    : null,
            label: isLastStep ? 'Terminer' : 'Continuer',
            icon: isLastStep ? Icons.check_rounded : Icons.arrow_forward_rounded,
            isLoading: state.isLoading,
          ),
        ],
      ),
    );
  }
}
