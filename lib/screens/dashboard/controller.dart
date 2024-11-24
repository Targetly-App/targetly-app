import 'dart:async';

import 'package:get/get.dart';
import 'package:targetly/screens/dashboard/widgets/tasks_list/widget.dart';
import 'package:targetly/services/app_service.dart';
import 'package:targetly/services/targets_service.dart';
import 'package:targetly/services/tasks_service.dart';

import '../../models/account.dart';
import '../../models/target.dart';
import '../../models/task.dart';
import '../../utils.dart';

class DashboardController extends GetxController {
  RxBool isLoading = true.obs;

  RxMap<String, List<Task>> groupedTasks = <String, List<Task>>{}.obs;
  final RxList<Target> targets = <Target>[].obs;
  StreamSubscription? _targetsSubscription;
  final RxList<Task> plannedTasks = <Task>[].obs;
  StreamSubscription? _tasksSubscription;

  final TargetsService _targetsService = Get.find();
  final TasksService _tasksService = Get.find();

  Account get account => Get.find<AppService>().currentAccount()!;

  List<Map<String, dynamic>> widgets = [
    // {'title': 'Decart\'s square'.tr, 'widget': DecartSquireWidget()},
  ];

  @override
  void onInit() async {
    super.onInit();

    _targetsSubscription = _targetsService.subscribe().listen((updatedTargets) {
      isLoading.value = true;
      targets.value = updatedTargets;

      // We will subscribe on all tasks statuses but will filter them later
      var tasksStatuses = [TaskStatus.planned.name, TaskStatus.completed.name];

      _tasksSubscription = _tasksService
          .subscribe(statuses: tasksStatuses)
          .listen((tasksFromStream) {
        try {
          if (tasksFromStream.isEmpty) {
            isLoading.value = false;
            return;
          }

          // Filter tasks by settings
          tasksFromStream = tasksFromStream.where((task) {
            if (account.settings['hideAwaitingTasks'] == true &&
                task.currentIteration < task.iterations &&
                task.currentIteration > 0 &&
                task.completedAt != null) {
              return false;
            }

            if (account.settings['hideCompletedTasks'] == true &&
                task.status == TaskStatus.completed.name) {
              return false;
            }
            return true;
          }).toList();

          updateTasks(tasksFromStream);
          isLoading.value = false;
        } catch (e) {
          print(e);
        }
      });
    });
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
