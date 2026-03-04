import 'dart:io' show Platform;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Manages reminder sound effects and haptic feedback.
///
/// Respects system silent/vibrate mode on Android.
class SoundService {
  final AudioPlayer _player = AudioPlayer();

  /// Play the reminder chime.
  ///
  /// - On Android: checks ringer mode; skips audio in silent/vibrate mode.
  /// - [vibrate] controls whether to also trigger haptic feedback.
  Future<void> playReminder({
    bool soundEnabled = true,
    bool vibrationEnabled = true,
  }) async {
    if (soundEnabled) {
      final shouldPlay = await _shouldPlaySound();
      if (shouldPlay) {
        try {
          await _player.play(AssetSource('sounds/reminder.mp3'));
        } catch (_) {
          // Sound file may not exist yet – fail silently.
        }
      }
    }

    if (vibrationEnabled && Platform.isAndroid) {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        // Short double vibration pattern
        Vibration.vibrate(pattern: [0, 100, 80, 100]);
      }
    }
  }

  /// Stop any currently playing audio.
  Future<void> stop() async {
    await _player.stop();
  }

  /// Check whether sound should play based on system ringer mode (Android).
  Future<bool> _shouldPlaySound() async {
    if (!Platform.isAndroid) return true;
    try {
      // Use platform channel to query ringer mode
      const channel = MethodChannel('com.greenish.greenish/audio');
      final int ringerMode = await channel.invokeMethod('getRingerMode');
      // 0 = SILENT, 1 = VIBRATE, 2 = NORMAL
      return ringerMode == 2;
    } catch (_) {
      // If platform channel not available, play anyway
      return true;
    }
  }

  void dispose() {
    _player.dispose();
  }
}
