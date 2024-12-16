import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:targetly/helpers.dart';
import 'package:targetly/screens/dashboard/controller.dart';
import 'package:targetly/widgets/list_section.dart';
import 'package:targetly/widgets/list_section_tile.dart';

import '../../app_routes.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(0, 0, 0, 0),
        elevation: 0,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text('Dashboard'.tr),
        ),
        actions: [
          // Padding(
          //   padding: const EdgeInsets.only(right: 10),
          //   child: TextButton(
          //     onPressed: () {},
          //     child: Text('Customize'.tr),
          //   ),
          // ),
        ],
      ),
      body: Obx(() {
        String todayTasksInfo =
            "${controller.groupedTasks.keys.length} targets with ${controller.plannedTasks.length} planned tasks";
        return controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: controller.refreshData,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 10),
                      ListSection(children: [
                        ListSectionTile(
                          title: getFormattedDate(DateTime.now()),
                          subtitle: todayTasksInfo,
                          leading: Icon(Iconsax.calendar_edit_outline),
                          trailing: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              minimumSize: Size(70, 30),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              backgroundColor: Theme.of(context).cardColor,
                            ),
                            onPressed: () {
                              Get.toNamed(AppRoutes.planning);
                            },
                            child: Text('Planning'.tr),
                          ),
                        ),
                      ]),
                      ...controller.widgets.map(
                        (widget) => widget['widget'],
                      ),
                    ],
                  ),
                ),
              );
      }),
    );
  }
}
