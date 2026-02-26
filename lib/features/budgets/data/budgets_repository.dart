import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';
import '../domain/budget_goal_model.dart';

/// Repository pour la gestion des objectifs budgétaires
class BudgetsRepository {
  final SupabaseClient _client;

  BudgetsRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.instance.client;

  /// Récupère tous les objectifs de l'utilisateur
  Future<List<BudgetGoal>> getGoals({bool activeOnly = true}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    var builder = _client
        .from('budget_goals')
        .select()
        .eq('user_id', userId);

    if (activeOnly) {
      builder = builder.eq('is_active', true);
    }

    final response = await builder.order('created_at', ascending: false);

    return (response as List).map((json) => BudgetGoal.fromJson(json)).toList();
  }

  /// Récupère un objectif par son ID
  Future<BudgetGoal?> getGoalById(String id) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    final response = await _client
        .from('budget_goals')
        .select()
        .eq('id', id)
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return BudgetGoal.fromJson(response);
  }

  /// Crée un nouvel objectif
  Future<BudgetGoal> createGoal({
    required String name,
    String? description,
    required double targetAmount,
    double initialAmount = 0.0,
    String? category,
    GoalType goalType = GoalType.savings,
    DateTime? deadline,
    String? color,
    String? icon,
    bool isRecurring = false,
    String? recurringPeriod,
    double? alertThreshold,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    final data = {
      'user_id': userId,
      'name': name,
      'description': description,
      'target_amount': targetAmount,
      'current_amount': initialAmount,
      'category': category,
      'goal_type': goalType.name,
      'deadline': deadline?.toIso8601String(),
      'color': color ?? '#E8A86C',
      'icon': icon ?? 'savings',
      'is_recurring': isRecurring,
      'recurring_period': recurringPeriod,
      'alert_threshold': alertThreshold,
    };

    final response = await _client
        .from('budget_goals')
        .insert(data)
        .select()
        .single();

    return BudgetGoal.fromJson(response);
  }

  /// Met à jour un objectif
  Future<BudgetGoal> updateGoal(
    String id, {
    String? name,
    String? description,
    double? targetAmount,
    double? currentAmount,
    String? category,
    GoalType? goalType,
    DateTime? deadline,
    String? color,
    String? icon,
    bool? isActive,
    bool? isRecurring,
    String? recurringPeriod,
    double? alertThreshold,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    final updates = <String, dynamic>{
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (targetAmount != null) 'target_amount': targetAmount,
      if (currentAmount != null) 'current_amount': currentAmount,
      if (category != null) 'category': category,
      if (goalType != null) 'goal_type': goalType.name,
      if (deadline != null) 'deadline': deadline.toIso8601String(),
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (isActive != null) 'is_active': isActive,
      if (isRecurring != null) 'is_recurring': isRecurring,
      if (recurringPeriod != null) 'recurring_period': recurringPeriod,
      if (alertThreshold != null) 'alert_threshold': alertThreshold,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _client
        .from('budget_goals')
        .update(updates)
        .eq('id', id)
        .eq('user_id', userId)
        .select()
        .single();

    return BudgetGoal.fromJson(response);
  }

  /// Ajoute un montant à l'objectif (pour l'épargne)
  Future<BudgetGoal> addToGoal(String id, double amount) async {
    final goal = await getGoalById(id);
    if (goal == null) throw Exception('Objectif non trouvé');

    return updateGoal(id, currentAmount: goal.currentAmount + amount);
  }

  /// Supprime (désactive) un objectif
  Future<void> deleteGoal(String id) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    await _client
        .from('budget_goals')
        .update({'is_active': false})
        .eq('id', id)
        .eq('user_id', userId);
  }

  /// Récupère les objectifs avec deadline proche
  Future<List<BudgetGoal>> getUpcomingDeadlines({int daysAhead = 30}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    final response = await _client.rpc(
      'get_upcoming_deadlines',
      params: {
        'user_uuid': userId,
        'days_ahead': daysAhead,
      },
    );

    if (response == null) return [];
    return (response as List).map((json) => BudgetGoal.fromJson(json)).toList();
  }

  /// Récupère les objectifs en alerte
  Future<List<BudgetGoal>> getBudgetAlerts() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    final response = await _client.rpc(
      'get_budget_alerts',
      params: {'user_uuid': userId},
    );

    if (response == null) return [];
    return (response as List).map((json) => BudgetGoal.fromJson(json)).toList();
  }

  /// Récupère la progression d'un objectif
  Future<double> getGoalProgress(String goalId) async {
    final response = await _client.rpc(
      'get_goal_progress',
      params: {'goal_uuid': goalId},
    );

    return (response as num?)?.toDouble() ?? 0.0;
  }
}
