import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/movie_model.dart';
import '../utils/constants.dart';

class DownloadService extends GetxService {
  final Dio _dio = Dio();
  final RxMap<String, double> downloadProgress = <String, double>{}.obs;
  final RxList<String> activeDownloads = <String>[].obs;

  /// Request storage permission
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  /// Get download directory
  Future<String> getDownloadDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final downloadPath = '${dir.path}/${AppConstants.downloadFolder}';
    await Directory(downloadPath).create(recursive: true);
    return downloadPath;
  }

  /// Download a movie/video file
  Future<String?> downloadVideo({
    required Movie movie,
    required String videoUrl,
  }) async {
    // --- URL Validation: only allow direct media streams ---
    final isDirectStream = videoUrl.contains('.mp4') || videoUrl.contains('.m3u8');
    if (!isDirectStream) {
      // TODO (Video Sniffer): In a future version, intercept WebView network
      // requests using a NavigationDelegate or a native channel to sniff the
      // real media URL from embed pages, then pass that URL here instead.
      Get.snackbar(
        'تنزيل غير متاح',
        'التنزيل المباشر غير متاح لهذا المصدر.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE50914),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return null;
    }

    final hasPermission = await requestPermission();
    if (!hasPermission) throw Exception('Storage permission denied');

    final movieId = movie.imdbId ?? movie.id ?? DateTime.now().toString();
    final dir = await getDownloadDir();
    final fileName = '${movie.displayTitle}_$movieId.mp4';
    final savePath = '$dir/$fileName';

    // Check if already downloading
    if (activeDownloads.contains(movieId)) return null;

    activeDownloads.add(movieId);
    downloadProgress[movieId] = 0.0;

    try {
      await _dio.download(
        videoUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            downloadProgress[movieId] = received / total;
          }
        },
      );

      downloadProgress[movieId] = 1.0;
      activeDownloads.remove(movieId);
      return savePath;
    } catch (e) {
      downloadProgress.remove(movieId);
      activeDownloads.remove(movieId);
      return null;
    }
  }

  /// Cancel download
  void cancelDownload(String movieId) {
    activeDownloads.remove(movieId);
    downloadProgress.remove(movieId);
  }

  /// Delete downloaded file
  Future<void> deleteDownload(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Get all downloaded files info
  Future<List<Map<String, dynamic>>> getDownloadedFiles() async {
    final dir = await getDownloadDir();
    final directory = Directory(dir);

    if (!await directory.exists()) return [];

    final files = <Map<String, dynamic>>[];
    await for (final entity in directory.list()) {
      if (entity is File && entity.path.endsWith('.mp4')) {
        final stat = await entity.stat();
        files.add({
          'path': entity.path,
          'size': stat.size,
          'modified': stat.modified,
        });
      }
    }
    return files;
  }

  /// Format file size
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
  }
}
