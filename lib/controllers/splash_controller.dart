import 'package:get/get.dart';
import '../services/storage_service.dart';
import '../config/app_routes.dart';

class SplashController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();
  final RxDouble progress = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _startSplash();
  }

  void _startSplash() async {
    // Simulate loading progress
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 50));
      progress.value = i / 100;
    }

    await Future.delayed(const Duration(milliseconds: 500));

    // Check if onboarding is done
    if (_storageService.isOnboardingDone) {
      Get.offAllNamed(AppRoutes.home);
    } else {
      Get.offAllNamed(AppRoutes.home);
      await _storageService.setOnboardingDone();
    }
  }
}
