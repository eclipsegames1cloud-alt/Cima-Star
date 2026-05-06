import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';
import '../config/app_routes.dart';
import '../controllers/watchlist_controller.dart';
import '../controllers/download_controller.dart';
import '../models/movie_model.dart';
import '../widgets/rating_badge.dart';
import '../widgets/glassmorphism_card.dart';

class MovieDetailScreen extends StatelessWidget {
  const MovieDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Movie movie = Get.arguments?['movie'] as Movie;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.share, color: Colors.white),
            ),
            onPressed: () {
              final shareText = movie.displayTitle + ' (' + (movie.yearDisplay) + ')\n'
                  + (movie.isTV ? 'مسلسل' : movie.isEpisode ? 'حلقة' : 'فيلم') + ' - تقييم: ' + movie.ratingDisplay + '\n'
                  + (movie.description ?? '') + '\n\n'
                  + 'شاهده الآن على CimaStar';
              Share.share(shareText, subject: movie.displayTitle);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Backdrop / Poster
            _buildBackdrop(movie),

            // Movie Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Title & Rating Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          movie.displayTitle,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (movie.rating != null)
                        RatingBadge(rating: movie.rating!),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Meta info chips
                  _buildMetaChips(movie),
                  const SizedBox(height: 20),

                  // Action buttons
                  _buildActionButtons(movie),
                  const SizedBox(height: 24),

                  // Description
                  if (movie.description != null) ...[
                    const Text(
                      'القصة',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      movie.description!,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Movie Details
                  GlassmorphismCard(
                    child: Column(
                      children: [
                        if (movie.director != null)
                          _detailRow('المخرج', movie.director!),
                        if (movie.durationDisplay.isNotEmpty)
                          _detailRow('المدة', movie.durationDisplay),
                        if (movie.countries?.isNotEmpty == true)
                          _detailRow('البلد', movie.countries!.join(', ')),
                        if (movie.votes != null)
                          _detailRow('عدد التقييمات', movie.votes!.toString()),
                        if (movie.popularity != null)
                          _detailRow('الشعبية', movie.popularity!.toStringAsFixed(1)),
                        if (movie.imdbId != null)
                          _detailRow('IMDB', movie.imdbId!),
                        if (movie.tmdbId != null)
                          _detailRow('TMDB', movie.tmdbId!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Season & Episode selector for TV shows
                  if (movie.isTV) ...[
                    _buildSeasonEpisodeSelector(movie),
                    const SizedBox(height: 24),
                  ],

                  // Episode info for episode items
                  if (movie.isEpisode) ...[
                    _buildEpisodeInfo(movie),
                    const SizedBox(height: 24),
                  ],

                  // Cast
                  if (movie.cast?.isNotEmpty == true) ...[
                    const Text(
                      'طاقم التمثيل',
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
                      children: movie.cast!.map((actor) {
                        return Chip(
                          label: Text(actor),
                          backgroundColor: AppTheme.surfaceColor,
                          labelStyle: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackdrop(Movie movie) {
    return SizedBox(
      height: 350,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: movie.posterUrl ?? '',
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: AppTheme.surfaceColor),
            errorWidget: (_, __, ___) => Container(
              color: AppTheme.surfaceColor,
              child: const Icon(Icons.movie, size: 60, color: AppTheme.textTertiary),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.backgroundColor.withOpacity(0.8),
                  AppTheme.backgroundColor,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),

          // Play button overlay
          Center(
            child: GestureDetector(
              onTap: () => Get.toNamed(
                AppRoutes.player,
                arguments: {
                  'movie': movie,
                  if (movie.isEpisode || movie.isTV) ...{
                    'season': movie.seasonNumber ?? 1,
                    'episode': movie.episodeNumber ?? 1,
                  },
                },
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChips(Movie movie) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(Icons.calendar_today, movie.yearDisplay),
        if (movie.durationDisplay.isNotEmpty)
          _chip(Icons.access_time, movie.durationDisplay),
        if (movie.isEpisode)
          _chip(Icons.tv, movie.seasonEpisodeDisplay)
        else
          _chip(movie.isTV ? Icons.tv : Icons.movie,
              movie.isTV ? 'مسلسل' : 'فيلم'),
        ...?movie.genres?.map((g) => _chip(Icons.label, g)),
      ],
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Movie movie) {
    return Row(
      children: [
        // Play button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Get.toNamed(
              AppRoutes.player,
              arguments: {
                'movie': movie,
                if (movie.isEpisode || movie.isTV) ...{
                  'season': movie.seasonNumber ?? 1,
                  'episode': movie.episodeNumber ?? 1,
                },
              },
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('شاهد الآن', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Watchlist button
        GetBuilder<WatchlistController>(
          builder: (wc) => Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: wc.isFavorite(movie.uniqueId)
                    ? AppTheme.primaryColor
                    : AppTheme.shimmerHighlight,
              ),
            ),
            child: IconButton(
              icon: Icon(
                wc.isFavorite(movie.uniqueId)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: wc.isFavorite(movie.uniqueId)
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
              ),
              onPressed: () => wc.toggleFavorite(movie),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Download button
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.shimmerHighlight),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.download,
              color: AppTheme.textSecondary,
            ),
            onPressed: () {
              final videoUrl = movie.embedUrl ?? movie.getPlayerUrl(isTV: movie.isTV || movie.isEpisode);
              if (videoUrl.isNotEmpty) {
                Get.find<DownloadController>().startDownload(
                  movie,
                  videoUrl,
                );
              } else {
                Get.snackbar(
                  'خطأ',
                  'لا يوجد رابط تنزيل متاح.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Build episode-specific info section
  Widget _buildEpisodeInfo(Movie movie) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'معلومات الحلقة',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GlassmorphismCard(
          child: Column(
            children: [
              if (movie.showTitle != null)
                _detailRow('المسلسل', movie.showTitle!),
              if (movie.seasonNumber != null)
                _detailRow('الموسم', movie.seasonNumber.toString()),
              if (movie.episodeNumber != null)
                _detailRow('الحلقة', movie.episodeNumber.toString()),
              if (movie.episodeTitle != null)
                _detailRow('عنوان الحلقة', movie.episodeTitle!),
              if (movie.airDate != null)
                _detailRow('تاريخ العرض', movie.airDate!),
              if (movie.showImdbId != null)
                _detailRow('IMDB المسلسل', movie.showImdbId!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSeasonEpisodeSelector(Movie movie) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'المواسم والحلقات',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _SeasonEpisodeGrid(movie: movie),
      ],
    );
  }
}

class _SeasonEpisodeGrid extends StatefulWidget {
  final Movie movie;
  const _SeasonEpisodeGrid({required this.movie});

  @override
  State<_SeasonEpisodeGrid> createState() => _SeasonEpisodeGridState();
}

class _SeasonEpisodeGridState extends State<_SeasonEpisodeGrid> {
  int selectedSeason = 1;

  @override
  Widget build(BuildContext context) {
    final seasons = widget.movie.seasons ?? 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Season tabs
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: seasons,
            itemBuilder: (_, index) {
              final season = index + 1;
              final isSelected = season == selectedSeason;
              return GestureDetector(
                onTap: () => setState(() => selectedSeason = season),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'الموسم $season',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Episode grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: 10, // Default 10 episodes per season
          itemBuilder: (_, index) {
            final episode = index + 1;
            return GestureDetector(
              onTap: () => Get.toNamed(
                AppRoutes.player,
                arguments: {
                  'movie': widget.movie,
                  'season': selectedSeason,
                  'episode': episode,
                },
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_circle_outline,
                        color: AppTheme.primaryColor, size: 20),
                    const SizedBox(height: 4),
                    Text(
                      '$episode',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
