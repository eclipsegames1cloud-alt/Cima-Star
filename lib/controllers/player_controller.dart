import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/movie_model.dart';
import '../services/storage_service.dart';
import '../services/cache_service.dart';
import '../utils/constants.dart';

class PlayerController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();
  final CacheService _cacheService = Get.find<CacheService>();

  late WebViewController webViewController;
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt currentPosition = 0.obs;
  final RxInt currentDuration = 0.obs;  // total duration in seconds (from postMessage)
  final RxInt currentSeason = 1.obs;
  final RxInt currentEpisode = 1.obs;
  final RxBool isFullscreen = false.obs;
  final RxBool showResumeOption = false.obs;
  final RxInt resumePosition = 0.obs;
  final RxBool isPlaying = false.obs;

  Movie? _currentMovie;
  late String _currentUrl;

  /// Initialize player with movie data
  void initPlayer(Movie movie, {int? season, int? episode}) async {
    _currentMovie = movie;

    int? savedProgress;
    try {
      savedProgress = await _cacheService.getWatchProgress(movie.uniqueId);
    } catch (_) {}

    if (savedProgress != null && savedProgress > 0) {
      showResumeOption.value = true;
      resumePosition.value = savedProgress;
    }

    final history = _storageService.getWatchHistory(movie.uniqueId);
    if (history != null) {
      currentSeason.value = history['season'] as int? ?? 1;
      currentEpisode.value = history['episode'] as int? ?? 1;
    } else {
      // For episode-type content, use the episode's own season/episode numbers
      if (movie.isEpisode) {
        currentSeason.value = season ?? movie.seasonNumber ?? 1;
        currentEpisode.value = episode ?? movie.episodeNumber ?? 1;
      } else {
        currentSeason.value = season ?? 1;
        currentEpisode.value = episode ?? 1;
      }
    }

    _setupWebView(movie);
  }

  /// Resume from saved position
  void resumeFromSavedPosition() {
    showResumeOption.value = false;
    if (_currentMovie != null) {
      _loadPlayerWithResume(_currentMovie!, resumePosition.value);
    }
  }

  /// Start from beginning
  void playFromBeginning() {
    showResumeOption.value = false;
    if (_currentMovie != null) {
      _setupWebView(_currentMovie!);
    }
  }

  void _loadPlayerWithResume(Movie movie, int secondsPosition) {
    String url = movie.getPlayerUrl(
      isTV: movie.isTV || movie.isEpisode,
      season: currentSeason.value,
      episode: currentEpisode.value,
    );
    if (!url.contains('resumeAt')) {
      final separator = url.contains('?') ? '&' : '?';
      url = '${url}${separator}resumeAt=$secondsPosition';
    }
    _currentUrl = url;
    webViewController.loadRequest(Uri.parse(url));
  }

  /// Setup WebView with navigation delegate and enhanced features
  /// Uses postMessage via JavaScript channel instead of JS polling
  void _setupWebView(Movie movie) {
    String url = movie.getPlayerUrl(
      isTV: movie.isTV || movie.isEpisode,
      season: currentSeason.value,
      episode: currentEpisode.value,
    );
    if (url.isEmpty) url = _buildFallbackUrl(movie);
    _currentUrl = url;

    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setJavaScriptChannels({
        JavaScriptChannel(
          name: 'CimaStarPlayer',
          onMessageReceived: (message) {
            _handlePlayerMessage(message.message);
          },
        ),
      })
      ..setMediaPlaybackRequiresUserGesture(false)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          isLoading.value = true;
          hasError.value = false;
        },
        onPageFinished: (url) {
          isLoading.value = false;
          _injectProgressTracking();
        },
        onWebResourceError: (error) {
          isLoading.value = false;
          hasError.value = true;
          errorMessage.value = 'خطأ في تحميل الفيديو: ${error.description}';
        },
        onNavigationRequest: (request) {
          if (_isBlockedUrl(request.url)) return NavigationDecision.prevent;
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(url));
  }

  /// Handle incoming postMessage from the WebView JavaScript channel
  void _handlePlayerMessage(String msg) {
    if (msg.startsWith('progress:')) {
      final seconds = int.tryParse(msg.replaceFirst('progress:', ''));
      if (seconds != null) updatePlaybackPosition(seconds);
    } else if (msg.startsWith('duration:')) {
      final dur = int.tryParse(msg.replaceFirst('duration:', ''));
      if (dur != null && dur > 0) {
        currentDuration.value = dur;
      }
    } else if (msg.startsWith('playing:')) {
      final playing = msg.replaceFirst('playing:', '') == 'true';
      isPlaying.value = playing;
    } else if (msg.startsWith('finished:')) {
      // Episode finished — auto-advance if TV or Episode
      if (_currentMovie?.isTV == true || _currentMovie?.isEpisode == true) {
        final nextEp = currentEpisode.value + 1;
        final maxEp = _currentMovie!.getEpisodesInSeason(currentSeason.value);
        final totalSeasons = _currentMovie!.seasons ?? 1;
        if (nextEp > maxEp) {
          final nextSeason = currentSeason.value + 1;
          if (nextSeason <= totalSeasons) changeEpisode(nextSeason, 1);
        } else {
          changeEpisode(currentSeason.value, nextEp);
        }
      }
    }
  }

  String _buildFallbackUrl(Movie movie) {
    final imdbId = movie.imdbId ?? '';
    final tmdbId = movie.tmdbId ?? '';
    final isTVContent = movie.isTV || movie.isEpisode;
    if (isTVContent) {
      final s = currentSeason.value;
      final e = currentEpisode.value;
      if (imdbId.isNotEmpty) return '${AppConstants.vaPlayerBaseUrl}/tv/$imdbId/$s/$e';
      if (tmdbId.isNotEmpty) return '${AppConstants.vaPlayerBaseUrl}/tv/$tmdbId/$s/$e';
    } else {
      if (imdbId.isNotEmpty) return '${AppConstants.vaPlayerBaseUrl}/movie/$imdbId';
      if (tmdbId.isNotEmpty) return '${AppConstants.vaPlayerBaseUrl}/movie/$tmdbId';
    }
    return '';
  }

  /// Inject JavaScript for progress tracking via CimaStarPlayer postMessage channel.
  /// This replaces the old JavaScript polling approach – the WebView pushes updates
  /// to Flutter instead of Flutter polling the WebView every second.
  void _injectProgressTracking() async {
    try {
      await webViewController.runJavaScript('''
        (function() {
          const video = document.querySelector('video');
          if (video) {
            let lastSaved = 0;

            // Send progress every 5 seconds of playback change
            video.addEventListener('timeupdate', function() {
              if (Math.abs(video.currentTime - lastSaved) > 5) {
                lastSaved = Math.floor(video.currentTime);
                if (window.CimaStarPlayer) {
                  window.CimaStarPlayer.postMessage('progress:' + lastSaved);
                }
              }
            });

            // Send duration once when metadata is loaded
            video.addEventListener('loadedmetadata', function() {
              if (window.CimaStarPlayer && video.duration && isFinite(video.duration)) {
                window.CimaStarPlayer.postMessage('duration:' + Math.floor(video.duration));
              }
            });

            // Send playing/paused state
            video.addEventListener('play', function() {
              if (window.CimaStarPlayer) {
                window.CimaStarPlayer.postMessage('playing:true');
              }
            });
            video.addEventListener('pause', function() {
              if (window.CimaStarPlayer) {
                window.CimaStarPlayer.postMessage('playing:false');
              }
            });

            // Send duration again on duration change (e.g. quality switch)
            video.addEventListener('durationchange', function() {
              if (window.CimaStarPlayer && video.duration && isFinite(video.duration)) {
                window.CimaStarPlayer.postMessage('duration:' + Math.floor(video.duration));
              }
            });

            // Episode finished
            video.addEventListener('ended', function() {
              if (window.CimaStarPlayer) {
                window.CimaStarPlayer.postMessage('finished:true');
              }
            });

            // Emit initial duration if already available
            if (video.duration && isFinite(video.duration)) {
              window.CimaStarPlayer.postMessage('duration:' + Math.floor(video.duration));
            }
          }
        })();
      ''');
    } catch (_) {}
  }

  bool _isBlockedUrl(String url) {
    final lower = url.toLowerCase();
    return AppConstants.blockedDomains.any((domain) => lower.contains(domain));
  }

  void changeEpisode(int season, int episode) {
    currentSeason.value = season;
    currentEpisode.value = episode;
    currentPosition.value = 0;
    currentDuration.value = 0;
    if (_currentMovie != null) _setupWebView(_currentMovie!);
  }

  Future<void> saveProgress() async {
    if (_currentMovie == null) return;
    try {
      if (currentPosition.value > 0) {
        await _cacheService.saveWatchProgress(
            _currentMovie!.uniqueId, currentPosition.value);
      }
      await _storageService.saveWatchHistory(
        movie: _currentMovie!,
        position: currentPosition.value,
        season: currentSeason.value,
        episode: currentEpisode.value,
      );
    } catch (_) {}
  }

  /// Update current playback position (called from postMessage channel)
  void updatePlaybackPosition(int seconds) {
    currentPosition.value = seconds;
    saveProgress();
  }

  void toggleFullscreen() {
    isFullscreen.value = !isFullscreen.value;
  }

  void reload() {
    hasError.value = false;
    errorMessage.value = '';
    currentPosition.value = 0;
    currentDuration.value = 0;
    if (_currentMovie != null) _setupWebView(_currentMovie!);
  }

  String getPlayerUrl() => _currentUrl;

  @override
  void onClose() {
    saveProgress();
    super.onClose();
  }
}
