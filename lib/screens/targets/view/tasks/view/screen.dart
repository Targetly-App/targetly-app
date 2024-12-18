import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:targetly/models/task.dart';
import 'package:targetly/widgets/chat/widget.dart';

import '../../../../../app_routes.dart';
import '../../../../../widgets/app_overflow_menu.dart';
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
                  child: AppOverflowMenu(
                    actions: [
                      if (controller.task.status !=
                          TaskStatus.completed.value) ...[
                        MenuAction(
                          title: 'Edit'.tr,
                          icon: Iconsax.edit_outline,
                          onTap: () {
                            Get.toNamed(AppRoutes.editTargetTask, arguments: {
                              'target': controller.target,
                              'task': controller.task
                            });
                          },
                        ),
                        MenuAction(
                          title: 'Mark as completed'.tr,
                          icon: Iconsax.tick_square_outline,
                          onTap: () {
                            controller.markAsCompleted();
                          },
                        ),
                      ],
                      if (controller.task.status == TaskStatus.todo.value)
                        MenuAction(
                          title: 'Mark as planned'.tr,
                          icon: Iconsax.play_circle_outline,
                          onTap: () {
                            controller.markAsPlanned();
                          },
                        ),
                      if (controller.task.status ==
                          TaskStatus.completed.value) ...[
                        MenuAction(
                          title: 'Mark as incomplete'.tr,
                          icon: Iconsax.refresh_outline,
                          onTap: () {
                            controller.markAsIncomplete();
                          },
                        ),
                      ],
                      MenuAction(
                        title: 'Delete'.tr,
                        icon: Icons.delete_outline,
                        isDestructive: true,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Delete target'.tr),
                                content: Text(
                                    'Are you sure you want to delete this target?\n\nAll tasks associated with this target will be deleted as well.\n\nThis action cannot be undone.'
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
                                      // await controller.deleteTarget();
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
                      ),
                    ],
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
