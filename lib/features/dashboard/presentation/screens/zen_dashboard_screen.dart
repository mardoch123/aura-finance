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
import '../../../../core/felix/felix_controller.dart';
import '../../../../core/felix/felix_animation_type.dart';
import '../providers/dashboard_provider.dart';

/// Dashboard en mode "Zen" - Visualisation minimaliste sans chiffres
/// Utilise uniquement des couleurs et formes pour représenter la santé financière
class ZenDashboardScreen extends ConsumerStatefulWidget {
  const ZenDashboardScreen({super.key});

  @override
  ConsumerState<ZenDashboardScreen> createState() => _ZenDashboardScreenState();
}

class _ZenDashboardScreenState extends ConsumerState<ZenDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _waveController;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    
    // Félix en mode zen
    Future.delayed(const Duration(seconds: 1), () {
      ref.read(felixControllerProvider.notifier).setAnimation(
        FelixAnimationType.idle,
        message: 'Mode Zen activé 🧘',
        subMessage: 'Respire et observe',
      );
    });
  }

  void _initializeAnimations() {
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _breathingAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardNotifierProvider);

    return Scaffold(
      backgroundColor: AuraColors.auraBackground,
      body: dashboardAsync.when(
        data: (state) => _buildZenContent(state),
        loading: () => _buildZenLoading(),
        error: (error, _) => _buildZenError(),
      ),
    );
  }

  Widget _buildZenContent(DashboardState state) {
    final healthScore = _calculateHealthScore(state);
    final mood = _getMoodFromScore(healthScore);

    return Stack(
      children: [
        // Fond animé avec la "respiration" financière
        _buildBreathingBackground(healthScore),

        // Contenu principal
        SafeArea(
          child: Column(
            children: [
              // Header minimaliste
              _buildZenHeader(),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(AuraDimensions.spaceL),
                    child: Column(
                      children: [
                        // Cercle principal d'humeur
                        _buildMoodCircle(mood, healthScore),

                        const SizedBox(height: AuraDimensions.spaceXXL),

                        // Visualisation des catégories (sans chiffres)
                        _buildCategoryFlow(state),

                        const SizedBox(height: AuraDimensions.spaceXXL),

                        // Flux de trésorerie (vagues)
                        _buildCashFlowWaves(state),

                        const SizedBox(height: AuraDimensions.spaceXXL),

                        // Conseil du jour
                        _buildDailyWisdom(mood),

                        const SizedBox(height: AuraDimensions.spaceXXL),

                        // Actions rapides zen
                        _buildZenActions(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreathingBackground(double healthScore) {
    final baseColor = _getColorFromScore(healthScore);

    return AnimatedBuilder(
      animation: _breathingController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.3),
              radius: 0.8 + (_breathingAnimation.value - 1) * 0.2,
              colors: [
                baseColor.withOpacity(0.3 * _breathingAnimation.value),
                AuraColors.auraBackground,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildZenHeader() {
    return Padding(
      padding: const EdgeInsets.all(AuraDimensions.spaceM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bouton retour mode normal
          GestureDetector(
            onTap: () {
              HapticService.lightTap();
              context.goToDashboard();
            },
            child: GlassCard(
              padding: const EdgeInsets.all(AuraDimensions.spaceS),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.dashboard_outlined,
                    color: AuraColors.auraTextDark,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mode Normal',
                    style: AuraTypography.labelMedium.copyWith(
                      color: AuraColors.auraTextDark,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Indicateur Zen
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AuraDimensions.spaceM,
              vertical: AuraDimensions.spaceXS,
            ),
            decoration: BoxDecoration(
              color: AuraColors.auraAmber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.spa,
                  color: AuraColors.auraAmber,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'ZEN',
                  style: AuraTypography.labelSmall.copyWith(
                    color: AuraColors.auraAmber,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodCircle(ZenMood mood, double score) {
    return AnimatedBuilder(
      animation: _breathingController,
      builder: (context, child) {
        return Transform.scale(
          scale: _breathingAnimation.value,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  mood.centerColor,
                  mood.outerColor,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: mood.centerColor.withOpacity(0.4),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    mood.icon,
                    size: 64,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(height: AuraDimensions.spaceM),
                  Text(
                    mood.label,
                    style: AuraTypography.h3.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: AuraDimensions.spaceXS),
                  Text(
                    mood.description,
                    style: AuraTypography.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryFlow(DashboardState state) {
    // Simule les catégories avec des tailles relatives
    final categories = [
      _CategoryBubble('Nourriture', 0.3, AuraColors.auraAmber),
      _CategoryBubble('Transport', 0.2, AuraColors.auraDeep),
      _CategoryBubble('Logement', 0.35, AuraColors.auraDark),
      _CategoryBubble('Loisirs', 0.15, AuraColors.auraAccentGold),
    ];

    return GlassCard(
      borderRadius: AuraDimensions.radiusXL,
      padding: const EdgeInsets.all(AuraDimensions.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Équilibre',
            style: AuraTypography.labelSmall.copyWith(
              color: AuraColors.auraTextDarkSecondary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceL),
          Wrap(
            spacing: AuraDimensions.spaceM,
            runSpacing: AuraDimensions.spaceM,
            children: categories.map((cat) => _buildCategoryBubble(cat)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBubble(_CategoryBubble category) {
    final size = 60 + (category.ratio * 100);

    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        final offset = sin(_waveController.value * 2 * pi + category.ratio * 10) * 5;

        return Transform.translate(
          offset: Offset(0, offset),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: category.color.withOpacity(0.3),
              border: Border.all(
                color: category.color.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                category.name,
                style: AuraTypography.labelSmall.copyWith(
                  color: category.color,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCashFlowWaves(DashboardState state) {
    final isPositive = state.monthlyDelta >= 0;

    return GlassCard(
      borderRadius: AuraDimensions.radiusXL,
      padding: const EdgeInsets.all(AuraDimensions.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Flux',
            style: AuraTypography.labelSmall.copyWith(
              color: AuraColors.auraTextDarkSecondary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceL),
          SizedBox(
            height: 100,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(double.infinity, 100),
                  painter: _WavePainter(
                    progress: _waveController.value,
                    isPositive: isPositive,
                    color: isPositive ? AuraColors.auraGreen : AuraColors.auraRed,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceM),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive ? AuraColors.auraGreen : AuraColors.auraRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isPositive ? 'Tendance positive' : 'Tendance à surveiller',
                style: AuraTypography.labelMedium.copyWith(
                  color: isPositive ? AuraColors.auraGreen : AuraColors.auraRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyWisdom(ZenMood mood) {
    final wisdoms = {
      ZenMood.excellent: [
        'Ta discipline porte ses fruits',
        'Continue sur cette belle lancée',
        'L\'harmonie financière est en toi',
      ],
      ZenMood.good: [
        'Chaque petit pas compte',
        'L\'équilibre se construit jour après jour',
        'Tu es sur la bonne voie',
      ],
      ZenMood.neutral: [
        'Prends un moment pour respirer',
        'L\'important est de rester conscient',
        'Demain est un nouveau jour',
      ],
      ZenMood.caution: [
        'Un peu d\'attention suffit',
        'Rien n\'est irréversible',
        'L\'awareness est le premier pas',
      ],
      ZenMood.alert: [
        'C\'est le moment de faire un break',
        'Respire profondément',
        'Demande de l\'aide si besoin',
      ],
    };

    final todayWisdom = wisdoms[mood]![DateTime.now().day % 3];

    return Container(
      padding: const EdgeInsets.all(AuraDimensions.spaceXL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AuraColors.auraAmber.withOpacity(0.1),
            AuraColors.auraDeep.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AuraDimensions.radiusXL),
        border: Border.all(
          color: AuraColors.auraAmber.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.format_quote,
            color: AuraColors.auraAmber.withOpacity(0.5),
            size: 32,
          ),
          const SizedBox(height: AuraDimensions.spaceM),
          Text(
            todayWisdom,
            style: AuraTypography.bodyLarge.copyWith(
              color: AuraColors.auraTextDark,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildZenActions() {
    return Row(
      children: [
        Expanded(
          child: _ZenActionButton(
            icon: Icons.camera_alt_outlined,
            label: 'Scan',
            onTap: () {
              HapticService.lightTap();
              context.goToScan();
            },
          ),
        ),
        const SizedBox(width: AuraDimensions.spaceM),
        Expanded(
          child: _ZenActionButton(
            icon: Icons.add_circle_outline,
            label: 'Ajouter',
            onTap: () {
              HapticService.lightTap();
              context.goToAddTransaction();
            },
          ),
        ),
        const SizedBox(width: AuraDimensions.spaceM),
        Expanded(
          child: _ZenActionButton(
            icon: Icons.insights,
            label: 'Insights',
            onTap: () {
              HapticService.lightTap();
              context.goToInsights();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildZenLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: AuraColors.auraAmber,
      ),
    );
  }

  Widget _buildZenError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off,
            size: 64,
            color: AuraColors.auraTextDarkSecondary,
          ),
          const SizedBox(height: AuraDimensions.spaceM),
          Text(
            'Prends un moment...',
            style: AuraTypography.h4.copyWith(
              color: AuraColors.auraTextDark,
            ),
          ),
        ],
      ),
    );
  }

  // Helpers
  double _calculateHealthScore(DashboardState state) {
    // Score entre 0 et 100 basé sur plusieurs facteurs
    double score = 70; // Base

    // Ajuste selon le delta mensuel
    if (state.monthlyDelta > 0) score += 20;
    if (state.monthlyDelta < -100) score -= 15;

    // Ajuste selon les objectifs
    if (state.budgetGoals.isNotEmpty) {
      final achievedGoals = state.budgetGoals.where((g) => 
        (g.currentAmount / g.targetAmount) >= 1.0
      ).length;
      score += achievedGoals * 5;
    }

    return score.clamp(0, 100);
  }

  ZenMood _getMoodFromScore(double score) {
    if (score >= 85) return ZenMood.excellent;
    if (score >= 70) return ZenMood.good;
    if (score >= 50) return ZenMood.neutral;
    if (score >= 30) return ZenMood.caution;
    return ZenMood.alert;
  }

  Color _getColorFromScore(double score) {
    if (score >= 85) return AuraColors.auraGreen;
    if (score >= 70) return AuraColors.auraAmber;
    if (score >= 50) return AuraColors.auraAccentGold;
    if (score >= 30) return AuraColors.auraDeep;
    return AuraColors.auraRed;
  }
}

/// Humeurs Zen possibles
enum ZenMood {
  excellent,
  good,
  neutral,
  caution,
  alert,
}

extension ZenMoodExtension on ZenMood {
  String get label {
    return switch (this) {
      ZenMood.excellent => 'Excellent',
      ZenMood.good => 'Harmonieux',
      ZenMood.neutral => 'Stable',
      ZenMood.caution => 'À surveiller',
      ZenMood.alert => 'Attention',
    };
  }

  String get description {
    return switch (this) {
      ZenMood.excellent => 'Tout va très bien',
      ZenMood.good => 'Bonne dynamique',
      ZenMood.neutral => 'Équilibre moyen',
      ZenMood.caution => 'Quelques ajustements',
      ZenMood.alert => 'Besoin de soin',
    };
  }

  IconData get icon {
    return switch (this) {
      ZenMood.excellent => Icons.sentiment_very_satisfied,
      ZenMood.good => Icons.sentiment_satisfied,
      ZenMood.neutral => Icons.sentiment_neutral,
      ZenMood.caution => Icons.sentiment_dissatisfied,
      ZenMood.alert => Icons.sentiment_very_dissatisfied,
    };
  }

  Color get centerColor {
    return switch (this) {
      ZenMood.excellent => const Color(0xFF4CAF50),
      ZenMood.good => AuraColors.auraAmber,
      ZenMood.neutral => AuraColors.auraAccentGold,
      ZenMood.caution => AuraColors.auraDeep,
      ZenMood.alert => AuraColors.auraRed,
    };
  }

  Color get outerColor {
    return switch (this) {
      ZenMood.excellent => const Color(0xFF81C784),
      ZenMood.good => AuraColors.auraDeep,
      ZenMood.neutral => AuraColors.auraAmber,
      ZenMood.caution => const Color(0xFFFF8A65),
      ZenMood.alert => const Color(0xFFE57373),
    };
  }
}

class _CategoryBubble {
  final String name;
  final double ratio;
  final Color color;

  _CategoryBubble(this.name, this.ratio, this.color);
}

class _WavePainter extends CustomPainter {
  final double progress;
  final bool isPositive;
  final Color color;

  _WavePainter({
    required this.progress,
    required this.isPositive,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height / 2);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height / 2 +
          sin((x / size.width * 4 * pi) + (progress * 2 * pi)) *
              (isPositive ? 20 : -20);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Deuxième vague
    final paint2 = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, size.height / 2);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height / 2 +
          sin((x / size.width * 3 * pi) + (progress * 2 * pi) + 1) *
              (isPositive ? 15 : -15);
      path2.lineTo(x, y);
    }

    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ZenActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ZenActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          vertical: AuraDimensions.spaceL,
          horizontal: AuraDimensions.spaceM,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AuraColors.auraAmber,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AuraTypography.labelSmall.copyWith(
                color: AuraColors.auraTextDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
