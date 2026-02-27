import '../domain/calculator_models.dart';
import 'dart:math';

/// Service de calculs financiers
class CalculatorsService {
  CalculatorsService._();
  
  static final CalculatorsService _instance = CalculatorsService._();
  static CalculatorsService get instance => _instance;

  // ═══════════════════════════════════════════════════════════
  // PRÊT IMMOBILIER
  // ═══════════════════════════════════════════════════════════

  /// Calcule les mensualités et le plan d'amortissement d'un prêt
  MortgageResult calculateMortgage({
    required double principal, // Montant emprunté
    required double annualRate, // Taux annuel (%)
    required int years, // Durée en années
    double? monthlyPayment, // Mensualité (optionnel, calculée si null)
  }) {
    final monthlyRate = annualRate / 100 / 12;
    final months = years * 12;
    
    double payment;
    if (monthlyPayment != null) {
      payment = monthlyPayment;
    } else {
      // Formule: M = P * [r(1+r)^n] / [(1+r)^n - 1]
      if (monthlyRate == 0) {
        payment = principal / months;
      } else {
        payment = principal * 
          (monthlyRate * pow(1 + monthlyRate, months)) / 
          (pow(1 + monthlyRate, months) - 1);
      }
    }

    // Générer le plan d'amortissement
    final schedule = <AmortizationEntry>[];
    double remainingBalance = principal;
    double totalInterest = 0;

    for (int month = 1; month <= months; month++) {
      final interestPayment = remainingBalance * monthlyRate;
      final principalPayment = payment - interestPayment;
      remainingBalance -= principalPayment;
      totalInterest += interestPayment;

      // Éviter les erreurs d'arrondi sur le dernier mois
      if (month == months) {
        remainingBalance = 0;
      }

      schedule.add(AmortizationEntry(
        month: month,
        payment: payment,
        principal: principalPayment,
        interest: interestPayment,
        remainingBalance: remainingBalance > 0 ? remainingBalance : 0,
      ));
    }

    return MortgageResult(
      monthlyPayment: payment,
      totalInterest: totalInterest,
      totalCost: principal + totalInterest,
      schedule: schedule,
      interestRate: annualRate,
      durationYears: years,
      principal: principal,
    );
  }

  /// Calcule le capital empruntable selon les mensualités
  double calculateBorrowableAmount({
    required double monthlyPayment,
    required double annualRate,
    required int years,
  }) {
    final monthlyRate = annualRate / 100 / 12;
    final months = years * 12;

    if (monthlyRate == 0) {
      return monthlyPayment * months;
    }

    // Formule inverse: P = M * [(1+r)^n - 1] / [r(1+r)^n]
    return monthlyPayment * 
      (pow(1 + monthlyRate, months) - 1) / 
      (monthlyRate * pow(1 + monthlyRate, months));
  }

  /// Calcule la durée nécessaire pour rembourser
  int? calculateRequiredDuration({
    required double principal,
    required double monthlyPayment,
    required double annualRate,
  }) {
    final monthlyRate = annualRate / 100 / 12;

    if (monthlyPayment <= principal * monthlyRate) {
      return null; // Mensualité insuffisante
    }

    // n = -ln(1 - Pr/M) / ln(1+r)
    final months = -log(1 - (principal * monthlyRate) / monthlyPayment) / log(1 + monthlyRate);
    return months.ceil();
  }

  // ═══════════════════════════════════════════════════════════
  // INTÉRÊTS COMPOSÉS
  // ═══════════════════════════════════════════════════════════

  /// Calcule les intérêts composés avec versements réguliers
  CompoundInterestResult calculateCompoundInterest({
    required double initialInvestment,
    required double monthlyContribution,
    required double annualRate, // Taux annuel (%)
    required int years,
    String compoundFrequency = 'monthly', // monthly, quarterly, yearly
  }) {
    final periodsPerYear = _getPeriodsPerYear(compoundFrequency);
    final ratePerPeriod = annualRate / 100 / periodsPerYear;
    final totalPeriods = years * periodsPerYear;
    final contributionPerPeriod = monthlyContribution * (12 / periodsPerYear);

    double balance = initialInvestment;
    double totalContributions = initialInvestment;
    final yearlyBreakdown = <YearlyGrowth>[];

    for (int year = 1; year <= years; year++) {
      final startBalance = balance;
      double yearContributions = 0;
      double yearInterest = 0;

      for (int period = 0; period < periodsPerYear; period++) {
        final interest = balance * ratePerPeriod;
        balance += interest + contributionPerPeriod;
        yearInterest += interest;
        yearContributions += contributionPerPeriod;
      }

      totalContributions += yearContributions;

      yearlyBreakdown.add(YearlyGrowth(
        year: year,
        startBalance: startBalance,
        contributions: yearContributions,
        interest: yearInterest,
        endBalance: balance,
      ));
    }

    return CompoundInterestResult(
      finalAmount: balance,
      totalContributions: totalContributions,
      totalInterest: balance - totalContributions,
      yearlyBreakdown: yearlyBreakdown,
      initialInvestment: initialInvestment,
      monthlyContribution: monthlyContribution,
      annualRate: annualRate,
      years: years,
    );
  }

