import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/aura_button.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../data/models/shared_account_model.dart';
import '../providers/shared_accounts_provider.dart';

/// Écran de création d'un compte partagé
class CreateSharedAccountScreen extends ConsumerStatefulWidget {
  const CreateSharedAccountScreen({super.key});

  @override
  ConsumerState<CreateSharedAccountScreen> createState() => _CreateSharedAccountScreenState();
}

class _CreateSharedAccountScreenState extends ConsumerState<CreateSharedAccountScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  SharingMode _selectedMode = SharingMode.couple;
  String _selectedColor = '#E8A86C';
  String _selectedIcon = 'people';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _modes = [
    {
      'mode': SharingMode.couple,
      'title': 'Couple',
      'description': 'Partagez vos finances avec votre partenaire',
      'icon': Icons.favorite_outline,
      'color': AuraColors.auraAccentGold,
      'features': ['Visibilité totale', 'Budget commun', 'Objectifs partagés'],
    },
    {
      'mode': SharingMode.family,
      'title': 'Famille',
      'description': 'Gérez le budget familial avec vos enfants',
      'icon': Icons.family_restroom_outlined,
      'color': AuraColors.auraGreen,
      'features': ['Contrôle parental', 'Allocation enfants', 'Dépenses suivies'],
    },
    {
      'mode': SharingMode.roommates,
      'title': 'Colocataires',
      'description': 'Partagez les dépenses communes facilement',
      'icon': Icons.home_outlined,
      'color': AuraColors.auraAmber,
      'features': ['Split des dépenses', 'Règlements automatiques', 'Historique clair'],
    },
  ];

  final List<String> _colors = [
    '#E8A86C', // Amber
    '#7DC983', // Green
    '#E07070', // Red
    '#6B8DD6', // Blue
    '#C4714A', // Deep
    '#9B7ED8', // Purple
  ];

  final List<Map<String, dynamic>> _icons = [
    {'name': 'people', 'icon': Icons.people_outline},
    {'name': 'family', 'icon': Icons.family_restroom_outlined},
    {'name': 'home', 'icon': Icons.home_outlined},
    {'name': 'favorite', 'icon': Icons.favorite_outline},
    {'name': 'wallet', 'icon': Icons.account_balance_wallet_outlined},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AuraColors.auraBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AuraDimensions.radiusXXL),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: AuraDimensions.spaceM),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AuraColors.auraTextDarkSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(AuraDimensions.spaceL),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nouveau compte partagé',
                          style: AuraTypography.h2.copyWith(
                            color: AuraColors.auraTextDark,
                          ),
                        ),
                        const SizedBox(height: AuraDimensions.spaceXS),
                        Text(
                          'Choisissez le mode qui vous convient',
                          style: AuraTypography.bodyMedium.copyWith(
                            color: AuraColors.auraTextDarkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close),
                    color: AuraColors.auraTextDarkSecondary,
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom du compte
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nom du compte',
                      hint: 'Ex: Notre Budget',
                      icon: Icons.edit_outlined,
                    ),
                    const SizedBox(height: AuraDimensions.spaceM),

                    // Description
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description (optionnel)',
                      hint: 'Ex: Gestion des dépenses communes',
                      icon: Icons.description_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: AuraDimensions.spaceXL),

                    // Sélection du mode
                    Text(
                      'Mode de partage',
                      style: AuraTypography.labelLarge.copyWith(
                        color: AuraColors.auraTextDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AuraDimensions.spaceM),
                    ..._modes.map((mode) => _buildModeCard(mode)),
                    const SizedBox(height: AuraDimensions.spaceXL),

                    // Couleur
                    Text(
                      'Couleur',
                      style: AuraTypography.labelLarge.copyWith(
                        color: AuraColors.auraTextDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AuraDimensions.spaceM),
                    _buildColorSelector(),
                    const SizedBox(height: AuraDimensions.spaceXL),

                    // Icône
                    Text(
                      'Icône',
                      style: AuraTypography.labelLarge.copyWith(
                        color: AuraColors.auraTextDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AuraDimensions.spaceM),
                    _buildIconSelector(),
                    const SizedBox(height: AuraDimensions.spaceXXL),
                  ],
                ),
              ),
            ),

            // Bouton créer
            Padding(
              padding: const EdgeInsets.all(AuraDimensions.spaceL),
              child: AuraButton(
                onPressed: _isLoading ? null : _createAccount,
                isLoading: _isLoading,
                text: 'Créer le compte partagé',
                icon: Icons.add,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AuraTypography.labelLarge.copyWith(
            color: AuraColors.auraTextDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AuraDimensions.spaceS),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: AuraTypography.bodyLarge.copyWith(
            color: AuraColors.auraTextDark,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AuraTypography.bodyLarge.copyWith(
              color: AuraColors.auraTextDarkSecondary.withOpacity(0.5),
            ),
            prefixIcon: Icon(
              icon,
              color: AuraColors.auraTextDarkSecondary,
            ),
            filled: true,
            fillColor: AuraColors.auraGlass,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AuraDimensions.spaceM,
              vertical: AuraDimensions.spaceM,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeCard(Map<String, dynamic> mode) {
    final isSelected = _selectedMode == mode['mode'];
    final color = mode['color'] as Color;

    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        setState(() {
          _selectedMode = mode['mode'] as SharingMode;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AuraDimensions.spaceM),
        padding: const EdgeInsets.all(AuraDimensions.spaceM),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AuraColors.auraGlass,
          borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
              ),
              child: Icon(
                mode['icon'] as IconData,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: AuraDimensions.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mode['title'] as String,
                    style: AuraTypography.labelLarge.copyWith(
                      color: AuraColors.auraTextDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mode['description'] as String,
                    style: AuraTypography.bodySmall.copyWith(
                      color: AuraColors.auraTextDarkSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: (mode['features'] as List<String>).map((feature) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AuraDimensions.radiusXS),
                        ),
                        child: Text(
                          feature,
                          style: AuraTypography.labelSmall.copyWith(
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSelector() {
    return Wrap(
      spacing: AuraDimensions.spaceM,
      runSpacing: AuraDimensions.spaceM,
      children: _colors.map((color) {
        final isSelected = _selectedColor == color;
        return GestureDetector(
          onTap: () {
            HapticService.lightTap();
            setState(() {
              _selectedColor = color;
            });
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: AuraColors.auraTextDark,
                      width: 3,
                    )
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Color(int.parse(color.replaceFirst('#', '0xFF'))).withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 24,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIconSelector() {
    return Wrap(
      spacing: AuraDimensions.spaceM,
      runSpacing: AuraDimensions.spaceM,
      children: _icons.map((iconData) {
        final name = iconData['name'] as String;
        final icon = iconData['icon'] as IconData;
        final isSelected = _selectedIcon == name;

        return GestureDetector(
          onTap: () {
            HapticService.lightTap();
            setState(() {
              _selectedIcon = name;
            });
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected
                  ? AuraColors.auraAmber.withOpacity(0.15)
                  : AuraColors.auraGlass,
              borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
              border: Border.all(
                color: isSelected ? AuraColors.auraAmber : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected
                  ? AuraColors.auraAmber
                  : AuraColors.auraTextDarkSecondary,
              size: 28,
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _createAccount() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un nom pour le compte'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticService.mediumTap();

    try {
      final config = _generateConfig();

      await ref.read(sharedAccountsListProvider.notifier).createAccount(
        name: _nameController.text.trim(),
        sharingMode: _selectedMode,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        config: config,
        color: _selectedColor,
        icon: _selectedIcon,
      );

      if (mounted) {
        HapticService.success();
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte partagé créé avec succès !'),
            backgroundColor: AuraColors.auraGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        HapticService.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AuraColors.auraRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, dynamic> _generateConfig() {
    switch (_selectedMode) {
      case SharingMode.couple:
        return {
          'income_sharing': 'full',
          'notify_large_expenses': true,
          'large_expense_threshold': 100.0,
        };
      case SharingMode.family:
        return {
          'children_can_view': true,
          'children_can_add': false,
          'parent_approval': true,
          'child_spending_limit': 50.0,
        };
      case SharingMode.roommates:
        return {
          'expense_splitting': 'equal',
          'settlement_day': 1,
          'notify_new_expense': true,
          'auto_calculate_balances': true,
        };
    }
  }
}
