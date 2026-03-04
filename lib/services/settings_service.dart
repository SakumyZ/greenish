import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

/// Persists and exposes all user-configurable settings via [ChangeNotifier].
class SettingsService extends ChangeNotifier {
  late SharedPreferences _prefs;

  // ── Fields ───────────────────────────────────────────────────
  int _usageIntervalSec = AppConstants.defaultUsageIntervalSec;
  int _restDurationSec = AppConstants.defaultRestDurationSec;
  int _snoozeDurationSec = AppConstants.defaultSnoozeDurationSec;
  int _gracePeriodSec = AppConstants.defaultGracePeriodSec;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _autoStartOnBoot = false;
  ThemeMode _themeMode = ThemeMode.system;
  bool _debugMode = false;
  bool _onboardingCompleted = false;

  // ── Getters ──────────────────────────────────────────────────
  int get usageIntervalSec => _debugMode ? AppConstants.debugUsageIntervalSec : _usageIntervalSec;
  int get restDurationSec => _debugMode ? AppConstants.debugRestDurationSec : _restDurationSec;
  int get snoozeDurationSec => _debugMode ? AppConstants.debugSnoozeDurationSec : _snoozeDurationSec;
  int get gracePeriodSec => _gracePeriodSec;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get autoStartOnBoot => _autoStartOnBoot;
  ThemeMode get themeMode => _themeMode;
  bool get debugMode => _debugMode;
  bool get onboardingCompleted => _onboardingCompleted;

  // Raw values (for settings sliders)
  int get rawUsageIntervalSec => _usageIntervalSec;
  int get rawRestDurationSec => _restDurationSec;
  int get rawSnoozeDurationSec => _snoozeDurationSec;

  // ── Initialisation ──────────────────────────────────────────
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _usageIntervalSec = _prefs.getInt(AppConstants.keyUsageInterval) ?? AppConstants.defaultUsageIntervalSec;
    _restDurationSec = _prefs.getInt(AppConstants.keyRestDuration) ?? AppConstants.defaultRestDurationSec;
    _snoozeDurationSec = _prefs.getInt(AppConstants.keySnoozeDuration) ?? AppConstants.defaultSnoozeDurationSec;
    _gracePeriodSec = _prefs.getInt(AppConstants.keyGracePeriod) ?? AppConstants.defaultGracePeriodSec;
    _soundEnabled = _prefs.getBool(AppConstants.keySoundEnabled) ?? true;
    _vibrationEnabled = _prefs.getBool(AppConstants.keyVibrationEnabled) ?? true;
    _autoStartOnBoot = _prefs.getBool(AppConstants.keyAutoStartOnBoot) ?? false;
    _debugMode = _prefs.getBool(AppConstants.keyDebugMode) ?? false;
    _onboardingCompleted = _prefs.getBool(AppConstants.keyOnboardingCompleted) ?? false;

    final themeModeStr = _prefs.getString(AppConstants.keyThemeMode) ?? 'system';
    _themeMode = _themeModeFromString(themeModeStr);

    notifyListeners();
  }

  // ── Setters ──────────────────────────────────────────────────
  Future<void> setUsageInterval(int seconds) async {
    _usageIntervalSec = seconds;
    await _prefs.setInt(AppConstants.keyUsageInterval, seconds);
    notifyListeners();
  }

  Future<void> setRestDuration(int seconds) async {
    _restDurationSec = seconds;
    await _prefs.setInt(AppConstants.keyRestDuration, seconds);
    notifyListeners();
  }

  Future<void> setSnoozeDuration(int seconds) async {
    _snoozeDurationSec = seconds;
    await _prefs.setInt(AppConstants.keySnoozeDuration, seconds);
    notifyListeners();
  }

  Future<void> setGracePeriod(int seconds) async {
    _gracePeriodSec = seconds;
    await _prefs.setInt(AppConstants.keyGracePeriod, seconds);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await _prefs.setBool(AppConstants.keySoundEnabled, value);
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    await _prefs.setBool(AppConstants.keyVibrationEnabled, value);
    notifyListeners();
  }

  Future<void> setAutoStartOnBoot(bool value) async {
    _autoStartOnBoot = value;
    await _prefs.setBool(AppConstants.keyAutoStartOnBoot, value);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(AppConstants.keyThemeMode, _themeModeToString(mode));
    notifyListeners();
  }

  Future<void> setDebugMode(bool value) async {
    _debugMode = value;
    await _prefs.setBool(AppConstants.keyDebugMode, value);
    notifyListeners();
  }

  Future<void> setOnboardingCompleted(bool value) async {
    _onboardingCompleted = value;
    await _prefs.setBool(AppConstants.keyOnboardingCompleted, value);
    notifyListeners();
  }

  // ── Helpers ──────────────────────────────────────────────────
  static ThemeMode _themeModeFromString(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeToString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
