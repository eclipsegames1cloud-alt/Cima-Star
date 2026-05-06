import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class RatingBadge extends StatelessWidget {
  final double rating;

  const RatingBadge({Key? key, required this.rating}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: _getGradient(),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: _getColor().withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    if (rating >= 8.0) return AppTheme.successColor;
    if (rating >= 6.0) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  LinearGradient _getGradient() {
    if (rating >= 8.0) {
      return const LinearGradient(
        colors: [Color(0xFF00C853), Color(0xFF009624)],
      );
    }
    if (rating >= 6.0) {
      return const LinearGradient(
        colors: [Color(0xFFFFAB00), Color(0xFFFF8F00)],
      );
    }
    return const LinearGradient(
      colors: [Color(0xFFFF1744), Color(0xFFD50000)],
    );
  }
}
