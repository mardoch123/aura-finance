import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/aura_colors.dart';
import '../theme/aura_dimensions.dart';
import '../theme/aura_typography.dart';
import '../widgets/glass_card.dart';
import '../haptics/haptic_service.dart';
import '../felix/felix_controller.dart';
import '../felix/felix_animation_type.dart';
import '../felix/widgets/felix_mascot.dart';
import 'aura_button.dart';

/// Empty states animés avec Félix comme compagnon
class FelixEmptyStates {
  /// Aucune transaction
  static Widget noTransactions({
    required VoidCallback onAddTransaction,
    String? customMessage,
  }) {
    return _FelixEmptyState(
      felixAnimation: FelixAnimationType.idle,
      title: 'Aucune transaction',
      message: customMessage ?? 'Commence par scanner ton premier ticket de caisse',
      felixMessage: 'Je suis prêt à t\'aider !📸      actionButton: _ActionButton(
        label: 'Scanner maintenant',
        icon: Icons.camera_alt,
        onPressed: onAddTransaction,
      ),
      felixPosition: Alignment.bottomCenter,
    );
  }

  /// Aucun compte
  static Widget noAccounts({
    required VoidCallback onAddAccount,
  }) {
    return _FelixEmptyState(
      felixAnimation: FelixAnimationType.curious,
      title: 'Aucun compte',
      message: 'Ajoute ton premier compte pour commencer à suivre tes finances',
      felixMessage: 'Où ranges-tu ton argent ?😊',
      actionButton: _ActionButton(
        label: 'Ajouter un compte',
        icon: Icons.account_balance,
        onPressed: onAddAccount,
      ),
    );
  }

  /// Aucun objectif
  static Widget noGoals({
    required VoidCallback onAddGoal,
  }) {
    return _FelixEmptyState(
      felixAnimation: FelixAnimationType.motivated,
      title: 'Aucun objectif',
      message: 'Définis tes objectifs financiers pour rester motivé',
      felixMessage: 'Quel est ton rêve ? Je t\'aide à l\'atteindre !✨      actionButton: _ActionButton(
        label: 'Créer un objectif',
        icon: Icons.flag,
        onPressed: onAddGoal,
      ),
    );
  }

  /// Aucune analyse
  static Widget noInsights() {
    return _FelixEmptyState(
      felixAnimation: FelixAnimationType.thinking,
      title: 'Analyse en cours',
      message: 'Félix analyse tes habitudes pour te donner des insights',
      felixMessage: 'Je réfléchis... ça va prendre quelques secondes      showActionButton: false,
    );
  }

  /// Aucun défi
  static Widget noChallenges({
    required VoidCallback onCreateChallenge,
  }) {
    return _FelixEmptyState(
      felixAnimation: FelixAnimationType.competitive,
      title: 'Aucun défi',
      message: 'Défie tes amis ou rejoins un défi pour t\'amuser',
      felixMessage: 'Qui va gagner ? Moi j\'espère que ce sera toi !      actionButton: _ActionButton(
        label: 'Créer un défi',
        icon: Icons.group,
        onPressed: onCreateChallenge,
      ),
    );
  }

  /// Aucune notification
  static Widget noNotifications() {
    return _FelixEmptyState(
      felixAnimation: FelixAnimationType.sleeping,
      title: 'Rien de neuf',
      message: 'Pas de nouvelles notifications pour le moment',
      felixMessage: 'Je surveille tout, je te préviens dès qu\'il y a quelque chose ! 😴',
      showActionButton: false,
    );
  }

  /// Erreur de connexion
  static Widget connectionError({
    required VoidCallback onRetry,
  }) {
    return _FelixEmptyState(
      felixAnimation: FelixAnimationType.confused,
      title: 'Connexion perdue',
      message: 'Vérifie ta connexion internet et réessaie',
      felixMessage: 'Oups, je ne capte plus rien...      actionButton: _ActionButton(
        label: 'Réessayer',
        icon: Icons.refresh,
        onPressed: onRetry,
      ),
      felixColor: AuraColors.auraRed,
    );
  }

  /// Résultat de recherche vide
  static Widget searchEmpty({
    required String searchTerm,
  }) {
    return _FelixEmptyState(
      felixAnimation: FelixAnimationType.searching,
      title: 'Aucun résultat',
      message: 'Aucune transaction ne correspond à "$searchTerm"',
      felixMessage: 'Hmm, je ne trouve rien avec ce mot...🔍',
      showActionButton: false,
    );
  }
}

/// Widget de base pour les empty states avec Félix
class _FelixEmptyState extends ConsumerStatefulWidget {
  final FelixAnimationType felixAnimation;
  final String title;
  final String message;
  final String felixMessage;
  final _ActionButton? actionButton;
  final bool showActionButton;
  final Alignment felixPosition;
  final Color? felixColor;

  const _FelixEmptyState({
    required this.felixAnimation,
    required this.title,
    required this.message,
    required this.felixMessage,
    this.actionButton,
    this.showActionButton = true,
    this.felixPosition = Alignment.center,
    this.felixColor,
  });

  @override
  ConsumerState<_FelixEmptyState> createState() => _FelixEmptyStateState();
}

class _FelixEmptyStateState extends ConsumerState<_FelixEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    // Démarrer l'animation
    _controller.forward();
    
    // Faire parler Félix
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(felixControllerProvider.notifier).triggerEvent(
        FelixEvent.custom,
        customMessage: widget.felixMessage,
      );
      HapticService.lightTap();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AuraDimensions.spaceXL),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Félix
            AnimatedAlign(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              alignment: widget.felixPosition,
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: FelixMascot(
                  animationType: widget.felixAnimation,
                  size: 120,
                  color: widget.felixColor,
                ),
              ),
            ),
            const SizedBox(height: AuraDimensions.spaceL),
            
            // Contenu
            GlassCard(
              padding: const EdgeInsets.all(AuraDimensions.spaceL),
              child: Column(
                children: [
                  // Titre
                  Text(
                    widget.title,
                    style: AuraTypography.titleLarge.copyWith(
                      color: AuraColors.auraTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AuraDimensions.spaceM),
                  
                  // Message
                  Text(
                    widget.message,
                    style: AuraTypography.bodyMedium.copyWith(
                      color: AuraColors.auraTextSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AuraDimensions.spaceL),
                  
                  // Bouton d'action
                  if (widget.showActionButton && widget.actionButton != null)
                    widget.actionButton!,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton d'action pour les empty states
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AuraButton.primary(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: AuraDimensions.spaceS),
            Text(label, style: AuraTypography.labelLarge),
          ],
        ),
      ),
    );
  }
}