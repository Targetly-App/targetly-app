import 'package:firebase_core/firebase_core.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:targetly/service_binding.dart';
import 'package:targetly/services/app_service.dart';
import 'package:targetly/services/snack_bar_service.dart';
import 'package:targetly/utils.dart';

import 'app_routes.dart';
import 'firebase_options.dart';
import 'models/account.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    name: 'Targetly',
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Because ServiceBinding not support async init, we need to init it manually
  AppService appService = await AppService().init();
  Get.put<AppService>(appService, permanent: true);
  Account? account = appService.currentAccount();

  await configureLocalTimeZone();

  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://290a10761adfe116cf167478b7cd4943@o4507763594690560.ingest.de.sentry.io/4507763598491728';
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 1.0;
      // The sampling rate for profiling is relative to tracesSampleRate
      // Setting to 1.0 will profile 100% of sampled transactions:
      options.profilesSampleRate = 1.0;
    },
    appRunner: () => runApp(GetMaterialApp(
      builder: (context, child) {
        return Material(child: child!);
      },
      navigatorKey: SnackBarService.navigatorKey,
      initialRoute: account == null
          ? AppRoutes.signIn
          : account.metadata['isTutorialCompleted'] != true
              ? AppRoutes.tutorial
              : AppRoutes.main,
      getPages: appPages,
      initialBinding: ServiceBinding(),
      theme: FlexThemeData.light(
        scheme: FlexScheme.materialHc,
        usedColors: 7,
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        blendLevel: 4,
        appBarStyle: FlexAppBarStyle.background,
        bottomAppBarElevation: 1.0,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 10,
          blendOnColors: false,
          blendTextTheme: true,
          useTextTheme: true,
          useM2StyleDividerInM3: true,
          thickBorderWidth: 2.0,
          elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
          elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
          inputDecoratorSchemeColor: SchemeColor.primary,
          inputDecoratorBackgroundAlpha: 12,
          inputDecoratorRadius: 8.0,
          inputDecoratorUnfocusedHasBorder: false,
          inputDecoratorPrefixIconSchemeColor: SchemeColor.primary,
          alignedDropdown: true,
          useInputDecoratorThemeInDialogs: true,
          appBarScrolledUnderElevation: 8.0,
          drawerElevation: 1.0,
          drawerWidth: 290.0,
          bottomNavigationBarSelectedLabelSchemeColor: SchemeColor.secondary,
          bottomNavigationBarMutedUnselectedLabel: false,
          bottomNavigationBarSelectedIconSchemeColor: SchemeColor.secondary,
          bottomNavigationBarMutedUnselectedIcon: false,
          navigationBarSelectedLabelSchemeColor:
              SchemeColor.onSecondaryContainer,
          navigationBarSelectedIconSchemeColor:
              SchemeColor.onSecondaryContainer,
          navigationBarIndicatorSchemeColor: SchemeColor.secondaryContainer,
          navigationBarIndicatorOpacity: 1.00,
          navigationBarElevation: 1.0,
          navigationBarHeight: 72.0,
          navigationRailSelectedLabelSchemeColor:
              SchemeColor.onSecondaryContainer,
          navigationRailSelectedIconSchemeColor:
              SchemeColor.onSecondaryContainer,
          navigationRailIndicatorSchemeColor: SchemeColor.secondaryContainer,
          navigationRailIndicatorOpacity: 1.00,
        ),
        useMaterial3ErrorColors: true,
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        // To use the Playground font, add GoogleFonts package and uncomment
        // fontFamily: GoogleFonts.notoSans().fontFamily,
      ),
      darkTheme: FlexThemeData.dark(
        colors: FlexColor.schemes[FlexScheme.materialHc]!.light.defaultError
            .toDark(40, false),
        usedColors: 7,
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        blendLevel: 10,
        appBarStyle: FlexAppBarStyle.background,
        bottomAppBarElevation: 2.0,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 20,
          blendTextTheme: true,
          useTextTheme: true,
          useM2StyleDividerInM3: true,
          thickBorderWidth: 2.0,
          elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
          elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
          inputDecoratorSchemeColor: SchemeColor.primary,
          inputDecoratorBackgroundAlpha: 48,
          inputDecoratorRadius: 8.0,
          inputDecoratorUnfocusedHasBorder: false,
          inputDecoratorPrefixIconSchemeColor: SchemeColor.primary,
          alignedDropdown: true,
          useInputDecoratorThemeInDialogs: true,
          drawerElevation: 1.0,
          drawerWidth: 290.0,
          bottomNavigationBarSelectedLabelSchemeColor: SchemeColor.secondary,
          bottomNavigationBarMutedUnselectedLabel: false,
          bottomNavigationBarSelectedIconSchemeColor: SchemeColor.secondary,
          bottomNavigationBarMutedUnselectedIcon: false,
          navigationBarSelectedLabelSchemeColor:
              SchemeColor.onSecondaryContainer,
          navigationBarSelectedIconSchemeColor:
              SchemeColor.onSecondaryContainer,
          navigationBarIndicatorSchemeColor: SchemeColor.secondaryContainer,
          navigationBarIndicatorOpacity: 1.00,
          navigationBarElevation: 1.0,
          navigationBarHeight: 72.0,
          navigationRailSelectedLabelSchemeColor:
              SchemeColor.onSecondaryContainer,
          navigationRailSelectedIconSchemeColor:
              SchemeColor.onSecondaryContainer,
          navigationRailIndicatorSchemeColor: SchemeColor.secondaryContainer,
          navigationRailIndicatorOpacity: 1.00,
        ),
        useMaterial3ErrorColors: true,
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        // To use the Playground font, add GoogleFonts package and uncomment
        // fontFamily: GoogleFonts.notoSans().fontFamily,
      ),
      // Use dark or light theme based on system setting.
      themeMode: ThemeMode.dark,
      // darkTheme: FlexThemeData.dark(scheme: FlexScheme.greyLaw),
      // Use dark or light theme based on system setting.

      debugShowCheckedModeBanner: false,
    )),
  );
}
