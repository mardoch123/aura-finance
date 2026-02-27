import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/aura_colors.dart';
import '../theme/aura_dimensions.dart';

/// Bouton avec micro-interactions premium
/// Press animation, scale, ripple effect
class InteractiveButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final BoxDecoration? decoration;
  final bool isEnabled;
  final Duration? animationDuration;

  const InteractiveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.decoration,
    this.isEnabled = true,
    this.animationDuration,
  });

  @override
  State<InteractiveButton> createState() => _InteractiveButtonState();
}

class _InteractiveButtonState extends State<InteractiveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration ?? const Duration(milliseconds: 100),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _pressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isEnabled ? (_) => _controller.forward() : null,
      onTapUp: widget.isEnabled ? (_) => _controller.reverse() : null,
      onTapCancel: widget.isEnabled ? () => _controller.reverse() : null,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              padding: widget.padding,
              decoration: widget.decoration?.copyWith(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1 * (1 - _pressAnimation.value)),
                    blurRadius: 10 * (1 - _pressAnimation.value),
                    offset: Offset(0, 2 * (1 - _pressAnimation.value)),
                  ),
                ],
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// Card avec micro-interactions au hover/tap
class InteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final BoxDecoration? decoration;
  final double elevation;
  final Duration? animationDuration;

  const InteractiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.decoration,
    this.elevation = 4,
    this.animationDuration,
  });

  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration ?? const Duration(milliseconds: 150),
      vsync: this,
    );

    _elevationAnimation = Tween<double>(begin: widget.elevation, end: widget.elevation + 4)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onTap != null ? (_) => _controller.reverse() : null,
      onTapCancel: widget.onTap != null ? () => _controller.reverse() : null,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: widget.padding,
              decoration: widget.decoration?.copyWith(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: _elevationAnimation.value,
                    offset: Offset(0, _elevationAnimation.value / 2),
                  ),
                ],
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// Switch avec animation fluide et haptique
class InteractiveSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;

  const InteractiveSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  @override
  State<InteractiveSwitch> createState() => _InteractiveSwitchState();
}

class _InteractiveSwitchState extends State<InteractiveSwitch>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    if (widget.value) {
      _controller.value = 1.0;
    }

    _positionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: AuraColors.auraGlass,
      end: AuraColors.auraAmber,
    ).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant InteractiveSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onChanged(!widget.value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: const TextStyle(
                color: AuraColors.auraTextDark,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 12),
          ],
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: 50,
                height: 30,
                decoration: BoxDecoration(
                  color: _colorAnimation.value,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: widget.value
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 26,
                        height: 26,
                        margin: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Slider avec feedback visuel et haptique
class InteractiveSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String? label;

  const InteractiveSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.label,
  });

  @override
  State<InteractiveSlider> createState() => _InteractiveSliderState();
}

class _InteractiveSliderState extends State<InteractiveSlider> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              color: AuraColors.auraTextDark,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onPanStart: (details) => setState(() => _isDragging = true),
              onPanEnd: (details) => setState(() => _isDragging = false),
              onPanUpdate: (details) {
                final position = details.localPosition.dx;
                final percentage = (position / constraints.maxWidth).clamp(0.0, 1.0);
                final newValue = widget.min + (widget.max - widget.min) * percentage;
                widget.onChanged(newValue);
              },
              onTapUp: (details) {
                final position = details.localPosition.dx;
                final percentage = (position / constraints.maxWidth).clamp(0.0, 1.0);
                final newValue = widget.min + (widget.max - widget.min) * percentage;
                widget.onChanged(newValue);
              },
              child: Container(
                height: 40,
                width: constraints.maxWidth,
                color: Colors.transparent,
                child: Stack(
                  children: [
                    // Track
                    Positioned(
                      top: 18,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AuraColors.auraGlass,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Progress
                    Positioned(
                      top: 18,
                      left: 0,
                      child: Container(
                        width: constraints.maxWidth * 
                               ((widget.value - widget.min) / (widget.max - widget.min)),
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AuraColors.auraAmber, AuraColors.auraDeep],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Thumb
                    Positioned(
                      left: constraints.maxWidth * 
                             ((widget.value - widget.min) / (widget.max - widget.min)) - 12,
                      top: 8,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _isDragging 
                              ? AuraColors.auraDeep 
                              : AuraColors.auraAmber,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isDragging 
                                      ? AuraColors.auraDeep 
                                      : AuraColors.auraAmber)
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Loader glassmorphique pour les états de chargement
class GlassLoader extends StatelessWidget {
  final String? message;
  final double size;

  const GlassLoader({
    super.key,
    this.message,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AuraDimensions.spaceL),
      decoration: BoxDecoration(
        color: AuraColors.auraGlass,
        borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
        border: Border.all(
          color: AuraColors.auraGlassBorder,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AuraColors.auraAmber),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style: const TextStyle(
                color: AuraColors.auraTextDark,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shimmer loader glassmorphique
class GlassShimmerLoader extends StatelessWidget {
  final double height;
  final double? width;

  const GlassShimmerLoader({
    super.key,
    this.height = 100,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AuraColors.auraGlass,
        borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
      )
          .animate(onPlay: (controller) => controller.repeat())
          .shimmer(
            duration: 1000.ms,
            color: AuraColors.auraGlass.withOpacity(0.5),
          );
  }
}
