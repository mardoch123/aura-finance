import 'package:flutter/material.dart';
import '../../theme/aura_colors.dart';
import '../../theme/aura_typography.dart';
import '../../theme/aura_dimensions.dart';
import 'felix_mascot.dart';
import '../felix_animation_type.dart';

/// Écran vide avec Félix - aucune transaction
class FelixEmptyState extends StatelessWidget {
  /// Titre principal
  final String title;
  
  /// Sous-titre/description
  final String? subtitle;
  
  /// Texte du bouton d'action
  final String? actionLabel;
  
  /// Callback quand on appuie sur le bouton
  final VoidCallback? onAction;
  
  /// Taille de Félix
  final double felixSize;

  const FelixEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.felixSize = 150,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AuraDimensions.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Félix assis, regard vers le haut
            FelixMascot(
              animationType: FelixAnimationType.empty,
              size: felixSize,
            ),
            
            const SizedBox(height: 32),
            
            // Titre
            Text(
              title,
              style: AuraTypography.h3.copyWith(
                color: AuraColors.auraTextDark,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Sous-titre
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              Text(
                subtitle!,
                style: AuraTypography.bodyLarge.copyWith(
                  color: AuraColors.auraTextDarkSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            // Bouton d'action
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuraColors.auraAmber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AuraDimensions.spaceXL,
                    vertical: AuraDimensions.spaceM,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Variante pour les transactions vides
class FelixEmptyTransactions extends StatelessWidget {
  final VoidCallback? onScan;

  const FelixEmptyTransactions({
    super.key,
    this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return FelixEmptyState(
      title: 'Félix attend vos premières transactions !',
      subtitle: 'Commencez à scanner vos reçus pour suivre vos dépenses',
      actionLabel: 'Scanner mon premier reçu',
      onAction: onScan,
      felixSize: 150,
    );
  }
}

/// Variante pour les objectifs vides
class FelixEmptyGoals extends StatelessWidget {
  final VoidCallback? onCreate;

  const FelixEmptyGoals({
    super.key,
    this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return FelixEmptyState(
      title: 'Pas encore d\'objectif ?',
      subtitle: 'Félix vous aidera à atteindre vos projets financiers',
      actionLabel: 'Créer un objectif',
      onAction: onCreate,
      felixSize: 140,
    );
  }
}

/// Variante générique
class FelixEmptyGeneric extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;

  const FelixEmptyGeneric({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FelixMascot(
            animationType: FelixAnimationType.empty,
            size: 120,
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: AuraTypography.h4.copyWith(
              color: AuraColors.auraTextDark,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.auraTextDarkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
