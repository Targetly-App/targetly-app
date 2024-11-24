import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:targetly/services/app_service.dart';

import '../../../analysers/decart_tasks_analyser.dart';
import '../../../analysers/pareto_tasks_analyser.dart';
import '../../../app_routes.dart';
import '../../../models/target.dart';
import '../../../models/task.dart';
import '../../../services/targets_service.dart';
import '../../../services/tasks_service.dart';
import '../../../utils.dart';
import 'layers/decart_squire/decart_squire.dart';

class PlanningStackController extends GetxController {
  RxBool isLoading = true.obs;
  RxBool hideCompletedTasks = true.obs;
  RxInt selectedLayer = 0.obs;
  final layerViewController = PageController(initialPage: 0);
  final List<String> layerTitles = [
    'Simple list',
    'Tasks by Decart\'s square',
    'Only 20% of tasks bring 80% of results',
  ];

  final AppService _appService = Get.find();
  final TargetsService _targetsService = Get.find();
  final TasksService _tasksService = Get.find();

  RxMap<String, List<Task>> groupedTasks = <String, List<Task>>{}.obs;
  final RxList<Target> targets = <Target>[].obs;
  StreamSubscription? _targetsSubscription;
  final RxList<Task> tasks = <Task>[].obs;
  StreamSubscription? _tasksSubscription;

  // Decart's square fields
  RxMap<QuadrantType, List<TaskAnalysis>> allTasksMatrix =
      <QuadrantType, List<TaskAnalysis>>{}.obs;

  // Pareto fields
  RxMap<String, List<Task>> vitalTargetsTasks = <String, List<Task>>{}.obs;
  RxMap<String, List<Task>> trivialTargetsTasks = <String, List<Task>>{}.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    subscribeOnData();
  }

  void subscribeOnData() {
    // Stop previous subscriptions
    _targetsSubscription?.cancel();
    _tasksSubscription?.cancel();

    // Subscribe on new data
    _targetsSubscription = _targetsService.subscribe().listen((updatedTargets) {
      isLoading.value = true;
      targets.value = updatedTargets;

      var tasksStatuses = [TaskStatus.todo.name, TaskStatus.planned.name];

      if (!hideCompletedTasks.value) {
        tasksStatuses.add(TaskStatus.completed.name);
      }

      _tasksSubscription = _tasksService
          .subscribe(statuses: tasksStatuses)
          .listen((tasksFromStream) {
        try {
          if (tasksFromStream.isEmpty) {
            isLoading.value = false;
            return;
          }
          isLoading.value = true;
          tasks.value = tasksFromStream;

          groupedTasks.value = groupTasksByTarget(sortTasks(tasksFromStream));

          // Prepare Decart's square data
          allTasksMatrix.value = getDecartSquireTasks();

          // Prepare Pareto data
          applyParetoAnalysis();

          isLoading.value = false;
        } catch (e) {
          print(e);
        }
      });
    });
  }

  void applyParetoAnalysis() {
    ParetoAnalyzer paretoAnalyzer = ParetoAnalyzer();

    for (var target in targets) {
      var targetTasks =
          tasks.where((task) => task.targetId == target.id).toList();

      ParetoResult result = paretoAnalyzer.analyzeTasks(targetTasks);

      vitalTargetsTasks[target.id!] = result.vital.map((e) => e.task).toList();
      trivialTargetsTasks[target.id!] =
          result.trivial.map((e) => e.task).toList();
    }
  }

  Map<QuadrantType, List<TaskAnalysis>> getDecartSquireTasks() {
    TaskAnalyzer analyzer = TaskAnalyzer();

    Map<QuadrantType, List<TaskAnalysis>> tasksMatrix = {};

    for (var target in targets) {
      var targetTasks =
          tasks.where((task) => task.targetId == target.id).toList();
      var deadline = target.deadline;

      if (deadline == null) {
        continue;
      }

      var targetMatrix =
          analyzer.analyzeTasksWithDeadline(targetTasks, deadline);

      for (var type in QuadrantType.values) {
        tasksMatrix
            .putIfAbsent(type, () => [])
            .addAll(targetMatrix.getTasksByQuadrant(type));
      }
    }

    return tasksMatrix;
  }

  @override
  void onClose() {
    _targetsSubscription?.cancel();
    _tasksSubscription?.cancel();
    super.onClose();
  }

  Map<String, List<Task>> groupTasksByTarget(List<Task> tasks) {
    Map<String, List<Task>> groupedTasks = {};

    for (var task in tasks) {
      final target = targets.firstWhereOrNull((target) {
        return target.id == task.targetId;
      });

      if (target == null) {
        print('Target not found for task ${task.id}');
        continue;
      }
      groupedTasks.putIfAbsent(target.title, () => []).add(task);
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

  void toggleTask(Task toggleTask) async {
    Task updatedTask = await _tasksService.setStatus(
        toggleTask,
        toggleTask.status == TaskStatus.todo.name
            ? TaskStatus.planned.name
            : TaskStatus.todo.name);
    await _tasksService.updateLocalNotification(updatedTask);
  }

  List getTaskCompletions(Task task) {
    return _tasksService.getTaskCompletions(task);
  }

  void setSelectedLayer(int index) {
    selectedLayer.value = index;
  }

  void navigateToTask(Task task) {
    Target target = targets.firstWhere((target) => target.id == task.targetId);
    Get.toNamed(AppRoutes.targetTask,
        arguments: {'target': target, 'task': task});
  }

  String getTitleByQuadrant(QuadrantType type) {
    switch (type) {
      case QuadrantType.urgentImportant:
        return 'Urgent and Important';
      case QuadrantType.urgentNotImportant:
        return 'Urgent and Not Important';
      case QuadrantType.notUrgentImportant:
        return 'Not Urgent and Important';
      case QuadrantType.notUrgentNotImportant:
        return 'Not Urgent and Not Important';
    }
  }
}
