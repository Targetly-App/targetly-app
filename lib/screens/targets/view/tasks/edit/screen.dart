import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../widgets/step_wizard/widget.dart';
import 'controller.dart';

class TaskEditScreen extends GetView<TaskEditController> {
  const TaskEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      assignId: true,
      init: TaskEditController(),
      builder: (TaskEditController controller) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SafeArea(
          bottom: false,
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              backgroundColor: const Color.fromRGBO(0, 0, 0, 0),
              elevation: 0,
              title: Align(
                alignment: Alignment.centerLeft,
                child: Text('Edit task details'.tr),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: TextButton(
                    style: TextButton.styleFrom(overlayColor: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Delete task'.tr),
                            content: Text(
                                'Are you sure you want to delete this task?'
                                    .tr),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('Cancel'.tr),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await controller.deleteTask();
                                },
                                child: Text(
                                  'Delete'.tr,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Text(
                      'Delete'.tr,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
            body: StepWizard(
              isLoading: controller.isLoading,
              steps: controller.wizardQuestions,
              submitCallback: (answers) async {
                await controller.save(answers);
              },
            ),
          ),
        );
      },
    );
  }
}
