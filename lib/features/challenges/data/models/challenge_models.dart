import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'challenge_models.freezed.dart';
part 'challenge_models.g.dart';

// ═══════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════

enum ChallengeType {
  spendingLimit,
  savingGoal,
  streak,
  categoryReduction,
  transactionCount,
  custom,
}

enum ChallengeStatus {
  active,
  completed,
  failed,
  abandoned,
}

enum ChallengeFrequency {
  daily,
  weekly,
  monthly,
  oneTime,
}

enum BadgeCategory {
  saving,
  spending,
  streak,
  social,
  exploration,
  special,
}

enum BadgeTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
}

enum BadgeUnlockType {
  challengeCompletion,
  streakDays,
  amountSaved,
  transactionCount,
  featureUsage,
  socialShare,
  specialEvent,
}

enum StreakType {
  dailyCheckIn,
  underBudget,
  transactionLogged,
  noImpulseBuy,
  savingMade,
}

enum LeaderboardType {
  weeklySaving,
  monthlySaving,
  streak,
  challengeCompletion,
  xpEarned,
}

enum SocialSharePlatform {
  instagram,
  facebook,
  twitter,
  whatsapp,
  other,
}

// ═══════════════════════════════════════════════════════════
// CHALLENGE MODELS
// ═══════════════════════════════════════════════════════════

