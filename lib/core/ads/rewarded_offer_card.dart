import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../haptics/haptic_service.dart';
import '../theme/aura_colors.dart';
import '../widgets/glass_card.dart';
import 'interstitial_ad_service.dart';

/// Carte d'offre de publicité récompensée
/// 
/// Affichée dans le flux quand l'utilisateur atteint une limite.
/// Design glassmorphique avec deux options :
/// 1. Regarder une pub pour un bonus temporaire
/// 2. Passer à Aura Pro pour un accès illimité
/// 
/// Usage:
/// ```dart
/// AuraRewardedOfferCard(
///   type: RewardType.scanBonus,
///   onRewardEarned: () => reloadScans(),
///   onProPressed: () => showPaywall(),
/// )
/// ```
class AuraRewardedOfferCard extends StatefulWidget {
  /// Type de récompense proposée
  final RewardType type;

  /// Callback quand la récompense est gagnée
  final VoidCallback? onRewardEarned;

  /// Callback quand l'utilisateur choisit de passer Pro
  final VoidCallback? onProPressed;

  /// Si true, affiche un indicateur de chargement
  final bool isLoading;

  const AuraRewardedOfferCard({
    super.key,
    required this.type,
    this.onRewardEarned,
    this.onProPressed,
    this.isLoading = false,
  });

  @override
  State<AuraRewardedOfferCard> createState() => _AuraRewardedOfferCardState();
}

class _AuraRewardedOfferCardState extends State<AuraRewardedOfferCard> {
  bool _isWatching = false;

  Future<void> _watchAd() async {
    if (_isWatching) return;

    setState(() => _isWatching = true);
    HapticService.mediumTap();

    final result = await rewardedAdService.showForReward(widget.type);

    setState(() => _isWatching = false);

    if (result == RewardResult.rewarded) {
      widget.onRewardEarned?.call();
    }
  }

  void _goPro() {
    HapticService.lightTap();
    widget.onProPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec icône cadeau
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AuraColors.auraAmber,
                      AuraColors.auraDeep,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vous avez atteint votre limite',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.type.description,
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

          const SizedBox(height: 20),

          // Bouton regarder une pub
          _buildWatchAdButton(),

          const SizedBox(height: 12),

          // Séparateur "ou"
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: const Color(0xFFE0E0E0),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'ou',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF888888),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: const Color(0xFFE0E0E0),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Bouton passer Pro
          _buildProButton(),
        ],
      ),
    );
  }

  Widget _buildWatchAdButton() {
    return GestureDetector(
      onTap: _isWatching ? null : _watchAd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AuraColors.auraAmber,
              AuraColors.auraDeep,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AuraColors.auraAmber.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: _isWatching
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Regarder 1 pub pour ${widget.type.displayName}',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildProButton() {
    return GestureDetector(
      onTap: _goPro,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AuraColors.auraAmber,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.workspace_premium,
                color: AuraColors.auraAmber,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Passer à Aura Pro — illimité',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AuraColors.auraAmber,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Version compacte de la carte (pour les listes)
class AuraRewardedOfferCardCompact extends StatelessWidget {
  final RewardType type;
  final VoidCallback? onRewardEarned;
  final VoidCallback? onProPressed;

  const AuraRewardedOfferCardCompact({
    super.key,
    required this.type,
    this.onRewardEarned,
    this.onProPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AuraColors.auraAmber,
                  AuraColors.auraDeep,
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.card_giftcard,
              color: Colors.white,
              size: 20,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  'Regarder une pub pour ${type.displayName}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              HapticService.mediumTap();
              final result = await rewardedAdService.showForReward(type);
              if (result == RewardResult.rewarded) {
                onRewardEarned?.call();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AuraColors.auraAmber,
                    AuraColors.auraDeep,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '▶',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
