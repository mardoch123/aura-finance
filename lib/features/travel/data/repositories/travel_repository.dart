import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/travel_models.dart';

class TravelRepository {
  final SupabaseClient _supabase;

  TravelRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  /// Récupérer les voyages de l'utilisateur
  Future<List<UserTrip>> getUserTrips() async {
    final userId = _userId;
    if (userId == null) return [];

    final response = await _supabase
        .from('user_trips')
        .select()
        .eq('user_id', userId)
        .order('start_date', ascending: false);

    return (response as List).map((e) => UserTrip.fromJson(e)).toList();
  }

  /// Récupérer les voyages actifs
  Future<List<UserTrip>> getActiveTrips() async {
    final userId = _userId;
    if (userId == null) return [];

    final response = await _supabase
        .from('user_trips')
        .select()
        .eq('user_id', userId)
        .eq('is_ongoing', true)
        .order('start_date', ascending: false);

    return (response as List).map((e) => UserTrip.fromJson(e)).toList();
  }

  /// Créer un nouveau voyage
  Future<UserTrip> createTrip({
    required String name,
    required String destinationCountry,
    String? destinationCity,
    required String destinationCurrency,
    required DateTime startDate,
    DateTime? endDate,
    double? totalBudget,
    bool isGroupTrip = false,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Non authentifié');

    // Calculer le budget quotidien
    double? dailyBudget;
    if (totalBudget != null && endDate != null) {
      final days = endDate.difference(startDate).inDays + 1;
      dailyBudget = totalBudget / days;
    }

    final response = await _supabase
        .from('user_trips')
        .insert({
          'user_id': userId,
          'name': name,
          'destination_country': destinationCountry,
          'destination_city': destinationCity,
          'destination_currency': destinationCurrency,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
          'total_budget': totalBudget,
          'daily_budget': dailyBudget,
          'is_group_trip': isGroupTrip,
          'is_ongoing': true,
          'status': 'active',
          'detection_source': 'manual',
        })
        .select()
        .single();

    return UserTrip.fromJson(response);
  }

  /// Mettre fin à un voyage
  Future<void> completeTrip(String tripId) async {
    final userId = _userId;
    if (userId == null) return;

    await _supabase
        .from('user_trips')
        .update({
          'is_ongoing': false,
          'status': 'completed',
          'end_date': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', tripId)
        .eq('user_id', userId);
  }

  /// Récupérer les membres d'un voyage
  Future<List<TripMember>> getTripMembers(String tripId) async {
    final response = await _supabase
        .from('trip_members')
        .select('*, user:user_id(full_name, avatar_url)')
        .eq('trip_id', tripId)
        .order('joined_at', ascending: true);

    return (response as List).map((e) {
      final userData = e['user'] as Map<String, dynamic>?;
      return TripMember.fromJson({
        ...e,
        'full_name': userData?['full_name'],
        'avatar_url': userData?['avatar_url'],
      });
    }).toList();
  }

  /// Inviter un membre au voyage
  Future<void> inviteMember(String tripId, String email) async {
    final userId = _userId;
    if (userId == null) throw Exception('Non authentifié');

    // Trouver l'utilisateur par email
    final userResponse = await _supabase
        .from('profiles')
        .select('id')
        .eq('email', email)
        .maybeSingle();

    if (userResponse == null) {
      throw Exception('Utilisateur non trouvé');
    }

    await _supabase.from('trip_members').insert({
      'trip_id': tripId,
      'user_id': userResponse['id'],
      'invited_by': userId,
      'role': 'member',
      'status': 'pending',
    });
  }

  /// Accepter une invitation
  Future<void> acceptInvitation(String memberId) async {
    final userId = _userId;
    if (userId == null) return;

    await _supabase
        .from('trip_members')
        .update({
          'status': 'joined',
          'joined_at': DateTime.now().toIso8601String(),
        })
        .eq('id', memberId)
        .eq('user_id', userId);
  }

  /// Ajouter une dépense
  Future<TripExpense> addExpense({
    required String tripId,
    required String description,
    required double amount,
    String currency = 'EUR',
    required DateTime expenseDate,
    String? category,
    required String splitType,
    required Map<String, dynamic> splitDetails,
    String? notes,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Non authentifié');

    final response = await _supabase
        .from('trip_expenses')
        .insert({
          'trip_id': tripId,
          'paid_by': userId,
          'description': description,
          'amount': amount,
          'currency': currency,
          'expense_date': expenseDate.toIso8601String(),
          'category': category,
          'split_type': splitType,
          'split_details': splitDetails,
          'notes': notes,
        })
        .select()
        .single();

    // Mettre à jour le montant dépensé du voyage
    await _supabase.rpc('update_trip_spent_amount', params: {
      'p_trip_id': tripId,
    });

    return TripExpense.fromJson(response);
  }

  /// Récupérer les dépenses d'un voyage
  Future<List<TripExpense>> getTripExpenses(String tripId) async {
    final response = await _supabase
        .from('trip_expenses')
        .select('*, paid_by_user:paid_by(full_name, avatar_url)')
        .eq('trip_id', tripId)
        .order('expense_date', ascending: false);

    return (response as List).map((e) {
      final userData = e['paid_by_user'] as Map<String, dynamic>?;
      return TripExpense.fromJson({
        ...e,
        'paid_by_name': userData?['full_name'],
        'paid_by_avatar': userData?['avatar_url'],
      });
    }).toList();
  }

  /// Calculer les soldes
  Future<Map<String, double>> calculateBalances(String tripId) async {
    final response = await _supabase
        .rpc('calculate_trip_balances', params: {'p_trip_id': tripId});

    final balances = <String, double>{};
    for (final row in response as List) {
      balances[row['user_id'] as String] = (row['balance'] as num).toDouble();
    }

    return balances;
  }

  /// Récupérer le résumé complet d'un voyage
  Future<TripSummary> getTripSummary(String tripId) async {
    final tripResponse = await _supabase
        .from('user_trips')
        .select()
        .eq('id', tripId)
        .single();

    final trip = UserTrip.fromJson(tripResponse);

    final members = await getTripMembers(tripId);
    final expenses = await getTripExpenses(tripId);
    final balances = await calculateBalances(tripId);

    // Calculer les stats
    final totalSpent = expenses.fold<double>(
      0,
      (sum, e) => sum + e.amount,
    );

    final daysRemaining = trip.endDate != null
        ? trip.endDate!.difference(DateTime.now()).inDays
        : 0;

    final budgetRemaining = (trip.totalBudget ?? 0) - totalSpent;

    final dailyBudgetRecommended = daysRemaining > 0 && budgetRemaining > 0
        ? budgetRemaining / daysRemaining
        : 0;

    // Dépenses par catégorie
    final categoryMap = <String, double>{};
    for (final expense in expenses) {
      final cat = expense.category ?? 'Autre';
      categoryMap[cat] = (categoryMap[cat] ?? 0) + expense.amount;
    }

    final expensesByCategory = categoryMap.entries.map((e) {
      final percentage = totalSpent > 0 ? (e.value / totalSpent) * 100 : 0;
      return ExpenseByCategory(
        category: e.key,
        amount: e.value,
        percentage: percentage,
        count: expenses.where((ex) => ex.category == e.key).length,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return TripSummary(
      trip: trip,
      members: members,
      expenses: expenses,
      balances: balances,
      totalSpent: totalSpent,
      averageDailySpend: trip.startDate.difference(DateTime.now()).inDays > 0
          ? totalSpent / trip.startDate.difference(DateTime.now()).inDays.abs()
          : 0,
      daysRemaining: daysRemaining,
      budgetRemaining: budgetRemaining,
      dailyBudgetRecommended: dailyBudgetRecommended,
      expensesByCategory: expensesByCategory,
    );
  }

  /// Enregistrer une position GPS
  Future<void> saveLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
    String? countryCode,
    String? city,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    await _supabase.from('geo_locations').insert({
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'country_code': countryCode,
      'city': city,
      'detection_source': 'gps',
    });
  }

  /// Récupérer le taux de change
  Future<double?> getExchangeRate(String from, String to) async {
    final response = await _supabase
        .from('currency_rates')
        .select('rate')
        .eq('from_currency', from)
        .eq('to_currency', to)
        .order('rate_date', ascending: false)
        .limit(1)
        .maybeSingle();

    return response != null ? (response['rate'] as num).toDouble() : null;
  }
}