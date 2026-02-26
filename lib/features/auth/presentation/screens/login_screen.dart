import 'dart:math' show pi, sin;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../presentation/auth_controller.dart';

/// Écran de login avec Social Auth
/// Design premium avec glassmorphism et bulles animées
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _bubblesController;
  late AnimationController _cardController;
  late Animation<double> _cardOpacityAnimation;
  late Animation<Offset> _cardSlideAnimation;
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    
    // Controller pour les bulles animées
    _bubblesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    // Controller pour l'entrée de la carte
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _cardOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutCubic,
    ));

    // Démarre l'animation de la carte après un court délai
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _cardController.forward();
      }
    });
  }

  @override
  void dispose() {
    _bubblesController.dispose();
    _cardController.dispose();
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _signInWithApple() async {
    HapticService.lightTap();
    await ref.read(authControllerProvider.notifier).signInWithApple();
  }

  Future<void> _signInWithGoogle() async {
    HapticService.lightTap();
    await ref.read(authControllerProvider.notifier).signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    
    // Écoute les changements d'état pour la navigation
    ref.listen(authControllerProvider, (previous, next) {
      next.when(
        initial: () {},
        loading: () {},
        authenticated: (_) => context.goToOnboarding(),
        unauthenticated: () {},
        error: (message) {
          _showErrorSnackBar(message);
        },
      );
    });

    return Scaffold(
      backgroundColor: AuraColors.auraBackground,
      resizeToAvoidBottomInset: true,
      body: AnimatedBuilder(
        animation: _bubblesController,
        builder: (context, child) {
          return Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2),
                radius: 1.0,
                colors: [
                  AuraColors.auraAmber,
                  AuraColors.auraDeep,
                  AuraColors.auraDark,
                ],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Bulles floutées animées en arrière-plan
                ...List.generate(3, (index) => _buildBubble(index)),
                
                // Contenu principal
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AuraDimensions.spaceXL,
                    ),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        
                        // Carte Glassmorphism
                        FadeTransition(
                          opacity: _cardOpacityAnimation,
                          child: SlideTransition(
                            position: _cardSlideAnimation,
                            child: GlassCard(
                              borderRadius: AuraDimensions.radiusXL,
                              padding: const EdgeInsets.all(AuraDimensions.spaceXL),
                              blurStrength: 32,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Titre
                                  Text(
                                    'Bienvenue',
                                    style: AuraTypography.h1.copyWith(
                                      color: AuraColors.auraTextPrimary,
                                      fontSize: 36,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AuraDimensions.spaceS),
                                  
                                  // Sous-titre
                                  Text(
                                    'Votre santé financière, réinventée',
                                    style: AuraTypography.bodyLarge.copyWith(
                                      color: AuraColors.auraTextPrimary
                                          .withOpacity(0.7),
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AuraDimensions.spaceXXL),
                                  
                                  // Bouton Apple
                                  _AppleSignInButton(
                                    onPressed: authState.maybeWhen(
                                      loading: () => null,
                                      orElse: () => _signInWithApple,
                                    ),
                                  ),
                                  const SizedBox(height: AuraDimensions.spaceM),
                                            
                                  // Bouton Google
                                  _GoogleSignInButton(
                                    onPressed: authState.maybeWhen(
                                      loading: () => null,
                                      orElse: () => _signInWithGoogle,
                                    ),
                                  ),
                                  const SizedBox(height: AuraDimensions.spaceXL),
                                  
                                  // Séparateur
                                  _buildSeparator(),
                                  const SizedBox(height: AuraDimensions.spaceXL),
                                  
                                  // Champ email discret
                                  _buildEmailField(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        const Spacer(flex: 3),
                      ],
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

  Widget _buildBubble(int index) {
    final animationValue = _bubblesController.value;
    final phase = index * 2.0;
    
    // Mouvement circulaire lent
    final offsetX = sin((animationValue * 2 * pi) + phase) * 50;
    final offsetY = sin((animationValue * 2 * pi * 0.7) + phase + 1) * 30;
    
    final sizes = [200.0, 150.0, 180.0];
    final positions = [
      const Offset(-0.2, 0.1),
      const Offset(0.7, 0.3),
      const Offset(0.1, 0.6),
    ];
    final opacities = [0.15, 0.1, 0.12];
    
    final size = sizes[index];
    final basePos = positions[index];
    final opacity = opacities[index];
    
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Positioned(
      left: basePos.dx * screenWidth + offsetX,
      top: basePos.dy * screenHeight + offsetY,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AuraColors.auraTextPrimary.withOpacity(opacity),
              AuraColors.auraTextPrimary.withOpacity(0),
            ],
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            color: Colors.transparent,
          ),
        ),
      ),
    );
  }

  Widget _buildSeparator() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AuraColors.auraTextPrimary.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AuraDimensions.spaceM,
          ),
          child: Text(
            'ou',
            style: AuraTypography.bodyMedium.copyWith(
              color: AuraColors.auraTextPrimary.withOpacity(0.6),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AuraColors.auraTextPrimary.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: AuraColors.auraGlass,
        borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
        border: Border.all(
          color: AuraColors.auraGlassBorder,
          width: 1,
        ),
      ),
      child: TextField(
        controller: _emailController,
        focusNode: _emailFocusNode,
        keyboardType: TextInputType.emailAddress,
        style: AuraTypography.bodyLarge.copyWith(
          color: AuraColors.auraTextPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Continuer avec email',
          hintStyle: AuraTypography.bodyLarge.copyWith(
            color: AuraColors.auraTextPrimary.withOpacity(0.5),
          ),
          prefixIcon: Icon(
            Icons.email_outlined,
            color: AuraColors.auraTextPrimary.withOpacity(0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AuraDimensions.spaceM,
            vertical: AuraDimensions.spaceM,
          ),
        ),
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            HapticService.lightTap();
            // TODO: Navigate to email sign in
          }
        },
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AuraTypography.bodyMedium.copyWith(
            color: AuraColors.auraTextPrimary,
          ),
        ),
        backgroundColor: AuraColors.auraRed.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
        ),
        margin: const EdgeInsets.all(AuraDimensions.spaceM),
      ),
    );
  }
}

/// Bouton Sign In with Apple
class _AppleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _AppleSignInButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.apple,
              size: 24,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(
              'Continuer avec Apple',
              style: AuraTypography.labelLarge.copyWith(
                color: Colors.white,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton Sign In with Google
class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _GoogleSignInButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Google coloré simplifié
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4285F4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Continuer avec Google',
              style: AuraTypography.labelLarge.copyWith(
                color: const Color(0xFF333333),
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
