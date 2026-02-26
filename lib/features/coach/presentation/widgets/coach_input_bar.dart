import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/coach_message.dart';

/// Barre d'input flottante pour le chat
class CoachInputBar extends StatefulWidget {
  const CoachInputBar({
    super.key,
    required this.onSend,
    this.onVoicePressed,
    this.suggestions = const [],
    this.isListening = false,
    this.isLoading = false,
  });

  final Function(String) onSend;
  final VoidCallback? onVoicePressed;
  final List<QuickSuggestion> suggestions;
  final bool isListening;
  final bool isLoading;

  @override
  State<CoachInputBar> createState() => _CoachInputBarState();
}

class _CoachInputBarState extends State<CoachInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _controller.text.trim().isNotEmpty;
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !widget.isLoading) {
      HapticFeedback.lightImpact();
      widget.onSend(text);
      _controller.clear();
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Suggestions rapides
        if (widget.suggestions.isNotEmpty)
          _buildSuggestions(),
        
        const SizedBox(height: AuraDimensions.spaceS),
        
        // Input bar
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AuraDimensions.spaceM,
            vertical: AuraDimensions.spaceS,
          ),
          child: GlassCard(
            borderRadius: AuraDimensions.radiusXXL,
            padding: const EdgeInsets.symmetric(
              horizontal: AuraDimensions.spaceS,
              vertical: AuraDimensions.spaceXS,
            ),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0x50FFFFFF),
                Color(0x30FFFFFF),
              ],
            ),
            child: Row(
              children: [
                // Bouton micro
                _buildVoiceButton(),
                
                // TextField
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: !widget.isLoading,
                    style: AuraTypography.bodyMedium.copyWith(
                      color: AuraColors.auraTextDark,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.isListening 
                          ? 'Écoute...' 
                          : 'Demandez à Aura...',
                      hintStyle: AuraTypography.bodyMedium.copyWith(
                        color: AuraColors.auraTextDarkSecondary.withOpacity(0.6),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AuraDimensions.spaceS,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: 1,
                  ),
                ),
                
                // Bouton envoyer
                AnimatedOpacity(
                  opacity: _hasText ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: _buildSendButton(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceM),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: AuraDimensions.spaceXS),
        itemBuilder: (context, index) {
          final suggestion = widget.suggestions[index];
          return _SuggestionChip(
            label: suggestion.label,
            onTap: () {
              HapticFeedback.lightImpact();
              _controller.text = suggestion.query;
              _onTextChanged();
              _focusNode.requestFocus();
            },
          );
        },
      ),
    );
  }

  Widget _buildVoiceButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: widget.isListening 
            ? AuraColors.auraRed.withOpacity(0.2)
            : Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: widget.isLoading ? null : widget.onVoicePressed,
          customBorder: const CircleBorder(),
          child: Container(
            padding: const EdgeInsets.all(AuraDimensions.spaceS),
            child: widget.isListening
                ? _buildWaveform()
                : Icon(
                    Icons.mic,
                    color: widget.isLoading
                        ? AuraColors.auraTextDarkSecondary
                        : AuraColors.auraDeep,
                    size: 24,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaveform() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AuraColors.auraRed,
            borderRadius: BorderRadius.circular(2),
          ),
        ).animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        ).scaleY(
          begin: 0.3,
          end: 1.0,
          duration: 400.ms,
          delay: (index * 100).ms,
          curve: Curves.easeInOut,
        );
      }),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _sendMessage,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: AuraColors.gradientAmber,
          shape: BoxShape.circle,
          boxShadow: AuraDimensions.shadowLight,
        ),
        child: const Icon(
          Icons.arrow_upward,
          color: AuraColors.auraTextPrimary,
          size: 20,
        ),
      ),
    );
  }
}

/// Chip de suggestion
class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: AuraDimensions.radiusS,
        padding: const EdgeInsets.symmetric(
          horizontal: AuraDimensions.spaceM,
          vertical: AuraDimensions.spaceXS,
        ),
        child: Text(
          label,
          style: AuraTypography.labelSmall.copyWith(
            color: AuraColors.auraTextDark,
          ),
        ),
      ),
    );
  }
}
