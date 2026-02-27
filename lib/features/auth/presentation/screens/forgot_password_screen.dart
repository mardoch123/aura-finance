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

/// Écran de réinitialisation de mot de passe
/// Design premium avec validation email et feedback visuel
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  late AnimationController _bubblesController;
  late AnimationController _cardController;
  late Animation<double> _cardOpacityAnimation;
  late Animation<Offset> _cardSlideAnimation;
  
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  
  bool _isSent = false;
  String? _sentToEmail;

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

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty || !email.contains('@')) {
      _showError('Veuillez entrer un email valide');
      return;
    }

    HapticService.mediumTap();
    
    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.resetPassword(email);
      
      setState(() {
        _isSent = true;
        _sentToEmail = email;
      });
      
      HapticService.success();
      
    } catch (e) {
      _showError('Erreur lors de l\'envoi : ${e.toString()}');
    }
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
    return Scaffold(
      backgroundColor: AuraColors.auraBackground,
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
                              child: _isSent
                                  ? _buildSuccessContent()
                                  : _buildFormContent(),
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

  Widget _buildFormContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icône
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AuraColors.auraAmber, AuraColors.auraDeep],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_reset,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: AuraDimensions.spaceXL),
        
        // Titre
        Text(
          'Mot de passe oublié ?',
          style: AuraTypography.h1.copyWith(
            color: AuraColors.auraTextPrimary,
            fontSize: 32,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AuraDimensions.spaceS),
        
        // Sous-titre
        Text(
          'Entrez votre email pour recevoir un lien de réinitialisation',
          style: AuraTypography.bodyLarge.copyWith(
            color: AuraColors.auraTextPrimary.withOpacity(0.7),
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AuraDimensions.spaceXXL),
        
        // Champ Email
        _buildEmailField(),
        const SizedBox(height: AuraDimensions.spaceXL),
        
        // Bouton Envoyer
        _SendButton(
          onPressed: _sendResetLink,
        ),
        const SizedBox(height: AuraDimensions.spaceL),
        
        // Lien retour
        _buildBackLink(),
      ],
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icône succès
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: AuraColors.auraGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: AuraDimensions.spaceXL),
        
        // Titre
        Text(
          'Email envoyé !',
          style: AuraTypography.h1.copyWith(
            color: AuraColors.auraTextPrimary,
            fontSize: 32,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AuraDimensions.spaceS),
        
        // Message
        Text(
          'Un lien de réinitialisation a été envoyé à :',
          style: AuraTypography.bodyLarge.copyWith(
            color: AuraColors.auraTextPrimary.withOpacity(0.7),
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AuraDimensions.spaceM),
        Text(
          _sentToEmail ?? '',
          style: AuraTypography.bodyLarge.copyWith(
            color: AuraColors.auraTextPrimary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AuraDimensions.spaceXXL),
        
        // Instructions
        Container(
          padding: const EdgeInsets.all(AuraDimensions.spaceM),
          decoration: BoxDecoration(
            color: AuraColors.auraGlass,
            borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
          ),
          child: Column(
            children: [
              Text(
                '💡 Conseils :',
                style: AuraTypography.labelMedium.copyWith(
                  color: AuraColors.auraTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '• Vérifiez vos spams\n• Le lien expire dans 1 heure\n• Ne partagez pas ce lien',
                style: AuraTypography.bodySmall.copyWith(
                  color: AuraColors.auraTextPrimary.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: AuraDimensions.spaceXL),
        
        // Bouton retour
        _BackToLoginButton(
          onPressed: () {
            HapticService.lightTap();
            context.goToLogin();
          },
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
          labelText: context.l10n.email,
          labelStyle: AuraTypography.labelMedium.copyWith(
            color: AuraColors.auraTextPrimary.withOpacity(0.7),
          ),
          prefixIcon: Icon(
            Icons.email_outlined,
            color: AuraColors.auraTextPrimary.withOpacity(0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AuraDimensions.spaceM,
            vertical: AuraDimensions.spaceL,
          ),
        ),
        onSubmitted: (_) => _sendResetLink(),
      ),
    );
  }

  Widget _buildBackLink() {
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        context.goToLogin();
      },
      child: Text.rich(
        TextSpan(
          text: 'Retour à ',
          style: AuraTypography.bodyMedium.copyWith(
            color: AuraColors.auraTextPrimary.withOpacity(0.7),
          ),
          children: [
            TextSpan(
              text: 'la connexion',
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

/// Bouton d'envoi avec état
class _SendButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SendButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
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
        child: const Center(
          child: Text(
            'Envoyer le lien',
            style: TextStyle(
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

/// Bouton retour à la connexion
class _BackToLoginButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BackToLoginButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AuraColors.auraGlass,
          borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
          border: Border.all(
            color: AuraColors.auraGlassBorder,
            width: 1,
          ),
        ),
        child: const Center(
          child: Text(
            'Retour à la connexion',
            style: TextStyle(
              color: AuraColors.auraTextPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
