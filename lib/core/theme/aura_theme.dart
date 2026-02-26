import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'aura_colors.dart';
import 'aura_typography.dart';
import 'aura_dimensions.dart';

/// Theme principal d'Aura Finance
/// Design Apple Luxury Style avec glassmorphism
class AuraTheme {
  AuraTheme._();

  // ═══════════════════════════════════════════════════════════
  // THEME CLAIR (Principal)
  // ═══════════════════════════════════════════════════════════

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // ═══════════════════════════════════════════════════════
      // COULEURS
      // ═══════════════════════════════════════════════════════
      
      scaffoldBackgroundColor: AuraColors.auraBackground,
      primaryColor: AuraColors.auraAmber,
      colorScheme: const ColorScheme.light(
        primary: AuraColors.auraAmber,
        onPrimary: AuraColors.auraTextPrimary,
        secondary: AuraColors.auraDeep,
        onSecondary: AuraColors.auraTextPrimary,
        surface: AuraColors.auraGlass,
        onSurface: AuraColors.auraTextPrimary,
        error: AuraColors.auraRed,
        onError: AuraColors.auraTextPrimary,
        background: AuraColors.auraBackground,
        onBackground: AuraColors.auraTextDark,
        surfaceTint: AuraColors.auraAmber,
      ),
      
      // ═══════════════════════════════════════════════════════
      // TYPOGRAPHIE
      // ═══════════════════════════════════════════════════════
      
      textTheme: TextTheme(
        displayLarge: AuraTypography.hero.withColor(AuraColors.auraTextDark),
        displayMedium: AuraTypography.h1.withColor(AuraColors.auraTextDark),
        displaySmall: AuraTypography.h2.withColor(AuraColors.auraTextDark),
        headlineLarge: AuraTypography.h2.withColor(AuraColors.auraTextDark),
        headlineMedium: AuraTypography.h3.withColor(AuraColors.auraTextDark),
        headlineSmall: AuraTypography.h4.withColor(AuraColors.auraTextDark),
        titleLarge: AuraTypography.h3.withColor(AuraColors.auraTextDark),
        titleMedium: AuraTypography.labelLarge.withColor(AuraColors.auraTextDark),
        titleSmall: AuraTypography.labelMedium.withColor(AuraColors.auraTextDarkSecondary),
        bodyLarge: AuraTypography.bodyLarge.withColor(AuraColors.auraTextDark),
        bodyMedium: AuraTypography.bodyMedium.withColor(AuraColors.auraTextDark),
        bodySmall: AuraTypography.bodySmall.withColor(AuraColors.auraTextDarkSecondary),
        labelLarge: AuraTypography.labelLarge.withColor(AuraColors.auraTextDark),
        labelMedium: AuraTypography.labelMedium.withColor(AuraColors.auraTextDarkSecondary),
        labelSmall: AuraTypography.labelSmall.withColor(AuraColors.auraTextDarkSecondary),
      ),
      
