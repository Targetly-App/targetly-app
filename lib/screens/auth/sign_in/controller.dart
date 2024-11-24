import 'package:get/get.dart';
import 'package:targetly/app_routes.dart';
import 'package:targetly/errors.dart';
import 'package:targetly/models/account.dart';
import 'package:targetly/services/app_service.dart';

import '../../../services/snack_bar_service.dart';
import '../../main_screen.dart';

class SignInController extends GetxController {
  bool isLoading = false;
  bool isPasswordVisible = false;

  final AppService _app = Get.find<AppService>();

  Future<void> signIn(String email, String password) async {
    try {
      isLoading = true;
      update();
      Account? account = await _app.signIn(email, password);

      if (account != null) {
        await Get.offNamed(AppRoutes.main);
        return;
      }
    } on AppError catch (e) {
      SnackBarService.showError(e.message);
    } catch (e) {
      print(e);
      SnackBarService.showError('An error occurred');
    } finally {
      isLoading = false;
      update();
    }
  }

  void signInWithGoogle() async {
    isLoading = true;
    update();
    Account? account = await _app.signInWithGoogle();

    if (account != null) {
      await Get.off(() => const MainScreen());
      return;
    }

    isLoading = false;
    update();
  }

  void signInWithApple() async {
    isLoading = true;
    update();
    Account? account = await _app.signInWithApple();

    if (account != null) {
      await Get.off(() => const MainScreen());
      return;
    }

    isLoading = false;
    update();
  }

  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    update();
  }
}
