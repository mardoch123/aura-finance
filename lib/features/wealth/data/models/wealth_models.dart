import 'package:freezed_annotation/freezed_annotation.dart';

part 'wealth_models.freezed.dart';
part 'wealth_models.g.dart';

/// Compte patrimonial (assurance vie, PEA, crypto, etc.)
@freezed
class WealthAccount with _$WealthAccount {
  const factory WealthAccount({
    required String id,
    required String userId,
    required String name,
    String? institution,
    required String accountType,
    @Default(0.0) double currentValue,
    @Default(0.0) double investedAmount,
    double? performanceEuro,
    double? performancePercent,
    Map<String, dynamic>? details,
    int? targetAllocationPercent,
    @Default('#E8A86C') String color,
    @Default(0) int displayOrder,
    @Default(true) bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _WealthAccount;

  factory WealthAccount.fromJson(Map<String, dynamic> json) =>
      _$WealthAccountFromJson(json);
}

/// Transaction patrimoniale
@freezed
class WealthTransaction with _$WealthTransaction {
  const factory WealthTransaction({
    required String id,
    required String wealthAccountId,
    required String userId,
    required String transactionType,
    required double amount,
    @Default('EUR') String currency,
    required DateTime transactionDate,
    String? description,
    Map<String, dynamic>? metadata,
    required DateTime createdAt,
  }) = _WealthTransaction;

  factory WealthTransaction.fromJson(Map<String, dynamic> json) =>
      _$WealthTransactionFromJson(json);
}

/// Valorisation historique
@freezed
class WealthValuation with _$WealthValuation {
  const factory WealthValuation({
    required String id,
    required String wealthAccountId,
    required String userId,
    required double value,
    required DateTime valuationDate,
    @Default('manual') String source,
  }) = _WealthValuation;

  factory WealthValuation.fromJson(Map<String, dynamic> json) =>
      _$WealthValuationFromJson(json);
}

/// Projection de retraite
@freezed
class RetirementProjection with _$RetirementProjection {
  const factory RetirementProjection({
    required String id,
    required String userId,
    required int currentAge,
    @Default(65) int retirementAge,
    @Default(90) int lifeExpectancy,
    double? currentMonthlyIncome,
    double? desiredMonthlyPension,
    @Default(0.0) double currentWealth,
    @Default(0.04) double annualReturnRate,
    @Default(0.02) double inflationRate,
    double? projectedWealthAtRetirement,
    double? projectedMonthlyPension,
    double? pensionGap,
    Map<String, dynamic>? scenarios,
    double? recommendedMonthlySavings,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _RetirementProjection;

  factory RetirementProjection.fromJson(Map<String, dynamic> json) =>
      _$RetirementProjectionFromJson(json);
}

/// Simulation de succession
@freezed
class SuccessionSimulation with _$SuccessionSimulation {
  const factory SuccessionSimulation({
    required String id,
    required String userId,
    required String name,
    String? maritalStatus,
    @Default(false) bool hasChildren,
    @Default(0) int childrenCount,
    @Default(0.0) double totalAssets,
    Map<String, dynamic>? assetsBreakdown,
    @Default(0.0) double totalLiabilities,
    double? netEstate,
    double? estimatedDuties,
    double? netHeritage,
    List<dynamic>? heirsDistribution,
    List<dynamic>? suggestedOptimizations,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SuccessionSimulation;

  factory SuccessionSimulation.fromJson(Map<String, dynamic> json) =>
      _$SuccessionSimulationFromJson(json);
}

/// Alerte de portefeuille
@freezed
class PortfolioAlert with _$PortfolioAlert {
  const factory PortfolioAlert({
    required String id,
    required String userId,
    required String alertType,
    @Default('info') String severity,
    required String title,
    required String description,
    Map<String, dynamic>? data,
    @Default(false) bool isRead,
    @Default(false) bool isDismissed,
    DateTime? dismissedAt,
    String? actionTaken,
    DateTime? actionTakenAt,
    required DateTime createdAt,
  }) = _PortfolioAlert;

  factory PortfolioAlert.fromJson(Map<String, dynamic> json) =>
      _$PortfolioAlertFromJson(json);
}

/// Objectif d'investissement
@freezed
class InvestmentGoal with _$InvestmentGoal {
  const factory InvestmentGoal({
    required String id,
    required String userId,
    required String name,
    required String goalType,
    required double targetAmount,
    @Default(0.0) double currentAmount,
    double? progressPercent,
    DateTime? targetDate,
    String? strategy,
    @Default('#E8A86C') String color,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _InvestmentGoal;

  factory InvestmentGoal.fromJson(Map<String, dynamic> json) =>
      _$InvestmentGoalFromJson(json);
}

/// Vue d'ensemble du patrimoine
@freezed
class WealthOverview with _$WealthOverview {
  const factory WealthOverview({
    required double totalWealth,
    required double totalInvested,
    required double totalPerformance,
    required double totalPerformancePercent,
    required List<WealthAccount> accounts,
    required Map<String, double> allocationByType,
    required Map<String, double> allocationByTypePercent,
    required List<PortfolioAlert> activeAlerts,
    required List<InvestmentGoal> goals,
    required RetirementProjection? retirementProjection,
  }) = _WealthOverview;

  factory WealthOverview.fromJson(Map<String, dynamic> json) =>
      _$WealthOverviewFromJson(json);
}

/// Types de comptes patrimoniaux
class WealthAccountType {
  static const String lifeInsurance = 'life_insurance';
  static const String pea = 'pea';
  static const String pep = 'pep';
  static const String crypto = 'crypto';
  static const String realEstate = 'real_estate';
  static const String stocks = 'stocks';
  static const String bonds = 'bonds';
  static const String savings = 'savings';
  static const String other = 'other';

  static String getLabel(String type) {
    return switch (type) {
      lifeInsurance => 'Assurance Vie',
      pea => 'PEA',
      pep => 'PEP',
      crypto => 'Crypto',
      realEstate => 'Immobilier',
      stocks => 'Compte-titres',
      bonds => 'Obligations',
      savings => 'Épargne',
      other => 'Autre',
      _ => type,
    };
  }

  static String getIcon(String type) {
    return switch (type) {
      lifeInsurance => 'shield',
      pea => 'trending_up',
      pep => 'savings',
      crypto => 'currency_bitcoin',
      realEstate => 'home',
      stocks => 'show_chart',
      bonds => 'account_balance',
      savings => 'savings',
      other => 'folder',
      _ => 'folder',
    };
  }
}

/// Types d'alertes
class PortfolioAlertType {
  static const String rebalancingNeeded = 'rebalancing_needed';
  static const String underperforming = 'underperforming';
  static const String concentrationRisk = 'concentration_risk';
  static const String opportunity = 'opportunity';
  static const String milestoneReached = 'milestone_reached';

  static String getLabel(String type) {
    return switch (type) {
      rebalancingNeeded => 'Rééquilibrage nécessaire',
      underperforming => 'Sous-performance',
      concentrationRisk => 'Risque de concentration',
      opportunity => 'Opportunité',
      milestoneReached => 'Jalon atteint',
      _ => type,
    };
  }
}

/// Scénarios de projection
class RetirementScenario {
  final String name;
  final String label;
  final double returnRate;
  final double projectedWealth;
  final double monthlyPension;
  final double gap;

  const RetirementScenario({
    required this.name,
    required this.label,
    required this.returnRate,
    required this.projectedWealth,
    required this.monthlyPension,
    required this.gap,
  });
}