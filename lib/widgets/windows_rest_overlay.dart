import 'package:flutter/material.dart';
import 'countdown_ring.dart';

/// Compact reminder UI designed to fit inside the 320 × 220 Windows overlay
/// window.
///
/// Layout:
///   ┌─────────────────────────────┐
///   │  👁  该休息了    20 s   ✕  │  ← title row (X closes the window)
///   │  ┌──────┐  看向 6 米远处,  │
///   │  │ ring │  放松眼睛。      │  ← ring + guidance
///   │  └──────┘                  │
///   │  [ 延后 5 分钟 ]  [ 跳过 ] │  ← action buttons
///   └─────────────────────────────┘
class WindowsRestOverlay extends StatelessWidget {
  const WindowsRestOverlay({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.snoozeDurationMin,
    required this.onSnooze,
    required this.onSkip,
    this.onClose,
  });

  final int remainingSeconds;
  final int totalSeconds;
  final int snoozeDurationMin;
  final VoidCallback onSnooze;
  final VoidCallback onSkip;

  /// If provided, an ✕ button is shown in the top-right corner.
  /// Tapping it is semantically equivalent to skipping the rest.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title row ────────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.visibility, color: colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  '该休息了',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Live countdown
                Text(
                  '$remainingSeconds 秒',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                // ✕ close button
                if (onClose != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: onClose,
                    icon: Icon(
                      Icons.close,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    tooltip: '关闭',
                  ),
                ],
              ],
            ),

            const SizedBox(height: 8),

            // ── Ring + guidance text ─────────────────────────────────
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CountdownRing(
                    remainingSeconds: remainingSeconds,
                    totalSeconds: totalSeconds,
                    size: 76,
                    strokeWidth: 5,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      '看向 6 米远处\n放松眼睛',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Action buttons ───────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSnooze,
                    icon: const Icon(Icons.snooze, size: 15),
                    label: Text('延后 $snoozeDurationMin 分钟'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  child: const Text('跳过'),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
