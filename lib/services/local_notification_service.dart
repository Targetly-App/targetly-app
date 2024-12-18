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

  DateTime? calculateNextNotificationDate(Task task) {
    if (task.status != TaskStatus.planned.value || task.plannedAt == null) {
      return null;
    }

    final now = DateTime.now();
    final notificationTime = _parseNotificationTime(task);

    // Calculate the base notification start time
    DateTime baseNotification =
        _calculateBaseNotification(task, notificationTime, now);

    // If notification time is in the past, find next occurrence
    if (baseNotification.isBefore(now)) {
      // For "once" tasks, return null if the time is in the past
      if (task.repeats == "once") {
        return null;
      }
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

    // Final check to ensure the notification is in the future
    if (baseNotification.isBefore(now)) {
      return null;
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
        // Calculate days to add, ensuring we move to the next day if we're past notification time
        final daysToAdd = now.difference(baseDate).inDays +
            (now.hour > baseDate.hour ||
                    (now.hour == baseDate.hour && now.minute >= baseDate.minute)
                ? 1
                : 0);
        return baseDate.add(Duration(days: daysToAdd));

      case "weekly":
        var weeksToAdd = (now.difference(baseDate).inDays / 7).ceil();
        var nextDate = baseDate.add(Duration(days: weeksToAdd * 7));

        // If we're past the notification time on the calculated day, add one more week
        if (nextDate.day == now.day &&
            (now.hour > nextDate.hour ||
                (now.hour == nextDate.hour && now.minute >= nextDate.minute))) {
          nextDate = nextDate.add(Duration(days: 7));
        }
        return nextDate;

      case "monthly":
        var nextDate = baseDate;
        while (nextDate.isBefore(now) ||
            (nextDate.day == now.day &&
                (now.hour > nextDate.hour ||
                    (now.hour == nextDate.hour &&
                        now.minute >= nextDate.minute)))) {
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
        while (nextDate.isBefore(now) ||
            (nextDate.day == now.day &&
                (now.hour > nextDate.hour ||
                    (now.hour == nextDate.hour &&
                        now.minute >= nextDate.minute)))) {
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

    // First, cancel any existing notification
    await _notifications.cancel(notificationId);

    final bool isNeedNotify = task.currentIteration < task.iterations &&
        task.status == TaskStatus.planned.value &&
        task.plannedAt != null;

    // If notification is not needed, we've already cancelled it above
    if (!isNeedNotify) return;

    try {
      // Calculate next notification date
      final nextNotificationDate = calculateNextNotificationDate(task);

      // If nextNotificationDate is null, it means the notification time is in the past
      // Just return without scheduling a new notification
      if (nextNotificationDate == null) {
        // Skipping notification for task because the calculated time is in the past
        return;
      }

      // Convert to TZDateTime
      final notificationTzDateTime = tz.TZDateTime.from(
        nextNotificationDate,
        tz.local,
      );

      // Double check that the TZ conversion didn't push us into the past
      if (notificationTzDateTime.isBefore(tz.TZDateTime.now(tz.local))) {
        print(
            'Skipping notification for task ${task.title} as the TZ converted time is in the past');
        return;
      }

      await _notifications.zonedSchedule(
        notificationId,
        task.title,
        task.description ?? '',
        notificationTzDateTime,
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
      print('Task: ${task.title}');
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
