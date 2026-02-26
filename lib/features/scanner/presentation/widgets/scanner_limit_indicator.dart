import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/subscription/subscription.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../features/subscription/subscription.dart';

/// Indicateur de limite de scans pour le Scanner
/// 
/// Affiche discrètement le compteur de scans utilisés.
/// Non-agressif, design glassmorphique avec barre de progression.
/// 
/// Usage:
/// ```dart
/// ScannerLimitIndicator(isPro: false)
/// ```
class ScannerLimitIndicator extends ConsumerStatefulWidget {
  final bool isPro;

  const ScannerLimitIndicator({
    super.key,
    required this.isPro,
  });

  @override
  ConsumerState<ScannerLimitIndicator> createState() =>
      _ScannerLimitIndicatorState();
}

class _ScannerLimitIndicatorState extends ConsumerState<ScannerLimitIndicator> {
  FeatureGateResult? _result;

  @override
  void initState() {
    super.initState();
    _loadUsage();
  }

  Future<void> _loadUsage() async {
    final result = await featureGateService.checkScanLimit(
      isPro: widget.isPro,
    );
    setState(() {
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ne rien afficher si Pro
    if (widget.isPro) return const SizedBox.shrink();

    // Loading state
    if (_result == null) {
      return const SizedBox(
        width: 120,
        height: 20,
        child: LinearProgressIndicator(
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(AuraColors.auraAmber),
        ),
      );
    }

    final result = _result!;
    final used = result.currentUsage;
    final limit = result.limit;
    final remaining = result.remaining;

    // Calculer le pourcentage
    final percentage = limit > 0 ? (used / limit * 100).clamp(0, 100) : 0.0;

    // Couleur selon l'usage
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
        // Afficher le paywall
        PaywallService.show(
          context,
          trigger: PaywallTrigger.manualFromProfile,
        );
      },
      child: GlassCard(
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  size: 14,
                  color: progressColor,
                ),
                const SizedBox(width: 6),
                Text(
                  '$used/$limit scans ce mois',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF666666),
                  ),
                ),
                if (result.hasBonus) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AuraColors.auraGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '+bonus',
                      style: GoogleFonts.dmSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AuraColors.auraGreen,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            // Barre de progression fine
            SizedBox(
              width: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: const Color(0xFFE0E0E0),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 3,
                ),
              ),
            ),
            if (remaining <= 2 && remaining > 0) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  PaywallService.show(
                    context,
                    trigger: PaywallTrigger.scanLimitReached,
                  );
                },
                child: Text(
                  '🔓 Illimité avec Pro',
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
      ),
    );
  }
}

/// Version compacte pour la top bar
class ScannerLimitIndicatorCompact extends ConsumerStatefulWidget {
  final bool isPro;

  const ScannerLimitIndicatorCompact({
    super.key,
    required this.isPro,
  });

  @override
  ConsumerState<ScannerLimitIndicatorCompact> createState() =>
      _ScannerLimitIndicatorCompactState();
}

class _ScannerLimitIndicatorCompactState
    extends ConsumerState<ScannerLimitIndicatorCompact> {
  FeatureGateResult? _result;

  @override
  void initState() {
    super.initState();
    _loadUsage();
  }

  Future<void> _loadUsage() async {
    final result = await featureGateService.checkScanLimit(
      isPro: widget.isPro,
    );
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

    // Afficher uniquement si proche de la limite
    if (remaining > 2) return const SizedBox.shrink();

    Color badgeColor;
    IconData icon;
    if (remaining == 0) {
      badgeColor = AuraColors.auraRed;
      icon = Icons.lock_outline;
    } else {
      badgeColor = AuraColors.auraOrange;
      icon = Icons.warning_amber_rounded;
    }

    return GestureDetector(
      onTap: () {
        PaywallService.show(
          context,
          trigger: PaywallTrigger.scanLimitReached,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: badgeColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: badgeColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: badgeColor,
            ),
            const SizedBox(width: 4),
            Text(
              remaining == 0 ? 'Limite' : '$remaining scans',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: badgeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
