import 'dart:math' show pi, sin;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/app_localizations_extension.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/felix/widgets/felix_with_confetti.dart';
import '../../domain/friend_challenge_models.dart';
import '../providers/friend_challenge_provider.dart';

/// Écran des défis entre amis
/// Permet de créer, rejoindre et suivre des défis compétitifs
class FriendChallengesScreen extends ConsumerStatefulWidget {
  const FriendChallengesScreen({super.key});

  @override
  ConsumerState<FriendChallengesScreen> createState() => _FriendChallengesScreenState();
}

class _FriendChallengesScreenState extends ConsumerState<FriendChallengesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraColors.auraBackground,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AuraColors.auraBackground,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: AuraColors.auraAmber,
                indicatorWeight: 3,
                labelColor: AuraColors.auraAmber,
                unselectedLabelColor: AuraColors.auraTextDarkSecondary,
                labelStyle: AuraTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Actifs'),
                  Tab(text: 'Invitations'),
                  Tab(text: 'Terminés'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildActiveChallenges(),
            _buildInvitations(),
            _buildCompletedChallenges(),
          ],
        ),
      ),
      floatingActionButton: _buildCreateButton(),
    );
  }

  Widget _buildHeader() {
    final statsAsync = ref.watch(userChallengeStatsProvider);

    return Container(
      padding: const EdgeInsets.all(AuraDimensions.spaceL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AuraColors.auraAmber.withOpacity(0.2),
            AuraColors.auraDeep.withOpacity(0.1),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Défis entre amis',
                      style: AuraTypography.h3.copyWith(
                        color: AuraColors.auraTextDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Qui sera le meilleur gestionnaire ?',
                      style: AuraTypography.bodyMedium.copyWith(
                        color: AuraColors.auraTextDarkSecondary,
                      ),
                    ),
                  ],
                ),
                // Avatar avec streak
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AuraColors.auraAmber, AuraColors.auraDeep],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AuraColors.auraAmber.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.emoji_events,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AuraDimensions.spaceL),
            statsAsync.when(
              data: (stats) => _buildStatsRow(stats),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(UserChallengeStats stats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('Victoires', stats.wins.toString(), Icons.emoji_events),
        _buildStatItem('Défis', stats.totalChallenges.toString(), Icons.games),
        _buildStatItem('Série', '${stats.currentStreak}🔥', Icons.local_fire_department),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AuraColors.auraAmber, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: AuraTypography.h4.copyWith(
            color: AuraColors.auraTextDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: AuraTypography.labelSmall.copyWith(
            color: AuraColors.auraTextDarkSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveChallenges() {
    final challengesAsync = ref.watch(activeFriendChallengesProvider);

    return challengesAsync.when(
      data: (challenges) {
        if (challenges.isEmpty) {
          return _buildEmptyState(
            icon: Icons.games_outlined,
            title: 'Aucun défi actif',
            subtitle: 'Crée ton premier défi et défie tes amis !',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AuraDimensions.spaceM),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            return _buildChallengeCard(challenges[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('Erreur: $error'),
      ),
    );
  }

  Widget _buildInvitations() {
    final invitationsAsync = ref.watch(challengeInvitationsProvider);

    return invitationsAsync.when(
      data: (invitations) {
        if (invitations.isEmpty) {
          return _buildEmptyState(
            icon: Icons.mail_outline,
            title: 'Pas d\'invitations',
            subtitle: 'Tu recevras les invitations ici',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AuraDimensions.spaceM),
          itemCount: invitations.length,
          itemBuilder: (context, index) {
            return _buildInvitationCard(invitations[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('Erreur: $error'),
      ),
    );
  }

  Widget _buildCompletedChallenges() {
    final challengesAsync = ref.watch(completedFriendChallengesProvider);

    return challengesAsync.when(
      data: (challenges) {
        if (challenges.isEmpty) {
          return _buildEmptyState(
            icon: Icons.history,
            title: 'Aucun défi terminé',
            subtitle: 'Les défis terminés apparaissent ici',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AuraDimensions.spaceM),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            return _buildCompletedChallengeCard(challenges[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('Erreur: $error'),
      ),
    );
  }

  Widget _buildChallengeCard(FriendChallenge challenge) {
    final daysLeft = challenge.endDate.difference(DateTime.now()).inDays;
    final isWinning = challenge.participants.any(
      (p) => p.isWinner && p.userId == 'current_user_id',
    );

    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        _showChallengeDetail(challenge);
      },
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: AuraDimensions.spaceM),
        borderRadius: AuraDimensions.radiusXL,
        padding: const EdgeInsets.all(AuraDimensions.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getChallengeColor(challenge.type),
                        _getChallengeColor(challenge.type).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
                  ),
                  child: Icon(
                    _getChallengeIcon(challenge.type),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AuraDimensions.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: AuraTypography.labelLarge.copyWith(
                          color: AuraColors.auraTextDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        challenge.description,
                        style: AuraTypography.bodySmall.copyWith(
                          color: AuraColors.auraTextDarkSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isWinning)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AuraColors.auraAccentGold,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AuraDimensions.spaceM),
            // Barre de progression
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _calculateProgress(challenge),
                backgroundColor: AuraColors.auraGlass,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getChallengeColor(challenge.type),
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: AuraDimensions.spaceS),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 16,
                      color: AuraColors.auraTextDarkSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${challenge.participants.length} participants',
                      style: AuraTypography.labelSmall.copyWith(
                        color: AuraColors.auraTextDarkSecondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: daysLeft <= 1
                        ? AuraColors.auraRed.withOpacity(0.1)
                        : AuraColors.auraAmber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    daysLeft <= 0
                        ? 'Termine aujourd\'hui'
                        : daysLeft == 1
                            ? '1 jour restant'
                            : '$daysLeft jours restants',
                    style: AuraTypography.labelSmall.copyWith(
                      color: daysLeft <= 1
                          ? AuraColors.auraRed
                          : AuraColors.auraAmber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationCard(ChallengeInvitation invitation) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: AuraDimensions.spaceM),
      borderRadius: AuraDimensions.radiusXL,
      padding: const EdgeInsets.all(AuraDimensions.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AuraColors.auraAmber,
                      AuraColors.auraDeep,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
                ),
                child: const Icon(
                  Icons.person_add,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: AuraDimensions.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitation.inviterName,
                      style: AuraTypography.labelLarge.copyWith(
                        color: AuraColors.auraTextDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'T\'invite à rejoindre',
                      style: AuraTypography.bodySmall.copyWith(
                        color: AuraColors.auraTextDarkSecondary,
                      ),
                    ),
                    Text(
                      invitation.challengeTitle,
                      style: AuraTypography.labelMedium.copyWith(
                        color: AuraColors.auraAmber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AuraDimensions.spaceM),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticService.lightTap();
                    ref.read(friendChallengeControllerProvider.notifier)
                        .acceptInvitation(invitation.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AuraColors.auraAmber, AuraColors.auraDeep],
                      ),
                      borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
                    ),
                    child: const Center(
                      child: Text(
                        'Accepter',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AuraDimensions.spaceM),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticService.lightTap();
                    ref.read(friendChallengeControllerProvider.notifier)
                        .declineInvitation(invitation.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AuraColors.auraGlass,
                      borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
                    ),
                    child: const Center(
                      child: Text(
                        'Refuser',
                        style: TextStyle(
                          color: AuraColors.auraTextDark,
                          fontWeight: FontWeight.w600,
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

  Widget _buildCompletedChallengeCard(FriendChallenge challenge) {
    final isWinner = challenge.participants.any(
      (p) => p.userId == 'current_user_id' && p.isWinner,
    );

    return GlassCard(
      margin: const EdgeInsets.only(bottom: AuraDimensions.spaceM),
      borderRadius: AuraDimensions.radiusXL,
      padding: const EdgeInsets.all(AuraDimensions.spaceM),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isWinner
                    ? [AuraColors.auraAccentGold, AuraColors.auraAmber]
                    : [AuraColors.auraGlass, AuraColors.auraGlass],
              ),
              borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
            ),
            child: Icon(
              isWinner ? Icons.emoji_events : Icons.check_circle,
              color: isWinner ? Colors.white : AuraColors.auraTextDarkSecondary,
              size: 32,
            ),
          ),
          const SizedBox(width: AuraDimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.title,
                  style: AuraTypography.labelLarge.copyWith(
                    color: AuraColors.auraTextDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isWinner ? 'Victoire ! 🎉' : 'Terminé',
                  style: AuraTypography.bodySmall.copyWith(
                    color: isWinner ? AuraColors.auraAccentGold : AuraColors.auraTextDarkSecondary,
                    fontWeight: isWinner ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (challenge.reward != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AuraColors.auraAccentGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                challenge.reward!,
                style: AuraTypography.labelSmall.copyWith(
                  color: AuraColors.auraAccentGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AuraDimensions.spaceXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AuraColors.auraTextDarkSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: AuraDimensions.spaceM),
            Text(
              title,
              style: AuraTypography.h4.copyWith(
                color: AuraColors.auraTextDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuraDimensions.spaceS),
            Text(
              subtitle,
              style: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.auraTextDarkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return GestureDetector(
      onTap: () {
        HapticService.mediumTap();
        _showCreateChallengeDialog();
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AuraColors.auraAmber, AuraColors.auraDeep],
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AuraColors.auraAmber.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  void _showChallengeDetail(FriendChallenge challenge) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ChallengeDetailSheet(challenge: challenge),
    );
  }

  void _showCreateChallengeDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreateChallengeSheet(),
    );
  }

  // Helpers
  double _calculateProgress(FriendChallenge challenge) {
    final total = challenge.endDate.difference(challenge.startDate).inDays;
    final elapsed = DateTime.now().difference(challenge.startDate).inDays;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  Color _getChallengeColor(ChallengeType type) {
    return switch (type) {
      ChallengeType.mostSavings => AuraColors.auraGreen,
      ChallengeType.leastSpending => AuraColors.auraAmber,
      ChallengeType.noSpendDays => AuraColors.auraDeep,
      ChallengeType.raceToGoal => AuraColors.auraAccentGold,
      ChallengeType.streak => AuraColors.auraRed,
      ChallengeType.custom => AuraColors.auraAmber,
    };
  }

  IconData _getChallengeIcon(ChallengeType type) {
    return switch (type) {
      ChallengeType.mostSavings => Icons.savings,
      ChallengeType.leastSpending => Icons.trending_down,
      ChallengeType.noSpendDays => Icons.block,
      ChallengeType.raceToGoal => Icons.emoji_events,
      ChallengeType.streak => Icons.local_fire_department,
      ChallengeType.custom => Icons.edit,
    };
  }
}

/// Sheet de détail d'un défi
class _ChallengeDetailSheet extends ConsumerWidget {
  final FriendChallenge challenge;

  const _ChallengeDetailSheet({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(challengeLeaderboardProvider(challenge.id));

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AuraColors.auraBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AuraDimensions.radiusXXL),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: AuraDimensions.spaceM),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AuraColors.auraTextDarkSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Contenu
          Expanded(
            child: leaderboardAsync.when(
              data: (leaderboard) => _buildLeaderboard(leaderboard),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Erreur: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard(ChallengeLeaderboard leaderboard) {
    return ListView.builder(
      padding: const EdgeInsets.all(AuraDimensions.spaceM),
      itemCount: leaderboard.entries.length,
      itemBuilder: (context, index) {
        final entry = leaderboard.entries[index];
        return _buildLeaderboardEntry(entry, index);
      },
    );
  }

  Widget _buildLeaderboardEntry(LeaderboardEntry entry, int index) {
    final isTop3 = index < 3;
    final rankColors = [
      AuraColors.auraAccentGold,
      const Color(0xFFC0C0C0), // Argent
      const Color(0xFFCD7F32), // Bronze
    ];

    return GlassCard(
      margin: const EdgeInsets.only(bottom: AuraDimensions.spaceS),
      borderRadius: AuraDimensions.radiusL,
      padding: const EdgeInsets.all(AuraDimensions.spaceM),
      child: Row(
        children: [
          // Rang
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isTop3
                  ? rankColors[index].withOpacity(0.2)
                  : AuraColors.auraGlass,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: AuraTypography.labelLarge.copyWith(
                  color: isTop3 ? rankColors[index] : AuraColors.auraTextDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AuraDimensions.spaceM),
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundImage: entry.avatarUrl != null
                ? NetworkImage(entry.avatarUrl!)
                : null,
            backgroundColor: AuraColors.auraAmber,
            child: entry.avatarUrl == null
                ? Text(
                    entry.displayName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
                Text(
                  entry.displayName,
                  style: AuraTypography.labelLarge.copyWith(
                    color: AuraColors.auraTextDark,
                    fontWeight: entry.isCurrentUser
                        ? FontWeight.w700
                        : FontWeight.w600,
                  ),
                ),
                if (entry.isCurrentUser)
                  Text(
                    'Toi',
                    style: AuraTypography.labelSmall.copyWith(
                      color: AuraColors.auraAmber,
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
                entry.score.toStringAsFixed(0),
                style: AuraTypography.h4.copyWith(
                  color: AuraColors.auraTextDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${(entry.progress * 100).toStringAsFixed(0)}%',
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
}

/// Sheet de création de défi
class _CreateChallengeSheet extends ConsumerStatefulWidget {
  const _CreateChallengeSheet();

  @override
  ConsumerState<_CreateChallengeSheet> createState() => _CreateChallengeSheetState();
}

class _CreateChallengeSheetState extends ConsumerState<_CreateChallengeSheet> {
  ChallengeType _selectedType = ChallengeType.mostSavings;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AuraColors.auraBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AuraDimensions.radiusXXL),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: AuraDimensions.spaceM),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AuraColors.auraTextDarkSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(AuraDimensions.spaceL),
            child: Text(
              'Nouveau défi',
              style: AuraTypography.h3.copyWith(
                color: AuraColors.auraTextDark,
              ),
            ),
          ),
          // Types de défis
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceM),
              itemCount: ChallengeType.values.length,
              itemBuilder: (context, index) {
                final type = ChallengeType.values[index];
                final isSelected = type == _selectedType;

                return GestureDetector(
                  onTap: () {
                    HapticService.lightTap();
                    setState(() => _selectedType = type);
                  },
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: AuraDimensions.spaceM),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [AuraColors.auraAmber, AuraColors.auraDeep],
                            )
                          : null,
                      color: isSelected ? null : AuraColors.auraGlass,
                      borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          type.icon,
                          color: isSelected
                              ? Colors.white
                              : AuraColors.auraTextDarkSecondary,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          type.label.split(' ').first,
                          style: AuraTypography.labelSmall.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AuraColors.auraTextDark,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceL),
          // Formulaire
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AuraDimensions.spaceM),
              child: Column(
                children: [
                  _buildTextField(
                    controller: _titleController,
                    label: 'Titre du défi',
                    hint: 'Ex: Qui économise le plus en janvier ?',
                  ),
                  const SizedBox(height: AuraDimensions.spaceM),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Décris les règles du défi...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: AuraDimensions.spaceL),
                  // Date de fin
                  _buildDatePicker(),
                ],
              ),
            ),
          ),
          // Bouton créer
          Padding(
            padding: const EdgeInsets.all(AuraDimensions.spaceM),
            child: GestureDetector(
              onTap: _createChallenge,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AuraColors.auraAmber, AuraColors.auraDeep],
                  ),
                  borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
                ),
                child: const Center(
                  child: Text(
                    'Créer le défi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AuraTypography.labelMedium.copyWith(
            color: AuraColors.auraTextDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AuraColors.auraGlass,
            borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.auraTextDarkSecondary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(AuraDimensions.spaceM),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _endDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() => _endDate = date);
        }
      },
      child: GlassCard(
        padding: const EdgeInsets.all(AuraDimensions.spaceM),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              color: AuraColors.auraAmber,
            ),
            const SizedBox(width: AuraDimensions.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date de fin',
                    style: AuraTypography.labelSmall.copyWith(
                      color: AuraColors.auraTextDarkSecondary,
                    ),
                  ),
                  Text(
                    '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                    style: AuraTypography.labelLarge.copyWith(
                      color: AuraColors.auraTextDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AuraColors.auraTextDarkSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _createChallenge() {
    HapticService.mediumTap();
    
    ref.read(friendChallengeControllerProvider.notifier).createChallenge(
      type: _selectedType,
      title: _titleController.text.isEmpty
          ? _selectedType.label
          : _titleController.text,
      description: _descriptionController.text,
      endDate: _endDate,
    );

    Navigator.pop(context);
  }
}
