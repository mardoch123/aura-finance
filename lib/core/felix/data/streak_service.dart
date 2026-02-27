import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../../services/supabase_service.dart';
import '../../felix/felix_controller.dart';
import '../../felix/felix_animation_type.dart';

part 'streak_service.g.dart';

/// Service de gestion des streaks quotidiens
/// Suit la régularité de l'utilisateur et déclenche les récompenses
@riverpod
class StreakService extends _$StreakService {
  static const String _prefsKey = 'daily_streak';
  static const String _lastCheckKey = 'last_streak_check';
  static const String _totalDaysKey = 'total_active_days';
  static const String _bestStreakKey = 'best_streak_ever';
  
  @override
  StreakState build() {
    // Charge l'état initial
    _loadStreakData();
    return const StreakState();
  }

  /// Charge les données depuis SharedPreferences
  Future<void> _loadStreakData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final currentStreak = prefs.getInt(_prefsKey) ?? 0;
    final lastCheck = prefs.getString(_lastCheckKey);
    final totalDays = prefs.getInt(_totalDaysKey) ?? 0;
    final bestStreak = prefs.getInt(_bestStreakKey) ?? 0;
    
    state = state.copyWith(
      currentStreak: currentStreak,
      lastCheckDate: lastCheck != null ? DateTime.parse(lastCheck) : null,
      totalActiveDays: totalDays,
      bestStreak: bestStreak,
    );
  }

  /// Vérifie et met à jour le streak quotidien
  /// À appeler à chaque ouverture de l'app
  Future<void> checkAndUpdateStreak() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Si jamais vérifié aujourd'hui
    if (state.lastCheckDate == null || 
        state.lastCheckDate!.day != today.day ||
        state.lastCheckDate!.month != today.month ||
        state.lastCheckDate!.year != today.year) {
      
      final prefs = await SharedPreferences.getInstance();
      
      // Si la dernière vérification était hier → streak continue
      if (state.lastCheckDate != null &&
          _isYesterday(state.lastCheckDate!, today)) {
        // Continue le streak
        final newStreak = state.currentStreak + 1;
        final newTotalDays = state.totalActiveDays + 1;
        final newBestStreak = newStreak > state.bestStreak ? newStreak : state.bestStreak;
        
        state = state.copyWith(
          currentStreak: newStreak,
          lastCheckDate: today,
          totalActiveDays: newTotalDays,
          bestStreak: newBestStreak,
        );
        
        // Sauvegarde
        await prefs.setInt(_prefsKey, newStreak);
        await prefs.setString(_lastCheckKey, today.toIso8601String());
        await prefs.setInt(_totalDaysKey, newTotalDays);
        await prefs.setInt(_bestStreakKey, newBestStreak);
        
        // Réactions Félix
        _triggerFelixReaction(newStreak);
        
      } else if (state.lastCheckDate != null) {
        // Streak brisé
        final newTotalDays = state.totalActiveDays + 1;
        
        state = state.copyWith(
          currentStreak: 1, // Reset à 1 (aujourd'hui)
          lastCheckDate: today,
          totalActiveDays: newTotalDays,
        );
        
        // Sauvegarde
        await prefs.setInt(_prefsKey, 1);
        await prefs.setString(_lastCheckKey, today.toIso8601String());
        await prefs.setInt(_totalDaysKey, newTotalDays);
        
        // Réaction Félix pour perte de streak
        _triggerStreakLost();
      } else {
        // Premier jour
        state = state.copyWith(
          currentStreak: 1,
          lastCheckDate: today,
          totalActiveDays: 1,
        );
        
        await prefs.setInt(_prefsKey, 1);
        await prefs.setString(_lastCheckKey, today.toIso8601String());
        await prefs.setInt(_totalDaysKey, 1);
        
        // Félix de bienvenue
        ref.read(felixControllerProvider.notifier).setAnimation(
          FelixAnimationType.success,
          message: 'Premier jour !🎉          subMessage: 'Ton streak commence maintenant',
        );
      }
    }
  }

  /// Déclenche les réactions Félix selon le streak
  void _triggerFelixReaction(int streakDays) {
    final felixController = ref.read(felixControllerProvider.notifier);
    
    if (streakDays == 1) {
      felixController.setAnimation(
        FelixAnimationType.streakLow,
        message: 'Première connexion !',
        subMessage: 'Streak : 1 jour🔥',
      );
    } else if (streakDays == 3) {
      felixController.setAnimation(
        FelixAnimationType.streakMedium,
        message: '3 jours d\'affilée !🔥',
        subMessage: 'Tu prends de bonnes habitudes',
      );
    } else if (streakDays == 7) {
      felixController.setAnimation(
        FelixAnimationType.streakMedium,
        message: 'Une semaine parfaite !🌟        subMessage: 'Tu es un vrai pro',
      );
    } else if (streakDays == 14) {
      felixController.setAnimation(
        FelixAnimationType.celebrate,
        message: 'Deux semaines !💪        subMessage: 'Impressionnant !',
      );
    } else if (streakDays == 30) {
      felixController.setAnimation(
        FelixAnimationType.celebrate,
        message: 'Un mois complet !        subMessage: 'Tu es inarrêtable',
      );
    } else if (streakDays > 30) {
      // Milestone spécial
      final felix = ref.read(felixControllerProvider.notifier);
      felix.setAnimation(
        FelixAnimationType.streakHigh,
        message: '$streakDays jours d\'affilée !🔥🔥',
        subMessage: 'Record absolu !',
      );
    } else {
      // Réaction standard
      felixController.setAnimation(
        FelixAnimationType.success,
        message: 'Streak : $streakDays jours !',
        subMessage: 'Continue comme ça',
      );
    }
  }

  /// Réaction quand le streak est perdu
  void _triggerStreakLost() {
    ref.read(felixControllerProvider.notifier).setAnimation(
      FelixAnimationType.streakLost,
      message: 'Oh non... Serie perdue😢      subMessage: 'Reprends dès demain !',
    );
  }

  /// Reset manuel (pour tests)
  Future<void> resetStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    await prefs.remove(_lastCheckKey);
    await prefs.remove(_totalDaysKey);
    await prefs.remove(_bestStreakKey);
    
    state = const StreakState();
    await _loadStreakData();
  }

  /// Si la date est hier
  bool _isYesterday(DateTime lastDate, DateTime today) {
    final yesterday = today.subtract(const Duration(days: 1));
    return lastDate.day == yesterday.day &&
           lastDate.month == yesterday.month &&
           lastDate.year == yesterday.year;
  }
}

