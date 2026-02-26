import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'coach_message.freezed.dart';
part 'coach_message.g.dart';

/// Type de message dans le chat
enum MessageRole {
  user,
  coach,
  system,
}

/// Type de contenu enrichi dans un message
enum MessageContentType {
  text,
  chart,
  transaction,
  goal,
  alert,
  action,
}

/// Action suggérée par le coach
@freezed
class CoachAction with _$CoachAction {
  const factory CoachAction({
    required String type,
    required String label,
    Map<String, dynamic>? data,
  }) = _CoachAction;

  factory CoachAction.fromJson(Map<String, dynamic> json) =>
      _$CoachActionFromJson(json);
}

/// Contenu enrichi d'un message (carte contextuelle)
@freezed
class MessageContent with _$MessageContent {
  const factory MessageContent({
    required MessageContentType type,
    required Map<String, dynamic> data,
  }) = _MessageContent;

  factory MessageContent.fromJson(Map<String, dynamic> json) =>
      _$MessageContentFromJson(json);
}

/// Message individuel dans une conversation
@freezed
class CoachMessage with _$CoachMessage {
  const factory CoachMessage({
    required String id,
    required String conversationId,
    required MessageRole role,
    required String content,
    DateTime? createdAt,
    
    /// Contenu enrichi (cartes contextuelles)
    List<MessageContent>? richContent,
    
    /// Actions suggérées
    List<CoachAction>? actions,
    
    /// Métadonnées (tokens utilisés, temps de réponse, etc.)
    Map<String, dynamic>? metadata,
    
    /// Indique si le message est en cours de streaming
    @Default(false) bool isStreaming,
    
    /// Indique si le message est complet
    @Default(true) bool isComplete,
  }) = _CoachMessage;

  factory CoachMessage.fromJson(Map<String, dynamic> json) =>
      _$CoachMessageFromJson(json);
}

/// Conversation complète avec le coach
@freezed
class CoachConversation with _$CoachConversation {
  const factory CoachConversation({
    required String id,
    required String userId,
    
    /// Titre généré automatiquement ou défini par l'utilisateur
    String? title,
    
    /// Résumé de la conversation (pour compression de mémoire)
    String? summary,
    
    /// Messages de la conversation
    @Default([]) List<CoachMessage> messages,
    
    /// Date de création
    DateTime? createdAt,
    
    /// Date du dernier message
    DateTime? lastMessageAt,
    
    /// Nombre total de messages
    @Default(0) int messageCount,
    
    /// Langue de la conversation
    @Default('fr') String language,
    
    /// Métadonnées (modèle utilisé, etc.)
    Map<String, dynamic>? metadata,
  }) = _CoachConversation;

  factory CoachConversation.fromJson(Map<String, dynamic> json) =>
      _$CoachConversationFromJson(json);
}

/// Contexte financier pour le coach
@freezed
class FinancialContext with _$FinancialContext {
  const factory FinancialContext({
    /// Solde actuel total
    required double currentBalance,
    
    /// Revenus mensuels
    required double monthlyIncome,
    
    /// Dépenses du mois en cours
    required double monthlyExpenses,
    
    /// Budget mensuel
    double? monthlyBudget,
    
    /// Top catégories de dépenses
    @Default([]) List<CategorySpending> topCategories,
    
    /// Abonnements actifs
    @Default([]) List<SubscriptionInfo> subscriptions,
    
    /// Vampires détectés
    @Default([]) List<VampireAlert> vampires,
    
    /// Objectifs en cours
    @Default([]) List<GoalInfo> goals,
    
    /// Insights non lus
    @Default([]) List<String> unreadInsights,
  }) = _FinancialContext;

  factory FinancialContext.fromJson(Map<String, dynamic> json) =>
      _$FinancialContextFromJson(json);
}

/// Dépenses par catégorie
@freezed
class CategorySpending with _$CategorySpending {
  const factory CategorySpending({
    required String category,
    required double amount,
    required double percentage,
    String? icon,
    String? color,
  }) = _CategorySpending;

  factory CategorySpending.fromJson(Map<String, dynamic> json) =>
      _$CategorySpendingFromJson(json);
}

/// Info abonnement
@freezed
class SubscriptionInfo with _$SubscriptionInfo {
  const factory SubscriptionInfo({
    required String id,
    required String name,
    required double amount,
    required String billingCycle,
    DateTime? nextBillingDate,
    @Default(false) bool isVampire,
  }) = _SubscriptionInfo;

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionInfoFromJson(json);
}

/// Alerte vampire
@freezed
class VampireAlert with _$VampireAlert {
  const factory VampireAlert({
    required String subscriptionId,
    required String name,
    required double oldAmount,
    required double newAmount,
    required double increasePercentage,
  }) = _VampireAlert;

  factory VampireAlert.fromJson(Map<String, dynamic> json) =>
      _$VampireAlertFromJson(json);
}

/// Info objectif
@freezed
class GoalInfo with _$GoalInfo {
  const factory GoalInfo({
    required String id,
    required String name,
    required double targetAmount,
    required double currentAmount,
    double? progressPercentage,
    DateTime? deadline,
  }) = _GoalInfo;

  factory GoalInfo.fromJson(Map<String, dynamic> json) =>
      _$GoalInfoFromJson(json);
}

/// Suggestion rapide pour l'utilisateur
@freezed
class QuickSuggestion with _$QuickSuggestion {
  const factory QuickSuggestion({
    required String id,
    required String label,
    required String query,
    String? icon,
    
    /// Condition pour afficher cette suggestion
    String? condition,
  }) = _QuickSuggestion;

  factory QuickSuggestion.fromJson(Map<String, dynamic> json) =>
      _$QuickSuggestionFromJson(json);
}

/// État du chat
enum ChatStatus {
  idle,
  loading,
  streaming,
  error,
  offline,
}
