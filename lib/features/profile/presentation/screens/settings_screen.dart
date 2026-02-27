import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/app_localizations_extension.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/locale_service.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/glass_card.dart';

/// Écran des paramètres
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AuraColors.auraBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AuraDimensions.spaceM),
                child: Column(
                  children: [
                    // Section Outils
                    _buildSectionTitle(context.l10n.tools),
                    _buildSettingsCard([
                      _SettingItem(
                        icon: Icons.account_balance,
                        title: context.l10n.bankSync,
                        subtitle: context.l10n.bankSyncDesc,
                        onTap: () => context.goToBanking(),
                      ),
                      _SettingItem(
                        icon: Icons.calculate_outlined,
                        title: context.l10n.calculator,
                        subtitle: context.l10n.calculatorDesc,
                        onTap: () => _navigateToCalculators(context),
                      ),
                      _SettingItem(
                        icon: Icons.currency_exchange,
                        title: context.l10n.converter,
                        subtitle: context.l10n.converterDesc,
                        onTap: () => _navigateToCurrencyConverter(context),
                      ),
                    ]),
                    
                    const SizedBox(height: AuraDimensions.spaceL),

                    // Section Général
                    _buildSectionTitle(context.l10n.general),
                    _buildSettingsCard([
                      _SettingItem(
                        icon: Icons.notifications_outlined,
                        title: context.l10n.notifications,
                        subtitle: context.l10n.notificationsDesc,
                        onTap: () => _showNotificationSettings(context),
                      ),
                      _SettingItem(
                        icon: Icons.lock_outline,
                        title: context.l10n.privacySettings,
                        subtitle: context.l10n.privacyDesc,
                        onTap: () => _navigateToPrivacy(context),
                      ),
                      _SettingItem(
                        icon: Icons.language,
                        title: context.l10n.language,
                        subtitle: LocaleService.instance.getLocaleName(
                          LocaleService.instance.currentLocale,
                        ),
                        onTap: () => _showLanguageSettings(context),
                      ),
                    ]),

                    const SizedBox(height: AuraDimensions.spaceL),

                    // Section Apparence
                    _buildSectionTitle(context.l10n.appearance),
                    _buildSettingsCard([
                      _SettingItem(
                        icon: Icons.palette_outlined,
                        title: context.l10n.theme,
                        subtitle: context.l10n.light,
                        onTap: () => _showThemeSettings(context),
                      ),
                      _SettingItem(
                        icon: Icons.format_size,
                        title: context.l10n.textSize,
                        subtitle: context.l10n.normal,
                        onTap: () {},
                      ),
                    ]),

                    const SizedBox(height: AuraDimensions.spaceL),

                    // Section Données
                    _buildSectionTitle(context.l10n.data),
                    _buildSettingsCard([
                      _SettingItem(
                        icon: Icons.backup_outlined,
                        title: context.l10n.backup,
                        subtitle: context.l10n.lastBackupToday,
                        onTap: () {},
                      ),
                      _SettingItem(
                        icon: Icons.download_outlined,
                        title: context.l10n.exportData,
                        subtitle: context.l10n.exportFormats,
                        onTap: () {},
                      ),
                      _SettingItem(
                        icon: Icons.delete_outline,
                        title: context.l10n.deleteData,
                        subtitle: context.l10n.deleteDataDesc,
                        isDanger: true,
                        onTap: () => _confirmDeleteData(context),
                      ),
                    ]),

                    const SizedBox(height: AuraDimensions.spaceL),

                    // Section À propos
                    _buildSectionTitle(context.l10n.about),
                    _buildSettingsCard([
                      _SettingItem(
                        icon: Icons.info_outline,
                        title: context.l10n.version,
                        subtitle: '1.0.0 (Build 1)',
                        onTap: null,
                      ),
                      _SettingItem(
                        icon: Icons.description_outlined,
                        title: context.l10n.termsOfUse,
                        onTap: () {},
                      ),
                      _SettingItem(
                        icon: Icons.privacy_tip_outlined,
                        title: context.l10n.privacyPolicy,
                        onTap: () {},
                      ),
                      _SettingItem(
                        icon: Icons.help_outline,
                        title: context.l10n.helpSupport,
                        onTap: () {},
                      ),
                    ]),

                    const SizedBox(height: AuraDimensions.spaceXL),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AuraDimensions.spaceM),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios, color: AuraColors.auraTextDark),
          ),
          Expanded(
            child: Text(
              context.l10n.settings,
              style: AuraTypography.h3.copyWith(color: AuraColors.auraTextDark),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AuraDimensions.spaceS,
        bottom: AuraDimensions.spaceS,
      ),
      child: Text(
        title.toUpperCase(),
        style: AuraTypography.labelSmall.copyWith(
          color: AuraColors.auraTextDarkSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<_SettingItem> items) {
    return GlassCard(
      child: Column(
        children: items.asMap().entries.map((entry) {
          final item = entry.value;
          final isLast = entry.key == items.length - 1;

          return Column(
            children: [
              ListTile(
                leading: Icon(
                  item.icon,
                  color: item.isDanger ? AuraColors.auraRed : AuraColors.auraTextDark,
                ),
                title: Text(
                  item.title,
                  style: AuraTypography.bodyLarge.copyWith(
                    color: item.isDanger ? AuraColors.auraRed : AuraColors.auraTextDark,
                  ),
                ),
                subtitle: item.subtitle != null
                    ? Text(
                        item.subtitle!,
                        style: AuraTypography.bodySmall.copyWith(
                          color: AuraColors.auraTextDarkSecondary,
                        ),
                      )
                    : null,
                trailing: item.onTap != null
                    ? Icon(
                        Icons.chevron_right,
                        color: AuraColors.auraTextDarkSecondary,
                      )
                    : null,
                onTap: () {
                  if (item.onTap != null) {
                    HapticService.lightTap();
                    item.onTap!();
                  }
                },
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 56,
                  color: AuraColors.auraGlassBorder,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _NotificationSettingsSheet(),
    );
  }

  void _navigateToCalculators(BuildContext context) {
    HapticService.lightTap();
    context.push(AppRoutes.calculators);
  }
  
  void _navigateToCurrencyConverter(BuildContext context) {
    HapticService.lightTap();
    context.push(AppRoutes.currencyConverter);
  }
  
  void _navigateToPrivacy(BuildContext context) {
    HapticService.lightTap();
    context.push(AppRoutes.privacySettings);
  }

  void _showLanguageSettings(BuildContext context) {
    HapticService.lightTap();
    context.push('/language');
  }

  void _showThemeSettings(BuildContext context) {
    HapticService.lightTap();
    // TODO: Modal sélection thème
  }

  void _confirmDeleteData(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AuraColors.auraGlassStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AuraDimensions.radiusXL),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: AuraColors.auraRed),
            const SizedBox(width: 8),
            Text(
              context.l10n.warning,
              style: AuraTypography.h4.copyWith(color: AuraColors.auraRed),
            ),
          ],
        ),
        content: Text(
          context.l10n.deleteDataConfirm,
          style: AuraTypography.bodyMedium.copyWith(
            color: AuraColors.auraTextDarkSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.l10n.cancel,
              style: AuraTypography.labelMedium.copyWith(
                color: AuraColors.auraTextDarkSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              HapticService.success();
              // TODO: Supprimer les données
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AuraColors.auraRed,
            ),
            child: Text(
              context.l10n.delete,
              style: AuraTypography.labelMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isDanger;

  _SettingItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.isDanger = false,
  });
}

/// Bottom sheet des paramètres de notification
class _NotificationSettingsSheet extends StatelessWidget {
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

          Padding(
            padding: const EdgeInsets.all(AuraDimensions.spaceM),
            child: Text(
              context.l10n.notifications,
              style: AuraTypography.h3.copyWith(color: AuraColors.auraTextDark),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceM),
              children: [
                _buildToggleTile(
                  context.l10n.expenseAlerts,
                  context.l10n.expenseAlertsDesc,
                  true,
                ),
                _buildToggleTile(
                  context.l10n.subscriptionReminders,
                  context.l10n.subscriptionRemindersDesc,
                  true,
                ),
                _buildToggleTile(
                  context.l10n.vampireDetection,
                  context.l10n.vampireDetectionDesc,
                  true,
                ),
                _buildToggleTile(
                  context.l10n.financialPredictions,
                  context.l10n.financialPredictionsDesc,
                  true,
                ),
                _buildToggleTile(
                  context.l10n.weeklySummary,
                  context.l10n.weeklySummaryDesc,
                  false,
                ),
                _buildToggleTile(
                  context.l10n.coachTips,
                  context.l10n.coachTipsDesc,
                  true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile(String title, String subtitle, bool value) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: AuraDimensions.spaceS),
      padding: const EdgeInsets.all(AuraDimensions.spaceM),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AuraTypography.labelLarge.copyWith(
                    color: AuraColors.auraTextDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: AuraTypography.bodySmall.copyWith(
                    color: AuraColors.auraTextDarkSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) {},
            activeColor: AuraColors.auraAmber,
          ),
        ],
      ),
    );
  }
}
