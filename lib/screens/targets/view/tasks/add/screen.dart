import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../models/target.dart';
import '../../../../../widgets/step_wizard/widget.dart';
import 'controller.dart';

class AddTaskScreen extends GetView<AddTaskController> {
  final Target target;
  const AddTaskScreen(this.target, {super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: AddTaskController(),
      builder: (AddTaskController controller) {
        return SafeArea(
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: const Color.fromRGBO(0, 0, 0, 0),
              elevation: 0,
              title: Align(
                alignment: Alignment.centerLeft,
                child: Text('Creating a task'.tr),
              ),
              actions: const [],
            ),
            body: StepWizard(
              steps: controller.wizardPages,
              submitCallback: (Map<String, String> answers) {
                controller.createTask(target, answers);
              },
            ),
          ),
        );
      },
    );
  }
}
