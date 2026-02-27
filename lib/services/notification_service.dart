import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/haptics/haptic_service.dart';
import '../features/transactions/data/transactions_repository.dart';
import '../features/subscriptions/data/subscriptions_repository.dart';

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
  
  // ═══════════════════════════════════════════════════════════
  // NOTIFICATIONS INTELLIGENTES AVANCÉES
  // ═══════════════════════════════════════════════════════════
  
  /// Notification basée sur la géolocalisation
  /// "Tu es au McDo, tu as déjà dépensé 45€ en fast-food ce mois"
  Future<void> showLocationBasedSpendingAlert({
    required String merchantName,
    required String category,
    required double monthlySpent,
    required double averageSpent,
  }) async {
    final percentageAbove = ((monthlySpent - averageSpent) / averageSpent * 100).round();
    final isAboveAverage = percentageAbove > 0;
    
    String body;
    if (isAboveAverage) {
      body = 'Tu as déjà dépensé ${monthlySpent.toStringAsFixed(0)}€ en $category ce mois, '
              '$percentageAbove% de plus que d\'habitude';
    } else {
      body = 'Tu as dépensé ${monthlySpent.toStringAsFixed(0)}€ en $category ce mois';
    }
    
    await showNotification(
      id: 2000,
      title: '📍 $merchantName',
      body: body,
      priority: isAboveAverage ? NotificationPriority.high : NotificationPriority.normal,
      payload: 'location:$merchantName',
    );
    
    HapticService.mediumTap();
  }
  
  /// Notification de prédiction de paiement récurrent
  /// "Dans 3 jours ton loyer passe, pense à recharger"
  Future<void> showUpcomingRecurringPayment({
    required String name,
    required double amount,
    required int daysUntil,
    required double currentBalance,
  }) async {
    final willBeNegative = currentBalance < amount;
    final emoji = willBeNegative ? '🚨' : daysUntil <= 1 ? '⏰' : '📅';
    
    String body;
    if (willBeNegative) {
      body = '$name (${amount.toStringAsFixed(2)}€) dans $daysUntil jour${daysUntil > 1 ? 's' : ''}. '
              'Ton solde actuel est insuffisant !';
    } else {
      body = '$name (${amount.toStringAsFixed(2)}€) dans $daysUntil jour${daysUntil > 1 ? 's' : ''}. '
              'Solde après prélèvement : ${(currentBalance - amount).toStringAsFixed(2)}€';
    }
    
    await showNotification(
      id: 2001,
      title: '$emoji $name à venir',
      body: body,
      priority: willBeNegative ? NotificationPriority.high : NotificationPriority.normal,
      payload: 'payment:$name',
    );
    
    if (willBeNegative) HapticService.error();
  }
  
  /// Notification de comportement de dépense anormal
  /// "Tu dépenses 30% plus que d'habitude ce mois"
  Future<void> showSpendingBehaviorAlert({
    required double currentMonthSpending,
    required double averageMonthlySpending,
    required int daysIntoMonth,
  }) async {
    final percentageDiff = ((currentMonthSpending - averageMonthlySpending) / averageMonthlySpending * 100).round();
    final isAbove = percentageDiff > 0;
    
    if (percentageDiff.abs() < 15) return; // Seulement si significatif
    
    final emoji = isAbove ? '⚠️' : '💡';
    final trend = isAbove ? 'plus' : 'moins';
    
    final projectedMonthEnd = (currentMonthSpending / daysIntoMonth) * 30;
    final projectedDiff = ((projectedMonthEnd - averageMonthlySpending) / averageMonthlySpending * 100).round();
    
    await showNotification(
      id: 2002,
      title: '$emoji Tes dépenses',
      body: 'Tu dépenses $percentageDiff% $trend que d\'habitude. '
              'Projection fin de mois : +$projectedDiff%',
      priority: isAbove && percentageDiff > 30 ? NotificationPriority.high : NotificationPriority.normal,
      payload: 'behavior:spending',
    );
    
    if (isAbove && percentageDiff > 30) HapticService.warning();
  }
  
  /// Notification de catégorie de dépense critique
  Future<void> showCategoryBudgetWarning({
    required String category,
    required double spent,
    required double budget,
    required double percentageUsed,
  }) async {
    final remaining = budget - spent;
    final emoji = percentageUsed >= 100 ? '🛑' : percentageUsed >= 90 ? '⚠️' : '💰';
    
    String body;
    if (percentageUsed >= 100) {
      body = 'Budget $category dépassé de ${(spent - budget).toStringAsFixed(2)}€ !';
    } else if (percentageUsed >= 90) {
      body = 'Il te reste ${remaining.toStringAsFixed(2)}€ pour $category (${percentageUsed.toStringAsFixed(0)}% utilisé)';
    } else {
      body = 'Tu as utilisé ${percentageUsed.toStringAsFixed(0)}% de ton budget $category';
    }
    
    await showNotification(
      id: 2003,
      title: '$emoji Budget $category',
      body: body,
      priority: percentageUsed >= 100 ? NotificationPriority.high : NotificationPriority.normal,
      payload: 'budget:$category',
    );
  }
  
  /// Notification de comparaison avec mois précédent
  Future<void> showMonthComparison({
    required String category,
    required double thisMonth,
    required double lastMonth,
  }) async {
    final diff = ((thisMonth - lastMonth) / lastMonth * 100).round();
    final isHigher = diff > 0;
    
    if (diff.abs() < 20) return; // Pas significatif
    
    final emoji = isHigher ? '📈' : '📉';
    final trend = isHigher ? 'augmenté' : 'diminué';
    
    await showNotification(
      id: 2004,
      title: '$emoji Tes habitudes $category',
      body: 'Tes dépenses $category ont $trend de ${diff.abs()}% par rapport au mois dernier',
      payload: 'comparison:$category',
    );
  }
  
  /// Notification de détection de double paiement
  Future<void> showDuplicatePaymentWarning({
    required String merchant,
    required double amount,
    required DateTime lastSimilarTransaction,
  }) async {
    await showNotification(
      id: 2005,
      title: '⚠️ Double paiement détecté ?',
      body: 'Transaction similaire chez $merchant (${amount.toStringAsFixed(2)}€) '
              'détectée. Dernière fois : ${lastSimilarTransaction.day}/${lastSimilarTransaction.month}',
      priority: NotificationPriority.high,
      payload: 'duplicate:$merchant',
    );
    
    HapticService.warning();
  }
  
  /// Notification de suggestion d'épargne
  Future<void> showSavingsSuggestion({
    required double suggestedAmount,
    required String reason,
  }) async {
    await showNotification(
      id: 2006,
      title: '💡 Suggestion d\'épargne',
      body: 'Tu pourrais mettre de côté ${suggestedAmount.toStringAsFixed(2)}€ cette semaine. $reason',
      payload: 'savings:suggestion',
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
