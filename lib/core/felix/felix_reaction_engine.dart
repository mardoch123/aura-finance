import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'felix_animation_type.dart';
import 'felix_controller.dart';
import 'felix_state.dart';

/// Moteur de réactions contextuelles de Félix
/// Analyse les actions utilisateur et déclenche les réactions appropriées
class FelixReactionEngine {
  final WidgetRef ref;
  
  FelixReactionEngine(this.ref);
  
  /// Réagit à l'ajout d'une transaction
  void onTransactionAdded({
    required double amount,
    required String category,
    bool isFirstTransaction = false,
    bool isScan = false,
  }) {
    final controller = ref.read(felixControllerProvider.notifier);
    
    if (isFirstTransaction) {
      controller.triggerEvent(
        FelixEvent.firstScan,
        customMessage: 'Première transaction ! 🎉',
        customSubMessage: 'Tu es sur la bonne voie',
      );
    } else if (isScan) {
      // Réaction selon le montant
      if (amount.abs() > 100) {
        controller.triggerEvent(
          FelixEvent.transactionSuccess,
          customMessage: 'Grosse dépense détectée !',
          customSubMessage: '${amount.abs().toStringAsFixed(0)}€ enregistrés',
        );
      } else {
        controller.setAnimation(
          FelixAnimationType.success,
          message: 'Scan réussi !',
          subMessage: 'Transaction enregistrée',
        );
      }
    } else {
      controller.setAnimation(
        FelixAnimationType.success,
        message: 'Ajouté !',
      );
    }
  }
  
  /// Réagit à la détection d'un vampire
  void onVampireDetected({
    required String subscriptionName,
    required double oldAmount,
    required double newAmount,
  }) {
    final controller = ref.read(felixControllerProvider.notifier);
    final increase = ((newAmount - oldAmount) / oldAmount * 100).round();
    
    controller.triggerEvent(
      FelixEvent.vampireAlert,
      customMessage: '$subscriptionName a augmenté ! 🧛',
      customSubMessage: '+$increase% soit +${(newAmount - oldAmount).toStringAsFixed(0)}€/mois',
    );
  }
  
  /// Réagit à l'atteinte d'un objectif
  void onGoalAchieved({
    required String goalName,
    required double targetAmount,
  }) {
    final controller = ref.read(felixControllerProvider.notifier);
    
    controller.triggerEvent(
      FelixEvent.goalAchieved,
      customMessage: 'Objectif atteint ! 🎯',
      customSubMessage: '$goalName : ${targetAmount.toStringAsFixed(0)}€',
    );
  }
  
  /// Réagit à la perte d'un streak
  void onStreakLost({required int previousStreak}) {
    final controller = ref.read(felixControllerProvider.notifier);
    
    controller.triggerEvent(
      FelixEvent.streakLost,
      customMessage: 'Série de $previousStreak jours perdue...',
      customSubMessage: 'Ne t\'inquiète pas, reprends demain !',
    );
  }
  
  /// Réagit à un nouveau streak
  void onStreakMilestone({required int streakDays}) {
    final controller = ref.read(felixControllerProvider.notifier);
    
    String message;
    String? subMessage;
    
    switch (streakDays) {
      case 3:
        message = '3 jours d\'affilée ! 🔥';
        subMessage = 'Tu prends de bonnes habitudes';
      case 7:
        message = 'Une semaine parfaite ! 🌟';
        subMessage = 'Tu es un vrai pro de la gestion';
      case 14:
        message = 'Deux semaines ! 💪';
        subMessage = 'Impressionnant !';
      case 30:
        message = 'Un mois complet ! 🏆';
        subMessage = 'Tu es inarrêtable !';
      default:
        message = '$streakDays jours de suite !';
        subMessage = 'Continue comme ça !';
    }
    
    controller.showStreak(streakDays);
    Future.delayed(const Duration(milliseconds: 300), () {
      controller.setAnimation(
        FelixAnimationType.celebrate,
        message: message,
        subMessage: subMessage,
      );
    });
  }
  
  /// Réagit à une économie significative
  void onSavingsMilestone({
    required double totalSavings,
    required double monthlySavings,
  }) {
    final controller = ref.read(felixControllerProvider.notifier);
    
    if (monthlySavings > 0) {
      controller.setAnimation(
        FelixAnimationType.celebrate,
        message: 'Tu économises ! 💰',
        subMessage: '+${monthlySavings.toStringAsFixed(0)}€ ce mois-ci',
      );
    } else {
      controller.setAnimation(
        FelixAnimationType.alert,
        message: 'Attention aux dépenses',
        subMessage: 'Tu dépenses ${monthlySavings.abs().toStringAsFixed(0)}€ de plus',
      );
    }
  }
  
  /// Réagit à l'ouverture de l'app selon l'heure
  void onAppOpen({required DateTime now}) {
    final controller = ref.read(felixControllerProvider.notifier);
    final hour = now.hour;
    
    String message;
    if (hour < 6) {
      message = 'Tu es matinal ! 🌙';
    } else if (hour < 12) {
      message = 'Bonne journée ! ☀️';
    } else if (hour < 18) {
      message = 'Bon après-midi ! 🌤️';
    } else {
      message = 'Bonne soirée ! 🌙';
    }
    
    controller.setAnimation(
      FelixAnimationType.idle,
      message: message,
    );
  }
  
  /// Réagit à une longue absence
  void onWelcomeBack({required int daysAbsent}) {
    final controller = ref.read(felixControllerProvider.notifier);
    
    if (daysAbsent > 7) {
      controller.triggerEvent(
        FelixEvent.welcome,
        customMessage: 'Tu nous as manqué ! 👋',
        customSubMessage: 'Ça fait $daysAbsent jours, on reprend ?',
      );
    } else if (daysAbsent > 1) {
      controller.setAnimation(
        FelixAnimationType.idle,
        message: 'Content de te revoir !',
      );
    }
  }
  
  /// Réagit à un scan qui échoue
  void onScanFailed({String? reason}) {
    final controller = ref.read(felixControllerProvider.notifier);
    
    controller.setAnimation(
      FelixAnimationType.thinking,
      message: 'Je n\'ai pas bien compris...',
      subMessage: reason ?? 'Essaye avec une meilleure luminosité',
    );
  }
  
  /// Réagit à un défi gagné
  void onChallengeWon({
    required String challengeName,
    required String reward,
  }) {
    final controller = ref.read(felixControllerProvider.notifier);
    
    controller.triggerEvent(
      FelixEvent.levelUp,
      customMessage: 'Défi réussi ! 🏆',
      customSubMessage: '$challengeName : $reward',
    );
  }
  
  /// Réagit à une nouvelle catégorie débloquée
  void onCategoryUnlocked({required String categoryName}) {
    final controller = ref.read(felixControllerProvider.notifier);
    
    controller.setAnimation(
      FelixAnimationType.celebrate,
      message: 'Nouvelle catégorie !',
      subMessage: 'Tu as débloqué "$categoryName"',
    );
  }
  
  /// Réagit à un mois sans vampire
  void onVampireFreeMonth() {
    final controller = ref.read(felixControllerProvider.notifier);
    
    controller.setAnimation(
      FelixAnimationType.celebrate,
      message: 'Aucun vampire ce mois-ci ! 🛡️',
      subMessage: 'Tes abonnements sont stables',
    );
  }
}

/// Provider pour accéder au moteur de réactions
final felixReactionEngineProvider = Provider<FelixReactionEngine>((ref) {
  return FelixReactionEngine(ref);
});
