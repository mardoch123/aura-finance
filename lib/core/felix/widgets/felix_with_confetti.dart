import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/aura_colors.dart';
import 'felix_mascot.dart';
import '../felix_animation_type.dart';

/// Félix avec effet de confettis pour les célébrations
class FelixWithConfetti extends StatefulWidget {
  /// Type d'animation
  final FelixAnimationType animationType;
  
  /// Taille de Félix
  final double size;
  
  /// Message à afficher
  final String? message;
  
  /// Sous-message
  final String? subMessage;
  
  /// Nombre de confettis
  final int confettiCount;
  
  /// Durée de l'animation des confettis
  final Duration duration;

  const FelixWithConfetti({
    super.key,
    this.animationType = FelixAnimationType.celebrate,
    this.size = 180,
    this.message,
    this.subMessage,
    this.confettiCount = 30,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<FelixWithConfetti> createState() => _FelixWithConfettiState();
}

class _FelixWithConfettiState extends State<FelixWithConfetti>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late List<ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    _initializeParticles();
    _confettiController.forward();
  }

  void _initializeParticles() {
    final random = math.Random();
    _particles = List.generate(widget.confettiCount, (index) {
      return ConfettiParticle(
        color: _getConfettiColor(random),
        size: random.nextDouble() * 8 + 4,
        initialX: random.nextDouble() * 300 - 150,
        initialY: random.nextDouble() * -200 - 50,
        velocityX: random.nextDouble() * 100 - 50,
        velocityY: random.nextDouble() * 200 + 100,
        rotation: random.nextDouble() * math.pi * 2,
        rotationSpeed: random.nextDouble() * 4 - 2,
      );
    });
  }

  Color _getConfettiColor(math.Random random) {
    final colors = [
      AuraColors.auraAmber,
      AuraColors.auraAccentGold,
      AuraColors.auraDeep,
      Colors.white,
      AuraColors.auraGreen,
    ];
    return colors[random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 350,
      height: 400,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confettis
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(350, 400),
                painter: ConfettiPainter(
                  particles: _particles,
                  progress: _confettiController.value,
                ),
              );
            },
          ),
          
          // Félix
          Positioned(
            bottom: 80,
            child: FelixMascot(
              animationType: widget.animationType,
              size: widget.size,
            ),
          ),
          
          // Messages
          if (widget.message != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    widget.message!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AuraColors.auraTextDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.subMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.subMessage!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AuraColors.auraTextDarkSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Représente une particule de confetti
class ConfettiParticle {
  final Color color;
  final double size;
  final double initialX;
  final double initialY;
  final double velocityX;
  final double velocityY;
  final double rotation;
  final double rotationSpeed;

  ConfettiParticle({
    required this.color,
    required this.size,
    required this.initialX,
    required this.initialY,
    required this.velocityX,
    required this.velocityY,
    required this.rotation,
    required this.rotationSpeed,
  });
}

/// Painter pour dessiner les confettis
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2 + 50;

    for (final particle in particles) {
      final x = centerX + 
                particle.initialX + 
                particle.velocityX * progress;
      
      final y = centerY + 
                particle.initialY + 
                particle.velocityY * progress + 
                0.5 * 300 * progress * progress; // Gravité

      final currentRotation = particle.rotation + particle.rotationSpeed * progress * 10;
      
      final paint = Paint()
        ..color = particle.color.withOpacity(1 - progress * 0.5)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(currentRotation);
      
      // Dessine un rectangle (confetti)
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size * 0.6,
        ),
        paint,
      );
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
