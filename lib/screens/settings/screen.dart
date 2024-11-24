import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:targetly/screens/settings/subscription/screen.dart';

import '../../app_routes.dart';
import '../../helpers.dart';
import '../../widgets/list_section.dart';
import '../../widgets/list_section_tile.dart';
import 'controller.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
        init: SettingsController(),
        builder: (controller) {
          return Obx(() {
            if (controller.isLoading.value ||
                controller.account.value == null) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            return Scaffold(
              appBar: AppBar(
                backgroundColor: const Color.fromARGB(0, 19, 12, 12),
                elevation: 0,
                title: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Settings'.tr),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text('Logout'.tr),
                              content:
                                  Text('Are you sure you want to logout?'.tr),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('Cancel'.tr),
                                ),
                                TextButton(
                                  onPressed: controller.logout,
                                  child: Text(
                                    'Yes'.tr,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Text('Logout'.tr),
                    ),
                  ),
                ],
              ),
              body: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    ListSection(
                      title: 'Account'.tr,
                      children: [
                        ListSectionTile(
                          title: 'E-mail'.tr,
                          subtitle: controller.account.value?.user.email,
                          leading: const Icon(Iconsax.user_tick_outline),
                        ),
                        ListSectionTile(
                          leading: const Icon(Icons.workspace_premium_rounded),
                          title: 'Subscription'.tr,
                          subtitle: controller.account.value!.isSubscribed
                              ? 'Premium'
                              : 'Free trial',
                          onTap: () {
                            showCupertinoModalBottomSheet(
                              expand: false,
                              context: context,
                              builder: (context) => const Stack(
                                children: <Widget>[
                                  SubscriptionScreen(),
                                ],
                              ),
                            );
                          },
                        ),
                        ListSectionTile(
                          title: 'Remove account data'.tr,
                          subtitle: 'Delete all user data and logout',
                          leading: const Icon(Iconsax.user_remove_outline),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text('Remove account data'.tr),
                                  content: Text(
                                      'Are you sure you want to delete all user data and logout? This action cannot be undone.'
                                          .tr),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('Cancel'.tr),
                                    ),
                                    TextButton(
                                      onPressed: controller.cleanAccountData,
                                      child: Text(
                                        'Delete'.tr,
                                        style:
                                            const TextStyle(color: Colors.red),
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
                    // ListSection(
                    //   title: 'Assistant'.tr,
                    //   children: [
                    //     ListSectionTile(
                    //       title: 'Memory'.tr,
                    //       subtitle: 'Manage assistant memory',
                    //       leading: const Icon(Iconsax.bubble_bold),
                    //       onTap: () {},
                    //     ),
                    //   ],
                    // ),
                    ListSection(
                      title: 'Notifications'.tr,
                      children: [
                        ListSectionTile(
                          title: 'Default time for notifications'.tr,
                          subtitle: controller.account.value?.accountSettings
                              .defaultNotificationsTime,
                          leading: const Icon(Icons.notifications_active),
                          onTap: () {
                            // Convert "2021-01-01 10:30 AM" to DateTime
                            DateFormat format = DateFormat("h:mm a");
                            DateTime currentValue = format.parse(controller
                                .account
                                .value!
                                .accountSettings
                                .defaultNotificationsTime);
                            var selectedTime = currentValue;
                            showCupertinoModalPopup(
                              context: context,
                              builder: (_) => Container(
                                color: CupertinoColors.darkBackgroundGray,
                                height: 270,
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: 200,
                                      child: CupertinoDatePicker(
                                        mode: CupertinoDatePickerMode.time,
                                        use24hFormat: false,
                                        minuteInterval: 30,
                                        initialDateTime: currentValue,
                                        onDateTimeChanged: (value) {
                                          selectedTime = value;
                                        },
                                      ),
                                    ),
                                    CupertinoButton(
                                      child: const Text('Done'),
                                      onPressed: () {
                                        // Getting date string as 'HH a'
                                        String time = getFormattedDate(
                                            selectedTime,
                                            format: 'h:mm a');
                                        controller
                                            .setDefaultNotificationTime(time);
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    ListSection(
                      title: 'Tasks'.tr,
                      children: [
                        ListSectionTile(
                          title: 'Hide completed tasks'.tr,
                          subtitle: 'Completed tasks will be hidden',
                          leading: const Icon(Icons.check),
                          trailing: Switch.adaptive(
                              value: controller.account.value!.accountSettings
                                  .hideCompletedTasks,
                              onChanged: (newValue) {
                                controller.setHideCompletedTasks(newValue);
                              }),
                        ),
                        ListSectionTile(
                          title: 'Hide awaiting tasks'.tr,
                          subtitle:
                              'Tasks awaiting the next iteration will be hidden',
                          leading: const Icon(Iconsax.timer_outline),
                          trailing: Switch.adaptive(
                              value: controller.account.value!.accountSettings
                                  .hideAwaitingTasks,
                              onChanged: (newValue) {
                                controller.setHideAwaitingTasks(newValue);
                              }),
                        ),
                      ],
                    ),
                    ListSection(
                      title: 'Others'.tr,
                      children: [
                        ListSectionTile(
                          title: 'Terms'.tr,
                          subtitle: 'Read the terms and conditions',
                          leading: const Icon(Iconsax.text_block_outline),
                          onTap: () {
                            Get.toNamed(AppRoutes.terms);
                          },
                        ),
                        ListSectionTile(
                          title: 'Privacy'.tr,
                          subtitle: 'Read the privacy policy',
                          leading: const Icon(Iconsax.lock_outline),
                          onTap: () {
                            Get.toNamed(AppRoutes.privacy);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          });
        });
  }
}
