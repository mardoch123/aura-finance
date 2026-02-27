import 'package:flutter/material.dart';
import '../../theme/aura_colors.dart';
import '../../theme/aura_typography.dart';
import 'felix_mascot.dart';
import '../felix_animation_type.dart';

/// Loader de scan IA avec Félix et textes changeants
class FelixScannerLoader extends StatelessWidget {
  /// Texte de l'étape actuelle du scan
  final String? stepText;
  
  /// Progression (0.0 à 1.0)
  final double progress;
  
  /// Taille de Félix
  final double size;

  const FelixScannerLoader({
    super.key,
    this.stepText,
    this.progress = 0.0,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Félix en animation scan
        FelixMascot(
          animationType: FelixAnimationType.scan,
          size: size,
        ),
        
        const SizedBox(height: 32),
        
        // Barre de progression fine
        Container(
          width: 200,
          height: 3,
          decoration: BoxDecoration(
            color: AuraColors.auraGlass,
            borderRadius: BorderRadius.circular(1.5),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AuraColors.auraAmber, AuraColors.auraAccentGold],
                ),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Texte de l'étape avec animation de fondu
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            stepText ?? 'Analyse en cours...',
            key: ValueKey(stepText),
            style: AuraTypography.bodyLarge.copyWith(
              color: AuraColors.auraTextDark,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

/// Version minimale du loader pour overlays
class FelixScannerLoaderCompact extends StatelessWidget {
  final String? stepText;
  final double progress;

  const FelixScannerLoaderCompact({
    super.key,
    this.stepText,
    this.progress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AuraColors.auraGlassStrong,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AuraColors.auraGlassBorder,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Félix plus petit
          FelixMascot(
            animationType: FelixAnimationType.scan,
            size: 120,
          ),
          
          const SizedBox(height: 20),
          
          // Barre de progression
          SizedBox(
            width: 150,
            child: LinearProgressIndicator(
              value: progress > 0 ? progress : null,
              backgroundColor: AuraColors.auraGlass,
              valueColor: const AlwaysStoppedAnimation(AuraColors.auraAmber),
              minHeight: 3,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Texte
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              stepText ?? 'Analyse...',
              key: ValueKey(stepText),
              style: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.auraTextDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
