# FitTrack Code Wiki — 项目代码百科

> **项目名称**: FitTrack (燃力) — 健身训练追踪应用
> **版本**: 1.0.0
> **包名**: com.ft.fittrack
> **最后更新**: 2026-06

---

## 目录

1. [项目概述](#1-项目概述)
2. [整体架构](#2-整体架构)
3. [子项目结构](#3-子项目结构)
4. [主要模块职责](#4-主要模块职责)
5. [关键类与函数说明](#5-关键类与函数说明)
6. [数据流与状态管理](#6-数据流与状态管理)
7. [依赖关系](#7-依赖关系)
8. [主题系统](#8-主题系统)
9. [平台特定功能](#9-平台特定功能)
10. [项目运行方式](#10-项目运行方式)
11. [数据库设计](#11-数据库设计)

---

## 1. 项目概述

FitTrack 是一款面向健身爱好者的多平台训练追踪应用，核心功能包括：

- **训练计划管理** — 创建、编辑、执行训练计划（支持多分化方案）
- **训练执行与记录** — 组间休息倒计时、训练数据实时记录
- **统计与进度追踪** — 周度/月度训练统计、肌肉分布分析
- **多主题支持** — 7 套视觉主题（活力运动、硬核铁馆、柔美花语、长者关怀、清新极简、赛博霓虹、黑金尊享）
- **OHOS 桌面卡片** — 实时显示训练进度与今日概览
- **休息提醒通知** — 前台振动 + 后台代理提醒双机制
- **健身卡管理** — 管理健身房会员卡信息
- **问卷与个性化推荐** — 新用户问卷引导，自动生成用户名/头像

### 目标平台

| 平台 | 实现方式 | 状态 |
|------|---------|------|
| HarmonyOS (OHOS) | Flutter + 原生扩展 | 主要目标平台 |
| Android | Flutter | 支持 |
| iOS | Flutter | 支持 |
| Web | React 原型 | 仅设计验证 |

---

## 2. 整体架构

```
health_training/
├── fittrack_flutter/        ← 主力版本（Flutter，功能最全）
│   ├── lib/                 ← Dart 源码
│   │   ├── main.dart        ← 应用入口
│   │   ├── router.dart      ← 路由配置（go_router）
│   │   ├── data/            ← 数据层（Storage + SQLite + Mock）
│   │   ├── pages/           ← 页面组件（16 个页面）
│   │   ├── services/        ← 服务层（通知、权限、卡片、提醒）
│   │   ├── themes/          ← 主题系统（7 套主题）
│   │   └── widgets/         ← 通用组件
│   ├── ohos/                ← OHOS 原生壳（EntryAbility + FormExtension）
│   ├── android/             ← Android 原生壳
│   └── ios/                 ← iOS 原生壳
│
├── fittrack_flutter2/       ← 精简版本（Flutter，基础功能）
│   └── lib/                 ← 结构同上，但页面/服务更少
│
├── FitTrackHarmony/         ← 原生 HarmonyOS 版（ArkTS/ETS）
│   └── entry/src/main/ets/  ← ETS 源码
│       ├── pages/           ← 页面
│       ├── components/      ← 组件
│       └── common/          ← 主题与数据
│
├── react-prototype/         ← React Web 原型（UI 设计验证）
│   └── src/                 ← React 组件 + 主题
│
└── 文档/
    ├── README.md
    ├── 运动训练APP开发方案.md
    ├── 单机版最小MVP方案.md
    └── 补充营销策略与上架难点分析.md
```

### 架构分层

```
┌─────────────────────────────────────────────┐
│                  UI 层 (Pages)               │
│  HomePage / TrainingPage / StatsPage / ...   │
├─────────────────────────────────────────────┤
│              路由层 (Router)                  │
│     go_router (ShellRoute + 子路由)           │
├─────────────────────────────────────────────┤
│            通用组件 (Widgets)                 │
│  BottomNav / StatCard / ConfirmDialog / ...  │
├─────────────────────────────────────────────┤
│             服务层 (Services)                 │
│  RestNotification / FormKit / Permission /   │
│  OhosReminder / UserProfileGenerator         │
├─────────────────────────────────────────────┤
│              数据层 (Data)                    │
│  Storage (内存缓存) + DatabaseHelper (SQLite) │
│  + SharedPreferences (轻量KV)                │
├─────────────────────────────────────────────┤
│           原生桥接 (MethodChannel)            │
│  FormKit Channel / Reminder Channel          │
└─────────────────────────────────────────────┘
```

---

## 3. 子项目结构

### 3.1 fittrack_flutter（主力版本）

```
lib/
├── main.dart                      ← 入口：初始化 Storage/权限/通知/卡片
├── router.dart                    ← go_router 路由配置 + AppShell
├── data/
│   ├── storage.dart               ← 混合持久化层（SQLite + SP + 内存缓存）
│   ├── database_helper.dart       ← SQLite 数据库管理（3 张表）
│   └── mock_data.dart             ← 静态 Mock 数据（16 个动作 + 问卷等）
├── pages/
│   ├── splash_page.dart           ← 启动动画页
│   ├── onboarding_page.dart       ← 新手引导页
│   ├── questionnaire_page.dart    ← 健身问卷页
│   ├── plan_recommend_page.dart   ← 计划推荐页
│   ├── home_page.dart             ← 首页（今日概览 + 快捷入口）
│   ├── plan_page.dart             ← 计划列表页
│   ├── training_page.dart         ← 训练执行页（核心页面）
│   ├── exercise_page.dart         ← 动作详情页
│   ├── stats_page.dart            ← 统计分析页
│   ├── records_page.dart          ← 训练记录页
│   ├── profile_page.dart          ← 个人中心页
│   ├── settings_page.dart         ← 设置页（含主题切换）
│   ├── reminder_settings_page.dart← 提醒设置页
│   ├── notification_test_page.dart← 通知测试页
│   └── gym_card_page.dart         ← 健身卡管理页
├── services/
│   ├── rest_notification_service.dart ← 休息结束通知服务
│   ├── form_kit_service.dart         ← OHOS 桌面卡片服务
│   ├── ohos_reminder_service.dart    ← OHOS 后台代理提醒服务
│   ├── permission_service.dart       ← 权限管理服务
│   └── user_profile_generator.dart   ← 用户名/头像生成器
├── themes/
│   └── app_themes.dart            ← 7 套主题定义 + FitTrackColors 扩展
└── widgets/
    ├── bottom_nav.dart            ← 底部导航栏（悬浮胶囊样式）
    ├── common_widgets.dart        ← 通用组件库（12+ 组件）
    └── page_header.dart           ← 页面标题组件
```

### 3.2 fittrack_flutter2（精简版本）

```
lib/
├── main.dart          ← 入口（简单，含 SplashScreen + AppShell）
├── data/
│   ├── storage.dart   ← 精简版 Storage
│   └── mock_data.dart ← 精简版 Mock 数据
├── pages/             ← 9 个基础页面（无问卷/引导/提醒/健身卡）
├── services/
│   └── permission_service.dart
├── themes/
│   └── app_themes.dart
└── widgets/           ← 3 个基础组件
```

### 3.3 FitTrackHarmony（原生 HarmonyOS 版）

```
entry/src/main/ets/
├── pages/
│   ├── Index.ets          ← 主入口（Tabs 导航，5 个 Tab）
│   ├── HomePage.ets       ← 首页
│   ├── PlanPage.ets       ← 计划页
│   ├── StatsPage.ets      ← 统计页
│   ├── ExercisePage.ets   ← 动作页
│   ├── ProfilePage.ets    ← 个人中心
│   ├── SettingsPage.ets   ← 设置页
│   └── TrainingPage.ets   ← 训练页
├── components/
│   ├── PageHeader.ets     ← 页面标题
│   ├── ProgressIndicator.ets ← 进度指示器
│   ├── SectionHeader.ets  ← 区域标题
│   ├── StatCard.ets       ← 统计卡片
│   └── TagBadge.ets       ← 标签徽章
├── common/
│   ├── ThemeConstants.ets ← 主题常量（6 套主题）
│   └── MockData.ets       ← Mock 数据
└── entryability/
    └── EntryAbility.ets   ← 应用入口 Ability
```

### 3.4 react-prototype（React Web 原型）

```
src/
├── App.jsx             ← 入口（ThemeProvider + AppShell）
├── AppShell.jsx        ← 应用壳（路由 + 底部导航）
├── context/
│   └── ThemeContext.jsx ← 主题上下文
├── components/         ← 10 个页面组件
├── data/
│   ├── mockData.js     ← Mock 数据
│   └── storage.js      ← 本地存储
├── themes.css          ← 主题样式
└── styles.css          ← 全局样式
```

---

## 4. 主要模块职责

### 4.1 数据层 (data/)

| 模块 | 职责 | 存储方式 |
|------|------|---------|
| `Storage` | 统一数据访问层，提供同步/异步双接口 | 内存缓存 + SQLite + SP |
| `DatabaseHelper` | SQLite 数据库管理，3 张表的 CRUD | SQLite (fittrack.db) |
| `MockData` | 开发阶段静态测试数据 | 硬编码常量 |

**数据分流策略**：
- **Plans / Records / GymCards** → SQLite（结构化大数据，需要查询索引）
- **Settings / Stats / BodyData** → SharedPreferences（简单键值对）
- **内存缓存** → 所有数据在启动时加载到内存，同步接口直接操作缓存，异步持久化到磁盘

### 4.2 服务层 (services/)

| 服务 | 职责 | 关键能力 |
|------|------|---------|
| `RestNotificationService` | 休息结束提醒 | Dart Timer + Android zonedSchedule + OHOS 代理提醒 |
| `FormKitService` | OHOS 桌面卡片 | 三态管理（idle/training/rest）+ 主题同步 |
| `OhosReminderService` | OHOS 后台代理提醒 | reminderAgentManager + 训练定时提醒 |
| `PermissionService` | 权限管理 | 通知权限申请 + 拒绝引导 |
| `UserProfileGenerator` | 用户个性化生成 | 基于问卷生成用户名 + 头像 |

### 4.3 主题系统 (themes/)

7 套完全独立的视觉主题，每套定义完整的 `ThemeData` + `FitTrackColors` 扩展：

| 主题ID | 名称 | 风格 | 亮度 |
|--------|------|------|------|
| `vitality-sport` | 活力运动 | 动感橙色，大圆角 | Light |
| `iron-forge` | 硬核铁馆 | 粗犷暗黑，零圆角 | Dark |
| `blossom` | 柔美花语 | 粉色柔和，大圆角 | Light |
| `silver-care` | 长者关怀 | 大字高对比，绿色系 | Light |
| `fresh-minimal` | 清新极简 | 大量留白，天蓝色 | Light |
| `neon-cyber` | 赛博霓虹 | 霓虹发光，深紫暗色 | Dark |
| `black-gold` | 黑金尊享 | 金色奢华，暗色底 | Dark |

### 4.4 通用组件库 (widgets/)

| 组件 | 用途 |
|------|------|
| `BottomNav` | 底部导航栏（悬浮胶囊样式，5 个 Tab） |
| `SectionHeader` | 区域标题（带"更多"链接） |
| `StatCard` | 统计卡片（图标 + 数值 + 标签） |
| `BadgeWidget` | 徽章标签（4 种颜色变体） |
| `ProgressBar` | 进度条 |
| `CardWidget` | 通用卡片容器 |
| `MenuButton` | 菜单按钮（图标 + 标签 + 箭头） |
| `IconBtn` | 图标按钮 |
| `EmptyState` | 空状态占位 |
| `FitToast` | Toast 提示（Overlay 实现，4 种类型） |
| `ConfirmDialog` | 确认弹窗 |
| `InfoDialog` | 信息弹窗 |
| `AchievementDialog` | 成就弹窗 |
| `FitBottomSheet` | 底部弹窗 |
| `FitTextField` | 输入框（带标签和验证） |
| `FitChipSelector` | Chip 风格选择器 |

---

## 5. 关键类与函数说明

### 5.1 入口与初始化

#### `main()` — [main.dart](file:///e:/Project/health_project/health_training/fittrack_flutter/lib/main.dart)

```
启动流程：
1. runZonedGuarded() 包裹整个应用，捕获未处理异常
2. WidgetsFlutterBinding.ensureInitialized()
3. tz_data.initializeTimeZones() — 初始化时区
4. Storage.init() — 初始化混合持久化
   ├── SharedPreferences 初始化
   ├── 加载 Settings/Stats/BodyData
   └── 从 SP 迁移旧 Plans/Records 到 SQLite
5. Storage.getPlansAsync() / getRecordsAsync() / getGymCardsAsync() — 预加载缓存
6. PermissionService.requestCorePermissions() — 异步请求通知权限
7. RestNotificationService.instance.init() — 初始化通知渠道
8. [OHOS] FormKitService.instance.init() — 初始化桌面卡片
9. [OHOS] OhosReminderService.instance.initListener() — 监听通知/卡片点击
10. [OHOS] _scheduleTrainingReminderIfNeeded() — 发布训练提醒
11. runApp(FitTrackApp())
```

#### `FitTrackApp` — 主应用 Widget

- `StatefulWidget`，持有当前主题 ID 和 GoRouter 实例
- 主题切换时调用 `setState` + 持久化到 Settings
- [OHOS] 主题切换时同步更新桌面卡片

### 5.2 路由系统

#### `createRouter()` — [router.dart](file:///e:/Project/health_project/health_training/fittrack_flutter/lib/router.dart)

```
路由结构：
/splash          → SplashPage（启动页）
/privacy         → _PrivacyPolicyPage（隐私政策）
/onboarding      → OnboardingPage（新手引导）
/questionnaire   → QuestionnairePage（健身问卷）
/recommend       → PlanRecommendPage（计划推荐）
── ShellRoute ──────────────────────────────
  /home          → HomePage（首页）
  /plan          → PlanPage（计划）
  /records       → RecordsPage（记录）
  /stats         → StatsPage（统计）
  /profile       → ProfilePage（我的）
── 独立路由（无底部导航栏）──────────────────
  /training      → TrainingPage（训练执行）
  /exercise      → ExercisePage（动作详情）
  /settings      → SettingsPage（设置）
  /notification-test → NotificationTestPage
  /reminder-settings → ReminderSettingsPage
  /gym-card      → GymCardPage
```

**AppShell**: 使用 `IndexedStack` 保持所有 Tab 页面存活，避免反复创建销毁。

### 5.3 数据存储

#### `Storage` — [storage.dart](file:///e:/Project/health_project/health_training/fittrack_flutter/lib/storage.dart)

核心方法：

| 方法 | 说明 |
|------|------|
| `static Future<void> init()` | 初始化 SP + 加载数据 + 迁移旧数据 |
| `static Future<List<Map>> getPlansAsync()` | 异步获取所有计划 |
| `static List<Map> getPlans()` | 同步获取缓存的计划 |
| `static Map addPlan(Map plan)` | 同步添加计划（更新缓存 + 异步持久化） |
| `static Map? updatePlan(String id, Map updates)` | 同步更新计划 |
| `static bool deletePlan(String id)` | 同步删除计划 |
| `static Map addRecord(Map record)` | 添加记录 + 更新统计 + 通知变更 |
| `static Map<String,dynamic> updateStats(Map record)` | 增量更新统计数据 |
| `static Map<String,dynamic> getSettings()` | 获取设置（含默认值） |
| `static bool saveSettings(Map settings)` | 保存设置 |
| `static Future<Map> exportAllDataAsync()` | 导出全部数据 |
| `static Future<bool> importDataAsync(Map data)` | 导入数据 |
| `static Future<void> clearAll()` | 清空所有数据 |
| `static Map? initDemoData()` | 首次启动时初始化演示数据 |

**缓存策略**：
- `_plansCache` / `_recordsCache` / `_gymCardsCache` — 内存缓存列表
- `*_CacheDirty` 标记 — 是否需要从 SQLite 重新加载
- 同步方法直接操作缓存，异步持久化到 SQLite
- `dataChanged` (ValueNotifier) — 跨页面数据变更通知

#### `DatabaseHelper` — [database_helper.dart](file:///e:/Project/health_project/health_training/fittrack_flutter/lib/data/database_helper.dart)

单例模式，管理 SQLite 数据库（fittrack.db, v2）：

| 方法 | 说明 |
|------|------|
| `Future<Database> get database` | 懒加载获取数据库实例 |
| `Future<void> _onCreate()` | 建表（plans/records/gym_cards + 索引） |
| `Future<void> _onUpgrade()` | 数据库升级（v1→v2 新增 gym_cards） |
| `getAllPlans()` / `insertPlan()` / `updatePlan()` / `deletePlan()` | Plans CRUD |
| `getAllRecords()` / `insertRecord()` / `deleteRecord()` / `trimRecords()` | Records CRUD |
| `getAllGymCards()` / `insertGymCard()` / `updateGymCard()` / `deleteGymCard()` | GymCards CRUD |

**行↔Map 转换**：
- `days` (Plans) / `muscles` / `setRecords` / `restLog` (Records) — 存储为 JSON 字符串，读取时反序列化为 List/Map

### 5.4 通知服务

#### `RestNotificationService` — [rest_notification_service.dart](file:///e:/Project/health_project/health_training/fittrack_flutter/lib/services/rest_notification_service.dart)

三重提醒机制：

```
┌──────────────────────────────────────┐
│  scheduleRestEndNotification()       │
│  ├── Dart Timer（前台保底）           │
│  ├── [OHOS] reminderAgentManager    │
│  └── [Android] zonedSchedule        │
└──────────────────────────────────────┘
```

| 方法 | 说明 |
|------|------|
| `Future<void> init()` | 初始化通知渠道 + 请求权限 + 配置时区 |
| `Future<void> scheduleRestEndNotification(exerciseName, delaySeconds)` | 预约定时通知 |
| `Future<void> showRestEndNotification(exerciseName)` | 立即显示通知 |
| `Future<void> cancelScheduledNotification()` | 取消预约通知 |
| `static Future<void> vibrate()` | 增强振动提醒（3 组双击） |

### 5.5 桌面卡片服务

#### `FormKitService` — [form_kit_service.dart](file:///e:/Project/health_project/health_training/fittrack_flutter/lib/services/form_kit_service.dart)

卡片三态：

| 状态 | 显示内容 |
|------|---------|
| `idle` | 今日训练概览 + 连续打卡 + 上次训练 |
| `training` | 当前动作/组数/进度 |
| `rest` | 倒计时 + 动作信息 |

数据流：
```
Flutter (FormKitService._buildFormData())
  → MethodChannel 'com.example.fittrack_flutter/form'
    → EntryAbility (updateFormData)
      → preferences (跨进程共享)
        → FormExtensionAbility (onUpdateForm)
          → 桌面卡片渲染
```

### 5.6 OHOS 后台代理提醒

#### `OhosReminderService` — [ohos_reminder_service.dart](file:///e:/Project/health_project/health_training/fittrack_flutter/lib/services/ohos_reminder_service.dart)

通过 MethodChannel 调用原生 `reminderAgentManager`：

| 方法 | 说明 |
|------|------|
| `void initListener()` | 监听通知/卡片点击事件 |
| `Future<int?> publishReminder(title, content, triggerTimeInSeconds, notificationId)` | 发布一次定时提醒 |
| `Future<void> cancelCurrentReminder()` | 取消当前提醒 |
| `Future<void> scheduleTrainingReminder(title, content, timeStr)` | 发布每日训练提醒（HH:mm） |
| `Future<void> cancelTrainingReminder()` | 取消每日训练提醒 |

### 5.7 用户档案生成

#### `UserProfileGenerator` — [user_profile_generator.dart](file:///e:/Project/health_project/health_training/fittrack_flutter/lib/services/user_profile_generator.dart)

| 方法 | 说明 |
|------|------|
| `static String generateUserName(gender, fitnessGoal, fitnessLevel)` | 根据性别/目标/水平生成用户名 |
| `static Map generateAvatar(gender, fitnessGoal, fitnessLevel)` | 根据目标/水平生成头像配置 |
| `static List<String> generateUserNameOptions(...)` | 生成 6 个候选用户名 |
| `static Widget buildAvatarWidget(avatarConfig)` | 构建头像 Widget |

### 5.8 权限服务

#### `PermissionService` — [permission_service.dart](file:///e:/Project/health_project/health_training/fittrack_flutter/lib/services/permission_service.dart)

| 方法 | 说明 |
|------|------|
| `static Future<bool> requestNotification()` | 请求通知权限 |
| `static Future<bool> isNotificationGranted()` | 检查通知权限 |
| `static Future<void> requestCorePermissions()` | 启动时请求核心权限（通知） |
| `static Future<void> showPermissionDeniedDialog(context, permissionName, reason)` | 权限拒绝引导弹窗 |

---

## 6. 数据流与状态管理

### 6.1 状态管理方案

项目 **未使用** 状态管理框架（如 Provider/Bloc/Riverpod），而是采用以下方案：

- **内存缓存** — `Storage` 类维护所有数据的内存缓存列表
- **ValueNotifier** — `Storage.dataChanged` 用于跨页面通知数据变更
- **setState** — 页面内部状态通过 `StatefulWidget.setState` 管理
- **GoRouter** — 路由状态由 `GoRouter` 管理

### 6.2 核心数据流

```
用户操作 (UI)
  → 页面 State 方法
    → Storage 同步方法 (更新缓存)
      → Storage 异步持久化 (写入 SQLite/SP)
        → DatabaseHelper / SharedPreferences
      → ValueNotifier.dataChanged (通知其他页面)
    → FormKitService.pushFormData() [OHOS]
```

### 6.3 主题变更流

```
SettingsPage 切换主题
  → onThemeChanged(themeId)
    → FitTrackApp.setState() (重建 MaterialApp)
    → Storage.saveSettings() (持久化)
    → FormKitService.pushFormData() [OHOS] (同步卡片颜色)
```

---

## 7. 依赖关系

### 7.1 fittrack_flutter (pubspec.yaml)

| 依赖 | 版本 | 用途 |
|------|------|------|
| `flutter` | SDK | UI 框架 |
| `cupertino_icons` | ^1.0.2 | iOS 风格图标 |
| `shared_preferences` | ^2.1.1 | 轻量键值存储 |
| `permission_handler` | ^11.0.1 | 权限管理 |
| `permission_handler_ohos` | ^0.0.8 | OHOS 权限管理 |
| `go_router` | - | 声明式路由 |
| `flutter_local_notifications` | - | 本地通知 |
| `timezone` | - | 时区支持 |
| `sqflite` | - | SQLite 数据库 |
| `path` | - | 路径工具 |

### 7.2 react-prototype (package.json)

| 依赖 | 版本 | 用途 |
|------|------|------|
| `react` | ^18.3.1 | UI 框架 |
| `react-dom` | ^18.3.1 | DOM 渲染 |
| `vite` | ^6.0.7 | 构建工具 |
| `@vitejs/plugin-react` | ^4.3.4 | Vite React 插件 |

### 7.3 FitTrackHarmony (oh-package.json5)

| 依赖 | 版本 | 用途 |
|------|------|------|
| `@ohos/hypium` | 1.0.25 | 测试框架 |
| `@ohos/hamock` | 1.0.0 | Mock 框架 |

### 7.4 模块间依赖关系

```
main.dart
  ├── → storage.dart
  │      └── → database_helper.dart
  ├── → permission_service.dart
  │      └── → permission_handler (三方包)
  ├── → rest_notification_service.dart
  │      ├── → flutter_local_notifications (三方包)
  │      └── → ohos_reminder_service.dart
  ├── → form_kit_service.dart
  │      └── → storage.dart
  ├── → router.dart
  │      ├── → 所有 pages
  │      └── → widgets/bottom_nav.dart
  └── → themes/app_themes.dart

pages/*
  ├── → data/storage.dart
  ├── → themes/app_themes.dart
  ├── → widgets/common_widgets.dart
  └── → services/* (按需)
```

---

## 8. 主题系统

### 8.1 FitTrackColors 扩展

通过 `ThemeExtension<FitTrackColors>` 定义额外颜色，所有组件统一通过以下方式访问：

```dart
final colors = Theme.of(context).extension<FitTrackColors>()!;
colors.bgCard       // 卡片背景
colors.accentGlow   // 强调色
colors.textPrimary  // 主文本色
// ...
```

**扩展色值清单**：

| 字段 | 用途 |
|------|------|
| `bgSecondary` | 次级背景 |
| `bgCard` | 卡片背景 |
| `bgElevated` | 浮起背景 |
| `accentGlow` | 主强调色（带透明度） |
| `accentSecondary` | 次强调色 |
| `textPrimary` | 主文本 |
| `textSecondary` | 次文本 |
| `textMuted` | 弱化文本 |
| `borderColor` | 边框色 |
| `successColor` | 成功色 |
| `warningColor` | 警告色 |
| `infoColor` | 信息色 |
| `purpleColor` | 紫色 |

### 8.2 主题切换机制

1. `SettingsPage` 调用 `onThemeChanged(themeId)` 回调
2. `FitTrackApp._onThemeChanged()` 执行：
   - `setState(() { _currentThemeId = themeId; })` — 触发重建
   - `Storage.saveSettings()` — 持久化主题选择
   - `[OHOS] FormKitService.instance.pushFormData()` — 同步卡片主题色

---

## 9. 平台特定功能

### 9.1 HarmonyOS (OHOS) 专属功能

#### 桌面卡片 (Form Kit)

- **MethodChannel**: `com.example.fittrack_flutter/form`
- **原生端**: `FitTrackFormExtension.ets` (FormExtensionAbility)
- **数据传递**: Flutter → MethodChannel → EntryAbility → preferences → FormExtension
- **卡片点击**: FormExtension → postCardAction → EntryAbility → MethodChannel → Flutter

#### 后台代理提醒 (ReminderAgent)

- **MethodChannel**: `com.example.fittrack_flutter/reminder`
- **原生端**: EntryAbility 中调用 `reminderAgentManager`
- **所需权限**: `ohos.permission.PUBLISH_AGENT_REMINDER`

#### 平台判断

```dart
if (Platform.isOhos) {
  // OHOS 专属逻辑
}
```

### 9.2 Android 专属功能

- `zonedSchedule` 定时通知（后台可靠触发）
- 通知渠道创建（高优先级 + 振动）
- `fullScreenIntent` 全屏通知

---

## 10. 项目运行方式

### 10.1 fittrack_flutter（主力版本）

```bash
# 安装依赖
cd health_training/fittrack_flutter
flutter pub get

# Android 运行
flutter run

# OHOS 运行（需 HarmonyOS SDK）
flutter run -d ohos

# 构建 APK
flutter build apk

# 构建 OHOS HAP
flutter build hap
```

### 10.2 fittrack_flutter2（精简版本）

```bash
cd health_training/fittrack_flutter2
flutter pub get
flutter run
```

### 10.3 FitTrackHarmony（原生 HarmonyOS 版）

使用 DevEco Studio 打开 `FitTrackHarmony/` 目录，连接 HarmonyOS 设备后运行。

**构建配置**：
- `targetSdkVersion`: 6.1.0(23)
- `compatibleSdkVersion`: 5.1.0(18)
- `runtimeOS`: HarmonyOS

### 10.4 react-prototype（Web 原型）

```bash
cd health_training/react-prototype
npm install
npm run dev       # 开发服务器
npm run build     # 生产构建
npm run preview   # 预览构建结果
```

---

## 11. 数据库设计

### 11.1 plans 表

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | TEXT PK | 计划ID (plan_{timestamp}_{random}) |
| `name` | TEXT NOT NULL | 计划名称 |
| `type` | TEXT | 类型（三分化/全身训练等） |
| `difficulty` | TEXT | 难度（入门/进阶/高级） |
| `frequency` | TEXT | 频率（3天/周、6天/周等） |
| `totalWeeks` | INTEGER | 总周数 |
| `defaultRestTime` | INTEGER | 默认休息时间（秒） |
| `week` | INTEGER | 当前周 |
| `progress` | INTEGER | 进度百分比 |
| `status` | TEXT | 状态（active/done/pending） |
| `badge` | TEXT | 标签（进行中/已完成/待开始） |
| `days` | TEXT | 每日训练内容（JSON 数组） |
| `createTime` | INTEGER | 创建时间戳 |
| `updateTime` | INTEGER | 更新时间戳 |

**索引**: `idx_plans_status`

### 11.2 records 表

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | TEXT PK | 记录ID (record_{timestamp}_{random}) |
| `name` | TEXT | 训练名称 |
| `date` | INTEGER | 训练日期时间戳 |
| `duration` | INTEGER | 训练时长（秒） |
| `totalWeight` | INTEGER | 总重量（kg） |
| `totalSets` | INTEGER | 总组数 |
| `exerciseCount` | INTEGER | 动作数量 |
| `muscles` | TEXT | 涉及肌群（JSON 数组） |
| `setRecords` | TEXT | 每组记录（JSON 对象） |
| `restLog` | TEXT | 休息日志（JSON 数组） |
| `createTime` | INTEGER | 创建时间戳 |

**索引**: `idx_records_date`, `idx_records_createTime`

### 11.3 gym_cards 表

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | TEXT PK | 卡片ID |
| `name` | TEXT NOT NULL | 卡片名称 |
| `gymName` | TEXT | 健身房名称 |
| `cardType` | TEXT | 卡片类型 |
| `price` | REAL | 价格 |
| `startDate` | INTEGER | 开始日期 |
| `endDate` | INTEGER | 到期日期 |
| `remainingCount` | INTEGER | 剩余次数（-1=不限） |
| `totalCount` | INTEGER | 总次数（-1=不限） |
| `phone` | TEXT | 联系电话 |
| `remark` | TEXT | 备注 |
| `createTime` | INTEGER | 创建时间戳 |
| `updateTime` | INTEGER | 更新时间戳 |

**索引**: `idx_gym_cards_endDate`

---

## 附录：Settings 默认值

| 键 | 默认值 | 说明 |
|----|--------|------|
| `unit` | `'kg'` | 重量单位 |
| `restTime` | `90` | 默认休息时间（秒） |
| `defaultRestTime` | `90` | 默认休息时间 |
| `defaultSets` | `3` | 默认组数 |
| `defaultReps` | `10` | 默认次数 |
| `defaultWeight` | `20.0` | 默认重量 |
| `theme` | `'vitality-sport'` | 主题ID |
| `trainingTime` | `''` | 训练提醒时间 (HH:mm) |
| `privacyAgreed` | `false` | 隐私政策同意 |
| `onboardingDone` | `false` | 引导完成标记 |
