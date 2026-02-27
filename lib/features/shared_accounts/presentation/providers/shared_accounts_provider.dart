import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/shared_account_model.dart';
import '../../data/repositories/shared_accounts_repository.dart';

part 'shared_accounts_provider.g.dart';

// ═══════════════════════════════════════════════════════════
// REPOSITORY PROVIDER
// ═══════════════════════════════════════════════════════════

final sharedAccountsRepositoryProvider = Provider<SharedAccountsRepository>((ref) {
  return SharedAccountsRepository(Supabase.instance.client);
});

// ═══════════════════════════════════════════════════════════
// STATE PROVIDERS
// ═══════════════════════════════════════════════════════════

/// Provider pour la liste des comptes partagés
@riverpod
class SharedAccountsList extends _$SharedAccountsList {
  @override
  Future<List<SharedAccount>> build() async {
    final repository = ref.read(sharedAccountsRepositoryProvider);
    return repository.getSharedAccounts();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(sharedAccountsRepositoryProvider);
      return repository.getSharedAccounts();
    });
  }

  Future<void> createAccount({
    required String name,
    required SharingMode sharingMode,
    String? description,
    Map<String, dynamic>? config,
    String? color,
    String? icon,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(sharedAccountsRepositoryProvider);
      await repository.createSharedAccount(
        name: name,
        sharingMode: sharingMode,
        description: description,
        config: config,
        color: color,
        icon: icon,
      );
      return repository.getSharedAccounts();
    });
  }

  Future<void> archiveAccount(String accountId) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(sharedAccountsRepositoryProvider);
      await repository.archiveSharedAccount(accountId);
      return repository.getSharedAccounts();
    });
  }
}

/// Provider pour un compte partagé spécifique
@riverpod
class SharedAccountDetail extends _$SharedAccountDetail {
  @override
  Future<SharedAccount?> build(String accountId) async {
    final repository = ref.read(sharedAccountsRepositoryProvider);
    return repository.getSharedAccountById(accountId);
  }

  Future<void> refresh() async {
    final accountId = (state.valueOrNull)?.id;
    if (accountId == null) return;
    
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(sharedAccountsRepositoryProvider);
      return repository.getSharedAccountById(accountId);
    });
  }

  Future<void> updateAccount({
    String? name,
    String? description,
    Map<String, dynamic>? config,
    String? color,
    String? icon,
  }) async {
    final accountId = state.valueOrNull?.id;
    if (accountId == null) return;

    state = await AsyncValue.guard(() async {
      final repository = ref.read(sharedAccountsRepositoryProvider);
      await repository.updateSharedAccount(
        accountId: accountId,
        name: name,
        description: description,
        config: config,
        color: color,
        icon: icon,
      );
      return repository.getSharedAccountById(accountId);
    });
  }
}

/// Provider pour les membres d'un compte
@riverpod
class SharedAccountMembers extends _$SharedAccountMembers {
  @override
  Future<List<SharedAccountMember>> build(String accountId) async {
    final repository = ref.read(sharedAccountsRepositoryProvider);
    return repository.getMembers(accountId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(sharedAccountsRepositoryProvider);
      final accountId = ref.read(sharedAccountIdProvider);
      return repository.getMembers(accountId);
    });
  }

  Future<void> updateMemberRole(String userId, SharedMemberRole newRole) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(sharedAccountsRepositoryProvider);
      final accountId = ref.read(sharedAccountIdProvider);
      await repository.updateMemberRole(
        accountId: accountId,
        userId: userId,
        newRole: newRole,
      );
      return repository.getMembers(accountId);
    });
  }

  Future<void> removeMember(String userId) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(sharedAccountsRepositoryProvider);
      final accountId = ref.read(sharedAccountIdProvider);
      await repository.removeMember(
        accountId: accountId,
        userId: userId,
      );
      return repository.getMembers(accountId);
    });
  }
}