  /// Calcule le temps nécessaire pour atteindre un objectif
  int? calculateTimeToGoal({
    required double initialAmount,
    required double monthlyContribution,
    required double annualRate,
    required double targetAmount,
  }) {
    final monthlyRate = annualRate / 100 / 12;
    double balance = initialAmount;
    int months = 0;
    const maxMonths = 1200; // 100 ans max

    while (balance < targetAmount && months < maxMonths) {
      balance = balance * (1 + monthlyRate) + monthlyContribution;
      months++;
    }

    return months >= maxMonths ? null : months;
  }

  /// Calcule le versement mensuel nécessaire
  double? calculateRequiredMonthlyContribution({
    required double initialAmount,
    required double annualRate,
    required int years,
    required double targetAmount,
  }) {
    final monthlyRate = annualRate / 100 / 12;
    final months = years * 12;

    // FV = PV(1+r)^n + PMT[((1+r)^n - 1)/r]
    // On isole PMT
    final fvFactor = pow(1 + monthlyRate, months);
    final fvFromInitial = initialAmount * fvFactor;
    
    if (fvFromInitial >= targetAmount) return 0;

    final pmt = (targetAmount - fvFromInitial) / ((fvFactor - 1) / monthlyRate);
    return pmt > 0 ? pmt : null;
  }

  // ═══════════════════════════════════════════════════════════
  // ROI INVESTISSEMENT
  // ═══════════════════════════════════════════════════════════

  /// Calcule le retour sur investissement
  ROIResult calculateROI({
    required double initialInvestment,
    required double finalValue,
    required int holdingPeriodYears,
    List<double>? cashFlows, // Flux de trésorerie annuels (dividendes, loyers...)
  }) {
    double totalCashFlows = 0;
    if (cashFlows != null) {
      totalCashFlows = cashFlows.reduce((a, b) => a + b);
    }

    final totalReturn = finalValue - initialInvestment + totalCashFlows;
    final roi = (totalReturn / initialInvestment) * 100;

    // ROI annualisé: (1 + ROI)^(1/n) - 1
    final annualizedROI = (pow(1 + roi / 100, 1 / holdingPeriodYears) - 1) * 100;

    return ROIResult(
      roi: roi,
      annualizedROI: annualizedROI,
      totalReturn: totalReturn,
      netProfit: totalReturn,
      investment: initialInvestment,
      finalValue: finalValue,
      holdingPeriodYears: holdingPeriodYears,
    );
  }

  /// Calcule le TRI (Taux de Rendement Interne)
  double? calculateIRR({
    required double initialInvestment,
    required List<double> cashFlows,
  }) {
    // Méthode de Newton-Raphson simplifiée
    double rate = 0.1; // 10% initial guess
    const maxIterations = 100;
    const precision = 0.0001;

    for (int i = 0; i < maxIterations; i++) {
      double npv = -initialInvestment;
      double derivative = 0;

      for (int t = 0; t < cashFlows.length; t++) {
        final discountFactor = pow(1 + rate, t + 1);
        npv += cashFlows[t] / discountFactor;
        derivative -= (t + 1) * cashFlows[t] / pow(1 + rate, t + 2);
      }

      if (derivative.abs() < precision) break;

      final newRate = rate - npv / derivative;
      if ((newRate - rate).abs() < precision) {
        return newRate * 100;
      }
      rate = newRate;
    }

    return null;
  }

  /// Compare plusieurs scénarios d'investissement
  List<ROIResult> compareInvestments({
    required List<InvestmentScenario> scenarios,
  }) {
    return scenarios.map((s) => calculateROI(
      initialInvestment: s.initialInvestment,
      finalValue: s.finalValue,
      holdingPeriodYears: s.years,
      cashFlows: s.cashFlows,
    )).toList();
  }

  // ═══════════════════════════════════════════════════════════
  // UTILITAIRES
  // ═══════════════════════════════════════════════════════════

  int _getPeriodsPerYear(String frequency) {
    switch (frequency) {
      case 'monthly':
        return 12;
      case 'quarterly':
        return 4;
      case 'yearly':
        return 1;
      default:
        return 12;
    }
  }

  /// Formate un montant en devise
  String formatCurrency(double amount, {String symbol = '€', int decimals = 2}) {
    final formatted = amount.toStringAsFixed(decimals);
    return '$formatted $symbol';
  }

  /// Formate un pourcentage
  String formatPercentage(double value, {int decimals = 2}) {
    final formatted = value.toStringAsFixed(decimals);
    return '$formatted%';
  }
}

/// Scénario d'investissement pour comparaison
class InvestmentScenario {
  final String name;
  final double initialInvestment;
  final double finalValue;
  final int years;
  final List<double>? cashFlows;

  InvestmentScenario({
    required this.name,
    required this.initialInvestment,
    required this.finalValue,
    required this.years,
    this.cashFlows,
  });
}

/// Règle des 72: temps pour doubler un investissement
class RuleOf72 {
  /// Calcule le temps nécessaire pour doubler
  static double yearsToDouble(double annualRate) {
    return 72 / annualRate;
  }

  /// Calcule le taux nécessaire pour doubler en X années
  static double rateToDouble(int years) {
    return 72 / years;
  }
}
