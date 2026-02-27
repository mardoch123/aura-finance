import 'package:freezed_annotation/freezed_annotation.dart';

part 'reconciliation_models.freezed.dart';
part 'reconciliation_models.g.dart';

/// Relevé bancaire importé
@freezed
class BankStatement with _$BankStatement {
  const factory BankStatement({
    required String id,
    required String userId,
    required String accountId,
    required DateTime statementPeriodStart,
    required DateTime statementPeriodEnd,
    required String fileName,
    required String fileUrl,
    int? fileSize,
    String? bankName,
    String? accountNumberMasked,
    @Default('EUR') String currency,
    required double openingBalance,
    required double closingBalance,
    double? calculatedBalance,
    @Default('processing') String status,
    @Default(0) int totalTransactions,
    @Default(0) int matchedTransactions,
    @Default(0) int unmatchedTransactions,
    @Default(0.0) double discrepancyAmount,
    String? errorMessage,
    DateTime? processedAt,
    String? processedBy,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _BankStatement;

  factory BankStatement.fromJson(Map<String, dynamic> json) =>
      _$BankStatementFromJson(json);
}

/// Transaction extraite du relevé
@freezed
class BankStatementTransaction with _$BankStatementTransaction {
  const factory BankStatementTransaction({
    required String id,
    required String statementId,
    String? rawDate,
    String? rawDescription,
    String? rawAmount,
    String? rawBalance,
    required DateTime transactionDate,
    DateTime? valueDate,
    required String description,
    required double amount,
    String? category,
    String? subcategory,
    String? merchantName,
    String? merchantId,
    String? referenceNumber,
    String? checkNumber,
    String? matchedTransactionId,
    double? matchConfidence,
    String? matchMethod,
    DateTime? matchedAt,
    String? matchedBy,
    @Default(false) bool hasDiscrepancy,
    String? discrepancyType,
    Map<String, dynamic>? discrepancyDetails,
    @Default('unmatched') String status,
    String? userAction,
    DateTime? userActionAt,
    String? userActionBy,
    String? userNotes,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _BankStatementTransaction;

  factory BankStatementTransaction.fromJson(Map<String, dynamic> json) =>
      _$BankStatementTransactionFromJson(json);
}

/// Session de rapprochement
@freezed
class ReconciliationSession with _$ReconciliationSession {
  const factory ReconciliationSession({
    required String id,
    required String userId,
    required String accountId,
    String? statementId,
    required DateTime periodStart,
    required DateTime periodEnd,
    @Default(0) int totalItems,
    @Default(0) int processedItems,
    @Default(0) int matchedItems,
    @Default(0) int discrepancyItems,
    @Default('in_progress') String status,
    required DateTime startedAt,
    DateTime? completedAt,
    int? durationSeconds,
    double? startingBalance,
    double? endingBalance,
    @Default(0.0) double discrepancyTotal,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ReconciliationSession;

  factory ReconciliationSession.fromJson(Map<String, dynamic> json) =>
      _$ReconciliationSessionFromJson(json);
}

/// Action de rapprochement
@freezed
class ReconciliationAction with _$ReconciliationAction {
  const factory ReconciliationAction({
    required String id,
    required String sessionId,
    required String actionType,
    String? statementTransactionId,
    String? appTransactionId,
    Map<String, dynamic>? details,
    required String performedBy,
    required DateTime performedAt,
    @Default(true) bool canUndo,
    DateTime? undoneAt,
    String? undoneBy,
  }) = _ReconciliationAction;

  factory ReconciliationAction.fromJson(Map<String, dynamic> json) =>
      _$ReconciliationActionFromJson(json);
}

/// Règle de matching personnalisée
@freezed
class MatchingRule with _$MatchingRule {
  const factory MatchingRule({
    required String id,
    required String userId,
    required String name,
    String? description,
    String? bankDescriptionPattern,
    String? appDescriptionPattern,
    @Default(0.01) double amountTolerance,
    @Default(2) int dateToleranceDays,
    @Default(false) bool autoMatch,
    String? autoCategorize,
    @Default(0) int priority,
    @Default(0) int timesApplied,
    DateTime? lastAppliedAt,
    @Default(true) bool isActive,
    required DateTime createdAt,
  }) = _MatchingRule;

  factory MatchingRule.fromJson(Map<String, dynamic> json) =>
      _$MatchingRuleFromJson(json);
}

/// Résultat de matching
@freezed
class MatchResult with _$MatchResult {
  const factory MatchResult({
    required String statementTransactionId,
    String? matchedTransactionId,
    required double confidence,
    required String method,
    String? discrepancyType,
    Map<String, dynamic>? discrepancyDetails,
  }) = _MatchResult;

  factory MatchResult.fromJson(Map<String, dynamic> json) =>
      _$MatchResultFromJson(json);
}

/// Vue d'ensemble du rapprochement
@freezed
class ReconciliationOverview with _$ReconciliationOverview {
  const factory ReconciliationOverview({
    required BankStatement statement,
    required List<BankStatementTransaction> transactions,
    required List<ReconciliationAction> recentActions,
    required Map<String, int> statusCounts,
    required double totalMatchedAmount,
    required double totalUnmatchedAmount,
    required List<DiscrepancySummary> discrepancies,
    required double progressPercentage,
  }) = _ReconciliationOverview;

  factory ReconciliationOverview.fromJson(Map<String, dynamic> json) =>
      _$ReconciliationOverviewFromJson(json);
}

/// Résumé des écarts
@freezed
class DiscrepancySummary with _$DiscrepancySummary {
  const factory DiscrepancySummary({
    required String type,
    required int count,
    required double totalAmount,
    required List<BankStatementTransaction> transactions,
  }) = _DiscrepancySummary;

  factory DiscrepancySummary.fromJson(Map<String, dynamic> json) =>
      _$DiscrepancySummaryFromJson(json);
}

/// Types d'actions
class ReconciliationActionType {
  static const String match = 'match';
  static const String unmatch = 'unmatch';
  static const String create = 'create';
  static const String ignore = 'ignore';
  static const String edit = 'edit';
  static const String merge = 'merge';
  static const String confirmBalance = 'confirm_balance';
  static const String addNote = 'add_note';
}

/// Types d'écarts
class DiscrepancyType {
  static const String amount = 'amount';
  static const String date = 'date';
  static const String duplicate = 'duplicate';
  static const String missing = 'missing';
  static const String unknown = 'unknown';
}

/// Statuts de transaction relevé
class StatementTransactionStatus {
  static const String unmatched = 'unmatched';
  static const String matched = 'matched';
  static const String discrepancy = 'discrepancy';
  static const String ignored = 'ignored';
  static const String created = 'created';
}

/// Statuts de relevé
class BankStatementStatus {
  static const String processing = 'processing';
  static const String parsed = 'parsed';
  static const String matching = 'matching';
  static const String reconciled = 'reconciled';
  static const String error = 'error';
}

/// Extension pour les labels
extension DiscrepancyTypeExtension on String {
  String get discrepancyLabel {
    return switch (this) {
      DiscrepancyType.amount => 'Écart de montant',
      DiscrepancyType.date => 'Écart de date',
      DiscrepancyType.duplicate => 'Doublon détecté',
      DiscrepancyType.missing => 'Transaction manquante',
      DiscrepancyType.unknown => 'Écart inconnu',
      _ => this,
    };
  }
}