import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'core/ads/ads_initializer.dart';
import 'core/router/app_router.dart';
import 'core/theme/aura_theme.dart';
import 'core/services/locale_service.dart';
import 'features/subscription/subscription_provider.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configuration de l'orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Configuration de la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Initialisation des services (ordre important)
  // 1. Supabase (authentification et base de données)
  await SupabaseService.instance.initialize();
  
  // 2. Publicités et achats in-app (UMP, AdMob, RevenueCat)
  await adsInitializer.initialize();
  
  // 3. Notifications
  await NotificationService.instance.initialize();
  
  // 4. Service de locale (langue)
  await LocaleService.instance.initialize();
  
  runApp(
    const ProviderScope(
      child: AuraApp(),
    ),
  );
}

/// Application principale Aura Finance
class AuraApp extends ConsumerStatefulWidget {
  const AuraApp({super.key});

  @override
  ConsumerState<AuraApp> createState() => _AuraAppState();
}

class _AuraAppState extends ConsumerState<AuraApp> {
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    // Initialiser le service de locale
    await LocaleService.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    
    return FutureBuilder(
      future: _initializationFuture,
      builder: (context, snapshot) {
        // Pendant l'initialisation, afficher un écran de chargement
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Container(
              color: AuraColors.auraBackground,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AuraColors.auraAmber,
                ),
              ),
            ),
          );
        }

        // Une fois initialisé, construire l'app avec la locale
        final currentLocale = LocaleService.instance.currentLocale;
        
        return MaterialApp.router(
          title: 'Aura Finance',
          debugShowCheckedModeBanner: false,
          
          // Thème
          theme: AuraTheme.lightTheme,
          darkTheme: AuraTheme.darkTheme,
          themeMode: ThemeMode.light,
          
          // Router
          routerConfig: router,
          
          // Localisation - utilise la locale détectée ou sauvegardée
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: LocaleService.supportedLocales,
          locale: currentLocale,
        );
      },
    );
  }
}
