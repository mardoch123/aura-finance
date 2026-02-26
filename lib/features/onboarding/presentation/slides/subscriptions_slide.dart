import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/onboarding_state.dart';
import '../onboarding_controller.dart';

/// Slide 3: Abonnements actuels
/// Liste de logos populaires avec sélection
class SubscriptionsSlide extends ConsumerStatefulWidget {
  const SubscriptionsSlide({super.key});

  @override
  ConsumerState<SubscriptionsSlide> createState() => _SubscriptionsSlideState();
}

class _SubscriptionsSlideState extends ConsumerState<SubscriptionsSlide>
    with TickerProviderStateMixin {
  late List<AnimationController> _itemControllers;
  late List<Animation<double>> _scaleAnimations;
  
  final List<String> _subscriptionKeys = [
    PopularSubscriptions.netflix,
    PopularSubscriptions.spotify,
    PopularSubscriptions.disney,
    PopularSubscriptions.amazon,
    PopularSubscriptions.apple,
    PopularSubscriptions.youtube,
    PopularSubscriptions.gym,
    PopularSubscriptions.phone,
  ];

  @override
  void initState() {
    super.initState();
    
    _itemControllers = List.generate(
      _subscriptionKeys.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    
    _scaleAnimations = _itemControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.elasticOut,
        ),
      );
    }).toList();
    
    _startAnimations();
  }

  Future<void> _startAnimations() async {
    for (var i = 0; i < _itemControllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        _itemControllers[i].forward();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleSubscription(String subscription) {
    HapticService.selection();
    ref.read(onboardingNotifierProvider.notifier).toggleSubscription(subscription);
  }

  @override
  Widget build(BuildContext context) {
    final selectedSubs = ref.watch(onboardingNotifierProvider).selectedSubscriptions;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AuraDimensions.spaceXL,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Titre
          Text(
            'Vos abonnements actuels ?',
            style: AuraTypography.h2.copyWith(
              color: AuraColors.auraTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AuraDimensions.spaceS),
          Text(
            'Nous les surveillerons pour vous',
            style: AuraTypography.bodyLarge.copyWith(
              color: AuraColors.auraTextPrimary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AuraDimensions.spaceXXL),
          
          // Grille d'abonnements
          Wrap(
            spacing: AuraDimensions.spaceM,
            runSpacing: AuraDimensions.spaceM,
            alignment: WrapAlignment.center,
            children: List.generate(_subscriptionKeys.length, (index) {
              final sub = _subscriptionKeys[index];
              final isSelected = selectedSubs.contains(sub);
              final amount = PopularSubscriptions.defaultAmounts[sub] ?? 9.99;
              
              return AnimatedBuilder(
                animation: _itemControllers[index],
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimations[index].value,
                    child: _SubscriptionItem(
                      subscription: sub,
                      isSelected: isSelected,
                      amount: amount,
                      onTap: () => _toggleSubscription(sub),
                    ),
                  );
                },
              );
            }),
          ),
          
          const SizedBox(height: AuraDimensions.spaceXXL),
          
          // Récapitulatif mensuel
          if (selectedSubs.isNotEmpty)
            GlassCard(
              borderRadius: AuraDimensions.radiusL,
              padding: const EdgeInsets.symmetric(
                horizontal: AuraDimensions.spaceXL,
                vertical: AuraDimensions.spaceM,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: AuraColors.auraTextPrimary.withOpacity(0.7),
                    size: 20,
                  ),
                  const SizedBox(width: AuraDimensions.spaceM),
                  Text(
                    'Total mensuel estimé: ',
                    style: AuraTypography.bodyMedium.copyWith(
                      color: AuraColors.auraTextPrimary.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    '${_calculateTotal(selectedSubs).toStringAsFixed(0)}€',
                    style: AuraTypography.amountMedium.copyWith(
                      color: AuraColors.auraTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  double _calculateTotal(List<String> selectedSubs) {
    return selectedSubs.fold(0.0, (sum, sub) {
      return sum + (PopularSubscriptions.defaultAmounts[sub] ?? 0);
    });
  }
}

/// Item d'abonnement individuel
class _SubscriptionItem extends StatelessWidget {
  final String subscription;
  final bool isSelected;
  final double amount;
  final VoidCallback onTap;

  const _SubscriptionItem({
    required this.subscription,
    required this.isSelected,
    required this.amount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = PopularSubscriptions.labels[subscription] ?? subscription;
    final icon = PopularSubscriptions.icons[subscription] ?? '📦';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        width: 100,
        padding: const EdgeInsets.all(AuraDimensions.spaceM),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    AuraColors.auraAmber,
                    AuraColors.auraDeep,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    AuraColors.auraGlass,
                    AuraColors.auraGlass.withOpacity(0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
          border: Border.all(
            color: isSelected
                ? AuraColors.auraAccentGold.withOpacity(0.8)
                : AuraColors.auraTextPrimary.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AuraColors.auraAmber.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: AuraDimensions.spaceS),
            Text(
              label,
              style: AuraTypography.labelSmall.copyWith(
                color: isSelected
                    ? AuraColors.auraTextPrimary
                    : AuraColors.auraTextPrimary.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AuraDimensions.spaceXS),
            Text(
              '${amount.toStringAsFixed(0)}€/mois',
              style: AuraTypography.caption.copyWith(
                color: isSelected
                    ? AuraColors.auraTextPrimary.withOpacity(0.8)
                    : AuraColors.auraTextPrimary.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
