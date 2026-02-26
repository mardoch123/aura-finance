import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';
import '../domain/insight_model.dart';

/// Repository pour la gestion des insights IA
class InsightsRepository {
  final SupabaseClient _client;

  InsightsRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.instance.client;

  /// Récupère tous les insights de l'utilisateur
  Future<List<Insight>> getInsights({
    int limit = 50,
    int offset = 0,
    InsightFilter filter = InsightFilter.all,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    var builder = _client
        .from('ai_insights')
        .select()
        .eq('user_id', userId);

    // Appliquer le filtre
    switch (filter) {
      case InsightFilter.unread:
        builder = builder.eq('is_read', false);
        break;
      case InsightFilter.alerts:
        builder = builder.eq('type', 'alert');
        break;
      case InsightFilter.predictions:
        builder = builder.eq('type', 'prediction');
        break;
      case InsightFilter.vampires:
        builder = builder.eq('type', 'vampire');
        break;
      case InsightFilter.tips:
        builder = builder.eq('type', 'tip');
        break;
      case InsightFilter.all:
        break;
    }

    final response = await builder
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List).map((json) => Insight.fromJson(json)).toList();
  }

  /// Récupère le nombre d'insights non lus
  Future<int> getUnreadCount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    final response = await _client.rpc(
      'get_unread_insights_count',
      params: {'user_uuid': userId},
    );

    return response as int? ?? 0;
  }

  /// Récupère les insights prioritaires
  Future<List<Insight>> getPriorityInsights({int minPriority = 3}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    final response = await _client.rpc(
      'get_priority_insights',
      params: {
        'user_uuid': userId,
        'min_priority': minPriority,
      },
    );

    if (response == null) return [];
    return (response as List).map((json) => Insight.fromJson(json)).toList();
  }

  /// Marque un insight comme lu
  Future<void> markAsRead(String insightId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    await _client
        .from('ai_insights')
        .update({
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
        })
        .eq('id', insightId)
        .eq('user_id', userId);
  }

  /// Marque tous les insights comme lus
  Future<void> markAllAsRead() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    await _client.rpc(
      'mark_all_insights_as_read',
      params: {'user_uuid': userId},
    );
  }

  /// Supprime un insight
  Future<void> deleteInsight(String insightId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    await _client
        .from('ai_insights')
        .delete()
        .eq('id', insightId)
        .eq('user_id', userId);
  }

  /// Enregistre une action sur un insight
  Future<void> recordAction(String insightId, String actionType) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    await _client
        .from('ai_insights')
        .update({
          'action_taken': true,
          'action_type': actionType,
        })
        .eq('id', insightId)
        .eq('user_id', userId);
  }
}
