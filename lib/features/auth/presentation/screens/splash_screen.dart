import 'dart:math' show pi, sin;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../presentation/auth_controller.dart';

/// Écran Splash avec animation premium
/// Affiche le logo AURA avec particules animées pendant 2.5 secondes
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _particlesController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _fadeOutAnimation;

  @override
  void initState() {
    super.initState();
    
    // Configuration immersive
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    
    // Controller pour l'animation du logo (entrée)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Controller pour les particules (loop)
    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Animation du logo: scale 0.8→1.0 avec easeOutBack
    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.8, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
    ]).animate(_logoController);

    // Animation du logo: opacity 0→1
    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    ));

    // Animation de fade out
    _fadeOutAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
    ));

    // Démarre l'animation
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    // Petit délai avant de commencer
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (mounted) {
      await _logoController.forward();
      
      // Attend la fin de l'animation puis navigue
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (mounted) {
        _navigateToNext();
      }
    }
  }

  void _navigateToNext() {
    HapticService.lightTap();
    
    final authState = ref.read(authControllerProvider);
    
    authState.when(
      initial: () => context.goToLogin(),
      loading: () {},
      authenticated: (_) => context.goToDashboard(),
      unauthenticated: () => context.goToLogin(),
      error: (_) => context.goToLogin(),
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _logoController.dispose();
    _particlesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraColors.auraBackground,
      body: AnimatedBuilder(
        animation: Listenable.merge([_logoController, _particlesController]),
        builder: (context, child) {
          return Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.2,
                colors: [
                  AuraColors.auraAmber,
                  AuraColors.auraDeep,
                  AuraColors.auraDark,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Particules ambiantes
                ...List.generate(12, (index) => _buildParticle(index)),
                
                // Contenu principal avec fade out
                Opacity(
                  opacity: _fadeOutAnimation.value,
                  child: Transform.scale(
                    scale: 1.0 + (1.0 - _fadeOutAnimation.value) * 0.05,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo AURA
                          FadeTransition(
                            opacity: _logoOpacityAnimation,
                            child: ScaleTransition(
                              scale: _logoScaleAnimation,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'AURA',
                                    style: AuraTypography.h1.copyWith(
                                      color: AuraColors.auraTextPrimary,
                                      fontSize: 42,
                                      letterSpacing: 8,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'FINANCE',
                                    style: AuraTypography.bodyMedium.copyWith(
                                      color: AuraColors.auraTextPrimary
                                          .withOpacity(0.6),
                                      fontSize: 14,
                                      letterSpacing: 6,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildParticle(int index) {
    final random = Random(index);
    final size = 4.0 + random.nextDouble() * 8;
    final baseX = 0.1 + random.nextDouble() * 0.8;
    final baseY = 0.1 + random.nextDouble() * 0.8;
    final speed = 0.3 + random.nextDouble() * 0.7;
    final phase = random.nextDouble() * 2 * pi;
    
    final animationValue = _particlesController.value;
    final offsetX = sin((animationValue * 2 * pi * speed) + phase) * 30;
    final offsetY = sin((animationValue * 2 * pi * speed * 0.7) + phase + 1) * 20;
    
    return Positioned(
      left: baseX * MediaQuery.of(context).size.width + offsetX - size / 2,
      top: baseY * MediaQuery.of(context).size.height + offsetY - size / 2,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AuraColors.auraTextPrimary.withOpacity(0.3),
          boxShadow: [
            BoxShadow(
              color: AuraColors.auraAmber.withOpacity(0.3),
              blurRadius: size * 2,
              spreadRadius: size * 0.5,
            ),
          ],
        ),
      ),
    );
  }
}

/// Générateur de nombres aléatoires déterministe pour les particules
class Random {
  final int seed;
  late int _state;

  Random(this.seed) {
    _state = seed * 1103515245 + 12345;
  }

  double nextDouble() {
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    return _state / 0x7fffffff;
  }
}
