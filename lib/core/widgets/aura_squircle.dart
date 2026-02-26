import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';
import '../theme/aura_dimensions.dart';

/// Widget AuraSquircle - Forme squircle Apple Style
/// Utilise le package figma_squircle pour un rendu précis
///
/// Usage:
/// ```dart
/// AuraSquircle(
///   radius: AuraDimensions.radiusL,
///   child: Container(color: Colors.red),
/// )
/// ```
class AuraSquircle extends StatelessWidget {
  const AuraSquircle({
    super.key,
    required this.child,
    this.radius = AuraDimensions.radiusL,
    this.smoothing = 0.6,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
    this.elevation = 0,
    this.shadowColor,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.alignment,
    this.clipBehavior = Clip.antiAlias,
    this.onTap,
  });

  final Widget child;
  final double radius;
  final double smoothing;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double elevation;
  final Color? shadowColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final Clip clipBehavior;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget result = ClipSmoothRect(
      radius: SmoothBorderRadius(
        cornerRadius: radius,
        cornerSmoothing: smoothing,
      ),
      clipBehavior: clipBehavior,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        alignment: alignment,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: borderWidth > 0
              ? Border.all(
                  color: borderColor ?? Colors.transparent,
                  width: borderWidth,
                )
              : null,
        ),
        child: child,
      ),
    );

    if (elevation > 0) {
      result = Material(
        elevation: elevation,
        shadowColor: shadowColor,
        color: Colors.transparent,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: radius,
            cornerSmoothing: smoothing,
          ),
        ),
        child: result,
      );
    }

    if (margin != null) {
      result = Padding(padding: margin!, child: result);
    }

    if (onTap != null) {
      result = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.translucent,
        child: result,
      );
    }

    return result;
  }
}

/// Container avec bordure squircle
class AuraSquircleBorder extends StatelessWidget {
  const AuraSquircleBorder({
    super.key,
    required this.child,
    this.radius = AuraDimensions.radiusL,
    this.smoothing = 0.6,
    this.backgroundColor,
    this.borderColor = Colors.white,
    this.borderWidth = 1.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  final Widget child;
  final double radius;
  final double smoothing;
  final Color? backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    Widget result = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: ShapeDecoration(
        color: backgroundColor,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: radius,
            cornerSmoothing: smoothing,
          ),
          side: BorderSide(
            color: borderColor,
            width: borderWidth,
          ),
        ),
      ),
      child: child,
    );

    if (margin != null) {
      result = Padding(padding: margin!, child: result);
    }

    return result;
  }
}

/// Avatar squircle pour les photos de profil
class AuraSquircleAvatar extends StatelessWidget {
  const AuraSquircleAvatar({
    super.key,
    this.imageUrl,
    this.imageProvider,
    this.radius = AuraDimensions.avatarSizeM,
    this.smoothing = 0.6,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
    this.placeholder,
    this.onTap,
  });

  final String? imageUrl;
  final ImageProvider? imageProvider;
  final double radius;
  final double smoothing;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final Widget? placeholder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget avatar = AuraSquircle(
      radius: radius,
      smoothing: smoothing,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      width: radius * 2,
      height: radius * 2,
      onTap: onTap,
      child: imageProvider != null
          ? Image(
              image: imageProvider!,
              fit: BoxFit.cover,
              width: radius * 2,
              height: radius * 2,
            )
          : imageUrl != null
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  width: radius * 2,
                  height: radius * 2,
                  errorBuilder: (context, error, stackTrace) {
                    return placeholder ?? _defaultPlaceholder();
                  },
                )
              : placeholder ?? _defaultPlaceholder(),
    );

    return avatar;
  }

  Widget _defaultPlaceholder() {
    return Container(
      width: radius * 2,
      height: radius * 2,
      color: backgroundColor ?? Colors.grey[300],
      child: Icon(
        Icons.person,
        size: radius,
        color: Colors.grey[600],
      ),
    );
  }
}

/// Bouton squircle
class AuraSquircleButton extends StatelessWidget {
  const AuraSquircleButton({
    super.key,
    required this.child,
    this.onTap,
    this.radius = AuraDimensions.radiusM,
    this.smoothing = 0.6,
    this.backgroundColor,
    this.splashColor,
    this.padding = AuraDimensions.paddingM,
    this.margin,
    this.width,
    this.height,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final double smoothing;
  final Color? backgroundColor;
  final Color? splashColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    Widget button = Material(
      color: backgroundColor ?? Colors.transparent,
      borderRadius: SmoothBorderRadius(
        cornerRadius: radius,
        cornerSmoothing: smoothing,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: splashColor,
        child: Container(
          width: width,
          height: height,
          padding: padding,
          alignment: alignment,
          child: child,
        ),
      ),
    );

    button = ClipSmoothRect(
      radius: SmoothBorderRadius(
        cornerRadius: radius,
        cornerSmoothing: smoothing,
      ),
      child: button,
    );

    if (margin != null) {
      button = Padding(padding: margin!, child: button);
    }

    return button;
  }
}

/// Extension pour créer facilement des bordures squircle
extension SquircleBorderExtension on RoundedRectangleBorder {
  /// Convertit en SmoothRectangleBorder
  SmoothRectangleBorder toSquircle({double smoothing = 0.6}) {
    return SmoothRectangleBorder(
      borderRadius: SmoothBorderRadius(
        cornerRadius: borderRadius.resolve(TextDirection.ltr).topLeft.x,
        cornerSmoothing: smoothing,
      ),
      side: side,
    );
  }
}
