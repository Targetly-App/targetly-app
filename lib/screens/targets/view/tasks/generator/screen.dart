import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../widgets/step_wizard/widget.dart';
import 'controller.dart';

class TasksGeneratorScreen extends GetView<TasksGeneratorController> {
  const TasksGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: TasksGeneratorController(),
      builder: (TasksGeneratorController controller) {
        return SafeArea(
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: const Color.fromRGBO(0, 0, 0, 0),
              elevation: 0,
              title: Align(
                alignment: Alignment.centerLeft,
                child: Text('Tasks generation'.tr),
              ),
              actions: [],
            ),
            body: Builder(
              builder: (context) {
                if (controller.isLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Analyzing'.tr),
                      ],
                    ),
                  );
                }

                if (controller.wizardQuestions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('We found technical issues, please try again later'
                            .tr),
                      ],
                    ),
                  );
                }

                return StepWizard(
                  isLoading: controller.isLoading,
                  steps: controller.wizardQuestions,
                  submitCallback: (answers) async {
                    await controller.generateTasks(answers);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
