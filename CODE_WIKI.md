# FitTrack Code Wiki — 项目代码百科

> **项目名称**: FitTrack（燃力）— 健身训练追踪应用
> **仓库名**: health_training
> **版本**: 1.1.0
> **本地路径**: `d:\app\projects\health_training`
> **文档生成日期**: 2026-07-13

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
10. [平台特定功能（OHOS）](#10-平台特定功能ohos)
11. [数据库设计](#11-数据库设计)
12. [项目运行方式](#12-项目运行方式)
13. [附录](#13-附录)

---

## 1. 项目概述

FitTrack 是一款面向健身爱好者的多平台训练追踪应用，采用**纯本地单机**架构（数据全部存储在设备本地，不上传服务器）。核心功能包括：

- **训练计划管理** — 创建、编辑、执行训练计划（支持多分化方案）
- **训练执行与记录** — 组间休息倒计时、训练数据实时记录、自动统计聚合
- **统计与进度追踪** — 周度训练统计、肌肉分布分析、个人记录、身体数据趋势
- **身体数据管理** — 身高/体重/体脂/围度记录、BMI 实时计算、体重趋势折线图
- **多主题支持** — 7 套视觉主题（活力运动、硬核铁馆、柔美花语、长者关怀、清新极简、赛博霓虹、黑金尊享）
- **HarmonyOS 桌面卡片** — 实时显示训练进度与今日概览（仅 OHOS，三态：idle/training/rest）
- **HarmonyOS 实况窗** — 休息倒计时胶囊（LiveViewKit，仅 OHOS）
- **休息提醒通知** — 前台 Dart Timer + Android `zonedSchedule` + OHOS 代理提醒三重机制
- **健身卡管理** — 管理健身房会员卡信息（次卡/期限卡）
- **问卷与个性化推荐** — 新用户问卷引导，自动生成用户名 / 头像

### 目标平台

| 平台 | 实现方式 | 说明 |
|------|---------|------|
| HarmonyOS (OHOS) | Flutter + 原生 ArkTS 扩展 | **主要目标平台**，含桌面卡片/实况窗/代理提醒 |
| Android | Flutter | 完整支持 |
| iOS / macOS / Windows / Linux / Web | Flutter 脚手架壳 | 主要用于运行/调试 |

---

## 2. 仓库整体结构

本仓库并非单一工程，而是同一款应用的**三个并行实现 + 文档**：

```
health_training/
├── fittrack_flutter/     ← 【主力版本】Flutter，功能最全（SQLite + 全部服务/页面 + OHOS 原生扩展）
├── fittrack_flutter2/    ← 【精简版本】Flutter，仅 SharedPreferences，基础页面
├── FitTrackHarmony/      ← 【原生 HarmonyOS 版】ArkTS / ETS 实现（独立，无桌面卡片）
├── docs/                 ← 产品需求文档与运营方案
│   ├── FitTrack_v2_产品需求文档.md
│   └── FitTrack运营方案.md
├── AGENT.md              ← AI 助手操作指南与约束
├── README.md             ← 仓库说明（Gitee 模板）
├── README.en.md          ← 英文说明
├── LogoDesign.md         ← Logo 设计说明
├── analyze_output.txt    ← flutter analyze 输出记录
└── CODE_WIKI.md          ← 本文档
```

> 三个子项目共享相同的产品设计与主题体系，但技术栈与完成度不同。`fittrack_flutter` 是理解本项目的核心入口。

---

## 3. 整体架构与分层

以主力版本 `fittrack_flutter` 为例，采用经典分层结构，**未引入独立状态管理框架**（Provider/Bloc/Riverpod），而是通过 `Storage` 内存缓存 + `ValueNotifier` + `setState` 组合管理状态。

```
┌───────────────────────────────────────────────┐
│                  UI 层 (pages/)                 │
│  HomePage / TrainingPage / StatsPage / ...      │
│  （17 个页面，含 splash/onboarding/body_data 等）│
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
│         原生桥接 (MethodChannel) [OHOS]          │
│  form 通道 / reminder 通道 + LiveViewKit         │
│  EntryAbility + FitTrackFormExtension            │
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
├── pages/                          ← 17 个页面
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
│   ├── settings_page.dart          ← 设置页（含训练默认值/数据管理）
│   ├── theme_settings_page.dart    ← 风格主题设置页（PageView 卡片预览）
│   ├── body_data_page.dart         ← 身体数据页（BMI + 趋势折线图）
│   ├── reminder_settings_page.dart ← 提醒设置页
│   ├── notification_test_page.dart ← 通知测试页
│   └── gym_card_page.dart          ← 健身卡管理页
├── services/
│   ├── rest_notification_service.dart ← 休息结束通知服务（三重提醒）
│   ├── form_kit_service.dart          ← OHOS 桌面卡片服务（三态）
│   ├── ohos_reminder_service.dart     ← OHOS 后台代理提醒服务
│   ├── permission_service.dart        ← 权限管理服务
│   └── user_profile_generator.dart    ← 用户名 / 头像生成器
├── themes/
│   └── app_themes.dart             ← 7 套主题 + FitTrackColors ThemeExtension
└── widgets/
    ├── bottom_nav.dart             ← 底部导航栏（悬浮胶囊样式）
    ├── common_widgets.dart         ← 通用组件库
    └── page_header.dart            ← 页面标题组件

OHOS 原生代码：fittrack_flutter/ohos/entry/src/main/ets/
├── entryability/EntryAbility.ets       ← FlutterAbility + form/reminder MethodChannel + LiveViewKit
├── formability/FitTrackFormExtension.ets ← 桌面卡片 FormExtensionAbility
├── pages/
│   ├── FitTrackWidget.ets              ← 桌面卡片 UI
│   └── Index.ets                       ← Flutter 引擎宿主页
└── plugins/GeneratedPluginRegistrant.ets ← 插件注册

平台壳目录：android/ ios/ macos/ windows/ linux/ web/
```

### 4.2 fittrack_flutter2（精简版本）

与主力版本结构类似，但功能收敛：

```
lib/
├── main.dart          ← 入口（含 SplashScreen 动画 + 自定义 AppShell），直接用 MaterialApp（无 go_router）
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
- 路由：直接使用 `MaterialApp` + 自定义 `AppShell`（`_navHistory` 栈管理，无 `go_router`、无 `router.dart`）。
- 无问卷 / 引导 / 提醒 / 健身卡 / 桌面卡片 / 实况窗 / 通知服务等高级功能。
- `pubspec.yaml` 中 `name` 字段为 `fittrack_flutter`（与目录名不一致）。
- `dependency_overrides: win32: ^5.0.0`（注意：与 Dart 2.x 兼容性存在风险，见 [8.2 节](#82-fittrack_flutter2pubspecyaml)）。
- `ohos/har/` 目录仅有 `flutter.har`，但 `entry/oh-package.json5` 引用了 `permission_handler_ohos.har`（文件缺失，OHOS 构建可能失败）。

### 4.3 FitTrackHarmony（原生 HarmonyOS 版）

纯 ArkTS/ETS 实现，使用 DevEco Studio + hvigor 构建。**注意：此版本为独立 UI 实现，不含桌面卡片（无 FormExtensionAbility），EntryAbility 为系统模板。**

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
│   ├── PageHeader.ets       ← 页面标题
│   ├── ProgressIndicator.ets← 进度指示器
│   ├── SectionHeader.ets    ← 区域标题
│   ├── StatCard.ets         ← 统计卡片
│   └── TagBadge.ets         ← 标签徽章
├── common/
│   ├── ThemeConstants.ets   ← 主题常量（ThemeColors 类 + 6 套主题定义）
│   └── MockData.ets         ← Mock 数据
├── data/
│   └── MockData.ets         ← 静态演示数据集合
├── entryability/
│   └── EntryAbility.ets     ← 应用入口 Ability（极简模板）
└── entrybackupability/
    └── EntryBackupAbility.ets ← 备份/恢复扩展 Ability（模板实现）
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
- **Settings / Stats / BodyData / BodyDataHistory** → SharedPreferences（简单键值对，序列化为 JSON 字符串）。
- **内存缓存** → 启动时预加载到内存；同步接口直接操作缓存并异步落盘，`*CacheDirty` 标记控制何时从 SQLite 重新加载。

**SharedPreferences 存储键**（实际存储时统一加 `fittrack_` 前缀）：

| 常量 | 实际键 | 内容 |
|------|--------|------|
| `_keySettings` | `fittrack_fitplan_settings` | 设置 JSON |
| `_keyStats` | `fittrack_fitplan_stats` | 统计 JSON |
| `_keyBodyData` | `fittrack_fitplan_bodyData` | 当前身体数据 |
| `_keyBodyDataHistory` | `fittrack_fitplan_bodyDataHistory` | 身体数据历史（≤50 条） |
| `_keyMigrated` | `fittrack_sqlite_migrated` | SP→SQLite 迁移完成标记 |

### 5.2 服务层 (services/)

| 服务 | 职责 | 关键能力 |
|------|------|---------|
| `RestNotificationService` | 休息结束提醒 | Dart Timer（前台保底）+ Android `zonedSchedule` + OHOS 代理提醒 + 增强振动 |
| `FormKitService` | OHOS 桌面卡片 | 三态管理（idle / training / rest）+ 主题色同步 + 推送串行化 |
| `OhosReminderService` | OHOS 后台代理提醒 | `reminderAgentManager` + 每日训练定时提醒 + 通知/卡片点击监听 + 训练卡片交互回调 |
| `PermissionService` | 权限管理 | 通知权限申请 + 拒绝引导弹窗 |
| `UserProfileGenerator` | 用户个性化生成 | 基于性别/目标/水平生成用户名 + 头像配置 |

### 5.3 通用组件库 (widgets/)

| 组件 | 用途 |
|------|------|
| `BottomNav` | 底部导航栏（悬浮胶囊样式，5 个 Tab，活动项缩放动画） |
| `PageHeader` | 页面标题（返回 + 标题 + 副标题 + 铃铛/日历操作，毛玻璃背景） |
| `common_widgets.dart` | 通用组件集合：`SectionHeader`、`StatCard`、`BadgeWidget`（4 variant）、`ProgressBar`、`CardWidget`、`MenuButton`、`IconBtn`、`EmptyState`、`DividerWidget`、`FitToast`（Overlay 浮层）、`ConfirmDialog`、`InfoDialog`、`AchievementDialog`、`FitBottomSheet`、`FitTextField`、`FitChipSelector` |

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
7. **[OHOS]** `FormKitService.instance.init()`、`OhosReminderService.instance.initListener()`、注册 `onCardClick` 回调（区分 `training` / `home` 目标页，训练态优先交给 `onTrainingCardAction` 原地处理避免销毁训练页）
8. `runApp(FitTrackApp())`

`FitTrackApp`（`StatefulWidget`）持有 `_currentThemeId` 与 `GoRouter` 实例，`build` 返回 `MaterialApp.router`。主题切换回调 `_onThemeChanged` 会 `setState` + `Storage.saveSettings` + **[OHOS]** 同步卡片主题（`FormKitService.instance.pushFormData()`）。`_globalRouter` 全局引用供卡片点击导航使用。

### 6.2 路由系统 — `router.dart`

`createRouter()` 返回 `GoRouter`，`initialLocation: '/splash'`。路由结构：

```
/splash          → SplashPage（启动页，决定后续流向）
/privacy         → _PrivacyPolicyPage（隐私政策，同意后写 privacyAgreed）
/onboarding      → OnboardingPage（新手引导，完成写 onboardingDone）
/questionnaire   → QuestionnairePage（健身问卷，extra 传 profileData）
/recommend       → PlanRecommendPage（计划推荐，接收 extra 问卷数据）
── ShellRoute（带底部导航栏）──────────────
  /home    → HomePage      /plan    → PlanPage
  /records → RecordsPage    /stats   → StatsPage
  /profile → ProfilePage
── 独立路由（root navigator，无底部导航栏）──
  /training（?planId&dayIndex）
  /exercise
  /settings
  /theme-settings（extra: currentThemeId）
  /notification-test
  /reminder-settings
  /gym-card
  /body-data
```

- **AppShell**：使用 `IndexedStack` 缓存 5 个 Tab 页面并保持存活，避免反复创建/销毁导致的 Ink splash 崩溃。
- `currentTabIndex`（`ValueNotifier<int>`）根据当前路径推导高亮 Tab。
- `onThemeChanged`（顶层可空回调）由 `main.dart` 注入，供 `SettingsPage` / `ThemeSettingsPage` 触发主题切换。
- `_PrivacyPolicyPage` 为 router.dart 内私有页面，"不同意"调用 `SystemNavigator.pop()` 退出应用。

### 6.3 数据存储 — `Storage`（`data/storage.dart`）

核心方法（同步方法操作内存缓存并异步落盘，`*Async` 方法直接读写数据库）：

| 方法 | 说明 |
|------|------|
| `Future<void> init()` | 初始化 SP + 加载轻量数据 + `_migrateFromPrefsIfNeeded()` 迁移旧 Plans/Records 到 SQLite |
| `String generateId(prefix)` | 生成唯一 ID：`{prefix}_{毫秒时间戳}_{6位base36随机}`（如 `plan_1736800000000_a3f9k2`） |
| `getWeekKey(timestamp)` | **ISO 周算法**：回退到本周四计算，返回 `${year}-W${weekNo 补零2位}`（如 `2026-W28`），用于统计聚合 |
| `getTodayStr()` | 返回 `YYYY-MM-DD` 今日字符串 |
| `getPlansAsync()` / `getPlans()` | 异步加载（脏标记为真时从 DB 重载缓存） / 同步读缓存深拷贝 |
| `savePlansAsync(plans)` | 先 `deleteAllPlans` 再逐条 `insertPlan`（覆盖式） |
| `addPlanAsync()` / `addPlan()` | 计划的异步 / 同步 CRUD（同步版仅更新缓存 + 异步 fire-and-forget 插入） |
| `updatePlanAsync()` / `updatePlan()` | 计划更新（缓存内 merge + 异步持久化） |
| `deletePlanAsync()` / `deletePlan()` | 计划删除 |
| `getPlanByIdAsync()` / `getPlanById()` | 按 ID 查计划 |
| `getRecordsAsync()` / `getRecords()` / `saveRecordsAsync()` | 记录读取与覆盖保存 |
| `addRecord(record)` | **关键方法**：插入缓存头部（限 500 条）+ 触发 `dataChanged` 通知 + 异步 `insertRecord` + `trimRecords(500)` + 调用 `updateStats(newRecord)` 增量更新统计 |
| `deleteRecord()` / `getRecordById()` | 记录删除与查询 |
| `getSettings()` / `saveSettings()` | 设置读写（含默认值，见 [附录 13.1](#131-settings-默认值)） |
| `getStats()` | 统计读取（默认值：`{totalTrainings:0, totalDuration:0, totalWeight:0, totalSets:0, weeklyData:[], muscleData:{}}`） |
| `updateStats(record)` | **增量更新**：累加 totalTrainings/totalDuration/totalWeight/totalSets；按 `getWeekKey` 更新 `weeklyData`（保留最近 12 周）；按 `record.muscles` 自增 `muscleData` |
| `recalcStatsAsync()` | 从全部记录重新计算统计（全量重算，用于校准） |
| `getBodyData()` / `saveBodyData()` | 当前身体数据读写 |
| `getBodyDataHistory()` / `saveBodyDataHistory(oldData)` | 身体数据历史（保存旧数据前调用，附加 timestamp，**只保留最近 50 条**） |
| `addGymCard()` / `updateGymCard()` / `deleteGymCard()` | 健身卡 CRUD（同步 + 异步双版本） |
| `exportAllDataAsync()` / `exportAllDataJsonAsync()` / `exportAllData()` / `exportAllDataJson()` | 数据导出（含同步兼容版本），输出 `{plans, records, settings, stats, exportTime}` |
| `importDataAsync()` / `importDataJsonAsync()` / `importData()` / `importDataJson()` | 数据导入（要求 plans 与 records 非空，覆盖式导入） |
| `clearAll()` | 清空全部数据（删 SQLite 三表 + 清缓存 + 置脏 + 移除 SP 4 键） |
| `hasData()` | `_plansCache.isNotEmpty || _recordsCache.isNotEmpty` |
| `initDemoData()` | 首次启动（`hasData()` 为假）时初始化演示计划（三分化增肌 + 新手入门） |

**缓存与通知**：`_plansCache` / `_recordsCache` / `_gymCardsCache` + `_*CacheDirty` 脏标记（初始 `true`）；`dataChanged`（`ValueNotifier<bool>`）仅在 `addRecord` 时触发 `dataChanged.value = !dataChanged.value`，用于跨页面数据变更通知。

**SP→SQLite 迁移**（`_migrateFromPrefsIfNeeded`）：读 `_keyMigrated` 标记，未迁移时从 SP 读取旧 `fitplan_plans` / `fitplan_records` JSON，逐条 `insertPlan` / `insertRecord`（缺失 id 时补全），成功后写标记并移除旧键。

**initDemoData() 内容**：
1. "三分化增肌计划"（进阶，6 天/周，8 周总，第 4 周，badge="进行中"）— Day1 胸+三头 / Day2 背+二头 / Day3 腿 / Day4 肩+核心 / Day5、6 空
2. "新手入门计划"（入门，3 天/周，4 周总，第 4 周，status='done'，progress=100，badge="已完成"）— Day1/2/3 全身训练 A/B/C

### 6.4 数据库 — `DatabaseHelper`（`data/database_helper.dart`）

单例（`DatabaseHelper._()` + `instance`），管理 `fittrack.db`（version 2）：

| 方法 | 说明 |
|------|------|
| `Future<Database> get database` | 懒加载获取数据库实例 |
| `_onCreate()` | 建表 `plans` / `records` / `gym_cards` + 4 个索引 |
| `_onUpgrade()` | v1→v2 升级：新增 `gym_cards` 表及 `idx_gym_cards_endDate` 索引 |
| `getAllPlans()` | `orderBy: 'createTime DESC'` |
| `getPlanById(id)` / `insertPlan(plan)` / `updatePlan(id, updates)` / `deletePlan(id)` / `deleteAllPlans()` | Plans CRUD（`insertPlan` 用 `ConflictAlgorithm.replace`；`updatePlan` 先读 existing merge 后写回并刷新 `updateTime`） |
| `getAllRecords()` | `orderBy: 'createTime DESC'` |
| `getRecordById` / `insertRecord` / `deleteRecord` / `deleteAllRecords` | Records CRUD |
| `trimRecords(maxCount)` | **保留最近 maxCount 条**，删除 SQL：`id IN (SELECT id FROM records ORDER BY createTime DESC LIMIT -1 OFFSET ?)` |
| `getAllGymCards()` | `orderBy: 'endDate ASC'`（按到期日升序） |
| `getGymCardById` / `insertGymCard` / `updateGymCard` / `deleteGymCard` / `deleteAllGymCards` | GymCards CRUD |

**行↔Map 转换中 JSON 字符串存储的字段**：
- **plans**：`days`（List）。`_planMapToRow` 还会 `remove('icon')` 和 `remove('desc')` 非数据库字段。
- **records**：`muscles`（List）、`setRecords`（Map）、`restLog`（List）三个字段以 JSON 字符串存储，读出时 `jsonDecode` 还原，解析失败回退 `[]` / `{}` / `[]`。
- **gym_cards**：无 JSON 字段。

### 6.5 通知服务 — `RestNotificationService`

单例 `RestNotificationService.instance`。常量：`_channelId='rest_channel'`、`_channelName='训练休息提醒'`、`_notificationId=1001`。

**三重提醒机制**：
1. **Dart Timer**（前台倒计时，所有平台通用保底）：`_scheduleWithDartTimer` 设置 `Timer(Duration(seconds: delaySeconds))`
2. **Android zonedSchedule**（系统级定时，后台可靠触发）：`TZDateTime.now(local).add(...)` + `AndroidScheduleMode.exactAllowWhileIdle` + `fullScreenIntent: true`
3. **OHOS 后台代理提醒**（由原生 EntryAbility 处理）：Flutter 侧不直接调用 `publishReminder`（避免重复创建带进度条通知），仅 `initListener()`，代理提醒由原生侧在收到 rest 数据后自动发布

| 方法 | 说明 |
|------|------|
| `init()` | 幂等初始化：创建插件实例 + Android/Darwin 初始化配置（OHOS 跳过 flutter_local_notifications）+ 创建 Android 通知渠道 + `_configureLocalTimeZone()` + `_requestNotificationPermission()`（OHOS 跳过）+ [OHOS] `OhosReminderService.initListener()` |
| `scheduleRestEndNotification({exerciseName, delaySeconds})` | 先 `cancelScheduledNotification`，再 Dart Timer 保底 + Android zonedSchedule（OHOS 跳过） |
| `showRestEndNotification({exerciseName})` | 立即显示通知（Android + OHOS 双平台 NotificationDetails） |
| `cancelScheduledNotification()` | 取消 Dart Timer + `_plugin.cancel(_notificationId)` + OHOS `cancelCurrentReminder` |
| `cancelAll()` | 取消 Dart Timer + `_plugin.cancelAll()` + OHOS `cancelAllReminders` |
| `static vibrate()` | 循环 3 次 `HapticFeedback.heavyImpact()`（150ms + 100ms 间隔），兜底 `HapticFeedback.vibrate` |

### 6.6 桌面卡片 — `FormKitService`（仅 OHOS）

单例 `FormKitService.instance`，MethodChannel 通道名 `'com.example.fittrack_flutter/form'`。

**卡片三态**：

| mode | 触发方法 | 显示内容 |
|------|---------|---------|
| `idle` | `endTraining()` 或初始 | 今日训练概览（todayTrainings/Duration/Weight）+ streak 连续天数 + lastTraining + 训练提醒时间 |
| `training` | `startTraining()` / `updateTrainingState()` | 当前动作名 / 组数进度 / 动作索引 / 已完成组数 / 计划总组数 |
| `rest` | `startRest()` / `updateRestSeconds()` | 倒计时 restSeconds + restEndTime + totalRestSeconds + 动作信息 |

| 方法 | 说明 |
|------|------|
| `init()` | 幂等初始化，首次启动时 `pushFormData()` 推送一次 |
| `startTraining({exerciseName, currentSet, totalSets, exerciseIndex, totalExercises, completedSets, totalPlanSets})` | 进入训练态 |
| `startRest({...same + restSeconds, restEndTime, totalRestSeconds})` | 进入休息态 |
| `updateTrainingState({...})` | 更新训练态数据（参数同 startTraining） |
| `updateRestSeconds(restSeconds)` | **仅当当前为 rest 态时生效**，调用方应节流（如每 3 秒一次） |
| `endTraining()` | 置 `_trainingState = null`，推送空闲态 |
| `pushFormData()` | 推送串行化（`_isPushing` 标记），若有推送进行中只保留最新 `_pendingData`，调 `_channel.invokeMethod('updateFormData', jsonStr)` |
| `requestFormUpdate()` | 训练完成后调用，等价 `pushFormData()` |

**`_buildFormData()` 结构**：
- 训练态：`{..._trainingState, ..._getThemeColorsForWidget(), 'trainingTime': _getTrainingTime()}`
- 空闲态：`{mode:'idle', todayTrainings, todayDuration, todayWeight, streak, lastTraining, lastDate, ...主题色, trainingTime}`（遍历 records 按今日字符串聚合；streak 从今天往前数连续打卡天数）

**主题色同步**（`_getThemeColorsForWidget`）：根据 `Storage.getSettings()['theme']` 从硬编码 `themeColorMap` 查表，返回 `{accentColor, bgColor, textPrimaryColor, textSecondaryColor}`（7 套主题，默认回退 `vitality-sport`）。

### 6.7 后台代理提醒 — `OhosReminderService`（仅 OHOS）

单例 `OhosReminderService.instance`，MethodChannel 通道名 `'com.example.fittrack_flutter/reminder'`。

**回调字段**：
- `onNotificationClick` — 通知点击回调（`call.arguments` 直接是 Map）
- `onCardClick` — 卡片点击回调（`call.arguments` 是 JSON 字符串，需 `jsonDecode`）
- `onTrainingCardAction` — **训练卡片交互回调**（训练页挂载时注册，原地处理 skipRest / resume，避免卡片点击跳转首页销毁训练页导致数据丢失）

| 方法 | 说明 |
|------|------|
| `initListener()` | `_channel.setMethodCallHandler` 监听 `onNotificationClick` / `onCardClick` |
| `publishReminder({title, content, triggerTimeInSeconds, notificationId})` | 先 `cancelCurrentReminder` 再发布，返回 reminderId 存入 `_currentReminderId`（非 OHOS 返回 null） |
| `cancelCurrentReminder()` | 仅当 `_currentReminderId != null && >= 0` 时调用 |
| `cancelAllReminders()` | 取消所有代理提醒 |
| `scheduleTrainingReminder({title, content, timeStr})` | `timeStr` 格式 `"HH:mm"`，每日训练定时提醒 |
| `cancelTrainingReminder()` | 取消每日训练提醒 |

所有方法均带 `Platform.isOhos` 守卫与 `PlatformException` 捕获。

### 6.8 用户档案生成 — `UserProfileGenerator`

私有构造，全静态方法。基于问卷（性别/健身目标/健身水平）自动生成用户名和头像。

| 方法 | 说明 |
|------|------|
| `generateUserName({gender, fitnessGoal, fitnessLevel})` | 性别选前缀（男 15 个/女 15 个/中性 10 个），目标选后缀（增肌/减脂/塑形/保持健康各 5 个），30% 概率插入水平修饰词（如"铁血萌新巨兽"） |
| `generateUserNameOptions({...})` | 生成最多 6 个不重复用户名（最多尝试 20 次） |
| `generateAvatar({gender, fitnessGoal, fitnessLevel})` | 返回 `{emoji, bgColor: 0xFF...}`，emoji 按目标选，bgColor 按水平选 |
| `getAllAvatars()` | 返回 16 条 `_avatarConfigs` 拷贝供手动选择 |
| `buildAvatarWidget(config, {size, borderWidth, borderColor})` | 构建圆形头像 Widget（emoji 居中 + 半透明背景 + 边框） |

### 6.9 权限服务 — `PermissionService`

私有构造，全静态方法，基于 `permission_handler`。

| 方法 | 说明 |
|------|------|
| `requestNotification()` | 检查 `Permission.notification.status`，已授予返回 true，否则 `request()`；`isPermanentlyDenied` 时 `openAppSettings()` 返回 false |
| `isNotificationGranted()` | 仅检查不请求 |
| `requestCorePermissions()` | 应用启动时调用，仅请求 `[Permission.notification]`（振动权限只需在 module.json5 声明，HapticFeedback 无需运行时申请） |
| `showPermissionDeniedDialog(context, {permissionName, reason})` | 显示带"取消/去设置"按钮的 AlertDialog，"去设置"调用 `openAppSettings()` |

`_isPermissionPlatform`：`kIsWeb` 为 false；否则判断 `Platform.isAndroid || Platform.isIOS || Platform.isFuchsia || Platform.isOhos`。

### 6.10 新页面补充说明

#### `body_data_page.dart` — 身体数据页

`BodyDataPage`（StatefulWidget）。10 个表单控制器（身高/体重/体脂/胸/腰/臀/臂围/大腿围/目标体重/静息心率）。

- **BMI 实时计算**：身高/体重输入变化即 `setState` 刷新，公式 `weight / (height/100)^2`，保留 1 位小数。分类：< 18.5 偏瘦 / < 24 正常 / < 28 偏胖 / >= 28 肥胖。
- **保存逻辑**：校验身高体重 > 0；计算 BMI；**保存前先将旧 `_savedBodyData` 存入历史**（`Storage.saveBodyDataHistory`）；调 `Storage.saveBodyData(newData)`；同步更新 `settings['height']`/`['weight']` 保持其他页面一致。
- **体重趋势折线图**：`_WeightTrendChart` + `_WeightTrendPainter`（CustomPaint 自绘），过滤 weight>0 数据点（最多 20 条），Y 轴范围 `min-2` 到 `max+2`，绘制坐标轴/折线/数据点/首尾日期。
- **身体变化趋势**：比较历史首尾体重差值，区分持平/减重/增肌/增重四种情绪文案与颜色。

#### `theme_settings_page.dart` — 风格主题设置页

`ThemeSettingsPage`（StatefulWidget），构造参数 `String currentThemeId` + `void Function(String themeId) onThemeChanged`。

- **PageView 滑动卡片**：`viewportFraction: 0.92`，7 套主题，每张卡片含 9:16 比例手机预览图。
- **预览内容**：以 600 高度为基准等比缩放，模拟首页布局（PageHeader + 今日训练卡片 + 2×2 统计 + 7 列日历）。
- **`_selectTheme(themeId)`**：与当前相同则返回；`setState` 更新；写入 `Storage.saveSettings`；调用 `widget.onThemeChanged(themeId)` 通知父级实时切换。
- **页码指示器**：7 个圆点，活动态 20×6 横条。
- **应用按钮**：当前页主题已应用时显示"已应用"（禁用），否则"应用此主题"。

---

## 7. 数据流与状态管理

### 7.1 状态管理方案

- **内存缓存** — `Storage` 维护所有数据的缓存列表（`_plansCache` / `_recordsCache` / `_gymCardsCache` / `_store`）。
- **ValueNotifier** — `Storage.dataChanged` 跨页面通知数据变更（仅 `addRecord` 触发）；`currentTabIndex` 管理导航高亮。
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
SettingsPage / ThemeSettingsPage 切换主题
  → onThemeChanged(themeId)
    → FitTrackApp.setState()（重建 MaterialApp）
    → Storage.saveSettings()（持久化）
    → [OHOS] FormKitService.pushFormData()（同步卡片颜色）
```

### 7.4 训练执行流（核心）

```
TrainingPage 进入
  → 按 planId + dayIndex 加载当日训练
  → 用户完成一组 → _completeSet()
    → 记录 setRecords
    → _startRest(seconds, isLastSet)
      → [OHOS] FormKitService.startRest() + EntryAbility LiveView 胶囊
      → RestNotificationService.scheduleRestEndNotification()（定时提醒）
      → 倒计时结束 → _advanceAfterRest()
        → 下一组或下一动作
  → 全部完成 → _saveAndReturn()
    → Storage.addRecord()（增量更新统计 + dataChanged 通知）
    → [OHOS] FormKitService.endTraining()
    → [OHOS] 取消 LiveView
```

---

## 8. 依赖关系

### 8.1 fittrack_flutter（`pubspec.yaml`）

> Flutter SDK 约束：`sdk: '>=2.19.6 <3.0.0'`。部分包为适配 HarmonyOS 使用 **gitcode 上的 OHOS 定制分支**。

| 依赖 | 来源/版本 | 用途 |
|------|-----------|------|
| `flutter` | SDK | UI 框架 |
| `shared_preferences` | gitcode（openharmony-tpc OHOS 定制） | 轻量键值存储 |
| `sqflite` | gitcode（CPF-Flutter） | SQLite 数据库 |
| `permission_handler` | gitcode（CPF-Flutter） | 权限管理 |
| `flutter_local_notifications` | gitcode（openharmony-sig） | 本地通知 |
| `go_router` | ^6.5.0 | 声明式路由 |
| `timezone` | ^0.9.4 | 时区支持（定时通知） |
| `path` | ^1.8.0 | 路径拼接 |
| `cupertino_icons` | ^1.0.2 | iOS 风格图标 |
| `flutter_lints`（dev） | ^2.0.0 | 代码规范 |

**资源**：`assets/images/exercises/`（16 张动作示意图 e1-e16）。

### 8.2 fittrack_flutter2（`pubspec.yaml`）

| 依赖 | 版本 | 用途 |
|------|------|------|
| `flutter` | SDK | UI 框架 |
| `shared_preferences` | ^2.1.1 | 本地存储（唯一持久化方式） |
| `permission_handler` | ^11.0.1 | 权限管理 |
| `permission_handler_ohos` | ^0.0.8 | OHOS 权限适配 |
| `cupertino_icons` | ^1.0.2 | 图标 |
| `flutter_lints`（dev） | ^2.0.0 | 代码规范 |

> ⚠️ **注意**：`dependency_overrides: win32: ^5.0.0`。项目 SDK 约束 `<3.0.0`，而 win32 4.1.4+ 依赖 Dart 3.2+ 的 `UnmodifiableUint8ListView` 类型。当前 `^5.0.0` 配置在 Dart 2.x 环境下可能存在兼容性风险，实际构建需验证。
>
> ⚠️ **注意**：`name: fittrack_flutter`（与目录名 `fittrack_flutter2` 不一致）。
>
> ⚠️ **注意**：`ohos/entry/oh-package.json5` 引用 `"permission_handler_ohos": "file:../har/permission_handler_ohos.har"`，但 `ohos/har/` 目录下仅有 `flutter.har`，`permission_handler_ohos.har` 缺失。

### 8.3 FitTrackHarmony（`oh-package.json5` / `build-profile.json5`）

- 运行时：`runtimeOS: HarmonyOS`
- `targetSdkVersion`: 6.1.0(23)，`compatibleSdkVersion`: 5.1.0(18)
- `strictMode`: `caseSensitiveCheck` + `useNormalizedOHMUrl`
- 构建：hvigor；模块：`entry`；无第三方运行时依赖
- 测试依赖（dev）：`@ohos/hypium: 1.0.25` + `@ohos/hamock: 1.0.0`

### 8.4 模块间依赖（主力版本）

```
main.dart
├── data/storage.dart ──→ data/database_helper.dart ──→ sqflite
├── services/permission_service.dart ──→ permission_handler
├── services/rest_notification_service.dart ──→ flutter_local_notifications / timezone / ohos_reminder_service.dart
├── services/form_kit_service.dart ──→ data/storage.dart（+ MethodChannel → EntryAbility）
├── services/ohos_reminder_service.dart ──→（+ MethodChannel → EntryAbility）
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

**`FitTrackColors` 13 个 Color 字段**：`bgSecondary` / `bgCard` / `bgElevated` / `accentGlow` / `accentSecondary` / `textPrimary` / `textSecondary` / `textMuted` / `borderColor` / `successColor` / `warningColor` / `infoColor` / `purpleColor`。实现 `copyWith` 与 `lerp`（用于主题切换动画）。

**`AppTheme` 类方法**：
- `static ThemeData getTheme(String themeId)` — switch 7 个 ID，default 回退 `_vitalitySportTheme`
- `static List<Map<String, dynamic>> get themes` — 返回 7 套主题元信息（id/name/desc/icon/colors）

每套主题均配置：colorScheme、extensions([FitTrackColors])、cardTheme、appBarTheme、elevatedButtonTheme、textTheme（完整 13 档）、inputDecorationTheme、dividerTheme、bottomNavigationBarTheme、floatingActionButtonTheme、chipTheme、progressIndicatorTheme。

便捷访问：`FitTrackTheme.dark` → `iron-forge`；`FitTrackTheme.light` → `vitality-sport`。

### 9.2 主题清单（Flutter 版 7 套）

| 主题 ID | 名称 | 描述 | 图标 | 亮度 | 主色 | 风格特征 |
|---------|------|------|------|------|------|---------|
| `vitality-sport` | 活力运动 | 动感活力，年轻有劲 | 🔥 | Light | `#FF6B35` | **默认主题**，大圆角(20)，w800 粗体 |
| `iron-forge` | 硬核铁馆 | 男性健身玩家 | 🏋️ | Dark | `#ef4444` | 零圆角，3px 粗边框，letterSpacing 2 |
| `blossom` | 柔美花语 | 女性优雅健身 | 🌸 | Light | `#ec4899` | 超大圆角(24)，w600 |
| `silver-care` | 长者关怀 | 大字清晰易读 | 🛡️ | Light | `#059669` | 超大字号(displayLarge 34px)，2px 边框 |
| `fresh-minimal` | 清新极简 | 简洁留白美学 | 🍃 | Light | `#0ea5e9` | 负字间距(-0.5)，细边框(1px)，大留白 |
| `neon-cyber` | 赛博霓虹 | Z 世代潮流玩家 | 🎮 | Dark | `#d946ef` | 极小圆角(4-6)，letterSpacing 3 |
| `black-gold` | 黑金尊享 | 商务精英品质 | 👑 | Dark | `#f59e0b` | 金色描边，letterSpacing 3 |

### 9.3 HarmonyOS 版主题

`ThemeConstants.ets` 定义 `ThemeColors` 类（**41 个字段**，含颜色、圆角、间距、字重、导航高度等完整设计令牌）与 `createTheme(...)` 工厂（45 个位置参数）。

**统一访问模式**：所有组件通过 `@StorageProp('themeId')` + `getCurrentTheme()` 获取当前 ThemeColors，主题切换时 `AppStorage.setOrCreate('themeId', id)` 触发全局重渲染。

**常量与函数**：
- `DEFAULT_THEME_ID = 'iron-forge'`
- `getThemeById(id)` — 找不到 fallback 至 `THEME_LIST[0]`
- `getCurrentTheme()` — 从 `AppStorage.get('themeId')` 读取
- `switchTheme(id)` — `AppStorage.setOrCreate('themeId', id)`

**主题清单（HarmonyOS 版 6 套，比 Flutter 少 `vitality-sport`）**：

| ID | 名称 | 主色 | 风格特征 |
|----|------|------|---------|
| `iron-forge` | 硬核铁馆 | `#ef4444` | **默认主题**，深色 + 红色，零圆角，字重 800，大写 |
| `blossom` | 柔美花语 | `#ec4899` | 粉色，圆角 12-50 |
| `silver-care` | 长者关怀 | `#059669` | 绿色，`fontSizeScale: 1.2`，navHeight 84 |
| `fresh-minimal` | 清新极简 | `#0ea5e9` | 蓝色，细边框 1 |
| `neon-cyber` | 赛博霓虹 | `#d946ef` | 深紫，大写，字间距 3 |
| `black-gold` | 黑金尊享 | `#f59e0b` | 深色 + 金色，大写，字间距 3，navHeight 80 |

---

## 10. 平台特定功能（OHOS）

> 仅 `fittrack_flutter`（主力版本）实现了完整的 OHOS 原生扩展。原生代码位于 `fittrack_flutter/ohos/entry/src/main/ets/`。`FitTrackHarmony` 原生版**不含**桌面卡片，`fittrack_flutter2` 的 OHOS 壳仅为 Hello World 模板。

### 10.1 OHOS 原生文件结构

```
fittrack_flutter/ohos/entry/src/main/ets/
├── entryability/EntryAbility.ets       ← FlutterAbility 子类，注册双 MethodChannel + LiveViewKit
├── formability/FitTrackFormExtension.ets ← 桌面卡片 FormExtensionAbility
├── pages/
│   ├── FitTrackWidget.ets              ← 桌面卡片 UI 模板
│   └── Index.ets                       ← Flutter 引擎宿主页
└── plugins/GeneratedPluginRegistrant.ets ← 插件自动注册
```

### 10.2 权限声明（`module.json5`）

```json5
"requestPermissions": [
  {"name": "ohos.permission.INTERNET"},
  {"name": "ohos.permission.PUBLISH_AGENT_REMINDER"},  // 后台代理提醒
  {"name": "ohos.permission.VIBRATE"}                   // 振动
]
```

`extensionAbilities` 声明 `FitTrackFormExtension`（type: `form`，metadata: `ohos.extension.form` → `$profile:form_config`）。

### 10.3 桌面卡片 (Form Kit) 数据流

```
Flutter (FormKitService._buildFormData())
  → MethodChannel（form 通道，invokeMethod 'updateFormData'）
    → EntryAbility (FormDataCallHandler.onMethodCall 'updateFormData')
      → preferences 写入 'fittrack_form_data' / 'form_data'（跨进程共享）
        → FormExtensionAbility (onUpdateForm)
          → removePreferencesFromCacheSync() 清缓存读最新数据
          → formProvider.updateForm(formId, binddata)
            → 桌面卡片渲染（FitTrackWidget.ets）

卡片点击：FormExtension → postCardAction → EntryAbility (onNewWant) → MethodChannel → Flutter(onCardClick)
```

**`FitTrackFormExtension` 关键方法**：
- `onAddForm(want)` — 卡片添加时返回初始数据
- `onUpdateForm(formId)` — 卡片更新时从 preferences 读取数据并 `formProvider.updateForm`
- `onRemoveForm(formId)` — 卡片删除
- `buildFormData()` — **先 `removePreferencesFromCacheSync` 清进程缓存**再读取最新数据（解决 HarmonyOS preferences 不支持跨进程共享的问题），rest 态下动态计算 `restSeconds = max(0, (restEndTime - Date.now()) / 1000)`

**`FormDataRecord` 字段**：mode / todayTrainings / todayDuration / todayWeight / streak / lastTraining / lastDate / exerciseName / currentSet / totalSets / exerciseIndex / totalExercises / completedSets / totalPlanSets / restSeconds / restEndTime / totalRestSeconds / accentColor / bgColor / textPrimaryColor / textSecondaryColor / trainingTime

### 10.4 实况窗 (LiveViewKit)

`EntryAbility.ets` 中集成 LiveViewKit（休息倒计时胶囊）：
- `REST_LIVE_VIEW_ID = 30001`
- `CAPSULE_ICON = 'liveview_icon.png'`
- 休息开始时创建 TIMER 类型实况窗，胶囊显示倒计时
- `liveViewSequence` 递增序号管理更新
- `liveViewWantAgent` 点击跳转回应用
- 训练结束 / 应用退出时取消实况窗

### 10.5 后台代理提醒 (ReminderAgent)

通过 `reminder` MethodChannel 调用原生 `reminderAgentManager`（`@kit.BackgroundTasksKit`）：
- `publishReminder` → 原生创建 `ReminderRequestTimer` 一次性定时提醒
- `cancelReminder` / `cancelAllReminders`
- `scheduleTrainingReminder` → 每日定时提醒（HH:mm）
- `cancelTrainingReminder`
- 需权限 `ohos.permission.PUBLISH_AGENT_REMINDER`

### 10.6 EntryAbility 交互回调

`EntryAbility.onNewWant` 处理卡片/通知点击的 Want 参数：
- `targetPage`（training / home）+ `cardAction`（skipRest / resume）
- 通过 `reminder` MethodChannel 反向调用 Flutter（`onCardClick` / `onNotificationClick`）

### 10.7 Android 专属

- `zonedSchedule` 定时通知（后台可靠触发）
- 高优先级通知渠道 + 振动
- 全屏通知 `fullScreenIntent`

### 10.8 平台判断

```dart
if (Platform.isOhos) { ... }  // OHOS 专属逻辑（桌面卡片、代理提醒、实况窗）
```

---

## 11. 数据库设计

### 11.1 `plans` 表（fittrack_flutter，SQLite `fittrack.db` v2）

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `id` | TEXT PK | — | 计划 ID（`plan_{ts}_{rand}`） |
| `name` | TEXT NOT NULL | — | 计划名称 |
| `type` | TEXT | '' | 类型（三分化 / 全身训练等） |
| `difficulty` | TEXT | '' | 难度（入门 / 进阶 / 高级） |
| `frequency` | TEXT | '' | 频率（3天/周、6天/周等） |
| `totalWeeks` | INTEGER | 8 | 总周数 |
| `defaultRestTime` | INTEGER | 90 | 默认休息时间（秒） |
| `week` | INTEGER | 0 | 当前周 |
| `progress` | INTEGER | 0 | 进度百分比 |
| `status` | TEXT | 'active' | 状态（active / done / pending） |
| `badge` | TEXT | '' | 标签（进行中 / 已完成 / 待开始） |
| `days` | TEXT | '[]' | 每日训练内容（**JSON 数组字符串**） |
| `createTime` | INTEGER NOT NULL | — | 创建时间戳 |
| `updateTime` | INTEGER NOT NULL | — | 更新时间戳 |

索引：`idx_plans_status`

### 11.2 `records` 表

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `id` | TEXT PK | — | 记录 ID（`record_{ts}_{rand}`） |
| `name` | TEXT | '' | 训练名称 |
| `date` | INTEGER | 0 | 训练日期时间戳 |
| `duration` | INTEGER | 0 | 训练时长（秒） |
| `totalWeight` | INTEGER | 0 | 总重量（kg） |
| `totalSets` | INTEGER | 0 | 总组数 |
| `exerciseCount` | INTEGER | 0 | 动作数量 |
| `muscles` | TEXT | '[]' | 涉及肌群（**JSON 数组字符串**） |
| `setRecords` | TEXT | '{}' | 每组记录（**JSON 对象字符串**） |
| `restLog` | TEXT | '[]' | 休息日志（**JSON 数组字符串**） |
| `createTime` | INTEGER NOT NULL | — | 创建时间戳 |

索引：`idx_records_date`、`idx_records_createTime`

### 11.3 `gym_cards` 表

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `id` | TEXT PK | — | 卡片 ID |
| `name` | TEXT NOT NULL | — | 卡片名称 |
| `gymName` | TEXT | '' | 健身房名称 |
| `cardType` | TEXT | '' | 卡片类型 |
| `price` | REAL | 0 | 价格 |
| `startDate` | INTEGER | 0 | 开始日期 |
| `endDate` | INTEGER | 0 | 到期日期 |
| `remainingCount` | INTEGER | -1 | 剩余次数（-1=不限） |
| `totalCount` | INTEGER | -1 | 总次数（-1=不限） |
| `phone` | TEXT | '' | 联系电话 |
| `remark` | TEXT | '' | 备注 |
| `createTime` | INTEGER NOT NULL | — | 创建时间戳 |
| `updateTime` | INTEGER NOT NULL | — | 更新时间戳 |

索引：`idx_gym_cards_endDate`

> `fittrack_flutter2` 无 SQLite，`plans` / `records` 以 JSON 字符串整体存于 SharedPreferences（键 `fittrack_fitplan_plans`、`fittrack_fitplan_records`）。
> `FitTrackHarmony` 无持久化层，全部使用 `MockData.ets` 静态常量。

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

# 静态检查 / 测试
flutter analyze
flutter test
```

### 12.2 fittrack_flutter2（精简版本）

```bash
cd health_training/fittrack_flutter2
flutter pub get
flutter run
```

> ⚠️ OHOS 构建可能因 `permission_handler_ohos.har` 缺失而失败，需补全该文件或调整依赖配置。

### 12.3 FitTrackHarmony（原生 HarmonyOS 版）

使用 **DevEco Studio** 打开 `FitTrackHarmony/` 目录，连接 HarmonyOS 设备/模拟器后运行。构建配置见 `build-profile.json5`：`targetSdkVersion 6.1.0(23)`、`compatibleSdkVersion 5.1.0(18)`、`runtimeOS: HarmonyOS`。

### 12.4 三个子项目对比

| 维度 | fittrack_flutter | fittrack_flutter2 | FitTrackHarmony |
|------|-----------------|-------------------|-----------------|
| 定位 | **主力版本** | 精简版本 | 原生独立实现 |
| 语言 | Dart 2.19.6+ | Dart 2.19.6+ | ArkTS/ETS |
| 持久化 | SQLite + SharedPreferences | 仅 SharedPreferences | 无（MockData） |
| 路由 | go_router | 自定义 Navigator 栈 | Tabs + router.pushUrl |
| 主题套数 | 7（默认 vitality-sport） | 7（默认 vitality-sport） | 6（默认 iron-forge） |
| 桌面卡片 | ✅ FormExtensionAbility | ❌ | ❌ |
| 实况窗 | ✅ LiveViewKit | ❌ | ❌ |
| 代理提醒 | ✅ reminderAgentManager | ❌ | ❌ |
| 通知服务 | ✅ 三重提醒 | ❌ | ❌ |
| 页面数 | 17 | 8 | 8 |
| bundleName | （Flutter OHOS 壳） | `com.ft.myapplication` | （原生版独有） |

---

## 13. 附录

### 13.1 Settings 默认值

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

### 13.2 Stats 默认值

`Storage.getStats()` 默认值：

```json
{
  "totalTrainings": 0,
  "totalDuration": 0,
  "totalWeight": 0,
  "totalSets": 0,
  "weeklyData": [],
  "muscleData": {}
}
```

### 13.3 关键常量速查

| 常量 | 值 | 位置 |
|------|-----|------|
| SQLite 数据库名 | `fittrack.db` | DatabaseHelper |
| SQLite 版本 | `2` | DatabaseHelper |
| 通知渠道 ID | `rest_channel` | RestNotificationService |
| 通知 ID | `1001` | RestNotificationService |
| form MethodChannel | `com.example.fittrack_flutter/form` | FormKitService / EntryAbility |
| reminder MethodChannel | `com.example.fittrack_flutter/reminder` | OhosReminderService / EntryAbility |
| preferences 名 | `fittrack_form_data` | EntryAbility / FitTrackFormExtension |
| preferences 键 | `form_data` | EntryAbility / FitTrackFormExtension |
| LiveView ID | `30001` | EntryAbility |
| 记录缓存上限 | `500` 条 | Storage.addRecord |
| 身体数据历史上限 | `50` 条 | Storage.saveBodyDataHistory |
| 周数据保留 | 最近 `12` 周 | Storage.updateStats |
| 默认主题（Flutter） | `vitality-sport` | AppTheme |
| 默认主题（HarmonyOS） | `iron-forge` | ThemeConstants |

### 13.4 工程约定与注意事项

- **状态管理**：未引入 Provider/Bloc/Riverpod。修改数据时走 `Storage` 的同步方法（更新缓存 + 异步落盘）。
- **数据分流**：结构化数据（Plans/Records/GymCards）→ SQLite；轻量键值（Settings/Stats/BodyData）→ SharedPreferences。
- **主题访问**：通过 `Theme.of(context).extension<FitTrackColors>()!` 访问色板，**不要硬编码颜色**。主题切换经 `main.dart` 的 `onThemeChanged` 回调统一处理。
- **平台判断**：OHOS 专属逻辑用 `if (Platform.isOhos) { ... }` 包裹。
- **HarmonyOS preferences 跨进程**：不支持跨进程共享；`FormExtensionAbility` 必须用 `removePreferencesFromCacheSync()` 清进程缓存才能读到主进程最新数据。
- **formProvider.updateForm() 限流**：每分钟每卡片实例最多 10 次调用。
- **EntryAbility 后台定时器**：`setInterval` 在应用进入后台时会被挂起（无后台任务权限），需依赖代理提醒保证后台触发。
- **LiveViewKit (TIMER 类型)**：必需字段 `capsule.icon`（string/image.PixelMap）、`layoutData.nodeIcons`（Array），更新参数结构须与 `startLiveView` 一致。
- **win32 兼容性**：win32-4.1.4+ 与 Dart 2.x 不兼容（`UnmodifiableUint8ListView` 需 Dart 3.2+），需通过 `dependency_overrides` 锁定版本。
- **新增第三方依赖**：需评估 OHOS 兼容性（部分包依赖 gitcode 上的 OHOS 定制分支）。
- **编码规范**：遵循 `analysis_options.yaml`（`package:flutter_lints/flutter.yaml`）；提交前跑 `flutter analyze` 保持无警告。页面放 `pages/`，可复用 UI 放 `widgets/`，业务能力放 `services/`，数据访问统一走 `data/storage.dart`。

### 13.5 相关文档

- [AGENT.md](file:///d:/app/projects/health_training/AGENT.md) — AI 助手操作指南与约束
- [FitTrack_v2_产品需求文档.md](file:///d:/app/projects/health_training/docs/FitTrack_v2_产品需求文档.md) — 产品需求文档
- [FitTrack运营方案.md](file:///d:/app/projects/health_training/docs/FitTrack运营方案.md) — 运营方案
- HarmonyOS 官方文档：https://developer.huawei.com/consumer/cn/doc/
