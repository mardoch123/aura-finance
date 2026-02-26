import 'package:flutter/material.dart';

/// Dimensions et espacements Aura Finance
/// Design system cohérent pour tous les composants
class AuraDimensions {
  AuraDimensions._();

  // ═══════════════════════════════════════════════════════════
  // BORDER RADIUS - Squircle Apple Style
  // ═══════════════════════════════════════════════════════════

  static const double radiusXS = 8.0;
  static const double radiusS = 14.0;
  static const double radiusM = 22.0;
  static const double radiusL = 32.0;
  static const double radiusXL = 44.0;
  static const double radiusXXL = 56.0;
  static const double radiusFull = 9999.0;

  // ═══════════════════════════════════════════════════════════
  // ESPACEMENTS
  // ═══════════════════════════════════════════════════════════

  static const double spaceXXS = 2.0;
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 16.0;
  static const double spaceL = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;
  static const double spaceXXXL = 64.0;

  // ═══════════════════════════════════════════════════════════
  // PADDINGS
  // ═══════════════════════════════════════════════════════════

  static const EdgeInsets paddingXXS = EdgeInsets.all(spaceXXS);
  static const EdgeInsets paddingXS = EdgeInsets.all(spaceXS);
  static const EdgeInsets paddingS = EdgeInsets.all(spaceS);
  static const EdgeInsets paddingM = EdgeInsets.all(spaceM);
  static const EdgeInsets paddingL = EdgeInsets.all(spaceL);
  static const EdgeInsets paddingXL = EdgeInsets.all(spaceXL);
  static const EdgeInsets paddingXXL = EdgeInsets.all(spaceXXL);

  // ═══════════════════════════════════════════════════════════
  // PADDINGS HORIZONTAL
  // ═══════════════════════════════════════════════════════════

  static const EdgeInsets paddingHorizontalS = EdgeInsets.symmetric(horizontal: spaceS);
  static const EdgeInsets paddingHorizontalM = EdgeInsets.symmetric(horizontal: spaceM);
  static const EdgeInsets paddingHorizontalL = EdgeInsets.symmetric(horizontal: spaceL);
  static const EdgeInsets paddingHorizontalXL = EdgeInsets.symmetric(horizontal: spaceXL);

  // ═══════════════════════════════════════════════════════════
  // PADDINGS VERTICAL
  // ═══════════════════════════════════════════════════════════

  static const EdgeInsets paddingVerticalXS = EdgeInsets.symmetric(vertical: spaceXS);
  static const EdgeInsets paddingVerticalS = EdgeInsets.symmetric(vertical: spaceS);
  static const EdgeInsets paddingVerticalM = EdgeInsets.symmetric(vertical: spaceM);
  static const EdgeInsets paddingVerticalL = EdgeInsets.symmetric(vertical: spaceL);

  // ═══════════════════════════════════════════════════════════
  // SIZES DE COMPOSANTS
  // ═══════════════════════════════════════════════════════════

  /// Hauteur des boutons
  static const double buttonHeight = 56.0;
  static const double buttonHeightSmall = 44.0;
  static const double buttonHeightLarge = 64.0;

  /// Largeur minimale des boutons
  static const double buttonMinWidth = 120.0;

  /// Taille des icônes
  static const double iconSizeXS = 16.0;
  static const double iconSizeS = 20.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  static const double iconSizeXL = 48.0;

  /// Taille des avatars
  static const double avatarSizeXS = 24.0;
  static const double avatarSizeS = 32.0;
  static const double avatarSizeM = 48.0;
  static const double avatarSizeL = 64.0;
  static const double avatarSizeXL = 96.0;

  /// Hauteur des cards
  static const double cardHeightSmall = 120.0;
  static const double cardHeightMedium = 180.0;
  static const double cardHeightLarge = 240.0;

  /// Hauteur des list items
  static const double listItemHeight = 72.0;
  static const double listItemHeightSmall = 56.0;

  // ═══════════════════════════════════════════════════════════
  // ÉLÉVATIONS & OMBRES
  // ═══════════════════════════════════════════════════════════

  static const double elevationXS = 2.0;
  static const double elevationS = 4.0;
  static const double elevationM = 8.0;
  static const double elevationL = 16.0;
  static const double elevationXL = 32.0;

  /// Ombre glassmorphism standard
  static const List<BoxShadow> shadowGlass = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 32.0,
      offset: Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 8.0,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  /// Ombre légère
  static const List<BoxShadow> shadowLight = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 16.0,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  /// Ombre moyenne
  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 24.0,
      offset: Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  /// Ombre forte
  static const List<BoxShadow> shadowHeavy = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 48.0,
      offset: Offset(0, 16),
      spreadRadius: 0,
    ),
  ];

  // ═══════════════════════════════════════════════════════════
  // BORDURES
  // ═══════════════════════════════════════════════════════════

  static const double borderWidthThin = 0.5;
  static const double borderWidthNormal = 1.0;
  static const double borderWidthThick = 2.0;

  // ═══════════════════════════════════════════════════════════
  // ANIMATIONS
  // ═══════════════════════════════════════════════════════════

  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationVerySlow = Duration(milliseconds: 800);

  static const Curve curveDefault = Curves.easeOutCubic;
  static const Curve curveBounce = Curves.elasticOut;
  static const Curve curveExpo = Curves.easeOutExpo;
  static const Curve curveSpring = Curves.fastOutSlowIn;

  // ═══════════════════════════════════════════════════════════
  // LAYOUT
  // ═══════════════════════════════════════════════════════════

  /// Largeur maximale du contenu
  static const double maxContentWidth = 480.0;

  /// Hauteur de la bottom navigation
  static const double bottomNavHeight = 80.0;

  /// Hauteur de l'app bar
  static const double appBarHeight = 64.0;

  /// Safe area bottom pour les devices avec notch
  static const double safeAreaBottom = 34.0;

  /// Safe area top pour les devices avec notch
  static const double safeAreaTop = 44.0;

  // ═══════════════════════════════════════════════════════════
  // GRID
  // ═══════════════════════════════════════════════════════════

  static const double gridSpacing = 16.0;
  static const int gridColumns = 4;
  static const double gridAspectRatio = 1.0;
}
