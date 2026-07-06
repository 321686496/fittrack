# FitTrack Code Wiki — 项目代码百科

> **项目名称**: FitTrack（燃力）— 健身训练追踪应用
> **仓库名**: health_training
> **版本**: 1.0.0
> **本地路径**: `D:\app\projects\health_training`

---

## 目录

1. [项目概述](#1-项目概述)
2. [仓库整体结构](#2-仓库整体结构)
3. [整体架构与分层](#3-整体架构与分层)
4. [子项目结构](#4-子项目结构)
5. [主要模块职责](#5-主要模块职责)
6. [关键类与函数说明](#6-关键类与函数说明)
7. [数据流与状态管理](#7-数据流与状态管理)
8. [依赖关系](#8-依赖关系)
9. [主题系统](#9-主题系统)
10. [平台特定功能](#10-平台特定功能)
11. [数据库设计](#11-数据库设计)
12. [项目运行方式](#12-项目运行方式)
13. [附录：Settings 默认值](#13-附录settings-默认值)

---

## 1. 项目概述

FitTrack 是一款面向健身爱好者的多平台训练追踪应用，采用**纯本地单机**架构（数据全部存储在设备本地，不上传服务器）。核心功能包括：

- **训练计划管理** — 创建、编辑、执行训练计划（支持多分化方案）
- **训练执行与记录** — 组间休息倒计时、训练数据实时记录
- **统计与进度追踪** — 周度训练统计、肌肉分布分析
- **多主题支持** — 7 套视觉主题（活力运动、硬核铁馆、柔美花语、长者关怀、清新极简、赛博霓虹、黑金尊享）
- **HarmonyOS 桌面卡片** — 实时显示训练进度与今日概览（仅 OHOS）
- **休息提醒通知** — 前台振动 + 后台代理提醒双机制
- **健身卡管理** — 管理健身房会员卡信息
- **问卷与个性化推荐** — 新用户问卷引导，自动生成用户名 / 头像

### 目标平台

| 平台 | 实现方式 | 说明 |
|------|---------|------|
| HarmonyOS (OHOS) | Flutter + 原生 ArkTS 扩展 | 主要目标平台 |
| Android | Flutter | 支持 |
| iOS / macOS / Windows / Linux / Web | Flutter | 由 Flutter 脚手架生成的壳，主要用于运行/调试 |

---

## 2. 仓库整体结构

本仓库并非单一工程，而是同一款应用的**三个并行实现 + 文档**：

```
health_training/
├── fittrack_flutter/     ← 【主力版本】Flutter，功能最全（SQLite + 全部服务/页面）
├── fittrack_flutter2/    ← 【精简版本】Flutter，仅 SharedPreferences，基础页面
├── FitTrackHarmony/      ← 【原生 HarmonyOS 版】ArkTS / ETS 实现
├── README.md             ← 仓库说明（Gitee 模板）
├── README.en.md          ← 英文说明
├── LogoDesign.md         ← Logo 设计说明
├── analyze_output.txt    ← flutter analyze 输出记录
└── CODE_WIKI.md          ← 本文档
```

> 说明：三个子项目共享相同的产品设计与主题体系，但技术栈与完成度不同。`fittrack_flutter` 是理解本项目的核心入口。

---

## 3. 整体架构与分层

以主力版本 `fittrack_flutter` 为例，采用经典分层结构，**未引入独立状态管理框架**（Provider/Bloc/Riverpod），而是通过 `Storage` 内存缓存 + `ValueNotifier` + `setState` 组合管理状态。

```
┌───────────────────────────────────────────────┐
│                  UI 层 (pages/)                 │
│  HomePage / TrainingPage / StatsPage / ...      │
├───────────────────────────────────────────────┤
│              路由层 (router.dart)                │
│      go_router (ShellRoute + 独立子路由)         │
├───────────────────────────────────────────────┤
│             通用组件 (widgets/)                  │
│  BottomNav / StatCard / ConfirmDialog / ...     │
├───────────────────────────────────────────────┤
│              服务层 (services/)                  │
│  RestNotification / FormKit / Permission /      │
│  OhosReminder / UserProfileGenerator            │
├───────────────────────────────────────────────┤
│               数据层 (data/)                     │
│  Storage(内存缓存) + DatabaseHelper(SQLite)      │
│  + SharedPreferences(轻量 KV)                   │
├───────────────────────────────────────────────┤
│            原生桥接 (MethodChannel) [OHOS]        │
│  Form Channel / Reminder Channel                │
└───────────────────────────────────────────────┘
```

---

## 4. 子项目结构

### 4.1 fittrack_flutter（主力版本）

```
lib/
├── main.dart                       ← 入口：初始化 Storage / 权限 / 通知 / 卡片，构建 FitTrackApp
├── router.dart                     ← go_router 路由配置 + AppShell（IndexedStack 底部导航）
├── data/
│   ├── storage.dart                ← 混合持久化层（SQLite + SharedPreferences + 内存缓存）
│   ├── database_helper.dart        ← SQLite 数据库管理（plans / records / gym_cards 三张表）
│   └── mock_data.dart              ← 静态 Mock 数据（动作库、问卷等）
├── pages/                          ← 15 个页面
│   ├── splash_page.dart            ← 启动动画页
│   ├── onboarding_page.dart        ← 新手引导页
│   ├── questionnaire_page.dart     ← 健身问卷页
│   ├── plan_recommend_page.dart    ← 计划推荐页
│   ├── home_page.dart              ← 首页（今日概览 + 快捷入口）
│   ├── plan_page.dart              ← 计划列表页
│   ├── training_page.dart          ← 训练执行页（核心页面）
│   ├── exercise_page.dart          ← 动作详情页
│   ├── stats_page.dart             ← 统计分析页
│   ├── records_page.dart           ← 训练记录页
│   ├── profile_page.dart           ← 个人中心页
│   ├── settings_page.dart          ← 设置页（含主题切换）
│   ├── reminder_settings_page.dart ← 提醒设置页
│   ├── notification_test_page.dart ← 通知测试页
│   └── gym_card_page.dart          ← 健身卡管理页
├── services/
│   ├── rest_notification_service.dart ← 休息结束通知服务
│   ├── form_kit_service.dart          ← OHOS 桌面卡片服务
│   ├── ohos_reminder_service.dart     ← OHOS 后台代理提醒服务
│   ├── permission_service.dart        ← 权限管理服务
│   └── user_profile_generator.dart    ← 用户名 / 头像生成器
├── themes/
│   └── app_themes.dart             ← 7 套主题 + FitTrackColors ThemeExtension
└── widgets/
    ├── bottom_nav.dart             ← 底部导航栏（悬浮胶囊样式）
    ├── common_widgets.dart         ← 通用组件库
    └── page_header.dart            ← 页面标题组件

平台壳目录：android/ ios/ ohos/ macos/ windows/ linux/ web/
```

### 4.2 fittrack_flutter2（精简版本）

与主力版本结构类似，但功能收敛：

```
lib/
├── main.dart          ← 入口（含 SplashScreen 动画 + AppShell），直接用 MaterialApp（无 go_router）
├── data/
│   ├── storage.dart   ← 精简版 Storage（仅 SharedPreferences，plans/records 以 JSON 存储，无 SQLite）
│   └── mock_data.dart ← 精简版 Mock 数据
├── pages/             ← 8 个基础页面（exercise / home / plan / profile / records / settings / stats / training）
├── services/
│   └── permission_service.dart
├── themes/
│   └── app_themes.dart
└── widgets/           ← bottom_nav / common_widgets / page_header
```

**与主力版本的关键差异**：
- 存储：仅 `SharedPreferences`（无 SQLite、无 `database_helper.dart`）。
- 路由：直接使用 `MaterialApp` + 自定义 `AppShell`（无 `go_router`、无 `router.dart`）。
- 无问卷 / 引导 / 提醒 / 健身卡 / 桌面卡片等高级功能。

### 4.3 FitTrackHarmony（原生 HarmonyOS 版）

纯 ArkTS/ETS 实现，使用 DevEco Studio + hvigor 构建。

```
entry/src/main/ets/
├── pages/
│   ├── Index.ets          ← 主入口（Tabs 导航，5 个 Tab）
│   ├── HomePage.ets        ← 首页
│   ├── PlanPage.ets        ← 计划页
│   ├── StatsPage.ets       ← 统计页
│   ├── ExercisePage.ets    ← 动作页
│   ├── ProfilePage.ets     ← 个人中心
│   ├── SettingsPage.ets     ← 设置页
│   └── TrainingPage.ets    ← 训练页
├── components/
│   ├── PageHeader.ets       ← 页面标题
│   ├── ProgressIndicator.ets← 进度指示器
│   ├── SectionHeader.ets    ← 区域标题
│   ├── StatCard.ets         ← 统计卡片
│   └── TagBadge.ets         ← 标签徽章
├── common/
│   ├── ThemeConstants.ets   ← 主题常量（ThemeColors 类 + 主题定义）
│   └── MockData.ets         ← Mock 数据
├── entryability/
│   └── EntryAbility.ets     ← 应用入口 Ability
└── entrybackupability/
    └── EntryBackupAbility.ets ← 备份/恢复扩展 Ability
```

---

## 5. 主要模块职责

### 5.1 数据层 (data/) — 以主力版本为准

| 模块 | 职责 | 存储方式 |
|------|------|---------|
| `Storage` | 统一数据访问层，提供同步/异步双接口 + 内存缓存 | 内存缓存 + SQLite + SharedPreferences |
| `DatabaseHelper` | SQLite 数据库管理，三张表的 CRUD 与行↔Map 转换 | SQLite (`fittrack.db`, v2) |
| `MockData` | 开发阶段静态测试数据（动作库、问卷等） | 硬编码常量 |

**数据分流策略**：
- **Plans / Records / GymCards** → SQLite（结构化数据，需要查询与索引）。
- **Settings / Stats / BodyData** → SharedPreferences（简单键值对，序列化为 JSON 字符串）。
- **内存缓存** → 启动时预加载到内存；同步接口直接操作缓存并异步落盘，`*CacheDirty` 标记控制何时从 SQLite 重新加载。

### 5.2 服务层 (services/)

| 服务 | 职责 | 关键能力 |
|------|------|---------|
| `RestNotificationService` | 休息结束提醒 | Dart Timer（前台保底）+ Android `zonedSchedule` + OHOS 代理提醒 + 增强振动 |
| `FormKitService` | OHOS 桌面卡片 | 三态管理（idle / training / rest）+ 主题色同步 |
| `OhosReminderService` | OHOS 后台代理提醒 | `reminderAgentManager` + 每日训练定时提醒 + 通知/卡片点击监听 |
| `PermissionService` | 权限管理 | 通知权限申请 + 拒绝引导弹窗 |
| `UserProfileGenerator` | 用户个性化生成 | 基于问卷生成用户名 + 头像配置 |

### 5.3 通用组件库 (widgets/)

| 组件 | 用途 |
|------|------|
| `BottomNav` | 底部导航栏（悬浮胶囊样式，5 个 Tab） |
| `PageHeader` | 页面标题（返回 + 标题 + 操作） |
| `common_widgets.dart` | 通用组件集合：区域标题、统计卡片、徽章、进度条、卡片容器、菜单按钮、空状态、Toast、确认/信息/成就弹窗、底部弹窗、输入框、Chip 选择器等 |

---

## 6. 关键类与函数说明

### 6.1 入口与初始化 — `main.dart`

`main()` 使用 `runZonedGuarded` 包裹整个应用以捕获未处理异常，启动流程：

1. `WidgetsFlutterBinding.ensureInitialized()` + 注册 `FlutterError.onError`
2. `tz_data.initializeTimeZones()` — 初始化时区（必须在通知服务前）
3. `Storage.init()` — 初始化混合持久化并执行 SP→SQLite 迁移
4. 预加载 `getPlansAsync()` / `getRecordsAsync()` / `getGymCardsAsync()` 填充缓存
5. `PermissionService.requestCorePermissions()` — 异步请求通知权限（不阻塞启动）
6. `RestNotificationService.instance.init()` — 初始化通知渠道
7. **[OHOS]** `FormKitService.instance.init()`、`OhosReminderService.instance.initListener()`、注册卡片点击回调、`_scheduleTrainingReminderIfNeeded()`
8. `runApp(FitTrackApp())`

`FitTrackApp`（`StatefulWidget`）持有 `_currentThemeId` 与 `GoRouter` 实例，`build` 返回 `MaterialApp.router`。主题切换回调 `_onThemeChanged` 会 `setState` + `Storage.saveSettings` + **[OHOS]** 同步卡片主题。

### 6.2 路由系统 — `router.dart`

`createRouter()` 返回 `GoRouter`，`initialLocation: '/splash'`。路由结构：

```
/splash          → SplashPage（启动页）
/privacy         → _PrivacyPolicyPage（隐私政策）
/onboarding      → OnboardingPage（新手引导）
/questionnaire   → QuestionnairePage（健身问卷）
/recommend       → PlanRecommendPage（计划推荐，接收 extra 问卷数据）
── ShellRoute（带底部导航栏）──────────────
  /home    → HomePage      /plan    → PlanPage
  /records → RecordsPage    /stats   → StatsPage
  /profile → ProfilePage
── 独立路由（root navigator，无底部导航栏）──
  /training（?planId&dayIndex） / /exercise / /settings
  /notification-test / /reminder-settings / /gym-card
```

- **AppShell**：使用 `IndexedStack` 缓存 5 个 Tab 页面并保持存活，避免反复创建/销毁导致的 Ink splash 崩溃。
- `currentTabIndex`（`ValueNotifier<int>`）根据当前路径推导高亮 Tab。
- `onThemeChanged`（顶层可空回调）由 `main.dart` 注入，供 `SettingsPage` 触发主题切换。

### 6.3 数据存储 — `Storage`（`data/storage.dart`）

核心方法（同步方法操作内存缓存并异步落盘，`*Async` 方法直接读写数据库）：

| 方法 | 说明 |
|------|------|
| `Future<void> init()` | 初始化 SP + 加载轻量数据 + `_migrateFromPrefsIfNeeded()` 迁移旧 Plans/Records 到 SQLite |
| `String generateId(prefix)` | 生成唯一 ID：`{prefix}_{timestamp}_{base36随机}` |
| `getWeekKey(timestamp)` | 基于 ISO 周计算周键（`yyyy-Www`），用于统计聚合 |
| `getPlansAsync()` / `getPlans()` | 异步加载 / 同步读缓存 计划 |
| `addPlan()` / `updatePlan()` / `deletePlan()` | 计划的同步 CRUD（+ `*Async` 版本） |
| `addRecord()` | 添加记录 + 缓存限 500 条 + `dataChanged` 通知 + `trimRecords(500)` + `updateStats()` |
| `updateStats(record)` | 增量更新统计（总次数/时长/重量/组数、周数据、肌群分布） |
| `recalcStatsAsync()` | 从全部记录重新计算统计 |
| `getSettings()` / `saveSettings()` | 设置读写（含默认值） |
| `getStats()` / `getBodyData()` / `saveBodyData()` | 统计与身体数据读写 |
| `addGymCard()` / `updateGymCard()` / `deleteGymCard()` | 健身卡 CRUD |
| `exportAllDataAsync()` / `importDataAsync()` | 数据导出 / 导入（含同步兼容版本） |
| `clearAll()` | 清空全部数据 |
| `initDemoData()` | 首次启动时初始化演示计划（三分化增肌 + 新手入门） |

**缓存与通知**：`_plansCache` / `_recordsCache` / `_gymCardsCache` + `_*CacheDirty` 脏标记；`dataChanged`（`ValueNotifier<bool>`）用于跨页面数据变更通知。

### 6.4 数据库 — `DatabaseHelper`（`data/database_helper.dart`）

单例（`DatabaseHelper._()` + `instance`），管理 `fittrack.db`（version 2）：

| 方法 | 说明 |
|------|------|
| `Future<Database> get database` | 懒加载获取数据库实例 |
| `_onCreate()` | 建表 `plans` / `records` / `gym_cards` + 索引 |
| `_onUpgrade()` | v1→v2 升级：新增 `gym_cards` 表及索引 |
| `getAllPlans/insertPlan/updatePlan/deletePlan/deleteAllPlans` | Plans CRUD |
| `getAllRecords/insertRecord/deleteRecord/deleteAllRecords/trimRecords` | Records CRUD（`trimRecords` 保留最近 N 条） |
| `getAllGymCards/insertGymCard/updateGymCard/deleteGymCard/deleteAllGymCards` | GymCards CRUD |

**行↔Map 转换**：`days`（plans）、`muscles` / `setRecords` / `restLog`（records）以 JSON 字符串存储，读取时反序列化；写入 plans 时移除非数据库字段 `icon` / `desc`。

### 6.5 通知服务 — `RestNotificationService`

三重提醒机制（前台 Dart Timer 保底 + 平台原生定时）：

| 方法 | 说明 |
|------|------|
| `init()` | 初始化通知渠道 + 请求权限 + 配置时区 |
| `scheduleRestEndNotification(exerciseName, delaySeconds)` | 预约定时通知（Android `zonedSchedule` / OHOS 代理提醒 / Dart Timer） |
| `showRestEndNotification(exerciseName)` | 立即显示通知 |
| `cancelScheduledNotification()` | 取消预约通知 |
| `vibrate()` | 增强振动提醒 |

### 6.6 桌面卡片 — `FormKitService`（仅 OHOS）

卡片三态：`idle`（今日概览 + 连续打卡）/ `training`（当前动作/组数/进度）/ `rest`（倒计时）。数据流见 [第 10 节](#10-平台特定功能)。

### 6.7 后台代理提醒 — `OhosReminderService`（仅 OHOS）

通过 MethodChannel 调用原生 `reminderAgentManager`：`initListener()`、`publishReminder(...)`、`cancelCurrentReminder()`、`scheduleTrainingReminder(title, content, timeStr)`、`cancelTrainingReminder()`；并通过 `onCardClick` 处理卡片/通知点击导航。

### 6.8 用户档案生成 — `UserProfileGenerator`

`generateUserName(...)` / `generateUserNameOptions(...)` / `generateAvatar(...)` / `buildAvatarWidget(config)`，根据性别/目标/水平生成个性化用户名与头像。

### 6.9 权限服务 — `PermissionService`

`requestNotification()` / `isNotificationGranted()` / `requestCorePermissions()` / `showPermissionDeniedDialog(...)`。

---

## 7. 数据流与状态管理

### 7.1 状态管理方案

- **内存缓存** — `Storage` 维护所有数据的缓存列表。
- **ValueNotifier** — `Storage.dataChanged` 跨页面通知数据变更；`currentTabIndex` 管理导航高亮。
- **setState** — 页面内部状态。
- **GoRouter** — 路由状态（仅主力版本）。

### 7.2 核心数据流

```
用户操作 (UI)
  → 页面 State 方法
    → Storage 同步方法（更新内存缓存）
      → 异步持久化到 SQLite / SharedPreferences
      → Storage.dataChanged 通知其他页面刷新
    → [OHOS] FormKitService.pushFormData()（同步桌面卡片）
```

### 7.3 主题变更流

```
SettingsPage 切换主题
  → onThemeChanged(themeId)
    → FitTrackApp.setState()（重建 MaterialApp）
    → Storage.saveSettings()（持久化）
    → [OHOS] FormKitService.pushFormData()（同步卡片颜色）
```

---

## 8. 依赖关系

### 8.1 fittrack_flutter（`pubspec.yaml`）

> Flutter SDK 约束：`sdk: '>=2.19.6 <3.0.0'`。部分包为适配 HarmonyOS 使用 **gitcode 上的 OHOS 定制分支**。

| 依赖 | 来源/版本 | 用途 |
|------|-----------|------|
| `flutter` | SDK | UI 框架 |
| `shared_preferences` | gitcode（OHOS 定制） | 轻量键值存储 |
| `sqflite` | gitcode（CPF-Flutter） | SQLite 数据库 |
| `permission_handler` | gitcode（CPF-Flutter） | 权限管理 |
| `flutter_local_notifications` | gitcode（OHOS SIG） | 本地通知 |
| `go_router` | ^6.5.0 | 声明式路由 |
| `timezone` | ^0.9.4 | 时区支持（定时通知） |
| `path` | ^1.8.0 | 路径拼接 |
| `cupertino_icons` | ^1.0.2 | iOS 风格图标 |
| `flutter_lints`（dev） | ^2.0.0 | 代码规范 |

### 8.2 fittrack_flutter2（`pubspec.yaml`）

| 依赖 | 版本 | 用途 |
|------|------|------|
| `flutter` | SDK | UI 框架 |
| `shared_preferences` | ^2.1.1 | 本地存储（唯一持久化方式） |
| `permission_handler` | ^11.0.1 | 权限管理 |
| `permission_handler_ohos` | ^0.0.8 | OHOS 权限适配 |
| `cupertino_icons` | ^1.0.2 | 图标 |
| `flutter_lints`（dev） | ^2.0.0 | 代码规范 |

### 8.3 FitTrackHarmony（`oh-package.json5` / `build-profile.json5`）

- 运行时：`runtimeOS: HarmonyOS`
- `targetSdkVersion`: 6.1.0(23)，`compatibleSdkVersion`: 5.1.0(18)
- 构建：hvigor；模块：`entry`；无第三方运行时依赖（测试使用 `@ohos/hypium` + `@ohos/hamock`）。

### 8.4 模块间依赖（主力版本）

```
main.dart
├── data/storage.dart ──→ data/database_helper.dart ──→ sqflite
├── services/permission_service.dart ──→ permission_handler
├── services/rest_notification_service.dart ──→ flutter_local_notifications / timezone / ohos_reminder_service.dart
├── services/form_kit_service.dart ──→ data/storage.dart（+ MethodChannel）
├── router.dart ──→ pages/* + widgets/bottom_nav.dart
└── themes/app_themes.dart

pages/*
├──→ data/storage.dart
├──→ themes/app_themes.dart
├──→ widgets/common_widgets.dart
└──→ services/*（按需）
```

---

## 9. 主题系统

### 9.1 Flutter 版：`FitTrackColors` ThemeExtension

`app_themes.dart` 中 `AppTheme.getTheme(String themeId)` 根据 ID 返回对应 `ThemeData`，并通过 `ThemeExtension<FitTrackColors>` 挂载扩展色板。组件统一访问方式：

```dart
final colors = Theme.of(context).extension<FitTrackColors>()!;
colors.bgCard;      // 卡片背景
colors.accentGlow;  // 主强调色
colors.textPrimary; // 主文本色
```

扩展字段包含：`bgSecondary` / `bgCard` / `bgElevated` / `accentGlow` / `accentSecondary` / `textPrimary` / `textSecondary` / `textMuted` / `borderColor` / `successColor` / `warningColor` / `infoColor` / `purpleColor` 等。

### 9.2 主题清单（Flutter 版 7 套）

| 主题 ID | 名称 | 风格 | 亮度 |
|---------|------|------|------|
| `vitality-sport` | 活力运动 | 动感橙色，大圆角（默认主题） | Light |
| `iron-forge` | 硬核铁馆 | 粗犷暗黑，零圆角 | Dark |
| `blossom` | 柔美花语 | 粉色柔和，大圆角 | Light |
| `silver-care` | 长者关怀 | 大字高对比，绿色系 | Light |
| `fresh-minimal` | 清新极简 | 大量留白，天蓝色 | Light |
| `neon-cyber` | 赛博霓虹 | 霓虹发光，深紫暗色 | Dark |
| `black-gold` | 黑金尊享 | 金色奢华，暗色底 | Dark |

`AppTheme.dark` = `iron-forge`，`AppTheme.light` = `vitality-sport`。

### 9.3 HarmonyOS 版主题

`ThemeConstants.ets` 定义 `ThemeColors` 类（含颜色、圆角、间距、字重、导航高度等完整设计令牌）与 `createTheme(...)` 工厂。原生版当前定义 6 套主题：`iron-forge`、`blossom`、`silver-care`、`fresh-minimal`、`neon-cyber`、`black-gold`（相较 Flutter 版少了 `vitality-sport`）。

---

## 10. 平台特定功能

### 10.1 HarmonyOS (OHOS) 专属

**桌面卡片 (Form Kit)** — MethodChannel 通道，数据流：

```
Flutter (FormKitService._buildFormData())
  → MethodChannel（form 通道）
    → EntryAbility (updateFormData)
      → preferences（跨进程共享）
        → FormExtensionAbility (onUpdateForm)
          → 桌面卡片渲染
卡片点击：FormExtension → postCardAction → EntryAbility → MethodChannel → Flutter(onCardClick)
```

**后台代理提醒 (ReminderAgent)** — 通过 MethodChannel 调用原生 `reminderAgentManager`，需要权限 `ohos.permission.PUBLISH_AGENT_REMINDER`。

**平台判断**：`if (Platform.isOhos) { ... }`。

### 10.2 Android 专属

- `zonedSchedule` 定时通知（后台可靠触发）
- 高优先级通知渠道 + 振动
- 全屏通知 `fullScreenIntent`

---

## 11. 数据库设计（fittrack_flutter，SQLite `fittrack.db` v2）

### 11.1 `plans` 表

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | TEXT PK | 计划 ID（`plan_{ts}_{rand}`） |
| `name` | TEXT NOT NULL | 计划名称 |
| `type` | TEXT | 类型（三分化 / 全身训练等） |
| `difficulty` | TEXT | 难度（入门 / 进阶 / 高级） |
| `frequency` | TEXT | 频率（3天/周、6天/周等） |
| `totalWeeks` | INTEGER | 总周数（默认 8） |
| `defaultRestTime` | INTEGER | 默认休息时间（秒，默认 90） |
| `week` | INTEGER | 当前周 |
| `progress` | INTEGER | 进度百分比 |
| `status` | TEXT | 状态（active / done / pending） |
| `badge` | TEXT | 标签（进行中 / 已完成 / 待开始） |
| `days` | TEXT | 每日训练内容（JSON 数组） |
| `createTime` / `updateTime` | INTEGER | 时间戳 |

索引：`idx_plans_status`

### 11.2 `records` 表

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | TEXT PK | 记录 ID（`record_{ts}_{rand}`） |
| `name` | TEXT | 训练名称 |
| `date` | INTEGER | 训练日期时间戳 |
| `duration` | INTEGER | 训练时长（秒） |
| `totalWeight` | INTEGER | 总重量（kg） |
| `totalSets` | INTEGER | 总组数 |
| `exerciseCount` | INTEGER | 动作数量 |
| `muscles` | TEXT | 涉及肌群（JSON 数组） |
| `setRecords` | TEXT | 每组记录（JSON 对象） |
| `restLog` | TEXT | 休息日志（JSON 数组） |
| `createTime` | INTEGER | 时间戳 |

索引：`idx_records_date`、`idx_records_createTime`

### 11.3 `gym_cards` 表

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | TEXT PK | 卡片 ID |
| `name` | TEXT NOT NULL | 卡片名称 |
| `gymName` | TEXT | 健身房名称 |
| `cardType` | TEXT | 卡片类型 |
| `price` | REAL | 价格 |
| `startDate` / `endDate` | INTEGER | 开始 / 到期日期 |
| `remainingCount` / `totalCount` | INTEGER | 剩余 / 总次数（-1=不限） |
| `phone` | TEXT | 联系电话 |
| `remark` | TEXT | 备注 |
| `createTime` / `updateTime` | INTEGER | 时间戳 |

索引：`idx_gym_cards_endDate`

> `fittrack_flutter2` 无 SQLite，`plans` / `records` 以 JSON 字符串整体存于 SharedPreferences（键 `fittrack_fitplan_plans`、`fittrack_fitplan_records`）。

---

## 12. 项目运行方式

### 12.1 fittrack_flutter（主力版本）

```bash
cd health_training/fittrack_flutter
flutter pub get

# Android 运行 / 构建
flutter run
flutter build apk

# HarmonyOS 运行 / 构建（需 Flutter OHOS 工具链 + DevEco 环境）
flutter run -d ohos
flutter build hap
```

### 12.2 fittrack_flutter2（精简版本）

```bash
cd health_training/fittrack_flutter2
flutter pub get
flutter run
```

### 12.3 FitTrackHarmony（原生 HarmonyOS 版）

使用 **DevEco Studio** 打开 `FitTrackHarmony/` 目录，连接 HarmonyOS 设备/模拟器后运行。构建配置见 `build-profile.json5`：`targetSdkVersion 6.1.0(23)`、`compatibleSdkVersion 5.1.0(18)`、`runtimeOS: HarmonyOS`。

---

## 13. 附录：Settings 默认值

`Storage.getSettings()` 在无数据时返回的默认值：

| 键 | 默认值 | 说明 |
|----|--------|------|
| `unit` | `'kg'` | 重量单位 |
| `restTime` | `90` | 休息时间（秒） |
| `defaultRestTime` | `90` | 默认休息时间 |
| `defaultSets` | `3` | 默认组数 |
| `defaultReps` | `10` | 默认次数 |
| `defaultWeight` | `20.0` | 默认重量 |
| `theme` | `'vitality-sport'` | 主题 ID |
| `trainingTime` | `''` | 训练提醒时间（HH:mm） |

> 另有由路由流程写入的 `privacyAgreed`（隐私政策同意）与 `onboardingDone`（引导完成）标记。
