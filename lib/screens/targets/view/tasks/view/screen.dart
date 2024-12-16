import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:targetly/widgets/chat/widget.dart';

import '../../../../../app_routes.dart';
import '../../../../../widgets/button.dart';
import '../../../../../widgets/task_details.dart';
import 'controller.dart';

class TaskViewScreen extends GetView<TaskStackViewController> {
  const TaskViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: TaskStackViewController(),
      builder: (TaskStackViewController controller) {
        return SafeArea(
          bottom: false,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: const Color.fromRGBO(0, 0, 0, 0),
              elevation: 0,
              title: Align(
                alignment: Alignment.centerLeft,
                child: Text('Task overview'.tr),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: TextButton(
                    onPressed: () async {
                      await Get.toNamed(AppRoutes.editTargetTask, arguments: {
                        'target': controller.target,
                        'task': controller.task
                      });
                    },
                    child: Text('Edit'.tr),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Button(
                text: 'Open chat',
                onPressed: () {
                  showCupertinoModalBottomSheet(
                    expand: false,
                    context: context,
                    builder: (context) => Stack(
                      children: [
                        Scaffold(
                          appBar: AppBar(
                            backgroundColor: const Color.fromRGBO(0, 0, 0, 0),
                            elevation: 0,
                            title: Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Task chat'.tr),
                            ),
                          ),
                          body: ChatWidget(
                              target: controller.target, task: controller.task),
                        )
                      ],
                    ),
                  );
                },
                isLoading: false,
              ),
            ),
            body: Builder(
              builder: (context) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: TaskDetails(task: controller.task),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
