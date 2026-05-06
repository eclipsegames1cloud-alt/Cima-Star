import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/app_theme.dart';

class Helpers {
  /// Show a snackbar with custom styling
  static void showSnackBar({
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    Get.snackbar(
      _getTitle(type),
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: _getColor(type),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: duration,
      icon: Icon(_getIcon(type), color: Colors.white),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static String _getTitle(SnackbarType type) {
    switch (type) {
      case SnackbarType.success: return 'تم بنجاح';
      case SnackbarType.error: return 'خطأ';
      case SnackbarType.warning: return 'تنبيه';
      case SnackbarType.info: return 'معلومة';
    }
  }

  static Color _getColor(SnackbarType type) {
    switch (type) {
      case SnackbarType.success: return AppTheme.successColor;
      case SnackbarType.error: return AppTheme.errorColor;
      case SnackbarType.warning: return AppTheme.warningColor;
      case SnackbarType.info: return AppTheme.accentColor;
    }
  }

  static IconData _getIcon(SnackbarType type) {
    switch (type) {
      case SnackbarType.success: return Icons.check_circle;
      case SnackbarType.error: return Icons.error;
      case SnackbarType.warning: return Icons.warning;
      case SnackbarType.info: return Icons.info;
    }
  }

  /// Show loading dialog
  static void showLoading([String? message]) {
    Get.dialog(
      Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.primaryColor),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Hide loading dialog
  static void hideLoading() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  /// Format duration from seconds
  static String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }

  /// Check if internet is available
  static Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }
}

enum SnackbarType { success, error, warning, info }
