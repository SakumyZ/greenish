import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

/// Greenish brand seed color – fresh green.
const Color _brandGreen = Color(0xFF4CAF50);

/// Build a Material 3 [ThemeData] using dynamic system colors when available,
/// falling back to the brand green seed.
class GreenishTheme {
  GreenishTheme._();

  /// Returns a [DynamicColorBuilder] widget that provides light & dark themes.
  static Widget withDynamicColor({required Widget Function(ThemeData light, ThemeData dark) builder}) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final lightScheme = lightDynamic ?? ColorScheme.fromSeed(seedColor: _brandGreen, brightness: Brightness.light);
        final darkScheme = darkDynamic ?? ColorScheme.fromSeed(seedColor: _brandGreen, brightness: Brightness.dark);

        return builder(
          _buildTheme(lightScheme),
          _buildTheme(darkScheme),
        );
      },
    );
  }

  static ThemeData _buildTheme(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: null, // use system default
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: CircleBorder(),
      ),
    );
  }
}
