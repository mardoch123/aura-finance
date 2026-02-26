import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_model.freezed.dart';
part 'transaction_model.g.dart';

/// Modèle de transaction financière
@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required String userId,
    String? accountId,
    required double amount,
    @Default('other') String category,
    String? subcategory,
    String? merchant,
    String? description,
    required DateTime date,
    @Default('manual') String source,
    String? scanImageUrl,
    double? aiConfidence,
    @Default(false) bool isRecurring,
    String? recurringGroupId,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);

  /// Constructeur vide pour les états initiaux
  factory Transaction.empty() => Transaction(
        id: '',
        userId: '',
        amount: 0.0,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );
}

/// Extension pour les propriétés calculées
extension TransactionExtension on Transaction {
  /// Vrai si c'est une dépense (montant négatif)
  bool get isExpense => amount < 0;

  /// Vrai si c'est un revenu (montant positif)
  bool get isIncome => amount > 0;

  /// Montant absolu pour l'affichage
  double get absoluteAmount => amount.abs();

  /// Icône associée à la catégorie
  String get categoryIcon {
    final icons = {
      'food': '🍽️',
      'transport': '🚗',
      'housing': '🏠',
      'entertainment': '🎬',
      'shopping': '🛍️',
      'health': '💊',
      'education': '📚',
      'travel': '✈️',
      'utilities': '💡',
      'salary': '💰',
      'other': '📦',
    };
    return icons[category.toLowerCase()] ?? '📦';
  }

  /// Couleur associée à la catégorie
  String get categoryColor {
    final colors = {
      'food': '#FF6B6B',
      'transport': '#4ECDC4',
      'housing': '#45B7D1',
      'entertainment': '#96CEB4',
      'shopping': '#FFEAA7',
      'health': '#DDA0DD',
      'education': '#98D8C8',
      'travel': '#F7DC6F',
      'utilities': '#BB8FCE',
      'salary': '#58D68D',
      'other': '#95A5A6',
    };
    return colors[category.toLowerCase()] ?? '#95A5A6';
  }
}

/// Filtres pour les transactions
enum TransactionFilter {
  all('Toutes'),
  income('Revenus'),
  expense('Dépenses'),
  recurring('Récurrentes');

  final String label;
  const TransactionFilter(this.label);
}

/// Période de filtrage
enum TransactionPeriod {
  today('Aujourd\'hui'),
  week('Cette semaine'),
  month('Ce mois'),
  quarter('Ce trimestre'),
  year('Cette année'),
  custom('Période personnalisée');

  final String label;
  const TransactionPeriod(this.label);

  /// Date de début selon la période
  DateTime get startDate {
    final now = DateTime.now();
    switch (this) {
      case TransactionPeriod.today:
        return DateTime(now.year, now.month, now.day);
      case TransactionPeriod.week:
        return now.subtract(Duration(days: now.weekday - 1));
      case TransactionPeriod.month:
        return DateTime(now.year, now.month, 1);
      case TransactionPeriod.quarter:
        final quarterStart = ((now.month - 1) ~/ 3) * 3 + 1;
        return DateTime(now.year, quarterStart, 1);
      case TransactionPeriod.year:
        return DateTime(now.year, 1, 1);
      case TransactionPeriod.custom:
        return now.subtract(const Duration(days: 30));
    }
  }

  /// Date de fin selon la période
  DateTime get endDate {
    final now = DateTime.now();
    switch (this) {
      case TransactionPeriod.today:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case TransactionPeriod.week:
        return now.add(Duration(days: 7 - now.weekday));
      case TransactionPeriod.month:
        return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      case TransactionPeriod.quarter:
        final quarterEnd = ((now.month - 1) ~/ 3) * 3 + 3;
        return DateTime(now.year, quarterEnd + 1, 0, 23, 59, 59);
      case TransactionPeriod.year:
        return DateTime(now.year, 12, 31, 23, 59, 59);
      case TransactionPeriod.custom:
        return now;
    }
  }
}
