import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../domain/banking_models.dart';
import '../../services/banking_service.dart';

/// Écran de gestion des comptes connectés (simplifié)
class ConnectedAccountsScreen extends ConsumerStatefulWidget {
  const ConnectedAccountsScreen({super.key});

  @override
  ConsumerState<ConnectedAccountsScreen> createState() => _ConnectedAccountsScreenState();
}

class _ConnectedAccountsScreenState extends ConsumerState<ConnectedAccountsScreen> {
  bool _isLoading = true;
  List<ConnectedBankAccount> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final userId = BankingService.instance._supabase.auth.currentUser?.id;
    if (userId == null) return;

    final accounts = await BankingService.instance.getConnectedAccounts(userId);
    
    setState(() {
      _accounts = accounts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: Text(
          'Comptes connectés',
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.push('/banking/connect'),
            child: Text(
              '+ Ajouter',
              style: GoogleFonts.dmSans(
                color: AuraColors.amber,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AuraColors.amber))
          : _accounts.isEmpty
              ? _buildEmptyState()
              : _buildAccountsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_outlined,
            size: 64,
            color: AuraColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun compte connecté',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connectez votre banque pour importer\nvos transactions automatiquement',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AuraColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => context.push('/banking/connect'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AuraColors.amber, AuraColors.deep],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Connecter une banque',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _accounts.length,
      itemBuilder: (context, index) {
        final account = _accounts[index];
        return _buildAccountCard(account);
      },
    );
  }

  Widget _buildAccountCard(ConnectedBankAccount account) {
    final status = BankConnectionStatus.values.firstWhere(
      (s) => s.name == account.connectionStatus,
      orElse: () => BankConnectionStatus.unknown,
    );

    return Dismissible(
      key: Key(account.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AuraColors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: AuraColors.red),
      ),
      confirmDismiss: (_) => _confirmDisconnect(account),
      onDismissed: (_) => _disconnectAccount(account.id),
      child: GlassCard(
        borderRadius: 16,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Logo
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    image: account.logoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(account.logoUrl!),
                            fit: BoxFit.contain,
                          )
                        : null,
                  ),
                  child: account.logoUrl == null
                      ? const Icon(Icons.account_balance, color: Colors.white54, size: 24)
                      : null,
                ),
                const SizedBox(width: 12),
                
                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.institutionName,
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        account.accountName,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AuraColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white54),
                  color: AuraColors.background,
                  onSelected: (value) {
                    switch (value) {
                      case 'sync':
                        _syncAccount(account.id);
                        break;
                      case 'default':
                        _setDefault(account.id);
                        break;
                      case 'disconnect':
                        _disconnectAccount(account.id);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'sync',
                      child: Row(
                        children: [
                          const Icon(Icons.sync, size: 20),
                          const SizedBox(width: 8),
                          Text('Synchroniser', style: GoogleFonts.dmSans()),
                        ],
                      ),
                    ),
                    if (!account.isDefault)
                      PopupMenuItem(
                        value: 'default',
                        child: Row(
                          children: [
                            const Icon(Icons.star_border, size: 20),
                            const SizedBox(width: 8),
                            Text('Définir par défaut', style: GoogleFonts.dmSans()),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'disconnect',
                      child: Row(
                        children: [
                          const Icon(Icons.link_off, size: 20, color: AuraColors.red),
                          const SizedBox(width: 8),
                          Text(
                            'Déconnecter',
                            style: GoogleFonts.dmSans(color: AuraColors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const Divider(height: 24, color: Colors.white10),
            
            // Détails
            Row(
              children: [
                // Statut
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == BankConnectionStatus.connected
                        ? AuraColors.green.withOpacity(0.15)
                        : AuraColors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(status.icon, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        status.displayName,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: status == BankConnectionStatus.connected
                              ? AuraColors.green
                              : AuraColors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Solde
                if (account.currentBalance != null)
                  Text(
                    '${account.currentBalance!.toStringAsFixed(0)} ${account.currency}',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
            
            // Dernière sync
            if (account.lastSyncAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: AuraColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Dernière sync: ${_formatTimeAgo(account.lastSyncAt!)}',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AuraColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDisconnect(ConnectedBankAccount account) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AuraColors.background,
        title: Text(
          'Déconnecter ${account.institutionName} ?',
          style: GoogleFonts.dmSans(color: Colors.white),
        ),
        content: Text(
          'Les transactions déjà importées seront conservées dans Aura.',
          style: GoogleFonts.dmSans(color: AuraColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: GoogleFonts.dmSans()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AuraColors.red),
            child: Text('Déconnecter', style: GoogleFonts.dmSans()),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  Future<void> _syncAccount(String accountId) async {
    HapticService.mediumTap();
    
    final result = await BankingService.instance.syncTransactions(
      accountId: accountId,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? '${result.transactionsImported} transactions importées'
                : 'Erreur: ${result.errorMessage}',
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: result.success ? AuraColors.green : AuraColors.red,
        ),
      );
    }
    
    await _loadAccounts();
  }

  Future<void> _setDefault(String accountId) async {
    HapticService.lightTap();
    await BankingService.instance.setDefaultAccount(accountId);
    await _loadAccounts();
  }

  Future<void> _disconnectAccount(String accountId) async {
    HapticService.error();
    await BankingService.instance.disconnectAccount(accountId);
    await _loadAccounts();
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inHours < 1) return '${diff.inMinutes} min';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }
}
