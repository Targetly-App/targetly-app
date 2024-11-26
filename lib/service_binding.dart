import 'package:get/get.dart';
import 'package:targetly/screens/auth/sign_in/controller.dart';
import 'package:targetly/screens/chat/controller.dart';
import 'package:targetly/screens/dashboard/controller.dart';
import 'package:targetly/screens/dashboard/planning/controller.dart';
import 'package:targetly/screens/dashboard/widgets/tasks_list/controller.dart';
import 'package:targetly/screens/settings/controller.dart';
import 'package:targetly/screens/targets/controller.dart';
import 'package:targetly/screens/targets/view/controller.dart';
import 'package:targetly/services/chats_service.dart';
import 'package:targetly/services/local_notification_service.dart';
import 'package:targetly/services/purchese_service.dart';
import 'package:targetly/services/remote_functions_service.dart';
import 'package:targetly/services/targets_service.dart';
import 'package:targetly/services/tasks_service.dart';

class ServiceBinding extends Bindings {
  @override
  void dependencies() {
    // Services
    // Get.lazyPut(() => AppService());
    Get.lazyPut(() => LocalNotificationService());
    Get.lazyPut(() => TargetsService());
    Get.lazyPut(() => TasksService());
    Get.lazyPut(() => RemoteFunctionsService());
    Get.lazyPut(() => ChatsService());
    Get.lazyPut(() => PurchaseService());

    // Controllers
    Get.lazyPut(() => SignInController(), fenix: true);
    Get.lazyPut(() => ChatViewController(), fenix: true);
    Get.lazyPut(() => DashboardController(), fenix: true);
    Get.lazyPut(() => PlanningStackController(), fenix: true);
    Get.lazyPut(() => SettingsController(), fenix: true);
    Get.lazyPut(() => TargetViewController(), fenix: true);
    Get.lazyPut(() => TargetsController(), fenix: true);
    Get.lazyPut(() => TasksListController(), fenix: true);
  }
}
