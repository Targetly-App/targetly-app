import 'package:get/get.dart';

import '../../../../../constants.dart';
import '../../../../../models/task.dart';
import '../../../../../services/local_notification_service.dart';
import '../../../../../services/snack_bar_service.dart';
import '../../../../../services/tasks_service.dart';
import '../../../../../utils.dart';
import '../../../../../widgets/step_wizard/views/properties.dart';
import '../../../../../widgets/step_wizard/widget.dart';

class TaskEditController extends GetxController {
  late Task task;
  List<dynamic> wizardQuestions = [];
  bool isLoading = false;

  final TasksService _tasksService = Get.find();
  final LocalNotificationService _localNotificationService = Get.find();

  Map<String, dynamic> properties = {
    "Iterations".tr: taskIterations[0],
    "Repeats".tr: taskRepeats[0],
    "Duration".tr: taskDurations[0],
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
    properties = {
      "Iterations".tr: task.iterations,
      "Repeats".tr: task.repeats,
      "Duration".tr: task.duration,
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
      (Map<String, String> answers) => StepWizardPropertiesView(
            title: "Task properties".tr,
            onPropertySelected: (String propertyName, dynamic value) {
              properties[propertyName] = value;
            },
            properties: [
              StepWizardProperty(
                name: "Priority".tr,
                values: ["No".tr, "Yes".tr],
                selectedValue: properties["Priority".tr],
              ),
              StepWizardProperty(
                name: "Iterations".tr,
                values: taskIterations,
                selectedValue: properties["Iterations".tr],
              ),
              StepWizardProperty(
                name: "Repeats".tr,
                values: taskRepeats,
                selectedValue: properties["Repeats".tr],
              ),
              StepWizardProperty(
                name: "Duration".tr,
                values: taskDurations,
                selectedValue: properties["Duration".tr],
              ),
            ],
          ),
    ];
    update();
  }

  Future<void> deleteTask() async {
    isLoading = true;
    update();

    int notificationId = getEnhanced32BitFromFirestoreId(task.id!);
    await _localNotificationService.cancelNotification(notificationId);

    await _tasksService.delete(task.id!);
    Get.close(3);
  }

  Future<void> save(Map<String, String> answers) async {
    isLoading = true;
    update();

    try {
      // Before we change status to planned, we should remove notification
      await _tasksService.updateLocalNotification(task);

      TaskRepeats repeat = TaskRepeats.values.firstWhere(
          (element) => element.name.toString() == properties["Repeats".tr]);

      Task updatedTask = task.copyWith(
        title: answers['title']!.trim(),
        description: answers['description']!.trim(),
        iterations: properties["Iterations".tr],
        repeats: repeat.name,
        duration: properties["Duration".tr],
        status: TaskStatus.planned.name,
        completedAt: null,
      );

      if (task.iterations <= task.currentIteration) {
        updatedTask = updatedTask.copyWith(
          status: TaskStatus.completed.toString(),
          currentIteration: updatedTask.iterations,
          completedAt: DateTime.now(),
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
}
