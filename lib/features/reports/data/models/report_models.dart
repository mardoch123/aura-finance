import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

part 'report_models.freezed.dart';
part 'report_models.g.dart';

// ═══════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════

enum ReportType {
  taxDeclaration,
  annualAnalysis,
  loanApplication,
  monthlySummary,
  categoryBreakdown,
  custom,
}

enum ReportStatus {
  pending,
  generating,
  completed,
  failed,
  expired,
}

enum ReportFrequency {
  weekly,
  monthly,
  quarterly,
  yearly,
}

enum ReportFormat {
  pdf,
  excel,
}

// ═══════════════════════════════════════════════════════════
// REPORT TEMPLATE MODELS
// ═══════════════════════════════════════════════════════════

@freezed
class ReportTemplate with _$ReportTemplate {
  const factory ReportTemplate({
    required String id,
    required String code,
    required String name,
    required String description,
    @Default(ReportType.custom) ReportType type,
    @Default({}) Map<String, dynamic> config,
    @Default([ReportFormat.pdf, ReportFormat.excel]) List<ReportFormat> availableFormats,
    @Default('description') String icon,
    @Default('#E8A86C') String color,
    @Default(false) bool isProFeature,
    @Default(true) bool isActive,
    @Default(0) int displayOrder,
    required DateTime createdAt,
  }) = _ReportTemplate;

  factory ReportTemplate.fromJson(Map<String, dynamic> json) =>
      _$ReportTemplateFromJson(json);

  String get typeLabel {
    return switch (type) {
      ReportType.taxDeclaration => 'Fiscal',
      ReportType.annualAnalysis => 'Analyse',
      ReportType.loanApplication => 'Prêt',
      ReportType.monthlySummary => 'Mensuel',
      ReportType.categoryBreakdown => 'Catégories',
      ReportType.custom => 'Personnalisé',
    };
  }

  IconData get iconData {
    return switch (icon) {
      'account_balance' => Icons.account_balance,
      'analytics' => Icons.analytics,
      'home' => Icons.home,
      'calendar_month' => Icons.calendar_month,
      'pie_chart' => Icons.pie_chart,
      _ => Icons.description,
    };
  }
}

// ═══════════════════════════════════════════════════════════
// GENERATED REPORT MODELS
// ═══════════════════════════════════════════════════════════

@freezed
class GeneratedReport with _$GeneratedReport {
  const factory GeneratedReport({
    required String id,
    required String userId,
    String? templateId,
    required String name,
    String? description,
    required DateTime periodStart,
    required DateTime periodEnd,
    @Default({}) Map<String, dynamic> config,
    String? pdfUrl,
    String? excelUrl,
    @Default(ReportStatus.pending) ReportStatus status,
    int? fileSizeBytes,
    int? pageCount,
    int? transactionCount,
    String? emailSentTo,
    DateTime? emailSentAt,
    @Default(0) int downloadCount,
    DateTime? lastDownloadedAt,
    required DateTime expiresAt,
    required DateTime createdAt,
    DateTime? updatedAt,
    // Relations
    ReportTemplate? template,
  }) = _GeneratedReport;

  factory GeneratedReport.fromJson(Map<String, dynamic> json) =>
      _$GeneratedReportFromJson(json);

  bool get isCompleted => status == ReportStatus.completed;
  bool get isPending => status == ReportStatus.pending || status == ReportStatus.generating;
  bool get isFailed => status == ReportStatus.failed;
  bool get isExpired => status == ReportStatus.expired || expiresAt.isBefore(DateTime.now());

  String get fileSizeFormatted {
    if (fileSizeBytes == null) return '--';
    if (fileSizeBytes! < 1024) return '${fileSizeBytes}B';
    if (fileSizeBytes! < 1024 * 1024) return '${(fileSizeBytes! / 1024).toStringAsFixed(1)}KB';
    return '${(fileSizeBytes! / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get periodLabel {
    final sameMonth = periodStart.year == periodEnd.year && 
                      periodStart.month == periodEnd.month;
    if (sameMonth) {
      return '${periodStart.month.toString().padLeft(2, '0')}/${periodStart.year}';
    }
    return '${periodStart.day}/${periodStart.month} - ${periodEnd.day}/${periodEnd.month}';
  }
}

// ═══════════════════════════════════════════════════════════
// SCHEDULED REPORT MODELS
// ═══════════════════════════════════════════════════════════

@freezed
class ScheduledReport with _$ScheduledReport {
  const factory ScheduledReport({
    required String id,
    required String userId,
    required String templateId,
    required String name,
    @Default(ReportFrequency.monthly) ReportFrequency frequency,
    @Default([]) List<String> emailRecipients,
    @Default(true) bool includePdf,
    @Default(false) bool includeExcel,
    required DateTime nextSendAt,
    DateTime? lastSentAt,
    @Default(true) bool isActive,
    required DateTime createdAt,
    DateTime? updatedAt,
    // Relations
    ReportTemplate? template,
  }) = _ScheduledReport;

  factory ScheduledReport.fromJson(Map<String, dynamic> json) =>
      _$ScheduledReportFromJson(json);

  String get frequencyLabel {
    return switch (frequency) {
      ReportFrequency.weekly => 'Hebdomadaire',
      ReportFrequency.monthly => 'Mensuel',
      ReportFrequency.quarterly => 'Trimestriel',
      ReportFrequency.yearly => 'Annuel',
    };
  }
}

