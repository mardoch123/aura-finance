import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Extension pour accéder facilement aux traductions dans le contexte
extension AppLocalizationsExtension on BuildContext {
  /// Récupère les traductions
  AppLocalizations get l10n => AppLocalizations.of(this)!;
  
  /// Récupère la locale actuelle
  Locale get currentLocale => Localizations.localeOf(this);
  
  /// Vérifie si la langue actuelle est le français
  bool get isFrench => currentLocale.languageCode == 'fr';
  
  /// Vérifie si la langue actuelle est l'anglais
  bool get isEnglish => currentLocale.languageCode == 'en';
}

/// Helper pour obtenir le nom de catégorie traduit
String getCategoryName(BuildContext context, String category) {
  final l10n = context.l10n;
  switch (category) {
    case 'food':
      return l10n.categoryFood;
    case 'transport':
      return l10n.categoryTransport;
    case 'housing':
      return l10n.categoryHousing;
    case 'entertainment':
      return l10n.categoryEntertainment;
    case 'shopping':
      return l10n.categoryShopping;
    case 'health':
      return l10n.categoryHealth;
    case 'education':
      return l10n.categoryEducation;
    case 'utilities':
      return l10n.categoryUtilities;
    case 'salary':
      return l10n.categorySalary;
    case 'other':
      return l10n.categoryOther;
    default:
      return category;
  }
}

/// Helper pour obtenir le nom du filtre traduit
String getFilterName(BuildContext context, String filter) {
  final l10n = context.l10n;
  switch (filter) {
    case 'all':
      return l10n.filterAll;
    case 'vampire':
      return l10n.filterVampire;
    case 'prediction':
      return l10n.filterPrediction;
    case 'tip':
      return l10n.filterTip;
    case 'achievement':
      return l10n.filterAchievement;
    default:
      return filter;
  }
}
