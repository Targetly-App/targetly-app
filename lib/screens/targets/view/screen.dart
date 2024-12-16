import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:targetly/helpers.dart';
import 'package:targetly/screens/targets/view/tasks/add/screen.dart';
import 'package:targetly/services/snack_bar_service.dart';

import '../../../app_routes.dart';
import '../../../models/target.dart';
import '../../../models/task.dart';
import '../../../widgets/button.dart';
import '../../../widgets/chat/widget.dart';
import '../../../widgets/sub_bar.dart';
import '../../../widgets/target_steps.dart';
import 'controller.dart';

class TargetViewScreen extends GetView<TargetViewController> {
  const TargetViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: TargetViewController(),
      builder: (TargetViewController controller) {
        return Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return SafeArea(
            bottom: false,
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: const Color.fromRGBO(0, 0, 0, 0),
                elevation: 0,
                title: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Target overview'.tr),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: TextButton(
                      onPressed: () {
                        Get.toNamed(AppRoutes.editTarget, arguments: {
                          'targetId': controller.target.value!.id,
                        });
                      },
                      child: Text('Edit'.tr),
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment
                      .spaceBetween, // Adjust alignment as needed
                  children: [
                    Expanded(
                      child: Button(
                        text: 'Open chat'.tr,
                        onPressed: () {
                          showCupertinoModalBottomSheet(
                            expand: false,
                            context: context,
                            builder: (context) => Stack(
                              children: [
                                Scaffold(
                                  appBar: AppBar(
                                    backgroundColor:
                                        const Color.fromRGBO(0, 0, 0, 0),
                                    elevation: 0,
                                    title: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('Target chat'.tr),
                                    ),
                                  ),
                                  body: ChatWidget(
                                      target: controller.target.value),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              body: _buildTasksList(
                  context, controller.target.value!, controller.tasks),
            ),
          );
        });
      },
    );
  }

  Widget _buildTasksList(
      BuildContext context, Target target, List<Task> tasks) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text('Target'.tr),
            subtitle: Text(target.title),
          ),
          if (target.description != null && target.description!.isNotEmpty)
            ListTile(
              title: Text('Description'.tr),
              subtitle: Text(target.description!),
            ),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: Text('Deadline'.tr),
                  subtitle: Text(target.deadline != null
                      ? getFormattedDate(target.deadline!)
                      : 'No deadline'.tr),
                ),
              ),
              Expanded(
                child: ListTile(
                  title: Text('Completed'.tr),
                  subtitle: Text(
                      '${(controller.completedPercentage * 100).toInt()}%'),
                ),
              ),
            ],
          ),
          // ListTile(
          //   title: Text('Time available'.tr),
          //   subtitle: Padding(
          //     padding: const EdgeInsets.only(top: 8),
          //     child: TimeBufferIndicator(
          //       details: controller.timeDetails,
          //     ),
          //   ),
          // ),
          const Divider(),
          SubBar(
            title: 'Tasks'.tr,
            actions: [
              TextButton.icon(
                icon: Icon(Icons.auto_awesome),
                onPressed: () {
                  if (controller.account.isSubscribed) {
                    Get.toNamed(
                      AppRoutes.targetTasksGenerate,
                      arguments: {'target': target},
                    );
                  } else {
                    SnackBarService.showInfo(
                      title: 'Subscription required'.tr,
                      'Please subscribe to generate tasks'.tr,
                    );
                  }
                },
                label: Text('Generate'.tr),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: TextButton(
                  onPressed: () {
                    showCupertinoModalBottomSheet(
                      expand: true,
                      isDismissible: false,
                      enableDrag: false,
                      context: context,
                      backgroundColor: Theme.of(context).canvasColor,
                      builder: (context) => Stack(
                        children: <Widget>[
                          AddTaskScreen(target),
                        ],
                      ),
                    );
                  },
                  child: Text('Create'.tr),
                ),
              ),
            ],
          ),
          if (tasks.isEmpty) ...[
            ListTile(
              title: Text('No tasks'.tr),
              subtitle: Text('Generate list of tasks or create it manually'.tr),
            ),
          ],
          TargetStepsWidget(
            target: target,
            tasks: tasks,
            onTaskTap: (Task task) {
              Get.toNamed(
                AppRoutes.targetTask,
                arguments: {'target': target, 'task': task},
              );
            },
          ),
        ],
      ),
    );
  }
}
