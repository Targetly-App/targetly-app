import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../models/account.dart';
import '../../services/app_service.dart';

class SettingsController extends GetxController {
  RxBool isLoading = true.obs;
  final _appService = Get.find<AppService>();
  int amountOfTokens = 0;
  late Rx<Account?> account;

  late FixedExtentScrollController defaultsScreenScrollController;

  @override
  void onInit() {
    super.onInit();
    account = _appService.currentAccount;
    isLoading.value = false;
  }

  void setHideCompletedTasks(bool value) async {
    try {
      account.value =
          await account.value?.updateSettings({'hideCompletedTasks': value});
    } catch (e) {
      print(e);
    }
  }

  void setHideAwaitingTasks(bool value) async {
    try {
      account.value =
          await account.value?.updateSettings({'hideAwaitingTasks': value});
    } catch (e) {
      print(e);
    }
  }

  void logout() async {
    await _appService.signOut();
  }

  void cleanAccountData() async {
    _appService.cleanAccountData();
    logout();
  }

  Future<void> setDefaultNotificationWeekDays(List<int> value) async {
    account.value = await account.value
        ?.updateSettings({'defaultNotificationsWeekDays': value});
    await _appService.initializeLocalNotifications();
  }

  Future<void> setDefaultNotificationTime(String value) async {
    account.value = await account.value
        ?.updateSettings({'defaultNotificationsTime': value});
    await _appService.initializeLocalNotifications();
  }

  Future<void> setMaxHoursPerDayForTasks(int value) async {
    account.value =
        await account.value?.updateSettings({'hoursPerDayForTasks': value});
  }
}
