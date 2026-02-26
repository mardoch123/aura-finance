import 'dart:math' show pi;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/haptics/haptic_service.dart';
import '../../../core/theme/aura_colors.dart';
import '../subscription_provider.dart';

/// Raison d'affichage du paywall (pour analytics)
enum PaywallTrigger {
  manualFromProfile, // utilisateur clique "Passer Pro"
  scanLimitReached, // 5 scans atteints
  coachLimitReached, // 10 messages Coach atteints
  rewardedAdOffer, // après une pub rewarded
  featureGated, // tentative d'accès feature Pro
}

/// Écran de paywall premium - Design Monarch x Aura Finance
/// 
/// Structure:
/// - Top 35%: Gradient ambre avec logo animé et badges flottants
/// - Bottom 65%: Feuille blanche avec timeline et sélection de plans
class PaywallScreen extends ConsumerStatefulWidget {
  /// Raison d'affichage du paywall
  final PaywallTrigger trigger;

  /// Si true, affiche comme bottom sheet sinon fullscreen
  final bool showAsBottomSheet;

  const PaywallScreen({
    super.key,
    this.trigger = PaywallTrigger.manualFromProfile,
    this.showAsBottomSheet = true,
  });

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String? _selectedPlanId;
  bool _isLoading = false;
  Offerings? _offerings;

  // IDs des plans attendus
  static const String _annualPlanId = 'aura_pro_annual_2999';
  static const String _weeklyPlanId = 'aura_pro_weekly_499';

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadOfferings();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      setState(() {
        _offerings = offerings;
        // Sélectionner le plan annuel par défaut
        _selectedPlanId = _annualPlanId;
      });
      _pulseController.repeat(reverse: true);
    } catch (e) {
      debugPrint('Erreur chargement offerings: $e');
    }
  }

  void _showSuccess() {
    HapticService.success();
    _confettiController.play();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              'Bienvenue dans Aura Pro !',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: AuraColors.auraAmber,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    });
  }

  Future<void> _purchase() async {
    if (_selectedPlanId == null) return;

    setState(() => _isLoading = true);
    HapticService.mediumTap();

    try {
      final success = await ref
          .read(subscriptionNotifierProvider.notifier)
          .purchasePackage(_selectedPlanId!);

      if (success && mounted) {
        _showSuccess();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restore() async {
    setState(() => _isLoading = true);
    HapticService.lightTap();

    await ref
        .read(subscriptionNotifierProvider.notifier)
        .restorePurchases();

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Fond gradient ambre (top 35%)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.38,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AuraColors.auraAmber,
                    AuraColors.auraDeep,
                    AuraColors.auraDark,
                  ],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
              child: _buildTopSection(),
            ),
          ),

          // Feuille blanche draggable (bottom 65%)
          DraggableScrollableSheet(
            initialChildSize: 0.68,
            minChildSize: 0.68,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(36),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(36),
                  ),
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      // Handle de drag
                      SliverToBoxAdapter(
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 12, bottom: 8),
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),

                      // Contenu
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            const SizedBox(height: 16),
                            _buildTimelineSection(),
                            const SizedBox(height: 32),
                            _buildPlanSelection(),
                            const SizedBox(height: 24),
                            _buildLinks(),
                            const SizedBox(height: 16),
                            _buildCTAButton(),
                            const SizedBox(height: 12),
                            _buildSecondaryLink(),
                            const SizedBox(height: 16),
                            _buildDisclaimer(),
                            const SizedBox(height: 32),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              colors: const [
                AuraColors.auraAmber,
                AuraColors.auraAccentGold,
                AuraColors.auraAccentGoldBright,
                Colors.white,
              ],
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AuraColors.auraAmber,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo animé
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  0,
                  sin(_floatController.value * 2 * pi) * 3,
                ),
                child: child,
              );
            },
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AuraColors.auraAmber.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Titre AURA PRO
          Text(
            'AURA PRO',
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 4,
            ),
          ),

          const SizedBox(height: 8),

          // Sous-titre
          Text(
            'Votre santé financière sans limites',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.75),
            ),
          ),

          const SizedBox(height: 24),

          // Badges flottants
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFloatingBadge('🔭', 'Scan illimité', -1),
              const SizedBox(width: 12),
              _buildFloatingBadge('🤖', 'Coach IA', 0),
              const SizedBox(width: 12),
              _buildFloatingBadge('🧛', 'Anti-Vampire', 1),
              const SizedBox(width: 12),
              _buildFloatingBadge('📈', 'Prédictions', 2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBadge(String emoji, String text, int index) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final offset = sin((_floatController.value + index * 0.25) * 2 * pi) * 4;
        return Transform.translate(
          offset: Offset(0, offset),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comment fonctionne votre essai gratuit',
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 24),
        _buildTimelineItem(
          icon: Icons.lock_open_outlined,
          title: 'Aujourd\'hui',
          description: 'Démarrez gratuitement. Accédez à toutes les fonctionnalités Pro.',
          isFirst: true,
        ),
        _buildTimelineItem(
          icon: Icons.notifications_none,
          title: 'Dans 6 jours',
          description: 'On vous envoie un rappel avant la fin de l\'essai. Annulez à tout moment.',
        ),
        _buildTimelineItem(
          icon: Icons.workspace_premium_outlined,
          title: 'Dans 7 jours',
          description: 'Votre abonnement démarre automatiquement sauf si vous annulez.',
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String description,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline avec ligne pointillée
          Column(
            children: [
              if (!isFirst)
                Container(
                  width: 2,
                  height: 12,
                  color: const Color(0xFFE0E0E0),
                ),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F0F0),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF666666),
                  size: 22,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: CustomPaint(
                    size: const Size(2, double.infinity),
                    painter: _DashedLinePainter(),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Contenu
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF666666),
                      height: 1.4,
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

  Widget _buildPlanSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Choisissez votre plan',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Plan Annuel (sélectionné par défaut)
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final isSelected = _selectedPlanId == _annualPlanId;
            return Transform.scale(
              scale: isSelected ? _pulseAnimation.value : 1.0,
              child: child,
            );
          },
          child: _buildPlanCard(
            isAnnual: true,
            isSelected: _selectedPlanId == _annualPlanId,
            onTap: () {
              HapticService.lightTap();
              setState(() => _selectedPlanId = _annualPlanId);
            },
          ),
        ),

        const SizedBox(height: 12),

        // Plan Hebdomadaire
        _buildPlanCard(
          isAnnual: false,
          isSelected: _selectedPlanId == _weeklyPlanId,
          onTap: () {
            HapticService.lightTap();
            setState(() => _selectedPlanId = _weeklyPlanId);
          },
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required bool isAnnual,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    // Prix depuis RevenueCat ou valeurs par défaut
    final annualPrice = _getPriceForPlan(_annualPlanId, '\$29.99');
    final weeklyPrice = _getPriceForPlan(_weeklyPlanId, '\$4.99');

    if (isAnnual) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8F0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AuraColors.auraAmber
                  : AuraColors.auraAmber.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AuraColors.auraAmber.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$annualPrice / an',
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$2.50 par mois, facturé annuellement',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
              // Badge ÉCONOMISEZ
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: const BoxDecoration(
                    color: AuraColors.auraAmber,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(10),
                    ),
                  ),
                  child: Text(
                    'ÉCONOMISEZ 88%',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Plan hebdomadaire
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AuraColors.auraAmber
                  : const Color(0xFFE0E0E0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$weeklyPrice / semaine',
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$259.48 par an, facturé hebdomadairement',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  String _getPriceForPlan(String planId, String defaultPrice) {
    if (_offerings?.current == null) return defaultPrice;

    final package = _offerings!.current!.availablePackages.firstWhere(
      (p) => p.identifier == planId,
      orElse: () => _offerings!.current!.availablePackages.first,
    );

    return package.storeProduct.priceString;
  }

  Widget _buildLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Restaurer l'achat
        TextButton(
          onPressed: _restore,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Restaurer l\'achat',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF007AFF), // Bleu iOS
            ),
          ),
        ),

        // Terms & Privacy
        Row(
          children: [
            TextButton(
              onPressed: () {
                // Ouvrir Conditions
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Conditions',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF888888),
                ),
              ),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () {
                // Ouvrir Confidentialité
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Confidentialité',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF888888),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCTAButton() {
    final isEnabled = _selectedPlanId != null && !_isLoading;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => HapticService.lightTap() : null,
      onTap: isEnabled ? _purchase : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AuraColors.auraAmber,
              AuraColors.auraDeep,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AuraColors.auraAmber.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  'Commencer l\'essai 7 jours gratuit',
                  style: GoogleFonts.dmSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSecondaryLink() {
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        Navigator.of(context).pop(false);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Ou continuer sans abonnement',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF888888),
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: Color(0xFF888888),
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    final selectedPrice = _selectedPlanId == _annualPlanId
        ? '\$29.99/an'
        : '\$4.99/semaine';

    return Text(
      'Essai gratuit de 7 jours, puis $selectedPrice. '
      'Renouvelé automatiquement. Annulez à tout moment dans les paramètres de votre compte.',
      textAlign: TextAlign.center,
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFAAAAAA),
        height: 1.5,
      ),
    );
  }
}

