import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/aura_colors.dart';
import '../../theme/aura_dimensions.dart';
import '../../haptics/haptic_service.dart';
import '../felix_animation_type.dart';
import '../felix_controller.dart';
import '../felix_state.dart';
import 'felix_mascot.dart';

/// Félix en tant que compagnon flottant
/// Apparaît discrètement et réagit aux actions de l'utilisateur
class FelixFloatingCompanion extends ConsumerStatefulWidget {
  /// Position sur l'écran
  final Alignment alignment;
  
  /// Taille de Félix
  final double size;
  
  /// Si Félix est draggable
  final bool isDraggable;
  
  /// Callback quand on tape sur Félix
  final VoidCallback? onTap;

  const FelixFloatingCompanion({
    super.key,
    this.alignment = Alignment.bottomRight,
    this.size = 80,
    this.isDraggable = true,
    this.onTap,
  });

  @override
  ConsumerState<FelixFloatingCompanion> createState() => _FelixFloatingCompanionState();
}

class _FelixFloatingCompanionState extends ConsumerState<FelixFloatingCompanion>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _pulseController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _pulseAnimation;
  
  Offset _position = Offset.zero;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _bounceAnimation = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeOutBack,
      ),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Pulse subtil en continu
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onTap() {
    HapticService.lightTap();
    
    setState(() => _isExpanded = !_isExpanded);
    
    _bounceController.forward().then((_) => _bounceController.reverse());
    
    widget.onTap?.call();
    
    // Réaction aléatoire de Félix
    final reactions = [
      'Coucou ! 👋',
      'Besoin d\'aide ?',
      'Je suis là !',
      'Scanne un reçu ?',
      'Tout va bien ?',
    ];
    
    final controller = ref.read(felixControllerProvider.notifier);
    controller.setAnimation(
      FelixAnimationType.idle,
      message: reactions[DateTime.now().millisecond % reactions.length],
    );
  }

  @override
  Widget build(BuildContext context) {
    final felixState = ref.watch(felixControllerProvider);
    
    if (!felixState.isVisible) return const SizedBox.shrink();
    
    return Align(
      alignment: widget.alignment,
      child: Padding(
        padding: const EdgeInsets.all(AuraDimensions.spaceM),
        child: GestureDetector(
          onTap: _onTap,
          child: AnimatedBuilder(
            animation: Listenable.merge([_bounceController, _pulseController]),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _bounceAnimation.value),
                child: Transform.scale(
                  scale: _pulseAnimation.value,
                  child: _buildFelixBubble(felixState),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFelixBubble(FelixState state) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Bulle de message si présente
        if (state.message != null && _isExpanded)
          Positioned(
            right: widget.size + 8,
            bottom: widget.size / 2 - 20,
            child: _buildMessageBubble(state.message!, state.subMessage),
          ),
        
        // Félix
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AuraColors.auraAmber, AuraColors.auraDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AuraColors.auraAmber.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/perso.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildFallbackFelix(),
            ),
          ),
        ),
        
        // Indicateur de notification
        if (state.animationType == FelixAnimationType.alert)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: AuraColors.auraRed,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageBubble(String message, String? subMessage) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.all(AuraDimensions.spaceM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: AuraColors.auraTextDark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              subMessage,
              style: const TextStyle(
                color: AuraColors.auraTextDarkSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFallbackFelix() {
    return Container(
      color: AuraColors.auraAmber,
      child: const Center(
        child: Text(
          'F',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Version minimale de Félix pour les petits espaces
class FelixMiniCompanion extends ConsumerWidget {
  final double size;
  final VoidCallback? onTap;

  const FelixMiniCompanion({
    super.key,
    this.size = 40,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final felixState = ref.watch(felixControllerProvider);
    
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        onTap?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: felixState.animationType == FelixAnimationType.alert
                ? [AuraColors.auraRed, AuraColors.auraRed.withOpacity(0.8)]
                : [AuraColors.auraAmber, AuraColors.auraDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AuraColors.auraAmber.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/perso.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Center(
              child: Text(
                'F',
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
