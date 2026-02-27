import 'package:freezed_annotation/freezed_annotation.dart';
import 'felix_animation_type.dart';

part 'felix_state.freezed.dart';

/// État de la mascotte Félix
@freezed
class FelixState with _$FelixState {
  const factory FelixState({
    /// Type d'animation actuel
    @Default(FelixAnimationType.idle) FelixAnimationType animationType,
    
    /// Message affiché avec Félix
    String? message,
    
    /// Sous-message (pour les alertes détaillées)
    String? subMessage,
    
    /// Si Félix est visible
    @Default(true) bool isVisible,
    
    /// Niveau de streak actuel (pour les animations de streak)
    @Default(0) int streakDays,
    
    /// Si une animation est en cours
    @Default(false) bool isAnimating,
    
    /// Progression pour les loaders (0.0 à 1.0)
    @Default(0.0) double progress,
    
    /// Texte dynamique pour le scanner (change toutes les 2s)
    String? scanStepText,
    
    /// Index de l'étape de scan actuelle
    @Default(0) int scanStepIndex,
  }) = _FelixState;

  const FelixState._();

  /// Détermine le type d'animation de streak en fonction des jours
  FelixAnimationType get streakAnimationType {
    if (streakDays == 0) return FelixAnimationType.streakLost;
    if (streakDays <= 2) return FelixAnimationType.streakLow;
    if (streakDays <= 6) return FelixAnimationType.streakMedium;
    return FelixAnimationType.streakHigh;
  }

  /// Si Félix affiche une animation de streak
  bool get isStreakAnimation {
    return animationType == FelixAnimationType.streakLow ||
           animationType == FelixAnimationType.streakMedium ||
           animationType == FelixAnimationType.streakHigh ||
           animationType == FelixAnimationType.streakLost;
  }
}

/// Événements que Félix peut afficher
enum FelixEvent {
  /// Transaction ajoutée avec succès
  transactionSuccess,
  
  /// Vampire détecté
  vampireAlert,
  
  /// Objectif atteint
  goalAchieved,
  
  /// Premier scan
  firstScan,
  
  /// Streak perdu
  streakLost,
  
  /// Nouveau niveau débloqué
  levelUp,
  
  /// Bienvenue
  welcome,
}

extension FelixEventExtension on FelixEvent {
  /// Animation associée à l'événement
  FelixAnimationType get animationType {
    return switch (this) {
      FelixEvent.transactionSuccess => FelixAnimationType.success,
      FelixEvent.vampireAlert => FelixAnimationType.alert,
      FelixEvent.goalAchieved => FelixAnimationType.celebrate,
      FelixEvent.firstScan => FelixAnimationType.success,
      FelixEvent.streakLost => FelixAnimationType.streakLost,
      FelixEvent.levelUp => FelixAnimationType.celebrate,
      FelixEvent.welcome => FelixAnimationType.idle,
    };
  }

  /// Durée d'affichage de l'événement
  Duration get displayDuration {
    return switch (this) {
      FelixEvent.transactionSuccess => const Duration(seconds: 2),
      FelixEvent.vampireAlert => const Duration(seconds: 4),
      FelixEvent.goalAchieved => const Duration(seconds: 3),
      FelixEvent.firstScan => const Duration(seconds: 3),
      FelixEvent.streakLost => const Duration(seconds: 3),
      FelixEvent.levelUp => const Duration(seconds: 3),
      FelixEvent.welcome => const Duration(seconds: 2),
    };
  }
}
