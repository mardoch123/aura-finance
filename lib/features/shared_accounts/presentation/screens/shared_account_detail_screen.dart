import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../data/models/shared_account_model.dart';
import '../providers/shared_accounts_provider.dart';
import '../widgets/shared_account_card.dart';

/// Écran détail d'un compte partagé
class SharedAccountDetailScreen extends ConsumerStatefulWidget {
  static const routeName = '/shared-accounts/:id';
  final String accountId;

  const SharedAccountDetailScreen({
    super.key,
    required this.accountId,
  });

  @override
  ConsumerState<SharedAccountDetailScreen> createState() => _SharedAccountDetailScreenState();
}

class _SharedAccountDetailScreenState extends ConsumerState<SharedAccountDetailScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final accountAsync = ref.watch(sharedAccountDetailProvider(widget.accountId));
    final membersAsync = ref.watch(sharedAccountMembersProvider(widget.accountId));

    return ProviderScope(
      overrides: [
        sharedAccountIdProvider.overrideWithValue(widget.accountId),
      ],
      child: Scaffold(
        backgroundColor: AuraColors.auraBackground,
        body: SafeArea(
          child: accountAsync.when(
            data: (account) {
              if (account == null) {
                return _buildNotFound();
              }
              return _buildContent(account, membersAsync);
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AuraColors.auraAmber),
            ),
            error: (error, _) => _buildError(error.toString()),
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildContent(SharedAccount account, AsyncValue<List<SharedAccountMember>> membersAsync) {
    return CustomScrollView(
      slivers: [
        // Header avec info compte
        SliverToBoxAdapter(
          child: _buildHeader(account),
        ),

        // Stats rapides
        SliverToBoxAdapter(
          child: _buildStats(account),
        ),

        // Contenu selon l'onglet
        if (_selectedTab == 0) ...[
          // Onglet Transactions
          SliverToBoxAdapter(
            child: _buildTransactionsSection(),
          ),
        ] else if (_selectedTab == 1) ...[
          // Onglet Membres
          membersAsync.when(
            data: (members) => _buildMembersSection(members, account),
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SliverToBoxAdapter(
              child: Center(child: Text('Erreur de chargement')),
            ),
          ),
        ] else ...[
          // Onglet Paramètres
          SliverToBoxAdapter(
            child: _buildSettingsSection(account),
          ),
        ],

        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }

  Widget _buildHeader(SharedAccount account) {
    return Padding(
      padding: const EdgeInsets.all(AuraDimensions.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(AuraDimensions.spaceS),
                  decoration: BoxDecoration(
                    color: AuraColors.auraGlass,
                    borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: AuraColors.auraTextDark,
                    size: 20,
                  ),
                ),
              ),
              const Spacer(),
              // Menu options
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(AuraDimensions.spaceS),
                  decoration: BoxDecoration(
                    color: AuraColors.auraGlass,
                    borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
                  ),
                  child: const Icon(
                    Icons.more_vert,
                    color: AuraColors.auraTextDark,
                    size: 20,
                  ),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'invite':
                      _showInviteMember();
                      break;
                    case 'settings':
                      _showAccountSettings();
                      break;
                    case 'leave':
                      _showLeaveConfirmation();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'invite',
                    child: Row(
                      children: [
                        Icon(Icons.person_add_outlined),
                        SizedBox(width: 8),
                        Text('Inviter un membre'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings_outlined),
                        SizedBox(width: 8),
                        Text('Paramètres'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'leave',
                    child: Row(
                      children: [
                        Icon(Icons.exit_to_app, color: AuraColors.auraRed),
                        SizedBox(width: 8),
                        Text('Quitter le groupe', style: TextStyle(color: AuraColors.auraRed)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AuraDimensions.spaceL),
          
          // Info compte
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(int.parse(account.color.replaceFirst('#', '0xFF'))),
                      Color(int.parse(account.color.replaceFirst('#', '0xFF'))).withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
                ),
                child: Icon(
                  _getIconData(account.icon),
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(width: AuraDimensions.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: AuraTypography.h2.copyWith(
                        color: AuraColors.auraTextDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildModeChip(account.sharingMode),
                    if (account.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        account.description!,
                        style: AuraTypography.bodyMedium.copyWith(
                          color: AuraColors.auraTextDarkSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(SharingMode mode) {
    final (label, color) = switch (mode) {
      SharingMode.couple => ('Couple', AuraColors.auraAccentGold),
      SharingMode.family => ('Famille', AuraColors.auraGreen),
      SharingMode.roommates => ('Coloc', AuraColors.auraAmber),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
      ),
      child: Text(
        label,
        style: AuraTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStats(SharedAccount account) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceL),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'Solde',
              value: '${account.totalBalance >= 0 ? '+' : ''}${account.totalBalance.toStringAsFixed(0)}€',
              color: account.totalBalance >= 0 ? AuraColors.auraGreen : AuraColors.auraRed,
              icon: Icons.account_balance_wallet_outlined,
            ),
          ),
          const SizedBox(width: AuraDimensions.spaceM),
          Expanded(
            child: _buildStatCard(
              title: 'Dépenses',
              value: '${account.totalExpensesThisMonth.toStringAsFixed(0)}€',
              color: AuraColors.auraAmber,
              icon: Icons.trending_down_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return GlassCard(
      borderRadius: AuraDimensions.radiusL,
      padding: const EdgeInsets.all(AuraDimensions.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(
                title,
                style: AuraTypography.labelSmall.copyWith(
                  color: AuraColors.auraTextDarkSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AuraDimensions.spaceS),
          Text(
            value,
            style: AuraTypography.h3.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection() {
    return Padding(
      padding: const EdgeInsets.all(AuraDimensions.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transactions récentes',
                style: AuraTypography.h4.copyWith(
                  color: AuraColors.auraTextDark,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Voir toutes les transactions
                },
                child: Text(
                  'Voir tout',
                  style: AuraTypography.labelMedium.copyWith(
                    color: AuraColors.auraDeep,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AuraDimensions.spaceL),
          
          // Bouton ajouter transaction
          GestureDetector(
            onTap: () => _showAddTransaction(),
            child: GlassCard(
              borderRadius: AuraDimensions.radiusL,
              padding: const EdgeInsets.symmetric(
                horizontal: AuraDimensions.spaceL,
                vertical: AuraDimensions.spaceM,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AuraColors.auraAmber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: AuraColors.auraAmber,
                    ),
                  ),
                  const SizedBox(width: AuraDimensions.spaceM),
                  Expanded(
                    child: Text(
                      'Ajouter une dépense',
                      style: AuraTypography.labelLarge.copyWith(
                        color: AuraColors.auraTextDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AuraColors.auraTextDarkSecondary,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AuraDimensions.spaceXL),
          
          // TODO: Liste des transactions
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: AuraColors.auraTextDarkSecondary.withOpacity(0.3),
                ),
                const SizedBox(height: AuraDimensions.spaceM),
                Text(
                  'Aucune transaction',
                  style: AuraTypography.bodyLarge.copyWith(
                    color: AuraColors.auraTextDarkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection(List<SharedAccountMember> members, SharedAccount account) {
    return SliverPadding(
      padding: const EdgeInsets.all(AuraDimensions.spaceL),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Membres (${members.length})',
                style: AuraTypography.h4.copyWith(
                  color: AuraColors.auraTextDark,
                ),
              ),
              if (account.isAdmin('current_user_id')) // TODO: Get current user id
                ElevatedButton.icon(
                  onPressed: () => _showInviteMember(),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Inviter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuraColors.auraAmber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AuraDimensions.spaceL),
          ...members.map((member) => _buildMemberTile(member, account)),
        ]),
      ),
    );
  }

  Widget _buildMemberTile(SharedAccountMember member, SharedAccount account) {
    final isOwner = member.role == SharedMemberRole.owner;
    final isCurrentUser = member.userId == 'current_user_id'; // TODO: Get current user

    return GlassCard(
      borderRadius: AuraDimensions.radiusL,
      margin: const EdgeInsets.only(bottom: AuraDimensions.spaceM),
      padding: const EdgeInsets.all(AuraDimensions.spaceM),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AuraColors.auraAmber,
              image: member.avatarUrl != null
                  ? DecorationImage(
                      image: NetworkImage(member.avatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: member.avatarUrl == null
                ? Center(
                    child: Text(
                      member.effectiveDisplayName.substring(0, 1).toUpperCase(),
                      style: AuraTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AuraDimensions.spaceM),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.effectiveDisplayName,
                      style: AuraTypography.labelLarge.copyWith(
                        color: AuraColors.auraTextDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AuraColors.auraAmber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Vous',
                          style: AuraTypography.labelSmall.copyWith(
                            color: AuraColors.auraAmber,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _getRoleLabel(member.role),
                  style: AuraTypography.bodySmall.copyWith(
                    color: AuraColors.auraTextDarkSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Actions
          if (isOwner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AuraColors.auraAccentGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AuraDimensions.radiusXS),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    size: 14,
                    color: AuraColors.auraAccentGold,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Créateur',
                    style: AuraTypography.labelSmall.copyWith(
                      color: AuraColors.auraAccentGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else if (account.isAdmin('current_user_id'))
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'remove') {
                  _showRemoveMemberConfirmation(member);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.remove_circle, color: AuraColors.auraRed, size: 20),
                      SizedBox(width: 8),
                      Text('Retirer', style: TextStyle(color: AuraColors.auraRed)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(SharedAccount account) {
    return Padding(
      padding: const EdgeInsets.all(AuraDimensions.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paramètres',
            style: AuraTypography.h4.copyWith(
              color: AuraColors.auraTextDark,
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceL),
          
          // Notifications
          _buildSettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Configurer les alertes',
            onTap: () {},
          ),
          
          // Permissions
          _buildSettingsTile(
            icon: Icons.security_outlined,
            title: 'Permissions',
            subtitle: 'Gérer les accès des membres',
            onTap: () {},
          ),
          
          // Export
          _buildSettingsTile(
            icon: Icons.download_outlined,
            title: 'Exporter les données',
            subtitle: 'Télécharger un rapport',
            onTap: () {},
          ),
          
          const SizedBox(height: AuraDimensions.spaceXL),
          
          // Zone danger
          Text(
            'Zone de danger',
            style: AuraTypography.labelLarge.copyWith(
              color: AuraColors.auraRed,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceM),
          
          _buildDangerTile(
            icon: Icons.exit_to_app,
            title: 'Quitter le groupe',
            subtitle: 'Vous ne pourrez plus accéder à ce compte',
            onTap: () => _showLeaveConfirmation(),
          ),
          
          if (account.isAdmin('current_user_id'))
            _buildDangerTile(
              icon: Icons.delete_forever,
              title: 'Supprimer le compte',
              subtitle: 'Action irréversible',
              onTap: () => _showDeleteConfirmation(),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AuraDimensions.spaceM),
        padding: const EdgeInsets.all(AuraDimensions.spaceM),
        decoration: BoxDecoration(
          color: AuraColors.auraGlass,
          borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AuraColors.auraAmber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
              ),
              child: Icon(icon, color: AuraColors.auraAmber),
            ),
            const SizedBox(width: AuraDimensions.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AuraTypography.labelLarge.copyWith(
                      color: AuraColors.auraTextDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AuraTypography.bodySmall.copyWith(
                      color: AuraColors.auraTextDarkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AuraColors.auraTextDarkSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AuraDimensions.spaceM),
        padding: const EdgeInsets.all(AuraDimensions.spaceM),
        decoration: BoxDecoration(
          color: AuraColors.auraRed.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
          border: Border.all(color: AuraColors.auraRed.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AuraColors.auraRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
              ),
              child: Icon(icon, color: AuraColors.auraRed),
            ),
            const SizedBox(width: AuraDimensions.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AuraTypography.labelLarge.copyWith(
                      color: AuraColors.auraRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AuraTypography.bodySmall.copyWith(
                      color: AuraColors.auraRed.withOpacity(0.7),
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

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AuraColors.auraGlassStrong,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AuraDimensions.radiusXXL),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AuraDimensions.spaceL,
            vertical: AuraDimensions.spaceM,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.receipt_long_outlined, 'Transactions'),
              _buildNavItem(1, Icons.people_outline, 'Membres'),
              _buildNavItem(2, Icons.settings_outlined, 'Paramètres'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        setState(() => _selectedTab = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AuraDimensions.spaceM,
          vertical: AuraDimensions.spaceS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AuraColors.auraAmber.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AuraColors.auraAmber : AuraColors.auraTextDarkSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AuraTypography.labelSmall.copyWith(
                color: isSelected ? AuraColors.auraAmber : AuraColors.auraTextDarkSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AuraColors.auraTextDarkSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: AuraDimensions.spaceL),
          Text(
            'Compte non trouvé',
            style: AuraTypography.h3.copyWith(
              color: AuraColors.auraTextDark,
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceM),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AuraColors.auraRed.withOpacity(0.5),
          ),
          const SizedBox(height: AuraDimensions.spaceL),
          Text(
            'Erreur',
            style: AuraTypography.h3.copyWith(
              color: AuraColors.auraTextDark,
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceM),
          Text(
            error,
            style: AuraTypography.bodyMedium.copyWith(
              color: AuraColors.auraTextDarkSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getRoleLabel(SharedMemberRole role) {
    return switch (role) {
      SharedMemberRole.owner => 'Propriétaire',
      SharedMemberRole.admin => 'Administrateur',
      SharedMemberRole.member => 'Membre',
      SharedMemberRole.child => 'Enfant',
      SharedMemberRole.viewer => 'Lecteur',
    };
  }

  IconData _getIconData(String icon) {
    return switch (icon) {
      'people' => Icons.people_outline,
      'family' => Icons.family_restroom_outlined,
      'home' => Icons.home_outlined,
      'favorite' => Icons.favorite_outline,
      'wallet' => Icons.account_balance_wallet_outlined,
      _ => Icons.people_outline,
    };
  }

  void _showInviteMember() {
    // TODO: Show invite member bottom sheet
  }

  void _showAccountSettings() {
    // TODO: Show account settings
  }

  void _showLeaveConfirmation() {
    // TODO: Show leave confirmation dialog
  }

  void _showDeleteConfirmation() {
    // TODO: Show delete confirmation dialog
  }

  void _showRemoveMemberConfirmation(SharedAccountMember member) {
    // TODO: Show remove member confirmation
  }

  void _showAddTransaction() {
    // TODO: Show add transaction bottom sheet
  }
}
