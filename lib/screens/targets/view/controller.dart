import 'dart:async';

import 'package:get/get.dart';
import 'package:targetly/services/app_service.dart';

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

  final AppService _appService = Get.find();
  Account get account => _appService.currentAccount()!;

  @override
  void onInit() async {
    super.onInit();
    final targetId = Get.arguments['targetId'];
    _targetSubscription =
        _targetsService.listenOneById(targetId).listen((updatedTarget) {
      target.value = updatedTarget;

      _tasksSubscription = _tasksService
          .subscribeOnTargetId(targetId: targetId)
          .listen((tasksFromStream) {
        tasks.value = tasksFromStream;
        isLoading.value = false;
      });
    });
  }

  @override
  void onClose() {
    _targetSubscription?.cancel();
    _tasksSubscription?.cancel();
    super.onClose();
  }
}
