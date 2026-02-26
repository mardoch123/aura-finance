import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/aura_colors.dart';
import '../../../core/theme/aura_dimensions.dart';
import '../../../core/theme/aura_typography.dart';
import '../../../core/haptics/haptic_service.dart';
import 'coach_chat_provider.dart';
import '../domain/coach_message.dart';
import 'widgets/coach_chat_header.dart';
import 'widgets/coach_message_bubble.dart';
import 'widgets/coach_input_bar.dart';
import 'widgets/coach_rich_cards.dart';

/// Écran principal du chat avec le Coach Aura
class CoachChatScreen extends ConsumerStatefulWidget {
  const CoachChatScreen({super.key});

  @override
  ConsumerState<CoachChatScreen> createState() => _CoachChatScreenState();
}

class _CoachChatScreenState extends ConsumerState<CoachChatScreen> {
  final _scrollController = ScrollController();
  final _listViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Initialize chat when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(coachChatProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coachChatProvider);
    
    // Auto-scroll when new messages arrive
    ref.listen(coachChatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    return Scaffold(
      backgroundColor: AuraColors.auraBackground,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Header
            CoachChatHeader(
              isOnline: state.status != ChatStatus.offline,
              onSettingsPressed: () => _showSettingsMenu(context),
            ),
            
            // Messages list
            Expanded(
              child: _buildMessagesList(state),
            ),
            
            // Offline indicator
            if (state.status == ChatStatus.offline)
              _buildOfflineBanner(),
            
            // Error banner
            if (state.errorMessage != null)
              _buildErrorBanner(state.errorMessage!),
            
            // Input bar
            CoachInputBar(
              onSend: (message) {
                HapticService.lightTap();
                ref.read(coachChatProvider.notifier).sendMessage(message);
              },
              onVoicePressed: () {
                HapticService.mediumTap();
                if (state.isListening) {
                  ref.read(coachChatProvider.notifier).stopVoiceInput();
                } else {
                  ref.read(coachChatProvider.notifier).startVoiceInput();
                }
              },
              suggestions: state.suggestions,
              isListening: state.isListening,
              isLoading: state.status == ChatStatus.streaming,
            ),
            
            // Safe area bottom
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(CoachChatState state) {
    if (state.messages.isEmpty && state.status == ChatStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AuraColors.auraAmber,
        ),
      );
    }

    if (state.messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      key: _listViewKey,
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: AuraDimensions.spaceM),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        final showAvatar = index == 0 || 
            state.messages[index - 1].role != MessageRole.coach;

        return Column(
          children: [
            CoachMessageBubble(
              message: message,
              showAvatar: showAvatar,
              onActionPressed: (action) {
                HapticService.lightTap();
                ref.read(coachChatProvider.notifier).executeAction(action);
              },
            ),
            // Rich content cards
            if (message.richContent != null && message.richContent!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AuraDimensions.spaceXL,
                  vertical: AuraDimensions.spaceXS,
                ),
                child: Column(
                  children: message.richContent!
                      .map((content) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AuraDimensions.spaceXS,
                            ),
                            child: CoachRichCardFactory.build(content),
                          ))
                      .toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AuraColors.gradientAmber,
              shape: BoxShape.circle,
              boxShadow: AuraDimensions.shadowMedium,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AuraColors.auraTextPrimary,
              size: 40,
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceL),
          Text(
            'Coach Aura',
            style: AuraTypography.h3.copyWith(
              color: AuraColors.auraTextDark,
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceS),
          Text(
            'Votre conseiller financier personnel',
            style: AuraTypography.bodyMedium.copyWith(
              color: AuraColors.auraTextDarkSecondary,
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceXL),
          Text(
            'Posez-moi des questions sur vos finances,\nje suis là pour vous aider !',
            textAlign: TextAlign.center,
            style: AuraTypography.bodyMedium.copyWith(
              color: AuraColors.auraTextDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AuraDimensions.spaceS,
        horizontal: AuraDimensions.spaceM,
      ),
      color: AuraColors.auraTextDarkSecondary.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off,
            size: 16,
            color: AuraColors.auraTextDarkSecondary,
          ),
          const SizedBox(width: AuraDimensions.spaceXS),
          Text(
            'Coach hors ligne - historique disponible',
            style: AuraTypography.labelSmall.copyWith(
              color: AuraColors.auraTextDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AuraDimensions.spaceS,
        horizontal: AuraDimensions.spaceM,
      ),
      color: AuraColors.auraRed.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 16,
            color: AuraColors.auraRed,
          ),
          const SizedBox(width: AuraDimensions.spaceXS),
          Expanded(
            child: Text(
              message,
              style: AuraTypography.labelSmall.copyWith(
                color: AuraColors.auraRed,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.close,
              size: 16,
              color: AuraColors.auraRed,
            ),
            onPressed: () {
              ref.read(coachChatProvider.notifier).clearError();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _showSettingsMenu(BuildContext context) {
    HapticService.mediumTap();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AuraColors.auraGlassStrong,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AuraDimensions.radiusXXL),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: AuraDimensions.spaceS),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AuraColors.auraTextDarkSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(height: AuraDimensions.spaceL),
              
              // Title
              Text(
                'Options',
                style: AuraTypography.h4.copyWith(
                  color: AuraColors.auraTextDark,
                ),
              ),
              
              const SizedBox(height: AuraDimensions.spaceM),
              
              // Options
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AuraColors.auraRed,
                ),
                title: Text(
                  'Vider la conversation',
                  style: AuraTypography.bodyMedium.copyWith(
                    color: AuraColors.auraRed,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showClearConfirmation(context);
                },
              ),
              
              ListTile(
                leading: const Icon(
                  Icons.language,
                  color: AuraColors.auraTextDark,
                ),
                title: Text(
                  'Langue du coach',
                  style: AuraTypography.bodyMedium.copyWith(
                    color: AuraColors.auraTextDark,
                  ),
                ),
                trailing: Text(
                  'Français',
                  style: AuraTypography.labelMedium.copyWith(
                    color: AuraColors.auraTextDarkSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement language selection
                },
              ),
              
              const SizedBox(height: AuraDimensions.spaceM),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AuraColors.auraGlassStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AuraDimensions.radiusXL),
        ),
        title: Text(
          'Vider la conversation ?',
          style: AuraTypography.h4.copyWith(
            color: AuraColors.auraTextDark,
          ),
        ),
        content: Text(
          'Cette action est irréversible. L\'historique sera supprimé.',
          style: AuraTypography.bodyMedium.copyWith(
            color: AuraColors.auraTextDarkSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: AuraTypography.labelLarge.copyWith(
                color: AuraColors.auraTextDarkSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              HapticService.success();
              ref.read(coachChatProvider.notifier).clearHistory();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AuraColors.auraRed,
              foregroundColor: AuraColors.auraTextPrimary,
            ),
            child: const Text('Vider'),
          ),
        ],
      ),
    );
  }
}
