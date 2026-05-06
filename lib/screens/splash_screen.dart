import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../config/app_theme.dart';
import '../controllers/splash_controller.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A0A0A), AppTheme.backgroundColor, Color(0xFF0A0A1A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with glow effect
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.5),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.movie_rounded,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),

              // App Name
              ShaderMask(
                shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                child: const Text(
                  'CIMA STAR',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'أفلام ومسلسلات بلا حدود',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 60),

              // Progress indicator
              Obx(() => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 80),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: controller.progress.value,
                        backgroundColor: AppTheme.shimmerBase,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.progress.value < 1.0
                          ? 'جاري التحميل...'
                          : 'مرحبًا!',
                      style: TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
