import 'package:flutter/material.dart';
import '../theme/aura_colors.dart';

/// Constantes des catégories de transactions
class Categories {
  Categories._();

  // ═══════════════════════════════════════════════════════════
  // CATÉGORIES DE DÉPENSES
  // ═══════════════════════════════════════════════════════════

  static const String food = 'food';
  static const String transport = 'transport';
  static const String housing = 'housing';
  static const String entertainment = 'entertainment';
  static const String shopping = 'shopping';
  static const String health = 'health';
  static const String education = 'education';
  static const String travel = 'travel';
  static const String utilities = 'utilities';
  static const String subscriptions = 'subscriptions';
  static const String other = 'other';

  // ═══════════════════════════════════════════════════════════
  // CATÉGORIES DE REVENUS
  // ═══════════════════════════════════════════════════════════

  static const String income = 'income';
  static const String salary = 'salary';
  static const String freelance = 'freelance';
  static const String investment = 'investment_income';
  static const String gift = 'gift';
  static const String refund = 'refund';

  // ═══════════════════════════════════════════════════════════
  // TYPES DE COMPTE
  // ═══════════════════════════════════════════════════════════

  static const String accountChecking = 'checking';
  static const String accountSavings = 'savings';
  static const String accountCredit = 'credit';
  static const String accountInvestment = 'investment';

  // ═══════════════════════════════════════════════════════════
  // SOURCES DE TRANSACTION
  // ═══════════════════════════════════════════════════════════

  static const String sourceManual = 'manual';
  static const String sourceScan = 'scan';
  static const String sourceVoice = 'voice';
  static const String sourceImport = 'import';

  // ═══════════════════════════════════════════════════════════
  // CYCLES DE FACTURATION
  // ═══════════════════════════════════════════════════════════

  static const String cycleWeekly = 'weekly';
  static const String cycleMonthly = 'monthly';
  static const String cycleYearly = 'yearly';

  // ═══════════════════════════════════════════════════════════
  // TYPES D'INSIGHTS IA
  // ═══════════════════════════════════════════════════════════

  static const String insightPrediction = 'prediction';
  static const String insightAlert = 'alert';
  static const String insightTip = 'tip';
  static const String insightVampire = 'vampire';
  static const String insightAchievement = 'achievement';

  // ═══════════════════════════════════════════════════════════
  // LISTES
  // ═══════════════════════════════════════════════════════════

  static const List<String> expenseCategories = [
    food,
    transport,
    housing,
    entertainment,
    shopping,
    health,
    education,
    travel,
    utilities,
    subscriptions,
    other,
  ];

  static const List<String> incomeCategories = [
    salary,
    freelance,
    investment,
    gift,
    refund,
    other,
  ];

  static const List<String> accountTypes = [
    accountChecking,
    accountSavings,
    accountCredit,
    accountInvestment,
  ];

  static const List<String> billingCycles = [
    cycleWeekly,
    cycleMonthly,
    cycleYearly,
  ];

  static const List<String> insightTypes = [
    insightPrediction,
    insightAlert,
    insightTip,
    insightVampire,
    insightAchievement,
  ];

  // ═══════════════════════════════════════════════════════════
  // LABELS
  // ═══════════════════════════════════════════════════════════

  static const Map<String, String> labels = {
    // Dépenses
    food: 'Alimentation',
    transport: 'Transport',
    housing: 'Logement',
    entertainment: 'Loisirs',
    shopping: 'Shopping',
    health: 'Santé',
    education: 'Éducation',
    travel: 'Voyage',
    utilities: 'Factures',
    subscriptions: 'Abonnements',
    other: 'Autre',
    // Revenus
    salary: 'Salaire',
    freelance: 'Freelance',
    investment: 'Investissements',
    gift: 'Cadeau',
    refund: 'Remboursement',
    // Comptes
    accountChecking: 'Compte courant',
    accountSavings: 'Épargne',
    accountCredit: 'Carte de crédit',
    accountInvestment: 'Investissement',
    // Cycles
    cycleWeekly: 'Hebdomadaire',
    cycleMonthly: 'Mensuel',
    cycleYearly: 'Annuel',
  };

