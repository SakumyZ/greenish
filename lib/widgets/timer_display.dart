import 'package:flutter/material.dart';
import 'countdown_ring.dart';

/// Displays the main timer progress on the home screen.
///
/// Shows a large ring with accumulated / target time and a status label.
class TimerDisplay extends StatelessWidget {
  const TimerDisplay({
    super.key,
    required this.accumulatedSec,
    required this.targetSec,
    required this.statusLabel,
    this.isResting = false,
    this.restRemainingSec = 0,
    this.restTotalSec = 0,
  });

  final int accumulatedSec;
  final int targetSec;
  final String statusLabel;
  final bool isResting;
  final int restRemainingSec;
  final int restTotalSec;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isResting) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CountdownRing(
            remainingSeconds: restRemainingSec,
            totalSeconds: restTotalSec,
            size: 220,
            strokeWidth: 12,
            color: theme.colorScheme.tertiary,
          ),
          const SizedBox(height: 16),
          Text(
            '看向 6 米远处，放松眼睛',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.tertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CountdownRing(
          remainingSeconds: accumulatedSec,
          totalSeconds: targetSec,
          size: 220,
          strokeWidth: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(accumulatedSec),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                '/ ${_formatTime(targetSec)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          statusLabel,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatTime(int totalSec) {
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
