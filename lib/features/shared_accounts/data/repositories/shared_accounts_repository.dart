import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../models/shared_account_model.dart';

/// Repository pour la gestion des comptes partagés
class SharedAccountsRepository {
  final SupabaseClient _supabase;
  final Logger _logger = Logger();

  SharedAccountsRepository(this._supabase);

  // ═══════════════════════════════════════════════════════════
  // COMPTES PARTAGÉS
  // ═══════════════════════════════════════════════════════════

  /// Récupère tous les comptes partagés de l'utilisateur courant
  Future<List<SharedAccount>> getSharedAccounts() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('shared_accounts')
          .select('''
            *,
            shared_account_members!inner(
              user_id,
              role,
              display_name,
              avatar_url,
              joined_at
            )
          ''')
          .eq('shared_account_members.user_id', userId)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => SharedAccount.fromJson(json))
          .toList();
    } catch (e, stackTrace) {
      _logger.e('Error fetching shared accounts', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Récupère un compte partagé par son ID avec tous les membres
  Future<SharedAccount?> getSharedAccountById(String accountId) async {
    try {
      final response = await _supabase
          .from('shared_accounts')
          .select('''
            *,
            shared_account_members(
              id,
              user_id,
              role,
              permissions,
              display_name,
              avatar_url,
              joined_at,
              notification_prefs,
              profiles:user_id(full_name, email, avatar_url)
            )
          ''')
          .eq('id', accountId)
          .single();

      // Transformer les données imbriquées
      final members = (response['shared_account_members'] as List?)
          ?.map((m) {
            final profile = m['profiles'] as Map<String, dynamic>?;
            return SharedAccountMember.fromJson({
              ...m,
              'full_name': profile?['full_name'],
              'email': profile?['email'],
              'avatar_url': m['avatar_url'] ?? profile?['avatar_url'],
            });
          })
          .toList();

      return SharedAccount.fromJson({
        ...response,
        'members': members,
      });
    } catch (e, stackTrace) {
      _logger.e('Error fetching shared account', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Crée un nouveau compte partagé
  Future<SharedAccount> createSharedAccount({
    required String name,
    required SharingMode sharingMode,
    String? description,
    Map<String, dynamic>? config,
    String? color,
    String? icon,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('shared_accounts')
          .insert({
            'created_by': userId,
            'name': name,
            'description': description,
            'sharing_mode': sharingMode.name,
            'config': config ?? {},
            'color': color ?? '#E8A86C',
            'icon': icon ?? 'people',
            'status': 'active',
          })
          .select()
          .single();

      // Ajouter automatiquement le créateur comme owner
      await _supabase.from('shared_account_members').insert({
        'shared_account_id': response['id'],
        'user_id': userId,
        'role': 'owner',
        'permissions': {},
        'joined_at': DateTime.now().toIso8601String(),
      });

      return SharedAccount.fromJson(response);
    } catch (e, stackTrace) {
      _logger.e('Error creating shared account', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Met à jour un compte partagé
  Future<SharedAccount> updateSharedAccount({
    required String accountId,
    String? name,
    String? description,
    Map<String, dynamic>? config,
    String? color,
    String? icon,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (config != null) updates['config'] = config;
      if (color != null) updates['color'] = color;
      if (icon != null) updates['icon'] = icon;

      final response = await _supabase
          .from('shared_accounts')
          .update(updates)
          .eq('id', accountId)
          .select()
          .single();

      return SharedAccount.fromJson(response);
    } catch (e, stackTrace) {
      _logger.e('Error updating shared account', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Archive un compte partagé
  Future<void> archiveSharedAccount(String accountId) async {
    try {
      await _supabase
          .from('shared_accounts')
          .update({'status': 'archived'})
          .eq('id', accountId);
    } catch (e, stackTrace) {
      _logger.e('Error archiving shared account', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // MEMBRES
  // ═══════════════════════════════════════════════════════════

  /// Récupère les membres d'un compte partagé
  Future<List<SharedAccountMember>> getMembers(String accountId) async {
    try {
      final response = await _supabase
          .from('shared_account_members')
          .select('''
            *,
            profiles:user_id(full_name, email, avatar_url)
          ''')
          .eq('shared_account_id', accountId)
          .order('joined_at', ascending: true);

      return (response as List).map((json) {
        final profile = json['profiles'] as Map<String, dynamic>?;
        return SharedAccountMember.fromJson({
          ...json,
          'full_name': profile?['full_name'],
          'email': profile?['email'],
          'avatar_url': json['avatar_url'] ?? profile?['avatar_url'],
        });
      }).toList();
    } catch (e, stackTrace) {
      _logger.e('Error fetching members', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Met à jour le rôle d'un membre
  Future<void> updateMemberRole({
    required String accountId,
    required String userId,
    required SharedMemberRole newRole,
  }) async {
    try {
      await _supabase
          .from('shared_account_members')
          .update({'role': newRole.name})
          .eq('shared_account_id', accountId)
          .eq('user_id', userId);
    } catch (e, stackTrace) {
      _logger.e('Error updating member role', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Met à jour les permissions d'un membre
  Future<void> updateMemberPermissions({
    required String accountId,
    required String userId,
    required MemberPermissions permissions,
  }) async {
    try {
      await _supabase
          .from('shared_account_members')
          .update({'permissions': permissions.toJson()})
          .eq('shared_account_id', accountId)
          .eq('user_id', userId);
    } catch (e, stackTrace) {
      _logger.e('Error updating member permissions', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Retire un membre du compte partagé
  Future<void> removeMember({
    required String accountId,
    required String userId,
  }) async {
    try {
      await _supabase
          .from('shared_account_members')
          .delete()
          .eq('shared_account_id', accountId)
          .eq('user_id', userId);
    } catch (e, stackTrace) {
      _logger.e('Error removing member', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Quitte un compte partagé (pour soi-même)
  Future<void> leaveAccount(String accountId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase
          .from('shared_account_members')
          .delete()
          .eq('shared_account_id', accountId)
          .eq('user_id', userId);
    } catch (e, stackTrace) {
      _logger.e('Error leaving account', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // INVITATIONS
  // ═══════════════════════════════════════════════════════════

  /// Envoie une invitation
  Future<SharedInvitation> sendInvitation({
    required String accountId,
    required String email,
    required SharedMemberRole role,
    MemberPermissions? permissions,
    String? message,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('shared_invitations')
          .insert({
            'shared_account_id': accountId,
            'invited_by': userId,
            'email': email.toLowerCase().trim(),
            'role': role.name,
            'permissions': permissions?.toJson() ?? {},
            'message': message,
            'status': 'pending',
            'expires_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
          })
          .select('''
            *,
            inviter:invited_by(full_name, avatar_url),
            account:shared_account_id(name)
          ''')
          .single();

      return SharedInvitation.fromJson({
        ...response,
        'inviter_name': response['inviter']?['full_name'],
        'inviter_avatar': response['inviter']?['avatar_url'],
        'shared_account_name': response['account']?['name'],
      });
    } catch (e, stackTrace) {
      _logger.e('Error sending invitation', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Récupère les invitations reçues par l'utilisateur
  Future<List<SharedInvitation>> getReceivedInvitations() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Récupérer par email
      final userEmail = _supabase.auth.currentUser?.email;
      
      final response = await _supabase
          .from('shared_invitations')
          .select('''
            *,
            inviter:invited_by(full_name, avatar_url),
            account:shared_account_id(name),
            invited_user:invited_user_id(full_name)
          ''')
          .or('email.eq.$userEmail,invited_user_id.eq.$userId')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List).map((json) => SharedInvitation.fromJson({
        ...json,
        'inviter_name': json['inviter']?['full_name'],
        'inviter_avatar': json['inviter']?['avatar_url'],
        'shared_account_name': json['account']?['name'],
        'invited_user_name': json['invited_user']?['full_name'],
      })).toList();
    } catch (e, stackTrace) {
      _logger.e('Error fetching received invitations', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Récupère les invitations envoyées par l'utilisateur
  Future<List<SharedInvitation>> getSentInvitations() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('shared_invitations')
          .select('''
            *,
            account:shared_account_id(name),
            invited_user:invited_user_id(full_name)
          ''')
          .eq('invited_by', userId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => SharedInvitation.fromJson({
        ...json,
        'shared_account_name': json['account']?['name'],
        'invited_user_name': json['invited_user']?['full_name'],
      })).toList();
    } catch (e, stackTrace) {
      _logger.e('Error fetching sent invitations', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Accepte une invitation
  Future<void> acceptInvitation(String invitationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Récupérer l'invitation
      final invitation = await _supabase
          .from('shared_invitations')
          .select()
          .eq('id', invitationId)
          .single();

      // Ajouter le membre
      await _supabase.from('shared_account_members').insert({
        'shared_account_id': invitation['shared_account_id'],
        'user_id': userId,
        'role': invitation['role'],
        'permissions': invitation['permissions'] ?? {},
        'invited_by': invitation['invited_by'],
        'joined_at': DateTime.now().toIso8601String(),
      });

      // Mettre à jour le statut
      await _supabase
          .from('shared_invitations')
          .update({
            'status': 'accepted',
            'responded_at': DateTime.now().toIso8601String(),
            'invited_user_id': userId,
          })
          .eq('id', invitationId);
    } catch (e, stackTrace) {
      _logger.e('Error accepting invitation', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Décline une invitation
  Future<void> declineInvitation(String invitationId) async {
    try {
      await _supabase
          .from('shared_invitations')
          .update({
            'status': 'declined',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', invitationId);
    } catch (e, stackTrace) {
      _logger.e('Error declining invitation', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Révoque une invitation
  Future<void> revokeInvitation(String invitationId) async {
    try {
      await _supabase
          .from('shared_invitations')
          .update({'status': 'revoked'})
          .eq('id', invitationId);
    } catch (e, stackTrace) {
      _logger.e('Error revoking invitation', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // TRANSACTIONS PARTAGÉES
  // ═══════════════════════════════════════════════════════════

  /// Récupère les transactions d'un compte partagé
  Future<List<SharedTransaction>> getTransactions({
    required String accountId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('shared_transactions')
          .select('''
            *,
            creator:created_by(full_name, avatar_url)
          ''')
          .eq('shared_account_id', accountId)
          .order('transaction_date', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) => SharedTransaction.fromJson({
        ...json,
        'creator_name': json['creator']?['full_name'],
        'creator_avatar': json['creator']?['avatar_url'],
      })).toList();
    } catch (e, stackTrace) {
      _logger.e('Error fetching transactions', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Crée une transaction partagée
  Future<SharedTransaction> createTransaction({
    required String accountId,
    required double amount,
    required String description,
    required DateTime transactionDate,
    String? category,
    String? subcategory,
    String? merchant,
    String? splitType,
    List<SplitDetail>? splitDetails,
    String? receiptUrl,
    String? notes,
    List<String>? tags,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('shared_transactions')
          .insert({
            'shared_account_id': accountId,
            'created_by': userId,
            'amount': amount,
            'description': description,
            'transaction_date': transactionDate.toIso8601String(),
            'category': category,
            'subcategory': subcategory,
            'merchant': merchant,
            'split_type': splitType ?? 'equal',
            'split_details': splitDetails?.map((d) => {'user_id': d.userId, 'amount': d.amount, 'percentage': d.percentage, 'paid': d.paid, 'paid_at': d.paidAt?.toIso8601String(), 'payment_method': d.paymentMethod}).toList() ?? [],
            'receipt_url': receiptUrl,
            'notes': notes,
            'tags': tags ?? [],
          })
          .select('''
            *,
            creator:created_by(full_name, avatar_url)
          ''')
          .single();

      return SharedTransaction.fromJson({
        ...response,
        'creator_name': response['creator']?['full_name'],
        'creator_avatar': response['creator']?['avatar_url'],
      });
    } catch (e, stackTrace) {
      _logger.e('Error creating transaction', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // REALTIME SUBSCRIPTIONS
  // ═══════════════════════════════════════════════════════════

  /// S'abonne aux changements d'un compte partagé
  Stream<List<Map<String, dynamic>>> subscribeToAccountChanges(String accountId) {
    return _supabase
        .from('shared_accounts')
        .stream(primaryKey: ['id'])
        .eq('id', accountId);
  }

  /// S'abonne aux nouvelles transactions
  Stream<List<Map<String, dynamic>>> subscribeToTransactionChanges(String accountId) {
    return _supabase
        .from('shared_transactions')
        .stream(primaryKey: ['id'])
        .eq('shared_account_id', accountId)
        .order('created_at', ascending: false);
  }
}
