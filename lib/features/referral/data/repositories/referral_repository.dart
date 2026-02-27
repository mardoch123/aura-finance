import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/referral_models.dart';

class ReferralRepository {
  final SupabaseClient _supabase;

  ReferralRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  /// Récupérer les stats complètes de parrainage
  Future<ReferralStats> getReferralStats() async {
    final userId = _userId;
    if (userId == null) throw Exception('Non authentifié');

    // Récupérer le code de parrainage
    final codeResponse = await _supabase
        .from('referral_codes')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    final referralCode = codeResponse != null 
        ? ReferralCode.fromJson(codeResponse) 
        : null;

    // Récupérer les relations
    final relationshipsResponse = await _supabase
        .from('referral_relationships')
        .select()
        .eq('referrer_id', userId)
        .order('signed_up_at', ascending: false);

    final relationships = (relationshipsResponse as List)
        .map((e) => ReferralRelationship.fromJson(e))
        .toList();

    // Récupérer les jalons
    final milestonesResponse = await _supabase
        .from('referral_milestones')
        .select()
        .eq('user_id', userId)
        .order('referrals_required', ascending: true);

    final milestones = (milestonesResponse as List)
        .map((e) => ReferralMilestone.fromJson(e))
        .toList();

    // Récupérer les récompenses récentes
    final rewardsResponse = await _supabase
        .from('referral_rewards')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(10);

    final recentRewards = (rewardsResponse as List)
        .map((e) => ReferralReward.fromJson(e))
        .toList();

    // Calculer les stats
    final activeReferrals = relationships.where((r) => r.status == 'active').length;
    final pendingReferrals = relationships.where((r) => r.status == 'pending').length;
    final totalClicks = referralCode?.totalClicks ?? 0;
    final conversionRate = relationships.isEmpty 
        ? 0.0 
        : (activeReferrals / relationships.length) * 100;

    // Prochain jalon
    final nextMilestone = milestones.firstWhere(
      (m) => m.achievedAt == null,
      orElse: () => milestones.last,
    );

    return ReferralStats(
      userId: userId,
      totalReferrals: relationships.length,
      activeReferrals: activeReferrals,
      pendingReferrals: pendingReferrals,
      totalClicks: totalClicks,
      conversionRate: conversionRate,
      currentStreak: activeReferrals,
      nextMilestoneAt: nextMilestone.referralsRequired,
      nextMilestoneType: nextMilestone.milestoneType,
      nextMilestoneReward: nextMilestone.rewardDescription,
      milestones: milestones,
      recentRewards: recentRewards,
      referralCode: referralCode,
    );
  }

  /// Récupérer son code de parrainage
  Future<ReferralCode?> getMyReferralCode() async {
    final userId = _userId;
    if (userId == null) return null;

    final response = await _supabase
        .from('referral_codes')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    return response != null ? ReferralCode.fromJson(response) : null;
  }

  /// Personnaliser son code
  Future<ReferralCode> customizeCode({String? customSlug}) async {
    final userId = _userId;
    if (userId == null) throw Exception('Non authentifié');

    final response = await _supabase
        .from('referral_codes')
        .update({
          'custom_slug': customSlug,
          'is_custom': customSlug != null,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .select()
        .single();

    return ReferralCode.fromJson(response);
  }

  /// Récupérer l'historique des parrainages
  Future<List<ReferralRelationship>> getReferralHistory() async {
    final userId = _userId;
    if (userId == null) return [];

    final response = await _supabase
        .from('referral_relationships')
        .select('*, referred:referred_id(full_name, avatar_url)')
        .eq('referrer_id', userId)
        .order('signed_up_at', ascending: false);

    return (response as List)
        .map((e) => ReferralRelationship.fromJson(e))
        .toList();
  }

  /// Réclamer une récompense de jalon
  Future<void> claimMilestoneReward(String milestoneId) async {
    final userId = _userId;
    if (userId == null) throw Exception('Non authentifié');

    await _supabase
        .from('referral_milestones')
        .update({
          'claimed': true,
          'claimed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', milestoneId)
        .eq('user_id', userId);
  }

  /// Partager le code (incrémente le compteur de clics)
  Future<void> trackShare() async {
    final userId = _userId;
    if (userId == null) return;

    await _supabase.rpc('increment_referral_clicks', params: {
      'p_user_id': userId,
    });
  }

  /// Utiliser un code de parrainage (pour un nouvel utilisateur)
  Future<void> applyReferralCode(String code) async {
    final userId = _userId;
    if (userId == null) throw Exception('Non authentifié');

    // Vérifier que l'utilisateur n'a pas déjà été parrainé
    final existing = await _supabase
        .from('referral_relationships')
        .select()
        .eq('referred_id', userId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('Vous avez déjà utilisé un code de parrainage');
    }

    // Trouver le code
    final codeData = await _supabase
        .from('referral_codes')
        .select()
        .eq('code', code)
        .eq('is_active', true)
        .maybeSingle();

    if (codeData == null) {
      throw Exception('Code de parrainage invalide');
    }

    // Créer la relation
    await _supabase.from('referral_relationships').insert({
      'referrer_id': codeData['user_id'],
      'referred_id': userId,
      'referral_code_id': codeData['id'],
      'code_used': code,
      'clicked_at': DateTime.now().toIso8601String(),
      'status': 'pending',
    });

    // Incrémenter les signups
    await _supabase
        .from('referral_codes')
        .update({
          'total_signups': codeData['total_signups'] + 1,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', codeData['id']);
  }

  /// Récupérer les récompenses disponibles
  Future<List<ReferralReward>> getAvailableRewards() async {
    final userId = _userId;
    if (userId == null) return [];

    final response = await _supabase
        .from('referral_rewards')
        .select()
        .eq('user_id', userId)
        .eq('status', 'granted')
        .gt('expires_at', DateTime.now().toIso8601String())
        .order('granted_at', ascending: false);

    return (response as List)
        .map((e) => ReferralReward.fromJson(e))
        .toList();
  }
}