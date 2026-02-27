import 'package:flutter/material.dart';
import '../../theme/aura_colors.dart';
import '../../theme/aura_typography.dart';
import '../../theme/aura_dimensions.dart';
import '../../widgets/glass_card.dart';
import 'felix_mascot.dart';
import '../felix_animation_type.dart';

/// Paywall avec Félix couronné (version Pro)
class FelixPaywall extends StatelessWidget {
  /// Prix mensuel
  final String monthlyPrice;
  
  /// Prix annuel
  final String yearlyPrice;
  
  /// Économie annuelle
  final String? yearlySavings;
  
  /// Callback pour l'achat mensuel
  final VoidCallback? onMonthlyTap;
  
  /// Callback pour l'achat annuel
  final VoidCallback? onYearlyTap;
  
  /// Callback pour restaurer les achats
  final VoidCallback? onRestoreTap;
  
  /// Callback pour fermer
  final VoidCallback? onClose;

  const FelixPaywall({
    super.key,
    required this.monthlyPrice,
    required this.yearlyPrice,
    this.yearlySavings,
    this.onMonthlyTap,
    this.onYearlyTap,
    this.onRestoreTap,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraColors.auraBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // Contenu scrollable
            CustomScrollView(
              slivers: [
                // Header avec Félix Pro
                SliverToBoxAdapter(
                  child: _buildHeader(),
                ),
                
                // Fonctionnalités Pro
                SliverPadding(
                  padding: const EdgeInsets.all(AuraDimensions.spaceL),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildFeatureItem(
                        icon: Icons.camera_alt_outlined,
                        title: 'Scans illimités',
                        description: 'Scannez autant de reçus que vous voulez',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureItem(
                        icon: Icons.psychology_outlined,
                        title: 'Coach IA avancé',
                        description: 'Conseils personnalisés en temps réel',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureItem(
                        icon: Icons.account_balance_outlined,
                        title: 'Sync bancaire',
                        description: 'Connectez tous vos comptes bancaires',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureItem(
                        icon: Icons.insights_outlined,
                        title: 'Prédictions 30 jours',
                        description: 'Anticipez votre solde futur',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureItem(
                        icon: Icons.workspace_premium_outlined,
                        title: 'Badges exclusifs',
                        description: 'Débloquez des accessoires pour Félix',
                      ),
                    ]),
                  ),
                ),
                
                // Espacement
                const SliverPadding(
                  padding: EdgeInsets.only(bottom: 200),
                ),
              ],
            ),
            
            // Bouton fermer
            Positioned(
              top: AuraDimensions.spaceM,
              right: AuraDimensions.spaceM,
              child: IconButton(
                onPressed: onClose ?? () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                color: AuraColors.auraTextDark,
              ),
            ),
            
            // Bottom sheet avec les offres
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildOffersSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AuraDimensions.spaceXL),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // Félix avec couronne
          Stack(
            alignment: Alignment.topCenter,
            children: [
              // Félix Pro
              FelixMascot(
                animationType: FelixAnimationType.pro,
                size: 160,
              ),
              
              // Couronne emoji positionnée au-dessus
              Positioned(
                top: -10,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AuraColors.auraAccentGold.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '👑',
                    style: TextStyle(fontSize: 32),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Titre
          Text(
            'Rejoignez Félix en Pro',
            style: AuraTypography.h2.copyWith(
              color: AuraColors.auraTextDark,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Sous-titre
          Text(
            'Débloquez toutes les fonctionnalités premium et donnez à Félix de nouveaux accessoires !',
            style: AuraTypography.bodyLarge.copyWith(
              color: AuraColors.auraTextDarkSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AuraColors.auraAmber.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
          ),
          child: Icon(
            icon,
            color: AuraColors.auraAmber,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
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
              const SizedBox(height: 2),
              Text(
                description,
                style: AuraTypography.bodySmall.copyWith(
                  color: AuraColors.auraTextDarkSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOffersSection() {
    return GlassCard(
      margin: const EdgeInsets.all(AuraDimensions.spaceM),
      borderRadius: AuraDimensions.radiusXXL,
      child: Padding(
        padding: const EdgeInsets.all(AuraDimensions.spaceL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Offre annuelle (recommandée)
            _buildOfferCard(
              title: 'Annuel',
              price: yearlyPrice,
              subtitle: yearlySavings != null ? 'Économisez $yearlySavings' : 'Le plus populaire',
              isRecommended: true,
              onTap: onYearlyTap,
            ),
            
            const SizedBox(height: 12),
            
            // Offre mensuelle
            _buildOfferCard(
              title: 'Mensuel',
              price: monthlyPrice,
              subtitle: 'Annulez à tout moment',
              isRecommended: false,
              onTap: onMonthlyTap,
            ),
            
            const SizedBox(height: 16),
            
            // Restaurer les achats
            TextButton(
              onPressed: onRestoreTap,
              child: Text(
                'Restaurer mes achats',
                style: AuraTypography.bodySmall.copyWith(
                  color: AuraColors.auraTextDarkSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferCard({
    required String title,
    required String price,
    required String subtitle,
    required bool isRecommended,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AuraDimensions.spaceM),
        decoration: BoxDecoration(
          color: isRecommended 
              ? AuraColors.auraAmber.withOpacity(0.2) 
              : AuraColors.auraGlass,
          borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
          border: Border.all(
            color: isRecommended 
                ? AuraColors.auraAmber 
                : AuraColors.auraGlassBorder,
            width: isRecommended ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AuraTypography.labelLarge.copyWith(
                          color: AuraColors.auraTextDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AuraColors.auraAmber,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'RECOMMANDÉ',
                            style: AuraTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AuraTypography.bodySmall.copyWith(
                      color: AuraColors.auraTextDarkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: AuraTypography.h3.copyWith(
                color: isRecommended 
                    ? AuraColors.auraAmber 
                    : AuraColors.auraTextDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mini paywall pour les fonctionnalités verrouillées
class FelixMiniPaywall extends StatelessWidget {
  final String featureName;
  final VoidCallback? onUpgrade;

  const FelixMiniPaywall({
    super.key,
    required this.featureName,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AuraDimensions.spaceL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Félix avec monocle
            Stack(
              alignment: Alignment.center,
              children: [
                FelixMascot(
                  animationType: FelixAnimationType.pro,
                  size: 100,
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AuraColors.auraAccentGold.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '🧐',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Fonctionnalité Pro',
              style: AuraTypography.h4.copyWith(
                color: AuraColors.auraTextDark,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              '$featureName est réservé aux membres Pro',
              style: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.auraTextDarkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 20),
            
            ElevatedButton.icon(
              onPressed: onUpgrade,
              icon: const Icon(Icons.workspace_premium),
              label: const Text('Passer à Pro'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AuraColors.auraAmber,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AuraDimensions.spaceXL,
                  vertical: AuraDimensions.spaceM,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
