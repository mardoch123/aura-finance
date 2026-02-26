import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typographie Aura Finance
/// - Playfair Display pour les titres (équivalent Canela)
/// - DM Sans pour le body text (rounded, moderne)
class AuraTypography {
  AuraTypography._();

  // ═══════════════════════════════════════════════════════════
  // FAMILLES DE POLICES
  // ═══════════════════════════════════════════════════════════

  static TextStyle get _playfairDisplay => GoogleFonts.playfairDisplay();
  static TextStyle get _dmSans => GoogleFonts.dmSans();

  // ═══════════════════════════════════════════════════════════
  // TAILLES DE POLICE
  // ═══════════════════════════════════════════════════════════

  static const double fontSizeXXL = 48.0;
  static const double fontSizeXL = 36.0;
  static const double fontSizeL = 28.0;
  static const double fontSizeML = 22.0;
  static const double fontSizeM = 17.0;
  static const double fontSizeS = 14.0;
  static const double fontSizeXS = 12.0;
  static const double fontSizeXXS = 10.0;

  // ═══════════════════════════════════════════════════════════
  // ESPACEMENT DES LETTRES
  // ═══════════════════════════════════════════════════════════

  static const double letterSpacingLuxury = 1.2;
  static const double letterSpacingWide = 0.8;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingTight = -0.5;

  // ═══════════════════════════════════════════════════════════
  // HAUTEURS DE LIGNE
  // ═══════════════════════════════════════════════════════════

  static const double lineHeightTight = 1.1;
  static const double lineHeightNormal = 1.3;
  static const double lineHeightRelaxed = 1.5;
  static const double lineHeightLoose = 1.8;

  // ═══════════════════════════════════════════════════════════
  // TITRES - Playfair Display
  // ═══════════════════════════════════════════════════════════

  /// Titre Hero - pour les grands montants, balances
  static TextStyle get hero => _playfairDisplay.copyWith(
        fontSize: fontSizeXXL,
        fontWeight: FontWeight.w300,
        letterSpacing: letterSpacingLuxury,
        height: lineHeightTight,
      );

  /// Titre XXL - pour les headers principaux
  static TextStyle get h1 => _playfairDisplay.copyWith(
        fontSize: fontSizeXL,
        fontWeight: FontWeight.w400,
        letterSpacing: letterSpacingLuxury,
        height: lineHeightTight,
      );

  /// Titre Large - pour les sections
  static TextStyle get h2 => _playfairDisplay.copyWith(
        fontSize: fontSizeL,
        fontWeight: FontWeight.w400,
        letterSpacing: letterSpacingWide,
        height: lineHeightNormal,
      );

  /// Titre Medium-Large
  static TextStyle get h3 => _playfairDisplay.copyWith(
        fontSize: fontSizeML,
        fontWeight: FontWeight.w500,
        letterSpacing: letterSpacingNormal,
        height: lineHeightNormal,
      );

  /// Titre Medium
  static TextStyle get h4 => _playfairDisplay.copyWith(
        fontSize: fontSizeM,
        fontWeight: FontWeight.w500,
        letterSpacing: letterSpacingNormal,
        height: lineHeightNormal,
      );

  // ═══════════════════════════════════════════════════════════
  // BODY TEXT - DM Sans
  // ═══════════════════════════════════════════════════════════

  /// Body Large - pour le texte principal
  static TextStyle get bodyLarge => _dmSans.copyWith(
        fontSize: fontSizeM,
        fontWeight: FontWeight.w400,
        letterSpacing: letterSpacingNormal,
        height: lineHeightRelaxed,
      );

  /// Body Medium - texte standard
  static TextStyle get bodyMedium => _dmSans.copyWith(
        fontSize: fontSizeS,
        fontWeight: FontWeight.w400,
        letterSpacing: letterSpacingNormal,
        height: lineHeightRelaxed,
      );

  /// Body Small - pour les légendes
  static TextStyle get bodySmall => _dmSans.copyWith(
        fontSize: fontSizeXS,
        fontWeight: FontWeight.w400,
        letterSpacing: letterSpacingNormal,
        height: lineHeightNormal,
      );

  // ═══════════════════════════════════════════════════════════
  // LABELS & BUTTONS
  // ═══════════════════════════════════════════════════════════

  /// Label Large - boutons principaux
  static TextStyle get labelLarge => _dmSans.copyWith(
        fontSize: fontSizeM,
        fontWeight: FontWeight.w600,
        letterSpacing: letterSpacingWide,
        height: lineHeightNormal,
      );

  /// Label Medium - boutons secondaires
  static TextStyle get labelMedium => _dmSans.copyWith(
        fontSize: fontSizeS,
        fontWeight: FontWeight.w600,
        letterSpacing: letterSpacingNormal,
        height: lineHeightNormal,
      );

  /// Label Small - tags, chips
  static TextStyle get labelSmall => _dmSans.copyWith(
        fontSize: fontSizeXS,
        fontWeight: FontWeight.w600,
        letterSpacing: letterSpacingWide,
        height: lineHeightNormal,
      );

  // ═══════════════════════════════════════════════════════════
  // MONTANTS & CHIFFRES
  // ═══════════════════════════════════════════════════════════

  /// Grand montant - pour les balances
  static TextStyle get amountLarge => _dmSans.copyWith(
        fontSize: fontSizeXL,
        fontWeight: FontWeight.w300,
        letterSpacing: letterSpacingTight,
        height: lineHeightTight,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Montant moyen - pour les transactions
  static TextStyle get amountMedium => _dmSans.copyWith(
        fontSize: fontSizeL,
        fontWeight: FontWeight.w400,
        letterSpacing: letterSpacingTight,
        height: lineHeightTight,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Petit montant - pour les détails
  static TextStyle get amountSmall => _dmSans.copyWith(
        fontSize: fontSizeM,
        fontWeight: FontWeight.w500,
        letterSpacing: letterSpacingNormal,
        height: lineHeightNormal,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // ═══════════════════════════════════════════════════════════
  // SPÉCIAUX
  // ═══════════════════════════════════════════════════════════

  /// Caption - pour les métadonnées
  static TextStyle get caption => _dmSans.copyWith(
        fontSize: fontSizeXXS,
        fontWeight: FontWeight.w500,
        letterSpacing: letterSpacingWide,
        height: lineHeightNormal,
      );

  /// Overline - pour les labels en majuscules
  static TextStyle get overline => _dmSans.copyWith(
        fontSize: fontSizeXXS,
        fontWeight: FontWeight.w600,
        letterSpacing: letterSpacingLuxury,
        height: lineHeightNormal,
        textBaseline: TextBaseline.alphabetic,
      );

  /// Monospace - pour les codes, IDs
  static TextStyle get mono => _dmSans.copyWith(
        fontSize: fontSizeXS,
        fontWeight: FontWeight.w500,
        letterSpacing: letterSpacingNormal,
        height: lineHeightNormal,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

/// Extension pour faciliter l'utilisation des styles
extension TextStyleExtension on TextStyle {
  /// Applique une couleur au style
  TextStyle withColor(Color color) => copyWith(color: color);

  /// Rend le texte en gras
  TextStyle get bold => copyWith(fontWeight: FontWeight.w700);

  /// Rend le texte semi-gras
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);

  /// Rend le texte medium
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);

  /// Rend le texte light
  TextStyle get light => copyWith(fontWeight: FontWeight.w300);
}
