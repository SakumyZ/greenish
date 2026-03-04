# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

**Greenish** 是一个基于 Flutter 的 20-20-20 眼睛护理提醒应用，支持 Android 和 Windows 平台。核心规则：每使用屏幕 20 分钟，提醒用户休息 20 秒并看向 6 米外放松眼睛。

## 常用命令

```bash
# 获取依赖
flutter pub get

# 代码静态分析
flutter analyze

# 运行测试
flutter test

# 运行单个测试文件
flutter test test/some_test.dart

# 运行应用（调试）
flutter run -d android
flutter run -d windows

# 构建发行版
flutter build apk
flutter build appbundle
flutter build windows

# 清理构建产物
flutter clean
```

## 架构概览

### 整体模式：Services + ChangeNotifier

采用 Service 层 + `ChangeNotifier` + `ListenableBuilder` 的响应式架构，无第三方状态管理库。

```
main.dart
  └── app.dart (GreenishApp)
        ├── SettingsService (从 main.dart 注入)
        ├── TimerService (依赖 SettingsService)
        └── screens/
              ├── OnboardingScreen  (首次启动权限引导)
              └── HomeScreen        (主界面，监听 TimerService)
```

### 目录职责

- `lib/core/` — 常量 (`constants.dart`)、主题、平台工具
- `lib/services/` — 全部业务逻辑，均为 `ChangeNotifier`
- `lib/screens/` — 三个页面：主界面、设置、引导
- `lib/widgets/` — 环形计时显示等可复用组件
- `lib/overlay/` — Android 灵动岛风格悬浮提醒（SYSTEM_ALERT_WINDOW 层）

### 核心服务

**`TimerService`** — 核心状态机，状态流：`idle → counting → resting → counting`

关键特性：**分级宽限期策略**，在 `onScreenOn()` 中实现：

- 离屏 < 20 秒：继续累积（避免锁屏/解锁重置计时）
- 离屏 20 秒~5 分钟：重置计时器（视为有效休息）
- 离屏 ≥ 5 分钟：完全重置（用户明显已离开）

**`SettingsService`** — 持久化所有用户配置到 `SharedPreferences`。所有可配置参数的键名定义在 `lib/core/constants.dart`。

**`ForegroundTaskHandler`** — Android 专用，在独立 isolate 运行，保证应用被杀死后计时继续。每秒通过消息队列向主 isolate 发送 `tick:$_accumulatedSec`。

**`dynamic_island_overlay.dart`** — Android 灵动岛悬浮窗，有收起（200×48dp）和展开（300×220dp）两种状态，与主应用通过 `FlutterOverlayWindow` 消息队列通信。

### 平台差异

- **Android**：前台服务（`flutter_foreground_task`）+ 灵动岛悬浮窗（`flutter_overlay_window`）
- **Windows**：系统托盘（`system_tray`）+ 窗口管理（`window_manager`）
- 平台判断通过 `lib/core/platform_utils.dart` 集中处理

## 调试模式

`SettingsService.debugMode = true` 时，所有计时自动缩短（20 分钟 → 20 秒，20 秒休息 → 5 秒）。可在设置页面开启，便于快速测试完整流程。

## Android 权限

需在运行时请求的关键权限：

- `SYSTEM_ALERT_WINDOW` — 灵动岛悬浮窗
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` — 后台保活
- `POST_NOTIFICATIONS` — 通知（Android 13+）

权限请求流程在 `OnboardingScreen` 中完成。
