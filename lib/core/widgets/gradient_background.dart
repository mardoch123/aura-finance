import 'package:flutter/material.dart';
import '../theme/aura_colors.dart';
import '../theme/aura_dimensions.dart';

/// Widget de fond avec dégradé animé
///
/// Usage:
/// ```dart
/// GradientBackground(
///   child: Scaffold(...),
/// )
/// ```
class GradientBackground extends StatelessWidget {
  const GradientBackground({
    super.key,
    required this.child,
    this.gradient,
    this.animate = false,
    this.duration = const Duration(seconds: 10),
  });

  final Widget child;
  final Gradient? gradient;
  final bool animate;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = gradient ?? AuraColors.gradientAmber;

    if (animate) {
      return AnimatedGradientBackground(
        gradient: effectiveGradient,
        duration: duration,
        child: child,
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: effectiveGradient,
      ),
      child: child,
    );
  }
}

/// Fond avec dégradé animé
class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({
    super.key,
    required this.child,
    required this.gradient,
    required this.duration,
  });

  final Widget child;
  final Gradient gradient;
  final Duration duration;

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState
    extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                -1.0 + _controller.value * 2.0,
                -1.0,
              ),
              end: Alignment(
                1.0 - _controller.value * 2.0,
                1.0,
              ),
              colors: const [
                AuraColors.auraAmber,
                AuraColors.auraDeep,
                AuraColors.auraDark,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Fond avec mesh gradient (simulé avec plusieurs dégradés)
class MeshGradientBackground extends StatelessWidget {
  const MeshGradientBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Couche de base
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AuraColors.auraBackground,
                AuraColors.auraAmber,
              ],
            ),
          ),
        ),
        // Cercle flou 1
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AuraColors.auraAmber.withOpacity(0.5),
                  AuraColors.auraAmber.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
        // Cercle flou 2
        Positioned(
          bottom: -150,
          left: -100,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AuraColors.auraDeep.withOpacity(0.4),
                  AuraColors.auraDeep.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
        // Cercle flou 3
        Positioned(
          top: MediaQuery.of(context).size.height * 0.4,
          left: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AuraColors.auraAccentGold.withOpacity(0.3),
                  AuraColors.auraAccentGold.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
        // Contenu
        child,
      ],
    );
  }
}

/// Fond avec effet de vagues
class WaveBackground extends StatelessWidget {
  const WaveBackground({
    super.key,
    required this.child,
    this.waveHeight = 100.0,
  });

  final Widget child;
  final double waveHeight;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Dégradé de base
        Container(
          decoration: const BoxDecoration(
            gradient: AuraColors.gradientAmber,
          ),
        ),
        // Vague
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: CustomPaint(
            size: Size(MediaQuery.of(context).size.width, waveHeight),
            painter: _WavePainter(
              color: AuraColors.auraBackground,
            ),
          ),
        ),
        // Contenu
        SafeArea(child: child),
      ],
    );
  }
}

class _WavePainter extends CustomPainter {
  final Color color;

  _WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.5)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.3,
        size.width * 0.5,
        size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.7,
        size.width,
        size.height * 0.4,
      )
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Fond avec particules flottantes (subtil)
class ParticleBackground extends StatefulWidget {
  const ParticleBackground({
    super.key,
    required this.child,
    this.particleCount = 20,
  });

  final Widget child;
  final int particleCount;

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.particleCount,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(
          milliseconds: 3000 + (index * 200),
        ),
      )..repeat(reverse: true),
    );

    _animations = _controllers
        .map((controller) => Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: controller,
                curve: Curves.easeInOut,
              ),
            ))
        .toList();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Dégradé de base
        Container(
          decoration: const BoxDecoration(
            gradient: AuraColors.gradientAmber,
          ),
        ),
        // Particules
        ...List.generate(
          widget.particleCount,
          (index) => AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              final random = index / widget.particleCount;
              return Positioned(
                left: MediaQuery.of(context).size.width *
                    (random * 0.8 + 0.1),
                top: MediaQuery.of(context).size.height *
                    (0.1 + _animations[index].value * 0.8),
                child: Opacity(
                  opacity: 0.1 + random * 0.1,
                  child: Container(
                    width: 4 + random * 8,
                    height: 4 + random * 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Contenu
        child,
      ],
    );
  }
}
