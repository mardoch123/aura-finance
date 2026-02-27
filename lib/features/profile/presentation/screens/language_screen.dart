import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/services/locale_service.dart';
import '../../../../core/widgets/animal_loader.dart';
import '../../../../core/extensions/app_localizations_extension.dart';

/// Écran de sélection de langue
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = LocaleService.instance.currentLocale;
    final localeService = LocaleService.instance;

    return Scaffold(
      backgroundColor: AuraColors.auraBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Animation du renard
            const Padding(
              padding: EdgeInsets.all(AuraDimensions.spaceL),
              child: AnimalLoader(
                size: 80,
                showBackground: false,
              ),
            ),

            // Titre
            Text(
              context.l10n.selectLanguage,
              style: AuraTypography.h3.copyWith(
                color: AuraColors.auraTextDark,
              ),
            ),
            const SizedBox(height: AuraDimensions.spaceS),
            Text(
              context.l10n.languageDesc,
              style: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.auraTextDarkSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AuraDimensions.spaceXL),

            // Liste des langues
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AuraDimensions.spaceXL,
                ),
                itemCount: LocaleService.supportedLocales.length,
                itemBuilder: (context, index) {
                  final locale = LocaleService.supportedLocales[index];
                  final isSelected = locale.languageCode == currentLocale.languageCode;
                  final flag = localeService.getLocaleFlag(locale);
                  final name = localeService.getLocaleName(locale);

                  return _buildLanguageTile(
                    context: context,
                    flag: flag,
                    name: name,
                    locale: locale,
                    isSelected: isSelected,
                    onTap: () => _changeLanguage(context, ref, locale),
                  );
                },
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(AuraDimensions.spaceL),
              child: Text(
                context.l10n.languageAutoDetect,
                style: AuraTypography.bodySmall.copyWith(
                  color: AuraColors.auraTextDarkSecondary,
                ),
                textAlign: TextAlign.center,
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
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AuraColors.auraTextDark,
            ),
          ),
          Expanded(
            child: Text(
              context.l10n.language,
              style: AuraTypography.h3.copyWith(
                color: AuraColors.auraTextDark,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildLanguageTile({
    required BuildContext context,
    required String flag,
    required String name,
    required Locale locale,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticService.mediumTap();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: AuraDimensions.spaceM),
        padding: const EdgeInsets.all(AuraDimensions.spaceL),
        decoration: BoxDecoration(
          color: isSelected
              ? AuraColors.auraAmber.withOpacity(0.15)
              : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AuraDimensions.radiusXL),
          border: Border.all(
            color: isSelected
                ? AuraColors.auraAmber
                : Colors.white.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Drapeau
            Text(
              flag,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: AuraDimensions.spaceL),

            // Nom de la langue
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AuraTypography.bodyLarge.copyWith(
                      color: AuraColors.auraTextDark,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  Text(
                    locale.toString(),
                    style: AuraTypography.bodySmall.copyWith(
                      color: AuraColors.auraTextDarkSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Indicateur de sélection
            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AuraColors.auraAmber,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeLanguage(
    BuildContext context,
    WidgetRef ref,
    Locale locale,
  ) async {
    // Afficher le loader avec le renard
    context.showAnimalLoader(
      message: context.l10n.changingLanguage,
    );

    // Changer la langue
    await LocaleService.instance.setLocale(locale);

    // Cacher le loader
    if (context.mounted) {
      context.hideAnimalLoader();
      
      // Afficher confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.languageChanged,
          ),
          backgroundColor: AuraColors.auraGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
          ),
        ),
      );

      // Retourner en arrière
      context.pop();
    }
  }
}
