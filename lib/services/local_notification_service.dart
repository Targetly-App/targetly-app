import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/account.dart';
import '../models/task.dart';
import '../utils.dart';
import 'app_service.dart';

class LocalNotificationService extends GetxService {
  late FlutterLocalNotificationsPlugin _notifications;
  final selectNotificationStream = StreamController<String?>.broadcast();

  Account get account => Get.find<AppService>().currentAccount()!;

  @override
  void onInit() {
    super.onInit();
    _initializeNotifications();
  }

  // Initialize the notifications settings
  Future<void> _initializeNotifications() async {
    _notifications = FlutterLocalNotificationsPlugin();

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

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        selectNotificationStream.add(notificationResponse.payload);
      },
      onDidReceiveBackgroundNotificationResponse: null,
    );
  }

  DateTime calculateNextNotificationDate(Task task) {
    if (task.status != TaskStatus.planned.value || task.plannedAt == null) {
      throw Exception('Task must be planned with plannedAt date');
    }

    // Parse reminder time if set, otherwise use default
    final format = DateFormat("h:mm a");
    final reminderTime = task.reminderTime != null
        ? format.parse(task.reminderTime!)
        : format.parse(account.accountSettings.defaultNotificationsTime);

    final now = DateTime.now();

    // Set reminder time to plannedAt date
    DateTime baseNotification = DateTime(
      task.plannedAt!.year,
      task.plannedAt!.month,
      task.plannedAt!.day,
      reminderTime.hour,
      reminderTime.minute,
    );

    // If base notification is in the past, adjust based on repeat pattern
    if (baseNotification.isBefore(now)) {
      baseNotification = _adjustPastNotification(
        baseNotification,
        now,
        task.repeats,
      );
    }

    // Adjust for allowed weekdays if needed
    List<int> reminderWeekdays = task.reminderWeekdays != null
        ? task.reminderWeekdays!
        : account.accountSettings.defaultNotificationsWeekDays;
    if (reminderWeekdays.isNotEmpty) {
      baseNotification = _adjustForWeekdays(
        baseNotification,
        reminderWeekdays,
        task.repeats,
      );
    }

    return baseNotification;
  }

  DateTime _adjustPastNotification(
    DateTime baseDate,
    DateTime now,
    String repeatPattern,
  ) {
    switch (repeatPattern) {
      case "once":
        // For "once" pattern, if the base date is in the past,
        // we should notify today at the same time
        final difference = now.difference(baseDate).inDays;
        return baseDate.add(Duration(days: difference));

      case "hourly":
        final difference = now.difference(baseDate).inHours;
        return baseDate.add(Duration(hours: difference + 1));

      case "daily":
        final difference = now.difference(baseDate).inDays;
        return baseDate.add(Duration(days: difference + 1));

      case "weekly":
        final difference = now.difference(baseDate).inDays;
        final weeksDifference = (difference / 7).ceil();
        return baseDate.add(Duration(days: weeksDifference * 7));

      case "monthly":
        var nextDate = baseDate;
        final monthsToAdd = (now.difference(baseDate).inDays / 30).ceil();
        return DateTime(
          nextDate.year,
          nextDate.month + monthsToAdd,
          nextDate.day,
          nextDate.hour,
          nextDate.minute,
        );

      case "yearly":
        var nextDate = baseDate;
        final yearsToAdd = (now.difference(baseDate).inDays / 365).ceil();
        return DateTime(
          nextDate.year + yearsToAdd,
          nextDate.month,
          nextDate.day,
          nextDate.hour,
          nextDate.minute,
        );

      default:
        throw Exception('Invalid repeat pattern: $repeatPattern');
    }
  }

  DateTime _adjustForWeekdays(
    DateTime date,
    List<int> allowedWeekdays,
    String repeatPattern,
  ) {
    // Convert weekday to 0-6 format (Sunday = 0)
    final currentWeekday = date.weekday - 1;

    if (!allowedWeekdays.contains(currentWeekday)) {
      // Find next allowed weekday
      final sortedWeekdays = List<int>.from(allowedWeekdays)..sort();
      final nextWeekday = sortedWeekdays.firstWhere(
        (weekday) => weekday > currentWeekday,
        orElse: () => sortedWeekdays.first,
      );

      final daysToAdd = nextWeekday > currentWeekday
          ? nextWeekday - currentWeekday
          : 7 - currentWeekday + nextWeekday;

      // For weekly/monthly/yearly notifications, only adjust if it's the first occurrence
      if (repeatPattern == "weekly" ||
          repeatPattern == "monthly" ||
          repeatPattern == "yearly") {
        final isFirstOccurrence = date.isAfter(DateTime.now());
        if (!isFirstOccurrence) {
          return date;
        }
      }

      return date.add(Duration(days: daysToAdd));
    }

    return date;
  }

  Future<void> updateTaskNotification(Task task) async {
    final notificationId = getEnhanced32BitFromFirestoreId(task.id!);

    final bool isNeedNotify = task.currentIteration < task.iterations &&
        task.status == TaskStatus.planned.value &&
        task.plannedAt != null;

    await _notifications.cancel(notificationId);

    if (!isNeedNotify) return;

    try {
      final nextNotificationDate = calculateNextNotificationDate(task);

      if (nextNotificationDate.year == 0) return;

      await _notifications.zonedSchedule(
        notificationId,
        task.title,
        task.description ?? '',
        tz.TZDateTime.from(nextNotificationDate, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'task_channel',
            'Task Notifications',
            channelDescription: 'Notifications for task reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: _getMatchDateTimeComponents(task.repeats),
      );
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  DateTimeComponents? _getMatchDateTimeComponents(String repeatPattern) {
    switch (repeatPattern) {
      case "hourly":
        return null;
      case "daily":
        return DateTimeComponents.time;
      case "weekly":
        return DateTimeComponents.dayOfWeekAndTime;
      case "monthly":
        return DateTimeComponents.dayOfMonthAndTime;
      case "yearly":
        return DateTimeComponents.dateAndTime;
      default:
        return null;
    }
  }

  Future<void> cancelTaskNotification(String taskId) async {
    final notificationId = getEnhanced32BitFromFirestoreId(taskId);
    await _notifications.cancel(notificationId);
  }
}
