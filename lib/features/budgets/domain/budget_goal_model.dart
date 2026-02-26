import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget_goal_model.freezed.dart';
part 'budget_goal_model.g.dart';

/// Types d'objectifs budgétaires
enum GoalType {
  savings,
  spendingLimit,
  debtReduction,
  incomeTarget,
}

/// Extension pour les labels
extension GoalTypeExtension on GoalType {
  String get label {
    switch (this) {
      case GoalType.savings:
        return 'Épargne';
      case GoalType.spendingLimit:
        return 'Limite de dépenses';
      case GoalType.debtReduction:
        return 'Remboursement de dette';
      case GoalType.incomeTarget:
        return 'Objectif de revenus';
    }
  }

  String get icon {
    switch (this) {
      case GoalType.savings:
        return '🏦';
      case GoalType.spendingLimit:
        return '🛑';
      case GoalType.debtReduction:
        return '💳';
      case GoalType.incomeTarget:
        return '💰';
    }
  }
}

/// Modèle d'objectif budgétaire
@freezed
class BudgetGoal with _$BudgetGoal {
  const factory BudgetGoal({
    required String id,
    required String userId,
    required String name,
    String? description,
    required double targetAmount,
    @Default(0.0) double currentAmount,
    String? category,
    @Default(GoalType.savings) GoalType goalType,
    DateTime? deadline,
    @Default('#E8A86C') String color,
    @Default('savings') String icon,
    @Default(true) bool isActive,
    @Default(false) bool isRecurring,
    String? recurringPeriod,
    double? alertThreshold,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _BudgetGoal;

  factory BudgetGoal.fromJson(Map<String, dynamic> json) =>
      _$BudgetGoalFromJson(json);

  factory BudgetGoal.empty() => BudgetGoal(
        id: '',
        userId: '',
        name: '',
        targetAmount: 0.0,
        createdAt: DateTime.now(),
      );
}

/// Extension pour les propriétés calculées
extension BudgetGoalExtension on BudgetGoal {
  /// Pourcentage de progression
  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    return (currentAmount / targetAmount * 100).clamp(0.0, 100.0);
  }

  /// Montant restant
  double get remainingAmount => (targetAmount - currentAmount).clamp(0.0, double.infinity);

  /// Si l'objectif est atteint
  bool get isCompleted => currentAmount >= targetAmount;

  /// Si une alerte doit être déclenchée
  bool get isAlertTriggered {
    if (alertThreshold == null || targetAmount <= 0) return false;
    final percentage = currentAmount / targetAmount * 100;
    return percentage >= alertThreshold!;
  }

  /// Jours restants avant la deadline
  int? get daysRemaining {
    if (deadline == null) return null;
    return deadline!.difference(DateTime.now()).inDays;
  }

  /// Si la deadline est proche (moins de 7 jours)
  bool get isDeadlineNear {
    final days = daysRemaining;
    return days != null && days <= 7 && days >= 0;
  }

  /// Si la deadline est dépassée
  bool get isOverdue {
    final days = daysRemaining;
    return days != null && days < 0;
  }

  /// Couleur parsée
  int get colorValue {
    try {
      return int.parse(color.replaceFirst('#', '0xFF'));
    } catch (_) {
      return 0xFFE8A86C;
    }
  }
}

/// Résumé des objectifs
class GoalsSummary {
  final int totalGoals;
  final int completedGoals;
  final double totalTarget;
  final double totalCurrent;
  final double overallProgress;

  const GoalsSummary({
    required this.totalGoals,
    required this.completedGoals,
    required this.totalTarget,
    required this.totalCurrent,
    required this.overallProgress,
  });

  factory GoalsSummary.empty() => const GoalsSummary(
        totalGoals: 0,
        completedGoals: 0,
        totalTarget: 0.0,
        totalCurrent: 0.0,
        overallProgress: 0.0,
      );
}
