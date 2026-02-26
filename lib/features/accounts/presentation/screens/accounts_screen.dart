import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/aura_button.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/account_model.dart';

/// Écran de gestion des comptes bancaires
class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  @override
  Widget build(BuildContext context) {
    // TODO: Remplacer par un vrai provider
    final accounts = _getMockAccounts();
    final totalBalance = accounts.fold<double>(
      0,
      (sum, a) => sum + a.balance,
    );

    return Scaffold(
      backgroundColor: AuraColors.auraBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Solde total
            _buildTotalBalance(totalBalance),

            const SizedBox(height: AuraDimensions.spaceL),

            // Liste des comptes
            Expanded(
              child: _buildAccountsList(accounts),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AuraDimensions.spaceM),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.goBack(),
            icon: const Icon(Icons.arrow_back_ios, color: AuraColors.auraTextDark),
          ),
          Expanded(
            child: Text(
              'Mes comptes',
              style: AuraTypography.h3.copyWith(color: AuraColors.auraTextDark),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTotalBalance(double total) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    );

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceM),
      padding: const EdgeInsets.all(AuraDimensions.spaceXL),
      child: Column(
        children: [
          Text(
            'Solde total',
            style: AuraTypography.labelMedium.copyWith(
              color: AuraColors.auraTextDarkSecondary,
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceS),
          Text(
            currencyFormat.format(total),
            style: AuraTypography.hero.copyWith(
              color: total >= 0 ? AuraColors.auraGreen : AuraColors.auraRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsList(List<Account> accounts) {
    if (accounts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceM),
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AuraDimensions.spaceM),
          child: AccountCard(
            account: account,
            onTap: () => _showAccountDetail(account),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AuraColors.auraGlass,
              borderRadius: BorderRadius.circular(AuraDimensions.radiusXXL),
            ),
            child: Icon(
              Icons.account_balance_outlined,
              size: 48,
              color: AuraColors.auraAmber.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceL),
          Text(
            'Aucun compte',
            style: AuraTypography.h4.copyWith(color: AuraColors.auraTextDark),
          ),
          const SizedBox(height: AuraDimensions.spaceS),
          Text(
            'Ajoutez votre premier compte bancaire',
            style: AuraTypography.bodyMedium.copyWith(
              color: AuraColors.auraTextDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        HapticService.mediumTap();
        _showAddAccountDialog();
      },
      backgroundColor: AuraColors.auraAmber,
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(
        'Ajouter',
        style: AuraTypography.labelMedium.copyWith(color: Colors.white),
      ),
    );
  }

  void _showAccountDetail(Account account) {
    HapticService.mediumTap();
    // TODO: Modal de détail
  }

  void _showAddAccountDialog() {
    HapticService.lightTap();
    // TODO: Modal d'ajout
  }

  List<Account> _getMockAccounts() {
    return [
      Account(
        id: '1',
        userId: 'user1',
        name: 'Compte Courant BNP',
        type: AccountType.checking,
        balance: 2450.50,
        color: '#E8A86C',
        institution: 'BNP Paribas',
        isPrimary: true,
        accountNumberMasked: '**** 1234',
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
      ),
      Account(
        id: '2',
        userId: 'user1',
        name: 'Livret A',
        type: AccountType.savings,
        balance: 8500.00,
        color: '#58D68D',
        institution: 'BNP Paribas',
        accountNumberMasked: '**** 5678',
        createdAt: DateTime.now().subtract(const Duration(days: 300)),
      ),
      Account(
        id: '3',
        userId: 'user1',
        name: 'Carte Gold',
        type: AccountType.credit,
        balance: -450.20,
        color: '#9B59B6',
        institution: 'Amex',
        accountNumberMasked: '**** 9012',
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
      ),
    ];
  }
}

/// Carte de compte
class AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback? onTap;

  const AccountCard({
    super.key,
    required this.account,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    );

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AuraDimensions.spaceM),
      child: Row(
        children: [
          // Icône
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Color(account.colorValue).withOpacity(0.15),
              borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
            ),
            child: Center(
              child: Text(
                account.type.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),

          const SizedBox(width: AuraDimensions.spaceM),

          // Informations
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        account.name,
                        style: AuraTypography.labelLarge.copyWith(
                          color: AuraColors.auraTextDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (account.isPrimary)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AuraColors.auraAmber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Principal',
                          style: AuraTypography.caption.copyWith(
                            color: AuraColors.auraAmber,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  account.institution ?? account.type.label,
                  style: AuraTypography.bodySmall.copyWith(
                    color: AuraColors.auraTextDarkSecondary,
                  ),
                ),
                if (account.accountNumberMasked != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    account.accountNumberMasked!,
                    style: AuraTypography.caption.copyWith(
                      color: AuraColors.auraTextDarkSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Solde
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(account.balance),
                style: AuraTypography.amountSmall.copyWith(
                  color: account.isOverdrawn
                      ? AuraColors.auraRed
                      : AuraColors.auraTextDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
