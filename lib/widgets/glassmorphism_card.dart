import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class GlassmorphismCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final double blur;
  final double opacity;

  const GlassmorphismCard({
    Key? key,
    required this.child,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(16),
    this.blur = 10,
    this.opacity = 0.15,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor.withOpacity(opacity + 0.7),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
