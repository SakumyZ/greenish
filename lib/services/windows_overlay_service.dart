import 'dart:convert';
import 'dart:ui';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
  static const MethodChannel _windowMetricsChannel = MethodChannel(
    'greenish/window_metrics',
  );

  WindowsOverlayService() {
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      if (call.method == 'overlayAction') {
        handleOverlayAction(call.arguments as String?);
      }
      return '';
    });
  }

  /// Called when the user taps "Snooze" in the reminder popup.
  VoidCallback? onSnooze;

  /// Called when the user taps "Skip" in the reminder popup.
  VoidCallback? onSkip;

  WindowController? _overlayWindow;
  bool _overlayVisible = false;

  bool get isOverlayVisible => _overlayVisible;

  /// Creates and shows the reminder sub-window.
  ///
  /// [themeMode] is `ThemeMode.index` (0=system, 1=light, 2=dark) and is
  /// forwarded to the sub-window so it matches the main app's theme.
  Future<void> showOverlay({
    required int snoozeDurationSec,
    required int restDurationSec,
    int themeMode = 0,
    bool forceRecreate = false,
  }) async {
    if (_overlayVisible) {
      if (!forceRecreate) return;
      await dismissOverlay();
    }

    final args = jsonEncode({
      'snoozeDurationSec': snoozeDurationSec,
      'restDurationSec': restDurationSec,
      'themeMode': themeMode,
    });

    try {
      final controller = await DesktopMultiWindow.createWindow(args);
      _overlayWindow = controller;
      _overlayVisible = true;
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

    try {
      final metrics = await _getCurrentMonitorMetrics();
      final frame = metrics != null
          ? computeOverlayFrame(
              metrics.workArea,
              scaleFactor: metrics.scaleFactor,
              overlaySize: const Size(overlayW, overlayH),
              margin: margin,
            )
          : _fallbackOverlayFrame(
              overlaySize: const Size(overlayW, overlayH),
              margin: margin,
            );
      await controller.setFrame(frame);
    } catch (_) {}
    try {
      await controller.show();
    } catch (_) {}
  }

  @visibleForTesting
  Rect computeOverlayFrame(
    Rect workArea, {
    required double scaleFactor,
    required Size overlaySize,
    required double margin,
  }) {
    final physicalOverlayW = overlaySize.width * scaleFactor;
    final physicalOverlayH = overlaySize.height * scaleFactor;
    final physicalMargin = margin * scaleFactor;

    return Rect.fromLTWH(
      workArea.right - physicalOverlayW - physicalMargin,
      workArea.bottom - physicalOverlayH - physicalMargin,
      physicalOverlayW,
      physicalOverlayH,
    );
  }

  /// Gets the work area and scale factor of the **primary** monitor from the
  /// native side, so the reminder popup always appears on the primary display.
  Future<_MonitorMetrics?> _getCurrentMonitorMetrics() async {
    try {
      final result = await _windowMetricsChannel
          .invokeMapMethod<String, double>('getCurrentMonitorMetrics');
      if (result == null) return null;

      final left = result['left'];
      final top = result['top'];
      final width = result['width'];
      final height = result['height'];
      final scaleFactor = result['scaleFactor'];
      if (left == null ||
          top == null ||
          width == null ||
          height == null ||
          scaleFactor == null) {
        return null;
      }

      return _MonitorMetrics(
        workArea: Rect.fromLTWH(left, top, width, height),
        scaleFactor: scaleFactor,
      );
    } catch (_) {
      return null;
    }
  }

  Rect _fallbackOverlayFrame({
    required Size overlaySize,
    required double margin,
  }) {
    final displays = PlatformDispatcher.instance.displays;
    if (displays.isNotEmpty) {
      final display = displays.first;
      return Rect.fromLTWH(
        display.size.width - overlaySize.width - margin,
        display.size.height - overlaySize.height - margin,
        overlaySize.width,
        overlaySize.height,
      );
    }

    return Rect.fromLTWH(1920 - overlaySize.width - margin,
        1080 - overlaySize.height - margin, overlaySize.width, overlaySize.height);
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
    if (!_overlayVisible && w == null) return;
    _clearOverlayState();
    if (w == null) return;
    try {
      await w.close();
    } catch (_) {
      // Sub-window may have already closed itself (countdown finished).
    }
  }

  void handleOverlayAction(String? action) {
    if (action == null) return;

    if (action == 'snooze' || action == 'skip' || action == 'done') {
      _clearOverlayState();
    }

    if (action == 'snooze') {
      onSnooze?.call();
    } else if (action == 'skip') {
      onSkip?.call();
    }
  }

  @visibleForTesting
  void debugSetOverlayVisible(bool visible) {
    _overlayVisible = visible;
    if (!visible) {
      _overlayWindow = null;
    }
  }

  void _clearOverlayState() {
    if (!_overlayVisible && _overlayWindow == null) return;
    _overlayVisible = false;
    _overlayWindow = null;
    notifyListeners();
  }
}

class _MonitorMetrics {
  const _MonitorMetrics({required this.workArea, required this.scaleFactor});

  final Rect workArea;
  final double scaleFactor;
}
