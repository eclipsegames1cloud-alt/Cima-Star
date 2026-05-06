import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';
import '../config/app_routes.dart';
import '../controllers/download_controller.dart';
import '../models/download_model.dart';

class DownloadsScreen extends GetView<DownloadController> {
  const DownloadsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.download, color: AppTheme.accentColor, size: 24),
            const SizedBox(width: 10),
            const Text('التحميلات'),
          ],
        ),
        actions: [
          if (controller.downloads.isNotEmpty)
            TextButton(
              onPressed: () => _showClearDialog(context),
              child: Text('مسح الكل', style: TextStyle(color: AppTheme.errorColor, fontSize: 13)),
            ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        }

        if (controller.downloads.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            // Storage info
            _buildStorageInfo(),
            // Download list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.downloads.length,
                itemBuilder: (context, index) {
                  return _DownloadCard(item: controller.downloads[index]);
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_download, size: 80, color: AppTheme.textTertiary),
          const SizedBox(height: 16),
          Text(
            'لا توجد تحميلات',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'حمّل أفلامك المفضلة لمشاهدتها بدون نت',
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.home),
            icon: const Icon(Icons.explore),
            label: const Text('استكشف الأفلام'),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.storage, color: AppTheme.accentColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مساحة التحميلات',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.totalSize,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${controller.downloads.length} ملف',
            style: TextStyle(color: AppTheme.accentColor, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('مسح كل التحميلات', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'هل أنت متأكد إنك عايز تمسح كل التحميلات؟',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء', style: TextStyle(color: AppTheme.textTertiary)),
          ),
          TextButton(
            onPressed: () {
              // Clear all downloads
              Get.back();
            },
            child: Text('مسح', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }
}

class _DownloadCard extends GetView<DownloadController> {
  final DownloadItem item;
  const _DownloadCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Poster
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            child: CachedNetworkImage(
              imageUrl: item.movie.posterUrl ?? '',
              width: 70,
              height: 100,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 70,
                height: 100,
                color: AppTheme.shimmerBase,
              ),
              errorWidget: (_, __, ___) => Container(
                width: 70,
                height: 100,
                color: AppTheme.shimmerBase,
                child: const Icon(Icons.movie, color: AppTheme.textTertiary, size: 24),
              ),
            ),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.movie.displayTitle,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.fileSizeDisplay,
                    style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  // Status indicator
                  Row(
                    children: [
                      Icon(
                        item.status == DownloadStatus.completed
                            ? Icons.check_circle
                            : item.status == DownloadStatus.downloading
                                ? Icons.downloading
                                : Icons.error,
                        size: 14,
                        color: item.status == DownloadStatus.completed
                            ? AppTheme.successColor
                            : item.status == DownloadStatus.downloading
                                ? AppTheme.accentColor
                                : AppTheme.errorColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _statusText(item.status),
                        style: TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 20),
            onPressed: () => controller.deleteDownload(item),
          ),
        ],
      ),
    );
  }

  String _statusText(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.completed: return 'مكتمل';
      case DownloadStatus.downloading: return 'جاري التحميل';
      case DownloadStatus.pending: return 'في الانتظار';
      case DownloadStatus.failed: return 'فشل';
      case DownloadStatus.paused: return 'متوقف';
    }
  }
}
