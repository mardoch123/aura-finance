import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_model.freezed.dart';
part 'account_model.g.dart';

/// Types de comptes bancaires
enum AccountType {
  checking,
  savings,
  credit,
  investment,
}

/// Extension pour les labels des types de compte
extension AccountTypeExtension on AccountType {
  String get label {
    switch (this) {
      case AccountType.checking:
        return 'Compte courant';
      case AccountType.savings:
        return 'Livret d\'épargne';
      case AccountType.credit:
        return 'Carte de crédit';
      case AccountType.investment:
        return 'Compte d\'investissement';
    }
  }

  String get icon {
    switch (this) {
      case AccountType.checking:
        return '💳';
      case AccountType.savings:
        return '🏦';
      case AccountType.credit:
        return '💎';
      case AccountType.investment:
        return '📈';
    }
  }
}

/// Modèle de compte bancaire
@freezed
class Account with _$Account {
  const factory Account({
    required String id,
    required String userId,
    required String name,
    @Default(AccountType.checking) AccountType type,
    @Default(0.0) double balance,
    @Default('#E8A86C') String color,
    String? institution,
    @Default(false) bool isPrimary,
    @Default(true) bool isActive,
    String? accountNumberMasked,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _Account;

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);

  /// Constructeur vide
  factory Account.empty() => Account(
        id: '',
        userId: '',
        name: '',
        createdAt: DateTime.now(),
      );
}

/// Extension pour les propriétés calculées
extension AccountExtension on Account {
  /// Solde formaté
  String get formattedBalance {
    final sign = balance >= 0 ? '' : '-';
    return '$sign${balance.abs().toStringAsFixed(2)}€';
  }

  /// Si le compte est en découvert
  bool get isOverdrawn => balance < 0;

  /// Couleur parsée
  int get colorValue {
    try {
      return int.parse(color.replaceFirst('#', '0xFF'));
    } catch (_) {
      return 0xFFE8A86C;
    }
  }
}

/// Résumé des comptes
class AccountsSummary {
  final double totalBalance;
  final int totalAccounts;
  final Map<AccountType, double> balanceByType;

  const AccountsSummary({
    required this.totalBalance,
    required this.totalAccounts,
    required this.balanceByType,
  });

  factory AccountsSummary.empty() => const AccountsSummary(
        totalBalance: 0.0,
        totalAccounts: 0,
        balanceByType: {},
      );
}
