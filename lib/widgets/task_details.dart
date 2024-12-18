import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:targetly/helpers.dart';
import 'package:targetly/services/local_notification_service.dart';

import '../constants.dart';
import '../models/account.dart';
import '../models/task.dart';
import '../services/app_service.dart';
import 'info_card.dart';

class TaskDetails extends StatelessWidget {
  final Task task;
  const TaskDetails({super.key, required this.task});

  Account get account => Get.find<AppService>().currentAccount()!;
  LocalNotificationService get _localNotificationService =>
      Get.find<LocalNotificationService>();
  @override
  Widget build(BuildContext context) {
    // Getting impact level description based on the impact index
    List<int> weekDays = task.reminderWeekdays ??
        account.accountSettings.defaultNotificationsWeekDays;
    String reminderTime =
        task.reminderTime ?? account.accountSettings.defaultNotificationsTime;
    DateTime? nextNotification =
        task.status == TaskStatus.planned.value && task.plannedAt != null
            ? _localNotificationService.calculateNextNotificationDate(task)
            : null;

    // Duration timeToNextIteration = Duration.zero;
    // if (nextNotification != null) {
    //   timeToNextIteration = nextNotification.difference(DateTime.now());
    // }
    return SingleChildScrollView(
      child: Column(
        children: [
          // Title card (full width)
          InfoCard(
            title: "Title",
            content: task.title,
            backgroundColor: const Color(0xFF1C1C1E),
            heightFactor: 1.0,
          ),

          if (task.description.isNotEmpty)
            InfoCard(
              title: "Description",
              content: task.description,
              backgroundColor: const Color(0xFF1C1C1E),
              heightFactor: 1.5,
            ),

          // Bottom row with three equal cards
          Row(
            children: [
              Expanded(
                child: InfoCard(
                  title: "Duration",
                  content: task.duration,
                  widthFactor: 1 / 3,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: InfoCard(
                  title: "Repeat",
                  content: task.repeats,
                  widthFactor: 1 / 3,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: InfoCard(
                  title: "Iterations",
                  content: "${task.currentIteration} / ${task.iterations}",
                  widthFactor: 1 / 3,
                ),
              ),
            ],
          ),

          if (nextNotification != null) ...[
            Row(
              children: [
                Expanded(
                  child: InfoCard(
                    title: "Notifications days",
                    content:
                        weekDays.map((dayNum) => daysOfWeek[dayNum]).join(' '),
                    widthFactor: 1 / 2,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: InfoCard(
                    title: "Notifications time",
                    content: reminderTime,
                    widthFactor: 1 / 2,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: InfoCard(
                    title: "Next notification",
                    content: getFormattedDate(nextNotification,
                        format: 'dd MMM yyyy HH:mm a'),
                    widthFactor: 1 / 2,
                  ),
                ),
                // SizedBox(width: 10),
                // Expanded(
                //   child: InfoCard(
                //     title: "Notifications time",
                //     content: reminderTime,
                //     widthFactor: 1 / 2,
                //   ),
                // ),
              ],
            ),
          ]
          //
          // Row(
          //   children: [
          //     Expanded(
          //       child: InfoCard(
          //         title: "Favorites",
          //         content: '1',
          //         widthFactor: 1 / 3,
          //       ),
          //     ),
          //     SizedBox(width: 10),
          //     Expanded(
          //       child: InfoCard(
          //         title: "Comments",
          //         content: '1',
          //         widthFactor: 1 / 3,
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}
