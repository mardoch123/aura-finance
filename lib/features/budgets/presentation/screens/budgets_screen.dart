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
import '../../domain/budget_goal_model.dart';

/// Écran de gestion des objectifs budgétaires
class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  @override
  Widget build(BuildContext context) {
    // TODO: Remplacer par un vrai provider
    final goals = _getMockGoals();
    final completedGoals = goals.where((g) => g.isCompleted).length;

    return Scaffold(
      backgroundColor: AuraColors.auraBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Stats
            _buildStats(goals, completedGoals),

            const SizedBox(height: AuraDimensions.spaceL),

            // Liste des objectifs
            Expanded(
              child: _buildGoalsList(goals),
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
            child: Text(
              context.l10n.goals,
              style: AuraTypography.h3.copyWith(color: AuraColors.auraTextDark),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildStats(List<BudgetGoal> goals, int completed) {
    final totalTarget = goals.fold<double>(0, (sum, g) => sum + g.targetAmount);
    final totalCurrent = goals.fold<double>(0, (sum, g) => sum + g.currentAmount);
    final progress = totalTarget > 0 ? (totalCurrent / totalTarget * 100) : 0;

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
                    '${goals.length}',
                    style: AuraTypography.h2.copyWith(
                      color: AuraColors.auraTextDark,
                    ),
                  ),
                  Text(
                    context.l10n.goals,
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
                    '$completed',
                    style: AuraTypography.h2.copyWith(
                      color: AuraColors.auraGreen,
                    ),
                  ),
                  Text(
                    context.l10n.achieved,
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
                    '${progress.toStringAsFixed(0)}%',
                    style: AuraTypography.h2.copyWith(
                      color: AuraColors.auraAmber,
                    ),
                  ),
                  Text(
                    context.l10n.progress,
                    style: AuraTypography.bodySmall.copyWith(
                      color: AuraColors.auraTextDarkSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList(List<BudgetGoal> goals) {
    if (goals.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceM),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goal = goals[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AuraDimensions.spaceM),
          child: GoalCard(
            goal: goal,
            onTap: () => _showGoalDetail(goal),
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
              Icons.flag_outlined,
              size: 48,
              color: AuraColors.auraAmber.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceL),
          Text(
            context.l10n.noGoals,
            style: AuraTypography.h4.copyWith(color: AuraColors.auraTextDark),
          ),
          const SizedBox(height: AuraDimensions.spaceS),
          Text(
            context.l10n.createFirstGoal,
            style: AuraTypography.bodyMedium.copyWith(
              color: AuraColors.auraTextDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        HapticService.mediumTap();
        _showAddGoalDialog();
      },
      backgroundColor: AuraColors.auraAmber,
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(
        context.l10n.newGoal,
        style: AuraTypography.labelMedium.copyWith(color: Colors.white),
      ),
    );
  }

  void _showGoalDetail(BudgetGoal goal) {
    HapticService.mediumTap();
    // TODO: Modal de détail
  }

  void _showAddGoalDialog() {
    HapticService.lightTap();
    // TODO: Modal d'ajout
  }

  List<BudgetGoal> _getMockGoals() {
    return [
      BudgetGoal(
        id: '1',
        userId: 'user1',
        name: 'Fonds d\'urgence',
        description: 'Épargne de précaution',
        targetAmount: 5000,
        currentAmount: 3200,
        goalType: GoalType.savings,
        color: '#58D68D',
        deadline: DateTime.now().add(const Duration(days: 90)),
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
      ),
      BudgetGoal(
        id: '2',
        userId: 'user1',
        name: 'Vacances été',
        description: 'Voyage en Italie',
        targetAmount: 2000,
        currentAmount: 1500,
        goalType: GoalType.savings,
        color: '#3498DB',
        deadline: DateTime.now().add(const Duration(days: 45)),
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      BudgetGoal(
        id: '3',
        userId: 'user1',
        name: 'Nouveau MacBook',
        description: 'Pour le travail',
        targetAmount: 2500,
        currentAmount: 2500,
        goalType: GoalType.savings,
        color: '#9B59B6',
        isCompleted: true,
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
      ),
      BudgetGoal(
        id: '4',
        userId: 'user1',
        name: 'Budget Alimentation',
        description: 'Limiter les dépenses',
        targetAmount: 400,
        currentAmount: 380,
        goalType: GoalType.spendingLimit,
        color: '#E74C3C',
        alertThreshold: 80,
        isRecurring: true,
        recurringPeriod: 'monthly',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ];
  }
}

/// Carte d'objectif
class GoalCard extends StatelessWidget {
  final BudgetGoal goal;
  final VoidCallback? onTap;

  const GoalCard({
    super.key,
    required this.goal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 0,
    );
    final progress = goal.progressPercentage / 100;

    return GlassCard(
      onTap: onTap,
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
                  color: Color(goal.colorValue).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
                ),
                child: Center(
                  child: Text(
                    goal.goalType.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),

              const SizedBox(width: AuraDimensions.spaceM),

              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            goal.name,
                            style: AuraTypography.labelLarge.copyWith(
                              color: AuraColors.auraTextDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (goal.isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AuraColors.auraGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check,
                                  size: 12,
                                  color: AuraColors.auraGreen,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  context.l10n.reached,
                                  style: AuraTypography.caption.copyWith(
                                    color: AuraColors.auraGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (goal.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        goal.description!,
                        style: AuraTypography.bodySmall.copyWith(
                          color: AuraColors.auraTextDarkSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AuraDimensions.spaceM),

          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(AuraDimensions.radiusXS),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AuraColors.auraGlass,
              valueColor: AlwaysStoppedAnimation<Color>(
                goal.isAlertTriggered && !goal.isCompleted
                    ? AuraColors.auraRed
                    : Color(goal.colorValue),
              ),
              minHeight: 8,
            ),
          ),

          const SizedBox(height: AuraDimensions.spaceS),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${goal.progressPercentage.toStringAsFixed(0)}%',
                style: AuraTypography.labelMedium.copyWith(
                  color: AuraColors.auraTextDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${currencyFormat.format(goal.currentAmount)} / ${currencyFormat.format(goal.targetAmount)}',
                style: AuraTypography.bodySmall.copyWith(
                  color: AuraColors.auraTextDarkSecondary,
                ),
              ),
            ],
          ),

          // Alertes
          if (goal.isAlertTriggered && !goal.isCompleted) ...[
            const SizedBox(height: AuraDimensions.spaceS),
            Container(
              padding: const EdgeInsets.all(AuraDimensions.spaceS),
              decoration: BoxDecoration(
                color: AuraColors.auraRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: AuraColors.auraRed,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      goal.goalType == GoalType.spendingLimit
                          ? 'Vous avez atteint ${goal.alertThreshold?.toStringAsFixed(0)}% de votre limite'
                          : 'Objectif en retard',
                      style: AuraTypography.bodySmall.copyWith(
                        color: AuraColors.auraRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Deadline
          if (goal.deadline != null && !goal.isCompleted) ...[
            const SizedBox(height: AuraDimensions.spaceS),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: goal.isDeadlineNear || goal.isOverdue
                      ? AuraColors.auraRed
                      : AuraColors.auraTextDarkSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  goal.isOverdue
                      ? context.l10n.deadlineExceeded
                      : (goal.daysRemaining == 1 
                          ? context.l10n.daysRemaining_one.replaceAll('{count}', goal.daysRemaining.toString())
                          : context.l10n.daysRemaining_other.replaceAll('{count}', goal.daysRemaining.toString())),
                  style: AuraTypography.caption.copyWith(
                    color: goal.isDeadlineNear || goal.isOverdue
                        ? AuraColors.auraRed
                        : AuraColors.auraTextDarkSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
