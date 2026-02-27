import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../felix_controller.dart';
import '../felix_state.dart';
import '../felix_animation_type.dart';
import 'felix_mascot.dart';
import 'felix_scanner_loader.dart';
import 'felix_empty_state.dart';

/// Widget qui écoute l'état de Félix et affiche la bonne animation
class FelixConsumer extends ConsumerWidget {
  /// Builder personnalisé pour un état spécifique
  final Widget Function(BuildContext context, FelixState state)? builder;
  
  /// Si on veut afficher Félix en overlay
  final bool asOverlay;
  
  /// Enfant à afficher derrière Félix (si asOverlay = true)
  final Widget? child;

  const FelixConsumer({
    super.key,
    this.builder,
    this.asOverlay = false,
    this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(felixControllerProvider);
    
    // Si Félix n'est pas visible et qu'on est en mode overlay
    if (!state.isVisible && asOverlay) {
      return child ?? const SizedBox.shrink();
    }
    
    // Si Félix n'est pas visible
    if (!state.isVisible) {
      return const SizedBox.shrink();
    }
    
    // Builder personnalisé
    if (builder != null) {
      return builder!(context, state);
    }
    
    // Widget par défaut selon l'état
    final felixWidget = _buildFelixWidget(state);
    
    if (asOverlay) {
      return Stack(
        children: [
          child ?? const SizedBox.expand(),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(child: felixWidget),
            ),
          ),
        ],
      );
    }
    
    return felixWidget;
  }

  Widget _buildFelixWidget(FelixState state) {
    switch (state.animationType) {
      case FelixAnimationType.scan:
        return FelixScannerLoader(
          stepText: state.scanStepText,
          progress: state.progress,
        );
      case FelixAnimationType.empty:
        return FelixEmptyTransactions();
      default:
        return FelixMascot(
          animationType: state.animationType,
          message: state.message,
          subMessage: state.subMessage,
        );
    }
  }
}

/// Widget qui affiche Félix uniquement pendant le scan
class FelixScanOverlay extends ConsumerWidget {
  final Widget child;

  const FelixScanOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(felixControllerProvider);
    final isScanning = state.animationType == FelixAnimationType.scan && 
                       state.isVisible;
    
    return Stack(
      children: [
        child,
        if (isScanning)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: FelixScannerLoader(
                  stepText: state.scanStepText,
                  progress: state.progress,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Widget qui affiche Félix dans un coin (pour le coach)
class FelixCornerWidget extends ConsumerWidget {
  final double size;
  final Alignment alignment;

  const FelixCornerWidget({
    super.key,
    this.size = 64,
    this.alignment = Alignment.bottomRight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(felixControllerProvider);
    
    if (!state.isVisible || state.animationType != FelixAnimationType.thinking) {
      return const SizedBox.shrink();
    }
    
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FelixMascot(
          animationType: FelixAnimationType.thinking,
          size: size,
        ),
      ),
    );
  }
}
