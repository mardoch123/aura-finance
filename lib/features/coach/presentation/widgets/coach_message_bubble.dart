import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/coach_message.dart';
import 'typing_indicator.dart';

/// Bubble de message pour le chat
class CoachMessageBubble extends StatelessWidget {
  const CoachMessageBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
    this.onActionPressed,
  });

  final CoachMessage message;
  final bool showAvatar;
  final Function(CoachAction)? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AuraDimensions.spaceM,
        vertical: AuraDimensions.spaceXS,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar pour le coach (gauche)
          if (!isUser && showAvatar) ...[
            _buildCoachAvatar(),
            const SizedBox(width: AuraDimensions.spaceS),
          ],
          
          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                _buildBubble(isUser),
                
                // Actions suggérées
                if (message.actions != null && message.actions!.isNotEmpty)
                  _buildActions(),
              ],
            ),
          ),
          
          // Espace pour l'utilisateur (droite)
          if (isUser) const SizedBox(width: 40),
        ],
      ),
    ).animate(
      effects: [
        FadeEffect(
          duration: 300.ms,
          curve: Curves.easeOut,
        ),
        SlideEffect(
          begin: Offset(isUser ? 0.1 : -0.1, 0),
          end: Offset.zero,
          duration: 300.ms,
          curve: Curves.easeOutBack,
        ),
      ],
    );
  }

  Widget _buildCoachAvatar() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        gradient: AuraColors.gradientAmber,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.auto_awesome,
        color: AuraColors.auraTextPrimary,
        size: 12,
      ),
    );
  }

  Widget _buildBubble(bool isUser) {
    // Radius personnalisés selon le type de message
    final borderRadius = isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(22),
            bottomRight: Radius.circular(22),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(22),
            bottomLeft: Radius.circular(22),
            bottomRight: Radius.circular(22),
          );

    if (isUser) {
      // Message utilisateur - gradient solide
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AuraDimensions.spaceM,
          vertical: AuraDimensions.spaceS + 4,
        ),
        decoration: BoxDecoration(
          gradient: AuraColors.gradientAmber,
          borderRadius: borderRadius,
          boxShadow: AuraDimensions.shadowLight,
        ),
        child: Text(
          message.content,
          style: AuraTypography.bodyMedium.copyWith(
            color: AuraColors.auraTextPrimary,
          ),
        ),
      );
    } else {
      // Message coach - glass card
      return GlassCard(
        borderRadius: 22,
        padding: const EdgeInsets.symmetric(
          horizontal: AuraDimensions.spaceM,
          vertical: AuraDimensions.spaceS + 4,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x40FFFFFF),
            Color(0x20FFFFFF),
          ],
        ),
        borderColor: const Color(0x40FFFFFF),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contenu texte
            if (message.isStreaming && message.content.isEmpty)
              const TypingIndicator()
            else
              Text(
                message.content,
                style: AuraTypography.bodyMedium.copyWith(
                  color: AuraColors.auraTextDark,
                  height: 1.5,
                ),
              ),
            
            // Indicateur de streaming (curseur clignotant)
            if (message.isStreaming && message.content.isNotEmpty)
              _buildCursor(),
          ],
        ),
      );
    }
  }

  Widget _buildCursor() {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      child: _BlinkingCursor(),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.only(top: AuraDimensions.spaceS),
      child: Wrap(
        spacing: AuraDimensions.spaceXS,
        runSpacing: AuraDimensions.spaceXS,
        children: message.actions!.map((action) {
          return ActionChip(
            label: Text(
              action.label,
              style: AuraTypography.labelSmall.copyWith(
                color: AuraColors.auraDeep,
              ),
            ),
            backgroundColor: AuraColors.auraGlass,
            side: const BorderSide(color: AuraColors.auraGlassBorder),
            onPressed: () {
              HapticFeedback.lightImpact();
              onActionPressed?.call(action);
            },
          );
        }).toList(),
      ),
    );
  }
}

/// Curseur clignotant pour l'effet typewriter
class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
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
        return Opacity(
          opacity: _controller.value,
          child: Container(
            width: 2,
            height: 16,
            color: AuraColors.auraAmber,
          ),
        );
      },
    );
  }
}
