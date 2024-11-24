import 'package:get/get.dart';
import 'package:targetly/services/app_service.dart';

import '../../../models/target.dart';
import '../../../models/task.dart';
import '../../../services/targets_service.dart';
import '../../../widgets/step_wizard/views/properties.dart';
import '../../../widgets/step_wizard/widget.dart';
import '../controller.dart';

class TargetAddController extends GetxController {
  bool isLoading = false;
  List<Task> tasks = [];

  Map<String, dynamic> properties = {
    "Deadline".tr: null,
  };

  List<dynamic> workflowWizardPages = [
    StepWizardQuestion(
      id: 'title',
      title: "Target title".tr,
      question: "Please specify the target title".tr,
      multiline: false,
      maxChars: 100,
    ),
    StepWizardQuestion(
      id: 'description',
      title: "Description".tr,
      question: "Please specify the target state".tr,
      minChars: 0,
      multiline: true,
    ),
  ];

  TargetsController targetsController = Get.find();
  TargetsService targetsService = Get.find();
  final _appService = Get.find<AppService>();

  @override
  onInit() {
    workflowWizardPages.add(
      (Map<String, String> answers) => StepWizardPropertiesView(
        title: "Target properties".tr,
        onPropertySelected: (String propertyName, dynamic value) {
          properties[propertyName] = value;
        },
        properties: [
          StepWizardProperty(
            name: "Deadline".tr,
            type: StepWizardQuestionType.date,
          ),
        ],
      ),
    );
    super.onInit();
  }

  Future<void> createTarget(Map<String, String> answers) async {
    isLoading = true;
    update();

    var target = Target(
      uid: _appService.currentAccount()!.user.uid,
      title: answers['title']!.trim(),
      description: answers['description'] ?? '',
      deadline: properties["Deadline".tr],
    );

    await targetsService.create(target, []);

    // After target and tasks updated we should return to the targets list
    targetsController.onInit();

    // After target and tasks created we should return to the targets list
    Get.close(1);

    return;
  }
}
