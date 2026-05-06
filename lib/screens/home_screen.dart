import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';
import '../config/app_routes.dart';
import '../controllers/home_controller.dart';
import '../controllers/browse_controller.dart';
import '../controllers/watchlist_controller.dart';
import '../models/movie_model.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_carousel.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/error_widget.dart' as custom;

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Obx(() {
        if (controller.isLoading.value && controller.latestMovies.isEmpty) {
          return const ShimmerHomeLoading();
        }

        if (controller.errorMessage.value.isNotEmpty && controller.latestMovies.isEmpty) {
          return custom.AppErrorWidget(
            message: controller.errorMessage.value,
            onRetry: () => controller.refreshAll(),
          );
        }

        return RefreshIndicator(
          color: AppTheme.primaryColor,
          backgroundColor: AppTheme.surfaceColor,
          onRefresh: () => controller.refreshAll(),
          child: CustomScrollView(
            slivers: [
              // Custom App Bar
              SliverAppBar(
                floating: true,
                pinned: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                expandedHeight: 60,
                flexibleSpace: _buildAppBar(),
              ),

              // Hero / Featured Section
              SliverToBoxAdapter(
                child: _buildHeroSection(),
              ),

              // Continue Watching (if any)
              if (controller.continueWatching.isNotEmpty)
                SliverToBoxAdapter(
                  child: MovieCarousel(
                    title: 'كمّل مشاهدتك',
                    icon: Icons.play_circle_filled,
                    movies: controller.continueWatching,
                    onSeeAll: () => Get.toNamed(AppRoutes.watchlist),
                  ),
                ),

              // Trending
              if (controller.trendingMovies.isNotEmpty)
                SliverToBoxAdapter(
                  child: MovieCarousel(
                    title: 'الأكثر رواجًا 🔥',
                    icon: Icons.trending_up,
                    movies: controller.trendingMovies,
                    accentColor: AppTheme.primaryColor,
                  ),
                ),

              // Popular
              if (controller.popularMovies.isNotEmpty)
                SliverToBoxAdapter(
                  child: MovieCarousel(
                    title: 'الأشهر',
                    icon: Icons.star,
                    movies: controller.popularMovies,
                    accentColor: AppTheme.accentColor,
                  ),
                ),

              // Latest Movies with See All
              SliverToBoxAdapter(
                child: MovieCarousel(
                  title: 'أحدث الأفلام',
                  icon: Icons.movie,
                  movies: controller.latestMovies,
                  accentColor: AppTheme.primaryColor,
                  onSeeAll: () => Get.toNamed(
                    AppRoutes.browseAll,
                    arguments: {'type': BrowseContentType.movies},
                  ),
                ),
              ),

              // TV Shows with See All
              SliverToBoxAdapter(
                child: MovieCarousel(
                  title: 'مسلسلات',
                  icon: Icons.tv,
                  movies: controller.tvShows,
                  accentColor: const Color(0xFF7C4DFF),
                  onSeeAll: () => Get.toNamed(
                    AppRoutes.browseAll,
                    arguments: {'type': BrowseContentType.tvShows},
                  ),
                ),
              ),

              // Latest Episodes with See All
              SliverToBoxAdapter(
                child: MovieCarousel(
                  title: 'أحدث الحلقات',
                  icon: Icons.playlist_play,
                  movies: controller.episodes,
                  accentColor: const Color(0xFFFF6D00),
                  onSeeAll: () => Get.toNamed(
                    AppRoutes.browseAll,
                    arguments: {'type': BrowseContentType.episodes},
                  ),
                ),
              ),

              // Quick Access: Browse All Buttons
              SliverToBoxAdapter(
                child: _buildQuickAccessSection(),
              ),

              // Bottom padding for navigation bar
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        );
      }),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildAppBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.movie, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.primaryGradient.createShader(bounds),
                  child: const Text(
                    'CIMA STAR',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),

            // Action buttons
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.search, color: AppTheme.textPrimary, size: 26),
                  onPressed: () => Get.toNamed(AppRoutes.search),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_none, color: AppTheme.textPrimary, size: 26),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    if (controller.trendingMovies.isEmpty && controller.latestMovies.isEmpty) {
      return const SizedBox.shrink();
    }

    final featured = controller.trendingMovies.isNotEmpty
        ? controller.trendingMovies.first
        : controller.latestMovies.first;

    return GestureDetector(
      onTap: () => Get.toNamed(
        AppRoutes.movieDetail,
        arguments: {'movie': featured},
      ),
      child: Container(
        height: 450,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Backdrop Image
            CachedNetworkImage(
              imageUrl: featured.posterUrl ?? '',
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppTheme.surfaceColor),
              errorWidget: (_, __, ___) => Container(
                color: AppTheme.surfaceColor,
                child: const Icon(Icons.movie, size: 60, color: AppTheme.textTertiary),
              ),
            ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    AppTheme.backgroundColor,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Movie Info
            Positioned(
              left: 20,
              right: 20,
              bottom: 30,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trending badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_up, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'رائج الآن',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    featured.displayTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Meta info
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        featured.ratingDisplay,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        featured.yearDisplay,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      ),
                      if (featured.genresDisplay.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        Flexible(
                          child: Text(
                            featured.genresDisplay,
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Get.toNamed(
                          AppRoutes.player,
                          arguments: {'movie': featured},
                        ),
                        icon: const Icon(Icons.play_arrow, size: 20),
                        label: const Text('شاهد الآن'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GetBuilder<WatchlistController>(
                        builder: (wc) => OutlinedButton.icon(
                          onPressed: () => wc.toggleFavorite(featured),
                          icon: Icon(
                            wc.isFavorite(featured.uniqueId)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 20,
                            color: wc.isFavorite(featured.uniqueId)
                                ? AppTheme.primaryColor
                                : AppTheme.accentColor,
                          ),
                          label: Text(
                            wc.isFavorite(featured.uniqueId) ? 'محفوظ' : 'حفظ',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Quick access section with big browse buttons
  Widget _buildQuickAccessSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.explore, color: AppTheme.accentColor, size: 22),
              const SizedBox(width: 8),
              const Text(
                'استكشف المزيد',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickAccessCard(
                  title: 'الأفلام',
                  subtitle: '89K+ فيلم',
                  icon: Icons.movie,
                  color: AppTheme.primaryColor,
                  onTap: () => Get.toNamed(
                    AppRoutes.browseAll,
                    arguments: {'type': BrowseContentType.movies},
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAccessCard(
                  title: 'المسلسلات',
                  subtitle: '19K+ مسلسل',
                  icon: Icons.tv,
                  color: const Color(0xFF7C4DFF),
                  onTap: () => Get.toNamed(
                    AppRoutes.browseAll,
                    arguments: {'type': BrowseContentType.tvShows},
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAccessCard(
                  title: 'الحلقات',
                  subtitle: '460K+ حلقة',
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

  Widget _buildQuickAccessCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, 'الرئيسية', 0, AppRoutes.home),
              _navItem(Icons.search_rounded, 'بحث', 1, AppRoutes.search),
              _navItem(Icons.favorite_rounded, 'المفضلة', 2, AppRoutes.watchlist),
              _navItem(Icons.download_rounded, 'التحميلات', 3, AppRoutes.downloads),
              _navItem(Icons.settings_rounded, 'الإعدادات', 4, AppRoutes.settings),
            ],
          )),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index, String route) {
    final isSelected = controller.currentTabIndex.value == index;
    return GestureDetector(
      onTap: () {
        controller.changeTab(index);
        if (route != AppRoutes.home) {
          Get.toNamed(route);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textTertiary,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
