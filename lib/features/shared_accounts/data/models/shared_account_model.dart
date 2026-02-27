import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'shared_account_model.freezed.dart';
part 'shared_account_model.g.dart';

/// Mode de partage d'un compte
enum SharingMode {
  couple,
  family,
  roommates,
}

/// Rôle d'un membre dans un compte partagé
enum SharedMemberRole {
  owner,
  admin,
  member,
  child,
  viewer,
}

/// Statut d'une invitation
enum InvitationStatus {
  pending,
  accepted,
  declined,
  expired,
  revoked,
}

/// Statut d'un compte partagé
enum SharedAccountStatus {
  active,
  archived,
  deleted,
}

/// Configuration pour le mode Couple
@freezed
class CoupleConfig with _$CoupleConfig {
  const factory CoupleConfig({
    @Default('full') String incomeSharing, // full, proportional, separate
    @Default(true) bool notifyLargeExpenses,
    @Default(100.0) double largeExpenseThreshold,
  }) = _CoupleConfig;

  factory CoupleConfig.fromJson(Map<String, dynamic> json) =>
      _$CoupleConfigFromJson(json);
}

/// Configuration pour le mode Famille
@freezed
class FamilyConfig with _$FamilyConfig {
  const factory FamilyConfig({
    @Default(false) bool childrenCanView,
    @Default(false) bool childrenCanAdd,
    @Default(true) bool parentApproval,
    @Default(50.0) double childSpendingLimit,
  }) = _FamilyConfig;

  factory FamilyConfig.fromJson(Map<String, dynamic> json) =>
      _$FamilyConfigFromJson(json);
}

/// Configuration pour le mode Roommates
@freezed
class RoommatesConfig with _$RoommatesConfig {
  const factory RoommatesConfig({
    @Default('equal') String expenseSplitting, // equal, custom
    @Default(1) int settlementDay, // Jour du mois pour les règlements
    @Default(true) bool notifyNewExpense,
    @Default(true) bool autoCalculateBalances,
  }) = _RoommatesConfig;

  factory RoommatesConfig.fromJson(Map<String, dynamic> json) =>
      _$RoommatesConfigFromJson(json);
}

/// Permissions granulaires d'un membre
@freezed
class MemberPermissions with _$MemberPermissions {
  const factory MemberPermissions({
    @Default(true) bool canViewAllTransactions,
    @Default(true) bool canAddTransactions,
    @Default(false) bool canEditTransactions,
    @Default(false) bool canDeleteTransactions,
    @Default(false) bool canInviteMembers,
    @Default(false) bool canManageSettings,
    @Default(true) bool canViewAnalytics,
  }) = _MemberPermissions;

  factory MemberPermissions.fromJson(Map<String, dynamic> json) =>
      _$MemberPermissionsFromJson(json);
}

/// Préférences de notification pour un membre
@freezed
class NotificationPrefs with _$NotificationPrefs {
  const factory NotificationPrefs({
    @Default(true) bool newTransaction,
    @Default(true) bool largeExpense,
    @Default(true) bool weeklySummary,
    @Default(true) bool settlementReminder,
    @Default(true) bool memberJoined,
  }) = _NotificationPrefs;

  factory NotificationPrefs.fromJson(Map<String, dynamic> json) =>
      _$NotificationPrefsFromJson(json);
}

/// Modèle de compte partagé
@freezed
class SharedAccount with _$SharedAccount {
  const factory SharedAccount({
    required String id,
    required String createdBy,
    required String name,
    String? description,
    @Default(SharingMode.couple) SharingMode sharingMode,
    @Default({}) Map<String, dynamic> config,
    @Default('#E8A86C') String color,
    @Default('people') String icon,
    @Default(SharedAccountStatus.active) SharedAccountStatus status,
    @Default(2) int maxMembers,
    @Default(false) bool isProFeature,
    @Default(0.0) double totalBalance,
    @Default(0.0) double totalExpensesThisMonth,
    required DateTime createdAt,
    required DateTime updatedAt,
    // Champs calculés/joints
    List<SharedAccountMember>? members,
    int? adultCount,
    int? childCount,
  }) = _SharedAccount;

