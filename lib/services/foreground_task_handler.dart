import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../core/constants.dart';

/// Android foreground service handler.
///
/// Runs in a separate isolate. Communicates with the main isolate
/// through `SendPort` / `ReceivePort` messages.
///
/// Messages FROM handler to main:
///   `tick:accumulated_seconds`
///   `rest_start`
///   `rest_tick:remaining_seconds`
///   `rest_end`
///
/// Messages FROM main to handler:
///   `start`
///   `pause`
///   `reset`
///   `snooze`
///   `skip`
///   `config:usageInterval,restDuration,snoozeDuration,gracePeriod`
class ForegroundTaskHandler extends TaskHandler {
  int _accumulatedSec = 0;
  int _restRemainingSec = 0;
  int _snoozeRemainingSec = 0;
  String _state = 'counting'; // counting | resting | snoozed | idle

  int _usageIntervalSec = AppConstants.defaultUsageIntervalSec;
  int _restDurationSec = AppConstants.defaultRestDurationSec;
  int _snoozeDurationSec = AppConstants.defaultSnoozeDurationSec;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Initial setup if needed
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    switch (_state) {
      case 'counting':
        _accumulatedSec++;
        FlutterForegroundTask.updateService(
          notificationTitle: 'Greenish 护眼提醒',
          notificationText: '已使用 ${_formatTime(_accumulatedSec)} / ${_formatTime(_usageIntervalSec)}',
        );
        FlutterForegroundTask.sendDataToMain('tick:$_accumulatedSec');
        if (_accumulatedSec >= _usageIntervalSec) {
          _beginRest();
        }
        break;

      case 'resting':
        _restRemainingSec--;
        FlutterForegroundTask.updateService(
          notificationTitle: '休息中 👀',
          notificationText: '看向远处... 剩余 ${_restRemainingSec}s',
        );
        FlutterForegroundTask.sendDataToMain('rest_tick:$_restRemainingSec');
        if (_restRemainingSec <= 0) {
          _endRest();
        }
        break;

      case 'snoozed':
        _snoozeRemainingSec--;
        FlutterForegroundTask.updateService(
          notificationTitle: 'Greenish 护眼提醒',
          notificationText: '已延后，${_snoozeRemainingSec}s 后提醒',
        );
        if (_snoozeRemainingSec <= 0) {
          _beginRest();
        }
        break;

      case 'idle':
        // Do nothing
        break;
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    // Cleanup
  }

  @override
  void onReceiveData(Object data) {
    final msg = data.toString();

    if (msg == 'start') {
      _state = 'counting';
    } else if (msg == 'pause') {
      _state = 'idle';
    } else if (msg == 'reset') {
      _accumulatedSec = 0;
      _restRemainingSec = 0;
      _snoozeRemainingSec = 0;
      _state = 'counting';
    } else if (msg == 'snooze') {
      _state = 'snoozed';
      _snoozeRemainingSec = _snoozeDurationSec;
    } else if (msg == 'skip') {
      _accumulatedSec = 0;
      _state = 'counting';
      FlutterForegroundTask.sendDataToMain('rest_end');
    } else if (msg.startsWith('config:')) {
      final parts = msg.substring(7).split(',');
      if (parts.length >= 4) {
        _usageIntervalSec = int.tryParse(parts[0]) ?? _usageIntervalSec;
        _restDurationSec = int.tryParse(parts[1]) ?? _restDurationSec;
        _snoozeDurationSec = int.tryParse(parts[2]) ?? _snoozeDurationSec;
        // parts[3] = gracePeriod (handled in main isolate)
      }
    }
  }

  void _beginRest() {
    _state = 'resting';
    _restRemainingSec = _restDurationSec;
    FlutterForegroundTask.sendDataToMain('rest_start');
  }

  void _endRest() {
    _accumulatedSec = 0;
    _state = 'counting';
    FlutterForegroundTask.sendDataToMain('rest_end');
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

/// Top-level callback – entry point for the foreground task isolate.
@pragma('vm:entry-point')
void startForegroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(ForegroundTaskHandler());
}

/// Helper to initialise and start the foreground task from the main isolate.
class ForegroundTaskService {
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: AppConstants.foregroundChannelId,
        channelName: AppConstants.foregroundChannelName,
        channelDescription: 'Keeps the eye-care timer running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000), // every 1 sec
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  static Future<ServiceRequestResult> startService() async {
    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    } else {
      return FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'Greenish 护眼提醒',
        notificationText: '正在保护你的眼睛...',
        callback: startForegroundTaskCallback,
      );
    }
  }

  static Future<ServiceRequestResult> stopService() {
    return FlutterForegroundTask.stopService();
  }

  /// Send a command string to the foreground task handler.
  static void sendToHandler(String message) {
    FlutterForegroundTask.sendDataToTask(message);
  }
}
