import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Utility helpers for platform detection.
class PlatformUtils {
  PlatformUtils._();

  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isDesktop => isWindows; // extend later for macOS/Linux
  static bool get isMobile => isAndroid; // extend later for iOS
}
