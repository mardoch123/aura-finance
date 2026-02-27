import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/aura_colors.dart';
import '../../theme/aura_typography.dart';
import '../../widgets/glass_card.dart';
import 'felix_mascot.dart';
import 'felix_with_confetti.dart';
import '../felix_animation_type.dart';

/// Pop-up de succès avec Félix et confettis
class FelixSuccessPopup extends StatefulWidget {
  /// Message principal
  final String message;
  
  /// Sous-message optionnel
  final String? subMessage;
  
  /// Durée d'affichage avant disparition auto
  final Duration duration;
  
  /// Callback quand le popup se ferme
  final VoidCallback? onDismiss;

  const FelixSuccessPopup({
    super.key,
    required this.message,
    this.subMessage,
    this.duration = const Duration(seconds: 2),
    this.onDismiss,
  });

  @override
  State<FelixSuccessPopup> createState() => _FelixSuccessPopupState();
}

class _FelixSuccessPopupState extends State<FelixSuccessPopup> {
  @override
  void initState() {
    super.initState();
    // Auto-dismiss après la durée spécifiée
    Timer(widget.duration, () {
      if (mounted) {
        widget.onDismiss?.call();
        Navigator.of(context).maybePop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onDismiss?.call();
        Navigator.of(context).maybePop();
      },
      child: Material(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: FelixWithConfetti(
            animationType: FelixAnimationType.success,
            message: widget.message,
            subMessage: widget.subMessage,
            confettiCount: 40,
            duration: widget.duration,
          ),
        ),
      ),
    );
  }
}

/// Pop-up d'alerte vampire avec Félix
class FelixVampireAlertPopup extends StatelessWidget {
  /// Nom du service qui a augmenté
  final String serviceName;
  
  /// Montant de l'augmentation
  final double increaseAmount;
  
  /// Pourcentage d'augmentation
  final double? percentage;
  
  /// Callback pour contester
  final VoidCallback? onDispute;
  
  /// Callback pour voir les alternatives
  final VoidCallback? onSeeAlternatives;

