import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';
import '../config/app_routes.dart';
import '../controllers/search_controller.dart';
import '../controllers/browse_controller.dart';
import '../models/movie_model.dart';
import '../widgets/shimmer_loading.dart';

class SearchScreen extends GetView<SearchController> {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: _buildSearchField(),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const ShimmerListLoading();
        }

        if (!controller.hasSearched.value) {
          return _buildSearchSuggestions();
        }

        if (controller.searchResults.isEmpty) {
          return _buildEmptyState();
        }

        return _buildSearchResults();
      }),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: TextField(
        onChanged: controller.onSearchChanged,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'ابحث عن فيلم أو مسلسل...',
          hintStyle: TextStyle(color: AppTheme.textTertiary, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor, size: 20),
          suffixIcon: Obx(() => controller.searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textTertiary, size: 18),
                  onPressed: controller.clearSearch,
                )
              : const SizedBox.shrink()),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (query) => controller.performSearch(query),
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Genre filters
          if (controller.availableGenres.isNotEmpty) ...[
            Text(
              'تصفح حسب النوع',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.availableGenres.map((genre) {
                return GestureDetector(
                  onTap: () => controller.filterByGenre(genre),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.shimmerHighlight),
                    ),
                    child: Text(
                      genre,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Search suggestions
          Text(
            'اقتراحات البحث',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.suggestedSearches.map((suggestion) {
              return GestureDetector(
                onTap: () {
                  controller.onSearchChanged(suggestion);
                  controller.performSearch(suggestion);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.shimmerHighlight),
                  ),
                  child: Text(
                    suggestion,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Quick browse links
          Text(
            'استكشف',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildExploreCard(
                  title: 'كل الأفلام',
                  icon: Icons.movie,
                  color: AppTheme.primaryColor,
                  onTap: () => Get.toNamed(
                    AppRoutes.browseAll,
                    arguments: {'type': BrowseContentType.movies},
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildExploreCard(
                  title: 'كل المسلسلات',
                  icon: Icons.tv,
                  color: const Color(0xFF7C4DFF),
                  onTap: () => Get.toNamed(
                    AppRoutes.browseAll,
                    arguments: {'type': BrowseContentType.tvShows},
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildExploreCard(
                  title: 'أحدث الحلقات',
                  icon: Icons.playlist_play,
                  color: const Color(0xFFFF6D00),
                  onTap: () => Get.toNamed(
                    AppRoutes.browseAll,
                    arguments: {'type': BrowseContentType.episodes},
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExploreCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 80, color: AppTheme.textTertiary),
          const SizedBox(height: 16),
          Text(
            'مفيش نتائج',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جرب كلمة بحث تانية',
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      children: [
        // Genre filter chips (when searching)
        if (controller.selectedGenre.value.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Chip(
                  label: Text(controller.selectedGenre.value),
                  backgroundColor: AppTheme.primaryColor,
                  labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                  onDeleted: () => controller.filterByGenre(controller.selectedGenre.value),
                  deleteIconColor: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  '${controller.searchResults.length} نتيجة',
                  style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.searchResults.length,
            itemBuilder: (context, index) {
              final movie = controller.searchResults[index];
              return _SearchResultCard(movie: movie);
            },
          ),
        ),
      ],
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Movie movie;

  const _SearchResultCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (movie.isEpisode) {
          Get.toNamed(
            AppRoutes.player,
            arguments: {
              'movie': movie,
              'season': movie.seasonNumber ?? 1,
              'episode': movie.episodeNumber ?? 1,
            },
          );
        } else {
          Get.toNamed(
            AppRoutes.movieDetail,
            arguments: {'movie': movie},
          );
        }
      },
      child: Container(
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
                imageUrl: movie.posterUrl ?? '',
                width: 80,
                height: 120,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 80,
                  height: 120,
                  color: AppTheme.shimmerBase,
                  child: const Icon(Icons.movie, color: AppTheme.textTertiary),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 80,
                  height: 120,
                  color: AppTheme.shimmerBase,
                  child: const Icon(Icons.broken_image, color: AppTheme.textTertiary),
                ),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.displayTitle,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (movie.rating != null) ...[
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            movie.ratingDisplay,
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Text(
                          movie.isEpisode ? movie.seasonEpisodeDisplay : movie.yearDisplay,
                          style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
                        ),
                        if (movie.isEpisode || movie.isTV) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: movie.isEpisode ? const Color(0xFFFF6D00) : AppTheme.accentColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              movie.isEpisode ? 'حلقة' : 'مسلسل',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (movie.genresDisplay.isNotEmpty)
                      Text(
                        movie.genresDisplay,
                        style: TextStyle(color: AppTheme.textTertiary, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),

            // Play button
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withOpacity(0.15),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
