import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/transaction_model.dart';
import '../providers/transactions_provider.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/transaction_filter_chips.dart';
import '../widgets/transaction_period_selector.dart';

/// Écran de liste des transactions
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Charger les transactions au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionsNotifierProvider.notifier).loadTransactions();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(transactionsNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionsNotifierProvider);

    return Scaffold(
      backgroundColor: AuraColors.auraBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Filtres
            TransactionFilterChips(
              selectedFilter: state.filter,
              onFilterChanged: (filter) {
                HapticService.lightTap();
                ref.read(transactionsNotifierProvider.notifier).setFilter(filter);
              },
            ),

            // Sélecteur de période
            TransactionPeriodSelector(
              selectedPeriod: state.period,
              onPeriodChanged: (period) {
                HapticService.lightTap();
                ref.read(transactionsNotifierProvider.notifier).setPeriod(period);
              },
            ),

            const SizedBox(height: AuraDimensions.spaceM),

            // Liste des transactions
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  HapticService.mediumTap();
                  await ref.read(transactionsNotifierProvider.notifier).refresh();
                },
                color: AuraColors.auraAmber,
                backgroundColor: Colors.white,
                child: _buildTransactionList(state),
              ),
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
              'Transactions',
              style: AuraTypography.h3.copyWith(color: AuraColors.auraTextDark),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: () {
              HapticService.lightTap();
              _showSearchModal();
            },
            icon: const Icon(Icons.search, color: AuraColors.auraTextDark),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(TransactionsState state) {
    if (state.isLoading && state.transactions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AuraColors.auraAmber),
      );
    }

    if (state.error != null && state.transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AuraColors.auraRed.withOpacity(0.5),
            ),
            const SizedBox(height: AuraDimensions.spaceM),
            Text(
              'Erreur de chargement',
              style: AuraTypography.h4.copyWith(color: AuraColors.auraTextDark),
            ),
            const SizedBox(height: AuraDimensions.spaceS),
            Text(
              state.error!,
              style: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.auraTextDarkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuraDimensions.spaceL),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(transactionsNotifierProvider.notifier).loadTransactions();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (state.transactions.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceM),
      itemCount: state.transactions.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.transactions.length) {
          return const Padding(
            padding: EdgeInsets.all(AuraDimensions.spaceM),
            child: Center(
              child: CircularProgressIndicator(color: AuraColors.auraAmber),
            ),
          );
        }

        final transaction = state.transactions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AuraDimensions.spaceS),
          child: TransactionListItem(
            transaction: transaction,
            onTap: () {
              HapticService.lightTap();
              context.goToTransactionDetail(transaction.id);
            },
            onDelete: () => _confirmDelete(transaction),
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
              Icons.receipt_long_outlined,
              size: 48,
              color: AuraColors.auraAmber.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceL),
          Text(
            'Aucune transaction',
            style: AuraTypography.h3.copyWith(color: AuraColors.auraTextDark),
          ),
          const SizedBox(height: AuraDimensions.spaceS),
          Text(
            'Commencez par ajouter votre première transaction',
            style: AuraTypography.bodyMedium.copyWith(
              color: AuraColors.auraTextDarkSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AuraDimensions.spaceXL),
          ElevatedButton.icon(
            onPressed: () => context.goToAddTransaction(),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une transaction'),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        HapticService.mediumTap();
        context.goToAddTransaction();
      },
      backgroundColor: AuraColors.auraAmber,
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(
        'Ajouter',
        style: AuraTypography.labelMedium.copyWith(color: Colors.white),
      ),
    );
  }

  void _confirmDelete(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AuraColors.auraGlassStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AuraDimensions.radiusXL),
        ),
        title: Text(
          'Supprimer la transaction ?',
          style: AuraTypography.h4.copyWith(color: AuraColors.auraTextDark),
        ),
        content: Text(
          'Cette action est irréversible.',
          style: AuraTypography.bodyMedium.copyWith(
            color: AuraColors.auraTextDarkSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: AuraTypography.labelMedium.copyWith(
                color: AuraColors.auraTextDarkSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              HapticService.success();
              ref.read(transactionsNotifierProvider.notifier).deleteTransaction(transaction.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AuraColors.auraRed,
            ),
            child: Text(
              'Supprimer',
              style: AuraTypography.labelMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _SearchBottomSheet(),
    );
  }
}

/// Bottom sheet de recherche
class _SearchBottomSheet extends ConsumerStatefulWidget {
  const _SearchBottomSheet();

  @override
  ConsumerState<_SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends ConsumerState<_SearchBottomSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(transactionSearchResultsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AuraColors.auraBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AuraDimensions.radiusXXL),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: AuraDimensions.spaceS),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AuraColors.auraTextDarkSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.all(AuraDimensions.spaceM),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Rechercher une transaction...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          ref.read(transactionSearchProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(transactionSearchProvider.notifier).state = value;
              },
            ),
          ),

          // Results
          Expanded(
            child: searchResults.when(
              data: (transactions) {
                if (transactions.isEmpty && _controller.text.isNotEmpty) {
                  return Center(
                    child: Text(
                      'Aucun résultat',
                      style: AuraTypography.bodyMedium.copyWith(
                        color: AuraColors.auraTextDarkSecondary,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AuraDimensions.spaceM,
                  ),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) => TransactionListItem(
                    transaction: transactions[index],
                    onTap: () {
                      context.goToTransactionDetail(transactions[index].id);
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AuraColors.auraAmber),
              ),
              error: (_, __) => Center(
                child: Text(
                  'Erreur de recherche',
                  style: AuraTypography.bodyMedium.copyWith(
                    color: AuraColors.auraRed,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
