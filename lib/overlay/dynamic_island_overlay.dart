import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../widgets/rest_reminder_card.dart';

/// Android overlay entry point for the Dynamic Island style reminder.
///
/// This widget is rendered in a SYSTEM_ALERT_WINDOW overlay on top of all apps.
/// It starts as a compact pill and can expand to show the full reminder card.
class DynamicIslandOverlay extends StatefulWidget {
  const DynamicIslandOverlay({super.key});

  @override
  State<DynamicIslandOverlay> createState() => _DynamicIslandOverlayState();
}

class _DynamicIslandOverlayState extends State<DynamicIslandOverlay> {
  bool _expanded = false;
  int _remainingSeconds = 20;
  int _totalSeconds = 20;
  int _snoozeDurationMin = 5;

  @override
  void initState() {
    super.initState();
    // Listen for data from main app
    FlutterOverlayWindow.overlayListener.listen(_onDataFromMain);
  }

  void _onDataFromMain(dynamic data) {
    if (data == null) return;
    final msg = data.toString();

    if (msg.startsWith('tick:')) {
      final parts = msg.substring(5).split('/');
      if (parts.length >= 2) {
        setState(() {
          _remainingSeconds = int.tryParse(parts[0]) ?? _remainingSeconds;
          _totalSeconds = int.tryParse(parts[1]) ?? _totalSeconds;
        });
      }
    } else if (msg.startsWith('config:')) {
      final parts = msg.substring(7).split(',');
      if (parts.isNotEmpty) {
        _snoozeDurationMin = (int.tryParse(parts[0]) ?? 300) ~/ 60;
      }
    } else if (msg == 'close') {
      FlutterOverlayWindow.closeOverlay();
    }
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
    // Resize overlay window
    if (_expanded) {
      FlutterOverlayWindow.resizeOverlay(300, 220, false);
    } else {
      FlutterOverlayWindow.resizeOverlay(200, 48, false);
    }
  }

  void _onSnooze() {
    FlutterOverlayWindow.shareData('snooze');
    FlutterOverlayWindow.closeOverlay();
  }

  void _onSkip() {
    FlutterOverlayWindow.shareData('skip');
    FlutterOverlayWindow.closeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4CAF50),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF4CAF50),
      ),
      home: Material(
        type: MaterialType.transparency,
        child: GestureDetector(
          onTap: _toggleExpanded,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _expanded
                ? RestReminderCard(
                    key: const ValueKey('expanded'),
                    remainingSeconds: _remainingSeconds,
                    totalSeconds: _totalSeconds,
                    snoozeDurationMin: _snoozeDurationMin,
                    onSnooze: _onSnooze,
                    onSkip: _onSkip,
                  )
                : RestReminderCard(
                    key: const ValueKey('compact'),
                    remainingSeconds: _remainingSeconds,
                    totalSeconds: _totalSeconds,
                    snoozeDurationMin: _snoozeDurationMin,
                    onSnooze: _onSnooze,
                    onSkip: _onSkip,
                    compact: true,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Entry point for the overlay isolate (called from AndroidManifest).
@pragma("vm:entry-point")
void overlayMain() {
  runApp(const DynamicIslandOverlay());
}
