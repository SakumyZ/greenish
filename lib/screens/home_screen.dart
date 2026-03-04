import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../core/platform_utils.dart';
import '../services/timer_service.dart';
import '../services/settings_service.dart';
import '../services/sound_service.dart';
import '../services/notification_service.dart';
import '../services/windows_overlay_service.dart';
import '../widgets/timer_display.dart';
import '../widgets/rest_reminder_card.dart';
import 'settings_screen.dart';

/// Main screen showing the timer progress and controls.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.timerService,
    required this.settingsService,
    required this.soundService,
    required this.notificationService,
    this.windowsOverlayService,
  });

  final TimerService timerService;
  final SettingsService settingsService;
  final SoundService soundService;
  final NotificationService notificationService;

  /// Non-null only on Windows.
  final WindowsOverlayService? windowsOverlayService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  TimerService get _timer => widget.timerService;
  SettingsService get _settings => widget.settingsService;
  StreamSubscription<dynamic>? _overlaySubscription;
  bool _isAppInForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer.addListener(_onTimerUpdate);

    _timer.onRestStart = _onRestStart;
    _timer.onRestEnd = _onRestEnd;

    if (PlatformUtils.isAndroid) {
      _overlaySubscription = FlutterOverlayWindow.overlayListener.listen((
        data,
      ) {
        final action = data?.toString();
        if (action == 'snooze') {
          _timer.snooze();
        } else if (action == 'skip') {
          _timer.skip();
        }
      });
    }

    // Wire the Windows overlay action callbacks so the sub-window can trigger
    // snooze/skip on the TimerService.
    if (PlatformUtils.isWindows) {
      widget.windowsOverlayService?.onSnooze = _timer.snooze;
      widget.windowsOverlayService?.onSkip = _timer.skip;
    }

    // Auto-start the timer
    if (_timer.state == TimerState.idle) {
      _timer.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.removeListener(_onTimerUpdate);
    _overlaySubscription?.cancel();
    if (PlatformUtils.isWindows) {
      widget.windowsOverlayService?.onSnooze = null;
      widget.windowsOverlayService?.onSkip = null;
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle for screen state detection on mobile
    if (PlatformUtils.isMobile) {
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive) {
        _isAppInForeground = false;
      } else if (state == AppLifecycleState.resumed) {
        _isAppInForeground = true;
      }
    }
  }

  void _onTimerUpdate() {
    if (PlatformUtils.isAndroid && _timer.state == TimerState.resting) {
      FlutterOverlayWindow.shareData(
        'tick:${_timer.restRemainingSec}/${_timer.restDurationSec}',
      );
    }

    // Forward ticks to the Windows reminder sub-window.
    if (PlatformUtils.isWindows && _timer.state == TimerState.resting) {
      widget.windowsOverlayService?.updateTick(
        _timer.restRemainingSec,
        _timer.restDurationSec,
      );
    }

    if (mounted) setState(() {});
  }

  Future<void> _onRestStart() async {
    widget.soundService.playReminder(
      soundEnabled: _settings.soundEnabled,
      vibrationEnabled: _settings.vibrationEnabled,
    );

    // Windows uses a visual overlay sub-window instead of a system notification.
    if (!PlatformUtils.isWindows) {
      try {
        await widget.notificationService.showReminderNotification();
      } catch (_) {
        // Non-fatal: notification failure should never block the overlay.
      }
    }

    if (PlatformUtils.isAndroid && !_isAppInForeground) {
      final canShowOverlay = await FlutterOverlayWindow.isPermissionGranted();
      if (canShowOverlay) {
        await FlutterOverlayWindow.showOverlay(
          height: 220,
          width: 300,
          alignment: OverlayAlignment.bottomCenter,
          overlayTitle: '该休息了 👀',
          overlayContent: '看向 6 米远处，放松眼睛 20 秒',
          enableDrag: true,
          flag: OverlayFlag.defaultFlag,
        );
        await FlutterOverlayWindow.shareData(
          'config:${_settings.snoozeDurationSec}',
        );
        await FlutterOverlayWindow.shareData(
          'tick:${_timer.restRemainingSec}/${_timer.restDurationSec}',
        );
      }
    }

    // Windows: spawn an independent reminder popup at the bottom-right.
    // The main window is NOT resized or moved.
    if (PlatformUtils.isWindows) {
      await widget.windowsOverlayService?.showOverlay(
        snoozeDurationSec: _settings.snoozeDurationSec,
        restDurationSec: _timer.restDurationSec,
        themeMode: _settings.themeMode.index,
      );
    }
  }

  Future<void> _onRestEnd() async {
    // Windows uses the visual overlay only, no system notification to cancel.
    if (!PlatformUtils.isWindows) {
      try {
        widget.notificationService.cancelReminder();
      } catch (_) {}
    }
    if (PlatformUtils.isAndroid) {
      await FlutterOverlayWindow.closeOverlay();
    }
    // Windows: close the reminder sub-window (if still open).
    if (PlatformUtils.isWindows) {
      await widget.windowsOverlayService?.dismissOverlay();
    }
  }

  String get _statusLabel {
    switch (_timer.state) {
      case TimerState.idle:
        return '已暂停';
      case TimerState.counting:
        return '正在计时';
      case TimerState.resting:
        return '休息中';
      case TimerState.snoozed:
        return '已延后';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isResting = _timer.state == TimerState.resting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Greenish'),
        centerTitle: true,
        actions: [
          if (_settings.debugMode)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: const Text('DEBUG'),
                backgroundColor: theme.colorScheme.errorContainer,
                labelStyle: TextStyle(
                  color: theme.colorScheme.onErrorContainer,
                  fontSize: 11,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '设置',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsScreen(settingsService: _settings),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Timer display
                TimerDisplay(
                  accumulatedSec: _timer.accumulatedSec,
                  targetSec: _timer.usageIntervalSec,
                  statusLabel: _statusLabel,
                  isResting: isResting,
                  restRemainingSec: _timer.restRemainingSec,
                  restTotalSec: _timer.restDurationSec,
                ),
                const SizedBox(height: 40),

                // Rest reminder actions (shown during rest state)
                if (isResting) ...[
                  RestReminderCard(
                    remainingSeconds: _timer.restRemainingSec,
                    totalSeconds: _timer.restDurationSec,
                    snoozeDurationMin: _settings.snoozeDurationSec ~/ 60,
                    onSnooze: () => _timer.snooze(),
                    onSkip: () => _timer.skip(),
                  ),
                ],

                // Quick actions (shown when NOT resting)
                if (!isResting) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => _timer.restNow(),
                        icon: const Icon(Icons.visibility),
                        label: const Text('立即休息'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),

      // Play / Pause FAB
      floatingActionButton: !isResting
          ? FloatingActionButton(
              onPressed: () {
                if (_timer.state == TimerState.counting ||
                    _timer.state == TimerState.snoozed) {
                  _timer.pause();
                } else {
                  _timer.start();
                }
              },
              tooltip: _timer.state == TimerState.idle ? '开始' : '暂停',
              child: Icon(
                _timer.state == TimerState.idle
                    ? Icons.play_arrow
                    : Icons.pause,
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
