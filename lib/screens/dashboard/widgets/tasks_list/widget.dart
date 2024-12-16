import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:targetly/models/task.dart';

import '../../../../app_routes.dart';
import '../../../../widgets/list_section.dart';
import '../../../../widgets/task_card.dart';
import 'controller.dart';

@immutable
class TasksListWidget extends GetWidget<TasksListController> {
  final List<Task>? tasks;
  final EdgeInsets? margin;
  const TasksListWidget({super.key, this.tasks, this.margin});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (controller.groupedTasks.keys.isEmpty) {
        return Center(
          child: Text('No planned tasks'.tr),
        );
      }

      return getGroupedTasksList(controller);
    });
  }

  Widget getGroupedTasksList(TasksListController controller) {
    var sortedTargets = controller.groupedTasks.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    return Column(
      children: sortedTargets.map<Widget>((title) {
        List<Task> tasks = controller.groupedTasks[title]!;
        return ListSection(
          insetGrouped: true,
          margin: margin,
          title: title,
          children: [
            for (var task in tasks)
              Builder(builder: (context) {
                var [isCompleted, timeCounterPercent] =
                    controller.getTaskCompletions(task);
                return TaskCardWidget(
                  task,
                  isPlanned: true,
                  isCompleted: isCompleted,
                  progress: timeCounterPercent,
                  toggleFn: () async {
                    if (isCompleted) {
                      // Need tell user that iteration will be reduced
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Warning'.tr),
                            content: Text(
                                'Are you sure you want to remove the completed status and decrease the iteration?'
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
                                  await controller.toggleTask(
                                      task, isCompleted);
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
                      await controller.toggleTask(task, isCompleted);
                    }
                  },
                  onTap: () {
                    var target = controller.targets
                        .firstWhere((element) => element.id == task.targetId);
                    Get.toNamed(AppRoutes.targetTask,
                        arguments: {'target': target, 'task': task});
                  },
                );
              }),
          ],
        );
      }).toList(),
    );
  }
}
