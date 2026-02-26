import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';
import '../domain/account_model.dart';

/// Repository pour la gestion des comptes bancaires
class AccountsRepository {
  final SupabaseClient _client;

  AccountsRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.instance.client;

  /// Récupère tous les comptes de l'utilisateur
  Future<List<Account>> getAccounts() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    final response = await _client
        .from('accounts')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('is_primary', ascending: false);

    return (response as List).map((json) => Account.fromJson(json)).toList();
  }

  /// Récupère un compte par son ID
  Future<Account?> getAccountById(String id) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    final response = await _client
        .from('accounts')
        .select()
        .eq('id', id)
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return Account.fromJson(response);
  }

  /// Crée un nouveau compte
  Future<Account> createAccount({
    required String name,
    required AccountType type,
    double initialBalance = 0.0,
    String? color,
    String? institution,
    bool isPrimary = false,
    String? accountNumberMasked,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    // Si c'est le premier compte principal, désactiver les autres
    if (isPrimary) {
      await _unsetPrimaryAccount(userId);
    }

    final data = {
      'user_id': userId,
      'name': name,
      'type': type.name,
      'balance': initialBalance,
      'color': color ?? '#E8A86C',
      'institution': institution,
      'is_primary': isPrimary,
      'account_number_masked': accountNumberMasked,
    };

    final response = await _client
        .from('accounts')
        .insert(data)
        .select()
        .single();

    return Account.fromJson(response);
  }

  /// Met à jour un compte
  Future<Account> updateAccount(
    String id, {
    String? name,
    AccountType? type,
    double? balance,
    String? color,
    String? institution,
    bool? isPrimary,
    bool? isActive,
    String? accountNumberMasked,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    // Si on définit ce compte comme principal
    if (isPrimary == true) {
      await _unsetPrimaryAccount(userId);
    }

    final updates = <String, dynamic>{
      if (name != null) 'name': name,
      if (type != null) 'type': type.name,
      if (balance != null) 'balance': balance,
      if (color != null) 'color': color,
      if (institution != null) 'institution': institution,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (isActive != null) 'is_active': isActive,
      if (accountNumberMasked != null) 'account_number_masked': accountNumberMasked,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _client
        .from('accounts')
        .update(updates)
        .eq('id', id)
        .eq('user_id', userId)
        .select()
        .single();

    return Account.fromJson(response);
  }

  /// Supprime (désactive) un compte
  Future<void> deleteAccount(String id) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    await _client
        .from('accounts')
        .update({'is_active': false})
        .eq('id', id)
        .eq('user_id', userId);
  }

  /// Récupère le solde total
  Future<double> getTotalBalance() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0.0;

    final response = await _client.rpc(
      'get_user_total_balance',
      params: {'user_uuid': userId},
    );

    return (response as num?)?.toDouble() ?? 0.0;
  }

  /// Définit un compte comme principal
  Future<void> setPrimaryAccount(String id) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    await _unsetPrimaryAccount(userId);

    await _client
        .from('accounts')
        .update({'is_primary': true})
        .eq('id', id)
        .eq('user_id', userId);
  }

  /// Désactive le statut principal de tous les comptes
  Future<void> _unsetPrimaryAccount(String userId) async {
    await _client
        .from('accounts')
        .update({'is_primary': false})
        .eq('user_id', userId)
        .eq('is_primary', true);
  }
}
