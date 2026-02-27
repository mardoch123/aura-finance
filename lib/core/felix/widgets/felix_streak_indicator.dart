import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/aura_colors.dart';
import '../../theme/aura_typography.dart';
import 'felix_mascot.dart';
import '../felix_animation_type.dart';

/// Indicateur de streak avec Félix
class FelixStreakIndicator extends StatelessWidget {
  /// Nombre de jours de streak
  final int days;
  
  /// Taille du widget
  final double size;
  
  /// Si on affiche le nombre de jours
  final bool showDays;
  
  /// Callback quand on tape
  final VoidCallback? onTap;

  const FelixStreakIndicator({
    super.key,
    required this.days,
    this.size = 80,
    this.showDays = true,
    this.onTap,
  });

  FelixAnimationType get _animationType {
    if (days == 0) return FelixAnimationType.streakLost;
    if (days <= 2) return FelixAnimationType.streakLow;
    if (days <= 6) return FelixAnimationType.streakMedium;
    return FelixAnimationType.streakHigh;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Félix avec effet de flamme si streak élevé
          Stack(
            alignment: Alignment.center,
            children: [
              // Flammes animées pour streak élevé
              if (days >= 7) ...[
                _AnimatedFlames(size: size),
              ],
              
              // Petite flamme pour streak moyen
              if (days >= 3 && days < 7) ...[
                Positioned(
                  top: 0,
                  child: _SmallFlame(size: size * 0.3),
                ),
              ],
              
              // Félix
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FelixMascot(
                  animationType: _animationType,
                  size: size * 0.8,
                ),
              ),
            ],
          ),
          
          // Nombre de jours
          if (showDays) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (days > 0) ...[
                  Icon(
                    Icons.local_fire_department,
                    size: 16,
                    color: days >= 7 
                        ? AuraColors.auraAmber 
                        : days >= 3 
                            ? AuraColors.auraDeep 
                            : AuraColors.auraTextDarkSecondary,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  days == 0 ? 'Série perdue' : '$days jours',
                  style: AuraTypography.labelMedium.copyWith(
                    color: days == 0 
                        ? AuraColors.auraRed 
                        : days >= 7 
                            ? AuraColors.auraAmber 
                            : AuraColors.auraTextDark,
                    fontWeight: days >= 7 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Flammes animées pour streak élevé
class _AnimatedFlames extends StatefulWidget {
  final double size;

  const _AnimatedFlames({required this.size});

  @override
  State<_AnimatedFlames> createState() => _AnimatedFlamesState();
}

class _AnimatedFlamesState extends State<_AnimatedFlames>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
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
        return CustomPaint(
          size: Size(widget.size, widget.size * 0.6),
          painter: _FlamesPainter(
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class _FlamesPainter extends CustomPainter {
  final double progress;

  _FlamesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final baseY = size.height;

    // Plusieurs flammes
    final flames = [
      _FlameData(
        offsetX: -15,
        height: 25 + math.sin(progress * math.pi * 2) * 5,
        color: AuraColors.auraAmber,
      ),
      _FlameData(
        offsetX: 0,
        height: 35 + math.sin((progress + 0.3) * math.pi * 2) * 8,
        color: AuraColors.auraAccentGold,
      ),
      _FlameData(
        offsetX: 15,
        height: 22 + math.sin((progress + 0.6) * math.pi * 2) * 6,
        color: AuraColors.auraDeep,
      ),
    ];

    for (final flame in flames) {
      final path = Path();
      path.moveTo(centerX + flame.offsetX - 8, baseY);
      path.quadraticBezierTo(
        centerX + flame.offsetX - 4,
        baseY - flame.height * 0.5,
        centerX + flame.offsetX,
        baseY - flame.height,
      );
      path.quadraticBezierTo(
        centerX + flame.offsetX + 4,
        baseY - flame.height * 0.5,
        centerX + flame.offsetX + 8,
        baseY,
      );
      path.close();

      final paint = Paint()
        ..color = flame.color.withOpacity(0.8)
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _FlameData {
  final double offsetX;
  final double height;
  final Color color;

  _FlameData({
    required this.offsetX,
    required this.height,
    required this.color,
  });
}

/// Petite flamme pour streak moyen
class _SmallFlame extends StatelessWidget {
  final double size;

  const _SmallFlame({required this.size});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.local_fire_department,
      size: size,
      color: AuraColors.auraAmber,
    );
  }
}

/// Widget de streak pour le calendrier
class FelixStreakCalendarDay extends StatelessWidget {
  final int day;
  final bool isActive;
  final bool isToday;
  final int? streakCount;

  const FelixStreakCalendarDay({
    super.key,
    required this.day,
    this.isActive = false,
    this.isToday = false,
    this.streakCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 50,
      decoration: BoxDecoration(
        color: isActive 
            ? AuraColors.auraAmber.withOpacity(0.2) 
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isToday 
            ? Border.all(color: AuraColors.auraAmber, width: 2) 
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: AuraTypography.labelMedium.copyWith(
              color: isActive 
                  ? AuraColors.auraAmber 
                  : AuraColors.auraTextDark,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isActive && streakCount != null && streakCount! > 0) ...[
            const SizedBox(height: 2),
            Icon(
              Icons.local_fire_department,
              size: 12,
              color: streakCount! >= 7 
                  ? AuraColors.auraAmber 
                  : AuraColors.auraDeep,
            ),
          ],
        ],
      ),
    );
  }
}
