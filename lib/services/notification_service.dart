import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../core/haptics/haptic_service.dart';

/// Service de notifications pour Aura Finance
class NotificationService {
  NotificationService._();
  
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;
  
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  
  /// Initialise les notifications
  Future<void> initialize() async {
    if (_initialized) return;
    
    tz_data.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    _initialized = true;
  }
  
  void _onNotificationTap(NotificationResponse response) {
    // TODO: Navigation vers l'écran approprié
    final payload = response.payload;
    if (payload != null) {
      // Parse payload et naviguer
    }
  }
  
  // ═══════════════════════════════════════════════════════════
  // PERMISSIONS
  // ═══════════════════════════════════════════════════════════
  
  /// Demande les permissions de notification
  Future<bool> requestPermissions() async {
    final result = await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    return result ?? true;
  }
  
  // ═══════════════════════════════════════════════════════════
  // NOTIFICATIONS IMMÉDIATES
  // ═══════════════════════════════════════════════════════════
  
  /// Affiche une notification simple
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    if (!_initialized) await initialize();
    
    final androidDetails = AndroidNotificationDetails(
      'aura_channel',
      'Aura Finance',
      channelDescription: 'Notifications d\'Aura Finance',
      importance: _toAndroidImportance(priority),
      priority: _toAndroidPriority(priority),
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    
    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(id, title, body, details, payload: payload);
    
    // Feedback haptique
    HapticService.lightTap();
  }
  
  // ═══════════════════════════════════════════════════════════
  // NOTIFICATIONS SPÉCIFIQUES
  // ═══════════════════════════════════════════════════════════
  
  /// Notification de vampire détecté
  Future<void> showVampireAlert({
    required String subscriptionName,
    required double oldPrice,
    required double newPrice,
    required double increasePercentage,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '🧛 Vampire détecté !',
      body: '$subscriptionName a augmenté de ${increasePercentage.toStringAsFixed(0)}% '
            '(de ${oldPrice.toStringAsFixed(2)}€ à ${newPrice.toStringAsFixed(2)}€)',
      priority: NotificationPriority.high,
      payload: 'vampire:$subscriptionName',
    );
    
    HapticService.vampireDetected();
  }
  
  /// Notification de prédiction de solde
  Future<void> showBalancePrediction({
    required DateTime date,
    required double predictedBalance,
    required String status,
  }) async {
    String emoji = status == 'safe' ? '✅' : status == 'warning' ? '⚠️' : '🚨';
    String message = status == 'safe'
        ? 'Votre solde sera de ${predictedBalance.toStringAsFixed(2)}€'
        : 'Attention : risque de découvert le ${date.day}/${date.month}';
    
    await showNotification(
      id: 1001,
      title: '$emoji Prédiction financière',
      body: message,
      priority: status == 'danger' ? NotificationPriority.high : NotificationPriority.normal,
    );
  }
  
  /// Notification de budget dépassé
  Future<void> showBudgetAlert({
    required String category,
    required double percentageUsed,
  }) async {
    await showNotification(
      id: 1002,
      title: '💰 Alerte budget',
      body: 'Vous avez utilisé ${percentageUsed.toStringAsFixed(0)}% de votre budget $category',
      priority: NotificationPriority.high,
    );
  }
  
  /// Notification de transaction récurrente à venir
  Future<void> showUpcomingSubscription({
    required String name,
    required double amount,
    required int daysUntil,
  }) async {
    await showNotification(
      id: 1003,
      title: '📅 Abonnement à venir',
      body: '$name (${amount.toStringAsFixed(2)}€) dans $daysUntil jour${daysUntil > 1 ? 's' : ''}',
    );
  }
  
  /// Notification de résumé hebdomadaire
  Future<void> showWeeklySummary({
    required double totalSpent,
    required double totalIncome,
  }) async {
    final net = totalIncome - totalSpent;
    final emoji = net >= 0 ? '📈' : '📉';
    
    await showNotification(
      id: 1004,
      title: '$emoji Résumé de la semaine',
      body: 'Dépenses: ${totalSpent.toStringAsFixed(2)}€ | '
            'Revenus: ${totalIncome.toStringAsFixed(2)}€ | '
            'Solde: ${net.toStringAsFixed(2)}€',
    );
  }
  
  /// Notification de scan réussi
  Future<void> showScanSuccess({
    required double amount,
    required String? merchant,
  }) async {
    await showNotification(
      id: 1005,
      title: '✅ Scan réussi',
      body: 'Transaction de ${amount.toStringAsFixed(2)}€ '
            '${merchant != null ? 'chez $merchant' : ''} ajoutée',
    );
    
    HapticService.success();
  }
  
  /// Notification d'objectif atteint
  Future<void> showGoalAchieved({
    required String goalName,
    required double amount,
  }) async {
    await showNotification(
      id: 1006,
      title: '🎉 Objectif atteint !',
      body: 'Vous avez atteint votre objectif "$goalName" (${amount.toStringAsFixed(2)}€)',
      priority: NotificationPriority.high,
    );
    
    HapticService.achievement();
  }
  
  // ═══════════════════════════════════════════════════════════
  // NOTIFICATIONS PROGRAMMÉES
  // ═══════════════════════════════════════════════════════════
  
  /// Programme une notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_initialized) await initialize();
    
    final androidDetails = const AndroidNotificationDetails(
      'aura_scheduled',
      'Aura Finance - Programmées',
      channelDescription: 'Notifications programmées',
    );
    
    final iosDetails = const DarwinNotificationDetails();
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }
  
  /// Annule une notification programmée
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
  
  /// Annule toutes les notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
  
  // ═══════════════════════════════════════════════════════════
  // UTILITAIRES
  // ═══════════════════════════════════════════════════════════
  
  Importance _toAndroidImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.max:
        return Importance.max;
    }
  }
  
  Priority _toAndroidPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.max:
        return Priority.max;
    }
  }
}

/// Priorité des notifications
enum NotificationPriority {
  low,
  normal,
  high,
  max,
}
