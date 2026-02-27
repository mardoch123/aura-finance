import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;
import '../models/wealth_models.dart';

class WealthRepository {
  final SupabaseClient _supabase;

  WealthRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  /// Récupérer la vue d'ensemble du patrimoine
  Future<WealthOverview> getWealthOverview() async {
    final userId = _userId;
    if (userId == null) throw Exception('Non authentifié');

    // Récupérer tous les comptes
    final accountsResponse = await _supabase
        .from('wealth_accounts')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('display_order');

    final accounts = (accountsResponse as List)
        .map((e) => WealthAccount.fromJson(e))
        .toList();

    // Calculer les totaux
    final totalWealth = accounts.fold<double>(
      0,
      (sum, a) => sum + a.currentValue,
    );
    final totalInvested = accounts.fold<double>(
      0,
      (sum, a) => sum + a.investedAmount,
    );
    final totalPerformance = totalWealth - totalInvested;
    final totalPerformancePercent = totalInvested > 0
        ? (totalPerformance / totalInvested) * 100
        : 0;

    // Allocation par type
    final allocationByType = <String, double>{};
    for (final account in accounts) {
      allocationByType[account.accountType] =
          (allocationByType[account.accountType] ?? 0) + account.currentValue;
    }

    // Allocation en pourcentage
    final allocationByTypePercent = <String, double>{};
    for (final entry in allocationByType.entries) {
      allocationByTypePercent[entry.key] = totalWealth > 0
          ? (entry.value / totalWealth) * 100
          : 0;
    }

    // Alertes actives
    final alertsResponse = await _supabase
        .from('portfolio_alerts')
        .select()
        .eq('user_id', userId)
        .eq('is_read', false)
        .eq('is_dismissed', false)
        .order('created_at', ascending: false);

    final alerts = (alertsResponse as List)
        .map((e) => PortfolioAlert.fromJson(e))
        .toList();

    // Objectifs
    final goalsResponse = await _supabase
        .from('investment_goals')
        .select()
        .eq('user_id', userId)
        .order('target_date', ascending: true);

    final goals = (goalsResponse as List)
        .map((e) => InvestmentGoal.fromJson(e))
        .toList();

    // Projection retraite
    final projectionResponse = await _supabase
        .from('retirement_projections')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    final projection = projectionResponse != null
        ? RetirementProjection.fromJson(projectionResponse)
        : null;

    return WealthOverview(
      totalWealth: totalWealth,
      totalInvested: totalInvested,
      totalPerformance: totalPerformance,
      totalPerformancePercent: totalPerformancePercent,
      accounts: accounts,
      allocationByType: allocationByType,
      allocationByTypePercent: allocationByTypePercent,
      activeAlerts: alerts,
      goals: goals,
      retirementProjection: projection,
    );
  }

