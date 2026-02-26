import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../..//core/theme/aura_typography.dart';
import '../../../../core/widgets/aura_button.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/transaction_model.dart';
import '../providers/transactions_provider.dart';

/// Écran d'ajout/édition de transaction
class AddTransactionScreen extends ConsumerStatefulWidget {
  final String? transactionId;

  const AddTransactionScreen({
    super.key,
    this.transactionId,
  });

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isExpense = true;
  String _selectedCategory = 'other';
  DateTime _selectedDate = DateTime.now();

  final List<Map<String, dynamic>> _categories = [
    {'id': 'food', 'name': 'Alimentation', 'icon': '🍽️'},
    {'id': 'transport', 'name': 'Transport', 'icon': '🚗'},
    {'id': 'housing', 'name': 'Logement', 'icon': '🏠'},
    {'id': 'entertainment', 'name': 'Loisirs', 'icon': '🎬'},
    {'id': 'shopping', 'name': 'Shopping', 'icon': '🛍️'},
    {'id': 'health', 'name': 'Santé', 'icon': '💊'},
    {'id': 'education', 'name': 'Éducation', 'icon': '📚'},
    {'id': 'utilities', 'name': 'Factures', 'icon': '💡'},
    {'id': 'salary', 'name': 'Salaire', 'icon': '💰'},
    {'id': 'other', 'name': 'Autre', 'icon': '📦'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.transactionId != null) {
      _loadTransaction();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTransaction() async {
    // Charger la transaction existante
    final notifier = ref.read(transactionFormNotifierProvider.notifier);
    await notifier.loadTransaction(widget.transactionId!);

    final state = ref.read(transactionFormNotifierProvider);
    if (state.amount != null) {
      _amountController.text = state.amount!.abs().toStringAsFixed(2);
      _isExpense = state.amount! < 0;
    }
    if (state.category != null) {
      _selectedCategory = state.category!;
    }
    if (state.merchant != null) {
      _merchantController.text = state.merchant!;
    }
    if (state.description != null) {
      _descriptionController.text = state.description!;
    }
    if (state.date != null) {
      _selectedDate = state.date!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(transactionFormNotifierProvider);
    final isEditing = widget.transactionId != null;

    // Écouter les changements de succès
    ref.listen(transactionFormNotifierProvider, (previous, next) {
      if (next.isSuccess && !(previous?.isSuccess ?? false)) {
        HapticService.success();
        context.goBack();
      }
    });

    return Scaffold(
      backgroundColor: AuraColors.auraBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(isEditing),

            // Formulaire
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AuraDimensions.spaceM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type (Dépense/Revenu)
                    _buildTypeSelector(),

                    const SizedBox(height: AuraDimensions.spaceL),

                    // Montant
                    _buildAmountField(),

                    const SizedBox(height: AuraDimensions.spaceL),

                    // Catégories
                    _buildCategorySelector(),

                    const SizedBox(height: AuraDimensions.spaceL),

                    // Marchand
                    _buildTextField(
                      controller: _merchantController,
                      label: 'Marchand',
                      hint: 'Nom du commerçant',
                      icon: Icons.store,
                      onChanged: (value) {
                        ref.read(transactionFormNotifierProvider.notifier).setMerchant(value);
                      },
                    ),

                    const SizedBox(height: AuraDimensions.spaceL),

                    // Description
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Détails de la transaction',
                      icon: Icons.description,
                      maxLines: 3,
                      onChanged: (value) {
                        ref.read(transactionFormNotifierProvider.notifier).setDescription(value);
                      },
                    ),

                    const SizedBox(height: AuraDimensions.spaceL),

                    // Date
                    _buildDateSelector(),

                    const SizedBox(height: AuraDimensions.spaceXL),

                    // Erreur
                    if (formState.error != null)
                      Container(
                        padding: const EdgeInsets.all(AuraDimensions.spaceM),
                        decoration: BoxDecoration(
                          color: AuraColors.auraRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: AuraColors.auraRed),
                            const SizedBox(width: AuraDimensions.spaceS),
                            Expanded(
                              child: Text(
                                formState.error!,
                                style: AuraTypography.bodyMedium.copyWith(
                                  color: AuraColors.auraRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: AuraDimensions.spaceL),

                    // Bouton de validation
                    AuraButton(
                      label: isEditing ? 'Enregistrer' : 'Ajouter la transaction',
                      onPressed: formState.isSubmitting ? null : _submit,
                      isLoading: formState.isSubmitting,
                      type: AuraButtonType.primary,
                      size: AuraButtonSize.large,
                      isFullWidth: true,
                    ),

                    const SizedBox(height: AuraDimensions.spaceL),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEditing) {
    return Padding(
      padding: const EdgeInsets.all(AuraDimensions.spaceM),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.goBack(),
            icon: const Icon(Icons.close, color: AuraColors.auraTextDark),
          ),
          Expanded(
            child: Text(
              isEditing ? 'Modifier' : 'Nouvelle transaction',
              style: AuraTypography.h3.copyWith(color: AuraColors.auraTextDark),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return GlassCard(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticService.lightTap();
                setState(() => _isExpense = true);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: AuraDimensions.spaceM),
                decoration: BoxDecoration(
                  color: _isExpense ? AuraColors.auraRed : Colors.transparent,
                  borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
                ),
                child: Text(
                  'Dépense',
                  textAlign: TextAlign.center,
                  style: AuraTypography.labelLarge.copyWith(
                    color: _isExpense ? Colors.white : AuraColors.auraTextDark,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticService.lightTap();
                setState(() => _isExpense = false);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: AuraDimensions.spaceM),
                decoration: BoxDecoration(
                  color: !_isExpense ? AuraColors.auraGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
                ),
                child: Text(
                  'Revenu',
                  textAlign: TextAlign.center,
                  style: AuraTypography.labelLarge.copyWith(
                    color: !_isExpense ? Colors.white : AuraColors.auraTextDark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return GlassCard(
      padding: const EdgeInsets.all(AuraDimensions.spaceL),
      child: Column(
        children: [
          Text(
            'Montant',
            style: AuraTypography.labelMedium.copyWith(
              color: AuraColors.auraTextDarkSecondary,
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceS),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: AuraTypography.hero.copyWith(
              color: _isExpense ? AuraColors.auraRed : AuraColors.auraGreen,
            ),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: AuraTypography.hero.copyWith(
                color: AuraColors.auraTextDarkSecondary.withOpacity(0.3),
              ),
              border: InputBorder.none,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 60),
                child: Text(
                  '€',
                  style: AuraTypography.h2.copyWith(
                    color: AuraColors.auraTextDarkSecondary,
                  ),
                ),
              ),
            ),
            onChanged: (value) {
              final amount = double.tryParse(value.replaceAll(',', '.'));
              if (amount != null) {
                final signedAmount = _isExpense ? -amount : amount;
                ref.read(transactionFormNotifierProvider.notifier).setAmount(signedAmount);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catégorie',
          style: AuraTypography.labelMedium.copyWith(
            color: AuraColors.auraTextDarkSecondary,
          ),
        ),
        const SizedBox(height: AuraDimensions.spaceS),
        Wrap(
          spacing: AuraDimensions.spaceS,
          runSpacing: AuraDimensions.spaceS,
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category['id'];
            return GestureDetector(
              onTap: () {
                HapticService.lightTap();
                setState(() => _selectedCategory = category['id']);
                ref.read(transactionFormNotifierProvider.notifier).setCategory(category['id']);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AuraDimensions.spaceM,
                  vertical: AuraDimensions.spaceS,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AuraColors.auraAmber
                      : AuraColors.auraGlass,
                  borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
                  border: isSelected
                      ? null
                      : Border.all(color: AuraColors.auraGlassBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(category['icon'], style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      category['name'],
                      style: AuraTypography.labelMedium.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AuraColors.auraTextDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AuraTypography.labelMedium.copyWith(
            color: AuraColors.auraTextDarkSecondary,
          ),
        ),
        const SizedBox(height: AuraDimensions.spaceS),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: AuraTypography.bodyLarge.copyWith(color: AuraColors.auraTextDark),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AuraColors.auraTextDarkSecondary),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    final dateFormat = DateFormat('dd MMMM yyyy', 'fr_FR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: AuraTypography.labelMedium.copyWith(
            color: AuraColors.auraTextDarkSecondary,
          ),
        ),
        const SizedBox(height: AuraDimensions.spaceS),
        GestureDetector(
          onTap: () => _selectDate(),
          child: GlassCard(
            padding: const EdgeInsets.all(AuraDimensions.spaceM),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AuraColors.auraTextDarkSecondary,
                ),
                const SizedBox(width: AuraDimensions.spaceM),
                Text(
                  dateFormat.format(_selectedDate),
                  style: AuraTypography.bodyLarge.copyWith(
                    color: AuraColors.auraTextDark,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: AuraColors.auraTextDarkSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AuraColors.auraAmber,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      HapticService.lightTap();
      setState(() => _selectedDate = picked);
      ref.read(transactionFormNotifierProvider.notifier).setDate(picked);
    }
  }

  Future<void> _submit() async {
    HapticService.mediumTap();

    // Mettre à jour les valeurs du formulaire
    final notifier = ref.read(transactionFormNotifierProvider.notifier);

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount != null) {
      notifier.setAmount(_isExpense ? -amount : amount);
    }
    notifier.setCategory(_selectedCategory);
    notifier.setMerchant(_merchantController.text);
    notifier.setDescription(_descriptionController.text);
    notifier.setDate(_selectedDate);

    // Soumettre
    if (widget.transactionId != null) {
      await notifier.update(widget.transactionId!);
    } else {
      await notifier.submit();
    }
  }
}
