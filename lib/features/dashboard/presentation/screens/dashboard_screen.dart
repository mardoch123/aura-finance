import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/animations/hero_number.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/models/dashboard_models.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/prediction_chart.dart';
import '../widgets/insight_card.dart';
import '../widgets/recent_transactions_list.dart';
import '../widgets/goals_progress_section.dart';

/// Écran principal du Dashboard avec SliverAppBar collapsible
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    HapticService.mediumTap();
    await ref.read(dashboardNotifierProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardNotifierProvider);
    final unreadCountAsync = ref.watch(unreadInsightsCountProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AuraColors.auraBackground,
              Color(0xFFF8EBD8),
              Color(0xFFF5E0C8),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Cercles d'ambiance en arrière-plan
            _buildBackgroundCircles(),
            
            // Contenu principal
            RefreshIndicator(
              onRefresh: _onRefresh,
              color: AuraColors.auraAmber,
              backgroundColor: Colors.white,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // SliverAppBar expansible
                  _buildSliverAppBar(unreadCountAsync),
                  
                  // Contenu du dashboard
                  SliverToBoxAdapter(
                    child: dashboardAsync.when(
                      data: (state) => _buildDashboardContent(state),
                      loading: () => _buildLoadingState(),
                      error: (error, _) => _buildErrorState(error.toString()),
                    ),
                  ),
                  
                  // Espace en bas pour la bottom nav
                  const SliverPadding(
                    padding: EdgeInsets.only(bottom: 100),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundCircles() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // Cercle haut droit
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AuraColors.auraAmber.withOpacity(0.15),
                      AuraColors.auraAmber.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Cercle milieu gauche
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              left: -150,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AuraColors.auraDeep.withOpacity(0.1),
                      AuraColors.auraDeep.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Cercle bas droit
            Positioned(
              bottom: 100,
              right: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AuraColors.auraAccentGold.withOpacity(0.12),
                      AuraColors.auraAccentGold.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(AsyncValue<int> unreadCountAsync) {
    final unreadCount = unreadCountAsync.valueOrNull ?? 0;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      floating: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        expandedTitleScale: 1.0,
        background: _buildExpandedHeader(),
        title: _buildCollapsedHeader(unreadCount),
      ),
      actions: [
        // Icône notification avec badge
        Stack(
          children: [
            IconButton(
              onPressed: () {
                HapticService.lightTap();
                context.goToInsights();
              },
              icon: const Icon(
                Icons.notifications_outlined,
                color: AuraColors.auraTextDark,
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: AuraColors.auraRed,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        // Avatar utilisateur
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () {
              HapticService.lightTap();
              context.goToProfile();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://api.dicebear.com/7.x/avataaars/svg?seed=aura',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedHeader() {
    final dashboardAsync = ref.watch(dashboardNotifierProvider);
    final state = dashboardAsync.valueOrNull;
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label
              Text(
                'SOLDE TOTAL',
                style: AuraTypography.labelSmall.copyWith(
                  color: AuraColors.auraTextDarkSecondary,
                  letterSpacing: 2,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Solde avec animation
              if (state != null)
                HeroNumber(
                  value: state.totalBalance,
                  prefix: '',
                  suffix: '€',
                  decimals: 2,
                  style: AuraTypography.hero.copyWith(
                    color: AuraColors.auraTextDark,
                    fontWeight: FontWeight.w300,
                    fontSize: 52,
                  ),
                )
              else
                Text(
                  '---',
                  style: AuraTypography.hero.copyWith(
                    color: AuraColors.auraTextDark,
                    fontSize: 52,
                  ),
                ),
              
              const SizedBox(height: 12),
              
              // Delta du mois
              if (state != null)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: state.monthlyDelta >= 0
                            ? AuraColors.auraGreen.withOpacity(0.15)
                            : AuraColors.auraRed.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${state.monthlyDelta >= 0 ? '+' : ''}${state.monthlyDelta.toStringAsFixed(0)}€ ce mois',
                        style: AuraTypography.labelMedium.copyWith(
                          color: state.monthlyDelta >= 0
                              ? AuraColors.auraGreen
                              : AuraColors.auraRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedHeader(int unreadCount) {
    final dashboardAsync = ref.watch(dashboardNotifierProvider);
    final state = dashboardAsync.valueOrNull;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Aura Finance',
          style: AuraTypography.h4.copyWith(
            color: AuraColors.auraTextDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (state != null) ...[
          const SizedBox(width: 12),
          Text(
            '${state.totalBalance.toStringAsFixed(0)}€',
            style: AuraTypography.labelLarge.copyWith(
              color: AuraColors.auraAmber,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  /// Actions rapides pour accéder aux fonctionnalités principales
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions rapides',
            style: AuraTypography.labelSmall.copyWith(
              color: AuraColors.auraTextDarkSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceS),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.smart_toy,
                  label: 'Coach IA',
                  color: AuraColors.auraAmber,
                  onTap: () {
                    HapticService.lightTap();
                    context.goToCoach();
                  },
                ),
              ),
              const SizedBox(width: AuraDimensions.spaceS),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.account_balance_wallet,
                  label: 'Comptes',
                  color: AuraColors.auraDeep,
                  onTap: () {
                    HapticService.lightTap();
                    context.goToAccounts();
                  },
                ),
              ),
              const SizedBox(width: AuraDimensions.spaceS),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.savings,
                  label: 'Objectifs',
                  color: AuraColors.auraGreen,
                  onTap: () {
                    HapticService.lightTap();
                    context.goToBudgets();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(DashboardState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AuraDimensions.spaceM),

        // Actions Rapides
        _buildQuickActions(),

        const SizedBox(height: AuraDimensions.spaceL),
        
        // Carte de prédiction
        if (state.prediction != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AuraDimensions.spaceM,
            ),
            child: GlassCard(
              borderRadius: AuraDimensions.radiusXL,
              padding: const EdgeInsets.all(AuraDimensions.spaceM),
              child: PredictionChart(prediction: state.prediction!),
            ),
          ),
        
        const SizedBox(height: AuraDimensions.spaceL),
        
        // Insights IA
        if (state.unreadInsights.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AuraDimensions.spaceM,
            ),
            child: Row(
              children: [
                Text(
                  'Insights IA',
                  style: AuraTypography.h4.copyWith(
                    color: AuraColors.auraTextDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AuraColors.auraAmber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${state.unreadInsights.length}',
                    style: AuraTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceM),
          InsightsCarousel(
            insights: state.unreadInsights,
            onInsightTap: (insight) {
              HapticService.lightTap();
              // TODO: Navigation vers détail insight
            },
            onInsightDismiss: (insight) {
              ref.read(dashboardNotifierProvider.notifier)
                  .markInsightAsRead(insight.id);
            },
          ),
          const SizedBox(height: AuraDimensions.spaceL),
        ],
        
        // Objectifs
        if (state.budgetGoals.isNotEmpty) ...[
          GoalsProgressSection(
            goals: state.budgetGoals,
            onGoalTap: (goal) {
              HapticService.lightTap();
              context.goToBudgets();
            },
          ),
          const SizedBox(height: AuraDimensions.spaceL),
        ],
        
        // Transactions récentes
        RecentTransactionsList(
          transactions: state.recentTransactions,
          onTransactionTap: (transaction) {
            HapticService.lightTap();
            context.goToTransactionDetail(transaction.id);
          },
          onViewAll: () {
            HapticService.lightTap();
            context.goToTransactions();
          },
        ),
        
        const SizedBox(height: AuraDimensions.spaceXL),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const SizedBox(height: AuraDimensions.spaceM),
        // Skeleton pour la carte de prédiction
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AuraDimensions.spaceM,
          ),
          child: GlassCard(
            height: 280,
            borderRadius: AuraDimensions.radiusXL,
            child: const Center(
              child: CircularProgressIndicator(
                color: AuraColors.auraAmber,
              ),
            ),
          ),
        ),
        const SizedBox(height: AuraDimensions.spaceL),
        // Skeleton pour transactions
        const TransactionsShimmer(),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: AuraDimensions.paddingXL,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AuraColors.auraRed.withOpacity(0.5),
            ),
            const SizedBox(height: AuraDimensions.spaceM),
            Text(
              'Oups ! Une erreur est survenue',
              style: AuraTypography.h4.copyWith(
                color: AuraColors.auraTextDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuraDimensions.spaceS),
            Text(
              error,
              style: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.auraTextDarkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuraDimensions.spaceL),
            ElevatedButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton d'action rapide pour le dashboard
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          vertical: AuraDimensions.spaceM,
          horizontal: AuraDimensions.spaceS,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AuraTypography.labelSmall.copyWith(
                color: AuraColors.auraTextDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
