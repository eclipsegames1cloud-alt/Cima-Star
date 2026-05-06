import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'api/multi_source_service.dart';

/// NotificationService – triggers native phone notifications for new content.
/// Works like a WhatsApp message: shows even when the app is in the background.
/// Only fires when an active internet connection is detected.
class NotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // IDs of content already seen so we don't re-notify
  static const _seenMoviesKey = 'notif_seen_movies';
  static const _seenShowsKey = 'notif_seen_shows';
  static const _seenEpisodesKey = 'notif_seen_episodes';

  Timer? _pollingTimer;

  // ─── Init ────────────────────────────────────────────────────────────────

  Future<NotificationService> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create high-importance Android channel
    const channel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDesc,
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Start background polling (every 30 minutes)
    _startPolling();

    return this;
  }

  // ─── Background Polling ──────────────────────────────────────────────────

  /// Starts in-app polling as a supplement to WorkManager background tasks.
  /// WorkManager (registered in main.dart) handles background checks when the app
  /// is closed. This timer handles the case where the app stays open for a long time.
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => checkForNewContent(),
    );
    // Run once immediately on app start (skip if offline – safe)
    checkForNewContent();
  }

  /// Main check: only runs when online. Compares latest API data against
  /// the list of IDs we already notified the user about.
  Future<void> checkForNewContent() async {
    final isOnline = await _hasActiveInternet();
    if (!isOnline) return; // Skip entirely when offline

    try {
      final api = Get.find<MultiSourceService>();
      final prefs = await SharedPreferences.getInstance();

      // ── New Movies ──────────────────────────────────────────────────────
      final seenMovies = prefs.getStringList(_seenMoviesKey) ?? [];
      final movies = await api.getLatestMovies();
      for (final movie in movies) {
        final id = movie.uniqueId;
        if (id.isNotEmpty && !seenMovies.contains(id)) {
          seenMovies.add(id);
          await showNewMovieNotification(
            title: '🎬 فيلم جديد!',
            body: movie.displayTitle,
            payload: id,
          );
          break; // one notification per poll to avoid spam
        }
      }
      await prefs.setStringList(_seenMoviesKey, seenMovies);

      // ── New TV Shows ────────────────────────────────────────────────────
      final seenShows = prefs.getStringList(_seenShowsKey) ?? [];
      final shows = await api.getLatestTVShows();
      for (final show in shows) {
        final id = show.uniqueId;
        if (id.isNotEmpty && !seenShows.contains(id)) {
          seenShows.add(id);
          await showNewMovieNotification(
            title: '📺 مسلسل جديد!',
            body: show.displayTitle,
            payload: id,
          );
          break;
        }
      }
      await prefs.setStringList(_seenShowsKey, seenShows);

      // ── New Episodes ────────────────────────────────────────────────────
      final seenEpisodes = prefs.getStringList(_seenEpisodesKey) ?? [];
      final episodes = await api.getLatestEpisodes();
      for (final ep in episodes) {
        final id = ep.uniqueId;
        if (id.isNotEmpty && !seenEpisodes.contains(id)) {
          seenEpisodes.add(id);
          await showNewMovieNotification(
            title: '🎞️ حلقة جديدة!',
            body: ep.displayTitle,
            payload: id,
          );
          break;
        }
      }
      await prefs.setStringList(_seenEpisodesKey, seenEpisodes);
    } catch (e) {
      // Silently fail – polling will retry next cycle
    }
  }

  // ─── Connectivity Check ──────────────────────────────────────────────────

  /// Returns true only when Wi-Fi or mobile data is active.
  Future<bool> _hasActiveInternet() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  // ─── Notification Helpers ─────────────────────────────────────────────────

  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      Get.toNamed('/movie-detail', arguments: {'movieId': response.payload});
    }
  }

  /// Show a native notification – call directly for manual triggers.
  Future<void> showNewMovieNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  /// Convenience wrapper for episode notifications.
  Future<void> showNewEpisodeNotification({
    required String showName,
    required int season,
    required int episode,
    String? payload,
  }) async {
    await showNewMovieNotification(
      title: '🎞️ حلقة جديدة!',
      body: '$showName - الموسم $season الحلقة $episode',
      payload: payload,
    );
  }

  /// Request notification permission (Android 13+).
  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return true;
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    super.onClose();
  }
}

