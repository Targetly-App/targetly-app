import 'package:get/get.dart';
import 'package:targetly/services/targets_service.dart';
import 'package:targetly/services/tasks_service.dart';

import '../../../../../models/target.dart';
import '../../../../../widgets/step_wizard/widget.dart';

class TasksGeneratorController extends GetxController {
  bool isLoading = true;
  List<dynamic> wizardQuestions = [];
  Target get target => Get.arguments['target'];

  final TargetsService _targetsService = Get.find();
  final TasksService _tasksService = Get.find();

  @override
  void onInit() async {
    super.onInit();
    await _createWizardQuestions();

    isLoading = false;
    update();
  }

  Future<void> _createWizardQuestions() async {
    List<ClarificationQuestion?> questions =
        await _targetsService.getClarificationQuestions(target.id!);

    wizardQuestions = [
      ...questions.map((ClarificationQuestion? q) {
        return StepWizardQuestion(
            id: q!.question,
            title: q.title,
            question: q.question,
            multiline: q.multiline,
            multipleChoice: q.answerType == 'multi-select',
            options: q.answerOptions);
      })
    ];
  }

  Future<void> generateTasks(Map<String, String> answers) async {
    isLoading = true;
    update();
    List<Map<String, String>> listOfAnswers = [];
    for (var entry in answers.entries) {
      listOfAnswers.add({'question': entry.key, 'answer': entry.value});
    }
    var tasks = await _targetsService.generateTasks(target.id!, listOfAnswers);

    // Save tasks to the target
    for (var task in tasks) {
      await _tasksService.create(
        task.copyWith(
          uid: target.uid,
          targetId: target.id,
        ),
      );
    }

    Get.close(1);
  }
}
