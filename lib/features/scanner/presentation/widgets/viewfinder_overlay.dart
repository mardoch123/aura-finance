import 'package:flutter/material.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';

/// Overlay de viewfinder pour le scanner
/// Affiche un rectangle central avec coins arrondis et animation de scan
class ViewfinderOverlay extends StatelessWidget {
  const ViewfinderOverlay({
    super.key,
    this.isProcessing = false,
    this.hasError = false,
  });

  final bool isProcessing;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _ViewfinderPainter(
        isProcessing: isProcessing,
        hasError: hasError,
      ),
    );
  }
}

/// Painter personnalisé pour le viewfinder
class _ViewfinderPainter extends CustomPainter {
  final bool isProcessing;
  final bool hasError;

  _ViewfinderPainter({
    required this.isProcessing,
    required this.hasError,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final viewfinderWidth = size.width * 0.75;
    final viewfinderHeight = viewfinderWidth * 1.4; // Ratio ticket de caisse
    final left = (size.width - viewfinderWidth) / 2;
    final top = (size.height - viewfinderHeight) / 2;
    final rect = Rect.fromLTWH(left, top, viewfinderWidth, viewfinderHeight);

    // Couleur selon l'état
    final color = hasError
        ? AuraColors.auraRed
        : isProcessing
            ? AuraColors.auraAmber
            : AuraColors.auraTextPrimary;

    // Overlay sombre autour du viewfinder
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Créer un path avec un trou au centre
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        rect,
        const Radius.circular(24),
      ));
    path.fillType = PathFillType.evenOdd;

    canvas.drawPath(path, overlayPaint);

    // Bordure du viewfinder
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(24)),
      borderPaint,
    );

    // Coins animés (petits arcs)
    final cornerLength = 24.0;
    final cornerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Coin haut-gauche
    canvas.drawLine(
      Offset(left, top + cornerLength),
      Offset(left, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      cornerPaint,
    );

    // Coin haut-droite
    canvas.drawLine(
      Offset(left + viewfinderWidth - cornerLength, top),
      Offset(left + viewfinderWidth, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + viewfinderWidth, top),
      Offset(left + viewfinderWidth, top + cornerLength),
      cornerPaint,
    );

    // Coin bas-gauche
    canvas.drawLine(
      Offset(left, top + viewfinderHeight - cornerLength),
      Offset(left, top + viewfinderHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + viewfinderHeight),
      Offset(left + cornerLength, top + viewfinderHeight),
      cornerPaint,
    );

    // Coin bas-droite
    canvas.drawLine(
      Offset(left + viewfinderWidth - cornerLength, top + viewfinderHeight),
      Offset(left + viewfinderWidth, top + viewfinderHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + viewfinderWidth, top + viewfinderHeight - cornerLength),
      Offset(left + viewfinderWidth, top + viewfinderHeight),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Ligne de scan animée qui descend et remonte
class ScanLine extends StatefulWidget {
  const ScanLine({super.key});

  @override
  State<ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<ScanLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewfinderWidth = constraints.maxWidth * 0.75;
        final viewfinderHeight = viewfinderWidth * 1.4;
        final left = (constraints.maxWidth - viewfinderWidth) / 2;
        final top = (constraints.maxHeight - viewfinderHeight) / 2;

        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final scanTop = top + (_animation.value * viewfinderHeight);

            return Positioned(
              left: left + 4,
              right: left + 4,
              top: scanTop - 1,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      AuraColors.auraAmber.withOpacity(0.8),
                      AuraColors.auraTextPrimary,
                      AuraColors.auraAmber.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AuraColors.auraAmber.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Animation de shake pour les erreurs
class ShakeAnimation extends StatefulWidget {
  const ShakeAnimation({
    super.key,
    required this.child,
    this.shake = false,
  });

  final Widget child;
  final bool shake;

  @override
  State<ShakeAnimation> createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<ShakeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant ShakeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // 3 oscillations
        final value = _animation.value;
        double offset = 0;
        if (value < 1) {
          offset = 8 * (1 - value) * (value < 0.33
              ? 1
              : value < 0.66
                  ? -1
                  : 1);
        }

        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
