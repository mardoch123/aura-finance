import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/extensions/app_localizations_extension.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/aura_button.dart';
import '../../../../core/widgets/glass_card.dart';

/// Écran de gestion des abonnements (Le Gardien)
class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  bool _showVampiresOnly = false;

  @override
  Widget build(BuildContext context) {
    // TODO: Remplacer par un vrai provider
    final subscriptions = _getMockSubscriptions();
    final vampires = subscriptions.where((s) => s.isVampire).toList();

    return Scaffold(
      backgroundColor: AuraColors.auraBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Stats
            _buildStats(subscriptions, vampires),

            // Filtre vampires
            if (vampires.isNotEmpty)
              _buildVampireFilter(vampires.length),

            const SizedBox(height: AuraDimensions.spaceM),

            // Liste
            Expanded(
              child: _buildSubscriptionsList(
                _showVampiresOnly ? vampires : subscriptions,
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
            child: Column(
              children: [
                Text(
                  context.l10n.subscriptions,
                  style: AuraTypography.h3.copyWith(color: AuraColors.auraTextDark),
                ),
                Text(
                  '${context.l10n.theGuardian} 🧛',
                  style: AuraTypography.bodySmall.copyWith(
                    color: AuraColors.auraTextDarkSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              HapticService.lightTap();
              _showInfoDialog();
            },
            icon: const Icon(Icons.info_outline, color: AuraColors.auraTextDark),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(List<Subscription> subscriptions, List<Subscription> vampires) {
    final totalMonthly = subscriptions.fold<double>(
      0,
      (sum, s) => sum + s.monthlyAmount,
    );
    final vampireAmount = vampires.fold<double>(
      0,
      (sum, s) => sum + (s.newAmount! - s.oldAmount!),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceM),
      child: Row(
        children: [
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(AuraDimensions.spaceM),
              child: Column(
                children: [
                  Text(
                    '${subscriptions.length}',
                    style: AuraTypography.h2.copyWith(
                      color: AuraColors.auraTextDark,
                    ),
                  ),
                  Text(
                    context.l10n.subscriptions,
                    style: AuraTypography.bodySmall.copyWith(
                      color: AuraColors.auraTextDarkSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AuraDimensions.spaceM),
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(AuraDimensions.spaceM),
              child: Column(
                children: [
                  Text(
                    '${totalMonthly.toStringAsFixed(0)}€',
                    style: AuraTypography.h2.copyWith(
                      color: AuraColors.auraTextDark,
                    ),
                  ),
                  Text(
                    context.l10n.perMonth,
                    style: AuraTypography.bodySmall.copyWith(
                      color: AuraColors.auraTextDarkSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (vampires.isNotEmpty) ...[
            const SizedBox(width: AuraDimensions.spaceM),
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(AuraDimensions.spaceM),
                child: Column(
                  children: [
                    Text(
                      '+${vampireAmount.toStringAsFixed(0)}€',
                      style: AuraTypography.h2.copyWith(
                        color: AuraColors.auraRed,
                      ),
                    ),
                    Text(
                      context.l10n.increases,
                      style: AuraTypography.bodySmall.copyWith(
                        color: AuraColors.auraTextDarkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVampireFilter(int vampireCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceM),
      child: GestureDetector(
        onTap: () {
          HapticService.lightTap();
          setState(() => _showVampiresOnly = !_showVampiresOnly);
        },
        child: GlassCard(
          gradient: _showVampiresOnly
              ? LinearGradient(
                  colors: [
                    AuraColors.auraRed.withOpacity(0.1),
                    AuraColors.auraRed.withOpacity(0.05),
                  ],
                )
              : null,
          padding: const EdgeInsets.symmetric(
            horizontal: AuraDimensions.spaceM,
            vertical: AuraDimensions.spaceS,
          ),
          child: Row(
            children: [
              const Text('🧛', style: TextStyle(fontSize: 20)),
              const SizedBox(width: AuraDimensions.spaceS),
              Expanded(
                child: Text(
                  vampireCount == 1 
                      ? context.l10n.vampiresDetected_one.replaceAll('{count}', vampireCount.toString())
                      : context.l10n.vampiresDetected_other.replaceAll('{count}', vampireCount.toString()),
                  style: AuraTypography.labelMedium.copyWith(
                    color: _showVampiresOnly
                        ? AuraColors.auraRed
                        : AuraColors.auraTextDark,
                  ),
                ),
              ),
              Icon(
                _showVampiresOnly
                    ? Icons.check_circle
                    : Icons.circle_outlined,
                color: _showVampiresOnly
                    ? AuraColors.auraRed
                    : AuraColors.auraTextDarkSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionsList(List<Subscription> subscriptions) {
    if (subscriptions.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceM),
      itemCount: subscriptions.length,
      itemBuilder: (context, index) {
        final sub = subscriptions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AuraDimensions.spaceM),
          child: SubscriptionCard(
            subscription: sub,
            onTap: () => _showSubscriptionDetail(sub),
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
              Icons.subscriptions_outlined,
              size: 48,
              color: AuraColors.auraAmber.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceL),
          Text(
            context.l10n.noSubscription,
            style: AuraTypography.h4.copyWith(color: AuraColors.auraTextDark),
          ),
          const SizedBox(height: AuraDimensions.spaceS),
          Text(
            context.l10n.addSubscriptionHint,
            style: AuraTypography.bodyMedium.copyWith(
              color: AuraColors.auraTextDarkSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        HapticService.mediumTap();
        _showAddSubscriptionDialog();
      },
      backgroundColor: AuraColors.auraAmber,
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(
        context.l10n.add,
        style: AuraTypography.labelMedium.copyWith(color: Colors.white),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AuraColors.auraGlassStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AuraDimensions.radiusXL),
        ),
        title: Row(
          children: [
            const Text('🧛', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              context.l10n.theGuardian,
              style: AuraTypography.h4.copyWith(color: AuraColors.auraTextDark),
            ),
          ],
        ),
        content: Text(
          context.l10n.theGuardianDesc,
          style: AuraTypography.bodyMedium.copyWith(
            color: AuraColors.auraTextDarkSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.l10n.understood,
              style: AuraTypography.labelMedium.copyWith(
                color: AuraColors.auraAmber,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDetail(Subscription sub) {
    HapticService.mediumTap();
    // TODO: Modal de détail
  }

  void _showAddSubscriptionDialog() {
    HapticService.lightTap();
    // TODO: Modal d'ajout
  }

  List<Subscription> _getMockSubscriptions() {
    return [
      Subscription(
        id: '1',
        name: 'Netflix',
        amount: 17.99,
        oldAmount: 13.99,
        newAmount: 17.99,
        billingCycle: 'monthly',
        nextBillingDate: DateTime.now().add(const Duration(days: 15)),
        category: 'entertainment',
        isVampire: true,
        priceIncreaseDetectedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Subscription(
        id: '2',
        name: 'Spotify',
        amount: 10.99,
        billingCycle: 'monthly',
        nextBillingDate: DateTime.now().add(const Duration(days: 8)),
        category: 'entertainment',
        isVampire: false,
      ),
      Subscription(
        id: '3',
        name: 'Canal+',
        amount: 24.90,
        oldAmount: 19.90,
        newAmount: 24.90,
        billingCycle: 'monthly',
        nextBillingDate: DateTime.now().add(const Duration(days: 22)),
        category: 'entertainment',
        isVampire: true,
        priceIncreaseDetectedAt: DateTime.now().subtract(const Duration(days: 12)),
      ),
      Subscription(
        id: '4',
        name: 'Adobe Creative Cloud',
        amount: 59.99,
        billingCycle: 'monthly',
        nextBillingDate: DateTime.now().add(const Duration(days: 3)),
        category: 'productivity',
        isVampire: false,
      ),
    ];
  }
}

/// Modèle d'abonnement
class Subscription {
  final String id;
  final String name;
  final double amount;
  final double? oldAmount;
  final double? newAmount;
  final String billingCycle;
  final DateTime nextBillingDate;
  final String category;
  final bool isVampire;
  final DateTime? priceIncreaseDetectedAt;

  Subscription({
    required this.id,
    required this.name,
    required this.amount,
    this.oldAmount,
    this.newAmount,
    required this.billingCycle,
    required this.nextBillingDate,
    required this.category,
    this.isVampire = false,
    this.priceIncreaseDetectedAt,
  });

  double get monthlyAmount =>
      billingCycle == 'yearly' ? amount / 12 : amount;

  double? get increasePercentage {
    if (oldAmount == null || newAmount == null) return null;
    return ((newAmount! - oldAmount!) / oldAmount!) * 100;
  }
}

/// Carte d'abonnement
class SubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final VoidCallback? onTap;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM', 'fr_FR');
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    );

    return GlassCard(
      onTap: onTap,
      gradient: subscription.isVampire
          ? LinearGradient(
              colors: [
                AuraColors.auraRed.withOpacity(0.05),
                AuraColors.auraRed.withOpacity(0.02),
              ],
            )
          : null,
      padding: const EdgeInsets.all(AuraDimensions.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icône
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: subscription.isVampire
                      ? AuraColors.auraRed.withOpacity(0.15)
                      : AuraColors.auraGlass,
                  borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
                ),
                child: Center(
                  child: Text(
                    subscription.isVampire ? '🧛' : '📋',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),

              const SizedBox(width: AuraDimensions.spaceM),

              // Nom et catégorie
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.name,
                      style: AuraTypography.labelLarge.copyWith(
                        color: AuraColors.auraTextDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${context.l10n.nextBilling}: ${dateFormat.format(subscription.nextBillingDate)}',
                      style: AuraTypography.bodySmall.copyWith(
                        color: AuraColors.auraTextDarkSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Montant
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(subscription.amount),
                    style: AuraTypography.amountSmall.copyWith(
                      color: subscription.isVampire
                          ? AuraColors.auraRed
                          : AuraColors.auraTextDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subscription.billingCycle == 'monthly' ? context.l10n.perMonth : context.l10n.perYear,
                    style: AuraTypography.caption.copyWith(
                      color: AuraColors.auraTextDarkSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Alerte vampire
          if (subscription.isVampire) ...[
            const SizedBox(height: AuraDimensions.spaceM),
            Container(
              padding: const EdgeInsets.all(AuraDimensions.spaceS),
              decoration: BoxDecoration(
                color: AuraColors.auraRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: AuraColors.auraRed,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.increaseDetected(
                        subscription.increasePercentage?.toStringAsFixed(0) ?? '0',
                        (subscription.newAmount! - subscription.oldAmount!).toStringAsFixed(2),
                      ),
                      style: AuraTypography.bodySmall.copyWith(
                        color: AuraColors.auraRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