  const FelixVampireAlertPopup({
    super.key,
    required this.serviceName,
    required this.increaseAmount,
    this.percentage,
    this.onDispute,
    this.onSeeAlternatives,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: GlassCard(
        gradient: LinearGradient(
          colors: [
            AuraColors.auraRed.withOpacity(0.15),
            AuraColors.auraRed.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderColor: AuraColors.auraRed.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Félix alerte
              FelixMascot(
                animationType: FelixAnimationType.alert,
                size: 120,
              ),
              
              const SizedBox(height: 20),
              
              // Titre
              Text(
                'Félix a détecté quelque chose ! 🧛',
                style: AuraTypography.h4.copyWith(
                  color: AuraColors.auraRed,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Détails de l'augmentation
              Text(
                '$serviceName a augmenté de ${increaseAmount.toStringAsFixed(0)}€/mois',
                style: AuraTypography.bodyLarge.copyWith(
                  color: AuraColors.auraTextDark,
                ),
                textAlign: TextAlign.center,
              ),
              
              if (percentage != null) ...[
                const SizedBox(height: 4),
                Text(
                  '(+${percentage!.toStringAsFixed(0)}%)',
                  style: AuraTypography.bodyMedium.copyWith(
                    color: AuraColors.auraRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onSeeAlternatives?.call();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AuraColors.auraTextDark,
                        side: const BorderSide(color: AuraColors.auraGlassBorder),
                      ),
                      child: const Text('Alternatives'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onDispute?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AuraColors.auraRed,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Contester'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pop-up d'objectif atteint
class FelixGoalAchievedPopup extends StatefulWidget {
  /// Nom de l'objectif
  final String goalName;
  
  /// Montant atteint
  final double amount;
  
  /// Callback quand le popup se ferme
  final VoidCallback? onDismiss;

  const FelixGoalAchievedPopup({
    super.key,
    required this.goalName,
    required this.amount,
    this.onDismiss,
  });

  @override
  State<FelixGoalAchievedPopup> createState() => _FelixGoalAchievedPopupState();
}

class _FelixGoalAchievedPopupState extends State<FelixGoalAchievedPopup> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        widget.onDismiss?.call();
        Navigator.of(context).maybePop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onDismiss?.call();
        Navigator.of(context).maybePop();
      },
      child: Material(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: FelixWithConfetti(
            animationType: FelixAnimationType.celebrate,
            message: 'Bravo ! Objectif atteint 🎉',
            subMessage: '${widget.goalName} - ${widget.amount.toStringAsFixed(0)}€',
            confettiCount: 50,
            duration: const Duration(seconds: 3),
          ),
        ),
      ),
    );
  }
}

/// Overlay de chargement avec Félix idle (Splash Screen)
class FelixSplashScreen extends StatelessWidget {
  /// Progression du chargement (0.0 à 1.0)
  final double progress;
  
  /// Message de chargement
  final String? loadingText;

  const FelixSplashScreen({
    super.key,
    this.progress = 0.0,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AuraColors.auraBackground,
              Color(0xFFF5E6D0),
              Color(0xFFE8D4B8),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Félix idle
              FelixMascot(
                animationType: FelixAnimationType.idle,
                size: 200,
              ),
              
              const SizedBox(height: 48),
              
              // Barre de progression fine
              SizedBox(
                width: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(1.5),
                  child: LinearProgressIndicator(
                    value: progress > 0 ? progress : null,
                    backgroundColor: AuraColors.auraGlass,
                    valueColor: const AlwaysStoppedAnimation(AuraColors.auraAmber),
                    minHeight: 3,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Texte de chargement
              Text(
                loadingText ?? 'Analyse de vos finances...',
                style: AuraTypography.bodyLarge.copyWith(
                  color: AuraColors.auraTextDarkSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Indicateur de réflexion du Coach (petit Félix)
class FelixCoachThinking extends StatelessWidget {
  final double size;

  const FelixCoachThinking({
    super.key,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FelixMascot(
          animationType: FelixAnimationType.thinking,
          size: size,
        ),
        const SizedBox(width: 8),
        // Points de suspension animés
        _AnimatedDots(),
      ],
    );
  }
}

/// Points de suspension animés
class _AnimatedDots extends StatefulWidget {
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
        final progress = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final dotProgress = ((progress - delay) % 1.0).abs();
            final opacity = dotProgress < 0.5 
                ? 0.3 + (dotProgress * 2 * 0.7) 
                : 1.0 - ((dotProgress - 0.5) * 2 * 0.7);
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AuraColors.auraTextDarkSecondary.withOpacity(opacity.clamp(0.3, 1.0)),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

/// Extension pour afficher facilement les popups
extension FelixPopupExtension on BuildContext {
  /// Affiche un popup de succès
  Future<void> showFelixSuccess({
    required String message,
    String? subMessage,
    Duration duration = const Duration(seconds: 2),
  }) async {
    return showDialog(
      context: this,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => FelixSuccessPopup(
        message: message,
        subMessage: subMessage,
        duration: duration,
      ),
    );
  }

  /// Affiche une alerte vampire
  Future<void> showFelixVampireAlert({
    required String serviceName,
    required double increaseAmount,
    double? percentage,
    VoidCallback? onDispute,
    VoidCallback? onSeeAlternatives,
  }) async {
    return showDialog(
      context: this,
      barrierDismissible: true,
      builder: (context) => FelixVampireAlertPopup(
        serviceName: serviceName,
        increaseAmount: increaseAmount,
        percentage: percentage,
        onDispute: onDispute,
        onSeeAlternatives: onSeeAlternatives,
      ),
    );
  }

  /// Affiche un popup d'objectif atteint
  Future<void> showFelixGoalAchieved({
    required String goalName,
    required double amount,
  }) async {
    return showDialog(
      context: this,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => FelixGoalAchievedPopup(
        goalName: goalName,
        amount: amount,
      ),
    );
  }
}