/// Painter pour la ligne pointillée de la timeline
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const dashHeight = 6.0;
    const dashSpace = 4.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Service pour afficher le paywall depuis n'importe où
class PaywallService {
  /// Affiche le paywall comme bottom sheet
  static Future<bool?> showBottomSheet(
    BuildContext context, {
    PaywallTrigger trigger = PaywallTrigger.manualFromProfile,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FractionallySizedBox(
        heightFactor: 0.95,
        child: PaywallScreen(
          trigger: PaywallTrigger.manualFromProfile,
          showAsBottomSheet: true,
        ),
      ),
    );
  }

  /// Affiche le paywall en plein écran
  static Future<bool?> showFullscreen(
    BuildContext context, {
    PaywallTrigger trigger = PaywallTrigger.manualFromProfile,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PaywallScreen(
          trigger: trigger,
          showAsBottomSheet: false,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  /// Affiche le paywall selon le contexte (bottom sheet sur mobile, fullscreen sur tablette)
  static Future<bool?> show(
    BuildContext context, {
    PaywallTrigger trigger = PaywallTrigger.manualFromProfile,
  }) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide > 600;

    if (isTablet) {
      return showFullscreen(context, trigger: trigger);
    } else {
      return showBottomSheet(context, trigger: trigger);
    }
  }
}

/// Provider pour accéder au PaywallService
final paywallServiceProvider = Provider<PaywallService>((ref) {
  return PaywallService();
});
