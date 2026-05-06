import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;
  final String? retryText;

  const AppErrorWidget({
    Key? key,
    required this.message,
    this.onRetry,
    this.icon,
    this.retryText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon with animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.errorColor.withOpacity(0.1),
                    ),
                    child: Icon(
                      icon ?? Icons.cloud_off,
                      size: 64,
                      color: AppTheme.errorColor.withOpacity(0.7),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Error message
            Text(
              message,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Friendly message
            Text(
              'السيرفر نايم دلوقتي. حاول تاني!',
              style: TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Retry button
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryText ?? 'حاول تاني'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
