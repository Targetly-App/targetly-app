import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:targetly/screens/main_controller.dart';

@immutable
class MainScreen extends GetWidget<MainController> {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MainController>(
      init: MainController(),
      builder: (MainController controller) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SafeArea(
          top: false,
          bottom: false,
          child: Scaffold(
            body: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: PageView(
                controller: controller.pageViewController,
                children: controller.pages,
                onPageChanged: (index) {
                  controller.setSelectedView(index);
                },
              ),
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: controller.selectedIndex,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: const TextStyle(fontSize: 12.0),
              unselectedLabelStyle: const TextStyle(fontSize: 12.0),
              onTap: (index) {
                controller.pageViewController.animateToPage(index,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.bounceOut);
              },
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Iconsax.activity_outline),
                  activeIcon: const Icon(Iconsax.activity_bold),
                  label: "Dashboard".tr,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Iconsax.note_2_outline),
                  activeIcon: const Icon(Iconsax.note_21_bold),
                  label: "Targets".tr,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Iconsax.message_outline),
                  activeIcon: const Icon(Iconsax.message_bold),
                  label: "Chat".tr,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Iconsax.setting_3_outline),
                  activeIcon: const Icon(Iconsax.setting_3_bold),
                  label: "Settings".tr,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
