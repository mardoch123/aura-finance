import 'package:flutter/material.dart';
import '../theme/aura_colors.dart';
import '../theme/aura_dimensions.dart';
import '../widgets/glass_card.dart';
import 'shimmer_effect.dart';

/// Loaders glassmorphiques pour l'expérience de chargement premium
class GlassLoaders {
  /// Loader pour les cartes de compte
  static Widget accountCardLoader() {
    return GlassCard(
      padding: const EdgeInsets.all(AuraDimensions.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec avatar et nom
          Row(
            children: [
              ShimmerEffect(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AuraColors.auraGlass,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: AuraDimensions.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerEffect(
                      child: Container(
                        width: 120,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AuraColors.auraGlass,
                          borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShimmerEffect(
                      child: Container(
                        width: 80,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AuraColors.auraGlass,
                          borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ShimmerEffect(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AuraColors.auraGlass,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AuraDimensions.spaceL),
          // Solde
          ShimmerEffect(
            child: Container(
              width: 180,
              height: 32,
              decoration: BoxDecoration(
                color: AuraColors.auraGlass,
                borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Loader pour les transactions
  static Widget transactionLoader() {
    return GlassCard(
      padding: const EdgeInsets.all(AuraDimensions.spaceM),
      child: Row(
        children: [
          // Icone
          ShimmerEffect(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AuraColors.auraGlass,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: AuraDimensions.spaceM),
          // Textes
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerEffect(
                  child: Container(
                    width: 100,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AuraColors.auraGlass,
                      borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ShimmerEffect(
                  child: Container(
                    width: 60,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AuraColors.auraGlass,
                      borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Montant
          ShimmerEffect(
            child: Container(
              width: 80,
              height: 20,
              decoration: BoxDecoration(
                color: AuraColors.auraGlass,
                borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Loader pour le dashboard complet
  static Widget dashboardLoader() {
    return const Column(
      children: [
        // Header
        _DashboardHeaderLoader(),
        SizedBox(height: AuraDimensions.spaceL),
        // Balance card
        _BalanceCardLoader(),
        SizedBox(height: AuraDimensions.spaceL),
        // Quick actions
        _QuickActionsLoader(),
        SizedBox(height: AuraDimensions.spaceL),
        // Transactions list
        _TransactionsListLoader(),
      ],
    );
  }

  /// Loader pour les insights IA
  static Widget insightLoader() {
    return GlassCard(
      padding: const EdgeInsets.all(AuraDimensions.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerEffect(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AuraColors.auraGlass,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: AuraDimensions.spaceS),
              ShimmerEffect(
                child: Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AuraColors.auraGlass,
                    borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AuraDimensions.spaceM),
          ShimmerEffect(
            child: Container(
              width: double.infinity,
              height: 16,
              decoration: BoxDecoration(
                color: AuraColors.auraGlass,
                borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ShimmerEffect(
            child: Container(
              width: 200,
              height: 16,
              decoration: BoxDecoration(
                color: AuraColors.auraGlass,
                borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Loaders composants internes
class _DashboardHeaderLoader extends StatelessWidget {
  const _DashboardHeaderLoader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ShimmerEffect(
            child: Container(
              width: 120,
              height: 24,
              decoration: BoxDecoration(
                color: AuraColors.auraGlass,
                borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
              ),
            ),
          ),
          ShimmerEffect(
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AuraColors.auraGlass,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCardLoader extends StatelessWidget {
  const _BalanceCardLoader();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AuraDimensions.spaceXL),
      child: Column(
        children: [
          ShimmerEffect(
            child: Container(
              width: 180,
              height: 40,
              decoration: BoxDecoration(
                color: AuraColors.auraGlass,
                borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
              ),
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceM),
          ShimmerEffect(
            child: Container(
              width: 120,
              height: 16,
              decoration: BoxDecoration(
                color: AuraColors.auraGlass,
                borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsLoader extends StatelessWidget {
  const _QuickActionsLoader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceM),
      child: Row(
        children: [
          Expanded(
            child: ShimmerEffect(
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: AuraColors.auraGlass,
                  borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
                ),
              ),
            ),
          ),
          const SizedBox(width: AuraDimensions.spaceM),
          Expanded(
            child: ShimmerEffect(
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: AuraColors.auraGlass,
                  borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
                ),
              ),
            ),
          ),
          const SizedBox(width: AuraDimensions.spaceM),
          Expanded(
            child: ShimmerEffect(
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: AuraColors.auraGlass,
                  borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionsListLoader extends StatelessWidget {
  const _TransactionsListLoader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(4, (index) => const Padding(
        padding: EdgeInsets.only(bottom: AuraDimensions.spaceS),
        child: GlassLoaders.transactionLoader(),
      )),
    );
  }
}