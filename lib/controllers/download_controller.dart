import 'package:get/get.dart';
import '../models/movie_model.dart';
import '../models/download_model.dart';
import '../services/download_service.dart';
import '../services/storage_service.dart';
import 'dart:io';
import '../utils/helpers.dart';

class DownloadController extends GetxController {
  final DownloadService _downloadService = Get.find<DownloadService>();
  final StorageService _storageService = Get.find<StorageService>();

  final RxList<DownloadItem> downloads = <DownloadItem>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadDownloads();
  }

  /// Load all downloads
  void loadDownloads() {
    isLoading.value = true;
    try {
      final downloadMaps = _storageService.getDownloads();
      downloads.assignAll(
        downloadMaps.map((d) => DownloadItem.fromJson(d)).toList(),
      );
    } catch (e) {
      downloads.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Start downloading a movie
  Future<void> startDownload(Movie movie, String videoUrl) async {
    try {
      Helpers.showLoading('جاري التحميل...');

      final localPath = await _downloadService.downloadVideo(
        movie: movie,
        videoUrl: videoUrl,
      );

      Helpers.hideLoading();

      if (localPath != null) {
        await _storageService.saveDownload(movie, localPath);
        final realSize = File(localPath).existsSync() ? File(localPath).lengthSync() : 0;
        downloads.add(DownloadItem(
          movie: movie,
          localPath: localPath,
          fileSize: realSize,
        ));
        Helpers.showSnackBar(
          message: 'تم تحميل ${movie.displayTitle} بنجاح',
          type: SnackbarType.success,
        );
      } else {
        Helpers.showSnackBar(
          message: 'فشل التحميل. حاول تاني',
          type: SnackbarType.error,
        );
      }
    } catch (e) {
      Helpers.hideLoading();
      Helpers.showSnackBar(
        message: 'خطأ في التحميل: $e',
        type: SnackbarType.error,
      );
    }
  }

  /// Delete a download
  Future<void> deleteDownload(DownloadItem item) async {
    try {
      await _downloadService.deleteDownload(item.localPath);
      await _storageService.removeDownload(item.movie.uniqueId);
      downloads.remove(item);
      Helpers.showSnackBar(
        message: 'تم حذف التحميل',
        type: SnackbarType.info,
      );
    } catch (e) {
      Helpers.showSnackBar(
        message: 'خطأ في حذف التحميل',
        type: SnackbarType.error,
      );
    }
  }

  /// Get download progress for a movie
  double? getDownloadProgress(String movieId) {
    return _downloadService.downloadProgress[movieId];
  }

  /// Check if movie is currently downloading
  bool isDownloading(String movieId) {
    return _downloadService.activeDownloads.contains(movieId);
  }

  /// Cancel download
  void cancelDownload(String movieId) {
    _downloadService.cancelDownload(movieId);
  }

  /// Get total downloads size
  String get totalSize {
    final bytes = downloads.fold<int>(0, (sum, item) => sum + item.fileSize);
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
  }
}
