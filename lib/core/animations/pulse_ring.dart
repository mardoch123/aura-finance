import 'package:flutter/material.dart';
import '../theme/aura_colors.dart';
import '../theme/aura_dimensions.dart';

/// Cercle qui pulse en boucle pour indiquer une activité en cours
/// (scan IA, chargement, etc.)
///
/// Usage:
/// ```dart
/// PulseRing(
///   size: 120,
///   color: AuraColors.auraAmber,
/// )
/// ```
class PulseRing extends StatefulWidget {
  const PulseRing({
    super.key,
    this.size = 120.0,
    this.color,
    this.ringWidth = 4.0,
    this.pulseScale = 1.3,
    this.duration = const Duration(milliseconds: 1500),
    this.child,
  });

  /// Taille du cercle
  final double size;

  /// Couleur du pulse (défaut: auraAmber)
  final Color? color;

  /// Épaisseur de l'anneau
  final double ringWidth;

  /// Échelle maximale du pulse (1.0 = pas de pulse, 2.0 = double taille)
  final double pulseScale;

  /// Durée d'un cycle de pulse
  final Duration duration;

  /// Widget enfant au centre
  final Widget? child;

  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pulseScale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AuraColors.auraAmber;

    return SizedBox(
      width: widget.size * widget.pulseScale,
      height: widget.size * widget.pulseScale,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Anneau pulse
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color,
                        width: widget.ringWidth,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Anneau fixe
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.3),
                width: widget.ringWidth,
              ),
            ),
            child: Center(child: widget.child),
          ),
        ],
      ),
    );
  }
}

/// Version avec double pulse (deux anneaux décalés)
class DoublePulseRing extends StatefulWidget {
  const DoublePulseRing({
    super.key,
    this.size = 120.0,
    this.color,
    this.ringWidth = 4.0,
    this.duration = const Duration(milliseconds: 2000),
    this.child,
  });

  final double size;
  final Color? color;
  final double ringWidth;
  final Duration duration;
  final Widget? child;

  @override
  State<DoublePulseRing> createState() => _DoublePulseRingState();
}

class _DoublePulseRingState extends State<DoublePulseRing>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;

  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _controller2 = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _controller1.repeat();
    Future.delayed(Duration(milliseconds: widget.duration.inMilliseconds ~/ 2),
        () {
      if (mounted) {
        _controller2.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AuraColors.auraAmber;

    return SizedBox(
      width: widget.size * 1.5,
      height: widget.size * 1.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Premier anneau
          _PulseRingItem(
            controller: _controller1,
            size: widget.size,
            color: color,
            ringWidth: widget.ringWidth,
          ),
          // Deuxième anneau
          _PulseRingItem(
            controller: _controller2,
            size: widget.size,
            color: color,
            ringWidth: widget.ringWidth,
          ),
          // Cercle central
          Container(
            width: widget.size * 0.6,
            height: widget.size * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: widget.ringWidth,
              ),
            ),
            child: Center(child: widget.child),
          ),
        ],
      ),
    );
  }
}

class _PulseRingItem extends StatelessWidget {
  const _PulseRingItem({
    required this.controller,
    required this.size,
    required this.color,
    required this.ringWidth,
  });

  final AnimationController controller;
  final double size;
  final Color color;
  final double ringWidth;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final scale = 1.0 + (controller.value * 0.5);
        final opacity = 1.0 - controller.value;

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: ringWidth,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Indicateur de scan avec animation de pulse et icône
class ScanIndicator extends StatelessWidget {
  const ScanIndicator({
    super.key,
    this.size = 160.0,
    this.color,
    this.label,
  });

  final double size;
  final Color? color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AuraColors.auraAmber;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DoublePulseRing(
          size: size,
          color: effectiveColor,
          child: Icon(
            Icons.document_scanner_outlined,
            size: size * 0.25,
            color: effectiveColor,
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: AuraDimensions.spaceL),
          Text(
            label!,
            style: TextStyle(
              color: effectiveColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// Indicateur de chargement avec pulse
class LoadingPulse extends StatelessWidget {
  const LoadingPulse({
    super.key,
    this.size = 80.0,
    this.color,
    this.label,
  });

  final double size;
  final Color? color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AuraColors.auraAmber;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PulseRing(
          size: size,
          color: effectiveColor,
          child: SizedBox(
            width: size * 0.4,
            height: size * 0.4,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: AuraDimensions.spaceM),
          Text(
            label!,
            style: TextStyle(
              color: effectiveColor.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }
}