      // ═══════════════════════════════════════════════════════
      // APP BAR
      // ═══════════════════════════════════════════════════════
      
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: AuraColors.auraTextDark,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AuraTypography.h3.withColor(AuraColors.auraTextDark),
        toolbarHeight: AuraDimensions.appBarHeight,
      ),
      
      // ═══════════════════════════════════════════════════════
      // BOTTOM NAVIGATION
      // ═══════════════════════════════════════════════════════
      
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AuraColors.auraGlass,
        selectedItemColor: AuraColors.auraAmber,
        unselectedItemColor: AuraColors.auraTextDarkSecondary,
        selectedLabelStyle: AuraTypography.labelSmall,
        unselectedLabelStyle: AuraTypography.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      
      // ═══════════════════════════════════════════════════════
      // BOUTONS
      // ═══════════════════════════════════════════════════════
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AuraColors.auraAmber,
          foregroundColor: AuraColors.auraTextPrimary,
          elevation: 0,
          minimumSize: const Size(AuraDimensions.buttonMinWidth, AuraDimensions.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AuraDimensions.spaceL,
            vertical: AuraDimensions.spaceM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
          ),
          textStyle: AuraTypography.labelLarge,
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AuraColors.auraDeep,
          padding: const EdgeInsets.symmetric(
            horizontal: AuraDimensions.spaceM,
            vertical: AuraDimensions.spaceS,
          ),
          textStyle: AuraTypography.labelMedium,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AuraColors.auraDeep,
          side: const BorderSide(color: AuraColors.auraGlassBorder),
          minimumSize: const Size(AuraDimensions.buttonMinWidth, AuraDimensions.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AuraDimensions.spaceL,
            vertical: AuraDimensions.spaceM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
          ),
          textStyle: AuraTypography.labelLarge,
        ),
      ),
      
      // ═══════════════════════════════════════════════════════
      // INPUTS
      // ═══════════════════════════════════════════════════════
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AuraColors.auraGlass,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AuraDimensions.spaceM,
          vertical: AuraDimensions.spaceM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
          borderSide: const BorderSide(color: AuraColors.auraGlassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
          borderSide: const BorderSide(color: AuraColors.auraAmber, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
          borderSide: const BorderSide(color: AuraColors.auraRed),
        ),
        labelStyle: AuraTypography.bodyMedium.withColor(AuraColors.auraTextDarkSecondary),
        hintStyle: AuraTypography.bodyMedium.withColor(AuraColors.auraTextDarkSecondary),
        errorStyle: AuraTypography.bodySmall.withColor(AuraColors.auraRed),
      ),
      
      // ═══════════════════════════════════════════════════════
      // CARDS
      // ═══════════════════════════════════════════════════════
      
      cardTheme: CardTheme(
        elevation: 0,
        color: AuraColors.auraGlass,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
        ),
        margin: EdgeInsets.zero,
      ),
      
      // ═══════════════════════════════════════════════════════
      // CHIPS
      // ═══════════════════════════════════════════════════════
      
      chipTheme: ChipThemeData(
        backgroundColor: AuraColors.auraGlass,
        selectedColor: AuraColors.auraAmber,
        labelStyle: AuraTypography.labelSmall.withColor(AuraColors.auraTextDark),
        secondaryLabelStyle: AuraTypography.labelSmall.withColor(AuraColors.auraTextPrimary),
        padding: const EdgeInsets.symmetric(
          horizontal: AuraDimensions.spaceS,
          vertical: AuraDimensions.spaceXS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
        ),
      ),
      
      // ═══════════════════════════════════════════════════════
      // DIALOGS
      // ═══════════════════════════════════════════════════════
      
      dialogTheme: DialogTheme(
        backgroundColor: AuraColors.auraGlassStrong,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AuraDimensions.radiusXL),
        ),
        titleTextStyle: AuraTypography.h3.withColor(AuraColors.auraTextPrimary),
        contentTextStyle: AuraTypography.bodyLarge.withColor(AuraColors.auraTextSecondary),
      ),
      
      // ═══════════════════════════════════════════════════════
      // BOTTOM SHEETS
      // ═══════════════════════════════════════════════════════
      
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AuraColors.auraGlassStrong,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AuraDimensions.radiusXXL),
          ),
        ),
      ),
      
      // ═══════════════════════════════════════════════════════
      // SNACKBARS
      // ═══════════════════════════════════════════════════════
      
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AuraColors.auraDark,
        contentTextStyle: AuraTypography.bodyMedium.withColor(AuraColors.auraTextPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: AuraDimensions.elevationM,
      ),
      
      // ═══════════════════════════════════════════════════════
      // DIVIDERS
      // ═══════════════════════════════════════════════════════
      
      dividerTheme: const DividerThemeData(
        color: AuraColors.auraGlassBorder,
        thickness: 0.5,
        space: AuraDimensions.spaceM,
      ),
      
      // ═══════════════════════════════════════════════════════
      // SLIDERS
      // ═══════════════════════════════════════════════════════
      
      sliderTheme: SliderThemeData(
        activeTrackColor: AuraColors.auraAmber,
        inactiveTrackColor: AuraColors.auraGlass,
        thumbColor: AuraColors.auraAmber,
        overlayColor: AuraColors.auraAmber.withOpacity(0.2),
        trackHeight: 4,
      ),
      
      // ═══════════════════════════════════════════════════════
      // SWITCHES
      // ═══════════════════════════════════════════════════════
      
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AuraColors.auraAmber;
          }
          return AuraColors.auraTextDarkSecondary;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AuraColors.auraAmber.withOpacity(0.5);
          }
          return AuraColors.auraGlass;
        }),
      ),
      
      // ═══════════════════════════════════════════════════════
      // PROGRESS INDICATORS
      // ═══════════════════════════════════════════════════════
      
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AuraColors.auraAmber,
        linearTrackColor: AuraColors.auraGlass,
        circularTrackColor: AuraColors.auraGlass,
      ),
      
      // ═══════════════════════════════════════════════════════
      // SCROLLBAR
      // ═══════════════════════════════════════════════════════
      
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: MaterialStateProperty.all(AuraColors.auraAmber.withOpacity(0.5)),
        trackColor: MaterialStateProperty.all(AuraColors.auraGlass),
        radius: const Radius.circular(AuraDimensions.radiusXS),
        thickness: MaterialStateProperty.all(4),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // THEME SOMBRE (Optionnel)
  // ═══════════════════════════════════════════════════════════

  static ThemeData get darkTheme {
    return lightTheme.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AuraColors.auraDark,
      colorScheme: const ColorScheme.dark(
        primary: AuraColors.auraAmber,
        onPrimary: AuraColors.auraTextPrimary,
        secondary: AuraColors.auraDeep,
        onSecondary: AuraColors.auraTextPrimary,
        surface: AuraColors.auraGlass,
        onSurface: AuraColors.auraTextPrimary,
        error: AuraColors.auraRed,
        onError: AuraColors.auraTextPrimary,
        background: AuraColors.auraDark,
        onBackground: AuraColors.auraTextPrimary,
      ),
      textTheme: TextTheme(
        displayLarge: AuraTypography.hero.withColor(AuraColors.auraTextPrimary),
        displayMedium: AuraTypography.h1.withColor(AuraColors.auraTextPrimary),
        displaySmall: AuraTypography.h2.withColor(AuraColors.auraTextPrimary),
        headlineLarge: AuraTypography.h2.withColor(AuraColors.auraTextPrimary),
        headlineMedium: AuraTypography.h3.withColor(AuraColors.auraTextPrimary),
        headlineSmall: AuraTypography.h4.withColor(AuraColors.auraTextPrimary),
        titleLarge: AuraTypography.h3.withColor(AuraColors.auraTextPrimary),
        titleMedium: AuraTypography.labelLarge.withColor(AuraColors.auraTextPrimary),
        titleSmall: AuraTypography.labelMedium.withColor(AuraColors.auraTextSecondary),
        bodyLarge: AuraTypography.bodyLarge.withColor(AuraColors.auraTextPrimary),
        bodyMedium: AuraTypography.bodyMedium.withColor(AuraColors.auraTextPrimary),
        bodySmall: AuraTypography.bodySmall.withColor(AuraColors.auraTextSecondary),
        labelLarge: AuraTypography.labelLarge.withColor(AuraColors.auraTextPrimary),
        labelMedium: AuraTypography.labelMedium.withColor(AuraColors.auraTextSecondary),
        labelSmall: AuraTypography.labelSmall.withColor(AuraColors.auraTextSecondary),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: AuraColors.auraTextPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AuraTypography.h3.withColor(AuraColors.auraTextPrimary),
        toolbarHeight: AuraDimensions.appBarHeight,
      ),
    );
  }
}
