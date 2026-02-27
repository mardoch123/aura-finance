import 'package:freezed_annotation/freezed_annotation.dart';

part 'referral_models.freezed.dart';
part 'referral_models.g.dart';

/// Code de parrainage personnel
@freezed
class ReferralCode with _$ReferralCode {
  const factory ReferralCode({
    required String id,
    required String code,
    required String userId,
    String? customSlug,
    @Default(false) bool isCustom,
    @Default(0) int totalClicks,
    @Default(0) int totalSignups,
    @Default(0) int totalConversions,
    @Default('app') String utmSource,
    @Default('referral') String utmMedium,
    String? utmCampaign,
    @Default(true) bool isActive,
    DateTime? deactivatedAt,
    String? deactivationReason,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ReferralCode;

  factory ReferralCode.fromJson(Map<String, dynamic> json) =>
      _$ReferralCodeFromJson(json);
}

/// Relation entre parrain et filleul
@freezed
class ReferralRelationship with _$ReferralRelationship {
  const factory ReferralRelationship({
    required String id,
    required String referrerId,
    required String referredId,
    String? referralCodeId,
    required String codeUsed,
    DateTime? clickedAt,
    required DateTime signedUpAt,
    DateTime? convertedAt,
    String? referrerIp,
    String? userAgent,
    @Default('pending') String status,
    @Default(false) bool referrerRewarded,
    @Default(false) bool referredRewarded,
    Map<String, dynamic>? referrerRewardDetails,
    Map<String, dynamic>? referredRewardDetails,
  }) = _ReferralRelationship;

  factory ReferralRelationship.fromJson(Map<String, dynamic> json) =>
      _$ReferralRelationshipFromJson(json);
}

/// Récompense de parrainage
@freezed
class ReferralReward with _$ReferralReward {
  const factory ReferralReward({
    required String id,
    required String userId,
    String? relationshipId,
    required String rewardType,
    @Default(1) int quantity,
    required String description,
    @Default('pending') String status,
    DateTime? grantedAt,
    DateTime? expiresAt,
    DateTime? revokedAt,
    String? revocationReason,
    Map<String, dynamic>? metadata,
    required DateTime createdAt,
  }) = _ReferralReward;

  factory ReferralReward.fromJson(Map<String, dynamic> json) =>
      _$ReferralRewardFromJson(json);
}

/// Jalon de parrainage
@freezed
class ReferralMilestone with _$ReferralMilestone {
  const factory ReferralMilestone({
    required String id,
    required String userId,
    required String milestoneType,
    required int referralsRequired,
    required String rewardType,
    @Default(1) int rewardQuantity,
    required String rewardDescription,
    DateTime? achievedAt,
    @Default(false) bool claimed,
    DateTime? claimedAt,
  }) = _ReferralMilestone;

  factory ReferralMilestone.fromJson(Map<String, dynamic> json) =>
      _$ReferralMilestoneFromJson(json);
}

/// Statistiques complètes de parrainage
@freezed
class ReferralStats with _$ReferralStats {
  const factory ReferralStats({
    required String userId,
    required int totalReferrals,
    required int activeReferrals,
    required int pendingReferrals,
    required int totalClicks,
    required double conversionRate,
    required int currentStreak,
    required int nextMilestoneAt,
    String? nextMilestoneType,
    String? nextMilestoneReward,
    required List<ReferralMilestone> milestones,
    required List<ReferralReward> recentRewards,
    required ReferralCode? referralCode,
  }) = _ReferralStats;

  factory ReferralStats.fromJson(Map<String, dynamic> json) =>
      _$ReferralStatsFromJson(json);
}

/// Types de récompenses
class RewardType {
  static const String proMonth = 'pro_month';
  static const String proYear = 'pro_year';
  static const String proLifetime = 'pro_lifetime';
  static const String scanCredits = 'scan_credits';
  static const String coachCredits = 'coach_credits';
  static const String custom = 'custom';
}

/// Types de jalons
class MilestoneType {
  static const String firstReferral = 'first_referral';
  static const String fiveReferrals = 'five_referrals';
  static const String tenReferrals = 'ten_referrals';
  static const String twentyReferrals = 'twenty_referrals';
  static const String fiftyReferrals = 'fifty_referrals';
  static const String hundredReferrals = 'hundred_referrals';
}

/// Extension pour obtenir le label d'un jalon
extension MilestoneTypeExtension on String {
  String get milestoneLabel {
    return switch (this) {
      MilestoneType.firstReferral => '1er Parrainage',
      MilestoneType.fiveReferrals => '5 Parrainages',
      MilestoneType.tenReferrals => '10 Parrainages',
      MilestoneType.twentyReferrals => '20 Parrainages',
      MilestoneType.fiftyReferrals => '50 Parrainages',
      MilestoneType.hundredReferrals => '100 Parrainages',
      _ => this,
    };
  }

  int get milestoneCount {
    return switch (this) {
      MilestoneType.firstReferral => 1,
      MilestoneType.fiveReferrals => 5,
      MilestoneType.tenReferrals => 10,
      MilestoneType.twentyReferrals => 20,
      MilestoneType.fiftyReferrals => 50,
      MilestoneType.hundredReferrals => 100,
      _ => 0,
    };
  }
}