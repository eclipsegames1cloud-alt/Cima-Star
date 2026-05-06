import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/app_theme.dart';
import '../controllers/player_controller.dart';
import '../models/movie_model.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({Key? key}) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late PlayerController controller;
  late Movie movie;

  bool _showControls = true;
  bool _isLocked = false;
  Timer? _hideTimer;

  double _volume = 0.5;
  double _brightness = 0.5;
  bool _showVolumeIndicator = false;
  bool _showBrightnessIndicator = false;
  Timer? _indicatorTimer;

  @override
  void initState() {
    super.initState();
    controller = Get.find<PlayerController>();
    movie = Get.arguments?['movie'] as Movie;
    final int? season = Get.arguments?['season'] as int?;
    final int? episode = Get.arguments?['episode'] as int?;
    controller.initPlayer(movie, season: season, episode: episode);
    _scheduleHide();
    // No more JS polling – progress & duration come via postMessage channel
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !_isLocked) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    if (_isLocked) return;
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHide();
  }

  void _seekForward() {
    controller.webViewController.runJavaScript(
        'var v=document.querySelector("video");if(v)v.currentTime=Math.min(v.currentTime+10,v.duration);');
    _showSeekToast('⏩ +10 ثانية');
  }

  void _seekBackward() {
    controller.webViewController.runJavaScript(
        'var v=document.querySelector("video");if(v)v.currentTime=Math.max(v.currentTime-10,0);');
    _showSeekToast('⏪ -10 ثانية');
  }

  void _togglePlayPause() {
    controller.webViewController.runJavaScript(
        'var v=document.querySelector("video");if(v){if(v.paused)v.play();else v.pause();}');
  }

  void _showSeekToast(String text) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text, textAlign: TextAlign.center),
      duration: const Duration(milliseconds: 700),
      backgroundColor: Colors.black54,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _handleVerticalSwipe(double delta, bool isRightSide) {
    final change = -delta / 300.0;
    _indicatorTimer?.cancel();
    if (isRightSide) {
      _volume = (_volume + change).clamp(0.0, 1.0);
      controller.webViewController.runJavaScript(
          'var v=document.querySelector("video");if(v)v.volume=${_volume.toStringAsFixed(2)};');
      setState(() => _showVolumeIndicator = true);
    } else {
      _brightness = (_brightness + change).clamp(0.0, 1.0);
      setState(() => _showBrightnessIndicator = true);
    }
    _indicatorTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() { _showVolumeIndicator = false; _showBrightnessIndicator = false; });
    });
  }

  Future<void> _handleDownload() async {
    try {
      final result = await controller.webViewController
          .runJavaScriptReturningResult(
              'document.querySelector("video")?.src ?? ""');
      final videoUrl = result.toString().replaceAll('"', '').trim();

      if (videoUrl.isNotEmpty && videoUrl.startsWith('http')) {
        final idmUri = Uri.parse('idm:$videoUrl');
        if (await canLaunchUrl(idmUri)) {
          await launchUrl(idmUri);
          return;
        }
        final webUri = Uri.parse(videoUrl);
        if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
          return;
        }
        _showDownloadDialog(
          'لم يتم العثور على 1DM',
          'يُرجى تثبيت تطبيق 1DM (IDM for Android) لتحميل الفيديو.',
          showInstall: true,
        );
      } else {
        _showDownloadDialog(
          'تعذّر اكتشاف رابط التحميل',
          'لم نتمكن من الحصول على رابط الفيديو المباشر.\nقد يكون الفيديو محمياً أو لم يبدأ بعد.',
          showInstall: false,
        );
      }
    } catch (_) {
      _showDownloadDialog(
        'تعذّر اكتشاف رابط التحميل',
        'حدث خطأ أثناء محاولة الحصول على رابط الفيديو.\nحاول مرة أخرى بعد بدء تشغيل الفيديو.',
        showInstall: false,
      );
    }
  }

  void _showDownloadDialog(String title, String message, {required bool showInstall}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(message, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        actions: [
          if (showInstall)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final uri = Uri.parse('https://play.google.com/store/apps/details?id=idm.internet.download.manager');
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
              child: const Text('تثبيت 1DM', style: TextStyle(color: AppTheme.primaryColor)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  Future<void> _enterPiP() async {
    try {
      const channel = MethodChannel('com.cimastar.app/pip');
      await channel.invokeMethod('enterPiP');
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('وضع Picture-in-Picture غير متاح على هذا الجهاز'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.black54,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _indicatorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        if (controller.hasError.value) return _buildErrorState();
        return _buildPlayerWithGestures();
      }),
    );
  }

  Widget _buildPlayerWithGestures() {
    final screenW = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        Positioned.fill(child: WebViewWidget(controller: controller.webViewController)),

        if (controller.isLoading.value)
          Container(
            color: Colors.black87,
            child: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const CircularProgressIndicator(color: AppTheme.primaryColor),
                const SizedBox(height: 16),
                Text('جاري تحميل الفيديو...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              ]),
            ),
          ),

        if (_isLocked) _buildLockedOverlay(),

        if (!_isLocked)
          Positioned.fill(child: _buildGestureLayer(screenW)),

        if (_showVolumeIndicator) _buildSideIndicator(Icons.volume_up, _volume, true),
        if (_showBrightnessIndicator) _buildSideIndicator(Icons.brightness_6, _brightness, false),

        if (controller.showResumeOption.value) _buildResumeDialog(),
      ],
    );
  }

  Widget _buildLockedOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {}),
        child: Container(
          color: Colors.transparent,
          child: SafeArea(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: _buildLockButton(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGestureLayer(double screenW) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _toggleControls,
      onDoubleTapDown: (details) {
        if (details.globalPosition.dx > screenW / 2) _seekForward();
        else _seekBackward();
      },
      onDoubleTap: () {},
      onVerticalDragUpdate: (details) {
        _handleVerticalSwipe(details.delta.dy, details.globalPosition.dx > screenW / 2);
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: _showControls ? 1.0 : 0.0,
        child: IgnorePointer(
          ignoring: !_showControls,
          child: _buildControlsOverlay(),
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Stack(
      children: [
        Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),
        Center(child: _buildCenterControls()),
        Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomBar()),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8, right: 8, bottom: 12,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black87, Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(movie.displayTitle,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (movie.isTV || movie.isEpisode)
                  Obx(() => Text(
                    'الموسم ${controller.currentSeason.value} - الحلقة ${controller.currentEpisode.value}',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  )),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.picture_in_picture_alt, color: Colors.white),
            tooltip: 'Picture in Picture',
            onPressed: _enterPiP,
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            tooltip: 'تحميل عبر 1DM',
            onPressed: _handleDownload,
          ),
          _buildLockButton(),
        ],
      ),
    );
  }

  Widget _buildLockButton() {
    return IconButton(
      icon: Icon(_isLocked ? Icons.lock : Icons.lock_open,
          color: _isLocked ? AppTheme.primaryColor : Colors.white),
      tooltip: _isLocked ? 'فتح القفل' : 'قفل الشاشة',
      onPressed: () {
        setState(() {
          _isLocked = !_isLocked;
          if (!_isLocked) _showControls = true;
        });
        if (!_isLocked) _scheduleHide();
      },
    );
  }

  Widget _buildCenterControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onDoubleTap: _seekBackward,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
            child: const Icon(Icons.replay_10, color: Colors.white70, size: 28),
          ),
        ),
        const SizedBox(width: 24),
        GestureDetector(
          onTap: _togglePlayPause,
          child: Obx(() => Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
            child: Icon(
              controller.isPlaying.value ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 36,
            ),
          )),
        ),
        const SizedBox(width: 24),
        GestureDetector(
          onDoubleTap: _seekForward,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
            child: const Icon(Icons.forward_10, color: Colors.white70, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        left: 12, right: 12, top: 12,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black87],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildProgressBar(),
          if (movie.isTV || movie.isEpisode) ...[const SizedBox(height: 4), _buildEpisodeNavigation()],
        ],
      ),
    );
  }

  /// Progress bar driven by postMessage data (no JS polling)
  Widget _buildProgressBar() {
    return Obx(() {
      final elapsed = controller.currentPosition.value;
      final total = controller.currentDuration.value;
      final progress = total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 0.0;

      String fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

      return Row(
        children: [
          Text(fmt(elapsed), style: const TextStyle(color: Colors.white70, fontSize: 11)),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: AppTheme.primaryColor,
                inactiveTrackColor: Colors.white24,
                thumbColor: AppTheme.primaryColor,
              ),
              child: Slider(
                value: progress,
                onChanged: (val) async {
                  final seekTo = (val * total).toInt();
                  await controller.webViewController.runJavaScript(
                      'var v=document.querySelector("video");if(v)v.currentTime=$seekTo;');
                },
              ),
            ),
          ),
          Text(fmt(total), style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      );
    });
  }

  Widget _buildEpisodeNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous, color: Colors.white),
          onPressed: () {
            if (controller.currentEpisode.value > 1) {
              controller.changeEpisode(controller.currentSeason.value, controller.currentEpisode.value - 1);
            }
          },
        ),
        Obx(() => Text(
          'S${controller.currentSeason.value.toString().padLeft(2, '0')}E${controller.currentEpisode.value.toString().padLeft(2, '0')}',
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        )),
        IconButton(
          icon: const Icon(Icons.skip_next, color: Colors.white),
          onPressed: () {
            final maxEpisodes = movie.getEpisodesInSeason(controller.currentSeason.value);
            final totalSeasons = movie.seasons ?? 1;
            final nextEp = controller.currentEpisode.value + 1;
            if (nextEp > maxEpisodes) {
              final nextSeason = controller.currentSeason.value + 1;
              if (nextSeason <= totalSeasons) controller.changeEpisode(nextSeason, 1);
            } else {
              controller.changeEpisode(controller.currentSeason.value, nextEp);
            }
          },
        ),
      ],
    );
  }

  Widget _buildSideIndicator(IconData icon, double value, bool isRight) {
    return Positioned(
      top: 0, bottom: 0,
      right: isRight ? 24 : null,
      left: isRight ? null : 24,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 8),
              SizedBox(
                height: 100, width: 6,
                child: RotatedBox(
                  quarterTurns: -1,
                  child: LinearProgressIndicator(
                    value: value,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('${(value * 100).round()}%', style: const TextStyle(color: Colors.white, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumeDialog() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('استمر من حيث توقفت؟',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Obx(() => Text(
                  'تم الحفظ عند ${controller.resumePosition.value ~/ 60}:${(controller.resumePosition.value % 60).toString().padLeft(2, '0')}',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                )),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: controller.playFromBeginning,
                      child: const Text('من البداية', style: TextStyle(color: Colors.white54)),
                    ),
                    ElevatedButton(
                      onPressed: controller.resumeFromSavedPosition,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                      child: const Text('استمر'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            const Text('خطأ في تحميل الفيديو',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Obx(() => Text(
              controller.errorMessage.value.isEmpty ? 'السيرفر نايم دلوقتي. حاول تاني!' : controller.errorMessage.value,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            )),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: controller.reload,
              icon: const Icon(Icons.refresh),
              label: const Text('حاول تاني'),
            ),
          ],
        ),
      ),
    );
  }
}
