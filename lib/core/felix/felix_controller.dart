import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/services.dart';
import 'felix_state.dart';
import 'felix_animation_type.dart';

part 'felix_controller.g.dart';

/// Messages de scan qui changent toutes les 2 secondes
const List<String> _scanMessagesFr = [
  'Lecture du reçu...',
  'Identification du marchand...',
  'Catégorisation...',
  'Presque...',
];

const List<String> _scanMessagesEn = [
  'Reading receipt...',
  'Identifying merchant...',
  'Categorizing...',
  'Almost done...',
];

/// Controller pour gérer l'état et les animations de Félix
@riverpod
class FelixController extends _$FelixController {
  Timer? _scanTimer;
  Timer? _autoHideTimer;
  Timer? _progressTimer;
  
  @override
  FelixState build() {
    // Nettoyer les timers quand le provider est détruit
    ref.onDispose(() {
      _scanTimer?.cancel();
      _autoHideTimer?.cancel();
      _progressTimer?.cancel();
    });
    
    return const FelixState();
  }

  /// Change l'animation de Félix
  void setAnimation(FelixAnimationType type, {String? message, String? subMessage}) {
    _autoHideTimer?.cancel();
    
    state = state.copyWith(
      animationType: type,
      message: message,
      subMessage: subMessage,
      isVisible: true,
      isAnimating: true,
    );

    // Feedback haptique selon l'animation
    _triggerHaptic(type);
  }

  /// Déclenche un événement Félix
  void triggerEvent(FelixEvent event, {String? customMessage, String? customSubMessage}) {
    final message = customMessage ?? _getDefaultMessage(event);
    final subMessage = customSubMessage ?? _getDefaultSubMessage(event);
    
    setAnimation(event.animationType, message: message, subMessage: subMessage);
    
    // Auto-hide après la durée de l'événement (sauf pour certaines animations)
    if (!event.animationType.shouldLoop) {
      _autoHideTimer = Timer(event.displayDuration, () {
        hide();
      });
    }
  }

  /// Démarre l'animation de scan avec messages changeants
  void startScanning({bool isFrench = true}) {
    _scanTimer?.cancel();
    _progressTimer?.cancel();
    
    final messages = isFrench ? _scanMessagesFr : _scanMessagesEn;
    var stepIndex = 0;
    
    state = state.copyWith(
      animationType: FelixAnimationType.scan,
      scanStepText: messages[0],
      scanStepIndex: 0,
      progress: 0.0,
      isVisible: true,
    );

    // Change le message toutes les 2 secondes
    _scanTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      stepIndex = (stepIndex + 1) % messages.length;
      state = state.copyWith(
        scanStepText: messages[stepIndex],
        scanStepIndex: stepIndex,
      );
    });

    // Simule la progression
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final newProgress = state.progress + 0.02;
      if (newProgress >= 1.0) {
        timer.cancel();
      }
      state = state.copyWith(progress: newProgress.clamp(0.0, 1.0));
    });
  }

  /// Arrête l'animation de scan
  void stopScanning() {
    _scanTimer?.cancel();
    _progressTimer?.cancel();
    state = state.copyWith(
      scanStepText: null,
      scanStepIndex: 0,
      progress: 0.0,
    );
  }

  /// Affiche Félix en mode réflexion (pour le coach IA)
  void showThinking() {
    setAnimation(FelixAnimationType.thinking);
  }

  /// Cache Félix
  void hide() {
    _scanTimer?.cancel();
    _autoHideTimer?.cancel();
    state = state.copyWith(isVisible: false, isAnimating: false);
  }

  /// Met à jour le streak
  void updateStreak(int days) {
    state = state.copyWith(streakDays: days);
  }

  /// Affiche Félix avec une animation de streak
  void showStreak(int days) {
    updateStreak(days);
    
    final type = days == 0 
        ? FelixAnimationType.streakLost 
        : days <= 2 
            ? FelixAnimationType.streakLow 
            : days <= 6 
                ? FelixAnimationType.streakMedium 
                : FelixAnimationType.streakHigh;
    
    setAnimation(type);
  }

  /// Affiche Félix pour l'écran vide (aucune transaction)
  void showEmpty() {
    setAnimation(FelixAnimationType.empty);
  }

  /// Affiche Félix en mode Pro
  void showPro() {
    setAnimation(FelixAnimationType.pro);
  }

  /// Déclenche le feedback haptique approprié
  void _triggerHaptic(FelixAnimationType type) {
    switch (type) {
      case FelixAnimationType.success:
      case FelixAnimationType.celebrate:
        HapticFeedback.lightImpact();
        Future.delayed(const Duration(milliseconds: 100), () {
          HapticFeedback.lightImpact();
        });
        break;
      case FelixAnimationType.alert:
      case FelixAnimationType.streakLost:
        HapticFeedback.heavyImpact();
        break;
      case FelixAnimationType.vampireAlert:
        HapticFeedback.mediumImpact();
        break;
      default:
        HapticFeedback.lightImpact();
    }
  }

  /// Retourne le message par défaut pour un événement
  String _getDefaultMessage(FelixEvent event) {
    return switch (event) {
      FelixEvent.transactionSuccess => 'Transaction enregistrée !',
      FelixEvent.vampireAlert => 'Félix a détecté quelque chose ! 🧛',
      FelixEvent.goalAchieved => 'Bravo ! Objectif atteint 🎉',
      FelixEvent.firstScan => 'Premier scan réussi !',
      FelixEvent.streakLost => 'Oh non... Série perdue 😢',
      FelixEvent.levelUp => 'Niveau supérieur ! 🎊',
      FelixEvent.welcome => 'Bienvenue !',
    };
  }

  /// Retourne le sous-message par défaut pour un événement
  String? _getDefaultSubMessage(FelixEvent event) {
    return switch (event) {
      FelixEvent.vampireAlert => 'Netflix a augmenté de 3€/mois',
      FelixEvent.goalAchieved => 'Vous avez atteint votre objectif vacances',
      FelixEvent.streakLost => 'Ne lâchez pas, reprenez demain !',
      _ => null,
    };
  }
}