/// Provider pour l'ID du compte courant (à utiliser avec override)
final sharedAccountIdProvider = Provider<String>((ref) {
  throw UnimplementedError('Must override sharedAccountIdProvider');
});

// ═══════════════════════════════════════════════════════════
// INVITATIONS PROVIDERS
// ═══════════════════════════════════════════════════════════

/// Provider pour les invitations reçues
@riverpod
class ReceivedInvitations extends _$ReceivedInvitations {
  @override
  Future<List<SharedInvitation>> build() async {
    final repository = ref.read(sharedAccountsRepositoryProvider);
    return repository.getReceivedInvitations();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(sharedAccountsRepositoryProvider);
      return repository.getReceivedInvitations();
    });
  }

  Future<void> acceptInvitation(String invitationId) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(sharedAccountsRepositoryProvider);
      await repository.acceptInvitation(invitationId);
      // Rafraîchir aussi la liste des comptes
      ref.invalidate(sharedAccountsListProvider);
      return repository.getReceivedInvitations();
    });
  }

  Future<void> declineInvitation(String invitationId) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(sharedAccountsRepositoryProvider);
      await repository.declineInvitation(invitationId);
      return repository.getReceivedInvitations();
    });
  }
}

/// Provider pour les invitations envoyées
@riverpod
class SentInvitations extends _$SentInvitations {
  @override
  Future<List<SharedInvitation>> build() async {
    final repository = ref.read(sharedAccountsRepositoryProvider);
    return repository.getSentInvitations();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(sharedAccountsRepositoryProvider);
      return repository.getSentInvitations();
    });
  }

  Future<void> sendInvitation({
    required String accountId,
    required String email,
    required SharedMemberRole role,
    String? message,
  }) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(sharedAccountsRepositoryProvider);
      await repository.sendInvitation(
        accountId: accountId,
        email: email,
        role: role,
        message: message,
      );
      return repository.getSentInvitations();
    });
  }

  Future<void> revokeInvitation(String invitationId) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(sharedAccountsRepositoryProvider);
      await repository.revokeInvitation(invitationId);
      return repository.getSentInvitations();
    });
  }
}

// ═══════════════════════════════════════════════════════════
// TRANSACTIONS PARTAGÉES PROVIDERS
// ═══════════════════════════════════════════════════════════

/// Provider pour les transactions d'un compte partagé
@riverpod
class SharedAccountTransactions extends _$SharedAccountTransactions {
  @override
  Future<List<SharedTransaction>> build(String accountId) async {
    final repository = ref.read(sharedAccountsRepositoryProvider);
    return repository.getTransactions(accountId: accountId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(sharedAccountsRepositoryProvider);
      final accountId = ref.read(sharedAccountIdProvider);
      return repository.getTransactions(accountId: accountId);
    });
  }

  Future<void> addTransaction({
    required double amount,
    required String description,
    required DateTime transactionDate,
    String? category,
    String? splitType,
    List<SplitDetail>? splitDetails,
  }) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(sharedAccountsRepositoryProvider);
      final accountId = ref.read(sharedAccountIdProvider);
      await repository.createTransaction(
        accountId: accountId,
        amount: amount,
        description: description,
        transactionDate: transactionDate,
        category: category,
        splitType: splitType,
        splitDetails: splitDetails,
      );
      return repository.getTransactions(accountId: accountId);
    });
  }
}

// ═══════════════════════════════════════════════════════════
// UI STATE PROVIDERS
// ═══════════════════════════════════════════════════════════

/// Mode de création sélectionné
final selectedSharingModeProvider = StateProvider<SharingMode>((ref) => SharingMode.couple);

/// Index de la page sélectionnée dans le bottom nav
final sharedAccountTabIndexProvider = StateProvider<int>((ref) => 0);

/// Recherche de membres
final memberSearchQueryProvider = StateProvider<String>((ref) => '');

/// État d'expansion des sections
final expandedSectionsProvider = StateProvider<Set<String>>((ref) => {});
