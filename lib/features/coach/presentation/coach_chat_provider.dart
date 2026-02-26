import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../services/supabase_service.dart';
import '../domain/coach_message.dart';

part 'coach_chat_provider.freezed.dart';
part 'coach_chat_provider.g.dart';

/// État du chat
@freezed
class CoachChatState with _$CoachChatState {
  const factory CoachChatState({
    /// Conversation active
    CoachConversation? conversation,
    
    /// Messages de la conversation
    @Default([]) List<CoachMessage> messages,
    
    /// Statut du chat
    @Default(ChatStatus.idle) ChatStatus status,
    
    /// Suggestions rapides
    @Default([]) List<QuickSuggestion> suggestions,
    
    /// Message d'erreur
    String? errorMessage,
    
    /// Indique si le micro est actif
    @Default(false) bool isListening,
    
    /// Transcription vocale en cours
    String? voiceTranscript,
    
    /// Action en attente d'exécution
    CoachAction? pendingAction,
  }) = _CoachChatState;
}

/// Provider pour le service de chat du coach
@Riverpod(keepAlive: false)
class CoachChat extends _$CoachChat {
  http.Client? _client;
  StreamSubscription? _streamSubscription;
  SpeechToText? _speechToText;
  
  @override
  CoachChatState build() {
    ref.onDispose(() {
      _streamSubscription?.cancel();
      _client?.close();
      _speechToText?.cancel();
    });
    return const CoachChatState();
  }

  /// Initialise le chat et charge l'historique
  Future<void> initialize() async {
    state = state.copyWith(status: ChatStatus.loading);
    
    try {
      // Charger la conversation active ou en créer une nouvelle
      await _loadOrCreateConversation();
      
      // Charger les suggestions contextuelles
      await _loadSuggestions();
      
      state = state.copyWith(status: ChatStatus.idle);
    } catch (e) {
      state = state.copyWith(
        status: ChatStatus.error,
        errorMessage: 'Erreur lors de l\'initialisation: $e',
      );
    }
  }

  /// Envoie un message et reçoit la réponse en streaming
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    
    final messageId = const Uuid().v4();
    final userMessage = CoachMessage(
      id: messageId,
      conversationId: state.conversation?.id ?? '',
      role: MessageRole.user,
      content: content,
      createdAt: DateTime.now(),
    );

    // Ajouter le message utilisateur
    _addMessage(userMessage);
    
    state = state.copyWith(status: ChatStatus.streaming);
    
