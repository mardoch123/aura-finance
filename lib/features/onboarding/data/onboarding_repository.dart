import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';
import '../domain/onboarding_state.dart';

/// Repository pour la gestion de l'onboarding
class OnboardingRepository {
  final _supabase = SupabaseService.instance;
  static const String _onboardingStepKey = 'onboarding_step';
  static const String _onboardingCompletedKey = 'onboarding_completed';

  /// Vérifie si l'onboarding est complété
  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  /// Sauvegarde l'étape actuelle de l'onboarding
  Future<void> saveCurrentStep(int step) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_onboardingStepKey, step);
  }

  /// Récupère l'étape actuelle de l'onboarding
  Future<int> getCurrentStep() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_onboardingStepKey) ?? 0;
  }

  /// Marque l'onboarding comme complété
  Future<void> markOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
  }

  /// Réinitialise l'onboarding (pour tests)
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingStepKey);
    await prefs.remove(_onboardingCompletedKey);
  }

  /// Crée le profil utilisateur avec les données d'onboarding
  Future<void> createProfile({
    required String userId,
    required double monthlyIncome,
    required List<String> goals,
    required String? budgetMethod,
    required bool notificationsEnabled,
  }) async {
    final financialGoals = <String, dynamic>{};
    for (final goal in goals) {
      switch (goal) {
        case 'emergency':
          financialGoals['emergency_fund'] = monthlyIncome * 3;
          break;
        case 'save':
          financialGoals['monthly_savings'] = monthlyIncome * 0.2;
          break;
        case 'house':
          financialGoals['house_down_payment'] = 50000;
          break;
        case 'travel':
          financialGoals['vacation'] = 3000;
          break;
        case 'freedom':
          financialGoals['financial_independence'] = monthlyIncome * 12 * 25;
          break;
      }
    }

    await _supabase.profiles.upsert({
      'id': userId,
      'monthly_income': monthlyIncome,
      'financial_goals': financialGoals,
      'notification_prefs': {
        'enabled': notificationsEnabled,
        'vampire_alerts': true,
        'weekly_summary': true,
        'budget_alerts': true,
      },
      'onboarding_completed': true,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Crée les abonnements sélectionnés
  Future<void> createSubscriptions({
    required String userId,
    required List<String> subscriptionIds,
  }) async {
    final now = DateTime.now();
    
    for (final subId in subscriptionIds) {
      final amount = PopularSubscriptions.defaultAmounts[subId] ?? 9.99;
      final name = PopularSubscriptions.labels[subId] ?? 'Abonnement';
      
      await _supabase.subscriptions.insert({
        'user_id': userId,
        'name': name,
        'amount': amount,
        'billing_cycle': 'monthly',
        'next_billing_date': now.add(const Duration(days: 30)).toIso8601String(),
        'category': 'subscriptions',
        'merchant_pattern': name.toLowerCase(),
        'created_at': now.toIso8601String(),
      });
    }
  }

  /// Génère les premiers insights IA via Edge Function
  Future<void> generateInitialInsights(String userId) async {
    try {
      await _supabase.client.functions.invoke(
        'generate-onboarding-insights',
        body: {'user_id': userId},
      );
    } catch (e) {
      // Silently fail - insights can be generated later
      print('Failed to generate initial insights: $e');
    }
  }

  /// Complète l'onboarding en une seule transaction
  Future<OnboardingResult> completeOnboarding({
    required String userId,
    required double monthlyIncome,
    required List<String> goals,
    required List<String> subscriptions,
    required String? budgetMethod,
    required bool notificationsEnabled,
  }) async {
    try {
      // 1. Crée le profil
      await createProfile(
        userId: userId,
        monthlyIncome: monthlyIncome,
        goals: goals,
        budgetMethod: budgetMethod,
        notificationsEnabled: notificationsEnabled,
      );

      // 2. Crée les abonnements
      if (subscriptions.isNotEmpty) {
        await createSubscriptions(
          userId: userId,
          subscriptionIds: subscriptions,
        );
      }

      // 3. Marque comme complété
      await markOnboardingCompleted();

      // 4. Génère les insights initiaux (async, ne bloque pas)
      generateInitialInsights(userId);

      return const OnboardingSuccess();
    } on PostgrestException catch (e) {
      return OnboardingFailure(e.message);
    } catch (e) {
      return OnboardingFailure(e.toString());
    }
  }
}
