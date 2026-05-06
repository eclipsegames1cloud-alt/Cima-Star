import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';
import '../config/app_routes.dart';
import '../models/movie_model.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final double? width;
  final double? height;

  const MovieCard({
    Key? key,
    required this.movie,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(
        AppRoutes.movieDetail,
        arguments: {'movie': movie},
      ),
      child: Container(
        width: width ?? 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Poster Image
              CachedNetworkImage(
                imageUrl: movie.posterUrl ?? '',
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppTheme.shimmerBase,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppTheme.shimmerBase,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.movie, color: AppTheme.textTertiary, size: 30),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          movie.displayTitle,
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom gradient overlay
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black87],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.displayTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 10),
                          const SizedBox(width: 2),
                          Text(
                            movie.ratingDisplay,
                            style: const TextStyle(color: Colors.white70, fontSize: 9),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            movie.yearDisplay,
                            style: TextStyle(color: Colors.white60, fontSize: 9),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Type badge
              if (movie.isTV)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'TV',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
