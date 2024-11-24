import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:targetly/services/snack_bar_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/timezone.dart';

class LocalNotificationService extends GetxService {
  // Initialize the FlutterLocalNotificationsPlugin
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final StreamController<String?> selectNotificationStream =
      StreamController<String?>.broadcast();

  @override
  void onInit() {
    super.onInit();
    _initializeNotifications();
  }

  // Initialize the notifications settings
  Future<void> _initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    final List<DarwinNotificationCategory> darwinNotificationCategories =
        <DarwinNotificationCategory>[];

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification:
          (int id, String? title, String? body, String? payload) async {},
      notificationCategories: darwinNotificationCategories,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        selectNotificationStream.add(notificationResponse.payload);
      },
      onDidReceiveBackgroundNotificationResponse: null,
    );
  }

  // Handle notification tap
  Future<void> _onSelectNotification(String? payload) async {
    if (payload != null) {
      // Handle notification payload here
      SnackBarService.showInfo("Notification tapped with payload: $payload");
    }
  }

  // Handle iOS notification while the app is in the foreground
  Future<void> _onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    // You can show a dialog or navigate to another page
    SnackBarService.showInfo("Received notification while in foreground");
  }

  Future<void> scheduleNotification(
      int id, String title, String body, DateTime scheduledDate) async {
    TZDateTime scheduledDateTime = TZDateTime.from(scheduledDate, tz.local);

    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(presentBadge: true);
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'app.targetly.notification',
        'Targetly',
        channelDescription: 'Targetly notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
      ),
      iOS: darwinNotificationDetails,
      macOS: darwinNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
        id, title, body, scheduledDateTime, notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);
  }

  // Cancel a notification by ID
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
