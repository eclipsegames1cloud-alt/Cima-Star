import 'package:get/get.dart';
import '../services/api/multi_source_service.dart';
import '../services/api/vid_api_service.dart';
import '../services/cache_service.dart';
import '../services/storage_service.dart';
import '../services/download_service.dart';
import '../services/notification_service.dart';
import '../services/resilience_service.dart';
import '../controllers/home_controller.dart';
import '../controllers/search_controller.dart';
import '../controllers/watchlist_controller.dart';
import '../controllers/download_controller.dart';
import '../controllers/splash_controller.dart';
import '../controllers/browse_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Initialize services (permanent)
    Get.putAsync<StorageService>(() => StorageService().init(), permanent: true);
    Get.putAsync<CacheService>(() => CacheService().init(), permanent: true);
    Get.putAsync<ResilienceService>(() => ResilienceService().init(), permanent: true);
    
    // Register VidApiService first (needed by MultiSourceService and BrowseController)
    Get.lazyPut<VidApiService>(() => VidApiService(Get.find<CacheService>()), fenix: true);
    
    Get.put<MultiSourceService>(MultiSourceService(), permanent: true);
    Get.put<DownloadService>(DownloadService(), permanent: true);
    Get.putAsync<NotificationService>(() => NotificationService().init(), permanent: true);

    // Initialize controllers
    Get.put(SplashController(), permanent: false);
    Get.put(HomeController(), permanent: true);
    Get.put(SearchController());
    Get.put(WatchlistController(), permanent: true);
    Get.put(DownloadController(), permanent: true);
    
    // BrowseController is created lazily per screen via GetBuilder
    // No need to register globally
  }
}