@freezed
class Challenge with _$Challenge {
  const factory Challenge({
    required String id,
    required String code,
    required String title,
    required String description,
    @Default(ChallengeType.custom) ChallengeType type,
    @Default({}) Map<String, dynamic> config,
    @Default(100) int xpReward,
    String? badgeId,
    @Default(1) int difficulty,
    @Default(ChallengeFrequency.monthly) ChallengeFrequency frequency,
    @Default(true) bool isActive,
    @Default(false) bool isFeatured,
    DateTime? startDate,
    DateTime? endDate,
    @Default('emoji_events') String icon,
    @Default('#E8A86C') String color,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _Challenge;

  const Challenge._();

  factory Challenge.fromJson(Map<String, dynamic> json) =>
      _$ChallengeFromJson(json);

  String get difficultyLabel {
    return switch (difficulty) {
      1 => 'Facile',
      2 => 'Moyen',
      3 => 'Difficile',
      4 => 'Expert',
      5 => 'Légendaire',
      _ => 'Inconnu',
    };
  }

  String get frequencyLabel {
    return switch (frequency) {
      ChallengeFrequency.daily => 'Quotidien',
      ChallengeFrequency.weekly => 'Hebdomadaire',
      ChallengeFrequency.monthly => 'Mensuel',
      ChallengeFrequency.oneTime => 'Unique',
    };
  }
}

@freezed
class UserChallenge with _$UserChallenge {
  const factory UserChallenge({
    required String id,
    required String userId,
    required String challengeId,
    @Default(ChallengeStatus.active) ChallengeStatus status,
    @Default(0.0) double progressCurrent,
    required double progressTarget,
    @Default(0) int progressPercentage,
    @Default({}) Map<String, dynamic> progressData,
    required DateTime startedAt,
    DateTime? completedAt,
    required DateTime expiresAt,
    @Default(0) int xpEarned,
    @Default(false) bool badgeEarned,
    // Relations
    Challenge? challenge,
  }) = _UserChallenge;

  factory UserChallenge.fromJson(Map<String, dynamic> json) =>
      _$UserChallengeFromJson(json);

  bool get isCompleted => status == ChallengeStatus.completed;
  bool get isActive => status == ChallengeStatus.active;
  bool get isExpired => expiresAt.isBefore(DateTime.now());
  
  int get daysRemaining {
    final diff = expiresAt.difference(DateTime.now());
    return diff.inDays.clamp(0, 999);
  }
}

// ═══════════════════════════════════════════════════════════
// BADGE MODELS
// ═══════════════════════════════════════════════════════════

@freezed
class Badge with _$Badge {
  const factory Badge({
    required String id,
    required String code,
    required String name,
    required String description,
    @Default(BadgeCategory.special) BadgeCategory category,
    @Default(BadgeTier.bronze) BadgeTier tier,
    @Default(BadgeUnlockType.specialEvent) BadgeUnlockType unlockType,
    required Map<String, dynamic> unlockRequirement,
    @Default('emoji_events') String icon,
    @Default('#E8A86C') String iconColor,
    @Default(['#E8A86C', '#C4714A']) List<String> backgroundGradient,
    @Default('none') String animationType,
    @Default(0) int displayOrder,
    @Default(false) bool isSecret,
    required DateTime createdAt,
  }) = _Badge;

  factory Badge.fromJson(Map<String, dynamic> json) =>
      _$BadgeFromJson(json);

  String get tierLabel {
    return switch (tier) {
      BadgeTier.bronze => 'Bronze',
      BadgeTier.silver => 'Argent',
      BadgeTier.gold => 'Or',
      BadgeTier.platinum => 'Platine',
      BadgeTier.diamond => 'Diamant',
    };
  }

  String get categoryLabel {
    return switch (category) {
      BadgeCategory.saving => 'Épargne',
      BadgeCategory.spending => 'Dépenses',
      BadgeCategory.streak => 'Séries',
      BadgeCategory.social => 'Social',
      BadgeCategory.exploration => 'Exploration',
      BadgeCategory.special => 'Spécial',
    };
  }
}

@freezed
class UserBadge with _$UserBadge {
  const factory UserBadge({
    required String id,
    required String userId,
    required String badgeId,
    required DateTime unlockedAt,
    @Default({}) Map<String, dynamic> unlockedContext,
    @Default(false) bool isShowcased,
    int? showcaseOrder,
    DateTime? sharedAt,
    @Default(0) int shareCount,
    // Relations
    Badge? badge,
  }) = _UserBadge;

  factory UserBadge.fromJson(Map<String, dynamic> json) =>
      _$UserBadgeFromJson(json);

  bool get isNew {
    final diff = DateTime.now().difference(unlockedAt);
    return diff.inDays < 7; // Considéré comme nouveau pendant 7 jours
  }
}

// ═══════════════════════════════════════════════════════════
// STREAK MODELS
// ═══════════════════════════════════════════════════════════

@freezed
class UserStreak with _$UserStreak {
  const factory UserStreak({
    required String id,
    required String userId,
    @Default(StreakType.dailyCheckIn) StreakType type,
    @Default(0) int currentStreak,
    @Default(0) int longestStreak,
    @Default(0) int totalDays,
    DateTime? lastActivityDate,
    @Default([]) List<bool> recentHistory,
    @Default(7) int nextMilestone,
  }) = _UserStreak;

  factory UserStreak.fromJson(Map<String, dynamic> json) =>
      _$UserStreakFromJson(json);

  String get typeLabel {
    return switch (type) {
      StreakType.dailyCheckIn => 'Connexion quotidienne',
      StreakType.underBudget => 'Sous budget',
      StreakType.transactionLogged => 'Transactions enregistrées',
      StreakType.noImpulseBuy => 'Pas d\'achat impulsif',
      StreakType.savingMade => 'Épargne quotidienne',
    };
  }

  IconData get typeIcon {
    return switch (type) {
      StreakType.dailyCheckIn => Icons.login,
      StreakType.underBudget => Icons.trending_down,
      StreakType.transactionLogged => Icons.receipt_long,
      StreakType.noImpulseBuy => Icons.shopping_bag_outlined,
      StreakType.savingMade => Icons.savings,
    };
  }

  bool get isActiveToday {
    if (lastActivityDate == null) return false;
    return lastActivityDate!.isAtSameMomentAs(
      DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0),
    );
  }

  double get progressToNextMilestone {
    if (nextMilestone == 0) return 1.0;
    return (currentStreak / nextMilestone).clamp(0.0, 1.0);
  }
}

// ═══════════════════════════════════════════════════════════
// XP & LEVELING MODELS
// ═══════════════════════════════════════════════════════════

@freezed
class UserXP with _$UserXP {
  const factory UserXP({
    required String id,
    required String userId,
    @Default(1) int level,
    @Default(0) int totalXp,
    @Default(0) int currentLevelXp,
    @Default(100) int xpToNextLevel,
    @Default([]) List<Map<String, dynamic>> recentTransactions,
    DateTime? updatedAt,
  }) = _UserXP;

  factory UserXP.fromJson(Map<String, dynamic> json) =>
      _$UserXPFromJson(json);

  double get levelProgress {
    if (xpToNextLevel == 0) return 1.0;
    return (currentLevelXp / xpToNextLevel).clamp(0.0, 1.0);
  }

  String get levelTitle {
    return switch (level) {
      1 => 'Débutant',
      2 => 'Apprenti',
      3 => 'Épargnant',
      4 => 'Économe',
      5 => 'Financier',
      6 => 'Investisseur',
      7 => 'Expert',
      8 => 'Maître',
      9 => 'Légende',
      10 => 'Gourou',
      _ => 'Mythique',
    };
  }
}

@freezed
class XPTransaction with _$XPTransaction {
  const factory XPTransaction({
    required String id,
    required String userId,
    required int amount,
    required String reason,
    required String sourceType,
    String? sourceId,
    @Default({}) Map<String, dynamic> metadata,
    required DateTime createdAt,
  }) = _XPTransaction;

