import 'package:get/get.dart';

import '../../../../../models/target.dart';
import '../../../../../models/task.dart';
import '../../../../../services/tasks_service.dart';

class TaskStackViewController extends GetxController {
  late final Task task;
  late final Target target;

  TaskStackViewController() {
    task = Get.arguments['task'];
    target = Get.arguments['target'];
  }

  TasksService tasksService = Get.find();

  void markAsCompleted() async {
    await tasksService.setStatus(task, 'completed');
    Get.back();
  }

  void markAsIncomplete() async {
    await tasksService.setStatus(task, 'todo');
    Get.back();
  }

  void markAsPlanned() async {
    await tasksService.setStatus(task, 'planned');
    Get.back();
  }
}
