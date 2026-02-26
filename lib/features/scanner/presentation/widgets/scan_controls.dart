import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/haptics/haptic_service.dart';

/// Contrôles du scanner en bas de l'écran
/// [🎤 Dicter] [○ Scanner] [⚡ Dernier reçu]
class ScanControls extends StatelessWidget {
  const ScanControls({
    super.key,
    required this.onVoicePressed,
    required this.onCapturePressed,
    required this.onLastReceiptPressed,
    required this.isProcessing,
  });

  final VoidCallback onVoicePressed;
  final VoidCallback onCapturePressed;
  final VoidCallback onLastReceiptPressed;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AuraDimensions.spaceL,
          vertical: AuraDimensions.spaceM,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Bouton Dicter
            _ControlButton(
              icon: Icons.mic,
              label: 'Dicter',
              onPressed: onVoicePressed,
            ),

            // Bouton Scanner (central)
            _CaptureButton(
              onPressed: isProcessing ? null : onCapturePressed,
              isProcessing: isProcessing,
            ),

            // Bouton Dernier reçu
            _ControlButton(
              icon: Icons.receipt_long,
              label: 'Récents',
              onPressed: onLastReceiptPressed,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton de contrôle secondaire (Dicter / Récents)
class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        onPressed();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassCard(
            borderRadius: AuraDimensions.radiusXL,
            padding: const EdgeInsets.all(AuraDimensions.spaceM),
            child: Icon(
              icon,
              color: AuraColors.auraTextPrimary,
              size: 24,
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceXS),
          Text(
            label,
            style: AuraTypography.labelSmall.copyWith(
              color: AuraColors.auraTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bouton de capture principal (grand cercle)
class _CaptureButton extends StatefulWidget {
  const _CaptureButton({
    required this.onPressed,
    required this.isProcessing,
  });

  final VoidCallback? onPressed;
  final bool isProcessing;

  @override
  State<_CaptureButton> createState() => _CaptureButtonState();
}

class _CaptureButtonState extends State<_CaptureButton>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = true);
      _controller.forward();
      HapticService.mediumTap();
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AuraColors.auraTextPrimary,
            border: Border.all(
              color: AuraColors.auraAmber,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: AuraColors.auraAmber.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: widget.isProcessing
              ? const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AuraColors.auraAmber,
                      ),
                    ),
                  ),
                )
              : const Center(
                  child: Icon(
                    Icons.camera_alt,
                    color: AuraColors.auraDark,
                    size: 32,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Barre supérieure glassmorphique
class ScannerTopBar extends StatelessWidget {
  const ScannerTopBar({
    super.key,
    required this.onClose,
    required this.onImport,
  });

  final VoidCallback onClose;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AuraDimensions.spaceM,
          vertical: AuraDimensions.spaceS,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Bouton fermer
            _TopBarButton(
              icon: Icons.close,
              onPressed: onClose,
            ),

            // Titre
            Text(
              'Scanner',
              style: AuraTypography.h4.copyWith(
                color: AuraColors.auraTextPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),

            // Bouton importer
            _TopBarButton(
              icon: Icons.photo_library,
              onPressed: onImport,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton de la barre supérieure
class _TopBarButton extends StatelessWidget {
  const _TopBarButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: AuraDimensions.radiusXL,
      padding: const EdgeInsets.all(AuraDimensions.spaceS),
      onTap: () {
        HapticService.lightTap();
        onPressed();
      },
      child: Icon(
        icon,
        color: AuraColors.auraTextPrimary,
        size: 24,
      ),
    );
  }
}
