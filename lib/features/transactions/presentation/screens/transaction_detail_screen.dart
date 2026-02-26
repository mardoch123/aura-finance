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
import '../../domain/transaction_model.dart';
import '../providers/transactions_provider.dart';

/// Écran de détail d'une transaction
class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionAsync = ref.watch(transactionProvider(transactionId));

    return Scaffold(
      backgroundColor: AuraColors.auraBackground,
      body: transactionAsync.when(
        data: (transaction) {
          if (transaction == null) {
            return _buildErrorState(context, 'Transaction non trouvée');
          }
          return _buildContent(context, ref, transaction);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AuraColors.auraAmber),
        ),
        error: (error, _) => _buildErrorState(context, error.toString()),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Transaction transaction) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('EEEE dd MMMM yyyy', 'fr_FR');

    return SafeArea(
      child: Column(
        children: [
          // Header
          _buildHeader(context, ref, transaction),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AuraDimensions.spaceM),
              child: Column(
                children: [
                  // Montant principal
                  GlassCard(
                    padding: const EdgeInsets.all(AuraDimensions.spaceXL),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _parseColor(transaction.categoryColor).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AuraDimensions.radiusXL),
                          ),
                          child: Center(
                            child: Text(
                              transaction.categoryIcon,
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                        const SizedBox(height: AuraDimensions.spaceL),
                        Text(
                          currencyFormat.format(transaction.amount),
                          style: AuraTypography.hero.copyWith(
                            color: transaction.isExpense
                                ? AuraColors.auraRed
                                : AuraColors.auraGreen,
                          ),
                        ),
                        const SizedBox(height: AuraDimensions.spaceS),
                        Text(
                          transaction.merchant ?? transaction.category,
                          style: AuraTypography.h3.copyWith(
                            color: AuraColors.auraTextDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AuraDimensions.spaceL),

                  // Détails
                  GlassCard(
                    child: Column(
                      children: [
                        _buildDetailRow(
                          icon: Icons.category,
                          label: 'Catégorie',
                          value: _capitalize(transaction.category),
                        ),
                        const Divider(height: 1),
                        _buildDetailRow(
                          icon: Icons.calendar_today,
                          label: 'Date',
                          value: _capitalize(dateFormat.format(transaction.date)),
                        ),
                        if (transaction.subcategory != null) ...[
                          const Divider(height: 1),
                          _buildDetailRow(
                            icon: Icons.label,
                            label: 'Sous-catégorie',
                            value: transaction.subcategory!,
                          ),
                        ],
                        if (transaction.description != null && transaction.description!.isNotEmpty) ...[
                          const Divider(height: 1),
                          _buildDetailRow(
                            icon: Icons.description,
                            label: 'Description',
                            value: transaction.description!,
                          ),
                        ],
                        if (transaction.isRecurring) ...[
                          const Divider(height: 1),
                          _buildDetailRow(
                            icon: Icons.repeat,
                            label: 'Type',
                            value: 'Transaction récurrente',
                            valueColor: AuraColors.auraAmber,
                          ),
                        ],
                        if (transaction.aiConfidence != null) ...[
                          const Divider(height: 1),
                          _buildDetailRow(
                            icon: Icons.auto_awesome,
                            label: 'Confiance IA',
                            value: '${(transaction.aiConfidence! * 100).toInt()}%',
                            valueColor: AuraColors.auraAmber,
                          ),
                        ],
                        if (transaction.source != 'manual') ...[
                          const Divider(height: 1),
                          _buildDetailRow(
                            icon: _getSourceIcon(transaction.source),
                            label: 'Source',
                            value: _getSourceLabel(transaction.source),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: AuraDimensions.spaceXL),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: AuraButton(
                          label: 'Modifier',
                          onPressed: () {
                            HapticService.lightTap();
                            // TODO: Navigation vers écran d'édition
                          },
                          type: AuraButtonType.secondary,
                        ),
                      ),
                      const SizedBox(width: AuraDimensions.spaceM),
                      Expanded(
                        child: AuraButton(
                          label: 'Supprimer',
                          onPressed: () => _confirmDelete(context, ref, transaction),
                          type: AuraButtonType.danger,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AuraDimensions.spaceL),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, Transaction transaction) {
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
              'Détail',
              style: AuraTypography.h3.copyWith(color: AuraColors.auraTextDark),
              textAlign: TextAlign.center,
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AuraColors.auraTextDark),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  HapticService.lightTap();
                  // TODO: Navigation vers écran d'édition
                  break;
                case 'duplicate':
                  HapticService.lightTap();
                  _duplicateTransaction(context, ref, transaction);
                  break;
                case 'share':
                  HapticService.lightTap();
                  // TODO: Partager la transaction
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Modifier'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.copy),
                    SizedBox(width: 8),
                    Text('Dupliquer'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Partager'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AuraDimensions.spaceM),
      child: Row(
        children: [
          Icon(icon, color: AuraColors.auraTextDarkSecondary, size: 20),
          const SizedBox(width: AuraDimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AuraTypography.bodySmall.copyWith(
                    color: AuraColors.auraTextDarkSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AuraTypography.bodyLarge.copyWith(
                    color: valueColor ?? AuraColors.auraTextDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
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
            'Erreur',
            style: AuraTypography.h3.copyWith(color: AuraColors.auraTextDark),
          ),
          const SizedBox(height: AuraDimensions.spaceS),
          Text(
            message,
            style: AuraTypography.bodyMedium.copyWith(
              color: AuraColors.auraTextDarkSecondary,
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceL),
          ElevatedButton(
            onPressed: () => context.goBack(),
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Transaction transaction) {
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
            onPressed: () async {
              Navigator.pop(context);
              HapticService.success();
              final repository = ref.read(transactionsRepositoryProvider);
              await repository.deleteTransaction(transaction.id);
              if (context.mounted) {
                context.goBack();
              }
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

  Future<void> _duplicateTransaction(
    BuildContext context,
    WidgetRef ref,
    Transaction transaction,
  ) async {
    try {
      final repository = ref.read(transactionsRepositoryProvider);
      await repository.createTransaction(
        amount: transaction.amount,
        category: transaction.category,
        date: DateTime.now(),
        subcategory: transaction.subcategory,
        merchant: transaction.merchant,
        description: '${transaction.description ?? ''} (copie)',
        isRecurring: transaction.isRecurring,
      );
      HapticService.success();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction dupliquée'),
            backgroundColor: AuraColors.auraGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
            ),
          ),
        );
      }
    } catch (e) {
      HapticService.error();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AuraColors.auraRed,
          ),
        );
      }
    }
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AuraColors.auraAmber;
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  IconData _getSourceIcon(String source) {
    switch (source) {
      case 'scan':
        return Icons.camera_alt;
      case 'voice':
        return Icons.mic;
      case 'import':
        return Icons.upload_file;
      default:
        return Icons.edit;
    }
  }

  String _getSourceLabel(String source) {
    switch (source) {
      case 'scan':
        return 'Scan IA';
      case 'voice':
        return 'Reconnaissance vocale';
      case 'import':
        return 'Import';
      default:
        return 'Manuel';
    }
  }
}
