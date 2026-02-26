import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/scanner/presentation/screens/scanner_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';
import '../../features/transactions/presentation/screens/add_transaction_screen.dart';
import '../../features/transactions/presentation/screens/transaction_detail_screen.dart';
import '../../features/insights/presentation/screens/insights_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/subscriptions/presentation/screens/subscriptions_screen.dart';
import '../../features/accounts/presentation/screens/accounts_screen.dart';
import '../../features/budgets/presentation/screens/budgets_screen.dart';
import '../../features/coach/presentation/coach_chat_screen.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/onboarding/presentation/onboarding_controller.dart';
import '../widgets/main_scaffold.dart';

/// Routes de l'application Aura Finance
class AppRoutes {
  AppRoutes._();

  // Auth
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Main
  static const String dashboard = '/dashboard';
  static const String transactions = '/transactions';
  static const String transactionDetail = '/transactions/:id';
  static const String addTransaction = '/transactions/add';
  static const String scan = '/scan';
  static const String insights = '/insights';
  static const String subscriptions = '/subscriptions';
  static const String coach = '/coach';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String accounts = '/accounts';
  static const String budgets = '/budgets';

  // Helper methods
  static String transactionDetailPath(String id) => '/transactions/$id';
}

/// Provider du router avec auth guards
final routerProvider = Provider<GoRouter>((ref) {
  return AppRouter.createRouter(ref);
});

