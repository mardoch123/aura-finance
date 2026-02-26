import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_state.freezed.dart';
part 'onboarding_state.g.dart';

/// État du processus d'onboarding
@freezed
class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(0) int currentStep,
    @Default(false) bool isLoading,
    @Default(false) bool isCompleted,
    String? errorMessage,
    
    // Slide 1: Revenu mensuel
    @Default(0) double monthlyIncome,
    
    // Slide 2: Objectifs financiers
    @Default([]) List<String> selectedGoals,
    
    // Slide 3: Abonnements
    @Default([]) List<String> selectedSubscriptions,
    
    // Slide 4: Gestion actuelle du budget
    String? currentBudgetMethod,
    
    // Slide 5: Notifications
    @Default(true) bool notificationsEnabled,
  }) = _OnboardingState;

  factory OnboardingState.fromJson(Map<String, dynamic> json) =>
      _$OnboardingStateFromJson(json);
}

/// Objectifs financiers disponibles
class FinancialGoals {
  static const String save = 'save';
  static const String travel = 'travel';
  static const String debt = 'debt';
  static const String invest = 'invest';
  static const String retirement = 'retirement';
  static const String house = 'house';
  static const String emergency = 'emergency';
  static const String freedom = 'freedom';

  static const Map<String, String> labels = {
    save: 'Épargner',
    travel: 'Voyager',
    debt: 'Rembourser dettes',
    invest: 'Investir',
    retirement: 'Retraite',
    house: 'Maison',
    emergency: 'Urgences',
    freedom: 'Liberté financière',
  };

  static const Map<String, String> icons = {
    save: '💰',
    travel: '✈️',
    debt: '💳',
    invest: '📈',
    retirement: '🏖️',
    house: '🏠',
    emergency: '🚨',
    freedom: '🦅',
  };
}

/// Abonnements populaires
class PopularSubscriptions {
  static const String netflix = 'netflix';
  static const String spotify = 'spotify';
  static const String disney = 'disney';
  static const String amazon = 'amazon';
  static const String apple = 'apple';
  static const String youtube = 'youtube';
  static const String gym = 'gym';
  static const String phone = 'phone';

  static const Map<String, String> labels = {
    netflix: 'Netflix',
    spotify: 'Spotify',
    disney: 'Disney+',
    amazon: 'Amazon Prime',
    apple: 'Apple One',
    youtube: 'YouTube Premium',
    gym: 'Salle de sport',
    phone: 'Forfait mobile',
  };

  static const Map<String, String> icons = {
    netflix: '🎬',
    spotify: '🎵',
    disney: '✨',
    amazon: '📦',
    apple: '🍎',
    youtube: '▶️',
    gym: '💪',
    phone: '📱',
  };

  static const Map<String, double> defaultAmounts = {
    netflix: 17.99,
    spotify: 10.99,
    disney: 11.99,
    amazon: 6.99,
    apple: 14.95,
    youtube: 11.99,
    gym: 29.99,
    phone: 19.99,
  };
}

/// Méthodes de gestion de budget
class BudgetMethods {
  static const String none = 'none';
  static const String spreadsheet = 'spreadsheet';
  static const String otherApp = 'other_app';
  static const String envelopes = 'envelopes';

  static const Map<String, String> labels = {
    none: 'Pas du tout',
    spreadsheet: 'Tableur Excel',
    otherApp: 'Autre app',
    envelopes: 'Enveloppes',
  };

  static const Map<String, String> icons = {
    none: '🤷',
    spreadsheet: '📊',
    otherApp: '📱',
    envelopes: '✉️',
  };

  static const Map<String, String> descriptions = {
    none: 'Je ne suis pas du tout organisé',
    spreadsheet: 'J\'utilise Excel ou Google Sheets',
    otherApp: 'J\'utilise une autre application',
    envelopes: 'Méthode des enveloppes physiques',
  };
}

/// Résultat d'une opération d'onboarding
sealed class OnboardingResult {
  const OnboardingResult();
}

class OnboardingSuccess extends OnboardingResult {
  const OnboardingSuccess();
}

class OnboardingFailure extends OnboardingResult {
  final String message;
  const OnboardingFailure(this.message);
}
