import 'package:flutter/material.dart';
import 'countdown_ring.dart';

/// The card content shown inside the rest reminder overlay / popup window.
///
/// Displays:
/// - A countdown ring
/// - Guidance text ("Look 6 metres away")
/// - Snooze and skip buttons
class RestReminderCard extends StatelessWidget {
  const RestReminderCard({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.onSnooze,
    required this.onSkip,
    this.snoozeDurationMin = 5,
    this.compact = false,
  });

  final int remainingSeconds;
  final int totalSeconds;
  final VoidCallback onSnooze;
  final VoidCallback onSkip;
  final int snoozeDurationMin;

  /// If true, uses a smaller layout (for the pill / collapsed state).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (compact) {
      return _buildCompact(context, theme);
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.visibility, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '该休息了',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Countdown ring
            CountdownRing(
              remainingSeconds: remainingSeconds,
              totalSeconds: totalSeconds,
              size: 100,
              strokeWidth: 6,
            ),
            const SizedBox(height: 16),

            // Guidance text
            Text(
              '看向 6 米远处，放松眼睛',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onSnooze,
                  icon: const Icon(Icons.snooze, size: 18),
                  label: Text('延后 $snoozeDurationMin 分钟'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: onSkip,
                  child: const Text('跳过'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.visibility,
            color: theme.colorScheme.onPrimaryContainer,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '休息 ${remainingSeconds}s',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
