import 'package:flutter/material.dart';
import '../../../../core/theme/aura_colors.dart';

/// Widget pour les coins animés du viewfinder
/// Animation: scale pulse subtle 0.98↔1.00 toutes les 1.5s
class AnimatedCorners extends StatefulWidget {
  const AnimatedCorners({
    super.key,
    this.size = 24.0,
    this.color,
    this.cornerLength = 24.0,
  });

  final double size;
  final Color? color;
  final double cornerLength;

  @override
  State<AnimatedCorners> createState() => _AnimatedCornersState();
}

class _AnimatedCornersState extends State<AnimatedCorners>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AuraColors.auraTextPrimary;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _CornerPainter(
          color: color,
          cornerLength: widget.cornerLength,
        ),
      ),
    );
  }
}

/// Painter pour dessiner les 4 coins
class _CornerPainter extends CustomPainter {
  final Color color;
  final double cornerLength;

  _CornerPainter({
    required this.color,
    required this.cornerLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Coin haut-gauche
    canvas.drawLine(
      Offset(0, cornerLength),
      Offset(0, 0),
      paint,
    );
    canvas.drawLine(
      Offset(0, 0),
      Offset(cornerLength, 0),
      paint,
    );

    // Coin haut-droite
    canvas.drawLine(
      Offset(size.width - cornerLength, 0),
      Offset(size.width, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLength),
      paint,
    );

    // Coin bas-gauche
    canvas.drawLine(
      Offset(0, size.height - cornerLength),
      Offset(0, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      paint,
    );

    // Coin bas-droite
    canvas.drawLine(
      Offset(size.width - cornerLength, size.height),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - cornerLength),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget pour afficher les 4 coins positionnés autour d'une zone
class PositionedCorners extends StatelessWidget {
  const PositionedCorners({
    super.key,
    required this.child,
    this.cornerSize = 32.0,
    this.cornerOffset = 8.0,
  });

  final Widget child;
  final double cornerSize;
  final double cornerOffset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        // Coin haut-gauche
        Positioned(
          left: -cornerOffset,
          top: -cornerOffset,
          child: SizedBox(
            width: cornerSize,
            height: cornerSize,
            child: const AnimatedCorners(),
          ),
        ),
        // Coin haut-droite
        Positioned(
          right: -cornerOffset,
          top: -cornerOffset,
          child: SizedBox(
            width: cornerSize,
            height: cornerSize,
            child: const AnimatedCorners(),
          ),
        ),
        // Coin bas-gauche
        Positioned(
          left: -cornerOffset,
          bottom: -cornerOffset,
          child: SizedBox(
            width: cornerSize,
            height: cornerSize,
            child: const AnimatedCorners(),
          ),
        ),
        // Coin bas-droite
        Positioned(
          right: -cornerOffset,
          bottom: -cornerOffset,
          child: SizedBox(
            width: cornerSize,
            height: cornerSize,
            child: const AnimatedCorners(),
          ),
        ),
      ],
    );
  }
}
