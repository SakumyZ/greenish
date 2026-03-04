import 'dart:async';
import 'package:flutter/foundation.dart';

/// The possible states of the 20-20-20 timer.
enum TimerState {
  /// Timer is idle / stopped.
  idle,

  /// Counting up towards the usage interval.
  counting,

  /// Rest reminder is active – user should look away.
  resting,

  /// User chose to snooze – waiting for snooze period to end.
  snoozed,
}

/// Core timer logic for the 20-20-20 rule.
///
/// This service tracks accumulated screen-on time and triggers a rest reminder
/// when the configured usage interval is reached. It implements a *grace period*
/// algorithm so that very short screen-off interruptions (e.g. checking the
/// time) do not reset the accumulated counter.
class TimerService extends ChangeNotifier {
  TimerService({
    required int usageIntervalSec,
    required int restDurationSec,
    required int snoozeDurationSec,
    required int gracePeriodSec,
    int longBreakThresholdSec = 5 * 60,
  })  : _usageIntervalSec = usageIntervalSec,
        _restDurationSec = restDurationSec,
        _snoozeDurationSec = snoozeDurationSec,
        _gracePeriodSec = gracePeriodSec,
        _longBreakThresholdSec = longBreakThresholdSec;

  // ── Configuration (can be updated at runtime) ───────────────
  int _usageIntervalSec;
  int _restDurationSec;
  int _snoozeDurationSec;
  int _gracePeriodSec;
  final int _longBreakThresholdSec;

  // ── Internal state ──────────────────────────────────────────
  TimerState _state = TimerState.idle;
  int _accumulatedSec = 0;
  int _restRemainingSec = 0;
  int _snoozeRemainingSec = 0;
  DateTime? _lastScreenOffTime;
  Timer? _ticker;

  // ── Callbacks ───────────────────────────────────────────────
  /// Called when it is time to show the rest reminder.
  VoidCallback? onRestStart;

  /// Called when the rest period finishes.
  VoidCallback? onRestEnd;

  /// Called every second while the timer is active (for UI updates).
  VoidCallback? onTick;

  // ── Public getters ──────────────────────────────────────────
  TimerState get state => _state;
  int get accumulatedSec => _accumulatedSec;
  int get restRemainingSec => _restRemainingSec;
  int get usageIntervalSec => _usageIntervalSec;
  int get restDurationSec => _restDurationSec;
  double get progress => _usageIntervalSec > 0 ? (_accumulatedSec / _usageIntervalSec).clamp(0.0, 1.0) : 0.0;

  // ── Configuration update ────────────────────────────────────
  void updateConfig({
    required int usageIntervalSec,
    required int restDurationSec,
    required int snoozeDurationSec,
    required int gracePeriodSec,
  }) {
    _usageIntervalSec = usageIntervalSec;
    _restDurationSec = restDurationSec;
    _snoozeDurationSec = snoozeDurationSec;
    _gracePeriodSec = gracePeriodSec;
    notifyListeners();
  }

  // ── Lifecycle ───────────────────────────────────────────────

  /// Start the timer (begin counting usage time).
  void start() {
    if (_state == TimerState.counting) return;
    _state = TimerState.counting;
    _startTicker();
    notifyListeners();
  }

  /// Pause the timer (user manually paused).
  void pause() {
    _state = TimerState.idle;
    _stopTicker();
    notifyListeners();
  }

  /// Fully reset accumulated time and go to idle.
  void reset() {
    _state = TimerState.idle;
    _accumulatedSec = 0;
    _restRemainingSec = 0;
    _snoozeRemainingSec = 0;
    _lastScreenOffTime = null;
    _stopTicker();
    notifyListeners();
  }

  /// Trigger an immediate rest (user pressed "rest now").
  void restNow() {
    _beginRest();
  }

  /// User chose to snooze the reminder.
  void snooze() {
    _state = TimerState.snoozed;
    _snoozeRemainingSec = _snoozeDurationSec;
    _startTicker();
    notifyListeners();
  }

  /// User chose to skip this rest entirely.
  void skip() {
    _accumulatedSec = 0;
    _state = TimerState.counting;
    _startTicker();
    onRestEnd?.call();
    notifyListeners();
  }

  // ── Screen state events ─────────────────────────────────────

  /// Call this when the screen turns off or app goes to background.
  void onScreenOff() {
    if (_state == TimerState.counting || _state == TimerState.snoozed) {
      _lastScreenOffTime = DateTime.now();
      _stopTicker();
    }
  }

  /// Call this when the screen turns on or app comes to foreground.
  void onScreenOn() {
    if (_lastScreenOffTime == null) return;

    final offDuration = DateTime.now().difference(_lastScreenOffTime!);
    _lastScreenOffTime = null;

    if (_state == TimerState.resting) {
      // If screen went off during rest, just continue rest
      _startTicker();
      return;
    }

    final offSeconds = offDuration.inSeconds;

    if (offSeconds < _gracePeriodSec) {
      // Short interruption – keep accumulating
      if (_state == TimerState.counting || _state == TimerState.snoozed) {
        _startTicker();
      }
    } else if (offSeconds < _longBreakThresholdSec) {
      // Medium break – counts as a valid rest, reset timer
      _accumulatedSec = 0;
      _state = TimerState.counting;
      _startTicker();
      notifyListeners();
    } else {
      // Long break – full reset
      _accumulatedSec = 0;
      _state = TimerState.counting;
      _startTicker();
      notifyListeners();
    }
  }

  // ── Internal tick logic ─────────────────────────────────────

  void _startTicker() {
    _stopTicker();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _onTick() {
    switch (_state) {
      case TimerState.counting:
        _accumulatedSec++;
        if (_accumulatedSec >= _usageIntervalSec) {
          _beginRest();
        }
        break;

      case TimerState.resting:
        _restRemainingSec--;
        if (_restRemainingSec <= 0) {
          _endRest();
        }
        break;

      case TimerState.snoozed:
        _snoozeRemainingSec--;
        if (_snoozeRemainingSec <= 0) {
          _beginRest();
        }
        break;

      case TimerState.idle:
        _stopTicker();
        break;
    }

    onTick?.call();
    notifyListeners();
  }

  void _beginRest() {
    _state = TimerState.resting;
    _restRemainingSec = _restDurationSec;
    _startTicker();
    onRestStart?.call();
    notifyListeners();
  }

  void _endRest() {
    _accumulatedSec = 0;
    _state = TimerState.counting;
    onRestEnd?.call();
    notifyListeners();
  }

  // ── Cleanup ─────────────────────────────────────────────────
  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}
