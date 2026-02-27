import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/aura_colors.dart';

/// Widget de chargement avec un renard animé
/// Le renard est le mascotte d'Aura Finance - intelligent et vif
class AnimalLoader extends StatefulWidget {
  final double size;
  final Color color;
  final String? message;
  final bool showBackground;

  const AnimalLoader({
    super.key,
    this.size = 120,
    this.color = AuraColors.auraAmber,
    this.message,
    this.showBackground = true,
  });

  @override
  State<AnimalLoader> createState() => _AnimalLoaderState();
}

class _AnimalLoaderState extends State<AnimalLoader>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _tailController;
  late AnimationController _eyeController;
  late AnimationController _coinController;

  @override
  void initState() {
    super.initState();
    
    // Animation de rebond du corps
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    // Animation de la queue
    _tailController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    // Animation des yeux (clignement)
    _eyeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _startBlinking();

    // Animation des pièces
    _coinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  void _startBlinking() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        await _eyeController.forward();
        await _eyeController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _tailController.dispose();
    _eyeController.dispose();
    _coinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.showBackground ? widget.size * 2 : null,
      height: widget.showBackground ? widget.size * 2.5 : null,
      decoration: widget.showBackground
          ? BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            )
          : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size * 0.9,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _bounceController,
                _tailController,
                _eyeController,
              ]),
              builder: (context, child) {
                return CustomPaint(
                  size: Size(widget.size, widget.size * 0.9),
                  painter: FoxPainter(
                    bounceValue: _bounceController.value,
                    tailValue: _tailController.value,
                    eyeValue: _eyeController.value,
                    color: widget.color,
                  ),
                );
              },
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.message!,
              style: TextStyle(
                color: AuraColors.auraTextDark,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Petites pièces animées
          SizedBox(
            width: widget.size * 0.8,
            height: 20,
            child: AnimatedBuilder(
              animation: _coinController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(widget.size * 0.8, 20),
                  painter: CoinsPainter(
                    progress: _coinController.value,
                    color: widget.color,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter pour dessiner le renard
class FoxPainter extends CustomPainter {
  final double bounceValue;
  final double tailValue;
  final double eyeValue;
  final Color color;

  FoxPainter({
    required this.bounceValue,
    required this.tailValue,
    required this.eyeValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Animation de rebond
    final bounceOffset = bounceValue * 8;
    
    // Couleurs
    final foxColor = color;
    final darkColor = Color.lerp(color, Colors.black, 0.3)!;
    final lightColor = Color.lerp(color, Colors.white, 0.4)!;
    final whiteColor = Colors.white;
    
    // === QUEUE (dessinée en premier, derrière) ===
    final tailPaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.fill;
    
    final tailAngle = tailValue * 0.3 - 0.15;
    final tailPath = Path();
    final tailBaseX = centerX - 35;
    final tailBaseY = centerY + 10 + bounceOffset;
    
    tailPath.moveTo(tailBaseX, tailBaseY);
    tailPath.quadraticBezierTo(
      tailBaseX - 40 + math.sin(tailAngle) * 20,
      tailBaseY - 30 + math.cos(tailAngle) * 15,
      tailBaseX - 25 + math.sin(tailAngle) * 30,
      tailBaseY - 50 + math.cos(tailAngle) * 10,
    );
    tailPath.quadraticBezierTo(
      tailBaseX - 10 + math.sin(tailAngle) * 15,
      tailBaseY - 40 + math.cos(tailAngle) * 8,
      tailBaseX,
      tailBaseY - 15,
    );
    tailPath.close();
    canvas.drawPath(tailPath, tailPaint);
    
    // Point blanc sur la queue
    final tailTipPaint = Paint()
      ..color = whiteColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(tailBaseX - 22 + math.sin(tailAngle) * 25, tailBaseY - 45 + math.cos(tailAngle) * 8),
      8,
      tailTipPaint,
    );

    // === CORPS ===
    final bodyPaint = Paint()
      ..color = foxColor
      ..style = PaintingStyle.fill;
    
    final bodyPath = Path();
    final bodyY = centerY + 15 + bounceOffset;
    bodyPath.addOval(Rect.fromCenter(
      center: Offset(centerX, bodyY),
      width: 55,
      height: 45,
    ));
    canvas.drawPath(bodyPath, bodyPaint);
    
    // Ventre blanc
    final bellyPaint = Paint()
      ..color = whiteColor
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromCenter(
      center: Offset(centerX, bodyY + 5),
      width: 30,
      height: 25,
    ), bellyPaint);

    // === TÊTE ===
    final headPaint = Paint()
      ..color = foxColor
      ..style = PaintingStyle.fill;
    
    final headY = centerY - 15 + bounceOffset;
    final headPath = Path();
    headPath.addOval(Rect.fromCenter(
      center: Offset(centerX, headY),
      width: 60,
      height: 50,
    ));
    canvas.drawPath(headPath, headPaint);
    
    // Museau blanc
    final snoutPaint = Paint()
      ..color = whiteColor
      ..style = PaintingStyle.fill;
    final snoutPath = Path();
    snoutPath.moveTo(centerX - 15, headY + 5);
    snoutPath.quadraticBezierTo(centerX, headY + 25, centerX + 15, headY + 5);
    snoutPath.lineTo(centerX, headY - 5);
    snoutPath.close();
    canvas.drawPath(snoutPath, snoutPaint);
    
    // Nez
    final nosePaint = Paint()
      ..color = const Color(0xFF2D2D2D)
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromCenter(
      center: Offset(centerX, headY + 12),
      width: 10,
      height: 6,
    ), nosePaint);

    // === OREILLES ===
    final earPaint = Paint()
      ..color = foxColor
      ..style = PaintingStyle.fill;
    
    // Oreille gauche
    final leftEarPath = Path();
    leftEarPath.moveTo(centerX - 20, headY - 20);
    leftEarPath.lineTo(centerX - 28, headY - 45);
    leftEarPath.lineTo(centerX - 8, headY - 35);
    leftEarPath.close();
    canvas.drawPath(leftEarPath, earPaint);
    
    // Oreille droite
    final rightEarPath = Path();
    rightEarPath.moveTo(centerX + 20, headY - 20);
    rightEarPath.lineTo(centerX + 28, headY - 45);
    rightEarPath.lineTo(centerX + 8, headY - 35);
    rightEarPath.close();
    canvas.drawPath(rightEarPath, earPaint);
    
    // Intérieur des oreilles
    final innerEarPaint = Paint()
      ..color = lightColor
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(
      Path()
        ..moveTo(centerX - 18, headY - 22)
        ..lineTo(centerX - 24, headY - 38)
        ..lineTo(centerX - 12, headY - 32)
        ..close(),
      innerEarPaint,
    );
    
    canvas.drawPath(
      Path()
        ..moveTo(centerX + 18, headY - 22)
        ..lineTo(centerX + 24, headY - 38)
        ..lineTo(centerX + 12, headY - 32)
        ..close(),
      innerEarPaint,
    );

    // === YEUX ===
    final eyePaint = Paint()
      ..color = const Color(0xFF2D2D2D)
      ..style = PaintingStyle.fill;
    
    // Animation de clignement
    final eyeHeight = 8 * (1 - eyeValue);
    
    // Œil gauche
    canvas.drawOval(Rect.fromCenter(
      center: Offset(centerX - 12, headY - 5),
      width: 8,
      height: eyeHeight < 1 ? 1 : eyeHeight,
    ), eyePaint);
    
    // Œil droit
    canvas.drawOval(Rect.fromCenter(
      center: Offset(centerX + 12, headY - 5),
      width: 8,
      height: eyeHeight < 1 ? 1 : eyeHeight,
    ), eyePaint);
    
    // Reflets dans les yeux
    if (eyeValue < 0.5) {
      final reflectionPaint = Paint()
        ..color = whiteColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(centerX - 10, headY - 7),
        2,
        reflectionPaint,
      );
      canvas.drawCircle(
        Offset(centerX + 14, headY - 7),
        2,
        reflectionPaint,
      );
    }

    // === PATTES ===
    final pawPaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.fill;
    
    // Pattes avant
    canvas.drawOval(Rect.fromCenter(
      center: Offset(centerX - 15, bodyY + 22),
      width: 12,
      height: 18,
    ), pawPaint);
    canvas.drawOval(Rect.fromCenter(
      center: Offset(centerX + 15, bodyY + 22),
      width: 12,
      height: 18,
    ), pawPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Painter pour les pièces animées
class CoinsPainter extends CustomPainter {
  final double progress;
  final Color color;

  CoinsPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final coinPaint = Paint()
      ..color = Color.lerp(color, Colors.amber, 0.3)!
      ..style = PaintingStyle.fill;
    
    final coinBorderPaint = Paint()
      ..color = Color.lerp(color, Colors.orange, 0.5)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // 3 petites pièces qui flottent
    for (int i = 0; i < 3; i++) {
      final x = size.width * (0.2 + i * 0.3);
      final offset = math.sin((progress + i * 0.3) * math.pi * 2) * 5;
      
      canvas.drawCircle(
        Offset(x, size.height / 2 + offset),
        6,
        coinPaint,
      );
      canvas.drawCircle(
        Offset(x, size.height / 2 + offset),
        6,
        coinBorderPaint,
      );
      
      // Symbole €
      final textPainter = TextPainter(
        text: TextSpan(
          text: '€',
          style: TextStyle(
            color: Colors.white,
            fontSize: 7,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - 3, size.height / 2 + offset - 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter) => true;
}

/// Widget d'overlay de chargement avec le renard
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: AnimalLoader(
                message: message,
                size: 100,
              ),
            ),
          ),
      ],
    );
  }
}

/// Extension pour facilement afficher le loader
extension AnimalLoaderExtension on BuildContext {
  void showAnimalLoader({String? message}) {
    showDialog(
      context: this,
      barrierDismissible: false,
      builder: (context) => Center(
        child: AnimalLoader(
          message: message,
          size: 100,
        ),
      ),
    );
  }

  void hideAnimalLoader() {
    Navigator.of(this, rootNavigator: true).pop();
  }
}
