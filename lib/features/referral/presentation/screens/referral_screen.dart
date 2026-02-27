import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../data/models/referral_models.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  bool _isLoading = true;
  ReferralStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    // Simuler le chargement - remplacer par l'appel réel au repository
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _stats = ReferralStats(
        userId: 'user123',
        totalReferrals: 3,
        activeReferrals: 2,
        pendingReferrals: 1,
        totalClicks: 47,
        conversionRate: 6.4,
        currentStreak: 2,
        nextMilestoneAt: 5,
        nextMilestoneType: MilestoneType.fiveReferrals,
        nextMilestoneReward: '1 an Pro offert',
        milestones: [
          const ReferralMilestone(
            id: '1',
            userId: 'user123',
            milestoneType: MilestoneType.firstReferral,
            referralsRequired: 1,
            rewardType: RewardType.proMonth,
            rewardDescription: '1 mois Pro offert',
            achievedAt: null,
            claimed: false,
          ),
          const ReferralMilestone(
            id: '2',
            userId: 'user123',
            milestoneType: MilestoneType.fiveReferrals,
            referralsRequired: 5,
            rewardType: RewardType.proYear,
            rewardDescription: '1 an Pro offert',
            achievedAt: null,
            claimed: false,
          ),
        ],
        recentRewards: [],
        referralCode: const ReferralCode(
          id: 'code1',
          code: 'AURA-JOHN-7X9P',
          userId: 'user123',
          totalClicks: 47,
          totalSignups: 5,
          totalConversions: 3,
          createdAt: null,
          updatedAt: null,
        ),
      );
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraColors.auraBackground,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AuraColors.auraAmber.withOpacity(0.3),
                    AuraColors.auraDeep.withOpacity(0.2),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parrainage',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1 mois Pro offert pour vous et vos amis',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Code de parrainage
                  _buildReferralCodeCard(),
                  const SizedBox(height: 20),

                  // Stats
                  _buildStatsGrid(),
                  const SizedBox(height: 20),

                  // Progression vers prochain jalon
                  _buildMilestoneProgress(),
                  const SizedBox(height: 20),

                  // Historique récent
                  _buildRecentActivity(),
                  const SizedBox(height: 20),

                  // Comment ça marche
                  _buildHowItWorks(),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReferralCodeCard() {
    final code = _stats?.referralCode?.code ?? 'AURA-XXXX-XXXX';
    
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Votre code de parrainage',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AuraColors.auraAmber.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    code,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () {
                      HapticService.lightTap();
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Code copié !'),
                          backgroundColor: AuraColors.auraGreen,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, color: AuraColors.auraAmber),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildShareButton(
                    icon: Icons.share,
                    label: 'Partager',
                    onTap: () {
                      HapticService.mediumTap();
                      // Share plus
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildShareButton(
                    icon: Icons.message,
                    label: 'SMS',
                    onTap: () {
                      HapticService.mediumTap();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AuraColors.auraAmber.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AuraColors.auraAmber, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AuraColors.auraAmber,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.people,
            value: '${_stats?.totalReferrals ?? 0}',
            label: 'Parrainages',
            color: AuraColors.auraAmber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.mouse,
            value: '${_stats?.totalClicks ?? 0}',
            label: 'Clics',
            color: AuraColors.auraDeep,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.trending_up,
            value: '${_stats?.conversionRate.toStringAsFixed(1) ?? 0}%',
            label: 'Conversion',
            color: AuraColors.auraGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneProgress() {
    final current = _stats?.activeReferrals ?? 0;
    final target = _stats?.nextMilestoneAt ?? 5;
    final progress = current / target;
    
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Prochain objectif',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AuraColors.auraAmber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$current / $target',
                    style: const TextStyle(
                      color: AuraColors.auraAmber,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation(AuraColors.auraAmber),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _stats?.nextMilestoneReward ?? '1 an Pro offert',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Encore ${target - current} parrainage${target - current > 1 ? 's' : ''} !',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activité récente',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (_stats?.activeReferrals == 0)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 48,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aucun parrainage encore',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  _buildActivityItem(
                    name: 'Marie L.',
                    status: 'Actif',
                    date: 'Il y a 2 jours',
                    reward: '1 mois Pro',
                    isActive: true,
                  ),
                  _buildActivityItem(
                    name: 'Pierre D.',
                    status: 'En attente',
                    date: 'Il y a 5 jours',
                    reward: 'En attente',
                    isActive: false,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required String name,
    required String status,
    required String date,
    required String reward,
    required bool isActive,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive 
                  ? AuraColors.auraGreen.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isActive ? Icons.check_circle : Icons.hourglass_empty,
              color: isActive ? AuraColors.auraGreen : Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$status • $date',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? AuraColors.auraGreen.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              reward,
              style: TextStyle(
                color: isActive ? AuraColors.auraGreen : Colors.white.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comment ça marche ?',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            _buildStepItem(
              number: '1',
              title: 'Partagez votre code',
              description: 'Envoyez votre code unique à vos amis',
            ),
            _buildStepItem(
              number: '2',
              title: 'Ils s\'inscrivent',
              description: 'Vos amis créent leur compte avec votre code',
            ),
            _buildStepItem(
              number: '3',
              title: 'Vous recevez 1 mois Pro',
              description: 'Dès leur première transaction active',
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required String number,
    required String title,
    required String description,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AuraColors.auraAmber,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: AuraColors.auraAmber.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              if (!isLast) const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}