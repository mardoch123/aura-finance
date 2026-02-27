import 'package:freezed_annotation/freezed_annotation.dart';

part 'calculator_models.freezed.dart';
part 'calculator_models.g.dart';

/// Résultat d'un calcul de prêt immobilier
@freezed
class MortgageResult with _$MortgageResult {
  const factory MortgageResult({
    required double monthlyPayment,
    required double totalInterest,
    required double totalCost,
    required List<AmortizationEntry> schedule,
    required double interestRate,
    required int durationYears,
    required double principal,
  }) = _MortgageResult;

  factory MortgageResult.fromJson(Map<String, dynamic> json) =>
      _$MortgageResultFromJson(json);
}

/// Entrée d'amortissement
@freezed
class AmortizationEntry with _$AmortizationEntry {
  const factory AmortizationEntry({
    required int month,
    required double payment,
    required double principal,
    required double interest,
    required double remainingBalance,
  }) = _AmortizationEntry;

  factory AmortizationEntry.fromJson(Map<String, dynamic> json) =>
      _$AmortizationEntryFromJson(json);
}

/// Résultat d'intérêts composés
@freezed
class CompoundInterestResult with _$CompoundInterestResult {
  const factory CompoundInterestResult({
    required double finalAmount,
    required double totalContributions,
    required double totalInterest,
    required List<YearlyGrowth> yearlyBreakdown,
    required double initialInvestment,
    required double monthlyContribution,
    required double annualRate,
    required int years,
  }) = _CompoundInterestResult;

  factory CompoundInterestResult.fromJson(Map<String, dynamic> json) =>
      _$CompoundInterestResultFromJson(json);
}

/// Croissance annuelle
@freezed
class YearlyGrowth with _$YearlyGrowth {
  const factory YearlyGrowth({
    required int year,
    required double startBalance,
    required double contributions,
    required double interest,
    required double endBalance,
  }) = _YearlyGrowth;

  factory YearlyGrowth.fromJson(Map<String, dynamic> json) =>
      _$YearlyGrowthFromJson(json);
}

/// Résultat ROI
@freezed
class ROIResult with _$ROIResult {
  const factory ROIResult({
    required double roi,
    required double annualizedROI,
    required double totalReturn,
    required double netProfit,
    required double investment,
    required double finalValue,
    required int holdingPeriodYears,
  }) = _ROIResult;

  factory ROIResult.fromJson(Map<String, dynamic> json) =>
      _$ROIResultFromJson(json);
}

/// Taux de change
@freezed
class ExchangeRate with _$ExchangeRate {
  const factory ExchangeRate({
    required String fromCurrency,
    required String toCurrency,
    required double rate,
    required DateTime lastUpdated,
    required String source,
  }) = _ExchangeRate;

  factory ExchangeRate.fromJson(Map<String, dynamic> json) =>
      _$ExchangeRateFromJson(json);
}

/// Conversion de devise
@freezed
class CurrencyConversion with _$CurrencyConversion {
  const factory CurrencyConversion({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    required double convertedAmount,
    required double rate,
    required DateTime timestamp,
  }) = _CurrencyConversion;

  factory CurrencyConversion.fromJson(Map<String, dynamic> json) =>
      _$CurrencyConversionFromJson(json);
}

/// Types de calculateurs
enum CalculatorType {
  mortgage,
  compoundInterest,
  roi,
  currency,
}

/// Extension pour les noms affichés
extension CalculatorTypeInfo on CalculatorType {
  String get displayName {
    switch (this) {
      case CalculatorType.mortgage:
        return 'Prêt immobilier';
      case CalculatorType.compoundInterest:
        return 'Intérêts composés';
      case CalculatorType.roi:
        return 'ROI Investissement';
      case CalculatorType.currency:
        return 'Convertisseur';
    }
  }

  String get icon {
    switch (this) {
      case CalculatorType.mortgage:
        return '🏠';
      case CalculatorType.compoundInterest:
        return '📈';
      case CalculatorType.roi:
        return '💰';
      case CalculatorType.currency:
        return '💱';
    }
  }

  String get description {
    switch (this) {
      case CalculatorType.mortgage:
        return 'Simulez vos mensualités et plan d\'amortissement';
      case CalculatorType.compoundInterest:
        return 'Visualisez la magie des intérêts composés';
      case CalculatorType.roi:
        return 'Calculez le retour sur investissement';
      case CalculatorType.currency:
        return 'Convertissez en temps réel';
    }
  }
}

/// Devises supportées
class SupportedCurrencies {
  static const Map<String, String> currencies = {
    'EUR': '🇪🇺 Euro',
    'USD': '🇺🇸 Dollar US',
    'GBP': '🇬🇧 Livre Sterling',
    'CHF': '🇨🇭 Franc Suisse',
    'JPY': '🇯🇵 Yen Japonais',
    'CAD': '🇨🇦 Dollar Canadien',
    'AUD': '🇦🇺 Dollar Australien',
    'CNY': '🇨🇳 Yuan Chinois',
    'SEK': '🇸🇪 Couronne Suédoise',
    'NOK': '🇳🇴 Couronne Norvégienne',
    'DKK': '🇩🇰 Couronne Danoise',
    'PLN': '🇵🇱 Zloty Polonais',
    'CZK': '🇨🇿 Couronne Tchèque',
    'HUF': '🇭🇺 Forint Hongrois',
    'RON': '🇷🇴 Leu Roumain',
    'BGN': '🇧🇬 Lev Bulgare',
    'HRK': '🇭🇷 Kuna Croate',
    'TRY': '🇹🇷 Livre Turque',
    'BRL': '🇧🇷 Real Brésilien',
    'MXN': '🇲🇽 Peso Mexicain',
    'INR': '🇮🇳 Roupie Indienne',
    'KRW': '🇰🇷 Won Sud-Coréen',
    'SGD': '🇸🇬 Dollar Singapourien',
    'HKD': '🇭🇰 Dollar Hongkongais',
    'NZD': '🇳🇿 Dollar Néo-Zélandais',
    'ZAR': '🇿🇦 Rand Sud-Africain',
    'AED': '🇦🇪 Dirham Émirien',
    'SAR': '🇸🇦 Riyal Saoudien',
    'THB': '🇹🇭 Baht Thaïlandais',
    'MYR': '🇲🇾 Ringgit Malaisien',
    'IDR': '🇮🇩 Roupie Indonésienne',
    'PHP': '🇵🇭 Peso Philippin',
    'VND': '🇻🇳 Dong Vietnamien',
  };

  static String? getSymbol(String code) => currencies[code];
}
