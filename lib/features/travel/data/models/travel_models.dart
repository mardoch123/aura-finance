import 'package:freezed_annotation/freezed_annotation.dart';

part 'travel_models.freezed.dart';
part 'travel_models.g.dart';

/// Voyage détecté ou créé
@freezed
class UserTrip with _$UserTrip {
  const factory UserTrip({
    required String id,
    required String userId,
    required String name,
    required String destinationCountry,
    String? destinationCity,
    required String destinationCurrency,
    required DateTime startDate,
    DateTime? endDate,
    @Default(true) bool isOngoing,
    double? totalBudget,
    double? dailyBudget,
    @Default(0.0) double spentAmount,
    DateTime? detectedAt,
    String? detectionSource,
    @Default(false) bool isGroupTrip,
    String? groupCode,
    @Default('upcoming') String status,
    Map<String, dynamic>? metadata,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserTrip;

  factory UserTrip.fromJson(Map<String, dynamic> json) =>
      _$UserTripFromJson(json);
}

/// Membre d'un voyage de groupe
@freezed
class TripMember with _$TripMember {
  const factory TripMember({
    required String id,
    required String tripId,
    required String userId,
    @Default('member') String role,
    String? invitedBy,
    required DateTime invitedAt,
    DateTime? joinedAt,
    @Default('pending') String status,
    @Default(0.0) double balance,
    String? fullName,
    String? avatarUrl,
  }) = _TripMember;

  factory TripMember.fromJson(Map<String, dynamic> json) =>
      _$TripMemberFromJson(json);
}

/// Dépense partagée d'un voyage
@freezed
class TripExpense with _$TripExpense {
  const factory TripExpense({
    required String id,
    required String tripId,
    String? transactionId,
    required String paidBy,
    required String description,
    required double amount,
    @Default('EUR') String currency,
    required DateTime expenseDate,
    String? category,
    @Default('equal') String splitType,
    Map<String, dynamic>? splitDetails,
    String? receiptUrl,
    String? notes,
    @Default(false) bool isSettled,
    DateTime? settledAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    // Champs calculés
    String? paidByName,
    String? paidByAvatar,
    List<TripExpenseParticipant>? participants,
  }) = _TripExpense;

  factory TripExpense.fromJson(Map<String, dynamic> json) =>
      _$TripExpenseFromJson(json);
}

/// Participant à une dépense
@freezed
class TripExpenseParticipant with _$TripExpenseParticipant {
  const factory TripExpenseParticipant({
    required String id,
    required String expenseId,
    required String userId,
    required double shareAmount,
    double? sharePercentage,
    @Default(false) bool isPaid,
    DateTime? paidAt,
    String? fullName,
    String? avatarUrl,
  }) = _TripExpenseParticipant;

  factory TripExpenseParticipant.fromJson(Map<String, dynamic> json) =>
      _$TripExpenseParticipantFromJson(json);
}

/// Règlement entre membres
@freezed
class TripSettlement with _$TripSettlement {
  const factory TripSettlement({
    required String id,
    required String tripId,
    required String fromUserId,
    required String toUserId,
    required double amount,
    @Default('EUR') String currency,
    String? method,
    String? reference,
    @Default('pending') String status,
    required DateTime requestedAt,
    DateTime? completedAt,
    required DateTime createdAt,
    // Champs calculés
    String? fromUserName,
    String? toUserName,
  }) = _TripSettlement;

  factory TripSettlement.fromJson(Map<String, dynamic> json) =>
      _$TripSettlementFromJson(json);
}

/// Taux de change
@freezed
class CurrencyRate with _$CurrencyRate {
  const factory CurrencyRate({
    required String id,
    required String fromCurrency,
    required String toCurrency,
    required double rate,
    @Default('ECB') String source,
    required DateTime rateDate,
    required DateTime createdAt,
  }) = _CurrencyRate;

  factory CurrencyRate.fromJson(Map<String, dynamic> json) =>
      _$CurrencyRateFromJson(json);
}

/// Position géographique
@freezed
class GeoLocation with _$GeoLocation {
  const factory GeoLocation({
    required String id,
    required String userId,
    required double latitude,
    required double longitude,
    double? accuracy,
    String? countryCode,
    String? city,
    required DateTime detectedAt,
    @Default('gps') String detectionSource,
    @Default(false) bool isAnonymized,
    DateTime? anonymizedAt,
  }) = _GeoLocation;

  factory GeoLocation.fromJson(Map<String, dynamic> json) =>
      _$GeoLocationFromJson(json);
}

/// Résumé du voyage avec stats
@freezed
class TripSummary with _$TripSummary {
  const factory TripSummary({
    required UserTrip trip,
    required List<TripMember> members,
    required List<TripExpense> expenses,
    required Map<String, double> balances,
    required double totalSpent,
    required double averageDailySpend,
    required int daysRemaining,
    required double budgetRemaining,
    required double dailyBudgetRecommended,
    required List<ExpenseByCategory> expensesByCategory,
  }) = _TripSummary;

  factory TripSummary.fromJson(Map<String, dynamic> json) =>
      _$TripSummaryFromJson(json);
}

/// Dépenses par catégorie
@freezed
class ExpenseByCategory with _$ExpenseByCategory {
  const factory ExpenseByCategory({
    required String category,
    required double amount,
    required double percentage,
    required int count,
    String? icon,
    String? color,
  }) = _ExpenseByCategory;

  factory ExpenseByCategory.fromJson(Map<String, dynamic> json) =>
      _$ExpenseByCategoryFromJson(json);
}

/// Constantes de devises
class CurrencyCode {
  static const String eur = 'EUR';
  static const String usd = 'USD';
  static const String gbp = 'GBP';
  static const String jpy = 'JPY';
  static const String chf = 'CHF';
  static const String cad = 'CAD';
  static const String aud = 'AUD';
  static const String cny = 'CNY';

  static String getSymbol(String code) {
    return switch (code) {
      eur => '€',
      usd => '\$',
      gbp => '£',
      jpy => '¥',
      chf => 'Fr',
      cad => 'C\$',
      aud => 'A\$',
      cny => '¥',
      _ => code,
    };
  }
}

/// Pays populaires avec devises
class PopularDestinations {
  static const Map<String, Map<String, String>> destinations = {
    'FR': {'name': 'France', 'currency': CurrencyCode.eur},
    'US': {'name': 'États-Unis', 'currency': CurrencyCode.usd},
    'GB': {'name': 'Royaume-Uni', 'currency': CurrencyCode.gbp},
    'ES': {'name': 'Espagne', 'currency': CurrencyCode.eur},
    'IT': {'name': 'Italie', 'currency': CurrencyCode.eur},
    'DE': {'name': 'Allemagne', 'currency': CurrencyCode.eur},
    'PT': {'name': 'Portugal', 'currency': CurrencyCode.eur},
    'CH': {'name': 'Suisse', 'currency': CurrencyCode.chf},
    'JP': {'name': 'Japon', 'currency': CurrencyCode.jpy},
    'TH': {'name': 'Thaïlande', 'currency': 'THB'},
    'MA': {'name': 'Maroc', 'currency': 'MAD'},
    'TN': {'name': 'Tunisie', 'currency': 'TND'},
  };
}