import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service de retours haptiques pour Aura Finance
/// Fournit des vibrations subtiles pour enrichir l'expérience utilisateur
/// 
/// Usage:
/// ```dart
/// HapticService.lightTap();
/// HapticService.success();
/// ```
class HapticService {
  HapticService._();

  static bool _enabled = true;

  /// Active ou désactive les retours haptiques
  static set enabled(bool value) => _enabled = value;

  /// Vérifie si les haptics sont activés
  static bool get isEnabled => _enabled;

  // ═══════════════════════════════════════════════════════════
  // FEEDBACKS DE BASE
  // ═══════════════════════════════════════════════════════════

  /// Impact léger - pour les taps sur les cartes, boutons
  /// Usage: tap sur une transaction, sélection d'un item
  static void lightTap() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  /// Impact moyen - pour les actions importantes
  /// Usage: confirmation de swipe, validation
  static void mediumTap() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Impact fort - pour les erreurs ou alertes importantes
  /// Usage: alerte Gardien, erreur critique
  static void heavyTap() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Sélection - pour les pickers et sélections
  /// Usage: changement de valeur dans un picker
  static void selection() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  // ═══════════════════════════════════════════════════════════
  // FEEDBACKS COMPOSÉS
  // ═══════════════════════════════════════════════════════════

  /// Succès - série de 2 light taps avec délai
  /// Usage: confirmation de scan, transaction ajoutée
  static Future<void> success() async {
    if (!_enabled) return;
    
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    if (_enabled) {
      HapticFeedback.lightImpact();
    }
  }

  /// Erreur - impact fort suivi d'un medium
  /// Usage: scan échoué, erreur de connexion
  static Future<void> error() async {
    if (!_enabled) return;
    
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    if (_enabled) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Avertissement - double medium tap
  /// Usage: alerte de budget, limite atteinte
  static Future<void> warning() async {
    if (!_enabled) return;
    
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    if (_enabled) {
      HapticFeedback.mediumImpact();
    }
  }

  // ═══════════════════════════════════════════════════════════
  // FEEDBACKS SPÉCIFIQUES AURA
  // ═══════════════════════════════════════════════════════════

  /// Scan démarré - pulse léger
  /// Usage: lorsque l'utilisateur appuie sur le bouton scan
  static void scanStarted() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Scan réussi - pattern de succès
  /// Usage: ticket scanné avec succès
  static Future<void> scanSuccess() async {
    if (!_enabled) return;
    await success();
  }

  /// Scan échoué - pattern d'erreur
  /// Usage: impossible de lire le ticket
  static Future<void> scanFailed() async {
    if (!_enabled) return;
    await error();
  }

  /// Vampire détecté - pattern d'alerte spécial
  /// Usage: hausse de prix détectée sur un abonnement
  static Future<void> vampireDetected() async {
    if (!_enabled) return;
    
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    if (_enabled) {
      HapticFeedback.mediumImpact();
    }
    await Future.delayed(const Duration(milliseconds: 100));
    if (_enabled) {
      HapticFeedback.lightImpact();
    }
  }

  /// Transaction ajoutée - confirmation subtile
  /// Usage: nouvelle transaction créée
  static void transactionAdded() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  /// Swipe effectué - feedback de mouvement
  /// Usage: suppression d'une transaction par swipe
  static void swipe() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Pull to refresh - feedback de résistance
  /// Usage: lors du pull to refresh
  static void refresh() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  /// Navigation - changement d'onglet
  /// Usage: tap sur un item de bottom navigation
  static void navigation() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Toggle - changement d'état d'un switch
  /// Usage: activation/désactivation d'une option
  static void toggle() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  /// Long press - pression longue détectée
  /// Usage: menu contextuel, drag & drop
  static void longPress() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Scroll limit - atteinte d'une limite de scroll
  /// Usage: bounce en haut ou en bas d'une liste
  static void scrollLimit() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  /// Picker tick - changement dans un picker
  /// Usage: roulette de sélection
  static void pickerTick() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Achievement unlocked - pattern de célébration
  /// Usage: objectif atteint, badge débloqué
  static Future<void> achievement() async {
    if (!_enabled) return;
    
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    if (_enabled) {
      HapticFeedback.lightImpact();
    }
    await Future.delayed(const Duration(milliseconds: 80));
    if (_enabled) {
      HapticFeedback.mediumImpact();
    }
    await Future.delayed(const Duration(milliseconds: 80));
    if (_enabled) {
      HapticFeedback.lightImpact();
    }
  }

  // ═══════════════════════════════════════════════════════════
  // UTILITAIRES
  // ═══════════════════════════════════════════════════════════

  /// Exécute un pattern personnalisé de vibrations
  /// 
  /// [pattern] : liste de durées en millisecondes (positif = vibration, négatif = pause)
  /// Exemple: [100, -50, 100, -50, 200] = vibration 100ms, pause 50ms, etc.
  static Future<void> customPattern(List<int> pattern) async {
    if (!_enabled) return;
    
    for (final duration in pattern) {
      if (duration > 0) {
        HapticFeedback.lightImpact();
        await Future.delayed(Duration(milliseconds: duration));
      } else {
        await Future.delayed(Duration(milliseconds: duration.abs()));
      }
    }
  }

  /// Vibration continue pendant une durée donnée (simulée)
  /// Note: iOS ne supporte pas les vibrations continues
  static Future<void> vibrate({Duration duration = const Duration(milliseconds: 500)}) async {
    if (!_enabled) return;
    
    final intervals = duration.inMilliseconds ~/ 50;
    for (var i = 0; i < intervals; i++) {
      HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }
}

/// Extension pour faciliter l'utilisation des haptics avec les widgets
extension HapticExtension on Widget {
  /// Ajoute un feedback haptique au tap
  Widget withHapticTap({
    VoidCallback? onTap,
    HapticType type = HapticType.light,
  }) {
    return GestureDetector(
      onTap: () {
        switch (type) {
          case HapticType.light:
            HapticService.lightTap();
            break;
          case HapticType.medium:
            HapticService.mediumTap();
            break;
          case HapticType.heavy:
            HapticService.heavyTap();
            break;
          case HapticType.success:
            HapticService.success();
            break;
          case HapticType.error:
            HapticService.error();
            break;
        }
        onTap?.call();
      },
      child: this,
    );
  }
}

/// Types de feedback haptiques disponibles
enum HapticType {
  light,
  medium,
  heavy,
  success,
  error,
}
