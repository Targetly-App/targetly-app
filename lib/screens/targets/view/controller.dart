import 'dart:async';

import 'package:get/get.dart';
import 'package:targetly/screens/targets/controller.dart';
import 'package:targetly/services/app_service.dart';
import 'package:targetly/widgets/time_buffer_indicator.dart';

import '../../../models/account.dart';
import '../../../models/target.dart';
import '../../../models/task.dart';
import '../../../services/targets_service.dart';
import '../../../services/tasks_service.dart';

class TargetViewController extends GetxController {
  RxBool isLoading = true.obs;
  List<dynamic> wizardQuestions = [];
  Rx<Target?> target = Rx<Target?>(null);
  StreamSubscription? _targetSubscription;
  RxList<Task> tasks = <Task>[].obs;
  StreamSubscription? _tasksSubscription;
  final TargetsService _targetsService = Get.find();
  final TasksService _tasksService = Get.find();
  final TargetsController _targetsController = Get.find();

  final AppService _appService = Get.find();
  Account get account => _appService.currentAccount()!;

  RxDouble completedPercentage = 0.0.obs;
  late TimeDetails timeDetails;

  @override
  void onInit() async {
    super.onInit();
    final targetId = Get.arguments['targetId'];
    _targetSubscription =
        _targetsService.listenOneById(targetId).listen((updatedTarget) {
      target.value = updatedTarget;

      _tasksSubscription = _tasksService
          .subscribeOnTargetId(targetId: targetId)
          .listen((tasksFromStream) async {
        tasks.value = tasksFromStream;
        completedPercentage.value = _targetsService.getCompletedPercentage(
            target.value!, tasksFromStream);
        timeDetails = await _targetsService.getTimeDetails(target.value!);
        isLoading.value = false;
      });
    });
  }

  Future<void> deleteAllTasks() async {
    if (tasks.isEmpty || target.value == null) {
      return;
    }
    await _tasksService.deleteByTargetId(target.value!.id!);
    tasks.clear();
  }

  Future<void> deleteTarget() async {
    isLoading.value = true;
    await _targetsService.delete(target.value!);
    Get.back();
  }

  Future<void> markAsCompleted() async {
    if (target.value == null) {
      return;
    }

    // Set status 'completed' for all tasks
    await _tasksService.markAllAsCompletedByTarget(target.value!);
    Get.back();
  }

  Future<void> startTargetAgain() async {
    if (target.value == null) {
      return;
    }

    // Set status 'active' for all tasks
    await _tasksService.resetAllTasksStatusByTarget(target.value!);
    Get.back();
  }

  @override
  void onClose() {
    _targetsController.refreshData();
    _targetSubscription?.cancel();
    _tasksSubscription?.cancel();
    super.onClose();
  }
}
