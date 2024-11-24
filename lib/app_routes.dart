import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:targetly/screens/auth/reset_password/screen.dart';
import 'package:targetly/screens/auth/sign_up/sceeen.dart';
import 'package:targetly/screens/dashboard/planning/screen.dart';
import 'package:targetly/screens/dashboard/screen.dart';
import 'package:targetly/screens/main_screen.dart';
import 'package:targetly/screens/privacy/screen.dart';
import 'package:targetly/screens/targets/add/screen.dart';
import 'package:targetly/screens/targets/edit/screen.dart';
import 'package:targetly/screens/targets/screen.dart';
import 'package:targetly/screens/targets/view/screen.dart';
import 'package:targetly/screens/targets/view/tasks/edit/screen.dart';
import 'package:targetly/screens/targets/view/tasks/generator/screen.dart';
import 'package:targetly/screens/targets/view/tasks/view/screen.dart';
import 'package:targetly/screens/terms/screen.dart';
import 'package:targetly/screens/tutorial/tutorial_controller.dart';
import 'package:targetly/screens/tutorial/tutorial_screen.dart';

import 'screens/auth/sign_in/screen.dart';

class AppRoutes {
  static const String tutorial = '/tutorial';
  static const String signIn = '/auth/signIn';
  static const String signUp = '/auth/signUp';
  static const String resetPassword = '/auth/resetPassword';
  static const String terms = '/terms';
  static const String privacy = '/privacy';
  static const String main = '/';
  static const String dashboard = '/dashboard';
  static const String planning = '/planning';
  static const String targets = '/targets';
  static const String targetView = '/targets/:id/view';
  static const String editTarget = '/targets/:id/edit';
  static const String targetTasksGenerate = '/targets/:id/tasks/generate';
  static const String editTargetTask = '/targets/:id/task/:taskId/edit';
  static const String addTarget = '/targets/add';
  static const String targetTask = '/targets/:id/edit/:taskId';
  static const String chat = '/chat';
  static const String subscription = '/subscription';
  static const String emailConfirmation = '/auth/emailConfirmation';
}

final tutorialSteps = [
  TutorialStep(
    title: 'Welcome to Targetly',
    description:
        'Organize your life targets and achieve better results with us.',
    imagePath: 'assets/tutorial/dashboard.png',
  ),
  TutorialStep(
    title: 'Targets',
    description:
        'Set your life goals or regular targets and track your progress',
    imagePath: 'assets/tutorial/targets.png',
  ),
  TutorialStep(
    title: 'Generate Tasks',
    description: 'Generate tasks for your targets using our AI assistant',
    imagePath: 'assets/tutorial/target-1.png',
  ),
  TutorialStep(
    title: 'Chat with your Targets',
    description: 'Chat about your targets and tasks to gain instant insights',
    imagePath: 'assets/tutorial/target-chat.png',
  ),
  TutorialStep(
    title: 'Smart planning',
    description: 'Enhance planning with Cartesian quadrants or Pareto analysis',
    imagePath: 'assets/tutorial/planning-decart.png',
  ),
];

List<GetPage> appPages = [
  GetPage(
    name: AppRoutes.signIn,
    page: () => SignInScreen(
      key: GlobalKey(debugLabel: 'SignInScreen'),
    ),
  ),
  GetPage(
    name: AppRoutes.signUp,
    page: () => SignUpScreen(
      key: GlobalKey(debugLabel: 'SignUpScreen'),
    ),
  ),
  GetPage(
    name: AppRoutes.resetPassword,
    page: () => const ResetPasswordScreen(),
  ),
  GetPage(name: AppRoutes.terms, page: () => const TermsScreen()),
  GetPage(name: AppRoutes.privacy, page: () => const PrivacyScreen()),
  GetPage(
      name: AppRoutes.tutorial,
      page: () => TutorialScreen(steps: tutorialSteps)),
  GetPage(name: AppRoutes.main, page: () => const MainScreen()),
  GetPage(name: AppRoutes.dashboard, page: () => DashboardScreen()),
  GetPage(name: AppRoutes.planning, page: () => PlanningStackScreen()),
  GetPage(name: AppRoutes.targets, page: () => TargetsScreen()),
  GetPage(name: AppRoutes.addTarget, page: () => TargetAddScreen()),
  GetPage(name: AppRoutes.editTarget, page: () => TargetEditScreen()),
  GetPage(name: AppRoutes.editTargetTask, page: () => TaskEditScreen()),
  GetPage(name: AppRoutes.targetTask, page: () => TaskViewScreen()),
  GetPage(name: AppRoutes.targetView, page: () => TargetViewScreen()),
  GetPage(
    name: AppRoutes.targetTasksGenerate,
    page: () => TasksGeneratorScreen(),
  ),
];
