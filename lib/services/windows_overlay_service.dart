import 'dart:convert';
import 'dart:ui';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';

/// Manages the Windows reminder popup (sub-window).
///
/// Creates an independent 320×220 child window at the bottom-right of the
/// screen when a rest reminder is triggered. The sub-window manages its own
/// countdown and closes itself; IPC is used for sync and action callbacks.
///
/// Communication flow:
///   Main → Sub : 'updateTick' '$remaining/$total'  (timer sync)
///   Sub  → Main: 'overlayAction' 'snooze'|'skip'|'done'
class WindowsOverlayService extends ChangeNotifier {
  WindowsOverlayService() {
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      if (call.method == 'overlayAction') {
        final action = call.arguments as String?;
        if (action == 'snooze') {
          onSnooze?.call();
        } else if (action == 'skip') {
          onSkip?.call();
        } else if (action == 'done') {
          // Sub-window counted down to zero and closed itself; clean up state.
          _overlayWindow = null;
          notifyListeners();
        }
      }
      return '';
    });
  }

  /// Called when the user taps "Snooze" in the reminder popup.
  VoidCallback? onSnooze;

  /// Called when the user taps "Skip" in the reminder popup.
  VoidCallback? onSkip;

  WindowController? _overlayWindow;

  bool get isOverlayVisible => _overlayWindow != null;

  /// Creates and shows the reminder sub-window.
  ///
  /// [themeMode] is `ThemeMode.index` (0=system, 1=light, 2=dark) and is
  /// forwarded to the sub-window so it matches the main app's theme.
  Future<void> showOverlay({
    required int snoozeDurationSec,
    required int restDurationSec,
    int themeMode = 0,
  }) async {
    if (_overlayWindow != null) return;

    final args = jsonEncode({
      'snoozeDurationSec': snoozeDurationSec,
      'restDurationSec': restDurationSec,
      'themeMode': themeMode,
    });

    try {
      final controller = await DesktopMultiWindow.createWindow(args);
      _overlayWindow = controller;
      await _positionAndShow(controller);
      notifyListeners();
    } catch (e) {
      debugPrint('WindowsOverlayService: createWindow failed: $e');
    }
  }

  /// Positions the sub-window at the bottom-right and calls show().
  Future<void> _positionAndShow(WindowController controller) async {
    const overlayW = 320.0;
    const overlayH = 220.0;
    const margin = 8.0;
    const taskbarH = 48.0;

    double screenW = 1920;
    double screenH = 1080;
    final displays = PlatformDispatcher.instance.displays;
    if (displays.isNotEmpty) {
      final d = displays.first;
      screenW = d.size.width / d.devicePixelRatio;
      screenH = d.size.height / d.devicePixelRatio;
    }

    final x = screenW - overlayW - margin;
    final y = screenH - overlayH - taskbarH - margin;

    try {
      await controller.setFrame(Rect.fromLTWH(x, y, overlayW, overlayH));
    } catch (_) {}
    try {
      await controller.show();
    } catch (_) {}
  }

  /// Forwards a timer tick to the reminder sub-window for sync.
  Future<void> updateTick(int remaining, int total) async {
    final w = _overlayWindow;
    if (w == null) return;
    try {
      await DesktopMultiWindow.invokeMethod(
        w.windowId,
        'updateTick',
        '$remaining/$total',
      );
    } catch (_) {}
  }

  /// Closes the reminder sub-window and resets state.
  Future<void> dismissOverlay() async {
    final w = _overlayWindow;
    if (w == null) return;
    _overlayWindow = null;
    notifyListeners();
    try {
      await w.close();
    } catch (_) {
      // Sub-window may have already closed itself (countdown finished).
    }
  }
}
