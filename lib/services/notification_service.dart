import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'stock_alert';
  static const _channelName = 'Alerta de stock';
  static const _channelDesc = 'Notificaciones cuando el stock de pañales está bajo';
  static const int stockAlertId = 1;

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showStockAlert({
    required String babyName,
    required int remainingDiapers,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    await _plugin.show(
      stockAlertId,
      '⚠️ Stock bajo — $babyName',
      'Solo quedan $remainingDiapers pañales. ¡Es momento de reordenar!',
      details,
      payload: 'reorder',
    );
  }

  Future<void> cancelStockAlert() async {
    await _plugin.cancel(stockAlertId);
  }

  static void _onNotificationTapped(NotificationResponse response) {
    if (response.payload == 'reorder') {
      navigatorKey.currentState?.pushNamed('/reorder');
    }
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();