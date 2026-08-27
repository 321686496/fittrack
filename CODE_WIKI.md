# FitTrack Code Wiki — 项目代码百科

> **项目名称**: FitTrack（燃力）— 健身训练追踪应用
> **仓库名**: health_training
> **主工程**: `fittrack_flutter`（Flutter，功能最全的主力版本）
> **本地路径**: `d:\app\projects\health_training`
> **文档生成日期**: 2026-08-27（基于当前仓库实际状态重写）

---

## 目录

1. [项目概述](#1-项目概述)
2. [仓库整体结构](#2-仓库整体结构)
3. [整体架构与分层](#3-整体架构与分层)
4. [启动流程](#4-启动流程)
5. [主要模块职责](#5-主要模块职责)
6. [关键类与函数说明](#6-关键类与函数说明)
7. [数据流与状态管理](#7-数据流与状态管理)
8. [依赖关系](#8-依赖关系)
9. [主题系统](#9-主题系统)
10. [平台特定功能](#10-平台特定功能)
11. [数据库设计](#11-数据库设计)
12. [测试](#12-测试)
13. [CI / CD 与构建](#13-ci--cd-与构建)
14. [项目运行方式](#14-项目运行方式)
15. [附录](#15-附录)

---

## 1. 项目概述

FitTrack 是一款面向健身爱好者的多平台训练追踪应用，采用**纯本地单机架构**（数据全部存储在设备本地，不上传服务器）。核心功能包括：

- **训练计划管理** — 创建、编辑、执行训练计划（支持多分化方案、性别区分、系统计划库）
- **训练执行与记录** — 组间休息倒计时（支持实时倒计时/后台提醒）、训练数据实时记录、进行中训练恢复
- **统计与进度追踪** — 周度/月度统计、肌肉分布、个人记录、热力图、最大重量、身体数据趋势
- **积分与成就体系** — 签到/训练/广告/邀请/兑换码赚积分，成就解锁，虚拟物品与精品内容兑换
- **教学与系统化课程** — 动作教学库、系统化课程（章节式阅读）、训练笔记
- **虚拟对手 PK** — 与虚拟对手进行周训练量 PK，含皮肤系统与逐帧动画
- **留存与营销** — 新手 7 天留存链、智能推送、邀请有礼、分享海报/二维码、应用内购买/兑换码解锁 Pro
- **多主题支持** — 7 套视觉主题（含日/夜明暗模式，支持跟随系统与定点自动切换）
- **多平台桌面卡片 / 实况窗 / 后台提醒** — OHOS 桌面卡片 + 实况窗 + 代理提醒；Android 定时通知/闹钟 + 桌面小组件；iOS 实时活动（Live Activity）
- **健身卡管理** — 管理健身房会员卡信息（次卡/期限卡），到期与次数提醒

### 目标平台

| 平台 | 实现方式 | 说明 |
|------|---------|------|
| HarmonyOS (OHOS) | Flutter + 原生 ArkTS 扩展 | **主要目标平台**，含桌面卡片/实况窗/代理提醒 |
| Android | Flutter | 完整支持，含定时通知/闹钟/桌面小组件 |
| iOS | Flutter + 原生扩展 | 含 Live Activity 实时活动 |
| macOS / Windows / Linux / Web | Flutter 脚手架壳 | 主要用于运行/调试 |

---

## 2. 仓库整体结构

当前仓库仅保留一个主力 Flutter 工程 `fittrack_flutter`（历史上存在过的精简版 `fittrack_flutter2` 与原生版 `FitTrackHarmony` 已移除）。

```
health_training/
├── fittrack_flutter/       ← 主力 Flutter 工程（本 Wiki 主体）
│   ├── lib/                ← Dart 源码
│   ├── android/            ← Android 壳（包名 com.lt.lifttrack）
│   ├── ios/                ← iOS 壳（含 RestLiveActivity）
│   ├── ohos/               ← HarmonyOS 原生壳（卡片/实况窗/代理提醒）
│   ├── assets/             ← 图片/音效/系统计划 JSON
│   ├── test/               ← 单元与 Widget 测试
│   └── pubspec.yaml        ← 依赖清单
├── docs/                   ← 产品需求文档与运营方案、迭代计划
│   ├── FitTrack_v2_产品需求文档.md
│   ├── FitTrack运营方案.md
│   ├── Phase2_开发文档.md
│   ├── versions/           ← v1 / v1.5 / v2 迭代方案
│   └── superpowers/plans/  ← 各功能实施计划
├── .github/workflows/      ← iOS 打包 CI（GitHub Actions）
├── codemagic.yaml          ← CodeMagic CI（OHOS 构建适配 + iOS 打包）
├── AGENT.md                ← AI 助手操作指南与约束
├── README.md / README.en.md
├── LogoDesign.md           ← Logo 设计说明
├── download_exercise_images.ps1  ← 动作图片批量下载脚本
└── CODE_WIKI.md            ← 本文档
```

> 仓库根目录下的 `1.25.15` 为历史遗留文件（内容为一段版本号/文本），非工程代码。

---

## 3. 整体架构与分层

采用经典分层结构，**未引入独立状态管理框架**（Provider/Bloc/Riverpod），而是通过 `Storage` 内存缓存 + `ValueNotifier` + `setState` 组合管理状态。

```
┌───────────────────────────────────────────────┐
│                  UI 层 (pages/)                 │
│  约 76 个页面（启动流程 / 5 Tab / 大量子页面）     │
├───────────────────────────────────────────────┤
│              路由层 (router.dart)                │
│      go_router（ShellRoute + root 独立子路由）   │
├───────────────────────────────────────────────┤
│             通用组件 (widgets/)                  │
│  约 34 个组件（导航 / 海报 / 弹窗 / 选择器 / PK）  │
├───────────────────────────────────────────────┤
│              服务层 (services/)                  │
│  业务服务（通知/积分/成就/留存/PK/分享/推荐等）    │
│  └─ platform/ 平台抽象层 PAL（按平台注入实现）    │
├───────────────────────────────────────────────┤
│               数据层 (data/)                     │
│  Storage(混合持久化) + DatabaseHelper(SQLite v10)│
│  + SystemPlanLibrary + 各业务模型/静态数据       │
├───────────────────────────────────────────────┤
│         原生桥接 (MethodChannel / 原生通道)      │
│  OHOS: form / reminder / poster / alarm 通道    │
│  + 桌面卡片 FormExtension + LiveViewKit + 代理提醒│
│  Android: AlarmReceiver / 桌面小组件 / 前台服务   │
│  iOS: Live Activity                             │
└───────────────────────────────────────────────┘
```

---

## 4. 启动流程

`lib/main.dart` 的 `main()` 使用 `runZonedGuarded` 包裹整个应用，启动时序：

1. `WidgetsFlutterBinding.ensureInitialized()` + 注册 `FlutterError.onError`
2. `tz_data.initializeTimeZones()` + `tz.setLocalLocation(...)` — 初始化时区（必须在通知服务前，否则通知按 UTC 调度偏移 8 小时）
3. `Storage.init()` — 初始化混合持久化、SP→SQLite 迁移、生成 `deviceId`、初始化 premium 状态
4. 并行预加载：`SystemPlanLibrary.instance.load()` + `Storage.getPlansAsync()/getRecordsAsync()/getGymCardsAsync()/getNotesAsync()` + 积分日志
5. 并行初始化服务（互不依赖）：
   - `SoundService.instance.init()`（音效）
   - `RestNotificationService.instance.init()`（休息提醒）
   - `SmartPushService.instance.init()`（智能推送）
   - `RetentionChainService.instance.init()`（留存链）
   - `IapService.instance.init()`（内购）
   - `DailyReminderService.instance.init()`（每日提醒）
   - `GymCardReminderService.instance.init()`（健身卡提醒）
6. 启动后 fire-and-forget：`GymCardReminderService.checkAndPush()` + `reschedule()`
7. `PlatformServices.init()` — 初始化平台抽象层（PAL），按平台注入 RestReminder/LiveView/WidgetCard/InviteUrl 实现
8. 注册邀请链接处理器（`fittrack://invite?code=XXX` → `/home?inviteCode=`）
9. **[OHOS]** 注册 `OhosReminderService.onCardClick`，将原生卡片点击统一转发到 PAL 事件流（`OhosWidgetCardService.handleCardClick` / `OhosLiveViewService.handleCardClick`）
10. `runApp(const LiftTrackApp())`

`LiftTrackApp`（`StatefulWidget` + `WidgetsBindingObserver`）职责：

- 持有当前主题 ID、明暗模式配置（`off`/`system`/`timed`）与 `GoRouter` 实例（`_globalRouter` 全局引用供卡片点击导航）
- `_onThemeChanged()`：切换主题时 `setState` + `Storage.saveSettings` + 推送桌面卡片空闲态数据
- `_maybePromptFirstNightMode()`：首次进入夜间且用户从未被询问时弹夜间模式引导（8 秒超时自动关闭）
- `_restartTimedTimerIfNeeded()`：`timed` 模式下每分钟重算深浅主题，实现"到点自动切换"
- `didChangeAppLifecycleState(resumed)`：回到前台时依次执行智能推送检查、每日/健身卡提醒重排、每日提醒补登记、ROM 适配复查、夜间引导复查
- `_checkRomAdaptationOnStartup/OnResume()`：Android 专属 ROM 自启动引导（用户关闭后 7 天内不重复弹）

---

## 5. 主要模块职责

### 5.1 数据层 (lib/data/)

| 文件 | 职责 |
|------|------|
| `storage.dart` | **统一数据访问层**：混合持久化（SQLite + SharedPreferences + 内存缓存），提供同步/异步双接口；持有全局可观测状态 `isPremiumNotifier`、`unlockedAchievementsNotifier`；通知存储；匿名统计/deviceId 生成 |
| `database_helper.dart` | SQLite 管理（`fittrack.db` v10）：`plans`/`records`/`gym_cards`/`achievements`/`notes`/`courses`/`user_courses` 七张表 + CRUD + 迁移 |
| `system_plan_library.dart` | 系统计划库：`SystemPlan`/`SystemPlanDay`/`SystemPlanExercise` 模型 + `SystemPlanLibrary` 单例（内置增肌/减脂/塑形/保持/力量 5 类计划） |
| `virtual_goods.dart` | 虚拟物品：`VirtualGood` 模型 + `VirtualGoodsStore`（积分购买/解锁状态） |
| `virtual_opponent.dart` | 虚拟对手系统：`VirtualOpponent` 模型（tier/persona/周数据/皮肤）+ `VirtualOpponentEngine` 单例（人设与动态模板生成） |
| `course_content.dart` | 系统化课程：`Course`/`Chapter` 模型（含 blocks、推荐动作、积分奖励） |
| `tutorial_content.dart` | 动作教学库：`Tutorial` 模型（类型/难度/主肌群/要点/常见错误/解锁要求/富文本 blocks） |
| `training_note.dart` | 训练笔记：`TrainingNote` 模型（心情/最佳动作/酸痛部位/正文） |
| `weight_comparisons.dart` | 趣味重量对比：`WeightComparison.forWeight(kg)` 按重量区间返回趣味描述 |
| `content_block.dart` | 富文本块：`ContentBlock` 模型（heading/paragraph/image/quote/bulletList/exerciseCard/callout） |
| `mock_data.dart` | 静态 Mock 数据（动作库、问卷等） |
| `contact_info.dart` / `legal/legal_content.dart` | 联系方式与法律文本常量 |

### 5.2 模型层 (lib/models/)

| 文件 | 职责 |
|------|------|
| `notification_record.dart` | `NotificationRecord`（id/type/title/body/createdAt/read）— 应用内通知记录 |

### 5.3 服务层 (lib/services/)

#### 提醒 / 通知类

| 服务 | 职责 |
|------|------|
| `RestNotificationService` | 休息结束提醒：Dart Timer（前台）+ 平台后台提醒（PAL）+ 本地通知 + 振动，三重机制 |
| `DailyReminderService` | 每日训练提醒：按用户 `trainingTime` 调度每日提醒，区分 OHOS/Android/iOS 行为，回前台重排 |
| `GymCardReminderService` | 健身卡到期/次数阈值提醒：检查→推送→调度后台一次性提醒，同日只推一次 |
| `SmartPushService` | 智能推送：20:00 默认调度、7 天内≤2 次、同天去重、opt-out 开关、`_PushStrategy` 策略选择 |
| `OhosReminderService` | OHOS 后台代理提醒（`com.lt.lifttrack/reminder` 通道）：发布/取消提醒、每日训练提醒、健身卡提醒、通知/卡片点击回调 |
| `AndroidAlarmService` | Android 原生闹钟（`com.lt.lifttrack/alarm` 通道）：调度/取消休息提醒闹钟 |
| `PermissionService` | 权限管理：通知权限申请、状态检查、拒绝引导弹窗 |
| `RomAdaptationService` | Android ROM 适配：检测是否需要自启动引导、评估是否已优化 |
| `ReminderScheduleCalculator` | 提醒调度计算辅助：`ReminderCandidate`（休息结束/次日提醒触发时间计算） |

#### 积分 / 成就 / 解锁类

| 服务 | 职责 |
|------|------|
| `PointsService` | 积分体系核心：加/扣积分、签到、训练/广告积分、功能解锁、积分日志 |
| `AchievementService` | 成就系统：成就定义、按训练/统计/计划/分享条件判定并解锁、成就弹窗（依赖 DB/Storage/Points/Sound） |
| `PlanUnlockService` | 精品计划解锁：扣积分、写解锁记录、清理过期记录 |
| `AdService` / `SimulatedAdService` | 广告抽象 + 模拟实现：广告开关、激励视频展示、广告积分 |
| `IapService` | 应用内购买（Android/iOS）：购买/恢复 Pro、本地标记 premium（OHOS 走兑换码） |
| `RedeemService` | 兑换码（`FITT-XXXX-...`）：格式/签名/重复使用校验，成功标记 premium（HMAC 签名） |

#### 留存 / 分享 / 推荐类

| 服务 | 职责 |
|------|------|
| `RetentionChainService` | 新手 7 天留存链：Day2/Day4/Day7 推送或周报弹窗，记录首次训练日、连续天数 |
| `InvitationService` | 邀请码：生成/验证/激活（HMAC 签名、防自邀、一码一绑、积分奖励、识别码 FIT-ACT） |
| `ClipboardInviteService` | 剪贴板邀请码处理 |
| `ShareCodeService` | 分享码：编码/解码分享内容，`ShareCodeImportResult` 校验结果 |
| `ShareCardService` | 训练记录分享卡片生成 |
| `PosterGenerator` | 海报截图生成：RepaintBoundary 截取 widget 为 PNG 写入临时目录（含 OHOS 兼容） |
| `PosterShareService` | OHOS 海报保存/分享（`com.lt.lifttrack/poster` 通道）：保存相册、分享图片/文本、读写权限 |
| `RecommendationService` | 推荐横幅：生成教学/课程/计划/成就/邀请等 `BannerItem` 列表 |
| `PlanRecommendationService` | 计划推荐算法：`ScoreResult`/`PlanRecommendation`，评分排序 |

#### 数据 / 业务辅助类

| 服务 | 职责 |
|------|------|
| `MaxWeightService` | 最大重量统计：扫描记录计算全局最大重量、按部位 Top N、推断肌肉部位 |
| `WeightRecommendationService` | 重量推荐：`ExerciseWeightSuggestion`，根据历史给动作推荐起手重量 |
| `RestPreferenceService` | 休息时间偏好：基于历史休息记录（IQR 过滤 + 加权平均）推荐休息秒数 |
| `NotificationStorageService` | 应用内通知记录存储（对接 Storage） |
| `SoundService` | 音效：按钮/完成/休息/积分/成就等 8 种音效播放 |
| `UserProfileGenerator` | 用户档案生成：按性别/目标/水平生成用户名与头像 |
| `FormKitService` | OHOS 桌面卡片（`com.lt.lifttrack/form` 通道）：idle/training/rest 三态管理 + 主题色同步 + 推送串行化 |

#### 平台抽象层 PAL（services/platform/）

| 文件 | 职责 |
|------|------|
| `platform_services.dart` | **平台服务工厂**：`PlatformServices.init()` 按平台注入 `restReminder`/`liveView`/`widgetCard`/`inviteUrl` 四类服务 |
| `rest_reminder_service.dart` | 抽象接口 `RestReminderService` + `RestReminderEvent` |
| `live_view_service.dart` | 抽象接口 `LiveViewService` + `LiveViewEvent` |
| `widget_card_service.dart` | 抽象接口 `WidgetCardService` + `WidgetCardClickEvent`/`WidgetCardData`（mode: idle/training/rest） |
| `invite_url_service.dart` | 抽象接口 `InviteUrlService` |
| `noop_platform_services.dart` | 桌面/调试平台的空实现（Noop 系列） |
| `implementations/ohos_*` | OHOS 实现：`OhosRestReminderService`/`OhosLiveViewService`/`OhosWidgetCardService`/`OhosInviteUrlService` |
| `implementations/android_*` | Android 实现：闹钟提醒/`AndroidLiveViewService`/桌面小组件/深链 |
| `implementations/ios_*` | iOS 实现：本地通知/`IosLiveViewService`(Live Activity)/小组件/深链 |

### 5.4 页面层 (lib/pages/)

约 76 个页面，按功能域分组：

#### 启动 / 引导流程

| 页面 | 类名 | 职责 |
|------|------|------|
| `splash_page.dart` | `SplashPage` | 启动动画页，决定流向（privacy/onboarding/home） |
| `onboarding_page.dart` | `OnboardingPage` | 新手引导 |
| `questionnaire_page.dart` | `QuestionnairePage` | 健身问卷（性别/目标/水平），产出 profileData |
| `plan_recommend_page.dart` | `PlanRecommendPage` | 问卷后的计划推荐页 |

#### 底部导航 5 个 Tab（ShellRoute）

| 页面 | 类名 | 职责 |
|------|------|------|
| `home_page.dart` | `HomePage` | 首页：今日概览 + 快捷入口 + 留存链/邀请检测/教练引导 |
| `plan_page.dart` | `PlanPage` | 计划列表：过滤/排序/新建/编辑/删除 |
| `tutorial_list_page.dart` | `TutorialListPage` | 教学中心：推荐 banner + 精选课程 + 推荐教学 |
| `stats_page.dart` | `StatsPage` | 统计分析：周/月图表、肌肉分布、个人记录、热力图 |
| `profile_page.dart` | `ProfilePage` | 个人中心：身体数据/设置/streak/成就评估弹窗 |

#### 训练 / 记录

| 页面 | 类名 | 职责 |
|------|------|------|
| `training_page.dart` | `TrainingPage` | **核心训练执行页**：组间休息倒计时、实时记录、进行中训练持久化/恢复、与 FormKit/实况窗/提醒服务交互 |
| `exercise_page.dart` | `ExercisePage` | 动作库/动作详情：动作步骤、添加进计划 |
| `records_page.dart` | `RecordsPage` | 训练记录列表 |
| `record_detail_page.dart` | `RecordDetailPage` | 单条训练记录详情 |
| `note_list_page.dart` | `NoteListPage` | 训练笔记列表 |
| `note_edit_page.dart` | `NoteEditPage` | 训练笔记编辑 |
| `note_poster_page.dart` | `NotePosterPage` | 训练笔记海报生成 |
| `reminder_settings_page.dart` | `ReminderSettingsPage` | 提醒设置（每日训练提醒时间等） |
| `notification_test_page.dart` | `NotificationTestPage` | 通知测试页 |
| `banner_notification_guide_page.dart` | `BannerNotificationGuidePage` | 横幅通知开启引导 |

#### 计划管理 / 计划库

| 页面 | 类名 | 职责 |
|------|------|------|
| `add_plan_page.dart` | `AddPlanPage` | 新建/编辑计划（`editPlanId` 参数） |
| `plan_detail_page.dart` | `PlanDetailPage` | 计划详情（接收 `planId`） |
| `plan_create_guide_page.dart` | `PlanCreateGuidePage` | 创建计划引导 |
| `plan_library_home_page.dart` | `PlanLibraryHomePage` | 系统计划库首页（目标卡片） |
| `plan_library_category_page.dart` | `PlanLibraryCategoryPage` | 计划库分类列表 |
| `plan_library_detail_page.dart` | `PlanLibraryDetailPage` | 计划库详情 |
| `plan_search_page.dart` | `PlanSearchPage` | 计划搜索（历史词） |
| `plan_weight_confirm_page.dart` | `PlanWeightConfirmPage` | 采用系统计划时的重量确认（extra 传 `SystemPlan`） |
| `plan_qr_code_page.dart` | `PlanQrCodePage` | 计划分享二维码（`/plan-qr/:planId`） |
| `plan_poster_page.dart` | `PlanPosterPage` | 计划分享海报（`/plan-poster/:planId`） |

#### 教学 / 课程

| 页面 | 类名 | 职责 |
|------|------|------|
| `all_tutorials_page.dart` | `AllTutorialsPage` | 全部教学（分类卡片） |
| `tutorial_category_page.dart` | `TutorialCategoryPage` | 教学分类详情 |
| `tutorial_detail_page.dart` | `TutorialDetailPage` | 教学详情（要点/错误/富文本） |
| `tutorial_search_page.dart` | `TutorialSearchPage` | 教学搜索 |
| `course_list_page.dart` | `CourseListPage` | 系统化课程列表 |
| `course_detail_page.dart` | `CourseDetailPage` | 课程详情 |
| `chapter_read_page.dart` | `ChapterReadPage` | 章节阅读 |

#### 身体数据 / 统计

| 页面 | 类名 | 职责 |
|------|------|------|
| `body_data_page.dart` | `BodyDataPage` | 身体数据：BMI 实时计算、体重趋势折线图（CustomPaint 自绘） |
| `max_weight_detail_page.dart` | `MaxWeightDetailPage` | 最大重量详情（按部位） |

#### 个人中心 / 设置 / 游戏化

| 页面 | 类名 | 职责 |
|------|------|------|
| `settings_page.dart` | `SettingsPage` | 设置（训练默认值/数据管理/主题入口） |
| `theme_settings_page.dart` | `ThemeSettingsPage` | 风格主题设置（PageView 卡片预览 + 明暗模式） |
| `gym_card_page.dart` | `GymCardPage` | 健身卡管理 |
| `gym_card_stats_page.dart` | `GymCardStatsPage` | 健身卡统计 |
| `points_detail_page.dart` | `PointsDetailPage` | 积分明细 |
| `achievement_page.dart` | `AchievementPage` | 成就中心 |
| `honor_wall_page.dart` | `HonorWallPage` | 荣誉墙 |
| `opponent_detail_page.dart` | `OpponentDetailPage` | 虚拟对手详情（皮肤预览/皮肤切换） |
| `redeem_page.dart` | `RedeemPage` | 兑换码输入 |
| `invitation_page.dart` | `InvitationPage` | 邀请有礼 |
| `share_code_page.dart` | `ShareCodePage` | 我的分享码 |
| `scan_import_page.dart` | `ScanImportPage` | 扫码/相册导入计划 |
| `qr_scan_page.dart` | `QrScanPage` | 二维码扫描（mobile_scanner） |

#### 法律 / 关于

| 页面 | 类名 | 职责 |
|------|------|------|
| `privacy_policy_page.dart` | `PrivacyPolicyPage` | 隐私政策全文 |
| `user_agreement_page.dart` | `UserAgreementPage` | 用户协议 |
| `data_privacy_page.dart` | `DataPrivacyPage` | 数据隐私管理 |
| `privacy_security_page.dart` | `PrivacySecurityPage` | 隐私安全 |
| `help_feedback_page.dart` | `HelpFeedbackPage` | 帮助与反馈 |
| `about_page.dart` | `AboutPage` | 关于 |
| `contact_page.dart` | `ContactPage` | 联系我们 |
| `logo_preview_page.dart` | `LogoPreviewPage` | Logo 预览（多种设计稿，CustomPainter 绘制） |

### 5.5 组件层 (lib/widgets/)

#### 通用基础

| 组件 | 职责 |
|------|------|
| `bottom_nav.dart` | `BottomNav` 悬浮胶囊底部导航（5 Tab，活动项缩放动画） |
| `page_header.dart` | `PageHeader` 页面标题（返回/副标题/铃铛/日历/搜索，毛玻璃） |
| `common_widgets.dart` | 通用组件集合：StatCard/SectionHeader/BadgeWidget/ConfirmDialog/FitToast/FitBottomSheet/FitTextField/FitChipSelector/EmptyState 等 |
| `tab_refresh_mixin.dart` | `TabRefreshMixin` 供 Tab 页刷新复用 |

#### 海报 / 分享

| 组件 | 职责 |
|------|------|
| `poster_theme.dart` | `PosterColors.fromThemeId()` 海报配色 + `PosterBackground` 统一渐变背景 |
| `poster_capture_helper.dart` | `PosterCaptureHelper` 统一"渲染→等待绘制→截图→预览弹窗"流程 |
| `poster_preview_dialog.dart` | `PosterPreviewDialog` 海报预览弹窗（保存/分享） |
| `plan_poster_widget.dart` | `PlanPosterWidget` 计划海报内容 |
| `note_poster.dart` | `NotePosterContent` 训练笔记海报内容（1080×1920） |
| `gym_card_poster.dart` | `GymCardPoster` 健身卡海报 |
| `invite_poster.dart` | `InvitePoster` 邀请码海报内容 |
| `share_card_frame.dart` | `ShareCardFrame` 训练记录分享海报框架（1080 宽） |
| `tutorial_poster.dart` | `TutorialPoster` 教学分享海报 |
| `tutorial_share_card.dart` | `TutorialShareCardSheet` 教学分享底部弹层 |

#### 训练 / 计划组件

| 组件 | 职责 |
|------|------|
| `exercise_set_table.dart` | `ExerciseSetTable` 逐组训练配置表格 |
| `exercise_picker_sheet.dart` | `ExercisePickerSheet` 动作选择器（统一参数/逐组设置） |
| `custom_time_picker.dart` | `CustomTimePicker` 主题风滚轮时间选择器 |
| `fit_date_picker_sheet.dart` | `FitDatePickerSheet` 日历网格日期选择器 |
| `default_exercise_cover.dart` | `DefaultExerciseCover` 动作默认封面（emoji + 渐变色） |

#### 游戏化 / 留存组件

| 组件 | 职责 |
|------|------|
| `celebration_dialog.dart` | `CelebrationDialog` 训练完成庆祝弹窗 |
| `celebration_overlay.dart` | `CelebrationOverlay` OverlayEntry 庆祝动效 |
| `achievement_badge.dart` | `AchievementBadge` 成就徽章 |
| `virtual_opponent_card.dart` | `VirtualOpponentCard` 虚拟对手 PK 卡片（周对比/超越百分比） |
| `max_weight_card.dart` | `MaxWeightCard` 最大重量卡片 |
| `recommendation_banner.dart` | `RecommendationBanner` 推荐横幅轮播 |
| `rating_prompt_sheet.dart` | `RatingPromptSheet` 评分提示（`shouldShow`/`maybeShow` 静态方法） |
| `unlock_panel.dart` | `UnlockPanel` 功能解锁面板（广告/积分） |
| `onboarding_coach.dart` | `OnboardingCoach` 新手教练引导气泡 |
| `rom_guidance_sheet.dart` | `RomGuidanceSheet` ROM 自启动引导弹层 |
| `notification_list_sheet.dart` | `NotificationListSheet` 应用内通知列表（标记已读/清空） |
| `simulated_ad_page.dart` | `SimulatedAdPage` 模拟激励视频广告页 |

#### 虚拟对手渲染子系统（widgets/opponent/）

虚拟对手的"皮肤 → 逐帧动画 → 绘制"链路独立收敛到 `widgets/opponent/` 子目录，与数据引擎 `data/virtual_opponent.dart` 解耦：

| 文件 | 职责 |
|------|------|
| `opponent_skin_config.dart` | 皮肤定义与配置：`SkinPalette`（配色方案）、`TrainBias`（复合/孤立/有氧/核心训练偏好权重）、`MotionFrame`（单帧姿势描述）、`MotionSpec`、`SkinSpec` 及各内置皮肤配置 |
| `opponent_renderer.dart` | `OpponentRenderer` 画布渲染组件：按 `skinId`/`size`/`autoTrain`/`showAura`/`animate` 在 CustomPainter 中绘制对手形象（含气焰效果与训练中动作切换） |
| `video_frame_animation.dart` | 逐帧动画播放：加载 `assets/opponent/video_frames/{skin}_{idle\|train}/` 帧序列并按进度播放 |
| `motion/motion_player.dart` | 程序化运动插值器：`interpolateMotion(MotionSpec, progress)` 按进度在帧之间插值出当前 `MotionFrame` 参数（循环映射帧索引） |

> 素材约定：对手主体占画布 70%+，服饰绘制尺寸 160×190、道具 100×100 以保证比例协调。

### 5.6 主题 (lib/themes/app_themes.dart)

- `LiftTrackColors` — `ThemeExtension` 主题色板（bgSecondary/bgCard/bgElevated/accentGlow/accentSecondary/textPrimary/textSecondary/textMuted/borderColor/successColor/warningColor/infoColor/purpleColor），实现 `copyWith`/`lerp`
- `AppTheme.getTheme(themeId)` — 按 ID 返回完整 `ThemeData`（colorScheme + extensions + card/appBar/button/text/input/divider/bottomNav/FAB/chip/progress 全量配置）
- `AppTheme.themes` — 7 套主题元信息（id/name/desc/icon/colors）
- `LiftTrackTheme` — 主题辅助（`isTimedDarkNow(timeStr)` 等）

### 5.7 工具 (lib/utils/)

| 文件 | 职责 |
|------|------|
| `platform_utils.dart` | `isOhos` / `isIos` 平台判断（替代 `Platform.isOhos` 直接判断，便于测试替换） |
| `art_assets.dart` | 动作/课程艺术图资源映射 |
| `gender_filter.dart` | 性别过滤（动作/计划按性别筛选） |

---

## 6. 关键类与函数说明

### 6.1 `Storage`（data/storage.dart）

静态类，混合持久化层。核心方法：

| 方法 | 说明 |
|------|------|
| `Future<void> init()` | 初始化 SP + 加载轻量数据 + SP→SQLite 迁移 + 旧 followSystem 迁移 + 生成 deviceId + 初始化 premium |
| `getPlansAsync()/getPlans()` | 计划异步加载（脏标记重载缓存）/ 同步读缓存深拷贝 |
| `addPlanAsync()/addPlan()` | 计划新增（异步/同步版） |
| `updatePlanAsync()/updatePlan()` | 计划更新（缓存 merge + 异步落盘） |
| `deletePlanAsync()/deletePlan()` | 计划删除 |
| `getPlanByIdAsync()/getPlanById()` | 按 ID 查计划 |
| `getRecordsAsync()/getRecords()` | 记录读取 |
| `addRecord(record)` | **关键**：插入缓存头部（限 500 条）+ 触发 `dataChanged` + 异步落盘 + `trimRecords(500)` + `updateStats()` 增量更新统计 |
| `deleteRecord()/getRecordById()` | 记录删除/查询 |
| `getSettings()/saveSettings()` | 设置读写（含默认值） |
| `getStats()/updateStats(record)/recalcStatsAsync()` | 统计读取 / 增量更新 / 全量重算 |
| `getBodyData()/saveBodyData()/getBodyDataHistory()/saveBodyDataHistory()` | 身体数据与历史（限 50 条） |
| `addGymCard()/updateGymCard()/deleteGymCard()` | 健身卡 CRUD（同步+异步双版本） |
| `exportAllDataAsync()/importDataAsync()` | 数据导出/导入（JSON，覆盖式） |
| `clearAll()` | 清空全部数据 |
| `hasData()/initDemoData()` | 是否有数据 / 首次启动初始化演示计划 |
| `saveInProgressTraining()/getInProgressTraining()/clearInProgressTraining()` | 进行中训练持久化/读取/清除 |
| `getNotifications()/saveNotification()/markNotificationRead()/clearNotifications()` | 应用内通知记录 |
| `setPremium()/isPremiumNotifier` | Pro 状态 |

**SharedPreferences 存储键**（实际统一加 `fittrack_` 前缀）：

| 常量 | 实际键 | 内容 |
|------|--------|------|
| `_keySettings` | `fittrack_fitplan_settings` | 设置 JSON |
| `_keyStats` | `fittrack_fitplan_stats` | 统计 JSON |
| `_keyBodyData` | `fittrack_fitplan_bodyData` | 当前身体数据 |
| `_keyBodyDataHistory` | `fittrack_fitplan_bodyDataHistory` | 身体数据历史（≤50 条） |
| `_keyMigrated` | `fittrack_sqlite_migrated` | SP→SQLite 迁移完成标记 |
| `_keyNotifications` | `fittrack_notifications` | 应用内通知 |

### 6.2 `DatabaseHelper`（data/database_helper.dart）

单例（`DatabaseHelper.instance`），管理 `fittrack.db`（**version 10**），七张表。详见 [第 11 章](#11-数据库设计)。

### 6.3 `SystemPlanLibrary`（data/system_plan_library.dart）

- 单例 `SystemPlanLibrary.instance`，`isLoaded`/`all` 状态，`load()` 加载 `assets/data/system_plans/{bulk,cut,keep,shape,strength}.json`
- 模型 `SystemPlan`（goal/days/frequency 等）+ `toStoragePlan()` 转为可写计划的格式（含 `sourcePlanId`/`isFromSystemLibrary`）

### 6.4 `VirtualOpponentEngine`（data/virtual_opponent.dart）

- `VirtualOpponent`：id/nickname/tier/avatarSeed/persona/周训练数据/上周数据/当前状态/`appliedSkinId`
- `VirtualOpponentEngine.instance`：人设模板 + 动态模板，生成与推进虚拟对手数据（周推进、重量系数按动作类型等）

### 6.5 `VirtualGoodsStore`（data/virtual_goods.dart）

- `VirtualGood`：id/name/category/pointsCost/emoji/unlockCondition/isLimited/metadata
- `VirtualGoodsStore`：商品清单、按 id/类别查询、积分可购买判断、`unlock()` 扣积分并写入 `unlockedFeatures`

### 6.6 核心训练页 — `TrainingPage`（pages/training_page.dart）

训练执行核心状态：当前动作/组索引、完成状态、休息阶段、通知权限、记录、定时器和 PAL 订阅。

核心流程：
1. 进入时按 `params['planId']`/`dayIndex` 加载计划与当日动作；检查是否有进行中训练（同天/跨天）可恢复
2. 完成一组 `_completeSet()` → 记录重量/次数/休息 → 判断是否完成 → 否则启动组间休息
3. 休息开始：推送桌面卡片 `rest` 态 + 启动实况窗（OHOS/iOS）+ `RestNotificationService.scheduleRestEndNotification()`（后台提醒）
4. 休息结束 `_advanceAfterRest()`：记录实际休息秒数、停止实况窗、推进下一组/下一动作
5. 全部完成 `_saveAndReturn()`：计算时长/重量/组数 → `Storage.addRecord()`（增量更新统计）→ 保存 `planId/planName` → 推进计划 `currentDayIndex` → 推送卡片 `idle` 态 + 取消实况窗
6. `WillPopScope` 清理卡片状态；`_buildBody` 按动作是否存在/是否完成/是否休息显示不同界面

### 6.7 路由系统 — `router.dart`

`createRouter()` 返回 `GoRouter`，`initialLocation: '/splash'`。路由结构：

```
启动流程：/splash → /privacy → /onboarding → /questionnaire → /recommend
ShellRoute（带底部导航 5 Tab）：
  /home /plan /tutorial /stats /profile
root 独立子路由（无底部导航）：
  /training(?planId&dayIndex)  /plan/:planId
  /records  /records/:recordId
  /add-plan(?editPlanId)  /plan-guide
  /plan-library  /plan-library/detail/:planId  /plan-library/:goal
  /plan-weight-confirm(extra:SystemPlan)  /plan-search
  /exercise  /settings  /theme-settings  /notification-test  /reminder-settings
  /banner-notification-guide
  /gym-card  /gym-card-stats  /body-data
  /privacy-full  /agreement  /data-privacy  /about  /privacy-security  /help-feedback  /contact
  /achievements  /honor-wall  /redeem  /invitation  /share-code
  /plan-qr/:planId  /scan-import  /plan-poster/:planId
  /tutorial/:tutorialId  /all-tutorials  /tutorial-search  /tutorials/:category
  /course  /course/:courseId  /course/:courseId/chapter/:chapterId
  /points-detail  /max-weight-detail  /opponent-detail  /logo-preview
  /note  /note/edit  /note/edit/:recordId
```

- **AppShell**：`IndexedStack` 缓存 5 个 Tab（`_children` 列表首帧初始化），避免反复创建销毁导致 Ink splash 崩溃；`BottomNav` 悬浮于底部
- `currentTabIndex`（`ValueNotifier<int>`）：按路径推导当前 Tab（`/plan`→1、`/tutorial`→2、`/stats`→3、`/profile`→4）
- `onThemeChanged`：顶层可空回调，由 `main.dart` 注入
- `_PrivacyPolicyPage`：router 内私有页，"不同意"调用 `SystemNavigator.pop()` 退出

### 6.8 平台抽象层 — `PlatformServices`（services/platform/platform_services.dart）

```dart
PlatformServices.init() // 按 isOhos / Platform.isAndroid / Platform.isIOS / 其它 注入实现
  .restReminder  → RestReminderService（OHOS 代理提醒 / Android 闹钟 / iOS 本地通知）
  .liveView      → LiveViewService（OHOS LiveViewKit / Android 前台服务 / iOS Live Activity）
  .widgetCard    → WidgetCardService（OHOS 桌面卡片 / Android 小组件 / iOS 小组件）
  .inviteUrl     → InviteUrlService（深链注册与解析）
```

OHOS 侧额外暴露 `ohosLiveView` / `ohosWidgetCard` 具名 getter 供 `main.dart` 注册原生点击回调。

### 6.9 关键服务方法速查

| 服务 | 关键方法 |
|------|---------|
| `RestNotificationService` | `init()` / `scheduleRestEndNotification({exerciseName, delaySeconds})` / `showRestEndNotification()` / `cancelScheduledNotification()` / `cancelAll()` / `static vibrate()` |
| `OhosReminderService` | `initListener()` / `publishReminder({title, content, triggerTimeInSeconds, notificationId})` / `cancelCurrentReminder()` / `cancelAllReminders()` / `scheduleTrainingReminder({title, content, timeStr})` / `scheduleGymCardReminder()` / `cancelTrainingReminder()`；回调 `onNotificationClick`/`onCardClick`/`onTrainingCardAction` |
| `SmartPushService` | `init()` / `maybePushNow()` / `scheduleDailyCheck()` / `publishSmartPushNow()` / `cancelSmartPushReminder()` |
| `DailyReminderService` | `init()` / `reschedule()` / `checkAndRecordNotification()` |
| `GymCardReminderService` | `init()` / `checkAndPush()` / `reschedule()` |
| `PointsService` | `getPoints()` / `addPoints()` / `spendPoints()` / `checkIn()` / `addTrainingPoints()` / `addAdPoints()` / `unlockFeature()` / `getPointsLog()` |
| `AchievementService` | `init()` / `evaluateAchievements()` / `isUnlocked()` / 成就定义列表 |
| `InvitationService` | `generateCode()` / `validateCode()` / `activateCode()` / `signCode()` |
| `RedeemService` | `validateAndRedeem(code)` |
| `IapService` | `init()` / `buyPremium()` / `restorePurchases()` / `markPremiumLocally()` |
| `FormKitService` | `init()` / `startTraining()` / `startRest()` / `updateTrainingState()` / `updateRestSeconds()` / `endTraining()` / `pushFormData()` / `requestFormUpdate()` |
| `UserProfileGenerator` | `generateUserName()` / `generateUserNameOptions()` / `generateAvatar()` / `getAllAvatars()` / `buildAvatarWidget()` |
| `MaxWeightService` | `getGlobalMax()` / `getTopByBodyPart()` |
| `WeightRecommendationService` | `suggestWeight()` |
| `RestPreferenceService` | `getRecommendedRestSeconds()` |
| `RetentionChainService` | `init()` / 周报/留存推送判定 |

---

## 7. 数据流与状态管理

### 7.1 状态管理方案

- **内存缓存** — `Storage` 维护所有数据缓存（`_plansCache`/`_recordsCache`/`_gymCardsCache`/`_store`），脏标记 `_*CacheDirty` 控制何时从 SQLite 重载
- **ValueNotifier** — `Storage.dataChanged`（跨页通知）、`Storage.isPremiumNotifier`（Pro 状态）、`Storage.unlockedAchievementsNotifier`、`currentTabIndex`（导航高亮）
- **setState** — 页面内部状态
- **GoRouter** — 路由状态

### 7.2 核心数据流

```
用户操作 (UI)
  → 页面 State 方法
    → Storage 同步方法（更新内存缓存）
      → 异步持久化到 SQLite / SharedPreferences
      → Storage.dataChanged 通知其他页面刷新
    → [OHOS] FormKitService.pushFormData()（同步桌面卡片）
    → [OHOS/iOS] PlatformServices.liveView（同步实况窗）
```

### 7.3 主题变更流

```
SettingsPage / ThemeSettingsPage 切换主题
  → onThemeChanged(themeId, {autoDarkMode, lightThemeId, darkThemeId, ...})
    → LiftTrackApp.setState()（重建 MaterialApp，theme/darkTheme/themeMode）
    → Storage.saveSettings()（持久化）
    → PlatformServices.widgetCard.pushCardData(idle)（同步卡片颜色）
```

### 7.4 平台抽象（PAL）调用流

```
TrainingPage 休息开始
  → PlatformServices.restReminder.scheduleRestEnd(...)   // 后台提醒
  → PlatformServices.liveView.startRest(...)             // 实况窗
  → PlatformServices.widgetCard.pushCardData(rest)       // 桌面卡片
PAL.init() 在 main.dart 启动时按平台选择实现，业务代码不感知平台差异
```

---

## 8. 依赖关系

### 8.1 第三方依赖（pubspec.yaml）

> Flutter SDK 约束：`sdk: '>=2.19.6 <3.0.0'`。部分包为适配 HarmonyOS 使用 **gitcode 上的 OHOS 定制分支**。

| 依赖 | 来源/版本 | 用途 |
|------|-----------|------|
| `flutter` | SDK | UI 框架 |
| `shared_preferences` | gitcode（openharmony-tpc OHOS 定制） | 轻量键值存储 |
| `sqflite` | gitcode（CPF-Flutter OHOS 适配） | SQLite 数据库 |
| `permission_handler` | gitcode（CPF-Flutter OHOS 适配） | 权限管理 |
| `flutter_local_notifications` | gitcode（openharmony-sig，ref: master） | 本地通知 |
| `go_router` | ^6.5.0 | 声明式路由 |
| `path_provider` | ^2.1.0 | 路径 |
| `share_plus` | ^7.0.0 | 分享 |
| `crypto` | ^3.0.3 | HMAC 签名（兑换码/邀请码） |
| `qr_flutter` | ^4.0.0 | 二维码生成 |
| `mobile_scanner` | ^3.5.5 | 二维码扫描 |
| `in_app_purchase` | ^3.1.0 | 应用内购买 |
| `timezone` | ^0.9.4 | 时区（定时通知） |
| `image_gallery_saver` | ^2.0.3 | 保存图片到相册 |
| `audioplayers` | ^4.0.0 | 音效播放 |
| `image_picker` | gitcode（CPF-Flutter，ohos 分支） | 相册选图（扫码导入） |
| `zxing2` | 0.2.0 | 纯 Dart 二维码解码（OHOS 扫码兜底） |
| `fl_chart` | ^0.61.0 | 图表 |
| `url_launcher` | gitcode（openharmony-tpc OHOS 适配） | 打开外部链接/应用市场 |
| `path` | ^1.8.0 | 路径拼接 |
| `cupertino_icons` | ^1.0.2 | iOS 风格图标 |
| `flutter_lints`（dev） | ^2.0.0 | 代码规范 |
| `sqflite_common_ffi`（dev） | gitcode（CPF-Flutter） | 桌面端测试用 SQLite |

### 8.2 模块间依赖

```
main.dart
├── data/storage.dart ──→ data/database_helper.dart ──→ sqflite
├── data/system_plan_library.dart
├── services/platform/platform_services.dart
│   ├── implementations/ohos_*（MethodChannel → EntryAbility）
│   ├── implementations/android_*（MethodChannel → MainActivity/Receivers）
│   └── implementations/ios_*
├── services/{permission,rest_notification,smart_push,iap,ohos_reminder,
│             rom_adaptation,retention_chain,points,sound,daily_reminder,
│             gym_card_reminder}_service.dart
├── router.dart ──→ pages/* + widgets/bottom_nav.dart
└── themes/app_themes.dart

services/*（按需）
├──→ data/storage.dart / database_helper.dart
├──→ themes/app_themes.dart
├──→ widgets/*（如海报、弹窗）
└──→ 其它 services（Points ← Achievement/Invitation/Ad/IAP；Sound ← 全局）

pages/* ──→ services/* + widgets/* + data/storage.dart + themes/app_themes.dart
```

### 8.3 平台通道（MethodChannel）清单

| 通道名 | Dart 侧 | 原生侧（OHOS） | 用途 |
|--------|---------|---------------|------|
| `com.lt.lifttrack/form` | `FormKitService` | `EntryAbility` | 桌面卡片数据推送 |
| `com.lt.lifttrack/reminder` | `OhosReminderService` | `EntryAbility` | 后台代理提醒 |
| `com.lt.lifttrack/poster` | `PosterShareService` | `EntryAbility` | 海报保存/分享 |
| `com.lt.lifttrack/alarm` | `AndroidAlarmService` | Android `MainActivity` | 休息闹钟调度 |

---

## 9. 主题系统

### 9.1 主题访问方式

```dart
final colors = Theme.of(context).extension<LiftTrackColors>()!;
colors.bgCard;      // 卡片背景
colors.accentGlow;  // 主强调色
colors.textPrimary; // 主文本色
```

**约定**：组件统一通过 `LiftTrackColors` 取色，不硬编码颜色；海报场景使用 `PosterColors.fromThemeId()` 保持与应用主题一致。

### 9.2 主题清单（7 套）

| 主题 ID | 名称 | 亮度 | 主色 | 风格特征 |
|---------|------|------|------|---------|
| `vitality-sport` | 活力运动 | Light | `#FF6B35` | **默认主题**，大圆角(20)，w800 粗体 |
| `iron-forge` | 硬核铁馆 | Dark | `#ef4444` | 零圆角，3px 粗边框，letterSpacing 2（**默认暗色主题**） |
| `blossom` | 柔美花语 | Light | `#ec4899` | 超大圆角(24)，w600 |
| `silver-care` | 长者关怀 | Light | `#059669` | 超大字号，2px 边框 |
| `fresh-minimal` | 清新极简 | Light | `#0ea5e9` | 负字间距，细边框，大留白 |
| `neon-cyber` | 赛博霓虹 | Dark | `#d946ef` | 极小圆角，letterSpacing 3 |
| `black-gold` | 黑金尊享 | Dark | `#f59e0b` | 金色描边，letterSpacing 3 |

### 9.3 明暗模式

- 设置键：`autoDarkMode`（`off`/`system`/`timed`）、`lightThemeId`、`darkThemeId`、`timedDarkTime`（默认 `18:00`）
- `timed` 模式：`LiftTrackTheme.isTimedDarkNow()` 判断当前是否夜间，`_LiftTrackAppState` 每分钟 `setState` 重算 `themeMode`
- `system` 模式：`ThemeMode.system` 跟随系统

---

## 10. 平台特定功能

### 10.1 OHOS（主目标平台）

OHOS 原生代码位于 `fittrack_flutter/ohos/entry/src/main/ets/`：

```
ets/
├── entryability/EntryAbility.ets         ← FlutterAbility：注册 form/reminder/poster 通道、LiveViewKit 实况窗、buildTimerReminder 倒计时代理提醒、onNewWant 卡片点击
├── formability/FitTrackFormExtension.ets ← 桌面卡片 FormExtensionAbility（onAddForm/onUpdateForm/onRemoveForm）
├── pages/
│   ├── FitTrackWidget.ets                ← 卡片 UI（RestView/TrainingView/IdleView 三态）
│   └── Index.ets                         ← Flutter 引擎宿主页
└── plugins/GeneratedPluginRegistrant.ets ← 插件注册
```

**权限**（`module.json5` `requestPermissions`）：`INTERNET`、`PUBLISH_AGENT_REMINDER`（后台代理提醒）、`VIBRATE`、`WRITE_IMAGEVIDEO`（海报保存）等。

**桌面卡片**：`form_config.json` 定义"LiftTrack训练卡片"；卡片数据经 preferences 跨进程（`removePreferencesFromCacheSync()` 清缓存后 `formProvider.updateForm`），三态 idle/training/rest；`formProvider.updateForm()` 限流 10 次/分钟/卡片。

**实况窗（LiveViewKit）**：休息倒计时胶囊，TIMER 类型，`REST_LIVE_VIEW_ID=30001`，胶囊图标 `liveview_icon.png`，失败时降级为持续通知。

**后台代理提醒**：`buildTimerReminder` 构造 `ReadyMessageRequestTimer` 倒计时代理提醒（代理提醒管控下仅 TIMER 类型可触发）；每日训练提醒、健身卡到期提醒、智能推送（20:00）均走此方案；代理提醒为单次触发，需 App 每次启动/回前台 `reschedule` 重排。

### 10.2 Android

- 包名 `com.lt.lifttrack`，`compileSdkVersion 34`，`minSdkVersion 21`，Java 8 编译、Java 17 构建
- 权限：精确闹钟（`SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`）、通知、前台服务、存储、相机（扫码）等
- 组件：`MainActivity`、`AlarmReceiver`、`ScheduledNotificationReceiver`、`RestOngoingService`（实况/持续通知）、桌面小组件 AppWidget
- `RestNotificationService` 走 `zonedSchedule`（exactAllowWhileIdle + fullScreenIntent）；`AndroidAlarmService` 走原生闹钟
- ROM 适配：`RomAdaptationService` + `RomGuidanceSheet` 自启动引导

### 10.3 iOS

- `ios/RestLiveActivity/FitTrackWidget.swift`：Live Activity 实时活动（.systemSmall/.systemMedium），显示名"LiftTrack 训练卡片"
- `Podfile` 配置 `permission_handler_apple` 的 `GCC_PREPROCESSOR_DEFINITIONS`
- 深链：`fittrack://invite?code=XXX` 邀请链接处理
- 打包经 CI：`flutter build ipa` + `altool --apiKey --apiIssuer` 上传 TestFlight（见第 13 章）

---

## 11. 数据库设计

`fittrack.db`（SQLite，**version 10**），共 7 张表。结构化数据（Plans/Records/GymCards/Achievements/Notes/Courses/UserCourses）走 SQLite；轻量数据（Settings/Stats/BodyData）走 SharedPreferences。

### 11.1 `plans` 表

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | TEXT PK | 计划 ID |
| `name` | TEXT NOT NULL | 计划名称 |
| `type` / `difficulty` / `frequency` | TEXT | 类型/难度/频率 |
| `totalWeeks` / `defaultRestTime` | INTEGER | 总周数 / 默认休息（秒） |
| `week` / `progress` / `currentDayIndex` | INTEGER | 当前周 / 进度 / 当前日索引 |
| `status` / `badge` | TEXT | active/done/pending / 进行中/已完成/待开始 |
| `gender` | TEXT | 性别过滤（all/male/female） |
| `days` | TEXT | 每日训练内容（JSON 数组） |
| `sourcePlanId` / `isFromSystemLibrary` | TEXT / INTEGER | 来源系统计划标记 |
| `createTime` / `updateTime` | INTEGER | 时间戳 |

索引：`idx_plans_status`

### 11.2 `records` 表

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | TEXT PK | 记录 ID |
| `name` / `date` / `duration` | — | 训练名 / 日期 / 时长 |
| `totalWeight` / `totalSets` / `exerciseCount` | INTEGER | 总重量 / 总组数 / 动作数 |
| `muscles` | TEXT | 涉及肌群（JSON 数组） |
| `setRecords` | TEXT | 每组记录（JSON 对象） |
| `restLog` | TEXT | 休息日志（JSON 数组） |
| `planId` / `planName` | TEXT | 关联计划 |
| `pureDuration` | INTEGER | 纯训练时长 |
| `createTime` | INTEGER | 时间戳 |

索引：`idx_records_date`、`idx_records_createTime`

### 11.3 `gym_cards` 表

`id`/`name`/`gymName`/`cardType`/`price`/`startDate`/`endDate`/`remainingCount`(-1=不限)/`totalCount`/`phone`/`remark`/`createTime`/`updateTime`。索引：`idx_gym_cards_endDate`

### 11.4 `achievements` 表

`id` PK / `category` / `unlockedAt` / `metadata` / `pointsReward` / `canEarnPoints`。索引：`idx_achievements_category`

### 11.5 `notes` 表

`id` PK / `createTime` / `recordId` / `feeling` / `bestExercise` / `soreParts`(JSON) / `content` / `moodSticker` / `isFeatured`。索引：`idx_notes_createTime`、`idx_notes_recordId`

### 11.6 `courses` 与 `user_courses` 表

- `courses`：`id`/`title`/`subtitle`/`description`/`goal`/`difficulty`/`points_cost`/`cover_colors`/`cover_emoji`/`coach_name`/`chapters`(JSON)
- `user_courses`：`course_id` PK / `unlocked_at` / `progress`

### 11.7 迁移策略

`_onUpgrade` 按版本递增迁移（v1→v2 增 gym_cards；后续依次增 achievements/notes/courses/user_courses 及字段扩展如 `gender`、`currentDayIndex`、`sourcePlanId`、`isFromSystemLibrary`、`planId`/`planName`/`pureDuration`、`pointsReward`/`canEarnPoints` 等，直至 v10）。

---

## 12. 测试

`test/` 目录约 37 个测试文件，覆盖：

| 测试域 | 文件示例 |
|--------|---------|
| 主题 | `app_themes_test.dart`、`activity_color_mode_test.dart` |
| 存储 | `storage_in_progress_test.dart`、`storage_anon_stats_test.dart` |
| 服务 | `achievement_service_test.dart`、`ad_service_test.dart`、`iap_service_test.dart`、`invitation_service_test.dart`、`redeem_service_test.dart`、`recommendation_service_test.dart`、`smart_push_service_test.dart`、`share_card_service_test.dart`、`rest_preference_service_test.dart` |
| 虚拟对手 | `opponent_assets_test.dart`、`opponent_daily_advance_test.dart`、`opponent_integration_test.dart`、`opponent_renderer_test.dart`、`opponent_skin_config_test.dart`、`virtual_opponent_skin_test.dart`、`virtual_goods_test.dart`、`video_frame_animation_test.dart` |
| 页面 | `data_privacy_page_test.dart`、`privacy_policy_page_test.dart`、`user_agreement_page_test.dart`、`rating_prompt_test.dart`、`onboarding_coach_test.dart`、`questionnaire_channel_test.dart`、`plan_gender_schema_test.dart`、`plan_adopt_bug_test.dart` |
| 组件/工具 | `celebration_overlay_test.dart`、`poster_capture_repro_test.dart`、`motion_player_test.dart`、`exercise_steps_test.dart`、`custom_exercise_test.dart`、`recommendation_banner_test.dart`、`tutorial_chapters_test.dart` |
| 冒烟 | `widget_test.dart` |

---

## 13. CI / CD 与构建

### 13.1 CodeMagic（codemagic.yaml）

- iOS 构建 workflow：安装 Flutter 依赖 → 用 Python 脚本将 OHOS fork 包中的 `TargetPlatform.ohos` / `Platform.isOhos` 替换为 Linux 兼容值 → 签名 → `flutter build ipa` → 产出 IPA/dSYM
- 使用 `mac_mini_m2` 实例、iOS 26 SDK / macos-26 runner

### 13.2 GitHub Actions（.github/workflows/ios-build.yml）

- iOS 打包：手工打包 Runner.app 并补充 `SwiftSupport`；`flutter build ipa --build-number=$GITHUB_RUN_NUMBER` 避免 build 号冲突
- 上传 TestFlight：`altool --apiKey --apiIssuer` 认证（app-store-connect 方式），`openssl -legacy` 读取 p12、临时文件解析 `.mobileprovision`、按部署目标处理 SwiftSupport 目录、上传步骤带重试循环

### 13.3 构建参数速查

| 项目 | 值 |
|------|-----|
| Android 包名 | `com.lt.lifttrack` |
| Android compileSdk | 34（buildTools 36.1.0），minSdk 21 |
| Android 签名 | `android/app/fittrack-release.keystore` + `android/key.properties` |
| Java | 17（`org.gradle.java.home` 指向 Java 17） |
| OHOS | DevEco + hvigor；Flutter OHOS 工具链 |
| iOS | MinimumOSVersion 15.0；`NSCameraUsageDescription` 已配置 |

---

## 14. 项目运行方式

### 14.1 安装依赖

```bash
cd d:\app\projects\health_training\fittrack_flutter
flutter pub get
```

### 14.2 静态检查与测试

```bash
flutter analyze        # 遵循 analysis_options.yaml（flutter_lints）
flutter test           # 运行 test/ 全部测试
```

### 14.3 运行 / 构建

```bash
# Android
flutter run
flutter build apk --release        # 需 Java 17（见 gradle.properties 的 org.gradle.java.home）

# HarmonyOS（需 Flutter OHOS 工具链 + DevEco 环境）
flutter run -d ohos
flutter build hap

# iOS（需 macOS + Xcode + CocoaPods）
cd ios && pod install
flutter build ipa --build-number=<n>

# 桌面 / Web
flutter run -d windows   # 或 macos / linux / chrome
```

### 14.4 环境要求与注意事项

- **Dart SDK**：`>=2.19.6 <3.0.0`（Flutter 3.7.x 系），勿升级大版本
- **Java 17**：Android 构建必须使用 Java 17（`C:/Program Files/Java/jdk-17.0.12`），与 Gradle 7.5 兼容
- **Android AVD**：使用标准 4KB 页大小模拟器（如 `Medium_Phone_4k`，android-34;google_apis;x86_64），16KB 页模拟器（gphone16k）不受 Flutter 3.7.12 引擎支持
- **OHOS 模拟器**：倒计时代理提醒 API version 20+ 才支持模拟器；真机建议使用
- **新增依赖**：需评估 OHOS 兼容性，优先选用 gitcode 上的 OHOS 定制分支
- **提醒重排**：OHOS 代理提醒为单次触发，App 每次启动/回前台会自动 `reschedule`

---

## 15. 附录

### 15.1 Settings 关键键速查

| 键 | 说明 |
|----|------|
| `theme` / `lightThemeId` / `darkThemeId` | 主题 ID |
| `autoDarkMode` | `off`/`system`/`timed` |
| `timedDarkTime` | 定点自动深色时间（HH:mm，默认 18:00） |
| `nightModePrompted` | 夜间模式引导是否已询问 |
| `trainingTime` | 每日训练提醒时间（HH:mm） |
| `unit` / `restTime` / `defaultRestTime` / `defaultSets` / `defaultReps` / `defaultWeight` | 训练默认值 |
| `deviceId` | 匿名统计设备标识 |
| `isPremium` | Pro 状态 |
| `privacyAgreed` / `onboardingDone` | 引导流程标记 |
| `romGuidanceDismissed` / `romGuidanceDismissTime` | ROM 引导关闭标记 |

### 15.2 关键常量速查

| 常量 | 值 | 位置 |
|------|-----|------|
| SQLite 数据库 | `fittrack.db` v10 | DatabaseHelper |
| 记录缓存上限 | 500 条 | Storage.addRecord |
| 身体数据历史上限 | 50 条 | Storage.saveBodyDataHistory |
| 周数据保留 | 最近 12 周 | Storage.updateStats |
| 默认主题（浅色） | `vitality-sport` | AppTheme |
| 默认暗色主题 | `iron-forge` | AppTheme |
| LiveView ID | 30001 | EntryAbility |
| 智能提醒默认时间 | 20:00 | SmartPushService |
| MethodChannel | `com.lt.lifttrack/{form,reminder,poster,alarm}` | 各服务 |
| OHOS 包标识前缀 | `com.lt.lifttrack` | module.json5 / build.gradle |

### 15.3 工程约定与注意事项

- **状态管理**：未引入 Provider/Bloc/Riverpod。修改数据走 `Storage` 同步方法（更新缓存 + 异步落盘）。
- **数据分流**：结构化数据 → SQLite；轻量键值 → SharedPreferences。
- **主题访问**：通过 `Theme.of(context).extension<LiftTrackColors>()!` 取色，不硬编码颜色。
- **平台判断**：优先用 `utils/platform_utils.dart` 的 `isOhos`/`isIos`（而非 `Platform.isXxx`），便于测试与 CI 替换。
- **平台能力**：跨平台能力统一走 `PlatformServices`（PAL），业务代码不感知平台实现。
- **OHOS preferences 跨进程**：不支持跨进程共享；`FormExtensionAbility` 必须 `removePreferencesFromCacheSync()` 清进程缓存才能读到主进程最新数据。
- **formProvider.updateForm() 限流**：每分钟每卡片实例最多 10 次调用。
- **LiveViewKit (TIMER 类型)**：必需 `capsule.icon`、`layoutData.nodeIcons` 等完整参数结构，更新参数须与 `startLiveView` 一致。
- **win32 兼容性**：win32 需锁定 ≤3.1.4（Dart 2.x 与 win32 4.1.4+ 不兼容），通过 `dependency_overrides` 固定。
- **编码规范**：页面放 `pages/`，可复用 UI 放 `widgets/`，业务能力放 `services/`，数据访问统一走 `data/storage.dart`；提交前 `flutter analyze` 无警告。
- **HarmonyOS 开发**：涉及 `.ets`/ArkTS/卡片/代理提醒时，须以华为官方文档为准（见 `AGENT.md` 第 0.2 节）。

### 15.4 相关文档

- [AGENT.md](file:///d:/app/projects/health_training/AGENT.md) — AI 助手操作指南与约束
- [FitTrack_v2_产品需求文档.md](file:///d:/app/projects/health_training/docs/FitTrack_v2_产品需求文档.md) — 产品需求文档
- [FitTrack运营方案.md](file:///d:/app/projects/health_training/docs/FitTrack运营方案.md) — 运营方案
- [Phase2_开发文档.md](file:///d:/app/projects/health_training/docs/Phase2_开发文档.md) — Phase 2 开发文档
- [GitHub_Actions_iOS打包操作指南.md](file:///d:/app/projects/health_training/docs/GitHub_Actions_iOS打包操作指南.md) — iOS 打包指南
- HarmonyOS 官方文档：https://developer.huawei.com/consumer/cn/doc/
