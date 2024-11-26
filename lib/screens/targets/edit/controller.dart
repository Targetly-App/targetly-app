import 'dart:async';

import 'package:get/get.dart';
import 'package:targetly/helpers.dart';

import '../../../models/target.dart';
import '../../../models/task.dart';
import '../../../services/local_notification_service.dart';
import '../../../services/snack_bar_service.dart';
import '../../../services/targets_service.dart';
import '../../../services/tasks_service.dart';
import '../../../utils.dart';
import '../../../widgets/step_wizard/views/properties.dart';
import '../../../widgets/step_wizard/widget.dart';

class TargetEditController extends GetxController {
  RxBool isLoading = true.obs;
  Rx<Target?> target = Rx<Target?>(null);
  StreamSubscription? _targetSubscription;
  RxList<dynamic> wizardQuestions = <dynamic>[].obs;
  final RxList<Task> tasks = <Task>[].obs;
  StreamSubscription? _tasksSubscription;

  Map<String, dynamic> properties = {
    "Deadline".tr: null,
  };

  final TargetsService _targetsService = Get.find();
  final TasksService _tasksService = Get.find();
  final LocalNotificationService _localNotificationService = Get.find();

  @override
  void onInit() async {
    super.onInit();
    final targetId = Get.arguments['targetId'];
    _targetSubscription =
        _targetsService.listenOneById(targetId).listen((updatedTarget) {
      target.value = updatedTarget;

      properties = {
        "Deadline".tr: updatedTarget!.deadline,
      };

      wizardQuestions.value = [
        StepWizardQuestion(
          id: 'title',
          title: "Target title".tr,
          question: "Please specify the target title".tr,
          answer: updatedTarget.title,
          multiline: false,
          maxChars: 100,
        ),
        StepWizardQuestion(
          id: 'description',
          title: "Description".tr,
          question: "Please specify the target state".tr,
          answer: updatedTarget.description,
          minChars: 0,
          multiline: true,
        ),
        (Map<String, String> answers) => StepWizardPropertiesView(
              title: "Target properties".tr,
              onPropertySelected: (String propertyName, dynamic value) {
                properties[propertyName] = value;
              },
              properties: [
                StepWizardProperty(
                  name: "Deadline".tr,
                  type: StepWizardQuestionType.date,
                  selectedValue:
                      getFormattedDate(updatedTarget.deadline as DateTime),
                ),
              ],
            ),
      ];

      isLoading.value = false;
    });

    _tasksSubscription = _tasksService
        .subscribeOnTargetId(targetId: targetId)
        .listen((tasksFromStream) => tasks.value = tasksFromStream);
  }

  @override
  void onClose() {
    _targetSubscription?.cancel();
    _tasksSubscription?.cancel();
    super.onClose();
  }

  Future<void> deleteTarget() async {
    isLoading.value = true;

    // Before remove target need remove all notifications related to this target
    for (Task task in tasks) {
      int notificationId = getEnhanced32BitFromFirestoreId(task.id!);
      await _localNotificationService.cancelNotification(notificationId);
    }
    await _targetsService.delete(target.value!);

    // After target and tasks created we should return to the targets list
    Get.close(3);
  }

  Future<void> save(Map<String, String> answers) async {
    isLoading.value = true;

    try {
      await _targetsService.update(
        target.value!.copyWith(
          title: answers['title']!.trim(),
          description: answers['description']!.trim(),
          deadline: properties["Deadline".tr],
        ),
      );

      Get.close(1);
    } catch (e) {
      print(e);
      SnackBarService.showError("Failed to save target".tr);
      isLoading.value = false;
      return;
    }
  }
}
