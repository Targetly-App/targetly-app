import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:targetly/screens/settings/screen.dart';
import 'package:targetly/screens/settings/subscription/screen.dart';
import 'package:targetly/screens/targets/screen.dart';
import 'package:targetly/services/app_service.dart';

import '../models/account.dart';
import 'chat/screen.dart';
import 'dashboard/screen.dart';

class MainController extends GetxController {
  bool isLoading = true;
  bool isSubscriptionScreenVisible = false;
  int selectedIndex = 0;

  final pageViewController = PageController(initialPage: 0);
  final List<Widget> pages = [
    DashboardScreen(),
    TargetsScreen(),
    ChatScreen(),
    SettingsScreen(),
  ];

  Account account = AppService.to.currentAccount()!;
  bool isUserHasSubscription = false;

  @override
  void onInit() {
    super.onInit();

    if (!account.isSubscribed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showCupertinoModalBottomSheet(
          expand: false,
          context: Get.context!,
          builder: (context) => const Stack(
            children: <Widget>[
              SubscriptionScreen(),
            ],
          ),
        );
      });
    }

    isLoading = false;
    update();
  }

  void setSelectedView(int index) {
    selectedIndex = index;
    update();
  }

  void checkSubscription(context) {
    isSubscriptionScreenVisible = true;
    update();
  }
}
