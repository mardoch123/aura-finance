/// Types d'animation pour la mascotte Félix
enum FelixAnimationType {
  /// Animation idle - Félix en attente, respiration douce
  idle,
  
  /// Animation scan - Félix avec téléphone en train de scanner
  scan,
  
  /// Animation success - Félix saute de joie
  success,
  
  /// Animation alert - Félix pointe du doigt, air vigilant
  alert,
  
  /// Animation celebrate - Félix danse avec confettis
  celebrate,
  
  /// Animation thinking - Félix réfléchit (petite bulle ...)
  thinking,
  
  /// Animation empty - Félix assis, regard vers le haut
  empty,
  
  /// Animation pro - Félix avec couronne et monocle
  pro,
  
  /// Animation streakLow - Félix souriant (jours 1-2)
  streakLow,
  
  /// Animation streakMedium - Félix avec petite flamme (jours 3-6)
  streakMedium,
  
  /// Animation streakHigh - Félix en feu (jour 7+)
  streakHigh,
  
  /// Animation streakLost - Félix avec larme
  streakLost,
}

/// Extension pour obtenir les propriétés des animations
extension FelixAnimationTypeExtension on FelixAnimationType {
  /// Durée de l'animation en millisecondes
  Duration get duration {
    return switch (this) {
      FelixAnimationType.idle => const Duration(milliseconds: 2000),
      FelixAnimationType.scan => const Duration(milliseconds: 1500),
      FelixAnimationType.success => const Duration(milliseconds: 1200),
      FelixAnimationType.alert => const Duration(milliseconds: 800),
      FelixAnimationType.celebrate => const Duration(milliseconds: 2000),
      FelixAnimationType.thinking => const Duration(milliseconds: 1500),
      FelixAnimationType.empty => const Duration(milliseconds: 2000),
      FelixAnimationType.pro => const Duration(milliseconds: 2000),
      FelixAnimationType.streakLow => const Duration(milliseconds: 1500),
      FelixAnimationType.streakMedium => const Duration(milliseconds: 1500),
      FelixAnimationType.streakHigh => const Duration(milliseconds: 2000),
      FelixAnimationType.streakLost => const Duration(milliseconds: 2000),
    };
  }

  /// Si l'animation doit boucler
  bool get shouldLoop {
    return switch (this) {
      FelixAnimationType.idle => true,
      FelixAnimationType.scan => true,
      FelixAnimationType.thinking => true,
      FelixAnimationType.streakHigh => true,
      _ => false,
    };
  }

  /// Taille recommandée pour cette animation
  double get recommendedSize {
    return switch (this) {
      FelixAnimationType.idle => 180,
      FelixAnimationType.scan => 200,
      FelixAnimationType.success => 180,
      FelixAnimationType.alert => 160,
      FelixAnimationType.celebrate => 200,
      FelixAnimationType.thinking => 64,
      FelixAnimationType.empty => 150,
      FelixAnimationType.pro => 180,
      FelixAnimationType.streakLow => 80,
      FelixAnimationType.streakMedium => 90,
      FelixAnimationType.streakHigh => 100,
      FelixAnimationType.streakLost => 80,
    };
  }
}
