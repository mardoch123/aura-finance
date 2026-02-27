import 'package:flutter/material.dart';
import '../../theme/aura_colors.dart';
import '../../theme/aura_typography.dart';
import '../felix_animation_type.dart';

/// Widget principal de la mascotte Félix
/// Affiche Félix avec différentes animations selon le contexte
class FelixMascot extends StatefulWidget {
  /// Type d'animation à afficher
  final FelixAnimationType animationType;
  
  /// Taille du widget
  final double size;
  
  /// Message optionnel à afficher sous Félix
  final String? message;
  
  /// Sous-message optionnel
  final String? subMessage;
  
  /// Si l'animation doit boucler
  final bool? loop;
  
  /// Callback quand l'animation est terminée
  final VoidCallback? onAnimationComplete;
  
  /// Si Félix est cliquable
  final bool isInteractive;
  
  /// Callback quand on tape sur Félix
  final VoidCallback? onTap;

  const FelixMascot({
    super.key,
    required this.animationType,
    this.size = 180,
    this.message,
    this.subMessage,
    this.loop,
    this.onAnimationComplete,
    this.isInteractive = false,
    this.onTap,
  });

  @override
  State<FelixMascot> createState() => _FelixMascotState();
}

class _FelixMascotState extends State<FelixMascot>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _bounceController;
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  
  Animation<double>? _bounceAnimation;
  Animation<double>? _pulseAnimation;
  Animation<double>? _shakeAnimation;
  Animation<double>? _scaleAnimation;
  Animation<double>? _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupAnimations();
    _startAnimation();
  }

  void _initializeControllers() {
    _mainController = AnimationController(
      vsync: this,
      duration: widget.animationType.duration,
    );
    
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _mainController.addStatusListener(_onAnimationStatusChanged);
  }

  void _setupAnimations() {
    // Animation de rebond
    _bounceAnimation = Tween<double>(begin: 0, end: -20).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeOut,
      ),
    );

    // Animation de pulsation
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Animation de secousse
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -5, end: 5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 5, end: -5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -5, end: 5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 5, end: 0), weight: 1),
    ]).animate(_shakeController);

    // Échelle selon le type
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Curves.easeOutBack,
      ),
    );

    // Rotation
    _rotateAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _startAnimation() {
    final shouldLoop = widget.loop ?? widget.animationType.shouldLoop;
    
    switch (widget.animationType) {
      case FelixAnimationType.idle:
        _pulseController.repeat(reverse: true);
        break;
      case FelixAnimationType.scan:
        _pulseController.repeat(reverse: true);
        _shakeController.repeat();
        break;
      case FelixAnimationType.success:
        _bounceController.forward().then((_) {
          _bounceController.reverse();
        });
        if (shouldLoop) {
          _mainController.repeat(reverse: true);
        } else {
          _mainController.forward();
        }
        break;
      case FelixAnimationType.celebrate:
        _bounceController.repeat(reverse: true);
        if (shouldLoop) {
          _mainController.repeat(reverse: true);
        } else {
          _mainController.forward();
        }
        break;
      case FelixAnimationType.alert:
        _shakeController.forward();
        _mainController.forward();
        break;
      case FelixAnimationType.thinking:
        _pulseController.repeat(reverse: true);
        break;
      case FelixAnimationType.streakHigh:
        _pulseController.repeat(reverse: true);
        break;
      default:
        if (shouldLoop) {
          _mainController.repeat(reverse: true);
        } else {
          _mainController.forward();
        }
    }
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && 
        !(widget.loop ?? widget.animationType.shouldLoop)) {
      widget.onAnimationComplete?.call();
    }
  }

  @override
  void didUpdateWidget(FelixMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationType != widget.animationType) {
      _resetAndStartAnimation();
    }
  }

  void _resetAndStartAnimation() {
    _mainController.stop();
    _bounceController.stop();
    _pulseController.stop();
    _shakeController.stop();
    
    _mainController.reset();
    _bounceController.reset();
    _pulseController.reset();
    _shakeController.reset();
    
    _setupAnimations();
    _startAnimation();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _bounceController.dispose();
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isInteractive ? widget.onTap : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Félix animé
          AnimatedBuilder(
            animation: Listenable.merge([
              _mainController,
              _bounceController,
              _pulseController,
              _shakeController,
            ]),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  _shakeAnimation?.value ?? 0,
                  _bounceAnimation?.value ?? 0,
                ),
                child: Transform.scale(
                  scale: (_pulseAnimation?.value ?? 1.0) * (_scaleAnimation?.value ?? 1.0),
                  child: Transform.rotate(
                    angle: _getRotation(),
                    child: _buildFelixImage(),
                  ),
                ),
              );
            },
          ),
          
          // Message
          if (widget.message != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.message!,
              style: AuraTypography.bodyLarge.copyWith(
                color: AuraColors.auraTextDark,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          
          // Sous-message
          if (widget.subMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.subMessage!,
              style: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.auraTextDarkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  double _getRotation() {
    switch (widget.animationType) {
      case FelixAnimationType.idle:
        return _rotateAnimation?.value ?? 0;
      case FelixAnimationType.thinking:
        return -0.05;
      case FelixAnimationType.empty:
        return 0.05;
      default:
        return 0;
    }
  }

  Widget _buildFelixImage() {
    // Utilise l'image de Félix avec des effets selon l'animation
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: _getDecoration(),
      child: ClipOval(
        child: Image.asset(
          'assets/images/perso.png',
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback si l'image n'existe pas
            return _buildFallbackFelix();
          },
        ),
      ),
    );
  }

  BoxDecoration? _getDecoration() {
    switch (widget.animationType) {
      case FelixAnimationType.pro:
        return BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AuraColors.auraAccentGold,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: AuraColors.auraAccentGold.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        );
      case FelixAnimationType.streakHigh:
        return BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AuraColors.auraAmber.withOpacity(0.5),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        );
      default:
        return null;
    }
  }

  Widget _buildFallbackFelix() {
    // Fallback stylisé si l'image n'est pas disponible
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AuraColors.auraAmber, AuraColors.auraDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AuraColors.auraAmber.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'F',
          style: TextStyle(
            fontSize: widget.size * 0.5,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