  const SharedAccount._();

  factory SharedAccount.fromJson(Map<String, dynamic> json) =>
      _$SharedAccountFromJson(json);

  /// Helpers pour accéder aux configs typées
  CoupleConfig? get coupleConfig {
    if (sharingMode != SharingMode.couple) return null;
    return CoupleConfig.fromJson(config);
  }

  FamilyConfig? get familyConfig {
    if (sharingMode != SharingMode.family) return null;
    return FamilyConfig.fromJson(config);
  }

  RoommatesConfig? get roommatesConfig {
    if (sharingMode != SharingMode.roommates) return null;
    return RoommatesConfig.fromJson(config);
  }

  /// Vérifie si l'utilisateur est membre
  bool isMember(String userId) {
    return members?.any((m) => m.userId == userId) ?? false;
  }

  /// Récupère le rôle d'un utilisateur
  SharedMemberRole? getUserRole(String userId) {
    final member = members?.firstWhere(
      (m) => m.userId == userId,
      orElse: () => throw Exception('Not a member'),
    );
    return member?.role;
  }

  /// Vérifie si l'utilisateur est owner ou admin
  bool isAdmin(String userId) {
    final role = getUserRole(userId);
    return role == SharedMemberRole.owner || role == SharedMemberRole.admin;
  }
}

/// Modèle de membre d'un compte partagé
@freezed
class SharedAccountMember with _$SharedAccountMember {
  const factory SharedAccountMember({
    required String id,
    required String sharedAccountId,
    required String userId,
    @Default(SharedMemberRole.member) SharedMemberRole role,
    @Default(MemberPermissions()) MemberPermissions permissions,
    String? displayName,
    String? avatarUrl,
    required DateTime joinedAt,
    String? invitedBy,
    @Default(NotificationPrefs()) NotificationPrefs notificationPrefs,
    // Champs joints
    String? fullName,
    String? email,
  }) = _SharedAccountMember;

  factory SharedAccountMember.fromJson(Map<String, dynamic> json) =>
      _$SharedAccountMemberFromJson(json);

  /// Nom d'affichage effectif
  String get effectiveDisplayName => displayName ?? fullName ?? 'Membre';

  /// Vérifie si le membre a une permission spécifique
  bool hasPermission(String permission) {
    switch (permission) {
      case 'canViewAllTransactions':
        return permissions.canViewAllTransactions;
      case 'canAddTransactions':
        return permissions.canAddTransactions;
      case 'canEditTransactions':
        return permissions.canEditTransactions;
      case 'canDeleteTransactions':
        return permissions.canDeleteTransactions;
      case 'canInviteMembers':
        return permissions.canInviteMembers;
      case 'canManageSettings':
        return permissions.canManageSettings;
      case 'canViewAnalytics':
        return permissions.canViewAnalytics;
      default:
        return false;
    }
  }
}

/// Modèle d'invitation
@freezed
class SharedInvitation with _$SharedInvitation {
  const factory SharedInvitation({
    required String id,
    required String sharedAccountId,
    required String invitedBy,
    String? email,
    String? invitedUserId,
    @Default(SharedMemberRole.member) SharedMemberRole role,
    @Default(MemberPermissions()) MemberPermissions permissions,
    required String token,
    @Default(InvitationStatus.pending) InvitationStatus status,
    required DateTime expiresAt,
    String? message,
    required DateTime createdAt,
    DateTime? respondedAt,
    // Champs joints
    String? inviterName,
    String? inviterAvatar,
    String? sharedAccountName,
    String? invitedUserName,
  }) = _SharedInvitation;

  factory SharedInvitation.fromJson(Map<String, dynamic> json) =>
      _$SharedInvitationFromJson(json);

