import 'dart:math' show pi, sin;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/app_localizations_extension.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/felix/felix_controller.dart';
import '../../../../core/felix/felix_animation_type.dart';

/// Story Viewer pour les récaps financiers
/// Format Stories Instagram-like avec swipe vertical
class FinancialStoryViewer extends ConsumerStatefulWidget {
  final List<FinancialStory> stories;
  final int initialIndex;

  const FinancialStoryViewer({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<FinancialStoryViewer> createState() => _FinancialStoryViewerState();
}

class _FinancialStoryViewerState extends ConsumerState<FinancialStoryViewer>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  int _currentIndex = 0;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _initializeAnimations();
    
    // Félix en mode story
    Future.delayed(const Duration(milliseconds: 500), () {
      ref.read(felixControllerProvider.notifier).setAnimation(
        FelixAnimationType.idle,
        message: 'Ton récap de la semaine !',
      );
    });
  }

  void _initializeAnimations() {
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.linear,
      ),
    );
    
    // Démarre automatiquement
    _startStory();
  }

  void _startStory() {
    _progressController.forward().then((_) {
      if (_currentIndex < widget.stories.length - 1) {
        _nextStory();
      } else {
        _finishStories();
      }
    });
  }

  void _pauseStory() {
    setState(() => _isPaused = true);
    _progressController.stop();
  }

  void _resumeStory() {
    setState(() => _isPaused = false);
    _progressController.forward();
  }

  void _nextStory() {
    HapticService.lightTap();
    if (_currentIndex < widget.stories.length - 1) {
      _progressController.reset();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentIndex++);
      _startStory();
    } else {
      _finishStories();
    }
  }

  void _previousStory() {
    HapticService.lightTap();
    if (_currentIndex > 0) {
      _progressController.reset();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentIndex--);
      _startStory();
    }
  }

  void _finishStories() {
    HapticService.success();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) => _pauseStory(),
        onTapUp: (details) => _resumeStory(),
        child: Stack(
          children: [
            // Contenu des stories
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.stories.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                return _buildStoryPage(widget.stories[index]);
              },
            ),
            
            // Header avec progression
            _buildStoryHeader(),
            
            // Indicateurs de progression
            _buildProgressIndicators(),
            
            // Indicateurs de swipe (gauche/droite)
            if (_currentIndex > 0)
              _buildSwipeIndicator(Alignment.centerLeft, Icons.arrow_back_ios),
            if (_currentIndex < widget.stories.length - 1)
              _buildSwipeIndicator(Alignment.centerRight, Icons.arrow_forward_ios),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryHeader() {
    final currentStory = widget.stories[_currentIndex];
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AuraDimensions.spaceM),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Avatar et nom
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AuraColors.auraAmber, AuraColors.auraDeep],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.insights,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: AuraDimensions.spaceM),
                Text(
                  currentStory.title,
                  style: AuraTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            // Bouton fermer
            GestureDetector(
              onTap: () {
                HapticService.lightTap();
                Navigator.pop(context);
              },
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicators() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AuraDimensions.spaceM),
        child: Row(
          children: List.generate(widget.stories.length, (index) {
            return Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: index == _currentIndex
                    ? AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _isPaused
                                ? _progressAnimation.value
                                : _progressAnimation.value,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AuraColors.auraAmber, AuraColors.auraAccentGold],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        },
                      )
                    : index < _currentIndex
                        ? Container(
                            decoration: BoxDecoration(
                              color: AuraColors.auraAmber,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          )
                        : null,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSwipeIndicator(Alignment alignment, IconData icon) {
    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.all(AuraDimensions.spaceL),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildStoryPage(FinancialStory story) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            story.backgroundColor,
            story.backgroundColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Contenu principal
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AuraDimensions.spaceXL,
                vertical: 100,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icône
                  if (story.icon != null)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            story.iconColor.withOpacity(0.2),
                            story.iconColor.withOpacity(0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        story.icon,
                        size: 64,
                        color: story.iconColor,
                      ),
                    ),
                  
                  const SizedBox(height: AuraDimensions.spaceXXL),
                  
                  // Titre principal
                  Text(
                    story.mainText,
                    style: AuraTypography.h1.copyWith(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: AuraDimensions.spaceL),
                  
                  // Sous-titre
                  if (story.subText != null)
                    Text(
                      story.subText!,
                      style: AuraTypography.bodyLarge.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  
                  const SizedBox(height: AuraDimensions.spaceXXL),
                  
                  // Métrique clé
                  if (story.metricValue != null)
                    _buildMetricCard(story),
                  
                  const SizedBox(height: AuraDimensions.spaceXXL),
                  
                  // Insights
                  if (story.insights.isNotEmpty)
                    _buildInsightsSection(story.insights),
                ],
              ),
            ),
          ),
          
          // Badge spécial
          if (story.isHighlight)
            Positioned(
              top: 100,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AuraColors.auraAccentGold, AuraColors.auraAmber],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  story.highlightLabel ?? '🏆',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(FinancialStory story) {
    return GlassCard(
      padding: const EdgeInsets.all(AuraDimensions.spaceXL),
      borderRadius: AuraDimensions.radiusXL,
      blurStrength: 20,
      child: Column(
        children: [
          Text(
            story.metricValue!,
            style: AuraTypography.h1.copyWith(
              color: story.iconColor,
              fontSize: 48,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceS),
          Text(
            story.metricLabel ?? '',
            style: AuraTypography.labelLarge.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(List<StoryInsight> insights) {
    return Column(
      children: [
        Text(
          '💡 Insights',
          style: AuraTypography.labelLarge.copyWith(
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AuraDimensions.spaceM),
        ...insights.map((insight) => _buildInsightItem(insight)),
      ],
    );
  }

  Widget _buildInsightItem(StoryInsight insight) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AuraDimensions.spaceS),
      padding: const EdgeInsets.all(AuraDimensions.spaceM),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
      ),
      child: Row(
        children: [
          Icon(
            insight.icon,
            color: insight.color,
            size: 20,
          ),
          const SizedBox(width: AuraDimensions.spaceM),
          Expanded(
            child: Text(
              insight.text,
              style: AuraTypography.bodyMedium.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modèle d'une story financière
class FinancialStory {
  final String id;
  final String title;
  final String mainText;
  final String? subText;
  final IconData? icon;
  final Color iconColor;
  final Color backgroundColor;
  final String? metricValue;
  final String? metricLabel;
  final bool isHighlight;
  final String? highlightLabel;
  final List<StoryInsight> insights;

  FinancialStory({
    required this.id,
    required this.title,
    required this.mainText,
    this.subText,
    this.icon,
    this.iconColor = Colors.white,
    this.backgroundColor = Colors.black,
    this.metricValue,
    this.metricLabel,
    this.isHighlight = false,
    this.highlightLabel,
    this.insights = const [],
  });
}

/// Insight dans une story
class StoryInsight {
  final String text;
  final IconData icon;
  final Color color;

  StoryInsight({
    required this.text,
    required this.icon,
    this.color = Colors.white,
  });
}

/// Générateur de stories hebdomadaires
class WeeklyStoryGenerator {
  static List<FinancialStory> generateWeeklyStories({
    required double weeklySpending,
    required double monthlyBalance,
    required double savingsRate,
    required int streakDays,
    required List<String> topCategories,
    required Map<String, double> categorySpending,
  }) {
    final stories = <FinancialStory>[];

    // Story 1: Solde actuel
    stories.add(FinancialStory(
      id: 'balance',
      title: 'Ton récap de la semaine',
      mainText: 'Solde actuel',
      icon: Icons.account_balance_wallet,
      iconColor: AuraColors.auraAccentGold,
      backgroundColor: const Color(0xFF1a1a2e),
      metricValue: '${monthlyBalance.toStringAsFixed(0)}€',
      metricLabel: 'disponibles',
      insights: [
        StoryInsight(
          text: 'Continue comme ça !',
          icon: Icons.trending_up,
          color: AuraColors.auraGreen,
        ),
      ],
    ));

    // Story 2: Dépenses de la semaine
    stories.add(FinancialStory(
      id: 'spending',
      title: 'Dépenses hebdo',
      mainText: 'Cette semaine',
      icon: Icons.shopping_cart,
      iconColor: AuraColors.auraRed,
      backgroundColor: const Color(0xFF16213e),
      metricValue: '${weeklySpending.toStringAsFixed(0)}€',
      metricLabel: 'dépensés',
      isHighlight: weeklySpending < 100,
      highlightLabel: '🔥 Eco',
      insights: [
        StoryInsight(
          text: 'Moins que la semaine dernière',
          icon: Icons.arrow_downward,
          color: AuraColors.auraGreen,
        ),
      ],
    ));

    // Story 3: Top catégorie
    if (topCategories.isNotEmpty) {
      final topCat = topCategories.first;
      final amount = categorySpending[topCat] ?? 0;
      
      stories.add(FinancialStory(
        id: 'top_category',
        title: 'Catégorie préférée',
        mainText: topCat,
        icon: _getCategoryIcon(topCat),
        iconColor: AuraColors.auraAmber,
        backgroundColor: const Color(0xFF0f3460),
        metricValue: '${amount.toStringAsFixed(0)}€',
        metricLabel: 'cette semaine',
        insights: [
          StoryInsight(
            text: 'Tu y passes le plus',
            icon: Icons.emoji_events,
            color: AuraColors.auraAccentGold,
          ),
        ],
      ));
    }

    // Story 4: Taux d'épargne
    stories.add(FinancialStory(
      id: 'savings',
      title: 'Taux d\'épargne',
      mainText: 'Tu économises',
      icon: Icons.savings,
      iconColor: AuraColors.auraGreen,
      backgroundColor: const Color(0xFF533483),
      metricValue: '${(savingsRate * 100).toStringAsFixed(0)}%',
      metricLabel: 'de tes revenus',
      isHighlight: savingsRate > 0.2,
      highlightLabel: '💎 Pro',
      insights: [
        StoryInsight(
          text: 'Objectif 20% atteint !',
          icon: Icons.check_circle,
          color: AuraColors.auraGreen,
        ),
      ],
    ));

    // Story 5: Série de connexion
    stories.add(FinancialStory(
      id: 'streak',
      title: 'Série de connexion',
      mainText: '$streakDays jours',
      icon: Icons.local_fire_department,
      iconColor: AuraColors.auraRed,
      backgroundColor: const Color(0xFFe94560),
      metricValue: '$streakDays',
      metricLabel: 'jours d\'affilée',
      isHighlight: streakDays >= 7,
      highlightLabel: '🔥 Hot',
      insights: [
        StoryInsight(
          text: 'Reste régulier !',
          icon: Icons.thumb_up,
          color: Colors.white,
        ),
      ],
    ));

    return stories;
  }

  static IconData _getCategoryIcon(String category) {
    return switch (category.toLowerCase()) {
      'food' || 'restaurant' => Icons.restaurant,
      'transport' => Icons.directions_car,
      'housing' => Icons.home,
      'entertainment' => Icons.movie,
      'shopping' => Icons.shopping_bag,
      'health' => Icons.local_hospital,
      'subscription' => Icons.subscriptions,
      'travel' => Icons.flight,
      'utilities' => Icons.bolt,
      _ => Icons.category,
    };
  }
}
