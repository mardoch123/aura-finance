import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../services/supabase_service.dart';
import '../data/onboarding_repository.dart';
import '../domain/onboarding_state.dart';

part 'onboarding_controller.g.dart';

/// Provider du repository d'onboarding
final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository();
});

/// Controller d'onboarding
@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  late final OnboardingRepository _repository;

  @override
  OnboardingState build() {
    _repository = ref.watch(onboardingRepositoryProvider);
    
    // Charge l'étape sauvegardée au démarrage
    _loadSavedStep();
    
    return const OnboardingState();
  }

  /// Charge l'étape sauvegardée
  Future<void> _loadSavedStep() async {
    final savedStep = await _repository.getCurrentStep();
    if (savedStep > 0) {
      state = state.copyWith(currentStep: savedStep);
    }
  }

  /// Passe à l'étape suivante
  Future<void> nextStep() async {
    final newStep = state.currentStep + 1;
    await _repository.saveCurrentStep(newStep);
    state = state.copyWith(currentStep: newStep, errorMessage: null);
  }

  /// Revient à l'étape précédente
  Future<void> previousStep() async {
    if (state.currentStep > 0) {
      final newStep = state.currentStep - 1;
      await _repository.saveCurrentStep(newStep);
      state = state.copyWith(currentStep: newStep, errorMessage: null);
    }
  }

  /// Va directement à une étape spécifique
  Future<void> goToStep(int step) async {
    await _repository.saveCurrentStep(step);
    state = state.copyWith(currentStep: step, errorMessage: null);
  }

  /// Met à jour le revenu mensuel
  void updateMonthlyIncome(double income) {
    state = state.copyWith(monthlyIncome: income);
  }

  /// Ajoute ou retire un objectif
  void toggleGoal(String goal) {
    final currentGoals = [...state.selectedGoals];
    if (currentGoals.contains(goal)) {
      currentGoals.remove(goal);
    } else {
      currentGoals.add(goal);
    }
    state = state.copyWith(selectedGoals: currentGoals);
  }

  /// Ajoute ou retire un abonnement
  void toggleSubscription(String subscription) {
    final currentSubs = [...state.selectedSubscriptions];
    if (currentSubs.contains(subscription)) {
      currentSubs.remove(subscription);
    } else {
      currentSubs.add(subscription);
    }
    state = state.copyWith(selectedSubscriptions: currentSubs);
  }

  /// Sélectionne la méthode de budget
  void selectBudgetMethod(String method) {
    state = state.copyWith(currentBudgetMethod: method);
  }

  /// Active/désactive les notifications
  void toggleNotifications() {
    state = state.copyWith(notificationsEnabled: !state.notificationsEnabled);
  }

  /// Vérifie si l'étape actuelle est valide
  bool isCurrentStepValid() {
    switch (state.currentStep) {
      case 0: // Revenu
        return state.monthlyIncome > 0;
      case 1: // Objectifs
        return state.selectedGoals.isNotEmpty;
      case 2: // Abonnements (optionnel)
        return true;
      case 3: // Méthode budget
        return state.currentBudgetMethod != null;
      case 4: // Notifications (optionnel)
        return true;
      default:
        return false;
    }
  }

  /// Complète l'onboarding
  Future<OnboardingResult> completeOnboarding() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final userId = SupabaseService.instance.currentUserId;
      if (userId == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Utilisateur non connecté',
        );
        return const OnboardingFailure('Utilisateur non connecté');
      }

      final result = await _repository.completeOnboarding(
        userId: userId,
        monthlyIncome: state.monthlyIncome,
        goals: state.selectedGoals,
        subscriptions: state.selectedSubscriptions,
        budgetMethod: state.currentBudgetMethod,
        notificationsEnabled: state.notificationsEnabled,
      );

      if (result is OnboardingSuccess) {
        state = state.copyWith(isLoading: false, isCompleted: true);
      } else if (result is OnboardingFailure) {
        state = state.copyWith(isLoading: false, errorMessage: result.message);
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return OnboardingFailure(e.toString());
    }
  }

  /// Réinitialise l'onboarding (pour tests)
  Future<void> reset() async {
    await _repository.resetOnboarding();
    state = const OnboardingState();
  }
}

/// Provider pour vérifier si l'onboarding est complété
@riverpod
Future<bool> isOnboardingCompleted(IsOnboardingCompletedRef ref) async {
  final repository = ref.watch(onboardingRepositoryProvider);
  return repository.isOnboardingCompleted();
}

/// Provider pour obtenir le nombre total d'étapes
final totalOnboardingStepsProvider = Provider<int>((ref) => 5);

/// Provider pour obtenir la progression (0.0 à 1.0)
final onboardingProgressProvider = Provider<double>((ref) {
  final state = ref.watch(onboardingNotifierProvider);
  final totalSteps = ref.watch(totalOnboardingStepsProvider);
  return (state.currentStep + 1) / totalSteps;
});
