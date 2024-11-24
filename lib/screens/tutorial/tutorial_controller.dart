import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../models/account.dart';
import '../../services/app_service.dart';

class TutorialStep {
  final String title;
  final String description;
  final String? imagePath;
  final IconData? icon;

  TutorialStep({
    required this.title,
    required this.description,
    this.imagePath,
    this.icon,
  });
}

class TutorialController extends GetxController {
  final RxInt currentStep = 0.obs;
  final RxBool isLastStep = false.obs;
  final List<TutorialStep> steps;

  Account get account => Get.find<AppService>().currentAccount()!;

  TutorialController({required this.steps}) {
    isLastStep.value = currentStep.value == steps.length - 1;
  }

  void nextStep() {
    if (currentStep.value < steps.length - 1) {
      currentStep.value++;
      isLastStep.value = currentStep.value == steps.length - 1;
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
      isLastStep.value = false;
    }
  }

  void skipTutorial() {
    account.updateMetadata({
      'isTutorialCompleted': true,
    });
    Get.offAllNamed('/');
  }
}
