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

  RxList<Target> targets = <Target>[].obs;
  late StreamSubscription<List<Target>> _targetsSubscription;
  RxList<Task> tasks = <Task>[].obs;
  late StreamSubscription<List<Task>> _tasksSubscription;

  @override
  void onInit() async {
    _tasksSubscription =
        _tasksService.subscribe(statuses: []).listen((tasksList) {
      tasks.value = tasksList;

      _targetsSubscription = _targetsService.subscribe().listen((targetsList) {
        targets.value = targetsList;
        isLoading.value = false;
      });
    });

    isOnline = _appService.isOnline();
    super.onInit();
  }

  @override
  void onClose() {
    _targetsSubscription.cancel();
    _tasksSubscription.cancel();
    super.onClose();
  }

  double getCompletedPercentage(Target target) {
    final targetTasks =
        tasks.where((task) => task.targetId == target.id).toList();
    return _targetsService.getCompletedPercentage(target, targetTasks);
  }
}
