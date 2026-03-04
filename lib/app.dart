import 'package:flutter/material.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'core/theme.dart';
import 'services/settings_service.dart';
import 'services/timer_service.dart';
import 'services/sound_service.dart';
import 'services/notification_service.dart';
import 'services/windows_overlay_service.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'core/platform_utils.dart';

/// Root application widget.
class GreenishApp extends StatefulWidget {
  const GreenishApp({super.key, required this.settingsService});

  final SettingsService settingsService;

  @override
  State<GreenishApp> createState() => _GreenishAppState();
}

class _GreenishAppState extends State<GreenishApp> {
  late final TimerService _timerService;
  late final SoundService _soundService;
  late final NotificationService _notificationService;
  // Only created on Windows; null on other platforms.
  late final WindowsOverlayService? _windowsOverlayService;

  SettingsService get _settings => widget.settingsService;

  @override
  void initState() {
    super.initState();

    _timerService = TimerService(
      usageIntervalSec: _settings.usageIntervalSec,
      restDurationSec: _settings.restDurationSec,
      snoozeDurationSec: _settings.snoozeDurationSec,
      gracePeriodSec: _settings.gracePeriodSec,
    );

    _soundService = SoundService();
    _notificationService = NotificationService();
    _notificationService.init();

    _windowsOverlayService = PlatformUtils.isWindows
        ? WindowsOverlayService()
        : null;

    // Update timer config when settings change
    _settings.addListener(_syncTimerConfig);
  }

  @override
  void dispose() {
    _settings.removeListener(_syncTimerConfig);
    _timerService.dispose();
    _soundService.dispose();
    _windowsOverlayService?.dispose();
    super.dispose();
  }

  void _syncTimerConfig() {
    _timerService.updateConfig(
      usageIntervalSec: _settings.usageIntervalSec,
      restDurationSec: _settings.restDurationSec,
      snoozeDurationSec: _settings.snoozeDurationSec,
      gracePeriodSec: _settings.gracePeriodSec,
    );
  }

  Future<void> _requestAndroidPermissions() async {
    if (!PlatformUtils.isAndroid) return;

    final hasOverlay = await FlutterOverlayWindow.isPermissionGranted();
    if (!hasOverlay) {
      await FlutterOverlayWindow.requestPermission();
    }

    final isBatteryOptimizationDisabled =
        await DisableBatteryOptimization.isBatteryOptimizationDisabled ?? false;
    if (!isBatteryOptimizationDisabled) {
      await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
    }

    await _notificationService.requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        return GreenishTheme.withDynamicColor(
          builder: (lightTheme, darkTheme) {
            return MaterialApp(
              title: 'Greenish',
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: _settings.themeMode,
              debugShowCheckedModeBanner: false,
              home: _settings.onboardingCompleted
                  ? HomeScreen(
                      timerService: _timerService,
                      settingsService: _settings,
                      soundService: _soundService,
                      notificationService: _notificationService,
                      windowsOverlayService: _windowsOverlayService,
                    )
                  : OnboardingScreen(
                      settingsService: _settings,
                      onRequestPermissions: _requestAndroidPermissions,
                      onComplete: () => setState(() {}),
                    ),
            );
          },
        );
      },
    );
  }
}