  static String getLabel(String key) {
    return labels[key] ?? key;
  }

  // ═══════════════════════════════════════════════════════════
  // ICÔNES
  // ═══════════════════════════════════════════════════════════

  static const Map<String, IconData> icons = {
    food: Icons.restaurant,
    transport: Icons.directions_car,
    housing: Icons.home,
    entertainment: Icons.movie,
    shopping: Icons.shopping_bag,
    health: Icons.favorite,
    education: Icons.school,
    travel: Icons.flight,
    utilities: Icons.bolt,
    subscriptions: Icons.subscriptions,
    other: Icons.more_horiz,
    salary: Icons.work,
    freelance: Icons.laptop,
    investment: Icons.trending_up,
    gift: Icons.card_giftcard,
    refund: Icons.reply,
    accountChecking: Icons.account_balance,
    accountSavings: Icons.savings,
    accountCredit: Icons.credit_card,
    accountInvestment: Icons.show_chart,
  };

  static IconData getIcon(String key) {
    return icons[key] ?? Icons.help_outline;
  }

  // ═══════════════════════════════════════════════════════════
  // COULEURS
  // ═══════════════════════════════════════════════════════════

  static Color getColor(String key) {
    return AuraColors.categoryColors[key] ?? AuraColors.auraTextDarkSecondary;
  }
}

/// Classe pour les données de catégorie complètes
class CategoryInfo {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  final bool isExpense;

  const CategoryInfo({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
    this.isExpense = true,
  });

  static final Map<String, CategoryInfo> all = {
    Categories.food: const CategoryInfo(
      key: Categories.food,
      label: 'Alimentation',
      icon: Icons.restaurant,
      color: AuraColors.auraAmber,
    ),
    Categories.transport: const CategoryInfo(
      key: Categories.transport,
      label: 'Transport',
      icon: Icons.directions_car,
      color: AuraColors.auraGreen,
    ),
    Categories.housing: const CategoryInfo(
      key: Categories.housing,
      label: 'Logement',
      icon: Icons.home,
      color: AuraColors.auraDeep,
    ),
    Categories.entertainment: const CategoryInfo(
      key: Categories.entertainment,
      label: 'Loisirs',
      icon: Icons.movie,
      color: AuraColors.auraAccentGold,
    ),
    Categories.shopping: const CategoryInfo(
      key: Categories.shopping,
      label: 'Shopping',
      icon: Icons.shopping_bag,
      color: AuraColors.auraRed,
    ),
    Categories.health: const CategoryInfo(
      key: Categories.health,
      label: 'Santé',
      icon: Icons.favorite,
      color: Color(0xFF7EC8E3),
    ),
    Categories.education: const CategoryInfo(
      key: Categories.education,
      label: 'Éducation',
      icon: Icons.school,
      color: Color(0xFFB8A9C9),
    ),
    Categories.travel: const CategoryInfo(
      key: Categories.travel,
      label: 'Voyage',
      icon: Icons.flight,
      color: Color(0xFF98D8C8),
    ),
    Categories.utilities: const CategoryInfo(
      key: Categories.utilities,
      label: 'Factures',
      icon: Icons.bolt,
      color: AuraColors.auraYellow,
    ),
    Categories.subscriptions: const CategoryInfo(
      key: Categories.subscriptions,
      label: 'Abonnements',
      icon: Icons.subscriptions,
      color: Color(0xFFD4A5A5),
    ),
    Categories.salary: const CategoryInfo(
      key: Categories.salary,
      label: 'Salaire',
      icon: Icons.work,
      color: AuraColors.auraGreen,
      isExpense: false,
    ),
    Categories.other: const CategoryInfo(
      key: Categories.other,
      label: 'Autre',
      icon: Icons.more_horiz,
      color: Color(0xFFB0B0B0),
    ),
  };

  static CategoryInfo get(String key) {
    return all[key] ?? all[Categories.other]!;
  }

  static List<CategoryInfo> get expenses =>
      all.values.where((c) => c.isExpense).toList();

  static List<CategoryInfo> get incomes =>
      all.values.where((c) => !c.isExpense).toList();
}
