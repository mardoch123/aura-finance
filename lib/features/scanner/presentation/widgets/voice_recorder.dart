import 'package:flutter/material.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/haptics/haptic_service.dart';

/// Widget de dictée vocale avec waveform animée
class VoiceRecorder extends StatefulWidget {
  const VoiceRecorder({
    super.key,
    required this.isListening,
    required this.transcript,
    required this.soundLevel,
    required this.onStart,
    required this.onStop,
    required this.onCancel,
  });

  final bool isListening;
  final String transcript;
  final double soundLevel;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onCancel;

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void didUpdateWidget(covariant VoiceRecorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isListening && oldWidget.isListening) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isListening && widget.transcript.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 120,
      left: AuraDimensions.spaceM,
      right: AuraDimensions.spaceM,
      child: GlassCard(
        borderRadius: AuraDimensions.radiusXL,
        padding: const EdgeInsets.all(AuraDimensions.spaceM),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Waveform
            if (widget.isListening) ...[
              SizedBox(
                height: 60,
                child: AnimatedWaveform(
                  soundLevel: widget.soundLevel,
                ),
              ),
              const SizedBox(height: AuraDimensions.spaceM),
            ],

            // Transcription
            if (widget.transcript.isNotEmpty)
              Text(
                widget.transcript,
                style: AuraTypography.bodyLarge.copyWith(
                  color: AuraColors.auraTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),

            if (widget.isListening) ...[
              const SizedBox(height: AuraDimensions.spaceM),

              // Boutons de contrôle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Annuler
                  _VoiceButton(
                    icon: Icons.close,
                    color: AuraColors.auraRed,
                    onPressed: () {
                      HapticService.error();
                      widget.onCancel();
                    },
                  ),
                  const SizedBox(width: AuraDimensions.spaceXL),

                  // Enregistrement en cours
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AuraColors.auraRed.withOpacity(
                            0.3 + (_pulseController.value * 0.3),
                          ),
                          border: Border.all(
                            color: AuraColors.auraRed,
                            width: 3,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.mic,
                            color: AuraColors.auraTextPrimary,
                            size: 32,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: AuraDimensions.spaceXL),

                  // Valider
                  _VoiceButton(
                    icon: Icons.check,
                    color: AuraColors.auraGreen,
                    onPressed: () {
                      HapticService.success();
                      widget.onStop();
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bouton de contrôle vocal
class _VoiceButton extends StatelessWidget {
  const _VoiceButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.2),
          border: Border.all(
            color: color,
            width: 2,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
      ),
    );
  }
}

/// Waveform animée pour la reconnaissance vocale
class AnimatedWaveform extends StatelessWidget {
  const AnimatedWaveform({
    super.key,
    required this.soundLevel,
  });

  final double soundLevel;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 60),
      painter: _WaveformPainter(
        soundLevel: soundLevel,
      ),
    );
  }
}

/// Painter pour la waveform
class _WaveformPainter extends CustomPainter {
  final double soundLevel;

  _WaveformPainter({required this.soundLevel});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AuraColors.auraAmber
      ..style = PaintingStyle.fill;

    final barCount = 30;
    final barWidth = size.width / (barCount * 2);
    final spacing = barWidth;

    for (int i = 0; i < barCount; i++) {
      // Simuler des barres avec variations
      final normalizedIndex = i / barCount;
      final distanceFromCenter = (normalizedIndex - 0.5).abs() * 2;
      
      // Variation basée sur le niveau sonore
      final baseHeight = 10.0 + (soundLevel * 40);
      final variation = (i % 3 == 0) ? 1.2 : (i % 2 == 0) ? 0.8 : 1.0;
      final height = baseHeight * variation * (1 - distanceFromCenter * 0.5);

      final x = i * (barWidth + spacing) + spacing;
      final y = (size.height - height) / 2;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, height),
        const Radius.circular(4),
      );

      // Opacité basée sur la distance du centre
      final opacity = 0.3 + (1 - distanceFromCenter) * 0.7;
      canvas.drawRRect(
        rect,
        paint..color = AuraColors.auraAmber.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