  /// Vérifie si l'invitation est expirée
  bool get isExpired => expiresAt.isBefore(DateTime.now());

  /// Vérifie si l'invitation est encore valide
  bool get isValid => status == InvitationStatus.pending && !isExpired;

  /// Jours restants avant expiration
  int get daysRemaining {
    final diff = expiresAt.difference(DateTime.now());
    return diff.inDays.clamp(0, 999);
  }
}

/// Modèle de transaction partagée
@freezed
class SharedTransaction with _$SharedTransaction {
  const factory SharedTransaction({
    required String id,
    required String sharedAccountId,
    required String createdBy,
    String? personalTransactionId,
    required double amount,
    @Default('EUR') String currency,
    required String description,
    String? category,
    String? subcategory,
    String? merchant,
    required DateTime transactionDate,
    @Default('confirmed') String status,
    @Default('equal') String splitType, // equal, percentage, amount, custom
    @Default([]) List<SplitDetail> splitDetails,
    String? receiptUrl,
    String? notes,
    @Default([]) List<String> tags,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? updatedBy,
    // Champs joints
    String? creatorName,
    String? creatorAvatar,
  }) = _SharedTransaction;

  factory SharedTransaction.fromJson(Map<String, dynamic> json) =>
      _$SharedTransactionFromJson(json);

  /// Vérifie si c'est une dépense
  bool get isExpense => amount < 0;

  /// Montant absolu
  double get absoluteAmount => amount.abs();

  /// Montant payé par un utilisateur spécifique
  double getAmountForUser(String userId) {
    final detail = splitDetails.firstWhere(
      (d) => d.userId == userId,
      orElse: () => const SplitDetail(userId: '', amount: 0),
    );
    return detail.amount;
  }

  /// Vérifie si un utilisateur a payé sa part
  bool isPaidByUser(String userId) {
    final detail = splitDetails.firstWhere(
      (d) => d.userId == userId,
      orElse: () => const SplitDetail(userId: '', amount: 0, paid: false),
    );
    return detail.paid ?? false;
  }
}

/// Détail de répartition d'une transaction
@freezed
class SplitDetail with _$SplitDetail {
  const factory SplitDetail({
    required String userId,
    required double amount,
    double? percentage,
    @Default(false) bool? paid,
    DateTime? paidAt,
    String? paymentMethod,
  }) = _SplitDetail;

  factory SplitDetail.fromJson(Map<String, dynamic> json) =>
      _$SplitDetailFromJson(json);
}

/// Modèle de règlement entre membres
@freezed
class SharedSettlement with _$SharedSettlement {
  const factory SharedSettlement({
    required String id,
    required String sharedAccountId,
    required String fromUserId,
    required String toUserId,
    required double amount,
    @Default('EUR') String currency,
    @Default('pending') String status,
    String? paymentMethod,
    String? paymentReference,
    @Default([]) List<String> relatedTransactionIds,
    required DateTime createdAt,
    DateTime? completedAt,
    // Champs joints
    String? fromUserName,
    String? fromUserAvatar,
    String? toUserName,
    String? toUserAvatar,
  }) = _SharedSettlement;

  factory SharedSettlement.fromJson(Map<String, dynamic> json) =>
      _$SharedSettlementFromJson(json);

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
}

/// État du chargement des comptes partagés
@freezed
class SharedAccountsState with _$SharedAccountsState {
  const factory SharedAccountsState({
    @Default([]) List<SharedAccount> accounts,
    @Default(false) bool isLoading,
    String? error,
    SharedAccount? selectedAccount,
  }) = _SharedAccountsState;
}

/// État des invitations
@freezed
class InvitationsState with _$InvitationsState {
  const factory InvitationsState({
    @Default([]) List<SharedInvitation> receivedInvitations,
    @Default([]) List<SharedInvitation> sentInvitations,
    @Default(false) bool isLoading,
    String? error,
  }) = _InvitationsState;
}
