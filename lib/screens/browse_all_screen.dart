import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';
import '../config/app_routes.dart';
import '../controllers/browse_controller.dart';
import '../models/movie_model.dart';
import '../widgets/shimmer_loading.dart';

class BrowseAllScreen extends StatelessWidget {
  const BrowseAllScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get content type from arguments
    final contentType = Get.arguments?['type'] as BrowseContentType? ?? BrowseContentType.movies;

    return GetBuilder<BrowseController>(
      init: BrowseController(),
      builder: (controller) {
        // Initialize controller with content type (only once)
        if (controller.contentType != contentType) {
          controller.initController(contentType);
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: CustomScrollView(
            slivers: [
              // App Bar with search
              SliverAppBar(
                floating: true,
                pinned: true,
                backgroundColor: AppTheme.surfaceColor,
                expandedHeight: 120,
                title: Text(
                  controller.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  child: _buildSearchBar(controller),
                ),
              ),

              // Stats bar
              SliverToBoxAdapter(
                child: _buildStatsBar(controller),
              ),

              // Content
              Obx(() {
                if (controller.isLoading.value && controller.items.isEmpty) {
                  return const SliverFillRemaining(
                    child: ShimmerGridLoading(),
                  );
                }

                if (controller.hasError.value && controller.items.isEmpty) {
                  return SliverFillRemaining(
                    child: _buildErrorState(controller),
                  );
                }

                final displayItems = controller.filteredItems;

                if (displayItems.isEmpty && controller.searchQuery.value.isNotEmpty) {
                  return SliverFillRemaining(
                    child: _buildNoResultsState(controller),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.48,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // Load more trigger
                        if (index >= displayItems.length - 6 && controller.hasMore.value) {
                          controller.loadMore();
                        }

                        final movie = displayItems[index];
                        return _BrowseMovieCard(movie: movie);
                      },
                      childCount: displayItems.length + (controller.hasMore.value ? 1 : 0),
                    ),
                  ),
                );
              }),

              // Loading more indicator
              Obx(() {
                if (controller.isLoadingMore.value) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryColor),
                      ),
                    ),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }),

              // End of list indicator
              Obx(() {
                if (!controller.hasMore.value && controller.items.isNotEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'وصلت لنهاية القائمة',
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 60),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(BrowseController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.shimmerHighlight),
        ),
        child: TextField(
          onChanged: controller.filterItems,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'ابحث في القائمة...',
            hintStyle: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor, size: 18),
            suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textTertiary, size: 16),
                    onPressed: controller.clearFilter,
                  )
                : const SizedBox.shrink()),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar(BrowseController controller) {
    return Obx(() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (controller.totalDisplay.isNotEmpty)
            Text(
              controller.totalDisplay,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            )
          else
            const SizedBox.shrink(),
          Text(
            'صفحة ${controller.currentPage.value} من ${controller.totalPages.value > 0 ? controller.totalPages.value : "?"}',
            style: TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildErrorState(BrowseController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            const Text('خطأ في تحميل البيانات',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage.value.isEmpty ? 'حاول تاني!' : controller.errorMessage.value,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: controller.refreshAll,
              icon: const Icon(Icons.refresh),
              label: const Text('حاول تاني'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(BrowseController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: AppTheme.textTertiary),
          const SizedBox(height: 16),
          Text(
            'مفيش نتائج لـ "${controller.searchQuery.value}"',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: controller.clearFilter,
            child: const Text('مسح البحث'),
          ),
        ],
      ),
    );
  }
}

/// Movie card for browse grid
class _BrowseMovieCard extends StatelessWidget {
  final Movie movie;
  const _BrowseMovieCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (movie.isEpisode) {
          // For episodes, navigate directly to player
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
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
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
                      const Icon(Icons.movie, color: AppTheme.textTertiary, size: 24),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          movie.shortDisplayTitle,
                          style: TextStyle(color: AppTheme.textTertiary, fontSize: 9),
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
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
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
                        movie.isEpisode ? (movie.episodeTitle ?? movie.shortDisplayTitle) : movie.shortDisplayTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (movie.rating != null) ...[
                            const Icon(Icons.star, color: Colors.amber, size: 9),
                            const SizedBox(width: 2),
                            Text(
                              movie.ratingDisplay,
                              style: const TextStyle(color: Colors.white70, fontSize: 8),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            movie.isEpisode ? movie.seasonEpisodeDisplay : movie.yearDisplay,
                            style: TextStyle(color: Colors.white60, fontSize: 8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Type badge
              if (movie.isTV || movie.isEpisode)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: movie.isEpisode ? const Color(0xFFFF6D00) : AppTheme.accentColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      movie.isEpisode ? 'EP' : 'TV',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // Play icon overlay
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 12,
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
