# 夜间模式与定点自动深色模式 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现深色模式默认关闭、首次 18:00 后弹窗询问、三选一自动深色模式（关闭/跟随系统/定点）、定点时间可配置。

**Architecture:** 新增 `autoDarkMode`（off/system/timed）统一字段替代 `followSystem`，新增 `timedDarkTime`（默认 18:00）与 `nightModePrompted` 标记。`main.dart` 依据模式动态切换 themeMode，`timed` 模式用定时器在时间边界刷新。首次夜间弹窗在 App 启动/回到前台时触发。

**Tech Stack:** Flutter 3.7.12 (Dart 2.19), shared_preferences, provider

## Global Constraints

- Dart >=2.19.6 <3.0.0
- `autoDarkMode` 三选一：`off`（默认）、`system`、`timed`
- `timedDarkTime` 默认 `"18:00"`，格式 `"HH:mm"`
- `nightModePrompted` 默认 `false`
- 首次弹窗触发条件：`autoDarkMode == 'off'` 且当前时刻 >= 18:00 且 `nightModePrompted == false`
- 弹窗同意 → `autoDarkMode='timed'`、`timedDarkTime='18:00'`、`nightModePrompted=true`
- 弹窗拒绝/超时 → `nightModePrompted=true` + SnackBar 引导到 设置→风格主题
- 旧 `followSystem` 迁移：存在且无 `autoDarkMode` 时，`followSystem==true → autoDarkMode='system'`
- `timed` 模式深色窗口：以 `timedDarkTime` 为起点持续 12 小时（如 18:00→次日 06:00）
- 设置页三选一 UI，选中 `timed` 时显示时间选择器

---

### Task 1: Storage 层新增字段与旧数据迁移

**Files:**
- Modify: `fittrack_flutter/lib/data/storage.dart:1-50`

**Interfaces:**
- Consumes: 无
- Produces: `getSettings()` 返回的 Map 包含 `autoDarkMode`、`timedDarkTime`、`nightModePrompted` 默认值；旧 `followSystem` 自动迁移

- [ ] **Step 1: 修改 getSettings 默认值**

在 `storage.dart` 的 `getSettings()` 方法中，为 `settings` Map 新增三个字段：

```dart
'autoDarkMode': 'off',       // off | system | timed
'timedDarkTime': '18:00',    // "HH:mm"
'nightModePrompted': false,
```

- [ ] **Step 2: 添加旧数据迁移逻辑**

在 `getSettings()` 中，读取完 settings 后添加迁移逻辑：

```dart
// 旧 followSystem 迁移
if (!settings.containsKey('autoDarkMode') && settings.containsKey('followSystem')) {
  settings['autoDarkMode'] = settings['followSystem'] == true ? 'system' : 'off';
}
```

- [ ] **Step 3: 验证编译通过**

Run: `cd fittrack_flutter && flutter analyze`
Expected: 无新增错误

- [ ] **Step 4: Commit**

```bash
git add fittrack_flutter/lib/data/storage.dart
git commit -m "feat(storage): 新增 autoDarkMode/timedDarkTime/nightModePrompted 字段，迁移旧 followSystem"
```

---

### Task 2: 工具函数 isTimedDarkNow

**Files:**
- Modify: `fittrack_flutter/lib/themes/app_themes.dart`

**Interfaces:**
- Consumes: 无
- Produces: `LiftTrackTheme.isTimedDarkNow(String timedDarkTime)` 静态方法

- [ ] **Step 1: 编写测试**

在 `fittrack_flutter/test/themes/app_themes_test.dart`（新建）中：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lifttrack/themes/app_themes.dart';

