import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../services/privacy_service.dart';

/// Écran des paramètres de confidentialité
class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  bool _isLoading = true;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await PrivacyService.instance.isBiometricAvailable();
    setState(() {
      _biometricAvailable = available;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PrivacySettings>(
      stream: PrivacyService.instance.privacyStream,
      initialData: PrivacyService.instance.currentSettings,
      builder: (context, snapshot) {
        final settings = snapshot.data ?? const PrivacySettings();

        return Scaffold(
          backgroundColor: AuraColors.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 140,
                floating: true,
                pinned: true,
                backgroundColor: AuraColors.background.withOpacity(0.9),
                leading: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                ),
                title: Text(
                  'Confidentialité',
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AuraColors.amber.withOpacity(0.2),
                          AuraColors.background,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🛡️',
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Protège tes données financières',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: AuraColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Authentification
                      _buildSectionTitle('Authentification'),
                      const SizedBox(height: 12),
                      _buildBiometricCard(settings),
                      
                      const SizedBox(height: 24),
                      
                      // Section Masquage
                      _buildSectionTitle('Masquage'),
                      const SizedBox(height: 12),
                      _buildHideBalanceCard(settings),
                      
                      const SizedBox(height: 24),
                      
                      // Section Mode Discret
                      _buildSectionTitle('Mode discret'),
                      const SizedBox(height: 12),
                      _buildStealthModeCard(settings),
                      const SizedBox(height: 12),
                      if (settings.stealthModeEnabled) ...[
                        _buildDisguiseSelector(settings),
                        const SizedBox(height: 12),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      // Section Sécurité avancée
                      _buildSectionTitle('Sécurité avancée'),
                      const SizedBox(height: 12),
                      _buildScreenshotBlockCard(settings),
                      const SizedBox(height: 12),
                      _buildFakeIconCard(settings),
                      
                      const SizedBox(height: 32),
                      
                      // Bouton d'urgence
                      _buildEmergencyButton(),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AuraColors.amber,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildBiometricCard(PrivacySettings settings) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AuraColors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.fingerprint,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verrouillage biométrique',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _biometricAvailable
                          ? 'Face ID / Touch ID requis'
                          : 'Non disponible sur cet appareil',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AuraColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: settings.biometricLockEnabled,
                onChanged: _biometricAvailable
                    ? (value) => _toggleBiometricLock(value)
                    : null,
                activeColor: AuraColors.amber,
              ),
            ],
          ),
          if (settings.biometricLockEnabled) ...[
            const Divider(color: Colors.white12, height: 24),
            _buildTimeoutSelector(settings),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeoutSelector(PrivacySettings settings) {
    final options = [1, 5, 15, 30, 60];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verrouillage automatique après',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: AuraColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: options.map((minutes) {
            final isSelected = settings.autoLockTimeoutMinutes == minutes;
            return GestureDetector(
              onTap: () {
                PrivacyService.instance.setAutoLockTimeout(minutes);
                HapticService.lightTap();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AuraColors.amber.withOpacity(0.3)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AuraColors.amber : Colors.white10,
                  ),
                ),
                child: Text(
                  minutes == 1 ? '1 min' : '$minutes min',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHideBalanceCard(PrivacySettings settings) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AuraColors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.visibility_off,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Masquer les soldes',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Affiche •••• à la place des montants',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AuraColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: settings.hideBalanceEnabled,
            onChanged: (value) {
              PrivacyService.instance.setHideBalance(value);
              HapticService.lightTap();
            },
            activeColor: AuraColors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildStealthModeCard(PrivacySettings settings) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AuraColors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.mask,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode discret',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Déguise l\'app en calculatrice ou autre',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AuraColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: settings.stealthModeEnabled,
            onChanged: (value) {
              PrivacyService.instance.setStealthMode(value);
              HapticService.lightTap();
            },
            activeColor: AuraColors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildDisguiseSelector(PrivacySettings settings) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apparence de l\'application',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AuraColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...DisguiseMode.values.where((m) => m != DisguiseMode.none).map((mode) {
            final isSelected = settings.disguiseMode == mode;
            return GestureDetector(
              onTap: () {
                PrivacyService.instance.setDisguiseMode(mode);
                HapticService.lightTap();
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AuraColors.amber.withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AuraColors.amber : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      mode.displayName.split(' ').first,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        mode.displayName.substring(2),
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: AuraColors.amber, size: 20),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildScreenshotBlockCard(PrivacySettings settings) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AuraColors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.mobile_off,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bloquer les captures',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Empêche les screenshots et enregistrements',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AuraColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: settings.screenshotBlockEnabled,
            onChanged: (value) {
              PrivacyService.instance.setScreenshotBlock(value);
              HapticService.lightTap();
            },
            activeColor: AuraColors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildFakeIconCard(PrivacySettings settings) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AuraColors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.app_shortcut,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Icône alternative',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Change l\'icône sur l\'écran d\'accueil',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AuraColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: settings.fakeAppIconEnabled,
            onChanged: (value) {
              PrivacyService.instance.setFakeAppIcon(value);
              HapticService.lightTap();
            },
            activeColor: AuraColors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton() {
    return GestureDetector(
      onTap: _showEmergencyDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AuraColors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AuraColors.red.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AuraColors.red,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              'Effacement d\'urgence',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AuraColors.red,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Efface immédiatement toutes les données',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AuraColors.red.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleBiometricLock(bool value) async {
    if (value) {
      // Authentifier avant d'activer
      final authenticated = await PrivacyService.instance.authenticate(
        localizedReason: 'Activez d\'abord l\'authentification biométrique',
      );
      
      if (authenticated) {
        await PrivacyService.instance.setBiometricLock(true);
        HapticService.success();
      }
    } else {
      await PrivacyService.instance.setBiometricLock(false);
      HapticService.lightTap();
    }
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AuraColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          '⚠️ Attention',
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        content: Text(
          'Cette action effacera TOUTES vos données financières de manière irréversible. Êtes-vous sûr ?',
          style: GoogleFonts.dmSans(
            fontSize: 15,
            color: AuraColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: GoogleFonts.dmSans(color: AuraColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await PrivacyService.instance.emergencyDataWipe();
              HapticService.error();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Données effacées',
                      style: GoogleFonts.dmSans(),
                    ),
                    backgroundColor: AuraColors.red,
                  ),
                );
              }
            },
            child: Text(
              'Effacer',
              style: GoogleFonts.dmSans(color: AuraColors.red),
            ),
          ),
        ],
      ),
    );
  }
}
