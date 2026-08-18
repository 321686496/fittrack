# 夜间模式 + 定点自动深色模式 设计

日期：2026-08-18
范围：fittrack_flutter/ 下的 Flutter 客户端

## 背景与目标

现有主题系统只有 `followSystem`（布尔）区分「跟随系统」与否，无独立的夜间/深色模式概念，
也没有首次夜间引导。本次新增：

1. 深色模式默认关闭。
2. 用户首次在 18:00 之后打开 App 时，弹出一次询问「是否开启夜间模式」。
   - 同意 → 开启「定点自动深色」。
   - 拒绝 / 超时 → 提示如何在设置里开启自动深色模式。
3. 新增设置项：可配置「定点自动夜间模式」的触发时间（默认 18:00）。
4. 该设置与现有「跟随系统」合并为一个三选一的「自动深色模式」，避免两套规则冲突。

## 概念模型

新增统一设置字段 `autoDarkMode`，三选一：

| 取值 | 名称 | 行为 |
|------|------|------|
| `off`（默认） | 关闭 | `ThemeMode.light`，使用用户手选的 `theme` |
| `system` | 跟随系统 | `ThemeMode.system`，日间=lightThemeId / 夜间=darkThemeId（等价原「跟随系统」） |
| `timed` | 定点自动 | 到点后强制深色；日间=lightThemeId / 夜间=darkThemeId |

新增辅助字段：

- `timedDarkTime`：定点触发时刻（`"HH:mm"`，默认 `"18:00"`），可配置。
- `nightModePrompted`：标记首次夜间弹窗是否已弹过（布尔，默认 `false`）。

## 存储

`storage.dart` getSettings 默认值新增：

```dart
'autoDarkMode': 'off',       // off | system | timed
'timedDarkTime': '18:00',    // "HH:mm"
'nightModePrompted': false,
```

旧字段 `followSystem`：不再作为驱动字段。为兼容旧数据，初始化时可做一次迁移：
读取时若 `followSystem` 存在且无 `autoDarkMode`，则 `followSystem==true → autoDarkMode='system'`。
（`theme`、`lightThemeId`、`darkThemeId` 三个字段语义不变，继续复用。）

## 夜间时段判定

`timed` 模式下，深色窗口以 `timedDarkTime` 为起点、持续 12 小时：
例：`18:00 → 次日 06:00` 为深色，其余为日间。

工具函数（放 `app_themes.dart` 的 `LiftTrackTheme`）：

```dart
/// 判断当前时刻是否处于"定点夜间（深色）窗口"内。
bool isTimedDarkNow(String timedDarkTime) {
  // 解析 "HH:mm"，若当前 tta 位于 [start, start + 12h) 则返回 true
}
```

## 首次夜间弹窗

触发条件（App 启动后首帧后，以及回到前台时判断），需同时满足：

1. `autoDarkMode == 'off'`（用户尚未配置自动深色）；且
2. 本地当前时刻 >= 18:00（后续统一以 `timedDarkTime` 默认为 18:00 判断，允许将来调整）；且
3. `nightModePrompted` 为 `false`。

弹窗（Dialog）文案：

- 标题：已到夜间，是否开启夜间模式？
- 「开启」：持久化 `autoDarkMode='timed'`、`timedDarkTime='18:00'`、`nightModePrompted=true`，
  立即依当前时刻切到深色，并刷新主题。
- 「暂不」/ 超时（约 8 秒自动消失）：持久化 `nightModePrompted=true`，然后 SnackBar 提示：
  「你可在 设置→风格主题 中开启『跟随系统』，或调整『定点自动深色模式』的触发时间」。

无论同意或拒绝，之后 `nightModePrompted` 均为 true，不再弹窗。

## 设置页（风格主题）

`theme_settings_page.dart`：

- 将原「跟随系统」开关替换为「自动深色模式」三选一（关闭 / 跟随系统 / 定点）。
- 选中「定点」时，新增一行「触发时间」可配置（默认 `18:00`，按分钟设置，复用现有时间选择器）。
- 日间/夜间主题选择保持不变；仅在 `system`/`timed` 模式下展示日间/夜间主题选择。

回调签名演进：

```dart
void onThemeChanged(String themeId, {
  String? autoDarkMode,       // 取代 followSystem
  String? timedDarkTime,
  String? lightThemeId,
  String? darkThemeId,
})
```

## 联动生效（main.dart）

- 启动时读取 `autoDarkMode`，决定 `themeMode`：
  - `off` → `ThemeMode.light`，theme=`theme`。
  - `system` → `ThemeMode.system`，theme=light / darkTheme=dark。
  - `timed` → 依据 `isTimedDarkNow(timedDarkTime)` 选择 `ThemeMode.dark/light`，theme=light / darkTheme=dark。
- `timed` 模式下需要动态刷新：启动、回到前台（`didChangeAppLifecycleState` resumed）、
  以及跨越时间边界时刷新。用一个轻量 `Timer.periodic`（如每分钟）在 `timed` 模式探测边界切换，
  非 `timed` 模式停止计时器。涉及 `mounted` 保护与资源释放（dispose）。

## 涉及文件

- `lib/data/storage.dart`：新增默认值 + 旧 `followSystem` 迁移。
- `lib/themes/app_themes.dart`：新增 `LiftTrackTheme.isTimedDarkNow`、模式常量。
- `lib/main.dart`：`autoDarkMode` 驱动 themeMode；首次夜间弹窗；定点时刻刷新。
- `lib/pages/theme_settings_page.dart`：三选一 + 触发时间设置。
- `lib/pages/settings_page.dart`：适配新回调/新字段。
- `lib/router.dart`：`onThemeChanged` 签名与 theme-settings 参数更新。

## 错误处理与兼容

- 时间解析失败（非 `"HH:mm"`）时回退为 `18:00`，不崩溃。
- 旧数据迁移：存在 `followSystem` 且无 `autoDarkMode` 时按上文映射。
- 定时器在 `dispose` 与切离 `timed` 模式时取消，避免泄漏。

## 测试要点

- `isTimedDarkNow` 的边界：跨零点、正好等于起点、起点 12 小时后。
- 首次弹窗触发：off + ≥18:00 + 未弹过 → 弹出；已弹过或白天 → 不弹。
- 同意/拒绝/超时分别写入正确设置。
- 三选一切换对 `themeMode` 的映射。