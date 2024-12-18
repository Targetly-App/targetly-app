import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:targetly/helpers.dart';
import 'package:targetly/services/app_service.dart';

import '../../../../../constants.dart';
import '../../../../../models/target.dart';
import '../../../../../models/task.dart';
import '../../../../../services/tasks_service.dart';
import '../../../../../widgets/step_wizard/views/properties.dart';
import '../../../../../widgets/step_wizard/widget.dart';
import '../../../../dashboard/controller.dart';
import '../../controller.dart';

class AddTaskController extends GetxController {
  bool isLoading = false;

  final _tasksService = Get.find<TasksService>();
  final _targetViewController = Get.find<TargetViewController>();
  final _dashboardController = Get.find<DashboardController>();
  final account = Get.find<AppService>().currentAccount()!;

  RxList<dynamic> wizardPages = [].obs;

  Map<String, dynamic> properties = {
    "Iterations".tr: taskIterations[0],
    "Duration".tr: taskDurations[0],
    "Frequency".tr: taskRepeats[0],
    "Use global settings".tr: true,
    "Weekdays".tr: null,
    "Time".tr: null,
    "Start notification date".tr: DateTime.now(),
  };

  @override
  void onInit() {
    properties["Weekdays".tr] =
        account.accountSettings.defaultNotificationsWeekDays;
    properties["Time".tr] = account.accountSettings.defaultNotificationsTime;

    wizardPages.addAll(getWizardPages());

    super.onInit();
  }

  List getWizardPages({withGlobalNotificationSettings = true}) {
    return [
      StepWizardQuestion(
        id: 'title',
        title: "Task title".tr,
        question: "Please specify the task title".tr,
        multiline: false,
        minChars: 1,
        maxChars: 100,
      ),
      StepWizardQuestion(
        id: 'description',
        title: "Task description".tr,
        question: "Please specify the task description".tr,
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
                    name: "Start notification date".tr,
                    icon: const Icon(Iconsax.calendar_outline),
                    type: StepWizardQuestionType.date,
                    selectedValue: getFormattedDate(
                        properties["Start notification date".tr]),
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
                    icon: Icon(Iconsax.calendar_2_outline),
                    type: StepWizardQuestionType.weekdays,
                    selectedValue: properties["Weekdays".tr],
                    dependencies: [
                      DependencyCondition(
                        propertyName: "Use global settings".tr,
                        visibleWhen: false,
                      ),
                      DependencyCondition(
                        propertyName: "Frequency".tr,
                        visibleWhen: (value) => value != 'once',
                      ),
                    ],
                  ),
                  StepWizardProperty(
                    name: "Time".tr,
                    icon: Icon(Icons.notifications_active),
                    type: StepWizardQuestionType.time,
                    selectedValue: properties["Time".tr],
                    dependencies: [
                      DependencyCondition(
                        propertyName: "Use global settings".tr,
                        visibleWhen: false,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
    ];
  }

  void createTask(Target target, Map<String, String> answers) async {
    isLoading = true;
    update();

    try {
      bool useGlobalSettings = properties["Use global settings".tr];
      Task task = Task(
        title: answers['title']!,
        description: answers['description']!,
        duration: properties["Duration".tr],
        repeats: properties["Frequency".tr],
        notifyAt: properties["Start notification date".tr],
        reminderWeekdays: useGlobalSettings ? null : properties["Weekdays".tr],
        reminderTime: useGlobalSettings ? null : properties["Time".tr],
        iterations: int.parse(properties["Iterations".tr]),
        step: _targetViewController.tasks.length + 1,
        targetId: target.id,
        currentIteration: 0,
        isPlanned: false,
        isCompleted: false,
        status: TaskStatus.todo.value,
        uid: account.user.uid,
      );

      await _tasksService.create(task);
    } catch (e) {
      isLoading = false;
      update();
      return;
    }

    isLoading = false;
    update();

    Get.close(1);
  }

  @override
  void onClose() {
    _dashboardController.refreshData();
    super.onClose();
  }
}
