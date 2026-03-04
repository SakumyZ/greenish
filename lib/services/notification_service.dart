import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/constants.dart';

/// Manages local notifications (foreground service notification on Android,
/// fallback reminders on both platforms).
///
/// On Windows the visual overlay is used instead, so all methods are no-ops.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Whether the plugin has been successfully initialized for the current platform.
  bool _initialized = false;

  /// True when running on a platform that needs this service (i.e. Android).
  static bool get _supported => !kIsWeb && Platform.isAndroid;

  Future<void> init() async {
    if (!_supported) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _plugin.initialize(initSettings);
      _initialized = true;
    } catch (_) {
      // Initialization failure is non-fatal.
    }

    // Create notification channels on Android
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          AppConstants.reminderChannelId,
          AppConstants.reminderChannelName,
          description: 'Break reminder notifications',
          importance: Importance.high,
        ),
      );
    }
  }

  Future<void> requestPermission() async {
    if (!_initialized) return;
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  /// Show a reminder notification (used as fallback when overlay is not available).
  Future<void> showReminderNotification({
    String title = '该休息了 👀',
    String body = '看向 6 米远处，放松眼睛 20 秒',
  }) async {
    if (!_initialized) return;
    const androidDetails = AndroidNotificationDetails(
      AppConstants.reminderChannelId,
      AppConstants.reminderChannelName,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      autoCancel: true,
    );

    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(1, title, body, details);
  }

  /// Cancel the reminder notification.
  Future<void> cancelReminder() async {
    if (!_initialized) return;
    await _plugin.cancel(1);
  }

  /// Cancel all notifications.
  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }
}
