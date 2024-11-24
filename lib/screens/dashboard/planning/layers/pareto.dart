import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:targetly/screens/dashboard/planning/controller.dart';

import '../../../../app_routes.dart';
import '../../../../models/target.dart';
import '../../../../models/task.dart';
import '../../../../widgets/list_section.dart';
import '../../../../widgets/task_card.dart';

class ParetoLayer extends GetWidget<PlanningStackController> {
  const ParetoLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      List<Widget> vitalSections = [];

      for (var target in controller.targets) {
        List<Task> tasks = controller.vitalTargetsTasks[target.id] ?? [];
        vitalSections.add(
          ListSection(
            title: target.title,
            children: tasks.map((Task task) {
              var [isCompleted, timeCounterPercent] =
                  controller.getTaskCompletions(task);
              return TaskCardWidget(
                isPlanned: true,
                isCompleted: isCompleted,
                progress: timeCounterPercent,
                task,
                toggleFn: () {
                  if (task.currentIteration > 0) {
                    // If we moving task to todo, we need alert that all progress will be lost
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Warning'.tr),
                          content: Text(
                              'Are you sure you want to move this task to todo? All progress will be lost'
                                  .tr),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Cancel'.tr),
                            ),
                            TextButton(
                              onPressed: () {
                                controller.toggleTask(task);
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                'Yes'.tr,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    controller.toggleTask(task);
                  }
                },
                onTap: () {
                  Target target = controller.targets
                      .firstWhere((target) => target.id == task.targetId);
                  Get.toNamed(AppRoutes.targetTask,
                      arguments: {'target': target, 'task': task});
                },
              );
            }).toList(),
          ),
        );
      }

      return SingleChildScrollView(
        child: Column(
          children: vitalSections,
        ),
      );
    });
  }
}
