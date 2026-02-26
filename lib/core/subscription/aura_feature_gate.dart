import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../ads/ads.dart';
import '../haptics/haptic_service.dart';
import '../theme/aura_colors.dart';
import '../widgets/glass_card.dart';
import 'feature_gate_service.dart';

/// Widget de contrôle d'accès aux features
/// 
/// Wrap n'importe quelle feature avec ce widget pour gérer
/// automatiquement les limites freemium et les accès Pro.
/// 
/// Usage:
/// ```dart
/// AuraFeatureGate(
///   feature: AuraFeature.scanner,
///   isPro: false, // depuis le provider
///   child: ScannerButton(),
///   lockedBuilder: (context, reason) => ScannerButton(locked: true),
///   onLocked: () => showRewardedOrPaywall(context),
/// )
/// ```
class AuraFeatureGate extends ConsumerStatefulWidget {
  /// Feature à protéger
  final AuraFeature feature;

  /// Si l'utilisateur est Pro
  final bool isPro;

  /// Widget enfant (affiché si accès autorisé)
  final Widget child;

  /// Builder pour l'état verrouillé (optionnel)
  final Widget Function(BuildContext context, FeatureGateReason reason)?
      lockedBuilder;

  /// Callback quand la feature est verrouillée
  final VoidCallback? onLocked;

  /// Si true, affiche une carte de récompense au lieu de verrouiller
  final bool showRewardCard;

  /// Callback quand la récompense est gagnée
  final VoidCallback? onRewardEarned;

  const AuraFeatureGate({
    super.key,
    required this.feature,
    required this.isPro,
    required this.child,
    this.lockedBuilder,
    this.onLocked,
    this.showRewardCard = true,
    this.onRewardEarned,
  });

  @override
  ConsumerState<AuraFeatureGate> createState() => _AuraFeatureGateState();
}

class _AuraFeatureGateState extends ConsumerState<AuraFeatureGate> {
  FeatureGateResult? _result;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    final result = await _checkFeature();
    setState(() {
      _result = result;
      _isLoading = false;
    });
  }

  Future<FeatureGateResult> _checkFeature() async {
    switch (widget.feature) {
      case AuraFeature.scanner:
        return await featureGateService.checkScanLimit(isPro: widget.isPro);
      case AuraFeature.coach:
        return await featureGateService.checkCoachLimit(isPro: widget.isPro);
      case AuraFeature.predictions:
        return featureGateService.checkPredictions(isPro: widget.isPro);
      case AuraFeature.export:
        return featureGateService.checkExport(isPro: widget.isPro);
      case AuraFeature.multiAccounts:
        // Nécessite le nombre de comptes actuels
        return featureGateService.checkMultiAccounts(
          isPro: widget.isPro,
          currentAccounts: 1, // TODO: Récupérer depuis le provider
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.child;
    }

    final result = _result!;

    if (result.allowed) {
      return widget.child;
    }

    // Feature verrouillée
    if (widget.lockedBuilder != null) {
      return widget.lockedBuilder!(context, result.reason);
    }

    // Afficher la carte de récompense si applicable
    if (widget.showRewardCard &&
        result.reason == FeatureGateReason.limitReached) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLimitIndicator(result),
          const SizedBox(height: 12),
          _buildRewardCard(result),
        ],
      );
    }

    // Afficher l'indicateur simple
    return _buildLimitIndicator(result);
  }

  Widget _buildLimitIndicator(FeatureGateResult result) {
    final percentage = result.limit > 0
        ? (result.currentUsage / result.limit * 100).clamp(0, 100)
        : 100.0;

    Color progressColor;
    if (percentage < 60) {
      progressColor = AuraColors.auraAmber;
    } else if (percentage < 90) {
      progressColor = AuraColors.auraOrange;
    } else {
      progressColor = AuraColors.auraRed;
    }

    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        widget.onLocked?.call();
      },
      child: GlassCard(
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  widget.feature.icon,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${result.currentUsage}/${result.limit} ${widget.feature.displayName.toLowerCase()} utilisés',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF666666),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticService.mediumTap();
                    widget.onLocked?.call();
                  },
                  child: Text(
                    '🔓 Illimité avec Pro',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AuraColors.auraAmber,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Barre de progression fine
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: const Color(0xFFE0E0E0),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardCard(FeatureGateResult result) {
    RewardType rewardType;
    switch (widget.feature) {
      case AuraFeature.scanner:
        rewardType = RewardType.scanBonus;
        break;
      case AuraFeature.coach:
        rewardType = RewardType.coachBonus;
        break;
      default:
        return const SizedBox.shrink();
    }

    return AuraRewardedOfferCard(
      type: rewardType,
      onRewardEarned: () {
        widget.onRewardEarned?.call();
        _checkAccess(); // Rafraîchir
      },
      onProPressed: widget.onLocked,
    );
  }
}

/// Badge de limite pour afficher dans les top bars
class AuraLimitBadge extends ConsumerStatefulWidget {
  final AuraFeature feature;
  final bool isPro;

  const AuraLimitBadge({
    super.key,
    required this.feature,
    required this.isPro,
  });

  @override
  ConsumerState<AuraLimitBadge> createState() => _AuraLimitBadgeState();
}

class _AuraLimitBadgeState extends ConsumerState<AuraLimitBadge> {
  FeatureGateResult? _result;

  @override
  void initState() {
    super.initState();
    _checkLimit();
  }

  Future<void> _checkLimit() async {
    FeatureGateResult result;
    switch (widget.feature) {
      case AuraFeature.scanner:
        result = await featureGateService.checkScanLimit(isPro: widget.isPro);
        break;
      case AuraFeature.coach:
        result = await featureGateService.checkCoachLimit(isPro: widget.isPro);
        break;
      default:
        return;
    }

    setState(() {
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPro) return const SizedBox.shrink();
    if (_result == null) return const SizedBox.shrink();

    final result = _result!;
    final remaining = result.remaining;

    // Afficher uniquement si proche de la limite (≤ 2)
    if (remaining > 2) return const SizedBox.shrink();

    Color badgeColor;
    if (remaining == 0) {
      badgeColor = AuraColors.auraRed;
    } else if (remaining == 1) {
      badgeColor = AuraColors.auraOrange;
    } else {
      badgeColor = AuraColors.auraAmber;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: badgeColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            remaining == 0 ? Icons.lock_outline : Icons.warning_amber_rounded,
            size: 14,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            remaining == 0
                ? 'Limite atteinte'
                : '$remaining ${widget.feature.displayName.toLowerCase()}',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Overlay pour le Coach quand la limite est atteinte
class CoachLimitOverlay extends StatelessWidget {
  final VoidCallback? onWatchAd;
  final VoidCallback? onGoPro;

  const CoachLimitOverlay({
    super.key,
    this.onWatchAd,
    this.onGoPro,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AuraColors.auraAmber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  color: AuraColors.auraAmber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Limite atteinte',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      'Coach Pro illimité 🤖',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onWatchAd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AuraColors.auraAmber,
                          AuraColors.auraDeep,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'Débloquer pour aujourd\'hui',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onGoPro,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AuraColors.auraAmber,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Voir Aura Pro',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AuraColors.auraAmber,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
