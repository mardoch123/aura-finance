import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
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
import '../../features/calculators/presentation/screens/calculators_screen.dart';
import '../../features/calculators/presentation/screens/mortgage_calculator_screen.dart';
import '../../features/calculators/presentation/screens/compound_interest_screen.dart';
import '../../features/calculators/presentation/screens/roi_calculator_screen.dart';
import '../../features/calculators/presentation/screens/currency_converter_screen.dart';
import '../../features/privacy/presentation/screens/privacy_settings_screen.dart';
import '../../features/banking/presentation/screens/banking_screen.dart';
import '../../features/banking/presentation/screens/bank_connection_screen.dart';
import '../../features/banking/presentation/screens/connected_accounts_screen.dart';
import '../../features/shared_accounts/presentation/screens/shared_accounts_list_screen.dart';
import '../../features/shared_accounts/presentation/screens/shared_account_detail_screen.dart';
import '../../features/challenges/presentation/screens/challenges_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/referral/presentation/screens/referral_screen.dart';
import '../../features/travel/presentation/screens/travel_screen.dart';
import '../../features/reconciliation/presentation/screens/reconciliation_screen.dart';
import '../../features/wealth/presentation/screens/wealth_screen.dart';
import '../../features/profile/presentation/screens/language_screen.dart';
import '../../features/reports/presentation/screens/financial_story_viewer.dart';
import '../../features/challenges/presentation/screens/friend_challenges_screen.dart';
import '../../features/dashboard/presentation/screens/zen_dashboard_screen.dart';
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
  
  // Calculators
  static const String calculators = '/calculators';
  static const String mortgageCalculator = '/calculators/mortgage';
  static const String compoundInterest = '/calculators/compound';
  static const String roiCalculator = '/calculators/roi';
  static const String currencyConverter = '/calculators/currency';
  
  // Privacy
  static const String privacySettings = '/privacy';
  
  // Banking
  static const String banking = '/banking';
  static const String bankConnect = '/banking/connect';
  static const String connectedAccounts = '/banking/accounts';
  
  // Shared Accounts
  static const String sharedAccounts = '/shared-accounts';
  static const String sharedAccountDetail = '/shared-accounts/:id';
  
  // Challenges & Gamification
  static const String challenges = '/challenges';
  
  // Reports
  static const String reports = '/reports';
  
  // Referral
  static const String referral = '/referral';
  
  // Travel
  static const String travel = '/travel';
  
  // Reconciliation
  static const String reconciliation = '/reconciliation';
  
  // Wealth / Patrimoine
  static const String wealth = '/wealth';
  
  // Language
  static const String language = '/language';
  
  // Features spéciales
  static const String zenMode = '/zen-mode';
  static const String friendChallenges = '/challenges/friends';
  static const String financialStories = '/stories';

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
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          name: 'forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
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
        
        // ═══════════════════════════════════════════════════════════
        // CALCULATORS
        // ═══════════════════════════════════════════════════════════
        GoRoute(
          path: AppRoutes.calculators,
          name: 'calculators',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const CalculatorsScreen(),
            transitionsBuilder: _slideRightTransition,
          ),
        ),
        GoRoute(
          path: AppRoutes.mortgageCalculator,
          name: 'mortgage-calculator',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const MortgageCalculatorScreen(),
            transitionsBuilder: _slideRightTransition,
          ),
        ),
        GoRoute(
          path: AppRoutes.compoundInterest,
          name: 'compound-interest',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const CompoundInterestScreen(),
            transitionsBuilder: _slideRightTransition,
          ),
        ),
        GoRoute(
          path: AppRoutes.roiCalculator,
          name: 'roi-calculator',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const ROICalculatorScreen(),
            transitionsBuilder: _slideRightTransition,
          ),
        ),
        GoRoute(
          path: AppRoutes.currencyConverter,
          name: 'currency-converter',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const CurrencyConverterScreen(),
            transitionsBuilder: _slideRightTransition,
          ),
        ),
        
        // ═══════════════════════════════════════════════════════════
        // PRIVACY
        // ═══════════════════════════════════════════════════════════
        GoRoute(
          path: AppRoutes.privacySettings,
          name: 'privacy-settings',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const PrivacySettingsScreen(),
            transitionsBuilder: _slideRightTransition,
          ),
        ),
        
        // ═══════════════════════════════════════════════════════════
        // BANKING / OPEN BANKING
        // ═══════════════════════════════════════════════════════════
        GoRoute(
          path: AppRoutes.banking,
          name: 'banking',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const BankingScreen(),
            transitionsBuilder: _slideRightTransition,
          ),
        ),
        GoRoute(
          path: AppRoutes.bankConnect,
          name: 'bank-connect',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) {
            final bankId = state.uri.queryParameters['bank'];
            return CustomTransitionPage(
              key: state.pageKey,
              child: BankConnectionScreen(preselectedBank: bankId),
              transitionsBuilder: _slideRightTransition,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.connectedAccounts,
          name: 'connected-accounts',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const ConnectedAccountsScreen(),
            transitionsBuilder: _slideRightTransition,
          ),
        ),
        
        // ═══════════════════════════════════════════════════════════
        // SHARED ACCOUNTS
        // ═══════════════════════════════════════════════════════════
        GoRoute(
          path: AppRoutes.sharedAccounts,
          name: 'shared-accounts',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const SharedAccountsListScreen(),
            transitionsBuilder: _slideRightTransition,
          ),
        ),
        GoRoute(
          path: AppRoutes.sharedAccountDetail,
          name: 'shared-account-detail',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return CustomTransitionPage(
              key: state.pageKey,
              child: SharedAccountDetailScreen(accountId: id),
              transitionsBuilder: _slideRightTransition,
            );
          },
        ),
        
        // ═══════════════════════════════════════════════════════════
        // CHALLENGES & GAMIFICATION
        // ═══════════════════════════════════════════════════════════
        GoRoute(
          path: AppRoutes.challenges,
          name: 'challenges',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const ChallengesScreen(),
            transitionsBuilder: _slideRightTransition,
          ),
        ),
        
        // ═══════════════════════════════════════════════════════════
        // REPORTS
        // ═══════════════════════════════════════════════════════════
        GoRoute(
          path: AppRoutes.reports,
          name: 'reports',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const ReportsScreen(),
            transitionsBuilder: _slideRightTransition,
          ),
        ),
        
        // ═══════════════════════════════════════════════════════════
        // REFERRAL
        // ═══════════════════════════════════════════════════════════
        GoRoute(
          path: AppRoutes.referral,
          name: 'referral',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const ReferralScreen(),
            transitionsBuilder: _slideRightTransition,
          ),
        ),
        
        // ═══════════════════════════════════════════════════════════
        // TRAVEL
        // ═══════════════════════════════════════════════════════════
        GoRoute(
          path: AppRoutes.travel,
          name: 'travel',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const TravelScreen(),
            transitionsBuilder: _slideRightTransition,
          ),
        ),
        
        // ═══════════════════════════════════════════════════════════
        // RECONCILIATION
        // ═══════════════════════════════════════════════════════════
        GoRoute(
          path: AppRoutes.reconciliation,
          name: 'reconciliation',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const ReconciliationScreen(),
            transitionsBuilder: _slideRightTransition,
          ),
        ),
        
        // ═══════════════════════════════════════════════════════════
        // WEALTH / PATRIMOINE
        // ═══════════════════════════════════════════════════════════
        GoRoute(
          path: AppRoutes.wealth,
          name: 'wealth',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const WealthScreen(),
            transitionsBuilder: _slideRightTransition,
          ),
        ),
        
        //═══════════════════════════════════════════════════════════
        // FEATURES SPÉCIALES
        // ═══════════════════════════════════════════════════════════
        GoRoute(
          path: AppRoutes.zenMode,
          name: 'zen-mode',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const ZenDashboardScreen(),
            transitionsBuilder: _fadeInUpTransition,
            fullscreenDialog: true,
          ),
        ),
        GoRoute(
          path: AppRoutes.friendChallenges,
          name: 'friend-challenges',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const FriendChallengesScreen(),
            transitionsBuilder: _slideRightTransition,
          ),
        ),
        
        // ═══════════════════════════════════════════════════════════
        // LANGUAGE / LANGUE
        // ═══════════════════════════════════════════════════════════
        GoRoute(
          path: AppRoutes.language,
          name: 'language',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const LanguageScreen(),
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

  static Widget _fadeInUpTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const curve = Curves.easeOutCubic;
  
    final opacityTween = Tween(begin: 0.0, end: 1.0).chain(
      CurveTween(curve: curve),
    );
  
    final translateY = Tween(begin: 50.0, end: 0.0).chain(
      CurveTween(curve: curve),
    ).animate(animation);
  
    return FadeTransition(
      opacity: animation.drive(opacityTween),
      child: SlideTransition(
        position: AlwaysStoppedAnimation(
          Offset(0, translateY.value),
        ),
        child: child,
      ),
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
  
  // Calculators
  void goToCalculators() => push(AppRoutes.calculators);
  void goToMortgageCalculator() => push(AppRoutes.mortgageCalculator);
  void goToCompoundInterest() => push(AppRoutes.compoundInterest);
  void goToROICalculator() => push(AppRoutes.roiCalculator);
  void goToCurrencyConverter() => push(AppRoutes.currencyConverter);
  
  // Privacy
  void goToPrivacySettings() => push(AppRoutes.privacySettings);
  
  // Banking
  void goToBanking() => push(AppRoutes.banking);
  void goToBankConnect({String? bankId}) => 
      push('${AppRoutes.bankConnect}${bankId != null ? '?bank=$bankId' : ''}');
  void goToConnectedAccounts() => push(AppRoutes.connectedAccounts);
  
  // Shared Accounts
  void goToSharedAccounts() => push(AppRoutes.sharedAccounts);
  void goToSharedAccountDetail(String id) => push('/shared-accounts/$id');
  
  // Challenges
  void goToChallenges() => push(AppRoutes.challenges);
  
  // Reports
  void goToReports() => push(AppRoutes.reports);
  
  // Referral
  void goToReferral() => push(AppRoutes.referral);
  
  // Travel
  void goToTravel() => push(AppRoutes.travel);
  
  // Reconciliation
  void goToReconciliation() => push(AppRoutes.reconciliation);
  
  // Wealth
  void goToWealth() => push(AppRoutes.wealth);

  // Features spéciales
  void goToZenMode() => push(AppRoutes.zenMode);
  void goToFriendChallenges() => push(AppRoutes.friendChallenges);
  void goToFinancialStories() => push(AppRoutes.financialStories);

  /// Pop
  void goBack() => pop();
}
