import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../../app_routes.dart';
import '../../widgets/stacked.dart';
import '../../widgets/sub_bar.dart';
import '../../widgets/target.dart';
import 'add/screen.dart';
import 'controller.dart';

class TargetsScreen extends GetView<TargetsController> {
  const TargetsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: TargetsController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color.fromRGBO(0, 0, 0, 0),
            elevation: 0,
            title: Align(
              alignment: Alignment.centerLeft,
              child: Text('Targets'.tr),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: TextButton(
                  onPressed: () {
                    showCupertinoModalBottomSheet(
                      expand: false,
                      isDismissible: false,
                      enableDrag: false,
                      context: context,
                      builder: (context) => Stack(
                        children: <Widget>[
                          TargetAddScreen(),
                        ],
                      ),
                    );
                  },
                  child: Text('Create'.tr),
                ),
              ),
            ],
          ),
          body: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.targets.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('No targets'.tr, style: const TextStyle(fontSize: 20)),
                    Text('Add new target for start your journey'.tr),
                  ],
                ),
              );
            }

            return CustomScrollView(
              slivers: [
                if (controller.completedTargets.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: SubBar(
                      title: 'Completed'.tr,
                      actions: [
                        controller.isCompletedTargetsExpanded.value
                            ? TextButton.icon(
                                icon: Icon(Iconsax.arrow_up_2_outline),
                                onPressed: () {
                                  controller.isCompletedTargetsExpanded.value =
                                      !controller
                                          .isCompletedTargetsExpanded.value;
                                },
                                label: Text('Roll up'.tr),
                              )
                            : SizedBox(),
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: TextButton.icon(
                            icon: Icon(Iconsax.trash_outline),
                            onPressed: () {
                              controller.removeAllCompletedTargets();
                            },
                            label: Text('Clean'.tr),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: AnimatedStackedCards(
                      spacing: 15,
                      maxVisibleCards: 3,
                      scaleFactor: 0.03,
                      isExpanded: controller.isCompletedTargetsExpanded.value,
                      onExpandChanged: (expanded) {},
                      onTap: () {
                        controller.isCompletedTargetsExpanded.value = true;
                      },
                      children:
                          controller.completedTargets.take(3).map((target) {
                        return TargetWidget(
                          target,
                          completedPercent: 1,
                          onTap: controller.isCompletedTargetsExpanded.value ||
                                  controller.completedTargets.length == 1
                              ? () {
                                  Get.toNamed(AppRoutes.targetView, arguments: {
                                    'targetId': target.id,
                                  });
                                }
                              : null,
                        );
                      }).toList(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SubBar(title: 'In Progress'.tr),
                  ),
                ],
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final target = controller.targets[index];
                      var [completedPercent, details] =
                          controller.getProgressDetails(target);

                      return TargetWidget(
                        target,
                        progress: details,
                        completedPercent: completedPercent,
                        onTap: () {
                          Get.toNamed(AppRoutes.targetView, arguments: {
                            'targetId': target.id,
                          });
                        },
                      );
                    },
                    childCount: controller.targets.length,
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }
}