  /// Créer un compte patrimonial
  Future<WealthAccount> createAccount({
    required String name,
    required String accountType,
    String? institution,
    double initialValue = 0,
    double investedAmount = 0,
    Map<String, dynamic>? details,
    int? targetAllocationPercent,
    String color = '#E8A86C',
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Non authentifié');

    final response = await _supabase
        .from('wealth_accounts')
        .insert({
          'user_id': userId,
          'name': name,
          'account_type': accountType,
          'institution': institution,
          'current_value': initialValue,
          'invested_amount': investedAmount,
          'details': details,
          'target_allocation_percent': targetAllocationPercent,
          'color': color,
        })
        .select()
        .single();

    return WealthAccount.fromJson(response);
  }

  /// Mettre à jour la valeur d'un compte
  Future<void> updateAccountValue(String accountId, double newValue) async {
    final userId = _userId;
    if (userId == null) return;

    await _supabase
        .from('wealth_accounts')
        .update({
          'current_value': newValue,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', accountId)
        .eq('user_id', userId);

    // Enregistrer dans l'historique
    await _supabase.from('wealth_valuations').insert({
      'wealth_account_id': accountId,
      'user_id': userId,
      'value': newValue,
      'valuation_date': DateTime.now().toIso8601String(),
      'source': 'manual',
    });
  }

  /// Récupérer l'historique d'un compte
  Future<List<WealthValuation>> getAccountHistory(
    String accountId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _supabase
        .from('wealth_valuations')
        .select()
        .eq('wealth_account_id', accountId)
        .order('valuation_date', ascending: true);

    if (startDate != null) {
      query = query.gte('valuation_date', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('valuation_date', endDate.toIso8601String());
    }

    final response = await query;

    return (response as List)
        .map((e) => WealthValuation.fromJson(e))
        .toList();
  }

  /// Calculer la projection de retraite
  Future<Map<String, RetirementScenario>> calculateRetirementProjection({
    required int currentAge,
    int retirementAge = 65,
    double? monthlySavings,
    double? desiredPension,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Non authentifié');

    // Récupérer le patrimoine actuel
    final overview = await getWealthOverview();
    final currentWealth = overview.totalWealth;

    final yearsToRetirement = retirementAge - currentAge;
    if (yearsToRetirement <= 0) {
      return {};
    }

    // Scénarios
    final scenarios = <String, RetirementScenario>{};

    // Optimiste (6%)
    final optimisticWealth = currentWealth * _compoundFactor(0.06, yearsToRetirement) +
        (monthlySavings ?? 500) * 12 * _annuityFactor(0.06, yearsToRetirement);
    scenarios['optimistic'] = RetirementScenario(
      name: 'optimistic',
      label: 'Optimiste',
      returnRate: 0.06,
      projectedWealth: optimisticWealth,
      monthlyPension: optimisticWealth * 0.04 / 12,
      gap: (desiredPension ?? 3000) - (optimisticWealth * 0.04 / 12),
    );

    // Réaliste (4%)
    final realisticWealth = currentWealth * _compoundFactor(0.04, yearsToRetirement) +
        (monthlySavings ?? 500) * 12 * _annuityFactor(0.04, yearsToRetirement);
    scenarios['realistic'] = RetirementScenario(
      name: 'realistic',
      label: 'Réaliste',
      returnRate: 0.04,
      projectedWealth: realisticWealth,
      monthlyPension: realisticWealth * 0.04 / 12,
      gap: (desiredPension ?? 3000) - (realisticWealth * 0.04 / 12),
    );

    // Prudent (2%)
    final pessimisticWealth = currentWealth * _compoundFactor(0.02, yearsToRetirement) +
        (monthlySavings ?? 500) * 12 * _annuityFactor(0.02, yearsToRetirement);
    scenarios['pessimistic'] = RetirementScenario(
      name: 'pessimistic',
      label: 'Prudent',
      returnRate: 0.02,
      projectedWealth: pessimisticWealth,
      monthlyPension: pessimisticWealth * 0.04 / 12,
      gap: (desiredPension ?? 3000) - (pessimisticWealth * 0.04 / 12),
    );

    // Sauvegarder la projection
    await _supabase.from('retirement_projections').upsert({
      'user_id': userId,
      'current_age': currentAge,
      'retirement_age': retirementAge,
      'current_wealth': currentWealth,
      'desired_monthly_pension': desiredPension ?? 3000,
      'projected_wealth_at_retirement': realisticWealth,
      'projected_monthly_pension': realisticWealth * 0.04 / 12,
      'pension_gap': (desiredPension ?? 3000) - (realisticWealth * 0.04 / 12),
      'scenarios': {
        'optimistic': {
          'return_rate': 0.06,
          'projected_wealth': optimisticWealth,
        },
        'realistic': {
          'return_rate': 0.04,
          'projected_wealth': realisticWealth,
        },
        'pessimistic': {
          'return_rate': 0.02,
          'projected_wealth': pessimisticWealth,
        },
      },
      'recommended_monthly_savings': monthlySavings ?? 500,
    });

    return scenarios;
  }

  double _compoundFactor(double rate, int years) {
    return (1 + rate).toDouble() * years;
  }

  double _annuityFactor(double rate, int years) {
    if (rate == 0) return years.toDouble();
    return ((1 + rate).toDouble() * years - 1) / rate;
  }

  /// Créer une simulation de succession
  Future<SuccessionSimulation> createSuccessionSimulation({
    required String name,
    String? maritalStatus,
    bool hasChildren = false,
    int childrenCount = 0,
    required Map<String, double> assetsBreakdown,
    double totalLiabilities = 0,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Non authentifié');

    final totalAssets = assetsBreakdown.values.fold<double>(0, (a, b) => a + b);
    final netEstate = totalAssets - totalLiabilities;

    // Calcul simplifié des droits de succession
    final estimatedDuties = _calculateSuccessionDuties(
      netEstate: netEstate,
      maritalStatus: maritalStatus,
      hasChildren: hasChildren,
      childrenCount: childrenCount,
    );

    final heirsDistribution = _calculateHeirsDistribution(
      netEstate: netEstate,
      estimatedDuties: estimatedDuties,
      maritalStatus: maritalStatus,
      hasChildren: hasChildren,
      childrenCount: childrenCount,
    );

    final response = await _supabase
        .from('succession_simulations')
        .insert({
          'user_id': userId,
          'name': name,
          'marital_status': maritalStatus,
          'has_children': hasChildren,
          'children_count': childrenCount,
          'total_assets': totalAssets,
          'assets_breakdown': assetsBreakdown,
          'total_liabilities': totalLiabilities,
          'estimated_duties': estimatedDuties,
          'net_heritage': netEstate - estimatedDuties,
          'heirs_distribution': heirsDistribution,
        })
        .select()
        .single();

    return SuccessionSimulation.fromJson(response);
  }

  double _calculateSuccessionDuties({
    required double netEstate,
    required String? maritalStatus,
    required bool hasChildren,
    required int childrenCount,
  }) {
    // Simplification : abattement et barème progressif
    var abatement = 0.0;
    
    if (maritalStatus == 'married' || maritalStatus == 'pacs') {
      abatement += 805724; // Abattement conjoint 2024
    }
    
    if (hasChildren) {
      abatement += 159325 * childrenCount; // Abattement par enfant
    }

    final taxable = math.max(0, netEstate - abatement);
    
    // Barème simplifié
    if (taxable <= 8072) return taxable * 0.05;
    if (taxable <= 12109) return 8072 * 0.05 + (taxable - 8072) * 0.10;
    if (taxable <= 15932) return 8072 * 0.05 + (12109 - 8072) * 0.10 + (taxable - 12109) * 0.15;
    if (taxable <= 552324) {
      return 8072 * 0.05 + (12109 - 8072) * 0.10 + (15932 - 12109) * 0.15 + 
             (taxable - 15932) * 0.20;
    }
    if (taxable <= 902838) {
      return 8072 * 0.05 + (12109 - 8072) * 0.10 + (15932 - 12109) * 0.15 + 
             (552324 - 15932) * 0.20 + (taxable - 552324) * 0.30;
    }
    if (taxable <= 1805677) {
      return 8072 * 0.05 + (12109 - 8072) * 0.10 + (15932 - 12109) * 0.15 + 
             (552324 - 15932) * 0.20 + (902838 - 552324) * 0.30 + (taxable - 902838) * 0.40;
    }
    return 8072 * 0.05 + (12109 - 8072) * 0.10 + (15932 - 12109) * 0.15 + 
           (552324 - 15932) * 0.20 + (902838 - 552324) * 0.30 + (1805677 - 902838) * 0.40 +
           (taxable - 1805677) * 0.45;
  }

  List<Map<String, dynamic>> _calculateHeirsDistribution({
    required double netEstate,
    required double estimatedDuties,
    required String? maritalStatus,
    required bool hasChildren,
    required int childrenCount,
  }) {
    final distribution = <Map<String, dynamic>>[];
    final netHeritage = netEstate - estimatedDuties;

    if (maritalStatus == 'married' || maritalStatus == 'pacs') {
      if (hasChildren && childrenCount > 0) {
        // Réserve héréditaire : 3/4 aux enfants, 1/4 au conjoint
        final childrenShare = netHeritage * 0.75 / childrenCount;
        for (var i = 0; i < childrenCount; i++) {
          distribution.add({
            'heir': 'Enfant ${i + 1}',
            'share_percent': (75 / childrenCount).round(),
            'amount': childrenShare,
            'duties': estimatedDuties / childrenCount,
          });
        }
        distribution.add({
          'heir': 'Conjoint',
          'share_percent': 25,
          'amount': netHeritage * 0.25,
          'duties': 0, // Exonéré
        });
      } else {
        distribution.add({
          'heir': 'Conjoint',
          'share_percent': 100,
          'amount': netHeritage,
          'duties': 0,
        });
      }
    } else if (hasChildren && childrenCount > 0) {
      final childrenShare = netHeritage / childrenCount;
      for (var i = 0; i < childrenCount; i++) {
        distribution.add({
          'heir': 'Enfant ${i + 1}',
          'share_percent': (100 / childrenCount).round(),
          'amount': childrenShare,
          'duties': estimatedDuties / childrenCount,
        });
      }
    }

    return distribution;
  }

  /// Récupérer les simulations de succession
  Future<List<SuccessionSimulation>> getSuccessionSimulations() async {
    final userId = _userId;
    if (userId == null) return [];

    final response = await _supabase
        .from('succession_simulations')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => SuccessionSimulation.fromJson(e))
        .toList();
  }

  /// Marquer une alerte comme lue
  Future<void> markAlertAsRead(String alertId) async {
    await _supabase
        .from('portfolio_alerts')
        .update({'is_read': true})
        .eq('id', alertId);
  }

  /// Ignorer une alerte
  Future<void> dismissAlert(String alertId) async {
    await _supabase
        .from('portfolio_alerts')
        .update({
          'is_dismissed': true,
          'dismissed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', alertId);
  }

  /// Créer un objectif d'investissement
  Future<InvestmentGoal> createGoal({
    required String name,
    required String goalType,
    required double targetAmount,
    double currentAmount = 0,
    DateTime? targetDate,
    String? strategy,
    String color = '#E8A86C',
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Non authentifié');

    final response = await _supabase
        .from('investment_goals')
        .insert({
          'user_id': userId,
          'name': name,
          'goal_type': goalType,
          'target_amount': targetAmount,
          'current_amount': currentAmount,
          'target_date': targetDate?.toIso8601String(),
          'strategy': strategy,
          'color': color,
        })
        .select()
        .single();

    return InvestmentGoal.fromJson(response);
  }
}