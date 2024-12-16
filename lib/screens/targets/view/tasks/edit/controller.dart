import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:targetly/screens/dashboard/controller.dart';

import '../../../../../constants.dart';
import '../../../../../models/account.dart';
import '../../../../../models/task.dart';
import '../../../../../services/app_service.dart';
import '../../../../../services/local_notification_service.dart';
import '../../../../../services/snack_bar_service.dart';
import '../../../../../services/tasks_service.dart';
import '../../../../../widgets/step_wizard/views/properties.dart';
import '../../../../../widgets/step_wizard/widget.dart';

class TaskEditController extends GetxController {
  late final Task task;

  List<dynamic> wizardQuestions = [];
  bool isLoading = false;

  final TasksService _tasksService = Get.find();
  final LocalNotificationService _localNotificationService = Get.find();
  final DashboardController _dashboardController = Get.find();

  Account get account => Get.find<AppService>().currentAccount()!;

  Map<String, dynamic> properties = {
    // "Impact".tr: impactLevels[0],
    // "Effort".tr: effortLevels[0],
    "Iterations".tr: taskIterations[0],
    "Duration".tr: taskDurations[0],
    "Frequency".tr: taskRepeats[0],
    "Weekdays".tr: null,
    "Time".tr: null,
  };

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null) {
      initWithTask(Get.arguments['task']);
    }
  }

  void initWithTask(Task task) {
    this.task = task;
    var time = task.reminderTime;
    var weekdays = task.reminderWeekdays;
    weekdays ??= account.accountSettings.defaultNotificationsWeekDays;
    time ??= account.accountSettings.defaultNotificationsTime;
    properties = {
      // "Impact".tr: impactLevels[task.impact - 1],
      // "Effort".tr: effortLevels[task.effort - 1],
      "Iterations".tr: task.iterations,
      "Repeats".tr: task.repeats,
      "Duration".tr: task.duration,
      "Frequency".tr: task.repeats,
      "Use global settings".tr: task.reminderWeekdays == null,
      "Weekdays".tr: weekdays,
      "Time".tr: time,
    };

    wizardQuestions = [
      StepWizardQuestion(
        id: 'title',
        title: "Task title".tr,
        question: "Please specify the task title".tr,
        answer: task.title,
        multiline: false,
        maxChars: 100,
      ),
      StepWizardQuestion(
        id: 'description',
        title: "Task description".tr,
        question: "Please specify the task description".tr,
        answer: task.description,
        minChars: 0,
        multiline: true,
      ),
      (Map<String, String> answers) => Column(
            children: [
              StepWizardPropertiesView(
                title: "Properties".tr,
                onPropertySelected: (String propertyName, dynamic value) {
                  properties[propertyName] = value;
                },
                properties: [
                  // StepWizardProperty(
                  //   name: "Impact".tr,
                  //   icon: const Icon(Iconsax.flash_1_outline),
                  //   values: impactLevels,
                  //   selectedValue: properties["Impact".tr],
                  // ),
                  // StepWizardProperty(
                  //   name: "Effort".tr,
                  //   icon: const Icon(Iconsax.weight_1_outline),
                  //   values: effortLevels,
                  //   selectedValue: properties["Effort".tr],
                  // ),
                  StepWizardProperty(
                    name: "Iterations".tr,
                    icon: const Icon(Iconsax.rotate_right_outline),
                    values: taskIterations,
                    selectedValue: properties["Iterations".tr],
                  ),
                  StepWizardProperty(
                    name: "Duration".tr,
                    icon: const Icon(Iconsax.timer_1_outline),
                    values: taskDurations,
                    selectedValue: properties["Duration".tr],
                  ),
                ],
              ),
              StepWizardPropertiesView(
                title: "Notifications".tr,
                onPropertySelected: (String propertyName, dynamic value) {
                  properties[propertyName] = value;
                },
                properties: [
                  StepWizardProperty(
                    name: "Frequency".tr,
                    icon: const Icon(Iconsax.notification_status_outline),
                    values: taskRepeats,
                    selectedValue: properties["Frequency".tr],
                  ),
                  StepWizardProperty(
                    name: "Use global settings".tr,
                    icon: Icon(Icons.settings),
                    type: StepWizardQuestionType.switcher,
                    selectedValue: properties["Use global settings".tr],
                    subTitle: "Use global notification settings".tr,
                  ),
                  StepWizardProperty(
                    name: "Weekdays".tr,
                    icon: const Icon(Iconsax.calendar_2_outline),
                    type: StepWizardQuestionType.weekdays,
                    selectedValue: properties["Weekdays".tr],
                    dependsOn: "Use global settings".tr,
                    visibleWhen: false,
                  ),
                  StepWizardProperty(
                    name: "Time".tr,
                    icon: Icon(Icons.notifications_active),
                    type: StepWizardQuestionType.time,
                    selectedValue: properties["Time".tr],
                    dependsOn: "Use global settings".tr,
                    visibleWhen: false,
                  ),
                ],
              ),
            ],
          )
    ];
    update();
  }

  Future<void> deleteTask() async {
    isLoading = true;
    update();

    await _localNotificationService.updateTaskNotification(task);

    await _tasksService.delete(task.id!);
    Get.close(3);
  }

  Future<void> save(Map<String, String> answers) async {
    isLoading = true;
    update();

    try {
      // Before we change status to planned, we should remove notification
      await _localNotificationService.updateTaskNotification(task);

      Task updatedTask = task.copyWith(
        title: answers['title']!.trim(),
        description: answers['description']!.trim(),
        // impact: impactLevels.indexOf(properties["Impact".tr]) + 1,
        // effort: effortLevels.indexOf(properties["Effort".tr]) + 1,
        repeats: properties["Frequency".tr],
        reminderWeekdays: properties["Weekdays".tr],
        reminderTime: properties["Time".tr],
        iterations: int.parse(properties["Iterations".tr].toString()),
        duration: properties["Duration".tr],
        status: TaskStatus.planned.name,
        completedAt: null,
      );

      if (task.iterations <= task.currentIteration) {
        updatedTask = updatedTask.copyWith(
          status: TaskStatus.completed.name,
          currentIteration: updatedTask.iterations,
          completedAt: DateTime.now(),
        );
      }

      bool useGlobalSettings = properties["Use global settings".tr];
      if (useGlobalSettings) {
        updatedTask = updatedTask.copyWithNull(
          reminderWeekdays: true,
          reminderTime: true,
        );
      }

      await _tasksService.update(updatedTask);

      Get.close(2);
    } catch (e) {
      SnackBarService.showError("Failed to save task".tr);
      isLoading = false;
      update();
      return;
    }
  }

  @override
  void onClose() {
    _dashboardController.refreshData();
    super.onClose();
  }
}
