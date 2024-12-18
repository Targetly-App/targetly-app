import 'dart:async';

import 'package:get/get.dart';
import 'package:targetly/services/app_service.dart';
import 'package:targetly/services/targets_service.dart';
import 'package:targetly/services/tasks_service.dart';

import '../../models/target.dart';
import '../../models/task.dart';

class TargetsController extends GetxController {
  final _appService = Get.find<AppService>();
  final _targetsService = Get.find<TargetsService>();
  final _tasksService = Get.find<TasksService>();
  RxBool isLoading = true.obs;
  bool isOnline = false;

  RxBool isCompletedTargetsExpanded = false.obs;

  RxList<Target> completedTargets = <Target>[].obs;
  RxList<Target> targets = <Target>[].obs;

  RxList<Task> tasks = <Task>[].obs;

  @override
  void onInit() async {
    isLoading.value = true;
    await refreshData();
    isLoading.value = false;
    isOnline = _appService.isOnline();
    super.onInit();
  }

  Future<void> refreshData() async {
    List<Target> targets = await _targetsService.getTargets();
    tasks.value = await _tasksService.getTasks();

    completedTargets.value = targets.where((target) {
      var targetTasks =
          tasks.where((task) => task.targetId == target.id).toList();
      var completedPercent =
          _targetsService.getCompletedPercentage(target, targetTasks);
      return completedPercent >= 1;
    }).toList();

    this.targets.value = targets.where((target) {
      var targetTasks =
          tasks.where((task) => task.targetId == target.id).toList();
      var completedPercent =
          _targetsService.getCompletedPercentage(target, targetTasks);
      return completedPercent < 1;
    }).toList();
  }

  Future<void> removeAllCompletedTargets() async {
    isLoading.value = true;
    for (var target in completedTargets) {
      await _targetsService.delete(target);
    }
    isLoading.value = false;
  }

  double getCompletedPercentage(Target target) {
    var targetTasks =
        tasks.where((task) => task.targetId == target.id).toList();
    return _targetsService.getCompletedPercentage(target, targetTasks);
  }
}
