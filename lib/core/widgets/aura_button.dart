import 'package:flutter/material.dart';
import '../theme/aura_colors.dart';
import '../theme/aura_typography.dart';
import '../theme/aura_dimensions.dart';
import '../haptics/haptic_service.dart';
import 'glass_card.dart';
import 'aura_squircle.dart';

/// Bouton principal Aura avec animation de pression
///
/// Usage:
/// ```dart
/// AuraButton(
///   label: 'Confirmer',
///   onPressed: () {},
/// )
/// ```
class AuraButton extends StatefulWidget {
  const AuraButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AuraButtonVariant.filled,
    this.size = AuraButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
    this.hapticType = HapticType.medium,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AuraButtonVariant variant;
  final AuraButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final double? width;
  final HapticType hapticType;

  @override
  State<AuraButton> createState() => _AuraButtonState();
}

class _AuraButtonState extends State<AuraButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.isDisabled || widget.isLoading) return;
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTap() {
    if (widget.isDisabled || widget.isLoading) return;

    switch (widget.hapticType) {
      case HapticType.light:
        HapticService.lightTap();
        break;
      case HapticType.medium:
        HapticService.mediumTap();
        break;
      case HapticType.heavy:
        HapticService.heavyTap();
        break;
      case HapticType.success:
        HapticService.success();
        break;
      case HapticType.error:
        HapticService.error();
        break;
    }

    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.isDisabled || widget.onPressed == null;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: isDisabled ? 0.5 : 1.0,
              child: child,
            ),
          );
        },
        child: _buildButton(),
      ),
    );
  }

  Widget _buildButton() {
    final height = switch (widget.size) {
      AuraButtonSize.small => AuraDimensions.buttonHeightSmall,
      AuraButtonSize.medium => AuraDimensions.buttonHeight,
      AuraButtonSize.large => AuraDimensions.buttonHeightLarge,
    };

    final textStyle = switch (widget.size) {
      AuraButtonSize.small => AuraTypography.labelMedium,
      AuraButtonSize.medium => AuraTypography.labelLarge,
      AuraButtonSize.large => AuraTypography.labelLarge.copyWith(fontSize: 18),
    };

    final padding = switch (widget.size) {
      AuraButtonSize.small => AuraDimensions.paddingHorizontalM,
      AuraButtonSize.medium => AuraDimensions.paddingHorizontalL,
      AuraButtonSize.large => AuraDimensions.paddingHorizontalL,
    };

    final iconSize = switch (widget.size) {
      AuraButtonSize.small => AuraDimensions.iconSizeS,
      AuraButtonSize.medium => AuraDimensions.iconSizeM,
      AuraButtonSize.large => AuraDimensions.iconSizeL,
    };

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.variant == AuraButtonVariant.filled
                    ? AuraColors.auraTextPrimary
                    : AuraColors.auraDeep,
              ),
            ),
          ),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: iconSize),
        ],
        if ((widget.icon != null || widget.isLoading) && widget.label.isNotEmpty)
          const SizedBox(width: AuraDimensions.spaceS),
        if (widget.label.isNotEmpty)
          Text(widget.label, style: textStyle),
      ],
    );

    switch (widget.variant) {
      case AuraButtonVariant.filled:
        return Container(
          width: widget.width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            gradient: AuraColors.gradientAmber,
            borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
            boxShadow: AuraDimensions.shadowMedium,
          ),
          child: Center(
            child: DefaultTextStyle(
              style: textStyle.copyWith(color: AuraColors.auraTextPrimary),
              child: content,
            ),
          ),
        );

      case AuraButtonVariant.outlined:
        return GlassCard(
          width: widget.width,
          height: height,
          padding: padding,
          borderRadius: AuraDimensions.radiusL,
          child: Center(
            child: DefaultTextStyle(
              style: textStyle.copyWith(color: AuraColors.auraDeep),
              child: content,
            ),
          ),
        );

      case AuraButtonVariant.ghost:
        return Container(
          width: widget.width,
          height: height,
          padding: padding,
          child: Center(
            child: DefaultTextStyle(
              style: textStyle.copyWith(color: AuraColors.auraDeep),
              child: content,
            ),
          ),
        );

      case AuraButtonVariant.glass:
        return GlassCard(
          width: widget.width,
          height: height,
          padding: padding,
          borderRadius: AuraDimensions.radiusL,
          gradient: AuraColors.gradientGlassStrong,
          child: Center(
            child: DefaultTextStyle(
              style: textStyle.copyWith(color: AuraColors.auraTextPrimary),
              child: content,
            ),
          ),
        );
    }
  }
}

/// Variantes de bouton
enum AuraButtonVariant {
  filled,
  outlined,
  ghost,
  glass,
}

/// Tailles de bouton
enum AuraButtonSize {
  small,
  medium,
  large,
}

/// Bouton avec icône circulaire
class AuraIconButton extends StatefulWidget {
  const AuraIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 56.0,
    this.backgroundColor,
    this.iconColor,
    this.isLoading = false,
    this.hapticType = HapticType.light,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool isLoading;
  final HapticType hapticType;

  @override
  State<AuraIconButton> createState() => _AuraIconButtonState();
}

class _AuraIconButtonState extends State<AuraIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.isLoading) return;

    switch (widget.hapticType) {
      case HapticType.light:
        HapticService.lightTap();
        break;
      case HapticType.medium:
        HapticService.mediumTap();
        break;
      case HapticType.heavy:
        HapticService.heavyTap();
        break;
      case HapticType.success:
        HapticService.success();
        break;
      case HapticType.error:
        HapticService.error();
        break;
    }

    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        _handleTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            gradient: AuraColors.gradientAmber,
            shape: BoxShape.circle,
            boxShadow: AuraDimensions.shadowMedium,
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: widget.size * 0.4,
                    height: widget.size * 0.4,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.iconColor ?? AuraColors.auraTextPrimary,
                      ),
                    ),
                  )
                : Icon(
                    widget.icon,
                    color: widget.iconColor ?? AuraColors.auraTextPrimary,
                    size: widget.size * 0.4,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Bouton flottant d'action (FAB)
class AuraFAB extends StatelessWidget {
  const AuraFAB({
    super.key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.isExtended = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? label;
  final bool isExtended;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        HapticService.mediumTap();
        onPressed?.call();
      },
      icon: Icon(icon),
      label: Text(label ?? ''),
      backgroundColor: AuraColors.auraAmber,
      foregroundColor: AuraColors.auraTextPrimary,
      elevation: AuraDimensions.elevationM,
      extendedIconLabelSpacing: AuraDimensions.spaceS,
    );
  }
}
