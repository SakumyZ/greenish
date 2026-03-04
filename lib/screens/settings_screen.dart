import 'package:flutter/material.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../core/constants.dart';
import '../core/platform_utils.dart';
import '../services/settings_service.dart';

/// Settings screen with configurable timer parameters.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.settingsService});

  final SettingsService settingsService;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsService,
      builder: (context, _) => _SettingsContent(settings: settingsService),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent({required this.settings});

  final SettingsService settings;

  Future<void> _requestAndroidPermissions(BuildContext context) async {
    final hasOverlay = await FlutterOverlayWindow.isPermissionGranted();
    if (!hasOverlay) {
      await FlutterOverlayWindow.requestPermission();
    }

    final isBatteryOptimizationDisabled = await DisableBatteryOptimization.isBatteryOptimizationDisabled ?? false;
    if (!isBatteryOptimizationDisabled) {
      await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
    }

    final plugin = FlutterLocalNotificationsPlugin();
    final androidPlugin = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('后台提醒权限已检查，请确认系统设置页中的授权状态')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _SectionHeader('计时参数'),

          // Usage interval
          _SliderTile(
            icon: Icons.timer,
            title: '使用间隔',
            subtitle: '${settings.rawUsageIntervalSec ~/ 60} 分钟',
            value: (settings.rawUsageIntervalSec ~/ 60).toDouble(),
            min: AppConstants.minUsageIntervalMin.toDouble(),
            max: AppConstants.maxUsageIntervalMin.toDouble(),
            divisions: AppConstants.maxUsageIntervalMin - AppConstants.minUsageIntervalMin,
            onChanged: (v) => settings.setUsageInterval(v.round() * 60),
          ),

          // Rest duration
          _SliderTile(
            icon: Icons.visibility,
            title: '休息时长',
            subtitle: '${settings.rawRestDurationSec} 秒',
            value: settings.rawRestDurationSec.toDouble(),
            min: AppConstants.minRestDurationSec.toDouble(),
            max: AppConstants.maxRestDurationSec.toDouble(),
            divisions: AppConstants.maxRestDurationSec - AppConstants.minRestDurationSec,
            onChanged: (v) => settings.setRestDuration(v.round()),
          ),

          // Snooze duration
          _SliderTile(
            icon: Icons.snooze,
            title: '延后时长',
            subtitle: '${settings.rawSnoozeDurationSec ~/ 60} 分钟',
            value: (settings.rawSnoozeDurationSec ~/ 60).toDouble(),
            min: AppConstants.minSnoozeDurationMin.toDouble(),
            max: AppConstants.maxSnoozeDurationMin.toDouble(),
            divisions: AppConstants.maxSnoozeDurationMin - AppConstants.minSnoozeDurationMin,
            onChanged: (v) => settings.setSnoozeDuration(v.round() * 60),
          ),

          const Divider(),
          _SectionHeader('提醒方式'),

          // Sound
          SwitchListTile(
            secondary: const Icon(Icons.volume_up),
            title: const Text('提醒音效'),
            subtitle: const Text('跟随系统静音模式'),
            value: settings.soundEnabled,
            onChanged: (v) => settings.setSoundEnabled(v),
          ),

          // Vibration (Android only)
          if (PlatformUtils.isAndroid)
            SwitchListTile(
              secondary: const Icon(Icons.vibration),
              title: const Text('震动'),
              value: settings.vibrationEnabled,
              onChanged: (v) => settings.setVibrationEnabled(v),
            ),

          const Divider(),
          _SectionHeader('外观'),

          // Theme mode
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('深色模式'),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('跟随系统')),
                ButtonSegment(value: ThemeMode.light, label: Icon(Icons.light_mode, size: 18)),
                ButtonSegment(value: ThemeMode.dark, label: Icon(Icons.dark_mode, size: 18)),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (v) => settings.setThemeMode(v.first),
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),

          if (PlatformUtils.isAndroid) ...[
            const Divider(),
            _SectionHeader('Android 专项'),

            // Auto start on boot
            SwitchListTile(
              secondary: const Icon(Icons.power_settings_new),
              title: const Text('开机自启'),
              value: settings.autoStartOnBoot,
              onChanged: (v) => settings.setAutoStartOnBoot(v),
            ),

            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('重新授权后台权限'),
              subtitle: const Text('通知、悬浮窗、电池优化豁免'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _requestAndroidPermissions(context),
            ),
          ],

          const Divider(),
          _SectionHeader('高级'),

          // Grace period
          _SliderTile(
            icon: Icons.timelapse,
            title: '短暂中断宽限期',
            subtitle: '${settings.gracePeriodSec} 秒（锁屏时间短于此值不重置计时器）',
            value: settings.gracePeriodSec.toDouble(),
            min: AppConstants.minGracePeriodSec.toDouble(),
            max: AppConstants.maxGracePeriodSec.toDouble(),
            divisions: (AppConstants.maxGracePeriodSec - AppConstants.minGracePeriodSec) ~/ 5,
            onChanged: (v) => settings.setGracePeriod(v.round()),
          ),

          // Debug mode
          SwitchListTile(
            secondary: const Icon(Icons.bug_report),
            title: const Text('调试模式'),
            subtitle: const Text('缩短计时时间以便测试'),
            value: settings.debugMode,
            onChanged: (v) => settings.setDebugMode(v),
          ),

          const SizedBox(height: 32),

          // App info
          Center(
            child: Text(
              'Greenish v0.1.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions > 0 ? divisions : null,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
