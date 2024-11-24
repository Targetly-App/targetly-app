import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:targetly/services/app_service.dart';

import '../../../services/snack_bar_service.dart';
import '../../../widgets/pin_input.dart';

class ResetPasswordController extends GetxController {
  bool isLoading = false;
  bool isEmailSent = false;
  bool isPasswordVisible = false;
  bool canBeSubmitted = false;
  final GlobalKey<PinInputWidgetState> pinKey =
      GlobalKey<PinInputWidgetState>();
  final authFormKey =
      GlobalKey<FormBuilderState>(debugLabel: 'ResetPasswordForm');

  final _appService = Get.find<AppService>();

  /// Send a pin to the user's email
  void sendRecoveryLink() async {
    if (authFormKey.currentState!.saveAndValidate()) {
      isLoading = true;
      update();
      final formData = authFormKey.currentState!.value;
      String email = formData['email'];
      await _appService.sendPasswordResetEmail(email: email);
      isEmailSent = true;
      isLoading = false;
      update();
    } else {
      SnackBarService.showError('Please enter a valid email');
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    update();
  }
}
