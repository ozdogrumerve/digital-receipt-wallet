import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: android,
    );

    await _notifications.initialize(
      settings: settings,
    );

  }

  // Bütçe bildirimi (mevcut)
  static Future<void> showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'channel_id',
      'Alerts',
      importance: Importance.max,
      priority: Priority.high,
    );

    await _notifications.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }

  // Bütçenin %100'ü harcandı bildirimi (yeni)
  static Future<void> showBudgetFullyUsedNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'channel_id',
      'Alerts',
      importance: Importance.max,
      priority: Priority.high,
    );

    await _notifications.show(
      id: 1,
      title: 'Budget Fully Used 💸',
      body: 'You have spent your entire monthly budget.',
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }

  // Recurring bildirimi (yeni)
  static Future<void> showRecurringNotification({
    required String storeName,
    required double amount,
    required String category,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'recurring_channel',
      'Recurring Transactions',
      channelDescription: 'Notifications for recurring transaction processing',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _notifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Recurring Transaction Processed 🔁',
      body: '$storeName — ₺${amount.toStringAsFixed(2)} ($category)',
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }
}