    try {
      await _sendMessageWithStreaming(content);
    } catch (e) {
      state = state.copyWith(
        status: ChatStatus.error,
        errorMessage: 'Erreur de communication: $e',
      );
    }
  }

  /// Envoie un message avec réponse en streaming
  Future<void> _sendMessageWithStreaming(String content) async {
    _client ??= http.Client();
    
    final token = SupabaseService.instance.auth.currentSession?.accessToken;
    final userId = SupabaseService.instance.auth.currentUser?.id;
    
    if (token == null || userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    // Préparer l'historique (10 derniers messages)
    final history = state.messages
        .take(10)
        .map((m) => {
              'role': m.role.name,
              'content': m.content,
            })
        .toList();

    final request = http.Request(
      'POST',
      Uri.parse('${ApiEndpoints.supabaseUrl}${ApiEndpoints.functionsBase}/coach-chat'),
    );
    
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Accept': 'text/event-stream',
    });
    
    request.body = jsonEncode({
      'userId': userId,
      'message': content,
      'conversationId': state.conversation?.id,
      'conversationHistory': history,
    });

    final response = await _client!.send(request);
    
    if (response.statusCode != 200) {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }

    // Créer le message du coach en cours de streaming
    final coachMessageId = const Uuid().v4();
    var coachMessage = CoachMessage(
      id: coachMessageId,
      conversationId: state.conversation?.id ?? '',
      role: MessageRole.coach,
      content: '',
      createdAt: DateTime.now(),
      isStreaming: true,
      isComplete: false,
    );
    
    _addMessage(coachMessage);

    // Lire le stream
    final stream = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    String fullContent = '';
    List<CoachAction>? actions;
    List<MessageContent>? richContent;

    await for (final line in stream) {
      if (line.startsWith('data: ')) {
        final data = line.substring(6);
        
        if (data == '[DONE]') {
          break;
        }

        try {
          final jsonData = jsonDecode(data);
          
          if (jsonData['type'] == 'token') {
            // Token de texte
            final token = jsonData['content'] as String;
            fullContent += token;
            
            // Mettre à jour le message en temps réel
            coachMessage = coachMessage.copyWith(content: fullContent);
            _updateMessage(coachMessage);
          } else if (jsonData['type'] == 'actions') {
            // Actions suggérées reçues
            actions = (jsonData['actions'] as List)
                .map((a) => CoachAction.fromJson(a))
                .toList();
          } else if (jsonData['type'] == 'rich_content') {
            // Contenu enrichi
            richContent = (jsonData['content'] as List)
                .map((c) => MessageContent.fromJson(c))
                .toList();
          } else if (jsonData['type'] == 'metadata') {
            // Métadonnées (fallback, etc.)
            if (jsonData['usingFallback'] == true) {
              // Ajouter une note discrète sur le fallback
              fullContent += '\n\n*(Mode fallback activé)*';
            }
          }
        } catch (e) {
          // Ignorer les lignes malformées
          if (kDebugMode) {
            print('Erreur parsing SSE: $e');
          }
        }
      }
    }

    // Finaliser le message
    coachMessage = coachMessage.copyWith(
      content: fullContent,
      isStreaming: false,
      isComplete: true,
      actions: actions,
      richContent: richContent,
    );
    
    _updateMessage(coachMessage);
    
    state = state.copyWith(status: ChatStatus.idle);
    
    // Sauvegarder la conversation
    await _saveConversation();
    
    // Mettre à jour les suggestions
    await _loadSuggestions();
  }

  /// Charge ou crée une conversation
  Future<void> _loadOrCreateConversation() async {
    final userId = SupabaseService.instance.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Chercher une conversation récente (moins de 24h)
      final yesterday = DateTime.now().subtract(const Duration(hours: 24));
      
      final response = await SupabaseService.instance.client
          .from('coach_conversations')
          .select()
          .eq('user_id', userId)
          .gt('last_message_at', yesterday.toIso8601String())
          .order('last_message_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        // Charger la conversation existante
        final conversation = CoachConversation.fromJson(response);
        
        // Charger les messages
        final messagesResponse = await SupabaseService.instance.client
            .from('coach_messages')
            .select()
            .eq('conversation_id', conversation.id)
            .order('created_at', ascending: true);

        final messages = (messagesResponse as List)
            .map((m) => CoachMessage.fromJson(m))
            .toList();

        state = state.copyWith(
          conversation: conversation.copyWith(messages: messages),
          messages: messages,
        );
      } else {
        // Créer une nouvelle conversation
        await _createNewConversation(userId);
      }
    } catch (e) {
      // En cas d'erreur, créer une conversation locale
      await _createNewConversation(userId);
    }
  }

  /// Crée une nouvelle conversation
  Future<void> _createNewConversation(String userId) async {
    final conversationId = const Uuid().v4();
    final conversation = CoachConversation(
      id: conversationId,
      userId: userId,
      title: 'Nouvelle conversation',
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
    );

    state = state.copyWith(conversation: conversation, messages: []);

    try {
      await SupabaseService.instance.client
          .from('coach_conversations')
          .insert(conversation.toJson());
    } catch (e) {
      // Ignorer l'erreur, on garde la conversation en mémoire
    }
  }

  /// Sauvegarde la conversation
  Future<void> _saveConversation() async {
    if (state.conversation == null) return;

    try {
      final conversation = state.conversation!.copyWith(
        lastMessageAt: DateTime.now(),
        messageCount: state.messages.length,
      );

      await SupabaseService.instance.client
          .from('coach_conversations')
          .upsert(conversation.toJson());

      // Sauvegarder les messages récents
      for (final message in state.messages.take(5)) {
        await SupabaseService.instance.client
            .from('coach_messages')
            .upsert(message.toJson());
      }
    } catch (e) {
      // Ignorer les erreurs de sauvegarde
    }
  }

  /// Charge les suggestions contextuelles
  Future<void> _loadSuggestions() async {
    final suggestions = <QuickSuggestion>[
      const QuickSuggestion(
        id: '1',
        label: 'Mon bilan du mois',
        query: 'Quel est mon bilan financier ce mois-ci ?',
        icon: 'chart',
      ),
      const QuickSuggestion(
        id: '2',
        label: 'Où je dépense trop ?',
        query: 'Analyse mes dépenses et dis-moi où je pourrais économiser',
        icon: 'search',
      ),
      const QuickSuggestion(
        id: '3',
        label: 'Conseil épargne',
        query: 'Donne-moi un conseil pour mieux épargner',
        icon: 'piggy',
      ),
    ];

    // Ajouter des suggestions contextuelles basées sur l'état
    if (state.messages.isNotEmpty) {
      final lastMessage = state.messages.last;
      if (lastMessage.role == MessageRole.coach) {
        // Suggestion de suivi
        suggestions.insert(0, const QuickSuggestion(
          id: 'follow_up',
          label: 'Dis-moi plus',
          query: 'Peux-tu m\'en dire plus sur ça ?',
          icon: 'chat',
        ));
      }
    }

    state = state.copyWith(suggestions: suggestions);
  }

  /// Ajoute un message à la liste
  void _addMessage(CoachMessage message) {
    state = state.copyWith(
      messages: [...state.messages, message],
    );
  }

  /// Met à jour un message existant
  void _updateMessage(CoachMessage updatedMessage) {
    state = state.copyWith(
      messages: state.messages.map((m) {
        if (m.id == updatedMessage.id) {
          return updatedMessage;
        }
        return m;
      }).toList(),
    );
  }

  /// Efface l'historique de la conversation
  Future<void> clearHistory() async {
    if (state.conversation == null) return;

    try {
      await SupabaseService.instance.client
          .from('coach_messages')
          .delete()
          .eq('conversation_id', state.conversation!.id);

      state = state.copyWith(messages: []);
      
      // Créer une nouvelle conversation
      final userId = SupabaseService.instance.auth.currentUser?.id;
      if (userId != null) {
        await _createNewConversation(userId);
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Erreur lors de la suppression: $e',
      );
    }
  }

  /// Démarre la reconnaissance vocale
  Future<void> startVoiceInput() async {
    _speechToText ??= SpeechToText();
    
    final available = await _speechToText!.initialize();
    if (!available) {
      state = state.copyWith(
        errorMessage: 'La reconnaissance vocale n\'est pas disponible',
      );
      return;
    }

    state = state.copyWith(isListening: true);

    await _speechToText!.listen(
      onResult: (result) {
        state = state.copyWith(
          voiceTranscript: result.recognizedWords,
        );
        
        if (result.finalResult) {
          state = state.copyWith(isListening: false);
          if (result.recognizedWords.isNotEmpty) {
            sendMessage(result.recognizedWords);
          }
        }
      },
      localeId: state.conversation?.language == 'en' ? 'en_US' : 'fr_FR',
    );
  }

  /// Arrête la reconnaissance vocale
  Future<void> stopVoiceInput() async {
    await _speechToText?.stop();
    state = state.copyWith(isListening: false);
  }

  /// Exécute une action suggérée
  void executeAction(CoachAction action) {
    // Gérer les différents types d'actions
    switch (action.type) {
      case 'create_goal':
        // Ouvrir le modal de création d'objectif
        state = state.copyWith(
          pendingAction: action,
        );
        break;
      case 'show_chart':
        // Afficher un graphique
        state = state.copyWith(
          pendingAction: action,
        );
        break;
      case 'mark_subscription':
        // Marquer un abonnement
        _markSubscription(action.data?['subscriptionId'] as String?);
        break;
      default:
        // Action non reconnue
        break;
    }
  }

  /// Marque un abonnement
  Future<void> _markSubscription(String? subscriptionId) async {
    if (subscriptionId == null) return;
    
    try {
      await SupabaseService.instance.client
          .from('subscriptions')
          .update({'is_vampire': false})
          .eq('id', subscriptionId);
    } catch (e) {
      // Ignorer l'erreur
    }
  }

  /// Efface l'action en attente
  void clearPendingAction() {
    state = state.copyWith(pendingAction: null);
  }

  /// Efface le message d'erreur
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
