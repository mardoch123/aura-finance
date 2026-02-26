import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/transactions_repository.dart';
import '../../domain/transaction_model.dart';

part 'transactions_provider.g.dart';

// ═══════════════════════════════════════════════════════════
// REPOSITORY PROVIDER
// ═══════════════════════════════════════════════════════════

@riverpod
TransactionsRepository transactionsRepository(Ref ref) {
  return TransactionsRepository();
}

// ═══════════════════════════════════════════════════════════
// STATE CLASSES
// ═══════════════════════════════════════════════════════════

/// État de la liste des transactions
class TransactionsState {
  final List<Transaction> transactions;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final TransactionFilter filter;
  final TransactionPeriod period;

  const TransactionsState({
    this.transactions = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.filter = TransactionFilter.all,
    this.period = TransactionPeriod.month,
  });

  TransactionsState copyWith({
    List<Transaction>? transactions,
    bool? isLoading,
    String? error,
    bool? hasMore,
    TransactionFilter? filter,
    TransactionPeriod? period,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      filter: filter ?? this.filter,
      period: period ?? this.period,
    );
  }
}

/// État du formulaire de transaction
class TransactionFormState {
  final double? amount;
  final String? category;
  final String? subcategory;
  final String? merchant;
  final String? description;
  final DateTime? date;
  final String? accountId;
  final bool isRecurring;
  final bool isSubmitting;
  final String? error;
  final bool isSuccess;

  const TransactionFormState({
    this.amount,
    this.category,
    this.subcategory,
    this.merchant,
    this.description,
    this.date,
    this.accountId,
    this.isRecurring = false,
    this.isSubmitting = false,
    this.error,
    this.isSuccess = false,
  });

  TransactionFormState copyWith({
    double? amount,
    String? category,
    String? subcategory,
    String? merchant,
    String? description,
    DateTime? date,
    String? accountId,
    bool? isRecurring,
    bool? isSubmitting,
    String? error,
    bool? isSuccess,
  }) {
    return TransactionFormState(
      amount: amount ?? this.amount,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      merchant: merchant ?? this.merchant,
      description: description ?? this.description,
      date: date ?? this.date,
      accountId: accountId ?? this.accountId,
      isRecurring: isRecurring ?? this.isRecurring,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  bool get isValid => amount != null && amount != 0 && category != null && date != null;
}

// ═══════════════════════════════════════════════════════════
// NOTIFIER CLASSES
// ═══════════════════════════════════════════════════════════

/// Notifier pour la liste des transactions
@riverpod
class TransactionsNotifier extends _$TransactionsNotifier {
  static const int _pageSize = 20;

  @override
  TransactionsState build() {
    return const TransactionsState();
  }

  /// Charge les transactions initiales
  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(transactionsRepositoryProvider);
      final transactions = await repository.getTransactions(
        limit: _pageSize,
        filter: state.filter,
        period: state.period,
      );

      state = state.copyWith(
        transactions: transactions,
        isLoading: false,
        hasMore: transactions.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement: $e',
      );
    }
  }

  /// Charge plus de transactions (pagination)
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final repository = ref.read(transactionsRepositoryProvider);
      final newTransactions = await repository.getTransactions(
        limit: _pageSize,
        offset: state.transactions.length,
        filter: state.filter,
        period: state.period,
      );

