import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/ads/ads.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../services/usage_limit_service.dart';
import '../../../subscription/subscription.dart';

/// Widget qui vérifie les limites de scan avant d'autoriser l'action
/// 
/// Affiche :
/// - Le compteur de scans restants (si gratuit)
/// - Une carte de récompense si la limite est atteinte
/// - Rien si Pro
/// 
/// Usage:
/// ```dart
/// ScanLimitChecker(
///   child: ScanButton(onPressed: startScan),
/// )
/// ```
class ScanLimitChecker extends ConsumerWidget {
  final Widget child;

  const ScanLimitChecker({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limitAsync = ref.watch(canScanProvider);

    return limitAsync.when(
      data: (result) {
        // Si Pro, afficher juste l'enfant
        if (result.isPro) {
          return child;
        }

        // Si limite atteinte, afficher la carte de récompense
        if (result.isLimitReached) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              child,
              const SizedBox(height: 12),
              AuraRewardedOfferCard(
                type: RewardType.scanBonus,
                onRewardEarned: () {
                  // Rafraîchir le provider après récompense
                  ref.invalidate(canScanProvider);
                  HapticService.success();
                },
                onProPressed: () {
                  PaywallService.show(
                    context,
                    trigger: PaywallTrigger.scanLimitReached,
                  );
                },
              ),
            ],
          );
        }

        // Afficher le compteur et l'enfant
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildUsageIndicator(result),
            const SizedBox(height: 8),
            child,
          ],
        );
      },
      loading: () => child,
      error: (_, __) => child,
    );
  }

  Widget _buildUsageIndicator(LimitCheckResult result) {
    final remaining = result.remaining;
    final total = result.limit;
    final percentage = result.usagePercentage;

    // Couleur selon l'usage
    Color indicatorColor;
    if (percentage < 50) {
      indicatorColor = AuraColors.auraGreen;
    } else if (percentage < 80) {
      indicatorColor = AuraColors.auraOrange;
    } else {
      indicatorColor = AuraColors.auraRed;
    }

    return GlassCard(
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 16,
            color: indicatorColor,
          ),
          const SizedBox(width: 8),
          Text(
            '$remaining/$total scans restants',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF666666),
            ),
          ),
          if (result.bonusAvailable) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AuraColors.auraAmber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '+${result.bonusAmount} bonus',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AuraColors.auraAmber,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Badge compact pour afficher dans la top bar
class ScanLimitBadge extends ConsumerWidget {
  const ScanLimitBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limitAsync = ref.watch(canScanProvider);

    return limitAsync.when(
      data: (result) {
        // Ne rien afficher si Pro
        if (result.isPro) return const SizedBox.shrink();

        // Afficher un badge warning si proche de la limite
        if (result.remaining <= 2) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AuraColors.auraRed.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AuraColors.auraRed.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: AuraColors.auraRed,
                ),
                const SizedBox(width: 4),
                Text(
                  '${result.remaining} scan${result.remaining > 1 ? 's' : ''}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AuraColors.auraRed,
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Dialog affiché quand la limite est atteinte
class ScanLimitReachedDialog extends StatelessWidget {
  final VoidCallback? onWatchAd;
  final VoidCallback? onGoPro;

  const ScanLimitReachedDialog({
    super.key,
    this.onWatchAd,
    this.onGoPro,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AuraColors.auraAmber, AuraColors.auraDeep],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.lock_outline,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Limite atteinte',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous avez utilisé vos 5 scans gratuits ce mois-ci.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 24),
            AuraRewardedOfferCard(
              type: RewardType.scanBonus,
              onRewardEarned: () {
                Navigator.of(context).pop();
                onWatchAd?.call();
              },
              onProPressed: () {
                Navigator.of(context).pop();
                onGoPro?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}
