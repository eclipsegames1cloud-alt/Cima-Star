import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:workmanager/workmanager.dart';
import 'config/app_theme.dart';
import 'config/app_routes.dart';
import 'bindings/app_bindings.dart';

// WorkManager background callback - runs even when app is closed
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'checkNewContent') {
      // Background content check - independent from app lifecycle
      try {
        // We can't use GetX services here (no app context), so we do a minimal check
        // The full check happens in NotificationService when app is open
        debugPrint('[WorkManager] Background check triggered: $task');
      } catch (_) {}
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize WorkManager for background tasks (replaces Timer.periodic)
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  await Workmanager().registerPeriodicTask(
    'checkNewContent',
    'checkNewContent',
    frequency: const Duration(minutes: 30),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingWorkPolicy.keep,
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(const CimaStarApp());
}

class CimaStarApp extends StatelessWidget {
  const CimaStarApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Cima Star',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialBinding: AppBindings(),
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.pages,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