      state = state.copyWith(
        transactions: [...state.transactions, ...newTransactions],
        isLoading: false,
        hasMore: newTransactions.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement: $e',
      );
    }
  }

  /// Change le filtre et recharge
  Future<void> setFilter(TransactionFilter filter) async {
    if (state.filter == filter) return;
    state = state.copyWith(filter: filter, transactions: []);
    await loadTransactions();
  }

  /// Change la période et recharge
  Future<void> setPeriod(TransactionPeriod period) async {
    if (state.period == period) return;
    state = state.copyWith(period: period, transactions: []);
    await loadTransactions();
  }

  /// Supprime une transaction
  Future<void> deleteTransaction(String id) async {
    try {
      final repository = ref.read(transactionsRepositoryProvider);
      await repository.deleteTransaction(id);

      state = state.copyWith(
        transactions: state.transactions.where((t) => t.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de la suppression: $e');
    }
  }

  /// Rafraîchit la liste
  Future<void> refresh() async {
    state = state.copyWith(transactions: [], hasMore: true);
    await loadTransactions();
  }
}

/// Notifier pour le formulaire de transaction
@riverpod
class TransactionFormNotifier extends _$TransactionFormNotifier {
  @override
  TransactionFormState build() {
    return TransactionFormState(date: DateTime.now());
  }

  // Setters
  void setAmount(double amount) => state = state.copyWith(amount: amount);
  void setCategory(String category) => state = state.copyWith(category: category);
  void setSubcategory(String? subcategory) => state = state.copyWith(subcategory: subcategory);
  void setMerchant(String? merchant) => state = state.copyWith(merchant: merchant);
  void setDescription(String? description) => state = state.copyWith(description: description);
  void setDate(DateTime date) => state = state.copyWith(date: date);
  void setAccountId(String? accountId) => state = state.copyWith(accountId: accountId);
  void setIsRecurring(bool value) => state = state.copyWith(isRecurring: value);

  /// Soumet le formulaire pour créer une transaction
  Future<void> submit() async {
    if (!state.isValid) {
      state = state.copyWith(error: 'Veuillez remplir tous les champs obligatoires');
      return;
    }

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final repository = ref.read(transactionsRepositoryProvider);
      await repository.createTransaction(
        amount: state.amount!,
        category: state.category!,
        date: state.date!,
        subcategory: state.subcategory,
        merchant: state.merchant,
        description: state.description,
        accountId: state.accountId,
        isRecurring: state.isRecurring,
      );

      state = state.copyWith(isSubmitting: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Erreur lors de la création: $e',
      );
    }
  }

  /// Met à jour une transaction existante
  Future<void> update(String id) async {
    if (!state.isValid) {
      state = state.copyWith(error: 'Veuillez remplir tous les champs obligatoires');
      return;
    }

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final repository = ref.read(transactionsRepositoryProvider);
      await repository.updateTransaction(
        id,
        amount: state.amount,
        category: state.category,
        date: state.date,
        subcategory: state.subcategory,
        merchant: state.merchant,
        description: state.description,
        accountId: state.accountId,
        isRecurring: state.isRecurring,
      );

      state = state.copyWith(isSubmitting: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Erreur lors de la mise à jour: $e',
      );
    }
  }

  /// Charge une transaction existante dans le formulaire
  Future<void> loadTransaction(String id) async {
    state = state.copyWith(isSubmitting: true);

    try {
      final repository = ref.read(transactionsRepositoryProvider);
      final transaction = await repository.getTransactionById(id);

      if (transaction != null) {
        state = TransactionFormState(
          amount: transaction.amount,
          category: transaction.category,
          subcategory: transaction.subcategory,
          merchant: transaction.merchant,
          description: transaction.description,
          date: transaction.date,
          accountId: transaction.accountId,
          isRecurring: transaction.isRecurring,
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors du chargement: $e');
    }
  }

  void reset() {
    state = TransactionFormState(date: DateTime.now());
  }
}

// ═══════════════════════════════════════════════════════════
// PROVIDERS SIMPLES
// ═══════════════════════════════════════════════════════════

/// Provider pour les statistiques des transactions
@riverpod
Future<TransactionStats> transactionStats(Ref ref, {TransactionPeriod? period}) async {
  final repository = ref.watch(transactionsRepositoryProvider);
  return await repository.getStats(period: period ?? TransactionPeriod.month);
}

/// Provider pour les dépenses par catégorie
@riverpod
Future<List<CategoryExpense>> expensesByCategory(Ref ref, {TransactionPeriod? period}) async {
  final repository = ref.watch(transactionsRepositoryProvider);
  return await repository.getExpensesByCategory(period: period ?? TransactionPeriod.month);
}

/// Provider pour une transaction spécifique
@riverpod
Future<Transaction?> transaction(Ref ref, String id) async {
  final repository = ref.watch(transactionsRepositoryProvider);
  return await repository.getTransactionById(id);
}

/// Provider pour la recherche de transactions
final transactionSearchProvider = StateProvider<String>((ref) => '');

@riverpod
Future<List<Transaction>> transactionSearchResults(Ref ref) async {
  final query = ref.watch(transactionSearchProvider);
  if (query.isEmpty) return [];

  final repository = ref.watch(transactionsRepositoryProvider);
  return await repository.searchTransactions(query);
}
