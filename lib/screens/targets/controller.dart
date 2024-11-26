import 'dart:async';

import 'package:get/get.dart';
import 'package:targetly/services/app_service.dart';
import 'package:targetly/services/targets_service.dart';
import 'package:targetly/services/tasks_service.dart';

import '../../models/target.dart';
import '../../models/task.dart';
import '../../widgets/goal_deadline_progress.dart';

class TargetsController extends GetxController {
  final _appService = Get.find<AppService>();
  final _targetsService = Get.find<TargetsService>();
  final _tasksService = Get.find<TasksService>();
  RxBool isLoading = true.obs;
  bool isOnline = false;

  RxBool isCompletedTargetsExpanded = false.obs;

  RxList<Target> completedTargets = <Target>[].obs;
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
        completedTargets.value = targetsList.where((target) {
          var [completedPercent, _] = getProgressDetails(target);
          return completedPercent >= 1;
        }).toList();
        targets.value = targetsList.where((target) {
          var [completedPercent, _] = getProgressDetails(target);
          return completedPercent < 1;
        }).toList();
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

  List getProgressDetails(Target target) {
    final targetTasks =
        tasks.where((task) => task.targetId == target.id).toList();
    double progressPercent =
        _targetsService.getCompletedPercentage(target, targetTasks);

    var notCompletedTasks = targetTasks.where((task) {
      return task.status != TaskStatus.completed.value;
    }).toList();

    var notCompletedTasksMinutes =
        _targetsService.calculateTasksTime(notCompletedTasks);

    var details = DeadlineProgress.calculate(
      maxHoursPerDay:
          _appService.currentAccount.value!.settings['hoursPerDayForTasks'],
      deadline: target.deadline!,
      totalTasksDuration: Duration(minutes: notCompletedTasksMinutes.toInt()),
    );

    return [progressPercent, details];
  }
}
