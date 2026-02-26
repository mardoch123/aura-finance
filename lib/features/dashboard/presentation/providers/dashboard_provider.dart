import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/dashboard_models.dart';

part 'dashboard_provider.g.dart';

/// Provider pour l'état du dashboard
@riverpod
class DashboardNotifier extends _$DashboardNotifier {
  @override
  Future<DashboardState> build() async {
    return _loadDashboardData();
  }

  Future<DashboardState> _loadDashboardData() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      return const DashboardState(error: 'Utilisateur non connecté');
    }

    try {
      // Chargement parallèle des données
      final results = await Future.wait([
        _loadAccounts(supabase, userId),
        _loadRecentTransactions(supabase, userId),
        _loadUnreadInsights(supabase, userId),
        _loadBudgetGoals(supabase, userId),
        _loadPrediction(supabase, userId),
      ]);

      final accounts = results[0] as List<DashboardAccount>;
      final transactions = results[1] as List<DashboardTransaction>;
      final insights = results[2] as List<AiInsight>;
      final goals = results[3] as List<BudgetGoal>;
      final prediction = results[4] as PredictionResult?;

      // Calcul du solde total
      final totalBalance = accounts.fold<double>(
        0,
        (sum, account) => sum + account.balance,
      );

      // Calcul du delta mensuel (simplifié)
      final monthlyDelta = transactions
          .where((t) => t.date.isAfter(DateTime.now().subtract(const Duration(days: 30))))
          .fold<double>(0, (sum, t) => sum + t.amount);

      return DashboardState(
        accounts: accounts,
        totalBalance: totalBalance,
        monthlyDelta: monthlyDelta,
        recentTransactions: transactions,
        unreadInsights: insights,
        prediction: prediction,
        budgetGoals: goals,
        isLoading: false,
      );
    } catch (e) {
      return DashboardState(
        error: 'Erreur de chargement: $e',
        isLoading: false,
      );
    }
  }

  Future<List<DashboardAccount>> _loadAccounts(
    SupabaseClient supabase,
    String userId,
  ) async {
    final response = await supabase
        .from('accounts')
        .select()
        .eq('user_id', userId)
        .order('is_primary', ascending: false);

    return (response as List)
        .map((json) => DashboardAccount(
              id: json['id'] as String,
              name: json['name'] as String,
              type: json['type'] as String,
              balance: (json['balance'] as num).toDouble(),
              color: json['color'] as String?,
              isPrimary: json['is_primary'] as bool? ?? false,
            ))
        .toList();
  }

  Future<List<DashboardTransaction>> _loadRecentTransactions(
    SupabaseClient supabase,
    String userId,
  ) async {
    final response = await supabase
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false)
        .limit(5);

    return (response as List)
        .map((json) => DashboardTransaction(
              id: json['id'] as String,
              amount: (json['amount'] as num).toDouble(),
              category: json['category'] as String? ?? 'other',
              subcategory: json['subcategory'] as String?,
              merchant: json['merchant'] as String?,
              description: json['description'] as String?,
              date: DateTime.parse(json['date'] as String),
              source: json['source'] as String? ?? 'manual',
            ))
        .toList();
  }

  Future<List<AiInsight>> _loadUnreadInsights(
    SupabaseClient supabase,
    String userId,
  ) async {
    final response = await supabase
        .from('ai_insights')
        .select()
        .eq('user_id', userId)
        .eq('is_read', false)
        .order('priority', ascending: true)
        .order('created_at', ascending: false)
        .limit(10);

    return (response as List)
        .map((json) => AiInsight(
              id: json['id'] as String,
              type: json['type'] as String,
              title: json['title'] as String,
              body: json['body'] as String,
              data: json['data'] as Map<String, dynamic>?,
              priority: json['priority'] as int? ?? 5,
              isRead: json['is_read'] as bool? ?? false,
              expiresAt: json['expires_at'] != null
                  ? DateTime.parse(json['expires_at'] as String)
                  : null,
              createdAt: DateTime.parse(json['created_at'] as String),
            ))
        .toList();
  }

  Future<List<BudgetGoal>> _loadBudgetGoals(
    SupabaseClient supabase,
    String userId,
  ) async {
    final response = await supabase
        .from('budget_goals')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(3);

    return (response as List)
        .map((json) => BudgetGoal(
              id: json['id'] as String,
              name: json['name'] as String,
              targetAmount: json['target_amount'] != null
                  ? (json['target_amount'] as num).toDouble()
                  : null,
              currentAmount: (json['current_amount'] as num? ?? 0).toDouble(),
              category: json['category'] as String?,
              deadline: json['deadline'] != null
                  ? DateTime.parse(json['deadline'] as String)
                  : null,
              color: json['color'] as String?,
              icon: json['icon'] as String?,
              createdAt: DateTime.parse(json['created_at'] as String),
            ))
        .toList();
  }

  Future<PredictionResult?> _loadPrediction(
    SupabaseClient supabase,
    String userId,
  ) async {
    try {
      // Appel de la Edge Function pour la prédiction
      final response = await supabase.functions.invoke(
        'predict-balance',
        body: {
          'userId': userId,
          'daysAhead': 30,
        },
      );

      if (response.status != 200) {
        return null;
      }

      final data = response.data as Map<String, dynamic>;
      final points = (data['points'] as List)
          .map((p) => BalancePredictionPoint(
                date: DateTime.parse(p['date'] as String),
                predictedBalance: (p['predictedBalance'] as num).toDouble(),
                events: (p['events'] as List? ?? [])
                    .map((e) => PredictionEvent(
                          type: e['type'] as String,
                          name: e['name'] as String,
                          amount: (e['amount'] as num).toDouble(),
                          category: e['category'] as String?,
                        ))
                    .toList(),
              ))
          .toList();

      return PredictionResult(
        points: points,
        currentBalance: (data['currentBalance'] as num).toDouble(),
        warnings: (data['warnings'] as List? ?? []).cast<String>(),
        criticalDate: data['criticalDate'] != null
            ? DateTime.parse(data['criticalDate'] as String)
            : null,
        lowestBalance: data['lowestBalance'] != null
            ? (data['lowestBalance'] as num).toDouble()
            : null,
      );
    } catch (e) {
      // Si la fonction n'existe pas encore, retourner des données mockées
      return _generateMockPrediction(userId);
    }
  }

  /// Génère des données de prédiction mockées pour le développement
  PredictionResult _generateMockPrediction(String userId) {
    final now = DateTime.now();
    final points = <BalancePredictionPoint>[];
    double currentBalance = 2450.0;

    for (int i = 0; i < 30; i++) {
      final date = now.add(Duration(days: i));
      
      // Simulation de variations
      if (i == 5) currentBalance -= 850; // Loyer
      if (i == 15) currentBalance += 2500; // Salaire
      if (i % 7 == 0) currentBalance -= 150; // Courses hebdo
      
      currentBalance -= 25 + (i * 2); // Dépenses quotidiennes croissantes

      final events = <PredictionEvent>[];
      if (i == 5) {
        events.add(const PredictionEvent(
          type: 'subscription',
          name: 'Loyer',
          amount: -850,
          category: 'housing',
        ));
      }
      if (i == 15) {
        events.add(const PredictionEvent(
          type: 'income',
          name: 'Salaire',
          amount: 2500,
          category: 'salary',
        ));
      }

      points.add(BalancePredictionPoint(
        date: date,
        predictedBalance: currentBalance,
        events: events,
      ));
    }

    final lowestPoint = points.reduce((a, b) =>
        a.predictedBalance < b.predictedBalance ? a : b);

    return PredictionResult(
      points: points,
      currentBalance: 2450.0,
      warnings: lowestPoint.predictedBalance < 0
          ? ['Risque de découvert détecté']
          : [],
      criticalDate: lowestPoint.predictedBalance < 0 ? lowestPoint.date : null,
      lowestBalance: lowestPoint.predictedBalance < 0 ? lowestPoint.predictedBalance : null,
    );
  }

  /// Rafraîchit les données du dashboard
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadDashboardData());
  }

  /// Marque un insight comme lu
  Future<void> markInsightAsRead(String insightId) async {
    final supabase = Supabase.instance.client;
    
    await supabase
        .from('ai_insights')
        .update({'is_read': true})
        .eq('id', insightId);

    // Met à jour l'état local
    state.whenData((currentState) {
      final updatedInsights = currentState.unreadInsights
          .where((i) => i.id != insightId)
          .toList();
      
      return currentState.copyWith(unreadInsights: updatedInsights);
    });
  }
}

/// Provider pour le nombre d'insights non lus (pour le badge)
@riverpod
Stream<int> unreadInsightsCount(UnreadInsightsCountRef ref) {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) return Stream.value(0);

  return supabase
      .from('ai_insights')
      .stream(primaryKey: ['id'])
      .map((data) => data
          .where((item) =>
              item['user_id'] == userId && item['is_read'] == false)
          .length);
}
