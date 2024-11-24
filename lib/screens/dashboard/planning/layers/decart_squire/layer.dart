import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:targetly/analysers/decart_tasks_analyser.dart';
import 'package:targetly/screens/dashboard/planning/controller.dart';

import '../../../../../models/task.dart';
import '../../../../../widgets/list_section.dart';
import '../../../../../widgets/task_card.dart';
import 'decart_squire.dart';

class DecartSquireLayer extends GetWidget<PlanningStackController> {
  const DecartSquireLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return SingleChildScrollView(
        child: Column(
          children: [
            DecartSquareWidget(
              onQuadrantTap: (QuadrantType type) {
                var obxWidget = Obx(() {
                  List<TaskAnalysis> quadrantTasksAnalysis =
                      controller.allTasksMatrix[type]!;

                  List<Widget> sections = [];

                  for (var targetTitle in controller.groupedTasks.keys) {
                    List<Task> groupTasks =
                        controller.groupedTasks[targetTitle]!;
                    groupTasks = groupTasks.where((task) {
                      return quadrantTasksAnalysis.any((element) {
                        return element.task.id == task.id;
                      });
                    }).toList();

                    if (groupTasks.isEmpty) {
                      continue;
                    }

                    sections.add(
                      ListSection(
                        title: targetTitle,
                        children: groupTasks.map((task) {
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
                                            style: const TextStyle(
                                                color: Colors.red),
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
                              controller.navigateToTask(task);
                            },
                          );
                        }).toList(),
                      ),
                    );
                  }

                  return Column(children: sections);
                });

                // Show list of tasks in this quadrant
                showCupertinoModalBottomSheet(
                  context: context,
                  builder: (context) {
                    final title = controller.getTitleByQuadrant(type);
                    return Scaffold(
                      appBar: AppBar(
                        backgroundColor: Colors.transparent,
                        title: Text(title),
                      ),
                      body: SingleChildScrollView(
                        child: obxWidget,
                      ),
                    );
                  },
                );
              },
              taskCounts: {
                QuadrantType.urgentImportant: controller
                        .allTasksMatrix[QuadrantType.urgentImportant]?.length ??
                    0,
                QuadrantType.notUrgentImportant: controller
                        .allTasksMatrix[QuadrantType.notUrgentImportant]
                        ?.length ??
                    0,
                QuadrantType.urgentNotImportant: controller
                        .allTasksMatrix[QuadrantType.urgentNotImportant]
                        ?.length ??
                    0,
                QuadrantType.notUrgentNotImportant: controller
                        .allTasksMatrix[QuadrantType.notUrgentNotImportant]
                        ?.length ??
                    0,
              },
            )
          ],
        ),
      );
    });
  }
}
