import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:targetly/services/app_service.dart';

import '../../../errors.dart';
import '../../../services/snack_bar_service.dart';
import '../sign_in/controller.dart';

class SignUpController extends GetxController {
  bool isLoading = false;
  bool isPasswordVisible = false;

  final AppService _app = Get.find<AppService>();
  final SignInController _signInController = Get.find<SignInController>();

  void signUp(GlobalKey<FormBuilderState> formKey) async {
    if (formKey.currentState!.saveAndValidate()) {
      try {
        String email = formKey.currentState!.value['email'];
        String password = formKey.currentState!.value['password'];
        await _app.registerUser(email, password);

        SnackBarService.showSuccess('Account created successfully');

        // Sign in the user
        await _signInController.signIn(email, password);
      } on AppError catch (e) {
        SnackBarService.showError(e.message);
      } catch (e) {
        print(e);
        SnackBarService.showError('An error occurred');

        return;
      }
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    update();
  }
}
