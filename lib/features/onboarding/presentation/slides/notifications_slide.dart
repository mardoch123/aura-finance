import 'dart:math' show pi, sin;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../onboarding_controller.dart';

/// Slide 5: Activation des notifications
/// Illustration animée avec toggle custom
class NotificationsSlide extends ConsumerStatefulWidget {
  const NotificationsSlide({super.key});

  @override
  ConsumerState<NotificationsSlide> createState() => _NotificationsSlideState();
}

class _NotificationsSlideState extends ConsumerState<NotificationsSlide>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _toggleNotifications() {
    HapticService.toggle();
    ref.read(onboardingNotifierProvider.notifier).toggleNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final notificationsEnabled = ref.watch(onboardingNotifierProvider).notificationsEnabled;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AuraDimensions.spaceXL,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Titre
          Text(
            'Notifications intelligentes',
            style: AuraTypography.h2.copyWith(
              color: AuraColors.auraTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AuraDimensions.spaceS),
          Text(
            'Restez informé de votre santé financière',
            style: AuraTypography.bodyLarge.copyWith(
              color: AuraColors.auraTextPrimary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AuraDimensions.spaceXXL),
          
          // Illustration animée
          AnimatedBuilder(
            animation: Listenable.merge([_pulseController, _floatController]),
            builder: (context, child) {
              final floatOffset = sin(_floatController.value * pi) * 10;
              
              return Transform.translate(
                offset: Offset(0, floatOffset),
                child: ScaleTransition(
                  scale: notificationsEnabled ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          AuraColors.auraAccentGold,
                          AuraColors.auraAmber,
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                      boxShadow: notificationsEnabled
                          ? [
                              BoxShadow(
                                color: AuraColors.auraAccentGold.withOpacity(0.5),
                                blurRadius: 60,
                                spreadRadius: 20,
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              AuraColors.auraGlassStrong,
                              AuraColors.auraGlass,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: AuraColors.auraTextPrimary.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          notificationsEnabled
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_off_outlined,
                          size: 56,
                          color: notificationsEnabled
                              ? AuraColors.auraTextPrimary
                              : AuraColors.auraTextPrimary.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: AuraDimensions.spaceXXL),
          
          // Toggle custom style Apple
          GestureDetector(
            onTap: _toggleNotifications,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: 80,
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: notificationsEnabled
                    ? const LinearGradient(
                        colors: [
                          AuraColors.auraAccentGold,
                          AuraColors.auraAmber,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          AuraColors.auraTextPrimary.withOpacity(0.2),
                          AuraColors.auraTextPrimary.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: notificationsEnabled
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AuraColors.auraTextPrimary,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    notificationsEnabled
                        ? Icons.check_rounded
                        : Icons.close_rounded,
                    size: 20,
                    color: notificationsEnabled
                        ? AuraColors.auraAmber
                        : AuraColors.auraTextDarkSecondary,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: AuraDimensions.spaceXL),
          
          // Liste des types de notifications
          GlassCard(
            borderRadius: AuraDimensions.radiusL,
            padding: const EdgeInsets.all(AuraDimensions.spaceL),
            child: Column(
              children: [
                _buildNotificationItem(
                  icon: Icons.shield_outlined,
                  title: 'Alertes Vampire',
                  description: 'Détection des hausses de prix',
                  enabled: notificationsEnabled,
                ),
                const Divider(
                  color: AuraColors.auraGlassBorder,
                  height: AuraDimensions.spaceXL,
                ),
                _buildNotificationItem(
                  icon: Icons.trending_up_rounded,
                  title: 'Résumé hebdomadaire',
                  description: 'Votre bilan chaque lundi',
                  enabled: notificationsEnabled,
                ),
                const Divider(
                  color: AuraColors.auraGlassBorder,
                  height: AuraDimensions.spaceXL,
                ),
                _buildNotificationItem(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Alertes budget',
                  description: 'Quand vous approchez des limites',
                  enabled: notificationsEnabled,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required String description,
    required bool enabled,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AuraColors.auraTextPrimary.withOpacity(0.1),
            ),
            child: Icon(
              icon,
              color: AuraColors.auraTextPrimary.withOpacity(enabled ? 0.9 : 0.5),
              size: 22,
            ),
          ),
          const SizedBox(width: AuraDimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AuraTypography.labelMedium.copyWith(
                    color: AuraColors.auraTextPrimary.withOpacity(enabled ? 1.0 : 0.6),
                  ),
                ),
                const SizedBox(height: AuraDimensions.spaceXS),
                Text(
                  description,
                  style: AuraTypography.bodySmall.copyWith(
                    color: AuraColors.auraTextPrimary.withOpacity(enabled ? 0.7 : 0.4),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            enabled ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: enabled
                ? AuraColors.auraAccentGold
                : AuraColors.auraTextPrimary.withOpacity(0.3),
            size: 24,
          ),
        ],
      ),
    );
  }
}
