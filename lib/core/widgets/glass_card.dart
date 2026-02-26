import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/aura_colors.dart';
import '../theme/aura_dimensions.dart';

/// Widget GlassCard - Carte avec effet glassmorphism
/// 
/// Usage:
/// ```dart
/// GlassCard(
///   child: Text('Contenu'),
/// )
/// ```
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.margin,
    this.blurStrength = 24.0,
    this.gradient,
    this.borderColor,
    this.shadow = AuraDimensions.shadowGlass,
    this.width,
    this.height,
    this.onTap,
  });

  final Widget child;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blurStrength;
  final Gradient? gradient;
  final Color? borderColor;
  final List<BoxShadow>? shadow;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? AuraDimensions.radiusL;
    final effectiveGradient = gradient ?? AuraColors.gradientGlass;
    final effectiveBorderColor = borderColor ?? AuraColors.auraGlassBorder;

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(effectiveBorderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurStrength,
          sigmaY: blurStrength,
        ),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? AuraDimensions.paddingM,
          decoration: BoxDecoration(
            gradient: effectiveGradient,
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            border: Border.all(
              color: effectiveBorderColor,
              width: AuraDimensions.borderWidthNormal,
            ),
            boxShadow: shadow,
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    if (onTap != null) {
      card = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.translucent,
        child: card,
      );
    }

    return card;
  }
}

/// Variante GlassCardDark avec gradient plus sombre
class GlassCardDark extends StatelessWidget {
  const GlassCardDark({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.margin,
    this.blurStrength = 24.0,
    this.shadow = AuraDimensions.shadowMedium,
    this.width,
    this.height,
    this.onTap,
  });

  final Widget child;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blurStrength;
  final List<BoxShadow>? shadow;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      blurStrength: blurStrength,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x40FFFFFF),
          Color(0x20FFFFFF),
        ],
      ),
      borderColor: const Color(0x40FFFFFF),
      shadow: shadow,
      width: width,
      height: height,
      onTap: onTap,
      child: child,
    );
  }
}

/// Variante GlassCardAccent avec couleur d'accent
class GlassCardAccent extends StatelessWidget {
  const GlassCardAccent({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.margin,
    this.blurStrength = 24.0,
    this.accentColor,
    this.shadow = AuraDimensions.shadowGlass,
    this.width,
    this.height,
    this.onTap,
  });

  final Widget child;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blurStrength;
  final Color? accentColor;
  final List<BoxShadow>? shadow;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveAccentColor = accentColor ?? AuraColors.auraAmber;

    return GlassCard(
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      blurStrength: blurStrength,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          effectiveAccentColor.withOpacity(0.3),
          effectiveAccentColor.withOpacity(0.1),
        ],
      ),
      borderColor: effectiveAccentColor.withOpacity(0.5),
      shadow: shadow,
      width: width,
      height: height,
      onTap: onTap,
      child: child,
    );
  }
}

/// Variante GlassCardGradient avec dégradé personnalisé
class GlassCardGradient extends StatelessWidget {
  const GlassCardGradient({
    super.key,
    required this.child,
    required this.gradient,
    this.borderRadius,
    this.padding,
    this.margin,
    this.blurStrength = 24.0,
    this.borderColor,
    this.shadow = AuraDimensions.shadowGlass,
    this.width,
    this.height,
    this.onTap,
  });

  final Widget child;
  final Gradient gradient;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blurStrength;
  final Color? borderColor;
  final List<BoxShadow>? shadow;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      blurStrength: blurStrength,
      gradient: gradient,
      borderColor: borderColor,
      shadow: shadow,
      width: width,
      height: height,
      onTap: onTap,
      child: child,
    );
  }
}

/// Widget pour créer un effet glass sur toute la page
class GlassBackground extends StatelessWidget {
  const GlassBackground({
    super.key,
    required this.child,
    this.blurStrength = 20.0,
    this.gradient,
  });

  final Widget child;
  final double blurStrength;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? AuraColors.gradientAmber,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurStrength,
          sigmaY: blurStrength,
        ),
        child: child,
      ),
    );
  }
}

/// Widget pour overlay glass en bas de page (bottom sheet style)
class GlassBottomSheet extends StatelessWidget {
  const GlassBottomSheet({
    super.key,
    required this.child,
    this.borderRadius = AuraDimensions.radiusXXL,
    this.padding = AuraDimensions.paddingL,
    this.blurStrength = 24.0,
    this.maxHeight,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double blurStrength;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(borderRadius),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurStrength,
          sigmaY: blurStrength,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: maxHeight ?? MediaQuery.of(context).size.height * 0.8,
          ),
          padding: padding,
          decoration: BoxDecoration(
            gradient: AuraColors.gradientGlassStrong,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(borderRadius),
            ),
            border: const Border(
              top: BorderSide(
                color: AuraColors.auraGlassBorder,
                width: AuraDimensions.borderWidthNormal,
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
