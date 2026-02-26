import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'dashboard_models.freezed.dart';
part 'dashboard_models.g.dart';

/// Point de prédiction du solde pour un jour donné
@freezed
class BalancePredictionPoint with _$BalancePredictionPoint {
  const factory BalancePredictionPoint({
    required DateTime date,
    required double predictedBalance,
    @Default([]) List<PredictionEvent> events,
  }) = _BalancePredictionPoint;

  factory BalancePredictionPoint.fromJson(Map<String, dynamic> json) =>
      _$BalancePredictionPointFromJson(json);
}

/// Événement prédit (abonnement, dépense récurrente, etc.)
@freezed
class PredictionEvent with _$PredictionEvent {
  const factory PredictionEvent({
    required String type, // 'subscription', 'income', 'expense'
    required String name,
    required double amount,
    String? category,
  }) = _PredictionEvent;

  factory PredictionEvent.fromJson(Map<String, dynamic> json) =>
      _$PredictionEventFromJson(json);
}

/// Résultat de prédition complète (30 jours)
@freezed
class PredictionResult with _$PredictionResult {
  const factory PredictionResult({
    required List<BalancePredictionPoint> points,
    required double currentBalance,
    @Default([]) List<String> warnings,
    DateTime? criticalDate,
    double? lowestBalance,
  }) = _PredictionResult;

  factory PredictionResult.fromJson(Map<String, dynamic> json) =>
      _$PredictionResultFromJson(json);
}

/// Insight IA généré pour l'utilisateur
@freezed
class AiInsight with _$AiInsight {
  const factory AiInsight({
    required String id,
    required String type, // 'prediction', 'alert', 'tip', 'vampire', 'achievement'
    required String title,
    required String body,
    Map<String, dynamic>? data,
    @Default(5) int priority,
    @Default(false) bool isRead,
    DateTime? expiresAt,
    required DateTime createdAt,
  }) = _AiInsight;

  factory AiInsight.fromJson(Map<String, dynamic> json) =>
      _$AiInsightFromJson(json);
}

/// Objectif budgétaire
@freezed
class BudgetGoal with _$BudgetGoal {
  const factory BudgetGoal({
    required String id,
    required String name,
    double? targetAmount,
    @Default(0) double currentAmount,
    String? category,
    DateTime? deadline,
    String? color,
    String? icon,
    required DateTime createdAt,
  }) = _BudgetGoal;

  factory BudgetGoal.fromJson(Map<String, dynamic> json) =>
      _$BudgetGoalFromJson(json);
}

/// Transaction simplifiée pour le dashboard
@freezed
class DashboardTransaction with _$DashboardTransaction {
  const factory DashboardTransaction({
    required String id,
    required double amount,
    required String category,
    String? subcategory,
    String? merchant,
    String? description,
    required DateTime date,
    required String source,
  }) = _DashboardTransaction;

  factory DashboardTransaction.fromJson(Map<String, dynamic> json) =>
      _$DashboardTransactionFromJson(json);
}

/// Compte simplifié pour le dashboard
@freezed
class DashboardAccount with _$DashboardAccount {
  const factory DashboardAccount({
    required String id,
    required String name,
    required String type,
    @Default(0) double balance,
    String? color,
    @Default(false) bool isPrimary,
  }) = _DashboardAccount;

  factory DashboardAccount.fromJson(Map<String, dynamic> json) =>
      _$DashboardAccountFromJson(json);
}

/// État complet du dashboard
@freezed
class DashboardState with _$DashboardState {
  const factory DashboardState({
    @Default([]) List<DashboardAccount> accounts,
    @Default(0) double totalBalance,
    @Default(0) double monthlyDelta,
    @Default([]) List<DashboardTransaction> recentTransactions,
    @Default([]) List<AiInsight> unreadInsights,
    PredictionResult? prediction,
    @Default([]) List<BudgetGoal> budgetGoals,
    @Default(false) bool isLoading,
    String? error,
  }) = _DashboardState;

  factory DashboardState.fromJson(Map<String, dynamic> json) =>
      _$DashboardStateFromJson(json);
}

/// Types d'insights
class InsightType {
  static const String prediction = 'prediction';
  static const String alert = 'alert';
  static const String tip = 'tip';
  static const String vampire = 'vampire';
  static const String achievement = 'achievement';
}

/// Catégories de transactions avec emojis
class TransactionCategories {
  static const Map<String, String> emojis = {
    'food': '🍽️',
    'transport': '🚗',
    'housing': '🏠',
    'entertainment': '🎬',
    'shopping': '🛍️',
    'health': '💊',
    'education': '📚',
    'utilities': '💡',
    'salary': '💰',
    'investment': '📈',
    'other': '📋',
  };

  static const Map<String, ColorInfo> colors = {
    'food': ColorInfo(light: 0xFFFFE4D1, dark: 0xFFE8A86C),
    'transport': ColorInfo(light: 0xFFD1E8FF, dark: 0xFF6C9EE8),
    'housing': ColorInfo(light: 0xFFE8D1FF, dark: 0xFFB86CE8),
    'entertainment': ColorInfo(light: 0xFFFFD1E8, dark: 0xFFE86CB8),
    'shopping': ColorInfo(light: 0xFFD1FFE8, dark: 0xFF6CE8A8),
    'health': ColorInfo(light: 0xFFFFD1D1, dark: 0xFFE86C6C),
    'education': ColorInfo(light: 0xFFFFF0D1, dark: 0xFFE8C06C),
    'utilities': ColorInfo(light: 0xFFD1F0FF, dark: 0xFF6CC4E8),
    'salary': ColorInfo(light: 0xFFD1FFD1, dark: 0xFF6CE86C),
    'investment': ColorInfo(light: 0xFFE8F0D1, dark: 0xFFA8C46C),
    'other': ColorInfo(light: 0xFFF0F0F0, dark: 0xFF999999),
  };

  static String getEmoji(String category) {
    return emojis[category.toLowerCase()] ?? '📋';
  }

  static ColorInfo getColors(String category) {
    return colors[category.toLowerCase()] ??
        const ColorInfo(light: 0xFFF0F0F0, dark: 0xFF999999);
  }
}

class ColorInfo {
  final int light;
  final int dark;

  const ColorInfo({required this.light, required this.dark});
}