/// État du streak quotidien
@freezed
class StreakState with _$StreakState {
  const factory StreakState({
    /// Nombre de jours consécutifs d'activité
    @Default(0) int currentStreak,
    
    /// Date de la dernière vérification
    DateTime? lastCheckDate,
    
    /// Nombre total de jours d'activité (toute la vie)
    @Default(0) int totalActiveDays,
    
    /// Meilleur streak de tous les temps
    @Default(0) int bestStreak,
    
    /// Si l'utilisateur s'est connecté aujourd'hui
    @Default(false) bool isActiveToday,
  }) = _StreakState;
  
  const StreakState._();
  
  /// Pourcentage de réussite par rapport au streak record
  double get consistencyRate {
    if (bestStreak == 0) return 0;
    return (totalActiveDays / (bestStreak > 0 ? bestStreak : 1) * 100).clamp(0, 100);
  }
  
  /// Badge basé sur le streak
  String get badge {
    if (currentStreak >= 100) return '🏆 Légende';
    if (currentStreak >= 50) return '🏅 Or';
    if (currentStreak >= 30) return '🥈 Argent';
    if (currentStreak >= 14) return '🥉 Bronze';
    if (currentStreak >= 7) return '🔥 Régulier';
    if (currentStreak >= 3) return '📅 Assidu';
    if (currentStreak >= 1) return '🆕 Débutant';
    return '👻 Inactif';
  }
}

/// Provider pour lancer la vérification automatique
final streakCheckProvider = Provider<Future<void>>((ref) async {
  // Exécute automatiquement quand l'app démarre
  await ref.read(streakServiceProvider.notifier).checkAndUpdateStreak();
});
