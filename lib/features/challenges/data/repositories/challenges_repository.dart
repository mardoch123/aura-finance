import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../models/challenge_models.dart';

class ChallengesRepository {
  final SupabaseClient _supabase;
  final Logger _logger = Logger();

  ChallengesRepository(this._supabase);

  // ═══════════════════════════════════════════════════════════
  // CHALLENGES
  // ═══════════════════════════════════════════════════════════

  Future<List<Challenge>> getAvailableChallenges() async {
    try {
      final response = await _supabase
          .from('challenges')
          .select()
          .eq('is_active', true)
          .order('is_featured', ascending: false)
          .order('difficulty');

      return (response as List)
          .map((json) => Challenge.fromJson(json))
          .toList();
    } catch (e, stackTrace) {
      _logger.e('Error fetching challenges', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<UserChallenge>> getUserActiveChallenges() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('user_challenges')
          .select(''', challenge:challenge_id(*)''')
          .eq('user_id', userId)
          .eq('status', 'active')
          .order('started_at', ascending: false);

      return (response as List).map((json) {
        final challenge = json['challenge'] != null
            ? Challenge.fromJson(json['challenge'])
            : null;
        return UserChallenge.fromJson({
          ...json,
          'challenge': challenge,
        });
      }).toList();
    } catch (e, stackTrace) {
      _logger.e('Error fetching user challenges', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<UserChallenge> joinChallenge(String challengeId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Récupérer le challenge pour la config
      final challenge = await _supabase
          .from('challenges')
          .select()
          .eq('id', challengeId)
          .single();

      final config = challenge['config'] as Map<String, dynamic>;
      final durationDays = config['duration_days'] as int? ?? 7;

      final response = await _supabase
          .from('user_challenges')
          .insert({
            'user_id': userId,
            'challenge_id': challengeId,
            'progress_target': config['target_amount'] ?? 100,
            'expires_at': DateTime.now().add(Duration(days: durationDays)).toIso8601String(),
          })
          .select()
          .single();

      return UserChallenge.fromJson(response);
    } catch (e, stackTrace) {
      _logger.e('Error joining challenge', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> updateChallengeProgress(String userChallengeId, double progress) async {
    try {
      await _supabase
          .from('user_challenges')
          .update({'progress_current': progress})
          .eq('id', userChallengeId);
    } catch (e, stackTrace) {
      _logger.e('Error updating challenge progress', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // BADGES
  // ═══════════════════════════════════════════════════════════

  Future<List<Badge>> getAllBadges() async {
    try {
      final response = await _supabase
          .from('badges')
          .select()
          .order('display_order');

      return (response as List)
          .map((json) => Badge.fromJson(json))
          .toList();
    } catch (e, stackTrace) {
      _logger.e('Error fetching badges', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<UserBadge>> getUserBadges() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('user_badges')
          .select(''', badge:badge_id(*)''')
          .eq('user_id', userId)
          .order('unlocked_at', ascending: false);

      return (response as List).map((json) {
        final badge = json['badge'] != null
            ? Badge.fromJson(json['badge'])
            : null;
        return UserBadge.fromJson({
          ...json,
          'badge': badge,
        });
      }).toList();
    } catch (e, stackTrace) {
      _logger.e('Error fetching user badges', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> showcaseBadge(String userBadgeId, int order) async {
    try {
      await _supabase
          .from('user_badges')
          .update({
            'is_showcased': true,
            'showcase_order': order,
          })
          .eq('id', userBadgeId);
    } catch (e, stackTrace) {
      _logger.e('Error showcasing badge', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // STREAKS
  // ═══════════════════════════════════════════════════════════

  Future<List<UserStreak>> getUserStreaks() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('user_streaks')
          .select()
          .eq('user_id', userId)
          .order('current_streak', ascending: false);

      return (response as List)
          .map((json) => UserStreak.fromJson(json))
          .toList();
    } catch (e, stackTrace) {
      _logger.e('Error fetching streaks', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> recordStreakActivity(StreakType type) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Upsert avec mise à jour de la streak
      await _supabase.rpc('update_streak', params: {
        'p_user_id': userId,
        'p_type': type.name,
      });
    } catch (e, stackTrace) {
      _logger.e('Error recording streak activity', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // XP & LEVELING
  // ═══════════════════════════════════════════════════════════

  Future<UserXP> getUserXP() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('user_xp')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Créer l'entrée si elle n'existe pas
        final newXP = await _supabase
            .from('user_xp')
            .insert({'user_id': userId})
            .select()
            .single();
        return UserXP.fromJson(newXP);
      }

      return UserXP.fromJson(response);
    } catch (e, stackTrace) {
      _logger.e('Error fetching user XP', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> addXP(int amount, String reason, String sourceType) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('xp_transactions').insert({
        'user_id': userId,
        'amount': amount,
        'reason': reason,
        'source_type': sourceType,
      });
    } catch (e, stackTrace) {
      _logger.e('Error adding XP', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // LEADERBOARDS
  // ═══════════════════════════════════════════════════════════

  Future<List<LeaderboardEntry>> getLeaderboard(String leaderboardId) async {
    try {
      final response = await _supabase
          .from('leaderboard_entries')
          .select(''', user:user_id(full_name, avatar_url)''')
          .eq('leaderboard_id', leaderboardId)
          .order('rank');

      return (response as List).map((json) {
        final user = json['user'] as Map<String, dynamic>?;
        return LeaderboardEntry.fromJson({
          ...json,
          'user_name': user?['full_name'],
          'user_avatar': user?['avatar_url'],
        });
      }).toList();
    } catch (e, stackTrace) {
      _logger.e('Error fetching leaderboard', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<LeaderboardEntry>> getFriendsLeaderboard() async {
    try {
      final response = await _supabase
          .from('friends_leaderboard')
          .select()
          .limit(100);

      return (response as List)
          .map((json) => LeaderboardEntry.fromJson(json))
          .toList();
    } catch (e, stackTrace) {
      _logger.e('Error fetching friends leaderboard', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SOCIAL SHARES
  // ═══════════════════════════════════════════════════════════

  Future<void> recordSocialShare({
    required String contentType,
    required SocialSharePlatform platform,
    String? contentId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('social_shares').insert({
        'user_id': userId,
        'content_type': contentType,
        'content_id': contentId,
        'platform': platform.name,
      });
    } catch (e, stackTrace) {
      _logger.e('Error recording social share', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // GAMIFICATION SUMMARY
  // ═══════════════════════════════════════════════════════════

  Future<GamificationSummary> getGamificationSummary() async {
    try {
      final userXP = await getUserXP();
      final streaks = await getUserStreaks();
      final activeChallenges = await getUserActiveChallenges();
      final badges = await getUserBadges();
      final leaderboard = await getFriendsLeaderboard();

      // Trouver la position de l'utilisateur
      final currentUserId = _supabase.auth.currentUser?.id;
      final userPosition = leaderboard
          .where((e) => e.userId == currentUserId)
          .toList();

      return GamificationSummary(
        userXP: userXP,
        streaks: streaks,
        activeChallenges: activeChallenges,
        recentBadges: badges.where((b) => b.isNew).toList(),
        leaderboardPosition: userPosition,
      );
    } catch (e, stackTrace) {
      _logger.e('Error fetching gamification summary', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
