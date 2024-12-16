import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:targetly/app_routes.dart';

import '../../../models/task.dart';
import '../../../widgets/task_card.dart';
import 'controller.dart';
import 'layers/simple_list.dart';

@immutable
class PlanningStackScreen extends GetWidget<PlanningStackController> {
  const PlanningStackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PlanningStackController>(
      init: PlanningStackController(),
      builder: (controller) {
        return Obx(() {
          if (controller.isLoading.value) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          return SafeArea(
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: const Color.fromRGBO(0, 0, 0, 0),
                elevation: 0,
                title: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Planning'.tr, style: const TextStyle(fontSize: 20)),
                      // controller.tasks.isEmpty
                      //     ? SizedBox()
                      //     : Text(
                      //         controller
                      //             .layerTitles[controller.selectedLayer.value],
                      //         style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                actions: [
                  // Padding(
                  //   padding: const EdgeInsets.only(right: 10),
                  //   child: TextButton(
                  //     onPressed: () {
                  //       controller.hideCompletedTasks.value =
                  //           !controller.hideCompletedTasks.value;
                  //
                  //       controller.subscribeOnData();
                  //     },
                  //     child: controller.tasks.isEmpty
                  //         ? SizedBox()
                  //         : controller.hideCompletedTasks.value
                  //             ? Text('Show completed'.tr)
                  //             : Text('Hide completed'.tr),
                  //   ),
                  // ),
                ],
              ),
              // bottomNavigationBar: controller.tasks.isEmpty
              //     ? null
              //     : BottomNavigationBar(
              //         currentIndex: controller.selectedLayer.value,
              //         type: BottomNavigationBarType.fixed,
              //         selectedLabelStyle: const TextStyle(fontSize: 12.0),
              //         unselectedLabelStyle: const TextStyle(fontSize: 12.0),
              //         onTap: (index) {
              //           controller.layerViewController.animateToPage(index,
              //               duration: const Duration(milliseconds: 300),
              //               curve: Curves.easeInOut);
              //         },
              //         items: [
              //           BottomNavigationBarItem(
              //             icon: const Icon(Iconsax.task_square_outline),
              //             activeIcon: const Padding(
              //               padding: EdgeInsets.only(left: 21),
              //               child: Icon(Iconsax.task_square_bold),
              //             ),
              //             label: "Simple list".tr,
              //           ),
              //           BottomNavigationBarItem(
              //             icon: const Icon(Iconsax.grid_2_outline),
              //             activeIcon: const Icon(Iconsax.grid_2_bold),
              //             label: "Decart's squires".tr,
              //           ),
              //           BottomNavigationBarItem(
              //             icon: RotatedBox(
              //                 quarterTurns: 1,
              //                 child: const Icon(Iconsax.grid_4_outline)),
              //             activeIcon: RotatedBox(
              //                 quarterTurns: 1,
              //                 child: const Icon(Iconsax.grid_4_bold)),
              //             label: "Pareto analyse".tr,
              //           ),
              //         ],
              //       ),
              body: controller.tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('You have no tasks yet'.tr,
                              style: const TextStyle(fontSize: 20)),
                          Text('Create new target and tasks to plan'.tr),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              Get.toNamed(AppRoutes.targets);
                            },
                            child: Text('Show my targets'.tr),
                          ),
                        ],
                      ),
                    )
                  : PageView(
                      controller: controller.layerViewController,
                      children: [
                        SimpleListLayer(),
                        // DecartSquireLayer(),
                        // ParetoLayer(),
                      ],
                      onPageChanged: (index) {
                        controller.setSelectedLayer(index);
                      },
                    ),
            ),
          );
        });
      },
    );
  }

  Widget getGroupedTasksList(Map<String, List<Task>> groupedTasks) {
    return ListView(
      children: groupedTasks.entries.map<Widget>((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: Text(
                '${entry.key[0].toUpperCase()}${entry.key.substring(1)}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            ListView.builder(
              physics:
                  const NeverScrollableScrollPhysics(), // To avoid inner scroll issues
              shrinkWrap: true, // Important to make ListView take minimum space
              itemCount: entry.value.length,
              itemBuilder: (context, index) {
                var task = entry.value[index];
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
                    showCupertinoModalBottomSheet(
                      expand: false,
                      context: context,
                      builder: (context) => Stack(
                        children: <Widget>[
                          // TasksStackViewScreen(task),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      }).toList(),
    );
  }
}
