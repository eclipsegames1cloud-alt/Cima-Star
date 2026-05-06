import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/app_theme.dart';
import '../controllers/home_controller.dart';
import '../services/api/multi_source_service.dart';
import '../services/storage_service.dart';
import '../services/cache_service.dart';
import '../utils/helpers.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late StorageService _storageService;

  // Reactive settings values (initialized from StorageService)
  late String _videoQuality;
  late String _subtitleLang;
  late bool _autoPlayNext;
  late bool _notifyNewMovies;
  late bool _notifyNewEpisodes;

  @override
  void initState() {
    super.initState();
    _storageService = Get.find<StorageService>();
    _loadSettings();
  }

  void _loadSettings() {
    _videoQuality = _storageService.videoQuality;
    _subtitleLang = _storageService.subtitleLang;
    _autoPlayNext = _storageService.autoPlayNext;
    _notifyNewMovies = _storageService.notifyNewMovies;
    _notifyNewEpisodes = _storageService.notifyNewEpisodes;
  }

  String _qualityDisplay(String q) {
    switch (q) {
      case 'auto': return 'تلقائي';
      case '1080p': return '1080p';
      case '720p': return '720p';
      case '480p': return '480p';
      default: return q;
    }
  }

  String _langDisplay(String lang) {
    switch (lang) {
      case 'ar': return 'العربية';
      case 'en': return 'English';
      case 'none': return 'بدون ترجمة';
      default: return lang;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.settings, color: AppTheme.accentColor, size: 24),
            const SizedBox(width: 10),
            const Text('الإعدادات'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // API Source section
          _buildSectionTitle('مصدر البيانات'),
          _buildSourceSelector(),
          const SizedBox(height: 24),

          // Playback settings
          _buildSectionTitle('إعدادات المشاهدة'),
          _buildSettingsCard([
            _settingItem(
              icon: Icons.play_circle,
              title: 'جودة الفيديو',
              subtitle: _qualityDisplay(_videoQuality),
              onTap: () => _showQualityDialog(),
            ),
            _settingItem(
              icon: Icons.subtitles,
              title: 'الترجمة',
              subtitle: _langDisplay(_subtitleLang),
              onTap: () => _showSubtitleDialog(),
            ),
            _settingItem(
              icon: Icons.skip_next,
              title: 'التشغيل التلقائي للحلقة التالية',
              subtitle: _autoPlayNext ? 'مفعل' : 'معطل',
              isSwitch: true,
              switchValue: _autoPlayNext,
              onSwitchChanged: (v) async {
                await _storageService.setAutoPlayNext(v);
                setState(() => _autoPlayNext = v);
              },
            ),
          ]),
          const SizedBox(height: 24),

          // Notifications
          _buildSectionTitle('الإشعارات'),
          _buildSettingsCard([
            _settingItem(
              icon: Icons.notifications,
              title: 'إشعارات الأفلام الجديدة',
              subtitle: _notifyNewMovies ? 'مفعل' : 'معطل',
              isSwitch: true,
              switchValue: _notifyNewMovies,
              onSwitchChanged: (v) async {
                await _storageService.setNotifyNewMovies(v);
                setState(() => _notifyNewMovies = v);
              },
            ),
            _settingItem(
              icon: Icons.tv,
              title: 'إشعارات الحلقات الجديدة',
              subtitle: _notifyNewEpisodes ? 'مفعل' : 'معطل',
              isSwitch: true,
              switchValue: _notifyNewEpisodes,
              onSwitchChanged: (v) async {
                await _storageService.setNotifyNewEpisodes(v);
                setState(() => _notifyNewEpisodes = v);
              },
            ),
          ]),
          const SizedBox(height: 24),

          // Data & Storage
          _buildSectionTitle('البيانات والتخزين'),
          _buildSettingsCard([
            _settingItem(
              icon: Icons.cleaning_services,
              title: 'مسح ذاكرة التخزين المؤقت',
              subtitle: 'حذف البيانات المؤقتة',
              onTap: () => _clearCache(),
            ),
            _settingItem(
              icon: Icons.history,
              title: 'مسح سجل المشاهدة',
              subtitle: 'حذف كل سجل المشاهدة',
              onTap: () => _clearWatchHistory(),
            ),
          ]),
          const SizedBox(height: 24),

          // About
          _buildSectionTitle('عن التطبيق'),
          _buildSettingsCard([
            _settingItem(
              icon: Icons.info,
              title: 'الإصدار',
              subtitle: '3.0.0',
              showArrow: false,
            ),
            _settingItem(
              icon: Icons.code,
              title: 'المطور',
              subtitle: 'Cima Star Team',
              showArrow: false,
            ),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _settingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool isSwitch = false,
    bool switchValue = false,
    ValueChanged<bool>? onSwitchChanged,
    bool showArrow = true,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
      ),
      trailing: isSwitch
          ? Switch(
              value: switchValue,
              onChanged: onSwitchChanged,
              activeColor: AppTheme.primaryColor,
            )
          : showArrow
              ? const Icon(Icons.chevron_right, color: AppTheme.textTertiary)
              : null,
      onTap: isSwitch ? null : onTap,
    );
  }

  Widget _buildSourceSelector() {
    return GetBuilder<MultiSourceService>(
      builder: (apiService) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dns, color: AppTheme.accentColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'المصدر النشط: ${apiService.activeSourceName.value}',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                apiService.sourceCount,
                (index) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Obx(() => ElevatedButton(
                      onPressed: () {
                        apiService.switchSource(index);
                        _storageService.setApiSourceIndex(index);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: apiService.activeServiceIndex.value == index
                            ? AppTheme.primaryColor
                            : AppTheme.shimmerBase,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'مصدر ${index + 1}',
                        style: TextStyle(
                          color: apiService.activeServiceIndex.value == index
                              ? Colors.white
                              : AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    )),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQualityDialog() {
    final qualities = ['auto', '1080p', '720p', '480p'];
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('جودة الفيديو', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: qualities.map((q) {
            final isSelected = q == _videoQuality;
            return ListTile(
              title: Text(_qualityDisplay(q), style: TextStyle(color: AppTheme.textPrimary)),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                  : null,
              onTap: () async {
                await _storageService.setVideoQuality(q);
                setState(() => _videoQuality = q);
                Get.back();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSubtitleDialog() {
    final languages = ['ar', 'en', 'none'];
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('لغة الترجمة', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) {
            final isSelected = lang == _subtitleLang;
            return ListTile(
              title: Text(_langDisplay(lang), style: TextStyle(color: AppTheme.textPrimary)),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                  : null,
              onTap: () async {
                await _storageService.setSubtitleLang(lang);
                setState(() => _subtitleLang = lang);
                Get.back();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _clearCache() async {
    final cacheService = Get.find<CacheService>();
    await cacheService.clearAllCache();
    Helpers.showSnackBar(
      message: 'تم مسح ذاكرة التخزين المؤقت',
      type: SnackbarType.success,
    );
  }

  void _clearWatchHistory() async {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('مسح سجل المشاهدة', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'هل أنت متأكد؟ ده مش هيترجع!',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء', style: TextStyle(color: AppTheme.textTertiary)),
          ),
          TextButton(
            onPressed: () async {
              await Get.find<StorageService>().clearAll();
              Get.back();
              Helpers.showSnackBar(
                message: 'تم مسح سجل المشاهدة',
                type: SnackbarType.success,
              );
            },
            child: Text('مسح', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }
}
