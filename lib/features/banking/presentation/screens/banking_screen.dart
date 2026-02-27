import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/animations/staggered_animator.dart';
import '../../../../core/extensions/app_localizations_extension.dart';
import '../../domain/banking_models.dart';
import '../../services/banking_service.dart';

/// Écran principal de synchronisation bancaire
class BankingScreen extends ConsumerStatefulWidget {
  const BankingScreen({super.key});

  @override
  ConsumerState<BankingScreen> createState() => _BankingScreenState();
}

class _BankingScreenState extends ConsumerState<BankingScreen> {
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
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _buildHeader(context),
          ),
          
          // Contenu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section comptes connectés
                  if (_accounts.isNotEmpty) ...[
                    _buildConnectedAccountsSection(),
                    const SizedBox(height: 32),
                  ],
                  
                  // Section ajouter une banque
                  _buildAddBankSection(),
                  
                  const SizedBox(height: 32),
                  
                  // Section infos sécurité
                  _buildSecurityInfo(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AuraColors.amber.withOpacity(0.3),
            AuraColors.background,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              ),
              const Spacer(),
              if (_accounts.isNotEmpty)
                StreamBuilder<SyncStatus>(
                  stream: BankingService.instance.syncStream,
                  builder: (context, snapshot) {
                    final status = snapshot.data;
                    if (status?.isSyncing ?? false) {
                      return const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      );
                    }
                    return IconButton(
                      onPressed: _syncAll,
                      icon: const Icon(Icons.sync, color: Colors.white),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '🏦 ${context.l10n.banking}',
            style: GoogleFonts.playfairDisplay(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _accounts.isEmpty
                ? context.l10n.bankSyncDesc
                : '${_accounts.length} ${context.l10n.accountConnected(_accounts.length)}',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              color: AuraColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedAccountsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.connectedAccounts,
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ..._accounts.map((account) => _buildAccountCard(account)),
      ],
    );
  }

  Widget _buildAccountCard(ConnectedBankAccount account) {
    final status = BankConnectionStatus.values.firstWhere(
      (s) => s.name == account.connectionStatus,
      orElse: () => BankConnectionStatus.unknown,
    );

    return GestureDetector(
      onTap: () => _showAccountOptions(account),
      child: GlassCard(
        borderRadius: 20,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Logo banque
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                image: account.logoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(account.logoUrl!),
                        fit: BoxFit.contain,
                      )
                    : null,
              ),
              child: account.logoUrl == null
                  ? const Icon(Icons.account_balance, color: Colors.white54)
                  : null,
            ),
            const SizedBox(width: 16),
            
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.institutionName,
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    account.accountName,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: AuraColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        status.icon,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status.displayName,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: status == BankConnectionStatus.connected
                              ? AuraColors.green
                              : AuraColors.textSecondary,
                        ),
                      ),
                      if (account.lastSyncAt != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          '• Sync ${_formatTimeAgo(account.lastSyncAt!)}',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AuraColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Solde
            if (account.currentBalance != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${account.currentBalance!.toStringAsFixed(0)} ${account.currency}',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Icon(
                    Icons.more_vert,
                    color: Colors.white38,
                    size: 20,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddBankSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.addBank,
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => context.push('/banking/connect'),
          child: GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AuraColors.amber,
                        AuraColors.deep,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.connectBank,
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.secureSync,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: AuraColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AuraColors.amber,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Banques populaires
        Text(
          context.l10n.popularBanks,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: AuraColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: FrenchBanks.banks.take(6).length,
            itemBuilder: (context, index) {
              final bank = FrenchBanks.banks[index];
              return GestureDetector(
                onTap: () => context.push('/banking/connect?bank=${bank['id']}'),
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (bank['logo'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            bank['logo']!,
                            width: 40,
                            height: 40,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.account_balance,
                              color: Colors.white54,
                            ),
                          ),
                        )
                      else
                        const Icon(
                          Icons.account_balance,
                          color: Colors.white54,
                          size: 32,
                        ),
                      const SizedBox(height: 8),
                      Text(
                        bank['name']!.split(' ').first,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: AuraColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityInfo() {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: AuraColors.green, size: 24),
              const SizedBox(width: 12),
              Text(
                context.l10n.maxSecurity,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.securityFeatures,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AuraColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  void _showAccountOptions(ConnectedBankAccount account) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AuraColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              account.institutionName,
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            _buildOptionTile(
              icon: Icons.sync,
              title: 'Synchroniser maintenant',
              onTap: () {
                Navigator.pop(context);
                _syncAccount(account.id);
              },
            ),
            _buildOptionTile(
              icon: account.isDefault ? Icons.star : Icons.star_border,
              title: account.isDefault ? 'Compte par défaut' : 'Définir par défaut',
              onTap: () {
                Navigator.pop(context);
                _setDefaultAccount(account.id);
              },
            ),
            _buildOptionTile(
              icon: Icons.delete_outline,
              title: 'Déconnecter',
              color: AuraColors.red,
              onTap: () {
                Navigator.pop(context);
                _disconnectAccount(account.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white),
      title: Text(
        title,
        style: GoogleFonts.dmSans(
          color: color ?? Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Future<void> _syncAll() async {
    HapticService.mediumTap();
    final result = await BankingService.instance.syncTransactions();
    
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
  }

  Future<void> _syncAccount(String accountId) async {
    HapticService.mediumTap();
    await BankingService.instance.syncTransactions(accountId: accountId);
  }

  Future<void> _setDefaultAccount(String accountId) async {
    HapticService.lightTap();
    await BankingService.instance.setDefaultAccount(accountId);
    await _loadAccounts();
  }

  Future<void> _disconnectAccount(String accountId) async {
    HapticService.error();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AuraColors.background,
        title: Text(
          'Déconnecter ?',
          style: GoogleFonts.dmSans(color: Colors.white),
        ),
        content: Text(
          'Les transactions déjà importées seront conservées.',
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

    if (confirmed == true) {
      await BankingService.instance.disconnectAccount(accountId);
      await _loadAccounts();
    }
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inHours < 1) return 'il y a ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }
}