  factory XPTransaction.fromJson(Map<String, dynamic> json) =>
      _$XPTransactionFromJson(json);

  bool get isPositive => amount > 0;
}

// ═══════════════════════════════════════════════════════════
// LEADERBOARD MODELS
// ═══════════════════════════════════════════════════════════

@freezed
class Leaderboard with _$Leaderboard {
  const factory Leaderboard({
    required String id,
    @Default(LeaderboardType.xpEarned) LeaderboardType type,
    required DateTime periodStart,
    required DateTime periodEnd,
    @Default(true) bool isActive,
    @Default(false) bool isFinalized,
    required DateTime createdAt,
  }) = _Leaderboard;

  factory Leaderboard.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardFromJson(json);

  String get periodLabel {
    final now = DateTime.now();
    if (periodStart.isBefore(now) && periodEnd.isAfter(now)) {
      return 'En cours';
    }
    if (periodEnd.isBefore(now)) {
      return 'Terminé';
    }
    return 'À venir';
  }
}

@freezed
class LeaderboardEntry with _$LeaderboardEntry {
  const factory LeaderboardEntry({
    required String id,
    required String leaderboardId,
    required String userId,
    required int rank,
    required double score,
    @Default({}) Map<String, dynamic> details,
    @Default(false) bool rewardClaimed,
    String? rewardType,
    int? rewardAmount,
    DateTime? updatedAt,
    // Relations
    String? userName,
    String? userAvatar,
  }) = _LeaderboardEntry;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardEntryFromJson(json);

  String get rankEmoji {
    return switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '$rank',
    };
  }
}

// ═══════════════════════════════════════════════════════════
// SOCIAL SHARE MODELS
// ═══════════════════════════════════════════════════════════

@freezed
class SocialShare with _$SocialShare {
  const factory SocialShare({
    required String id,
    required String userId,
    required String contentType,
    String? contentId,
    @Default(SocialSharePlatform.other) SocialSharePlatform platform,
    @Default({}) Map<String, dynamic> shareData,
    @Default(0) int views,
    @Default(0) int clicks,
    @Default(0) int xpRewarded,
    required DateTime createdAt,
  }) = _SocialShare;

  factory SocialShare.fromJson(Map<String, dynamic> json) =>
      _$SocialShareFromJson(json);

  IconData get platformIcon {
    return switch (platform) {
      SocialSharePlatform.instagram => Icons.camera_alt,
      SocialSharePlatform.facebook => Icons.facebook,
      SocialSharePlatform.twitter => Icons.flutter_dash,
      SocialSharePlatform.whatsapp => Icons.chat,
      SocialSharePlatform.other => Icons.share,
    };
  }
}

// ═══════════════════════════════════════════════════════════
// STATE MODELS
// ═══════════════════════════════════════════════════════════

@freezed
class ChallengesState with _$ChallengesState {
  const factory ChallengesState({
    @Default([]) List<Challenge> availableChallenges,
    @Default([]) List<UserChallenge> activeChallenges,
    @Default([]) List<UserChallenge> completedChallenges,
    @Default(false) bool isLoading,
    String? error,
  }) = _ChallengesState;
}

@freezed
class BadgesState with _$BadgesState {
  const factory BadgesState({
    @Default([]) List<Badge> allBadges,
    @Default([]) List<UserBadge> unlockedBadges,
    @Default([]) List<UserBadge> showcasedBadges,
    @Default(false) bool isLoading,
    String? error,
  }) = _BadgesState;

  int get unlockedCount => unlockedBadges.length;
  int get totalCount => allBadges.length;
  double get completionPercentage => 
      allBadges.isEmpty ? 0 : (unlockedCount / totalCount * 100);
}

@freezed
class GamificationSummary with _$GamificationSummary {
  const factory GamificationSummary({
    required UserXP userXP,
    @Default([]) List<UserStreak> streaks,
    @Default([]) List<UserChallenge> activeChallenges,
    @Default([]) List<UserBadge> recentBadges,
    @Default([]) List<LeaderboardEntry> leaderboardPosition,
  }) = _GamificationSummary;
}

// Extension pour IconData
extension IconDataExtension on StreakType {
  IconData get icon {
    return switch (this) {
      StreakType.dailyCheckIn => Icons.login,
      StreakType.underBudget => Icons.trending_down,
      StreakType.transactionLogged => Icons.receipt_long,
      StreakType.noImpulseBuy => Icons.shopping_bag_outlined,
      StreakType.savingMade => Icons.savings,
    };
  }
}
