/// Default configuration constants for the 20-20-20 rule.
class AppConstants {
  AppConstants._();

  // ── Timer defaults ──────────────────────────────────────────
  /// Screen usage interval before a break reminder (seconds).
  static const int defaultUsageIntervalSec = 20 * 60; // 20 min

  /// Rest / break duration (seconds).
  static const int defaultRestDurationSec = 20; // 20 sec

  /// Snooze duration (seconds).
  static const int defaultSnoozeDurationSec = 5 * 60; // 5 min

  // ── Grace period thresholds ─────────────────────────────────
  /// If the screen is off for less than this, the timer keeps accumulating.
  /// Prevents a quick lock/unlock from resetting the timer.
  static const int defaultGracePeriodSec = 20; // 20 sec

  /// If the screen is off for longer than this, the timer fully resets.
  static const int defaultLongBreakThresholdSec = 5 * 60; // 5 min

  // ── Configurable ranges ─────────────────────────────────────
  static const int minUsageIntervalMin = 10;
  static const int maxUsageIntervalMin = 60;

  static const int minRestDurationSec = 10;
  static const int maxRestDurationSec = 60;

  static const int minSnoozeDurationMin = 1;
  static const int maxSnoozeDurationMin = 15;

  static const int minGracePeriodSec = 5;
  static const int maxGracePeriodSec = 60;

  // ── Debug mode (shortens timers for testing) ────────────────
  static const int debugUsageIntervalSec = 20; // 20 sec
  static const int debugRestDurationSec = 5; // 5 sec
  static const int debugSnoozeDurationSec = 10; // 10 sec

  // ── SharedPreferences keys ──────────────────────────────────
  static const String keyUsageInterval = 'usage_interval_sec';
  static const String keyRestDuration = 'rest_duration_sec';
  static const String keySnoozeDuration = 'snooze_duration_sec';
  static const String keyGracePeriod = 'grace_period_sec';
  static const String keySoundEnabled = 'sound_enabled';
  static const String keyVibrationEnabled = 'vibration_enabled';
  static const String keyAutoStartOnBoot = 'auto_start_on_boot';
  static const String keyThemeMode = 'theme_mode'; // system / light / dark
  static const String keyDebugMode = 'debug_mode';
  static const String keyOnboardingCompleted = 'onboarding_completed';

  // ── Notification ────────────────────────────────────────────
  static const String foregroundChannelId = 'greenish_foreground';
  static const String foregroundChannelName = 'Greenish Timer';
  static const String reminderChannelId = 'greenish_reminder';
  static const String reminderChannelName = 'Break Reminder';
}
