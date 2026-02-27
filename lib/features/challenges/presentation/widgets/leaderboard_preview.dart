import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../data/models/challenge_models.dart';

/// Aperçu du classement entre amis
class LeaderboardPreview extends ConsumerWidget {
  const LeaderboardPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Connect to actual provider
    final mockEntries = _getMockEntries();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceM),
      children: [
        // Podium (top 3)
        if (mockEntries.length >= 3) _buildPodium(mockEntries.take(3).toList()),

        const SizedBox(height: AuraDimensions.spaceL),

        // Liste complète
        Text(
          'Classement complet',
          style: AuraTypography.h4.copyWith(
            color: AuraColors.auraTextDark,
          ),
        ),
        const SizedBox(height: AuraDimensions.spaceM),

        ...mockEntries.map((entry) => _buildLeaderboardRow(entry)),

        const SizedBox(height: AuraDimensions.spaceXL),

        // Info
        Center(
          child: Text(
            'Le classement se réinitialise chaque semaine',
            style: AuraTypography.bodySmall.copyWith(
              color: AuraColors.auraTextDarkSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> top3) {
    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 2ème place
          _buildPodiumItem(
            rank: 2,
            entry: top3[1],
            height: 120,
            color: const Color(0xFFC0C0C0), // Argent
          ),
          const SizedBox(width: AuraDimensions.spaceM),
          // 1ère place
          _buildPodiumItem(
            rank: 1,
            entry: top3[0],
            height: 160,
            color: const Color(0xFFFFD700), // Or
            isFirst: true,
          ),
          const SizedBox(width: AuraDimensions.spaceM),
          // 3ème place
          _buildPodiumItem(
            rank: 3,
            entry: top3[2],
            height: 100,
            color: const Color(0xFFCD7F32), // Bronze
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem({
    required int rank,
    required LeaderboardEntry entry,
    required double height,
    required Color color,
    bool isFirst = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Avatar
        Container(
          width: isFirst ? 72 : 56,
          height: isFirst ? 72 : 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: isFirst ? 4 : 3,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
            image: entry.userAvatar != null
                ? DecorationImage(
                    image: NetworkImage(entry.userAvatar!),
                    fit: BoxFit.cover,
                  )
                : null,
            color: AuraColors.auraAmber,
          ),
          child: entry.userAvatar == null
              ? Center(
                  child: Text(
                    entry.userName?.substring(0, 1).toUpperCase() ?? '?',
                    style: AuraTypography.h3.copyWith(
                      color: Colors.white,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: AuraDimensions.spaceS),

        // Nom
        Text(
          entry.userName ?? 'Utilisateur',
          style: AuraTypography.labelMedium.copyWith(
            color: AuraColors.auraTextDark,
            fontWeight: FontWeight.w600,
          ),
        ),

        // Score
        Text(
          '${entry.score.toInt()} XP',
          style: AuraTypography.bodySmall.copyWith(
            color: AuraColors.auraTextDarkSecondary,
          ),
        ),

        const SizedBox(height: AuraDimensions.spaceS),

        // Podium
        Container(
          width: isFirst ? 100 : 80,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withOpacity(0.8),
                color.withOpacity(0.4),
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AuraDimensions.radiusM),
            ),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: AuraTypography.hero.copyWith(
                color: Colors.white,
                fontSize: isFirst ? 48 : 32,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardRow(LeaderboardEntry entry) {
    final isCurrentUser = entry.rank == 5; // Simuler l'utilisateur courant

    return GlassCard(
      margin: const EdgeInsets.only(bottom: AuraDimensions.spaceS),
      borderRadius: AuraDimensions.radiusL,
      padding: const EdgeInsets.all(AuraDimensions.spaceM),
      child: Row(
        children: [
          // Rang
          SizedBox(
            width: 40,
            child: Text(
              entry.rankEmoji,
              style: AuraTypography.h4.copyWith(
                fontSize: 24,
              ),
            ),
          ),

          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: entry.userAvatar != null
                  ? DecorationImage(
                      image: NetworkImage(entry.userAvatar!),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: AuraColors.auraAmber,
            ),
            child: entry.userAvatar == null
                ? Center(
                    child: Text(
                      entry.userName?.substring(0, 1).toUpperCase() ?? '?',
                      style: AuraTypography.labelLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AuraDimensions.spaceM),

          // Nom
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.userName ?? 'Utilisateur',
                      style: AuraTypography.labelLarge.copyWith(
                        color: AuraColors.auraTextDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AuraColors.auraAmber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'VOUS',
                          style: AuraTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (entry.details.isNotEmpty)
                  Text(
                    '${entry.details['challenges_completed'] ?? 0} défis complétés',
                    style: AuraTypography.bodySmall.copyWith(
                      color: AuraColors.auraTextDarkSecondary,
                    ),
                  ),
              ],
            ),
          ),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.score.toInt()}',
                style: AuraTypography.h4.copyWith(
                  color: AuraColors.auraAmber,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'XP',
                style: AuraTypography.labelSmall.copyWith(
                  color: AuraColors.auraTextDarkSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<LeaderboardEntry> _getMockEntries() {
    return [
      LeaderboardEntry(
        id: '1',
        leaderboardId: 'lb1',
        userId: 'user1',
        rank: 1,
        score: 2850,
        userName: 'Marie L.',
        details: {'challenges_completed': 12},
      ),
      LeaderboardEntry(
        id: '2',
        leaderboardId: 'lb1',
        userId: 'user2',
        rank: 2,
        score: 2340,
        userName: 'Thomas D.',
        details: {'challenges_completed': 10},
      ),
      LeaderboardEntry(
        id: '3',
        leaderboardId: 'lb1',
        userId: 'user3',
        rank: 3,
        score: 2100,
        userName: 'Sophie M.',
        details: {'challenges_completed': 9},
      ),
      LeaderboardEntry(
        id: '4',
        leaderboardId: 'lb1',
        userId: 'user4',
        rank: 4,
        score: 1890,
        userName: 'Lucas B.',
        details: {'challenges_completed': 8},
      ),
      LeaderboardEntry(
        id: '5',
        leaderboardId: 'lb1',
        userId: 'current',
        rank: 5,
        score: 1250,
        userName: 'Vous',
        details: {'challenges_completed': 5},
      ),
      LeaderboardEntry(
        id: '6',
        leaderboardId: 'lb1',
        userId: 'user6',
        rank: 6,
        score: 980,
        userName: 'Emma R.',
        details: {'challenges_completed': 4},
      ),
      LeaderboardEntry(
        id: '7',
        leaderboardId: 'lb1',
        userId: 'user7',
        rank: 7,
        score: 750,
        userName: 'Hugo P.',
        details: {'challenges_completed': 3},
      ),
    ];
  }
}
