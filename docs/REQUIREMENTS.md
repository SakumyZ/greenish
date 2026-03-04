# Greenish — 20-20-20 护眼提醒应用

## 概述

基于 Flutter 构建跨平台（Android + Windows）护眼应用。核心功能是累积屏幕使用时间计时器，达到 20 分钟后以非侵入方式提醒用户休息 20 秒并看向远处（6 米 / 20 英尺）。

**目标平台**: Android、Windows
**技术栈**: Flutter + Dart
**UI 风格**: Material Design 3

---

## 20-20-20 规则

每使用屏幕 **20 分钟**，休息 **20 秒**，看向 **20 英尺（约 6 米）远处**。

---

## 核心需求

### 1. 累积计时算法

- 屏幕亮起/用户活跃时累积计时
- 达到设定时间（默认 20 分钟）后触发休息提醒
- **短暂中断不重置**：如果用户锁屏后很快解锁（< 20 秒），计时器继续累积，避免"快 20 分钟锁屏又开"导致重置的问题
- 分级宽限策略：
  | 中断时长 | 行为 | 原因 |
  |---|---|---|
  | < 20 秒（可配置） | 继续累积，不重置 | 视为误触/看时间 |
  | 20 秒 ~ 5 分钟 | 重置计时器 | 已完成有效休息 |
  | ≥ 5 分钟 | 完全重置 | 用户明显已离开 |

### 2. 提醒展示方式

#### Android 端 — 灵动岛风格悬浮药丸

- 使用 `flutter_overlay_window` 在所有 app 之上绘制
- **收起态**：屏幕顶部居中小药丸（约 200×40dp），绿色图标 + "休息 20s"
- **展开态**：点击药丸展开为圆角卡片（约 300×160dp）
  - 环形倒计时动画
  - "看向 6 米远处，放松眼睛" 引导文案
  - 「延后」按钮（默认 5 分钟，可配置）
  - 「跳过」按钮
- 需要 `SYSTEM_ALERT_WINDOW` 权限，首次使用引导授权

#### Windows 端 — 右下角自定义悬浮小窗口

- 使用 `window_manager` 创建无边框、置顶、固定右下角的小窗口（约 320×200px）
- 内容：环形倒计时 + 引导文案 + 延后/跳过按钮
- Material 3 Card 风格，圆角 + 阴影
- 可拖拽但默认锚定右下角（任务栏上方）

### 3. 声音与震动

- **跟随系统静音模式**：
  - Android 静音/震动模式下不播放声音，改为震动
  - Windows 系统静音时不播放
- 内置柔和提醒音效（水滴声）
- Android 震动反馈：短促双震 `[0, 100, 80, 100]`
- 声音/震动可在设置中独立开关

### 4. 延后功能

- 休息提醒弹出后可选择「延后」
- 默认延后 5 分钟，可在设置中配置（1~15 分钟）
- 延后后到时再次提醒

### 5. 常驻 & 保活（Android）

- 使用 `flutter_foreground_task` 前台服务
- 常驻通知栏显示当前累积使用时长
- 请求电池优化豁免（`disable_battery_optimization`）
- 检测厂商（小米/华为/OPPO/三星等）给针对性设置引导
- 可选开机自启

### 6. 用户设置

| 设置项                 | 默认值   | 范围                      |
| ---------------------- | -------- | ------------------------- |
| 使用间隔               | 20 分钟  | 10~60 分钟                |
| 休息时长               | 20 秒    | 10~60 秒                  |
| 延后时长               | 5 分钟   | 1~15 分钟                 |
| 短暂中断宽限期         | 20 秒    | 5~60 秒（高级）           |
| 提醒音效               | 跟随系统 | 开/关/跟随系统            |
| 震动（仅 Android）     | 开       | 开/关                     |
| 开机自启（仅 Android） | 关       | 开/关                     |
| 暗色模式               | 跟随系统 | 跟随系统/亮/暗            |
| 调试模式               | 关       | 开/关（缩短时间便于测试） |

### 7. 首次引导

- 2~3 页引导页：
  1. 介绍 20-20-20 规则
  2. 请求权限（Android：悬浮窗 + 电池优化豁免 + 通知）
  3. 快速配置时间参数

### 8. 主界面

- 大号环形进度条展示当前累积/目标时间
- 启动/暂停按钮（FAB）
- 状态文案（正在计时/休息中/已暂停）
- 底部快捷：立即休息、设置入口
- Windows 支持最小化到系统托盘

---

## 技术方案

### 核心依赖

| 包名                           | 用途                       |
| ------------------------------ | -------------------------- |
| `flutter_foreground_task`      | Android 前台服务保活       |
| `flutter_overlay_window`       | Android 灵动岛悬浮窗       |
| `window_manager`               | Windows 窗口管理（小窗口） |
| `flutter_local_notifications`  | 跨平台通知（备用）         |
| `audioplayers`                 | 提醒音效                   |
| `vibration`                    | Android 震动               |
| `dynamic_color`                | Material 3 动态配色        |
| `disable_battery_optimization` | 电池优化豁免               |
| `shared_preferences`           | 本地配置持久化             |
| `wakelock_plus`                | 休息时保持屏幕亮           |
| `system_tray`                  | Windows 系统托盘           |

### 项目结构

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants.dart
│   ├── theme.dart
│   └── platform_utils.dart
├── services/
│   ├── timer_service.dart
│   ├── screen_state_service.dart
│   ├── idle_service.dart
│   ├── notification_service.dart
│   ├── sound_service.dart
│   ├── foreground_task_handler.dart
│   └── settings_service.dart
├── screens/
│   ├── home_screen.dart
│   ├── settings_screen.dart
│   └── onboarding_screen.dart
├── widgets/
│   ├── countdown_ring.dart
│   ├── rest_reminder_card.dart
│   └── timer_display.dart
└── overlay/
    └── dynamic_island_overlay.dart
```

### 关键技术决策

| 决策            | 选择                            | 理由                                |
| --------------- | ------------------------------- | ----------------------------------- |
| Android 保活    | `flutter_foreground_task`       | 专为前台服务设计，支持 repeat event |
| Android 提醒 UI | `flutter_overlay_window` 灵动岛 | 完全自定义 UI，不打断当前 app       |
| Windows 提醒 UI | `window_manager` 小窗口         | 自定义 UI，支持倒计时动画           |
| 计时算法        | 累积计时 + 分级宽限期           | 避免短暂锁屏重置，贴合真实场景      |
| 主题            | `dynamic_color` + Material 3    | Google 官方，支持动态配色           |

---

## 验证清单

### Android

- [ ] 启动 → 等待到时 → 灵动岛药丸弹出
- [ ] 短暂锁屏（< 20s）→ 解锁 → 计时器继续
- [ ] 锁屏 > 20s → 解锁 → 计时器重置
- [ ] 杀进程 → 前台服务仍运行 → 到时提醒
- [ ] 「延后」→ 指定时间后再次提醒
- [ ] 静音模式 → 无声音仅震动

### Windows

- [ ] 启动 → 等待到时 → 右下角小窗口弹出
- [ ] 无操作超过 20s → 计时器重置
- [ ] 最小化到托盘 → 计时器继续
- [ ] 「延后」/「跳过」行为正确

### 通用

- [ ] 亮/暗主题切换
- [ ] 设置修改立即生效
- [ ] 引导流程完整

---

## 后续迭代方向（不在 MVP 范围）

- 使用统计与可视化图表
- iOS / macOS / Linux 支持
- 番茄钟工作法集成
- 蓝光过滤提醒联动
