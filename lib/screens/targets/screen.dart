import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:targetly/app_routes.dart';

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
            return ListView.builder(
              itemCount: controller.targets.length,
              itemBuilder: (context, index) {
                final target = controller.targets[index];
                var completedPercent =
                    controller.getCompletedPercentage(target);
                return TargetWidget(
                  target,
                  completedPercent: completedPercent,
                  onTap: () {
                    Get.toNamed(AppRoutes.targetView, arguments: {
                      'targetId': target.id,
                    });
                  },
                );
              },
            );
          }),
        );
      },
    );
  }
}