// ═══════════════════════════════════════════════════════════
// REPORT CONFIGURATION MODELS
// ═══════════════════════════════════════════════════════════

@freezed
class ReportConfiguration with _$ReportConfiguration {
  const factory ReportConfiguration({
    required String templateId,
    required DateTime periodStart,
    required DateTime periodEnd,
    @Default([ReportFormat.pdf]) List<ReportFormat> formats,
    @Default({}) Map<String, dynamic> customConfig,
    String? emailRecipient,
    @Default(false) bool scheduleRecurring,
    ReportFrequency? scheduleFrequency,
  }) = _ReportConfiguration;

  factory ReportConfiguration.fromJson(Map<String, dynamic> json) =>
      _$ReportConfigurationFromJson(json);
}

// ═══════════════════════════════════════════════════════════
// REPORT DATA MODELS (pour l'affichage des données dans les rapports)
// ═══════════════════════════════════════════════════════════

@freezed
class ReportData with _$ReportData {
  const factory ReportData({
    required ReportSummary summary,
    required List<ReportCategoryBreakdown> categoryBreakdown,
    required List<ReportMonthlyTrend> monthlyTrends,
    required List<ReportTransaction> transactions,
    required List<ReportDeduction> deductions,
    ReportLoanMetrics? loanMetrics,
  }) = _ReportData;

  factory ReportData.fromJson(Map<String, dynamic> json) =>
      _$ReportDataFromJson(json);
}

@freezed
class ReportSummary with _$ReportSummary {
  const factory ReportSummary({
    required double totalIncome,
    required double totalExpenses,
    required double netSavings,
    required double savingsRate,
    required int transactionCount,
    required double averageDailyExpense,
    required double largestExpense,
    String? largestExpenseCategory,
  }) = _ReportSummary;

  factory ReportSummary.fromJson(Map<String, dynamic> json) =>
      _$ReportSummaryFromJson(json);
}

@freezed
class ReportCategoryBreakdown with _$ReportCategoryBreakdown {
  const factory ReportCategoryBreakdown({
    required String category,
    required String? subcategory,
    required double amount,
    required double percentage,
    required int transactionCount,
    required double averageAmount,
    String? trend, // 'up', 'down', 'stable'
  }) = _ReportCategoryBreakdown;

  factory ReportCategoryBreakdown.fromJson(Map<String, dynamic> json) =>
      _$ReportCategoryBreakdownFromJson(json);
}

@freezed
class ReportMonthlyTrend with _$ReportMonthlyTrend {
  const factory ReportMonthlyTrend({
    required DateTime month,
    required double income,
    required double expenses,
    required double savings,
  }) = _ReportMonthlyTrend;

  factory ReportMonthlyTrend.fromJson(Map<String, dynamic> json) =>
      _$ReportMonthlyTrendFromJson(json);
}

@freezed
class ReportTransaction with _$ReportTransaction {
  const factory ReportTransaction({
    required String id,
    required DateTime date,
    required String description,
    required String category,
    required double amount,
    String? merchant,
    bool? isDeductible,
    String? deductionCategory,
  }) = _ReportTransaction;

  factory ReportTransaction.fromJson(Map<String, dynamic> json) =>
      _$ReportTransactionFromJson(json);
}

@freezed
class ReportDeduction with _$ReportDeduction {
  const factory ReportDeduction({
    required String category,
    required String description,
    required double amount,
    required String? legalReference,
    double? maxDeduction,
  }) = _ReportDeduction;

  factory ReportDeduction.fromJson(Map<String, dynamic> json) =>
      _$ReportDeductionFromJson(json);
}

@freezed
class ReportLoanMetrics with _$ReportLoanMetrics {
  const factory ReportLoanMetrics({
    required double averageMonthlyIncome,
    required double averageMonthlyExpenses,
    required double debtToIncomeRatio,
    required double savingsCapacity,
    required double averageAccountBalance,
    required int monthsOfHistory,
    required List<String> incomeSources,
    required bool hasRegularIncome,
  }) = _ReportLoanMetrics;

  factory ReportLoanMetrics.fromJson(Map<String, dynamic> json) =>
      _$ReportLoanMetricsFromJson(json);
}

// ═══════════════════════════════════════════════════════════
// STATE MODELS
// ═══════════════════════════════════════════════════════════

@freezed
class ReportsState with _$ReportsState {
  const factory ReportsState({
    @Default([]) List<ReportTemplate> templates,
    @Default([]) List<GeneratedReport> recentReports,
    @Default([]) List<ScheduledReport> scheduledReports,
    @Default(false) bool isLoading,
    String? error,
    ReportTemplate? selectedTemplate,
  }) = _ReportsState;
}

// Extension pour IconData

extension IconDataExtension on String {
  IconData get iconData {
    return switch (this) {
      'account_balance' => Icons.account_balance,
      'analytics' => Icons.analytics,
      'home' => Icons.home,
      'calendar_month' => Icons.calendar_month,
      'pie_chart' => Icons.pie_chart,
      'description' => Icons.description,
      'receipt' => Icons.receipt,
      'trending_up' => Icons.trending_up,
      _ => Icons.description,
    };
  }
}