void main() {
  group('isTimedDarkNow', () {
    test('18:00 起点，18:00 时刻返回 true', () {
      // 需要 mock DateTime.now()
      // 简化：直接测试逻辑
      expect(LiftTrackTheme.isTimedDarkNow('18:00', testNow: DateTime(2026, 8, 18, 18, 0)), isTrue);
    });

    test('18:00 起点，17:59 时刻返回 false', () {
      expect(LiftTrackTheme.isTimedDarkNow('18:00', testNow: DateTime(2026, 8, 18, 17, 59)), isFalse);
    });

    test('18:00 起点，次日 05:59 时刻返回 true', () {
      expect(LiftTrackTheme.isTimedDarkNow('18:00', testNow: DateTime(2026, 8, 19, 5, 59)), isTrue);
    });

    test('18:00 起点，次日 06:00 时刻返回 false', () {
      expect(LiftTrackTheme.isTimedDarkNow('18:00', testNow: DateTime(2026, 8, 19, 6, 0)), isFalse);
    });

    test('无效格式回退 18:00', () {
      expect(LiftTrackTheme.isTimedDarkNow('invalid', testNow: DateTime(2026, 8, 18, 18, 0)), isTrue);
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd fittrack_flutter && flutter test test/themes/app_themes_test.dart`
Expected: FAIL（方法不存在）

- [ ] **Step 3: 实现 isTimedDarkNow**

在 `app_themes.dart` 的 `LiftTrackTheme` 类中添加：

```dart
/// 判断指定时刻是否处于"定点夜间（深色）窗口"内。
/// [timedDarkTime] 格式 "HH:mm"，窗口持续 12 小时。
/// [testNow] 用于测试注入，生产环境传 null 使用 DateTime.now()。
static bool isTimedDarkNow(String timedDarkTime, {DateTime? testNow}) {
  final parts = timedDarkTime.split(':');
  int startHour = 18, startMinute = 0;
  if (parts.length == 2) {
    startHour = int.tryParse(parts[0]) ?? 18;
    startMinute = int.tryParse(parts[1]) ?? 0;
  }
  
  final now = testNow ?? DateTime.now();
  final startMinutes = startHour * 60 + startMinute;
  final nowMinutes = now.hour * 60 + now.minute;
  final endMinutes = (startMinutes + 720) % 1440; // 12 小时后
  
  if (startMinutes < endMinutes) {
    return nowMinutes >= startMinutes && nowMinutes < endMinutes;
  } else {
    // 跨零点
    return nowMinutes >= startMinutes || nowMinutes < endMinutes;
  }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd fittrack_flutter && flutter test test/themes/app_themes_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add fittrack_flutter/lib/themes/app_themes.dart fittrack_flutter/test/themes/app_themes_test.dart
git commit -m "feat(theme): 新增 isTimedDarkNow 工具函数，支持定点深色窗口判定"
```

---

### Task 3: main.dart 主题模式切换与定时器

**Files:**
- Modify: `fittrack_flutter/lib/main.dart:50-120`

**Interfaces:**
- Consumes: `LiftTrackTheme.isTimedDarkNow`、`storage.getSettings()`
- Produces: `_LiftTrackAppState` 中 `_resolveThemeMode()` 方法、`_timedRefreshTimer`

- [ ] **Step 1: 添加 _resolveThemeMode 方法**

在 `_LiftTrackAppState` 中添加：

```dart
ThemeMode _resolveThemeMode(Map<String, dynamic> settings) {
  final autoDarkMode = settings['autoDarkMode'] as String? ?? 'off';
  final theme = settings['theme'] as String? ?? 'ironGym';
  final timedDarkTime = settings['timedDarkTime'] as String? ?? '18:00';
  
  if (autoDarkMode == 'system') {
    return ThemeMode.system;
  } else if (autoDarkMode == 'timed') {
    final isDark = LiftTrackTheme.isTimedDarkNow(timedDarkTime);
    return isDark ? ThemeMode.dark : ThemeMode.light;
  } else {
    // off
    return ThemeMode.light;
  }
}
```

- [ ] **Step 2: 修改 build 方法使用 _resolveThemeMode**

将 `build()` 中的 `themeMode: (settings['followSystem'] as bool? ?? false) ? ThemeMode.system : ThemeMode.light` 替换为：

```dart
themeMode: _resolveThemeMode(settings),
```

- [ ] **Step 3: 添加定时器管理**

在 `_LiftTrackAppState` 中添加字段和方法：

```dart
Timer? _timedRefreshTimer;

void _startTimedRefreshIfNeeded(Map<String, dynamic> settings) {
  _timedRefreshTimer?.cancel();
  final autoDarkMode = settings['autoDarkMode'] as String? ?? 'off';
  if (autoDarkMode == 'timed') {
    _timedRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {}); // 触发 rebuild，重新计算 themeMode
    });
  }
}

@override
void dispose() {
  _timedRefreshTimer?.cancel();
  super.dispose();
}
```

- [ ] **Step 4: 在 initState 和 didChangeDependencies 中启动定时器**

在 `initState()` 末尾添加：

```dart
final settings = storage.getSettings();
_startTimedRefreshIfNeeded(settings);
```

在 `didChangeDependencies()` 的 `storage.addListener(this)` 之后添加：

```dart
_startTimedRefreshIfNeeded(storage.getSettings());
```

- [ ] **Step 5: 验证编译通过**

Run: `cd fittrack_flutter && flutter analyze`
Expected: 无新增错误

- [ ] **Step 6: Commit**

```bash
git add fittrack_flutter/lib/main.dart
git commit -m "feat(main): autoDarkMode 驱动 themeMode，timed 模式定时刷新"
```

---

### Task 4: 首次夜间弹窗

**Files:**
- Modify: `fittrack_flutter/lib/main.dart`

**Interfaces:**
- Consumes: `storage.getSettings()`、`storage.saveSettings()`、`LiftTrackTheme.isTimedDarkNow`
- Produces: `_showNightModePromptIfNeeded()` 方法

- [ ] **Step 1: 编写弹窗方法**

在 `_LiftTrackAppState` 中添加：

```dart
void _showNightModePromptIfNeeded() {
  final settings = storage.getSettings();
  final autoDarkMode = settings['autoDarkMode'] as String? ?? 'off';
  final prompted = settings['nightModePrompted'] as bool? ?? false;
  final timedDarkTime = settings['timedDarkTime'] as String? ?? '18:00';
  
  if (autoDarkMode != 'off' || prompted) return;
  
  final now = DateTime.now();
  final isAfterSix = LiftTrackTheme.isTimedDarkNow(timedDarkTime, testNow: now);
  if (!isAfterSix) return;
  
  // 延迟 1 秒避免与启动动画冲突
  Future.delayed(const Duration(seconds: 1), () {
    if (!mounted) return;
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('已到夜间，是否开启夜间模式？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('暂不开启'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('开启'),
          ),
        ],
      ),
    ).then((result) {
      if (!mounted) return;
      final current = storage.getSettings();
      if (result == true) {
        storage.saveSettings({
          ...current,
          'autoDarkMode': 'timed',
          'timedDarkTime': '18:00',
          'nightModePrompted': true,
        });
      } else {
        storage.saveSettings({
          ...current,
          'nightModePrompted': true,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('你可在 设置→风格主题 中开启『跟随系统』或调整『定点自动深色模式』的触发时间'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  });
}
```

- [ ] **Step 2: 在合适的时机调用**

在 `build()` 方法的 `return MaterialApp(...)` 之前添加：

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  _showNightModePromptIfNeeded();
});
```

在 `didChangeAppLifecycleState` 的 `resumed` 分支中添加：

```dart
_showNightModePromptIfNeeded();
```

- [ ] **Step 3: 验证编译通过**

Run: `cd fittrack_flutter && flutter analyze`
Expected: 无新增错误

- [ ] **Step 4: Commit**

```bash
git add fittrack_flutter/lib/main.dart
git commit -m "feat(main): 首次 18:00 后弹窗询问夜间模式，同意开启 timed，拒绝引导到设置"
```

---

### Task 5: 设置页三选一 UI

**Files:**
- Modify: `fittrack_flutter/lib/pages/theme_settings_page.dart`
- Modify: `fittrack_flutter/lib/router.dart:120-140`

**Interfaces:**
- Consumes: `storage.getSettings()`、`storage.saveSettings()`
- Produces: 三选一 UI、时间选择器、新 `onThemeChanged` 签名

- [ ] **Step 1: 修改 onThemeChanged 签名**

在 `router.dart` 中，将 `onThemeChanged` 方法签名改为：

```dart
void onThemeChanged(String themeId, {
  String? autoDarkMode,
  String? timedDarkTime,
  String? lightThemeId,
  String? darkThemeId,
})
```

在方法体中，构建新的 settings Map：

```dart
final current = storage.getSettings();
final updated = {
  ...current,
  'theme': themeId,
};
if (autoDarkMode != null) updated['autoDarkMode'] = autoDarkMode;
if (timedDarkTime != null) updated['timedDarkTime'] = timedDarkTime;
if (lightThemeId != null) updated['lightThemeId'] = lightThemeId;
if (darkThemeId != null) updated['darkThemeId'] = darkThemeId;
storage.saveSettings(updated);
```

- [ ] **Step 2: 修改 ThemeSettingsPage 构造参数**

将 `ThemeSettingsPage` 的 `followSystem` 参数替换为 `autoDarkMode` 和 `timedDarkTime`：

```dart
class ThemeSettingsPage extends StatefulWidget {
  final String themeId;
  final String autoDarkMode;
  final String timedDarkTime;
  final String lightThemeId;
  final String darkThemeId;
  final void Function(String, {String?, String?, String?, String?}) onThemeChanged;
  // ...
}
```

- [ ] **Step 3: 实现三选一 UI**

在 `_ThemeSettingsPageState` 中，将「跟随系统」开关替换为三选一 RadioListTile：

```dart
Card(
  child: Column(
    children: [
      RadioListTile<String>(
        title: const Text('关闭'),
        subtitle: const Text('始终使用浅色主题'),
        value: 'off',
        groupValue: widget.autoDarkMode,
        onChanged: (v) => widget.onThemeChanged(widget.themeId, autoDarkMode: v),
      ),
      RadioListTile<String>(
        title: const Text('跟随系统'),
        subtitle: const Text('根据系统设置自动切换'),
        value: 'system',
        groupValue: widget.autoDarkMode,
        onChanged: (v) => widget.onThemeChanged(widget.themeId, autoDarkMode: v),
      ),
      RadioListTile<String>(
        title: const Text('定点自动'),
        subtitle: const Text('到点后自动切换深色'),
        value: 'timed',
        groupValue: widget.autoDarkMode,
        onChanged: (v) => widget.onThemeChanged(widget.themeId, autoDarkMode: v),
      ),
    ],
  ),
)
```

- [ ] **Step 4: 添加时间选择器**

在 `timed` 选项下方，条件显示时间选择器：

```dart
if (widget.autoDarkMode == 'timed')
  ListTile(
    title: const Text('触发时间'),
    subtitle: Text(widget.timedDarkTime),
    trailing: const Icon(Icons.schedule),
    onTap: () async {
      final now = DateTime.now();
      final parts = widget.timedDarkTime.split(':');
      final initialTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 18,
        minute: int.tryParse(parts[1]) ?? 0,
      );
      final picked = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );
      if (picked != null) {
        final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        widget.onThemeChanged(widget.themeId, timedDarkTime: timeStr);
      }
    },
  )
```

- [ ] **Step 5: 修改路由传参**

在 `router.dart` 的 `theme-settings` 路由中，从 settings 读取新字段并传入：

```dart
final autoDarkMode = settings['autoDarkMode'] as String? ?? 'off';
final timedDarkTime = settings['timedDarkTime'] as String? ?? '18:00';
return ThemeSettingsPage(
  themeId: theme,
  autoDarkMode: autoDarkMode,
  timedDarkTime: timedDarkTime,
  lightThemeId: lightThemeId,
  darkThemeId: darkThemeId,
  onThemeChanged: onThemeChanged,
);
```

- [ ] **Step 6: 验证编译通过**

Run: `cd fittrack_flutter && flutter analyze`
Expected: 无新增错误

- [ ] **Step 7: Commit**

```bash
git add fittrack_flutter/lib/pages/theme_settings_page.dart fittrack_flutter/lib/router.dart
git commit -m "feat(settings): 自动深色模式三选一 UI，timed 模式可配置触发时间"
```

---

### Task 6: 集成测试与回归

**Files:**
- Modify: `fittrack_flutter/test/` (如有现有测试需适配)

**Interfaces:**
- Consumes: 所有前序任务产出
- Produces: 完整功能验证

- [ ] **Step 1: 运行全量测试**

Run: `cd fittrack_flutter && flutter test`
Expected: 所有测试通过

- [ ] **Step 2: 手动验证场景**

启动 App，验证：
1. 默认浅色主题
2. 18:00 后首次启动弹窗，同意→变深色，拒绝→SnackBar 提示
3. 设置→风格主题，三选一切换正常，timed 模式时间选择器可用
4. timed 模式下，到点后自动变深色

- [ ] **Step 3: Commit**

```bash
git add .
git commit -m "test: 夜间模式与定点自动深色模式集成验证"
```
