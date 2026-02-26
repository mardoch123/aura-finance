import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/ads/ads_initializer.dart';
import 'core/router/app_router.dart';
import 'core/theme/aura_theme.dart';
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
  
  runApp(
    const ProviderScope(
      child: AuraApp(),
    ),
  );
}

/// Application principale Aura Finance
class AuraApp extends ConsumerWidget {
  const AuraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Aura Finance',
      debugShowCheckedModeBanner: false,
      
      // Thème
      theme: AuraTheme.lightTheme,
      darkTheme: AuraTheme.darkTheme,
      themeMode: ThemeMode.light,
      
      // Router
      routerConfig: router,
      
      // Localisation
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('fr', 'FR'),
    );
  }
}
