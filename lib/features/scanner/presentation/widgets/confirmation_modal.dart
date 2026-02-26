import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/animations/staggered_animator.dart';
import '../../domain/transaction_draft.dart';

/// Modal de confirmation post-analyse IA
/// Affiche les détails de la transaction avec animation "cristallisation"
class ConfirmationModal extends StatefulWidget {
  const ConfirmationModal({
    super.key,
    required this.draft,
    required this.onConfirm,
    required this.onEdit,
    required this.onCancel,
  });

  final TransactionDraft draft;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  @override
  State<ConfirmationModal> createState() => _ConfirmationModalState();
}

class _ConfirmationModalState extends State<ConfirmationModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    // Démarrer l'animation au prochain frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
      HapticService.success();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    HapticService.success();
    _controller.reverse().then((_) {
      widget.onConfirm();
    });
  }

  void _handleEdit() {
    HapticService.lightTap();
    _controller.reverse().then((_) {
      widget.onEdit();
    });
  }

  void _handleCancel() {
    HapticService.lightTap();
    _controller.reverse().then((_) {
      widget.onCancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * MediaQuery.of(context).size.height),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () {}, // Empêcher la propagation du tap
        child: GlassBottomSheet(
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AuraColors.auraTextPrimary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AuraDimensions.spaceL),

                // Titre
                Text(
                  'Transaction détectée',
                  style: AuraTypography.h3.copyWith(
                    color: AuraColors.auraTextPrimary,
                  ),
                ),
                const SizedBox(height: AuraDimensions.spaceXL),

                // Contenu avec animation staggered
                StaggeredAnimator(
                  delay: const Duration(milliseconds: 100),
                  children: [
                    // Montant
                    _AmountDisplay(amount: widget.draft.amount),
                    const SizedBox(height: AuraDimensions.spaceL),

                    // Marchand
                    if (widget.draft.merchant != null)
                      _InfoRow(
                        label: 'Marchand',
                        value: widget.draft.merchant!,
                      ),

                    // Catégorie
                    _CategoryChip(category: widget.draft.category),
                    const SizedBox(height: AuraDimensions.spaceM),

                    // Date
                    _InfoRow(
                      label: 'Date',
                      value: _formatDate(widget.draft.date ?? DateTime.now()),
                    ),

                    // Description
                    if (widget.draft.description != null)
                      _InfoRow(
                        label: 'Description',
                        value: widget.draft.description!,
                      ),

                    const SizedBox(height: AuraDimensions.spaceL),

                    // Barre de confiance IA
                    _ConfidenceBar(confidence: widget.draft.confidence),
                  ],
                ),

                const SizedBox(height: AuraDimensions.spaceXL),

                // Boutons d'action
                Row(
                  children: [
                    // Bouton Modifier
                    Expanded(
                      child: GlassCard(
                        borderRadius: AuraDimensions.radiusL,
                        onTap: _handleEdit,
                        child: Center(
                          child: Text(
                            'Modifier',
                            style: AuraTypography.labelLarge.copyWith(
                              color: AuraColors.auraTextPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AuraDimensions.spaceM),

                    // Bouton Confirmer
                    Expanded(
                      child: GestureDetector(
                        onTap: _handleConfirm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: AuraDimensions.spaceM,
                          ),
                          decoration: BoxDecoration(
                            color: AuraColors.auraAmber,
                            borderRadius: BorderRadius.circular(
                              AuraDimensions.radiusL,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Confirmer',
                                style: AuraTypography.labelLarge.copyWith(
                                  color: AuraColors.auraTextPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: AuraDimensions.spaceXS),
                              const Icon(
                                Icons.check,
                                color: AuraColors.auraTextPrimary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AuraDimensions.spaceM),

                // Bouton Annuler
                Center(
                  child: TextButton(
                    onPressed: _handleCancel,
                    child: Text(
                      'Annuler',
                      style: AuraTypography.labelMedium.copyWith(
                        color: AuraColors.auraTextSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// Affichage du montant en grand
class _AmountDisplay extends StatelessWidget {
  const _AmountDisplay({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    final isExpense = amount < 0;
    final displayAmount = amount.abs().toStringAsFixed(2);

    return Center(
      child: Column(
        children: [
          Text(
            '${isExpense ? '-' : '+'}${displayAmount}€',
            style: AuraTypography.hero.copyWith(
              color: isExpense ? AuraColors.auraRed : AuraColors.auraGreen,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceXS),
          Text(
            isExpense ? 'Dépense' : 'Revenu',
            style: AuraTypography.labelMedium.copyWith(
              color: AuraColors.auraTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne d'information label: valeur
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AuraDimensions.spaceM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: AuraTypography.labelMedium.copyWith(
              color: AuraColors.auraTextSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.auraTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip de catégorie coloré
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final color = AuraColors.categoryColors[category] ?? AuraColors.auraAmber;
    final label = _getCategoryLabel(category);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AuraDimensions.spaceM,
        vertical: AuraDimensions.spaceXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
        border: Border.all(
          color: color.withOpacity(0.5),
        ),
      ),
      child: Text(
        label,
        style: AuraTypography.labelMedium.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getCategoryLabel(String category) {
    final labels = {
      'food': 'Alimentation',
      'transport': 'Transport',
      'housing': 'Logement',
      'entertainment': 'Loisirs',
      'shopping': 'Shopping',
      'health': 'Santé',
      'education': 'Éducation',
      'travel': 'Voyage',
      'utilities': 'Factures',
      'subscriptions': 'Abonnements',
      'restaurant': 'Restaurant',
      'other': 'Autre',
    };
    return labels[category] ?? category;
  }
}

/// Barre de confiance IA
class _ConfidenceBar extends StatelessWidget {
  const _ConfidenceBar({required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    final percentage = (confidence * 100).round();
    Color color;
    if (confidence >= 0.8) {
      color = AuraColors.auraGreen;
    } else if (confidence >= 0.5) {
      color = AuraColors.auraOrange;
    } else {
      color = AuraColors.auraRed;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Confiance IA',
              style: AuraTypography.labelSmall.copyWith(
                color: AuraColors.auraTextSecondary,
              ),
            ),
            Text(
              '$percentage%',
              style: AuraTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AuraDimensions.spaceXS),
        ClipRRect(
          borderRadius: BorderRadius.circular(AuraDimensions.radiusXS),
          child: LinearProgressIndicator(
            value: confidence,
            backgroundColor: AuraColors.auraGlass,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
