import 'package:get/get.dart';
import 'package:targetly/services/app_service.dart';

import '../../../../../constants.dart';
import '../../../../../models/target.dart';
import '../../../../../models/task.dart';
import '../../../../../services/tasks_service.dart';
import '../../../../../widgets/step_wizard/views/properties.dart';
import '../../../../../widgets/step_wizard/widget.dart';
import '../../controller.dart';

class AddTaskController extends GetxController {
  bool isLoading = false;

  final _appService = Get.find<AppService>();
  final _tasksService = Get.find<TasksService>();
  final _targetViewController = Get.find<TargetViewController>();

  List<dynamic> wizardPages = [
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
  ];

  Map<String, dynamic> properties = {
    "Iterations".tr: taskIterations[0],
    "Repeats".tr: taskRepeats[0],
    "Duration".tr: taskDurations[0],
  };

  @override
  void onInit() {
    wizardPages.add(
      (Map<String, String> answers) => StepWizardPropertiesView(
        title: "Task properties".tr,
        onPropertySelected: (String propertyName, dynamic value) {
          properties[propertyName] = value;
        },
        properties: [
          StepWizardProperty(
            name: "Importance".tr,
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
    );
    super.onInit();
  }

  void createTask(Target target, Map<String, String> answers) async {
    isLoading = true;
    update();
    int iterations =
        properties["Repeats".tr] == "once".tr ? 1 : properties["Iterations".tr];

    TaskRepeats repeat = TaskRepeats.values.firstWhere(
        (element) => element.name.toString() == properties["Repeats".tr]);

    Task task = Task(
      title: answers['title']!,
      description: answers['description']!,
      duration: properties["Duration".tr],
      repeats: repeat.name.toString(),
      iterations: iterations,
      step: _targetViewController.tasks.length + 1,
      targetId: target.id,
      currentIteration: 0,
      isPlanned: false,
      isCompleted: false,
      status: TaskStatus.todo.value,
      uid: _appService.currentAccount()!.user.uid,
    );

    await _tasksService.create(task);
    isLoading = false;
    update();

    Get.close(1);
  }
}
