import 'dart:math' show pi, sin;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/app_localizations_extension.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../presentation/auth_controller.dart';

/// Écran d'inscription avec design premium
/// Glassmorphism + animations fluides + validation en temps réel
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  late AnimationController _bubblesController;
  late AnimationController _formController;
  late Animation<double> _formOpacityAnimation;
  late Animation<Offset> _formSlideAnimation;
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _fullNameFocusNode = FocusNode();
  
  bool _obscurePassword = true;
  bool _termsAccepted = false;

  @override
  void initState() {
    super.initState();
    
    // Controller pour les bulles animées
    _bubblesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    // Controller pour l'entrée du formulaire
    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _formOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _formSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: Curves.easeOutCubic,
    ));

    // Démarre l'animation du formulaire après un court délai
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _formController.forward();
      }
    });
  }

  @override
  void dispose() {
    _bubblesController.dispose();
    _formController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _fullNameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_validateForm()) return;
    
    HapticService.mediumTap();
    
    final authController = ref.read(authControllerProvider.notifier);
    await authController.signUp(
      _emailController.text.trim(),
      _passwordController.text,
      _fullNameController.text.trim(),
    );
  }

  bool _validateForm() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final fullName = _fullNameController.text.trim();

    if (fullName.isEmpty) {
      _showError('Veuillez entrer votre nom complet');
      return false;
    }

    if (email.isEmpty || !email.contains('@')) {
      _showError('Email invalide');
      return false;
    }

    if (password.length < 6) {
      _showError('Mot de passe trop court (min 6 caractères)');
      return false;
    }

    if (!_termsAccepted) {
      _showError('Veuillez accepter les conditions d\'utilisation');
      return false;
    }

    return true;
  }

  void _showError(String message) {
    HapticService.error();
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
          _showError(message);
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
                          opacity: _formOpacityAnimation,
                          child: SlideTransition(
                            position: _formSlideAnimation,
                            child: GlassCard(
                              borderRadius: AuraDimensions.radiusXL,
                              padding: const EdgeInsets.all(AuraDimensions.spaceXL),
                              blurStrength: 32,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Titre
                                  Text(
                                    context.l10n.createAccount,
                                    style: AuraTypography.h1.copyWith(
                                      color: AuraColors.auraTextPrimary,
                                      fontSize: 32,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AuraDimensions.spaceS),
                                  
                                  // Sous-titre
                                  Text(
                                    'Rejoins la communauté Aura',
                                    style: AuraTypography.bodyLarge.copyWith(
                                      color: AuraColors.auraTextPrimary
                                          .withOpacity(0.7),
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AuraDimensions.spaceXXL),
                                  
                                  // Champ Nom Complet
                                  _buildTextField(
                                    controller: _fullNameController,
                                    focusNode: _fullNameFocusNode,
                                    label: 'Nom complet',
                                    icon: Icons.person_outline,
                                    keyboardType: TextInputType.name,
                                  ),
                                  const SizedBox(height: AuraDimensions.spaceM),
                                  
                                  // Champ Email
                                  _buildTextField(
                                    controller: _emailController,
                                    focusNode: _emailFocusNode,
                                    label: context.l10n.email,
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: AuraDimensions.spaceM),
                                  
                                  // Champ Mot de passe
                                  _buildPasswordField(),
                                  const SizedBox(height: AuraDimensions.spaceM),
                                  
                                  // Checkbox CGU
                                  _buildTermsCheckbox(),
                                  const SizedBox(height: AuraDimensions.spaceXL),
                                  
                                  // Bouton Inscription
                                  _SignUpButton(
                                    onPressed: authState.maybeWhen(
                                      loading: () => null,
                                      orElse: () => _signUp,
                                    ),
                                    isLoading: authState.maybeWhen(
                                      loading: () => true,
                                      orElse: () => false,
                                    ),
                                  ),
                                  const SizedBox(height: AuraDimensions.spaceL),
                                  
                                  // Lien vers login
                                  _buildLoginLink(),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
  }) {
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
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        style: AuraTypography.bodyLarge.copyWith(
          color: AuraColors.auraTextPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AuraTypography.labelMedium.copyWith(
            color: AuraColors.auraTextPrimary.withOpacity(0.7),
          ),
          prefixIcon: Icon(
            icon,
            color: AuraColors.auraTextPrimary.withOpacity(0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AuraDimensions.spaceM,
            vertical: AuraDimensions.spaceL,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
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
        controller: _passwordController,
        focusNode: _passwordFocusNode,
        obscureText: _obscurePassword,
        style: AuraTypography.bodyLarge.copyWith(
          color: AuraColors.auraTextPrimary,
        ),
        decoration: InputDecoration(
          labelText: context.l10n.password,
          labelStyle: AuraTypography.labelMedium.copyWith(
            color: AuraColors.auraTextPrimary.withOpacity(0.7),
          ),
          prefixIcon: Icon(
            Icons.lock_outline,
            color: AuraColors.auraTextPrimary.withOpacity(0.5),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
              color: AuraColors.auraTextPrimary.withOpacity(0.5),
            ),
            onPressed: () {
              HapticService.lightTap();
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AuraDimensions.spaceM,
            vertical: AuraDimensions.spaceL,
          ),
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            HapticService.lightTap();
            setState(() => _termsAccepted = !_termsAccepted);
          },
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _termsAccepted
                  ? AuraColors.auraAmber
                  : AuraColors.auraGlass,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AuraColors.auraGlassBorder,
                width: 1,
              ),
            ),
            child: _termsAccepted
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'J\'accepte les conditions d\'utilisation et la politique de confidentialité',
            style: AuraTypography.bodySmall.copyWith(
              color: AuraColors.auraTextPrimary.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        context.goToLogin();
      },
      child: Text.rich(
        TextSpan(
          text: 'Déjà un compte ? ',
          style: AuraTypography.bodyMedium.copyWith(
            color: AuraColors.auraTextPrimary.withOpacity(0.7),
          ),
          children: [
            TextSpan(
              text: 'Se connecter',
              style: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.auraAmber,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Bouton d'inscription avec loading state
class _SignUpButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _SignUpButton({
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AuraColors.auraAmber, AuraColors.auraDeep],
          ),
          borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
          boxShadow: [
            BoxShadow(
              color: AuraColors.auraAmber.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Créer mon compte',
                  style: AuraTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
