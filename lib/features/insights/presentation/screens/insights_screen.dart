import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/insight_model.dart';

/// Écran des insights IA
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  InsightFilter _selectedFilter = InsightFilter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraColors.auraBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Filtres
            _buildFilterChips(),

            const SizedBox(height: AuraDimensions.spaceM),

            // Liste des insights
            Expanded(
              child: _buildInsightsList(),
            ),
          ],
        ),
      ),
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
            child: Column(
              children: [
                Text(
                  'Insights IA',
                  style: AuraTypography.h3.copyWith(color: AuraColors.auraTextDark),
                ),
                Text(
                  'Analyses et recommandations',
                  style: AuraTypography.bodySmall.copyWith(
                    color: AuraColors.auraTextDarkSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              HapticService.lightTap();
              _markAllAsRead();
            },
            child: Text(
              'Tout lire',
              style: AuraTypography.labelMedium.copyWith(
                color: AuraColors.auraAmber,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceM),
      child: Row(
        children: InsightFilter.values.map((filter) {
          final isSelected = filter == _selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: AuraDimensions.spaceS),
            child: GestureDetector(
              onTap: () {
                HapticService.lightTap();
                setState(() => _selectedFilter = filter);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AuraDimensions.spaceM,
                  vertical: AuraDimensions.spaceS,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AuraColors.auraAmber
                      : AuraColors.auraGlass,
                  borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
                  border: isSelected
                      ? null
                      : Border.all(color: AuraColors.auraGlassBorder),
                ),
                child: Text(
                  filter.label,
                  style: AuraTypography.labelMedium.copyWith(
                    color: isSelected
                        ? Colors.white
                        : AuraColors.auraTextDark,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInsightsList() {
    // TODO: Remplacer par un vrai provider
    final mockInsights = _getMockInsights();

    if (mockInsights.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceM),
      itemCount: mockInsights.length,
      itemBuilder: (context, index) {
        final insight = mockInsights[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AuraDimensions.spaceM),
          child: InsightCard(
            insight: insight,
            onTap: () => _showInsightDetail(insight),
            onDismiss: () => _dismissInsight(insight),
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
              Icons.psychology_outlined,
              size: 48,
              color: AuraColors.auraAmber.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceL),
          Text(
            'Aucun insight pour le moment',
            style: AuraTypography.h4.copyWith(color: AuraColors.auraTextDark),
          ),
          const SizedBox(height: AuraDimensions.spaceS),
          Text(
            'L\'IA analyse vos habitudes financières...',
            style: AuraTypography.bodyMedium.copyWith(
              color: AuraColors.auraTextDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _markAllAsRead() {
    // TODO: Implémenter
    HapticService.success();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tous les insights ont été marqués comme lus'),
        backgroundColor: AuraColors.auraGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
        ),
      ),
    );
  }

  void _dismissInsight(Insight insight) {
    HapticService.lightTap();
    // TODO: Implémenter la suppression
  }

  void _showInsightDetail(Insight insight) {
    HapticService.mediumTap();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => InsightDetailSheet(insight: insight),
    );
  }

  List<Insight> _getMockInsights() {
    return [
      Insight(
        id: '1',
        userId: 'user1',
        type: InsightType.vampire,
        title: '🧛 Netflix a augmenté !',
        body: 'Votre abonnement Netflix est passé de 13,99€ à 17,99€ (+29%). C\'est la 2ème augmentation cette année.',
        data: {'old_price': 13.99, 'new_price': 17.99, 'service': 'Netflix'},
        priority: 2,
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Insight(
        id: '2',
        userId: 'user1',
        type: InsightType.prediction,
        title: '🔮 Prédiction : attention au 18',
        body: 'D\'après vos habitudes, votre solde sera de -120€ le 18 si vous maintenez ce rythme de dépenses.',
        data: {'date': '2024-01-18', 'predicted_balance': -120.0},
        priority: 1,
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Insight(
        id: '3',
        userId: 'user1',
        type: InsightType.tip,
        title: '💡 Astuce d\'économie',
        body: 'Vous dépensez en moyenne 45€/mois en cafés. En préparant votre café maison 2 jours sur 3, vous économiseriez 30€/mois.',
        priority: 5,
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Insight(
        id: '4',
        userId: 'user1',
        type: InsightType.achievement,
        title: '🏆 Objectif atteint !',
        body: 'Bravo ! Vous avez respecté votre budget Alimentation ce mois-ci. Continuez comme ça !',
        priority: 4,
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }
}

/// Carte d'insight
class InsightCard extends StatelessWidget {
  final Insight insight;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const InsightCard({
    super.key,
    required this.insight,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM', 'fr_FR');

    return Dismissible(
      key: Key(insight.id),
      direction: onDismiss != null ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        decoration: BoxDecoration(
          color: AuraColors.auraRed,
          borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AuraDimensions.spaceM),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss?.call(),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AuraDimensions.spaceM),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _parseColor(insight.typeColor).withOpacity(0.15),
                borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
              ),
              child: Center(
                child: Text(
                  insight.typeIcon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),

            const SizedBox(width: AuraDimensions.spaceM),

            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          insight.title,
                          style: AuraTypography.labelLarge.copyWith(
                            color: AuraColors.auraTextDark,
                            fontWeight: insight.isRead ? FontWeight.w400 : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!insight.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AuraColors.auraAmber,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AuraDimensions.spaceXS),
                  Text(
                    insight.body,
                    style: AuraTypography.bodyMedium.copyWith(
                      color: AuraColors.auraTextDarkSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AuraDimensions.spaceS),
                  Text(
                    dateFormat.format(insight.createdAt),
                    style: AuraTypography.caption.copyWith(
                      color: AuraColors.auraTextDarkSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Flèche
            Icon(
              Icons.chevron_right,
              color: AuraColors.auraTextDarkSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AuraColors.auraAmber;
    }
  }
}

/// Bottom sheet de détail d'insight
class InsightDetailSheet extends StatelessWidget {
  final Insight insight;

  const InsightDetailSheet({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
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
            margin: const EdgeInsets.only(top: AuraDimensions.spaceS),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AuraColors.auraTextDarkSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AuraDimensions.spaceXL),
              child: Column(
                children: [
                  // Icône
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _parseColor(insight.typeColor).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AuraDimensions.radiusXXL),
                    ),
                    child: Center(
                      child: Text(
                        insight.typeIcon,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),

                  const SizedBox(height: AuraDimensions.spaceL),

                  // Titre
                  Text(
                    insight.title,
                    style: AuraTypography.h2.copyWith(
                      color: AuraColors.auraTextDark,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AuraDimensions.spaceM),

                  // Contenu
                  Text(
                    insight.body,
                    style: AuraTypography.bodyLarge.copyWith(
                      color: AuraColors.auraTextDarkSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AuraDimensions.spaceXL),

                  // Actions selon le type
                  _buildActions(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    switch (insight.type) {
      case InsightType.vampire:
        return Column(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Contester la hausse
              },
              icon: const Icon(Icons.warning_amber),
              label: const Text('Contester la hausse'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AuraColors.auraRed,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: AuraDimensions.spaceS),
            TextButton(
              onPressed: () {
                // TODO: Voir alternatives
              },
              child: const Text('Voir les alternatives'),
            ),
          ],
        );
      case InsightType.prediction:
        return ElevatedButton.icon(
          onPressed: () {
            context.goToBudgets();
          },
          icon: const Icon(Icons.savings),
          label: const Text('Ajuster mon budget'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        );
      case InsightType.tip:
        return ElevatedButton.icon(
          onPressed: () {
            // TODO: Appliquer le conseil
          },
          icon: const Icon(Icons.check),
          label: const Text('Appliquer ce conseil'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AuraColors.auraAmber;
    }
  }
}
