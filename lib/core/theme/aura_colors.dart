import 'package:flutter/material.dart';

/// Palette de couleurs Aura Finance - Design Apple Luxury Style
/// Basée sur un thème ambre/warm orange avec glassmorphism
class AuraColors {
  AuraColors._();

  // ═══════════════════════════════════════════════════════════
  // COULEURS PRINCIPALES
  // ═══════════════════════════════════════════════════════════

  /// Fond crème chaud - couleur de base de l'application
  static const Color auraBackground = Color(0xFFF5E6D0);

  /// Ambre principal - couleur d'accent principale
  static const Color auraAmber = Color(0xFFE8A86C);

  /// Ambre profond - pour les dégradés et accents
  static const Color auraDeep = Color(0xFFC4714A);

  /// Brun luxe - pour le texte et les éléments sombres
  static const Color auraDark = Color(0xFF8B5A3A);

  // ═══════════════════════════════════════════════════════════
  // GLASSMORPHISM
  // ═══════════════════════════════════════════════════════════

  /// Blanc 15% d'opacité - pour les cartes glassmorphism
  static const Color auraGlass = Color(0x26FFFFFF);

  /// Blanc 25% d'opacité - pour les cartes glassmorphism plus prononcées
  static const Color auraGlassStrong = Color(0x40FFFFFF);

  /// Blanc 40% d'opacité - pour les bordures et séparations
  static const Color auraGlassBorder = Color(0x66FFFFFF);

  // ═══════════════════════════════════════════════════════════
  // TEXTE
  // ═══════════════════════════════════════════════════════════

  /// Texte principal - blanc pur
  static const Color auraTextPrimary = Color(0xFFFFFFFF);

  /// Texte secondaire - blanc 80% d'opacité
  static const Color auraTextSecondary = Color(0xCCFFFFFF);

  /// Texte tertiaire - blanc 60% d'opacité
  static const Color auraTextTertiary = Color(0x99FFFFFF);

  /// Texte sombre - pour les fonds clairs
  static const Color auraTextDark = Color(0xFF2D2D2D);

  /// Texte sombre secondaire
  static const Color auraTextDarkSecondary = Color(0xFF666666);

  // ═══════════════════════════════════════════════════════════
  // ACCENTS
  // ═══════════════════════════════════════════════════════════

  /// Or doux - pour les éléments premium
  static const Color auraAccentGold = Color(0xFFF0C080);

  /// Or brillant - pour les highlights
  static const Color auraAccentGoldBright = Color(0xFFFFD700);

  // ═══════════════════════════════════════════════════════════
  // ÉTATS
  // ═══════════════════════════════════════════════════════════

  /// Vert succès - transactions positives, confirmations
  static const Color auraGreen = Color(0xFF7DC983);

  /// Vert clair - pour les variations
  static const Color auraGreenLight = Color(0xFFA8E0AC);

  /// Rouge alerte - transactions négatives, erreurs
  static const Color auraRed = Color(0xFFE07070);

  /// Rouge profond - pour les alertes importantes
  static const Color auraRedDeep = Color(0xFFC45050);

  /// Orange attention - vigilance, avertissements
  static const Color auraOrange = Color(0xFFF0A060);

  /// Jaune info - notifications informatives
  static const Color auraYellow = Color(0xFFF5D080);

  // ═══════════════════════════════════════════════════════════
  // DÉGRADÉS
  // ═══════════════════════════════════════════════════════════

  /// Dégradé principal ambre
  static const LinearGradient gradientAmber = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [auraAmber, auraDeep],
  );

  /// Dégradé ambre foncé
  static const LinearGradient gradientDeep = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [auraDeep, auraDark],
  );

  /// Dégradé glassmorphism
  static const LinearGradient gradientGlass = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [auraGlass, Color(0x10FFFFFF)],
  );

  /// Dégradé glassmorphism fort
  static const LinearGradient gradientGlassStrong = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [auraGlassStrong, auraGlass],
  );

  /// Dégradé doré premium
  static const LinearGradient gradientGold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [auraAccentGold, auraAmber],
  );

  // ═══════════════════════════════════════════════════════════
  // CATÉGORIES DE DÉPENSES
  // ═══════════════════════════════════════════════════════════

  static const Map<String, Color> categoryColors = {
    'food': Color(0xFFE8A86C),
    'transport': Color(0xFF7DC983),
    'housing': Color(0xFFC4714A),
    'entertainment': Color(0xFFF0C080),
    'shopping': Color(0xFFE07070),
    'health': Color(0xFF7EC8E3),
    'education': Color(0xFFB8A9C9),
    'travel': Color(0xFF98D8C8),
    'utilities': Color(0xFFF5D080),
    'subscriptions': Color(0xFFD4A5A5),
    'income': Color(0xFF7DC983),
    'other': Color(0xFFB0B0B0),
  };
}
