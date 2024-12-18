import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app_routes.dart';
import '../../../../models/target.dart';
import '../../../../models/task.dart';
import '../../../../widgets/list_section.dart';
import '../../../../widgets/task_card.dart';
import '../controller.dart';

class SimpleListLayer extends GetWidget<PlanningStackController> {
  const SimpleListLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      List<Widget> sections = [];

      List<String> groupedTasks = controller.groupedTasks.keys.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      for (var groupName in groupedTasks) {
        List<Task> tasks = controller.groupedTasks[groupName]!;
        sections.add(
          ListSection(
            title: groupName,
            children: tasks.map((Task task) {
              var [isCompleted, timeCounterPercent] =
                  controller.getTaskCompletions(task);
              return TaskCardWidget(
                isPlanned: true,
                isCompleted: isCompleted,
                progress: timeCounterPercent,
                task,
                toggleFn: () {
                  if (task.status == TaskStatus.planned.value &&
                      task.completedAt != null &&
                      task.currentIteration > 0) {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Warning'.tr),
                          content: Text(
                              'Task in progress. Are you sure you want to move it to todo?'
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
          children: sections,
        ),
      );
    });
  }
}
