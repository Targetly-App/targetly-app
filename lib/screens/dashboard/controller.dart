import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:targetly/screens/dashboard/widgets/tasks_list/widget.dart';
import 'package:targetly/services/app_service.dart';
import 'package:targetly/services/local_notification_service.dart';
import 'package:targetly/services/targets_service.dart';
import 'package:targetly/services/tasks_service.dart';

import '../../models/account.dart';
import '../../models/target.dart';
import '../../models/task.dart';
import '../../utils.dart';

class DashboardController extends GetxController with WidgetsBindingObserver {
  RxBool isLoading = true.obs;

  RxString searchQuery = ''.obs;
  TextEditingController searchTextController = TextEditingController();

  RxMap<String, List<Task>> groupedTasks = <String, List<Task>>{}.obs;
  final RxList<Target> targets = <Target>[].obs;
  StreamSubscription? _targetsSubscription;
  final RxList<Task> plannedTasks = <Task>[].obs;
  StreamSubscription? _tasksSubscription;

  final TargetsService _targetsService = Get.find();
  final TasksService _tasksService = Get.find();
  final LocalNotificationService _localNotificationService = Get.find();

  Account get account => Get.find<AppService>().currentAccount()!;

  List<Map<String, dynamic>> widgets = [
    // {'title': 'Decart\'s square'.tr, 'widget': DecartSquireWidget()},
  ];

  @override
  void onInit() async {
    super.onInit();
    isLoading.value = true;
    await refreshData();
    isLoading.value = false;
  }

  Future<void> refreshData() async {
    targets.value = await _targetsService.getTargets();
    var tasksStatuses = [TaskStatus.planned.name, TaskStatus.completed.name];
    List<Task> tasks = await _tasksService.getTasks(statuses: tasksStatuses);

    // Update notifications
    for (var task in tasks) {
      _localNotificationService.updateTaskNotification(task);
    }

    // Filter tasks by settings
    tasks = tasks.where((task) {
      var [isCompleted, timeCounterPercent] =
          _tasksService.getTaskCompletions(task);
      if (account.settings['hideAwaitingTasks'] == true &&
          isCompleted == true &&
          timeCounterPercent > 0 &&
          task.currentIteration < task.iterations &&
          task.completedAt != null) {
        return false;
      }

      if (account.settings['hideCompletedTasks'] == true &&
          task.status == TaskStatus.completed.name) {
        return false;
      }
      return true;
    }).toList();

    plannedTasks.value = tasks;

    updateTasks(tasks);
  }

  void updateTasks(List<Task> tasks) {
    plannedTasks.value = tasks;
    var sortedTasks = sortTasks(tasks);
    groupedTasks.value = groupTasksByTarget(sortedTasks);

    widgets.clear();
    widgets.add({
      'widget': TasksListWidget(
        tasks: plannedTasks,
      ),
    });
  }

  Map<String, List<Task>> groupTasksByTarget(List<Task> tasks) {
    Map<String, List<Task>> groupedTasks = {};

    for (var task in tasks) {
      Target? taskTarget = targets.firstWhereOrNull((target) {
        return target.id == task.targetId;
      });
      if (taskTarget == null) continue;
      groupedTasks.putIfAbsent(taskTarget.title, () => []).add(task);
    }

    return groupedTasks;
  }

  List<Task> sortTasks(List<Task> tasks) {
    tasks.sort((a, b) {
      // Compare by step
      int stepComparison = a.step.compareTo(b.step);
      if (stepComparison != 0) return stepComparison;

      // If priorities are equal, compare by duration
      return parseDuration(a.duration).compareTo(parseDuration(b.duration));
    });

    return tasks;
  }

  @override
  void onClose() {
    _targetsSubscription?.cancel();
    _tasksSubscription?.cancel();
    super.onClose();
  }
}
