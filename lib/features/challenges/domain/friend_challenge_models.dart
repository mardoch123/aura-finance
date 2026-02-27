import 'package:freezed_annotation/freezed_annotation.dart';

part 'friend_challenge_models.freezed.dart';
part 'friend_challenge_models.g.dart';

/// Modèle d'un défi entre amis
@freezed
class FriendChallenge with _$FriendChallenge {
  const factory FriendChallenge({
    required String id,
    required String creatorId,
    required String title,
    required String description,
    required ChallengeType type,
    required ChallengeStatus status,
    required DateTime startDate,
    required DateTime endDate,
    required List<ChallengeParticipant> participants,
    String? reward,
    double? targetAmount,
    String? category,
    @Default(0) int participantCount,
    DateTime? createdAt,
  }) = _FriendChallenge;

  factory FriendChallenge.fromJson(Map<String, dynamic> json) =>
      _$FriendChallengeFromJson(json);
}

/// Participant à un défi
@freezed
class ChallengeParticipant with _$ChallengeParticipant {
  const factory ChallengeParticipant({
    required String userId,
    required String displayName,
    String? avatarUrl,
    required double currentScore,
    required ChallengeParticipantStatus status,
    DateTime? joinedAt,
    DateTime? completedAt,
    @Default(false) bool isWinner,
  }) = _ChallengeParticipant;

  factory ChallengeParticipant.fromJson(Map<String, dynamic> json) =>
      _$ChallengeParticipantFromJson(json);
}

/// Types de défis disponibles
enum ChallengeType {
  /// Qui économise le plus
  mostSavings,
  
  /// Qui dépense le moins dans une catégorie
  leastSpending,
  
  /// Nombre de jours sans dépense
  noSpendDays,
  
  /// Premier à atteindre un objectif
  raceToGoal,
  
  /// Défi de streak (connexion quotidienne)
  streak,
  
  /// Défi personnalisé
  custom,
}

extension ChallengeTypeExtension on ChallengeType {
  String get label {
    return switch (this) {
      ChallengeType.mostSavings => 'Qui économise le plus ?',
      ChallengeType.leastSpending => 'Qui dépense le moins ?',
      ChallengeType.noSpendDays => 'Jours sans dépense',
      ChallengeType.raceToGoal => 'Course à l\'objectif',
      ChallengeType.streak => 'Série de connexion',
      ChallengeType.custom => 'Défi personnalisé',
    };
  }

  String get description {
    return switch (this) {
      ChallengeType.mostSavings => 'Celui qui met le plus de côté gagne !',
      ChallengeType.leastSpending => 'Qui arrive à réduire ses dépenses ?',
      ChallengeType.noSpendDays => 'Combien de jours sans dépense ?',
      ChallengeType.raceToGoal => 'Premier à atteindre l\'objectif !',
      ChallengeType.streak => 'Qui aura la plus longue série ?',
      ChallengeType.custom => 'Crée ton propre défi',
    };
  }

  IconData get icon {
    return switch (this) {
      ChallengeType.mostSavings => Icons.savings,
      ChallengeType.leastSpending => Icons.trending_down,
      ChallengeType.noSpendDays => Icons.block,
      ChallengeType.raceToGoal => Icons.emoji_events,
      ChallengeType.streak => Icons.local_fire_department,
      ChallengeType.custom => Icons.edit,
    };
  }
}

/// Statut d'un défi
enum ChallengeStatus {
  pending,    // En attente de participants
  active,     // En cours
  completed,  // Terminé
  cancelled,  // Annulé
}

/// Statut d'un participant
enum ChallengeParticipantStatus {
  invited,    // Invité, pas encore rejoint
  joined,     // A rejoint
  declined,   // A refusé
  active,     // Participe activement
  completed,  // A terminé
  winner,     // Gagnant
}

/// Invitation à un défi
@freezed
class ChallengeInvitation with _$ChallengeInvitation {
  const factory ChallengeInvitation({
    required String id,
    required String challengeId,
    required String inviterId,
    required String inviterName,
    required String inviteeId,
    required ChallengeType challengeType,
    required String challengeTitle,
    required DateTime sentAt,
    @Default(InvitationStatus.pending) InvitationStatus status,
    DateTime? respondedAt,
  }) = _ChallengeInvitation;

  factory ChallengeInvitation.fromJson(Map<String, dynamic> json) =>
      _$ChallengeInvitationFromJson(json);
}

enum InvitationStatus {
  pending,
  accepted,
  declined,
  expired,
}

/// Classement d'un défi
@freezed
class ChallengeLeaderboard with _$ChallengeLeaderboard {
  const factory ChallengeLeaderboard({
    required String challengeId,
    required List<LeaderboardEntry> entries,
    required DateTime lastUpdated,
  }) = _ChallengeLeaderboard;

  factory ChallengeLeaderboard.fromJson(Map<String, dynamic> json) =>
      _$ChallengeLeaderboardFromJson(json);
}

@freezed
class LeaderboardEntry with _$LeaderboardEntry {
  const factory LeaderboardEntry({
    required String userId,
    required String displayName,
    String? avatarUrl,
    required int rank,
    required double score,
    required double progress,
    @Default(false) bool isCurrentUser,
  }) = _LeaderboardEntry;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardEntryFromJson(json);
}

/// Historique des défis d'un utilisateur
@freezed
class UserChallengeStats with _$UserChallengeStats {
  const factory UserChallengeStats({
    required String userId,
    @Default(0) int totalChallenges,
    @Default(0) int wins,
    @Default(0) int losses,
    @Default(0) int draws,
    @Default(0) int currentStreak,
    @Default(0) int bestStreak,
    @Default(0) int totalPoints,
    List<String>? badges,
  }) = _UserChallengeStats;

  factory UserChallengeStats.fromJson(Map<String, dynamic> json) =>
      _$UserChallengeStatsFromJson(json);
}
