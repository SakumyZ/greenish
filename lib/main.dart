import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'core/platform_utils.dart';
import 'services/settings_service.dart';
import 'services/foreground_task_handler.dart';
import 'windows/reminder_window.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Sub-window mode (Windows reminder popup) ────────────────────────────
  // desktop_multi_window launches sub-windows by re-running the same executable
  // with 'multi_window <windowId> <jsonArgs>' as command-line arguments.
  if (args.isNotEmpty && args.first == 'multi_window') {
    final windowId = int.parse(args[1]);
    final argument =
        args.length > 2 && args[2].isNotEmpty ? args[2] : '{}';
    final config = jsonDecode(argument) as Map<String, dynamic>;
    runApp(ReminderWindowApp(windowId: windowId, config: config));
    return;
  }

  // ── Normal startup ───────────────────────────────────────────────────────

  // Initialise settings from SharedPreferences
  final settingsService = SettingsService();
  await settingsService.init();

  // Initialise Android foreground task
  if (PlatformUtils.isAndroid) {
    ForegroundTaskService.init();
  }

  // Initialise window manager for Windows desktop
  if (PlatformUtils.isWindows) {
    await windowManager.ensureInitialized();
    const WindowOptions windowOptions = WindowOptions(
      size: Size(420, 700),
      minimumSize: Size(320, 480),
      center: true,
      title: 'Greenish',
      titleBarStyle: TitleBarStyle.normal,
      skipTaskbar: false,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(GreenishApp(settingsService: settingsService));
}