/// Router principal de l'application
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter(ProviderRef ref) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: AppRoutes.splash,
      debugLogDiagnostics: true,
      routes: [
        // ═══════════════════════════════════════════════════════════
        // SPLASH & ONBOARDING
        // ═══════════════════════════════════════════════════════════
        GoRoute(
          path: AppRoutes.splash,
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          name: 'onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),

        // ═══════════════════════════════════════════════════════════
        // AUTH
        // ═══════════════════════════════════════════════════════════
        GoRoute(
          path: AppRoutes.login,
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.register,
          name: 'register',
          builder: (context, state) => const Placeholder(), // TODO: RegisterScreen
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          name: 'forgot-password',
          builder: (context, state) => const Placeholder(), // TODO: ForgotPasswordScreen
        ),

        // ═══════════════════════════════════════════════════════════
        // MAIN SHELL (avec bottom navigation)
        // ═══════════════════════════════════════════════════════════
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) {
            return MainScaffold(child: child);
          },
          routes: [
            // Dashboard
            GoRoute(
              path: AppRoutes.dashboard,
              name: 'dashboard',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const DashboardScreen(),
                transitionsBuilder: _fadeTransition,
              ),
            ),
            // Transactions
            GoRoute(
              path: AppRoutes.transactions,
              name: 'transactions',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const TransactionsScreen(),
                transitionsBuilder: _fadeTransition,
              ),
            ),
            // Scan (center button)
            GoRoute(
              path: AppRoutes.scan,
              name: 'scan',
              parentNavigatorKey: _rootNavigatorKey,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const ScannerScreen(),
                transitionsBuilder: _scaleTransition,
                fullscreenDialog: true,
              ),
            ),
            // Insights
            GoRoute(
              path: AppRoutes.insights,
              name: 'insights',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const InsightsScreen(),
                transitionsBuilder: _fadeTransition,
              ),
            ),
            // Profile
            GoRoute(
              path: AppRoutes.profile,
              name: 'profile',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const ProfileScreen(),
                transitionsBuilder: _fadeTransition,
              ),
            ),
          ],
        ),

        // ═══════════════════════════════════════════════════════════
        // FULL SCREEN ROUTES
        // ═══════════════════════════════════════════════════════════
        GoRoute(
          path: AppRoutes.addTransaction,
          name: 'add-transaction',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const AddTransactionScreen(),
            transitionsBuilder: _slideUpTransition,
            fullscreenDialog: true,
          ),
        ),
        GoRoute(
          path: AppRoutes.transactionDetail,
          name: 'transaction-detail',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return CustomTransitionPage(
              key: state.pageKey,
              child: TransactionDetailScreen(transactionId: id),
              transitionsBuilder: _slideUpTransition,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.subscriptions,
          name: 'subscriptions',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const SubscriptionsScreen(),
            transitionsBuilder: _slideRightTransition,
          ),
        ),
        GoRoute(
          path: AppRoutes.coach,
          name: 'coach',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const CoachChatScreen(),
            transitionsBuilder: _slideRightTransition,
          ),
        ),
        GoRoute(
          path: AppRoutes.settings,
          name: 'settings',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const SettingsScreen(),
            transitionsBuilder: _slideRightTransition,
          ),
        ),
        GoRoute(
          path: AppRoutes.accounts,
          name: 'accounts',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const AccountsScreen(),
            transitionsBuilder: _slideRightTransition,
          ),
        ),
        GoRoute(
          path: AppRoutes.budgets,
          name: 'budgets',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const BudgetsScreen(),
            transitionsBuilder: _slideRightTransition,
          ),
        ),
      ],

      // ═══════════════════════════════════════════════════════════
      // ERROR HANDLER
      // ═══════════════════════════════════════════════════════════
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Page non trouvée: ${state.uri.path}'),
        ),
      ),

      // ═══════════════════════════════════════════════════════════
      // REDIRECTS
      // ═══════════════════════════════════════════════════════════
      redirect: (context, state) {
        final authState = ref.read(authControllerProvider);
        final isOnboardingAsync = ref.read(isOnboardingCompletedProvider);
        
        final isSplash = state.matchedLocation == AppRoutes.splash;
        final isLogin = state.matchedLocation == AppRoutes.login;
        final isOnboarding = state.matchedLocation == AppRoutes.onboarding;
        
        // Ne redirige pas depuis le splash (il gère sa propre navigation)
        if (isSplash) return null;
        
        return authState.when(
          initial: () => null,
          loading: () => null,
          unauthenticated: () => isLogin ? null : AppRoutes.login,
          error: (_) => isLogin ? null : AppRoutes.login,
          authenticated: (user) {
            // Vérifie si l'onboarding est complété
            return isOnboardingAsync.when(
              data: (isCompleted) {
                if (!isCompleted && !isOnboarding) {
                  return AppRoutes.onboarding;
                }
                if (isCompleted && isOnboarding) {
                  return AppRoutes.dashboard;
                }
                return null;
              },
              loading: () => null,
              error: (_, __) => null,
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TRANSITIONS
  // ═══════════════════════════════════════════════════════════

  static Widget _fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
      child: child,
    );
  }

  static Widget _slideRightTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    const curve = Curves.easeInOutCubic;

    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    var offsetAnimation = animation.drive(tween);

    return SlideTransition(
      position: offsetAnimation,
      child: child,
    );
  }

  static Widget _slideUpTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(0.0, 1.0);
    const end = Offset.zero;
    const curve = Curves.easeOutExpo;

    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    var offsetAnimation = animation.drive(tween);

    return SlideTransition(
      position: offsetAnimation,
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  static Widget _scaleTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const curve = Curves.easeOutExpo;

    var scaleTween = Tween(begin: 0.8, end: 1.0).chain(CurveTween(curve: curve));
    var fadeTween = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

    return ScaleTransition(
      scale: animation.drive(scaleTween),
      child: FadeTransition(
        opacity: animation.drive(fadeTween),
        child: child,
      ),
    );
  }

  static Widget _heroTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}

/// Extension pour faciliter la navigation
extension GoRouterExtension on BuildContext {
  /// Navigation simple
  void goTo(String location) => go(location);
  void pushTo(String location) => push(location);

  // Auth
  void goToLogin() => go(AppRoutes.login);
  void goToRegister() => go(AppRoutes.register);
  void goToForgotPassword() => push(AppRoutes.forgotPassword);
  void goToOnboarding() => go(AppRoutes.onboarding);

  // Main
  void goToDashboard() => go(AppRoutes.dashboard);
  void goToTransactions() => go(AppRoutes.transactions);
  void goToTransactionDetail(String id) => push(AppRoutes.transactionDetailPath(id));
  void goToScan() => push(AppRoutes.scan);
  void goToInsights() => go(AppRoutes.insights);
  void goToSubscriptions() => push(AppRoutes.subscriptions);
  void goToCoach() => push(AppRoutes.coach);
  void goToProfile() => go(AppRoutes.profile);
  void goToSettings() => push(AppRoutes.settings);
  void goToAccounts() => push(AppRoutes.accounts);
  void goToBudgets() => push(AppRoutes.budgets);
  void goToAddTransaction() => push(AppRoutes.addTransaction);

  /// Pop
  void goBack() => pop();
}
