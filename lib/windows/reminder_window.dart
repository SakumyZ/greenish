import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/windows_rest_overlay.dart';

/// Entry point for the Windows reminder sub-window.
///
/// This app runs in an independent child process spawned by desktop_multi_window.
/// It manages its own countdown timer so that the window always counts down
/// and auto-closes without depending on IPC ticks from the main window.
/// IPC ticks from the main window are still accepted to keep both in sync.
class ReminderWindowApp extends StatefulWidget {
  const ReminderWindowApp({
    super.key,
    required this.windowId,
    required this.config,
  });

  final int windowId;

  /// JSON config passed from the main window:
  ///   {
  ///     "snoozeDurationSec": int,
  ///     "restDurationSec": int,
  ///     "themeMode": int   // ThemeMode.index: 0=system, 1=light, 2=dark
  ///   }
  final Map<String, dynamic> config;

  @override
  State<ReminderWindowApp> createState() => _ReminderWindowAppState();
}

class _ReminderWindowAppState extends State<ReminderWindowApp> {
  late int _remainingSec;
  late int _totalSec;
  late int _snoozeDurationMin;
  late ThemeMode _themeMode;

  Timer? _countdown;

  @override
  void initState() {
    super.initState();

    final snoozeSec =
        (widget.config['snoozeDurationSec'] as num?)?.toInt() ?? 300;
    _totalSec = (widget.config['restDurationSec'] as num?)?.toInt() ?? 20;
    _remainingSec = _totalSec;
    _snoozeDurationMin = snoozeSec ~/ 60;
    _themeMode = ThemeMode
        .values[(widget.config['themeMode'] as num?)?.toInt().clamp(0, 2) ?? 0];

    // Optional IPC tick from main window – keeps countdown in sync if available.
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      if (call.method == 'updateTick' && mounted) {
        final parts = (call.arguments as String).split('/');
        final newRemaining = int.tryParse(parts[0]);
        final newTotal = int.tryParse(parts[1]);
        if (newRemaining != null && newTotal != null) {
          setState(() {
            _remainingSec = newRemaining;
            _totalSec = newTotal;
          });
        }
      }
      return '';
    });

    // Start the local countdown. This is the primary driver for the sub-window
    // so that it still counts down and auto-closes even if IPC ticks are lost.
    _startCountdown();
    _configureWindow();
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _countdown?.cancel();
        return;
      }
      setState(() => _remainingSec--);
      if (_remainingSec <= 0) {
        _countdown?.cancel();
        _closeWindow('done');
      }
    });
  }

  Future<void> _configureWindow() async {
    // Window style (borderless, topmost) is configured by
    // WindowsOverlayService via Win32 FFI before the window is shown.
    // Here we just ensure the window is visible as a fallback.
    try {
      await WindowController.fromWindowId(widget.windowId).show();
    } catch (_) {}
  }

  /// Send [action] to the main window then close this window.
  ///
  /// Actions: 'snooze', 'skip', 'done' (countdown reached zero naturally).
  Future<void> _closeWindow(String action) async {
    _countdown?.cancel();
    try {
      await DesktopMultiWindow.invokeMethod(0, 'overlayAction', action);
    } catch (_) {}
    try {
      await WindowController.fromWindowId(widget.windowId).close();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return GreenishTheme.withDynamicColor(
      builder: (lightTheme, darkTheme) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: _themeMode,
          home: WindowsRestOverlay(
            remainingSeconds: _remainingSec,
            totalSeconds: _totalSec,
            snoozeDurationMin: _snoozeDurationMin,
            onSnooze: () => _closeWindow('snooze'),
            onSkip: () => _closeWindow('skip'),
            onClose: () => _closeWindow('skip'),
          ),
        );
      },
    );
  }
}
