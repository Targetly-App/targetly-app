import 'package:get/get.dart';
import 'package:targetly/models/account.dart';
import 'package:targetly/screens/dashboard/controller.dart';
import 'package:targetly/services/app_service.dart';

import '../../../../models/target.dart';
import '../../../../models/task.dart';
import '../../../../services/local_notification_service.dart';
import '../../../../services/tasks_service.dart';

class TasksListController extends GetxController {
  RxBool isLoading = true.obs;

  final LocalNotificationService _localNotificationService = Get.find();
  final DashboardController _dashboardController = Get.find();
  final TasksService _tasksService = Get.find();

  Account get account => Get.find<AppService>().currentAccount()!;

  RxMap<String, List<Task>> get groupedTasks =>
      _dashboardController.groupedTasks;
  RxList<Target> get targets => _dashboardController.targets;
  RxList<Task> get tasks => _dashboardController.plannedTasks;

  @override
  void onInit() async {
    super.onInit();

    isLoading.value = false;
  }

  Future<void> toggleTask(Task task, bool isCompleted) async {
    try {
      Task updatedTask;
      if (isCompleted) {
        updatedTask = await _tasksService.setStatus(
            task, TaskStatus.planned.name,
            delay: Duration(seconds: 10));
      } else {
        // Change status to in progress
        updatedTask = await _tasksService.setStatus(
            task, TaskStatus.completed.name,
            delay: Duration(seconds: 10));
        _tasksService.updateLocalNotification(updatedTask);
      }

      _tasksService.updateLocalNotification(updatedTask);

      // Update the task in rx list
      int index = tasks.indexWhere((element) => element.id == task.id);
      if (index != -1) {
        // Replace the task in the list and force update
        List<Task> updatedTasks = tasks.toList();
        updatedTasks[index] = updatedTask;
        _dashboardController.updateTasks(updatedTasks);
      }
    } catch (e) {
      print(e);
    }
  }

  List getTaskCompletions(Task task) {
    return _tasksService.getTaskCompletions(task);
  }
}
