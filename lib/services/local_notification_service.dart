import 'dart:async';
import 'dart:math';

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

    final now = DateTime.now();
    final notificationTime = _parseNotificationTime(task);

    // Calculate the base notification start time
    DateTime baseNotification =
        _calculateBaseNotification(task, notificationTime, now);

    // If notification time is in the past, find next occurrence
    if (baseNotification.isBefore(now)) {
      baseNotification =
          _findNextOccurrence(baseNotification, now, task.repeats);
    }

    // Apply weekday restrictions for non-hourly repeating tasks
    if (task.repeats != "hourly" && task.repeats != "once") {
      baseNotification = _adjustForWeekdays(
        baseNotification,
        task.reminderWeekdays ??
            account.accountSettings.defaultNotificationsWeekDays,
      );
    }

    return baseNotification;
  }

  DateTime _parseNotificationTime(Task task) {
    final format = DateFormat("h:mm a");
    return task.reminderTime != null
        ? format.parse(task.reminderTime!)
        : format.parse(account.accountSettings.defaultNotificationsTime);
  }

  DateTime _calculateBaseNotification(
      Task task, DateTime notificationTime, DateTime now) {
    // For "once", use exact notifyAt time
    if (task.repeats == "once") {
      return DateTime(
        task.notifyAt.year,
        task.notifyAt.month,
        task.notifyAt.day,
        notificationTime.hour,
        notificationTime.minute,
      );
    }

    // For hourly notifications, round to next hour from notifyAt or now
    if (task.repeats == "hourly") {
      final startFrom = task.notifyAt;
      return DateTime(
        startFrom.year,
        startFrom.month,
        startFrom.day,
        startFrom.hour + 1, // Round to next hour
        0, // Reset minutes to 00
      );
    }

    // For other repeat patterns, use notifyAt or now
    final startFrom = task.notifyAt;
    return DateTime(
      startFrom.year,
      startFrom.month,
      startFrom.day,
      notificationTime.hour,
      notificationTime.minute,
    );
  }

  DateTime _findNextOccurrence(
      DateTime baseDate, DateTime now, String repeatPattern) {
    switch (repeatPattern) {
      case "once":
        return baseDate; // For "once", we always use the exact notifyAt time

      case "hourly":
        final hoursToAdd = now.difference(baseDate).inHours + 1;
        return baseDate.add(Duration(hours: hoursToAdd));

      case "daily":
        final daysToAdd = now.difference(baseDate).inDays + 1;
        return baseDate.add(Duration(days: daysToAdd));

      case "weekly":
        final weeksToAdd = (now.difference(baseDate).inDays / 7).ceil();
        return baseDate.add(Duration(days: weeksToAdd * 7));

      case "monthly":
        var nextDate = baseDate;
        while (nextDate.isBefore(now)) {
          final nextMonth = nextDate.month + 1;
          final nextYear = nextDate.year + (nextMonth > 12 ? 1 : 0);
          nextDate = DateTime(
            nextYear,
            nextMonth > 12 ? 1 : nextMonth,
            min(baseDate.day,
                _daysInMonth(nextYear, nextMonth > 12 ? 1 : nextMonth)),
            baseDate.hour,
            baseDate.minute,
          );
        }
        return nextDate;

      case "yearly":
        var nextDate = baseDate;
        while (nextDate.isBefore(now)) {
          nextDate = DateTime(
            nextDate.year + 1,
            nextDate.month,
            min(baseDate.day, _daysInMonth(nextDate.year + 1, nextDate.month)),
            baseDate.hour,
            baseDate.minute,
          );
        }
        return nextDate;

      default:
        throw Exception('Invalid repeat pattern: $repeatPattern');
    }
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  DateTime _adjustForWeekdays(DateTime date, List<int> allowedWeekdays) {
    if (allowedWeekdays.isEmpty) return date;

    // Convert weekday to 0-6 format (Sunday = 0)
    final currentWeekday = date.weekday - 1;

    if (!allowedWeekdays.contains(currentWeekday)) {
      final sortedWeekdays = List<int>.from(allowedWeekdays)..sort();
      final nextWeekday = sortedWeekdays.firstWhere(
        (weekday) => weekday > currentWeekday,
        orElse: () => sortedWeekdays.first,
      );

      final daysToAdd = nextWeekday > currentWeekday
          ? nextWeekday - currentWeekday
          : 7 - currentWeekday + nextWeekday;

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

      await _notifications.zonedSchedule(
        notificationId,
        task.title,
        task.description ?? '',
        tz.TZDateTime.from(nextNotificationDate, tz.local),
        NotificationDetails(
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
