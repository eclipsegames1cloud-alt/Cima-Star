import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/movie_model.dart';
import 'movie_card.dart';

class MovieCarousel extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Movie> movies;
  final Color? accentColor;
  final VoidCallback? onSeeAll;

  const MovieCarousel({
    Key? key,
    required this.title,
    required this.icon,
    required this.movies,
    this.accentColor,
    this.onSeeAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: accentColor ?? AppTheme.primaryColor, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (onSeeAll != null)
                  TextButton(
                    onPressed: onSeeAll,
                    child: Text(
                      'عرض الكل',
                      style: TextStyle(
                        color: accentColor ?? AppTheme.primaryColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal movie list
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: movies.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: MovieCard(movie: movies[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
