import 'package:flutter/material.dart';
import '../core/platform_utils.dart';
import '../services/settings_service.dart';

/// First-time onboarding flow (2-3 pages).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.settingsService,
    required this.onComplete,
    this.onRequestPermissions,
  });

  final SettingsService settingsService;
  final VoidCallback onComplete;

  /// Platform-specific permission request callback.
  final Future<void> Function()? onRequestPermissions;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final int _totalPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await widget.settingsService.setOnboardingCompleted(true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _WelcomePage(theme: theme),
                  _PermissionsPage(
                    theme: theme,
                    onRequestPermissions: widget.onRequestPermissions,
                  ),
                  _ConfigPage(
                    theme: theme,
                    settings: widget.settingsService,
                  ),
                ],
              ),
            ),

            // Bottom navigation
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page indicators
                  Row(
                    children: List.generate(
                      _totalPages,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Next / Finish button
                  FilledButton(
                    onPressed: _nextPage,
                    child: Text(_currentPage < _totalPages - 1 ? '下一步' : '开始使用'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page 1: Welcome & introduce the 20-20-20 rule.
class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.eco,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Greenish',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '20-20-20 护眼助手',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Rule explanation cards
          _RuleCard(
            icon: Icons.timer,
            number: '20',
            unit: '分钟',
            description: '每使用屏幕 20 分钟',
            theme: theme,
          ),
          const SizedBox(height: 12),
          _RuleCard(
            icon: Icons.visibility,
            number: '20',
            unit: '秒',
            description: '休息 20 秒',
            theme: theme,
          ),
          const SizedBox(height: 12),
          _RuleCard(
            icon: Icons.landscape,
            number: '20',
            unit: '英尺',
            description: '看向 6 米（20 英尺）远处',
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.icon,
    required this.number,
    required this.unit,
    required this.description,
    required this.theme,
  });

  final IconData icon;
  final String number;
  final String unit;
  final String description;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Text(
              number,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            Text(unit, style: theme.textTheme.bodySmall),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                description,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page 2: Request necessary permissions.
class _PermissionsPage extends StatelessWidget {
  const _PermissionsPage({required this.theme, this.onRequestPermissions});
  final ThemeData theme;
  final Future<void> Function()? onRequestPermissions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.security,
            size: 60,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            '需要一些权限',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            '为了在后台持续提醒你休息，Greenish 需要以下权限：',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          if (PlatformUtils.isAndroid) ...[
            _PermissionItem(
              icon: Icons.layers,
              title: '悬浮窗权限',
              description: '在其他应用上方显示灵动岛提醒',
              theme: theme,
            ),
            const SizedBox(height: 12),
            _PermissionItem(
              icon: Icons.battery_saver,
              title: '电池优化豁免',
              description: '防止系统杀掉后台计时服务',
              theme: theme,
            ),
            const SizedBox(height: 12),
            _PermissionItem(
              icon: Icons.notifications,
              title: '通知权限',
              description: '显示计时状态和休息提醒',
              theme: theme,
            ),
          ],

          if (PlatformUtils.isWindows) ...[
            _PermissionItem(
              icon: Icons.check_circle,
              title: '无需特殊权限',
              description: 'Windows 版本不需要额外权限',
              theme: theme,
            ),
          ],

          const SizedBox(height: 32),

          if (PlatformUtils.isAndroid && onRequestPermissions != null)
            FilledButton.icon(
              onPressed: () => onRequestPermissions!(),
              icon: const Icon(Icons.check),
              label: const Text('授予权限'),
            ),
        ],
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.theme,
  });

  final IconData icon;
  final String title;
  final String description;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(icon, color: theme.colorScheme.onPrimaryContainer, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Page 3: Quick configuration.
class _ConfigPage extends StatelessWidget {
  const _ConfigPage({required this.theme, required this.settings});
  final ThemeData theme;
  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.tune,
            size: 60,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            '快速配置',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '你可以使用默认的 20-20-20 参数，也可以根据习惯调整',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Usage interval
          ListenableBuilder(
            listenable: settings,
            builder: (context, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('使用间隔'),
                        Text(
                          '${settings.rawUsageIntervalSec ~/ 60} 分钟',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: (settings.rawUsageIntervalSec ~/ 60).toDouble(),
                      min: 10,
                      max: 60,
                      divisions: 50,
                      onChanged: (v) => settings.setUsageInterval(v.round() * 60),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('休息时长'),
                        Text(
                          '${settings.rawRestDurationSec} 秒',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: settings.rawRestDurationSec.toDouble(),
                      min: 10,
                      max: 60,
                      divisions: 50,
                      onChanged: (v) => settings.setRestDuration(v.round()),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          Text(
            '这些设置随时可以在设置页面调整',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
