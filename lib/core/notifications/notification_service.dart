import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';
import '../../../core/theme/aura_colors.dart';

part 'notification_service.g.dart';

/// Service de gestion des notifications push
/// Notifications locales programmées + notifications à la demande
@riverpod
class NotificationService extends _$NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  @override
  NotificationState build() {
    _initialize();
    return const NotificationState();
  }

  /// Initialise le service de notifications
  Future<void> _initialize() async {
    // Initialisation timezone
    tz.initializeTimeZones();
    
    // Configuration Android
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Configuration iOS
    const ios = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    // Configuration globale
    const initSettings = InitializationSettings(
      android: android,
      iOS: ios,
    );
    
    // Initialisation
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    // Demande les permissions (iOS)
    await _requestPermissions();
    
    // Planifie les notifications récurrentes
    await _scheduleRecurringNotifications();
  }

  /// Demande les permissions de notification
  Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  /// Callback quand l'utilisateur tape sur une notification
  void _onNotificationTap(NotificationResponse response) {
    // TODO: Naviguer vers l'écran approprié selon le type
    debugPrint('Notification tap: ${response.payload}');
  }

  /// Planifie les notifications récurrentes quotidiennes
  Future<void> _scheduleRecurringNotifications() async {
    // Notification matinale (8h00)
    await _scheduleDailyNotification(
      id: 1001,
      title: 'Félix : Bonjour !☀️',
      body: 'Prêt à scanner tes dépenses du jour ?',
      hour: 8,
      minute: 0,
      payload: 'morning_reminder',
    );
    
    // Notification après-midi (14h00)
    await _scheduleDailyNotification(
      id: 1002,
      title: 'Félix : Mi-journée !🌤️',
      body: 'N\'oublie pas de scanner tes tickets de caisse',
      hour: 14,
      minute: 0,
      payload: 'afternoon_reminder',
    );
    
    // Notification du soir (19h00)
    await _scheduleDailyNotification(
      id: 1003,
      title: 'Félix : Déjà le soir ?🌙',
      body: 'Dernière chance de scanner avant de dormir',
      hour: 19,
      minute: 0,
      payload: 'evening_reminder',
    );
  }

  /// Planifie une notification quotidienne
  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    final scheduledTime = tz.TZDateTime(
      tz.local,
      tz.TZDateTime.now().year,
      tz.TZDateTime.now().month,
      tz.TZDateTime.now().day,
      hour,
      minute,
    );

    // Si l'heure est déjà passée aujourd'hui, on programme pour demain
    final now = tz.TZDateTime.now(tz.local);
    final finalTime = scheduledTime.isBefore(now) 
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;

    const androidDetails = AndroidNotificationDetails(
      'daily_reminders',
      'Rappels quotidiens',
      channelDescription: 'Notifications récurrentes pour l\'utilisation quotidienne',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: AuraColors.auraAmber,
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      finalTime,
      platformDetails,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Envoie une notification immédiate
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? category,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'immediate',
      'Notifications immédiates',
      channelDescription: 'Notifications envoyées immédiatement',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: AuraColors.auraAmber,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  /// Envoie une notification de récompense
  Future<void> showRewardNotification({
    required int streakDays,
    required String rewardType,
  }) async {
    String title, body;
    
    switch (streakDays) {
      case 3:
        title = '🎉 Félicitations !';
        body = '3 jours d\'affilée ! Tu gagnes le badge "Assidu"';
      case 7:
        title = '🌟 Une semaine parfaite !';
        body = 'Tu es un vrai pro de la gestion !';
      case 14:
        title = '💪 Deux semaines !';
        body = 'Impressionnant ! Continue comme ça';
      case 30:
        title = '🏆 Un mois complet !';
        body = 'Tu es inarrêtable ! Badge "Légende" débloqué';
      default:
        title = '🔥 Streak : $streakDays jours !';
        body = 'Continue ta série incroyable';
    }

    await showImmediateNotification(
      id: 2000 + streakDays,
      title: title,
      body: body,
      payload: 'streak_reward_$streakDays',
    );
  }

  /// Envoie une notification d'alerte vampire
  Future<void> showVampireAlert({
    required String subscriptionName,
    required double increaseAmount,
    required double increasePercentage,
  }) async {
    await showImmediateNotification(
      id: 3001,
      title: '🧛lix a détecté quelque chose !',
      body: '$subscriptionName a augmenté de ${increasePercentage.round()}% (+${increaseAmount.toStringAsFixed(0)}€/mois)',
      payload: 'vampire_alert',
    );
  }

  /// Envoie une notification de scan réussi
  Future<void> showScanSuccess({
    required double amount,
    required String merchant,
    required int streakDays,
  }) async {
    await showImmediateNotification(
      id: 4001,
      title: '📸 Scan réussi !',
      body: '$amount€ chez $merchant enregistrés. Streak : $streakDays jours ! 🔥',
      payload: 'scan_success',
    );
  }

  /// Envoie une notification de premier scan
  Future<void> showFirstScanSuccess() async {
    await showImmediateNotification(
      id: 4002,
      title: '🎉 Premier scan !',
      body: 'Bienvenue dans l\'automatisation !',
      payload: 'first_scan',
    );
  }

  /// Envoie une notification de dépassement de budget
  Future<void> showBudgetAlert({
    required String category,
    required double spent,
    required double budget,
    required double percentage,
  }) async {
    await showImmediateNotification(
      id: 5001,
      title: '⚠️ Attention budget',
      body: 'Tu as dépensé ${percentage.round()}% de ton budget $category (${spent.toStringAsFixed(0)}€/${budget.toStringAsFixed(0)}€)',
      payload: 'budget_alert',
    );
  }

  /// Annule toutes les notifications programmées
  Future<void> cancelAllScheduled() async {
    await _notifications.cancelAll();
  }

  /// Annule une notification spécifique
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Vérifie si les permissions sont accordées
  Future<bool> arePermissionsGranted() async {
    final details = await _notifications.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp ?? false;
  }
}

/// État du service de notifications
@freezed
class NotificationState with _$NotificationState {
  const factory NotificationState({
    @Default(true) bool notificationsEnabled,
    @Default(3) int dailyRemindersCount,
    @Default([]) List<String> scheduledNotifications,
  }) = _NotificationState;
}

/// Provider pour les paramètres de notification
@riverpod
class NotificationSettings extends _$NotificationSettings {
  @override
  NotificationSettingsState build() {
    return const NotificationSettingsState();
  }
  
  void toggleMorningReminder(bool enabled) {
    state = state.copyWith(morningReminderEnabled: enabled);
  }
  
  void toggleAfternoonReminder(bool enabled) {
    state = state.copyWith(afternoonReminderEnabled: enabled);
  }
  
  void toggleEveningReminder(bool enabled) {
    state = state.copyWith(eveningReminderEnabled: enabled);
  }
  
  void setVampireAlerts(bool enabled) {
    state = state.copyWith(vampireAlertsEnabled: enabled);
  }
  
  void setBudgetAlerts(bool enabled) {
    state = state.copyWith(budgetAlertsEnabled: enabled);
  }
}

@freezed
class NotificationSettingsState with _$NotificationSettingsState {
  const factory NotificationSettingsState({
    @Default(true) bool morningReminderEnabled,
    @Default(true) bool afternoonReminderEnabled,
    @Default(true) bool eveningReminderEnabled,
    @Default(true) bool vampireAlertsEnabled,
    @Default(true) bool budgetAlertsEnabled,
    @Default(true) bool scanSuccessEnabled,
    @Default(true) bool streakNotificationsEnabled,
  }) = _NotificationSettingsState;
}
