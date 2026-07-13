# FitTrack（燃力）第二阶段开发文档

> **版本**: Phase 2.0 | **起始日期**: 2026-07-13 | **状态**: 待评审
> **范围**: v1 基线 → v2 模块（A/B/C/D/F，**不含 E 服务器模块**）
> **基线代码**: `master` 分支 commit `591f084`（2026-07-13 推送）

---

## 目录

1. [背景与目标](#1-背景与目标)
2. [范围边界](#2-范围边界)
3. [模块清单与优先级](#3-模块清单与优先级)
4. [整体架构与数据流](#4-整体架构与数据流)
5. [新增依赖与文件结构](#5-新增依赖与文件结构)
6. [模块详细设计](#6-模块详细设计)
7. [数据库与存储扩展](#7-数据库与存储扩展)
8. [验收标准](#8-验收标准)
9. [风险与依赖](#9-风险与依赖)
10. [里程碑与交付节奏](#10-里程碑与交付节奏)

---

## 1. 背景与目标

### 1.1 起点

FitTrack v1 基线已稳定（17 个页面、SQLite + SharedPreferences 混合持久化、OHOS 桌面卡片/实况窗、7 套主题、三重休息提醒）。详见 [CODE_WIKI.md](file:///d:/app/projects/health_training/CODE_WIKI.md)。

### 1.2 第二阶段目标

围绕 [FitTrack运营方案.md](file:///d:/app/projects/health_training/docs/FitTrack运营方案.md) 与 [FitTrack_v2_产品需求文档.md](file:///d:/app/projects/health_training/docs/FitTrack_v2_产品需求文档.md) 落地"运营方案功能增强"——把运营所需的**变现、流量、留存、数据、合规**能力一次性补齐，**暂不引入自建服务器**，所有功能在纯本地即可跑通。

| 维度 | v1 基线 | Phase 2 目标 |
|------|---------|------------|
| 变现 | 无 | 兑换码本地验证 + Pro 解锁（IAP/本地解锁码）+ 广告位预留 |
| 流量 | 无机制 | 训练分享卡片 + 日历热力图 |
| 留存 | 通知 + 卡片 | 新手引导 + 庆祝动画 + 智能推送 + 成就徽章 |
| 数据 | 全量统计 | 渠道追踪 + 评分引导 + 匿名统计开关 |
| 合规 | 隐私弹窗 | 隐私政策 + 用户协议 + 数据授权页 |

### 1.3 非目标（明确不做）

- **服务器模块 E1-E4**：匿名账号、服务器兑换码、全国排行榜、年度报告服务器端 → 全部推迟到第三阶段
- **OHOS 原生 IAP / HMS Ads Kit 接入**：Phase 2.0 仅做 Android IAP + 本地解锁码兜底，OHOS 走本地解锁码
- **激励视频广告 C2**：PRD 标记 P2 v2.1，Phase 2.0 仅预留广告位接口与 `AdService` 抽象，不实际接入 SDK

---

## 2. 范围边界

### 2.1 纳入 Phase 2.0 的功能（15 项）

| ID | 功能 | 优先级 | 估时 | 是否本地化 |
|----|------|:------:|:----:|:--------:|
| A1 | 训练完成分享卡片 | P0 | 1d | ✅ 纯本地 |
| A2 | 训练日历热力图 | P0 | 2d | ✅ 纯本地 |
| B1 | 新手 5 分钟首次记录引导 | P0 | 2d | ✅ 纯本地 |
| B2 | 训练完成庆祝动画 | P1 | 0.5d | ✅ 纯本地 |
| B3 | 精准推送训练提醒 | P0 | 1.5d | ✅ 纯本地 |
| B4 | 成就徽章系统 | P1 | 3d | ✅ 纯本地 |
| C1 | Pro 买断（IAP + 本地解锁码兜底） | P0 | 3d | ✅ 本地兜底 |
| C2 | 激励视频广告位预留 | P2 | 1d | ✅ 仅接口 |
| C3 | 兑换码本地验证（HMAC） | P0 | 2d | ✅ 纯本地 |
| D1 | 问卷渠道来源追踪 | P1 | 0.5d | ✅ 纯本地 |
| D2 | 应用商店评分引导 | P1 | 1d | ✅ 纯本地 |
| D3 | 训练数据匿名统计开关 | P0 | 0.5d | ✅ 仅开关 UI |
| F1 | 隐私政策更新 | P0 | 1d | ✅ 文档 + 渲染 |
| F2 | 用户协议更新 | P0 | 1d | ✅ 文档 + 渲染 |
| F3 | 数据授权管理页面 | P0 | 1d | ✅ 纯本地 |

**合计估时**: 21 人天（不含测试/上架时间）

### 2.2 推迟到 Phase 3 的功能

- E1 匿名账号系统（CloudBase）
- E2 兑换码服务器验证（CloudBase）
- E3 全国训练排行榜（CloudBase）
- E4 训练报告年度生成（服务器端辅助）
- C2 激励视频广告实际接入（华为 Ads / 穿山甲 SDK 集成）

---

## 3. 模块清单与优先级

### 3.1 模块依赖图

```
        ┌────────────────────────────────────────────────────┐
        │              Phase 2 模块依赖关系                  │
        └────────────────────────────────────────────────────┘

   ┌─── F1/F2/F3 合规模块（最先做，奠定法务基础）
   │        │
   │        ▼
   │   ┌── D3 匿名统计开关（为后续排行榜准备，本期仅 UI）
   │   │
   │   ▼
   │   D1 渠道追踪（改问卷）  ──┐
   │   D2 评分引导             │
   │                           │
   ▼                           ▼
   C3 兑换码本地验证 ──→ C1 Pro 解锁（依赖兑换码 + IAP）
   │                           ▲
   │                           │
   └──→ C2 广告位接口（预留） ──┘
                                 │
   独立模块（无依赖）：           │
   ├── A1 分享卡片                │
   ├── A2 日历热力图              │
   ├── B1 新手引导                │
   ├── B2 庆祝动画                │
   ├── B3 智能推送                │
   └── B4 成就徽章 ───────────────┘ （徽章可触发 Pro 解锁推荐）
```

### 3.2 推荐实施顺序

按依赖与优先级分 6 批次（W=周）：

| 批次 | 周次 | 模块 | 说明 |
|:----:|:----:|------|------|
| W1 | 第 1 周 | F1+F2+F3 → D3 | 合规先行，铺好隐私底座 |
| W2 | 第 1-2 周 | A2 日历热力图 + A1 分享卡片 | 流量工具，独立无依赖 |
| W3 | 第 2-3 周 | B1 新手引导 + B2 庆祝动画 | 留存体验 |
| W4 | 第 3 周 | B3 智能推送 + B4 成就徽章 | 留存机制（依赖 A2 热力图数据） |
| W5 | 第 3-4 周 | C3 兑换码 + C1 Pro 解锁 + C2 广告位预留 | 变现核心 |
| W6 | 第 4 周 | D1 渠道追踪 + D2 评分引导 | 数据驱动收尾 |

---

## 4. 整体架构与数据流

### 4.1 架构变化概览

Phase 2 在 v1 架构基础上**新增 6 个 Service + 5 个 Page + 3 个 Widget**，不引入状态管理框架（继续用 `Storage` + `ValueNotifier` + `setState`）。

```
┌───────────────────────────────────────────────────────────────┐
│                  UI 层 (pages/)                                │
│  + LeaderboardPage? ✗（推迟）  + AchievementPage              │
│  + RedeemPage  + DataPrivacyPage  + ShareCardPreview          │
│  修改：HomePage（加热力图）/TrainingPage（加分享/动画）        │
│  /QuestionnairePage（加渠道题）/SettingsPage（加入口）          │
├───────────────────────────────────────────────────────────────┤
│              通用组件 (widgets/)                               │
│  + HeatmapGrid  + AchievementBadge  + CelebrationOverlay       │
│  + OnboardingCoach  + ShareCardFrame                           │
├───────────────────────────────────────────────────────────────┤
│              服务层 (services/)                                 │
│  + ShareCardService  + AchievementService  + RedeemService      │
│  + IapService  + AdService（接口预留）+ SmartPushService        │
├───────────────────────────────────────────────────────────────┤
│               数据层 (data/)                                    │
│  Storage 扩展：achievements / redeemedCodes / isPremium /      │
│  channelSource / ratingPromptLastShown / anonStatsOptIn        │
│  DatabaseHelper v2 → v3 升级（新增 achievements 表）            │
└───────────────────────────────────────────────────────────────┘
```

### 4.2 核心数据流（Phase 2 新增）

#### 4.2.1 训练完成 → 分享 + 庆祝 + 徽章 + Pro 推荐

```
TrainingPage._saveAndReturn()
  → Storage.addRecord()（已有）
  → ShareCardService.generateShareCard(record)  [A1]
       → RepaintBoundary.toImage() → 保存 PNG → share_plus
  → CelebrationOverlay.show(context)  [B2]
       → CustomPaint 粒子动画 3s
  → AchievementService.checkAndUnlock(record)  [B4]
       → 触发新徽章 → 弹 AchievementDialog
       → 若达到里程碑 → 推荐 Pro 解锁 [C1]
  → SmartPushService.recordTrainingAndReschedule()  [B3]
       → 更新下次推送时机
  → FormKitService.endTraining()（已有，OHOS）
```

#### 4.2.2 兑换码 → Pro 解锁

```
RedeemPage 输入兑换码
  → RedeemService.verifyAndRedeem(code)  [C3]
       → 格式校验 FITT-XXXX-XXXX-XXXX
       → HMAC-SHA256 签名校验（多密钥轮换）
       → 本地已兑换列表检查（防重复）
       → 写入 redeemedCodes + isPremium=true
  → IapService.markPremiumLocally()  [C1 兜底]
       → 触发 UI 全局刷新（ValueNotifier）
  → AdService.disableAds()（如已展示） [C2]
```

### 4.3 Pro 状态全局可观测

新增 `Storage.isPremiumNotifier`（`ValueNotifier<bool>`）：

- 主题切换页、训练完成页、设置页、广告位组件订阅此 notifier
- 任一渠道解锁 Pro（IAP / 兑换码 / 测试码）→ `Storage.setPremium(true)` → 全局 UI 自动响应

---

## 5. 新增依赖与文件结构

### 5.1 pubspec.yaml 新增依赖

```yaml
dependencies:
  # 已有依赖保持不变（sdk: '>=2.19.6 <3.0.0'）

  # 图片生成与分享（A1 分享卡片）
  path_provider: ^2.1.0           # 图片临时存储路径
  share_plus: ^7.0.0              # 系统分享面板（微信/朋友圈/保存图片）

  # 加密（C3 兑换码 HMAC-SHA256）
  crypto: ^3.0.3                  # Dart 官方加密库

  # IAP（C1 Pro 买断，仅 Android；OHOS 走本地解锁码兜底）
  in_app_purchase: ^3.1.0         # Android IAP（注意 OHOS 不支持，需 Platform 守卫）

  # Lottie（B2 庆祝动画，可选）
  # 决策：本期用 CustomPaint 自绘粒子，不引入 Lottie（保持依赖精简）
```

**OHOS 兼容性注意**：
- `path_provider` / `share_plus` / `crypto` / `in_app_purchase` 均需确认在 OHOS 平台的支持情况
- 若 `share_plus` / `in_app_purchase` 在 OHOS 不可用，用 `Platform.isOhos` 守卫，OHOS 退化为"保存到本地相册"或"显示兑换码"路径
- 涉及到 gitcode OHOS 定制分支的依赖，参照 [CODE_WIKI 8.1 节](file:///d:/app/projects/health_training/CODE_WIKI.md) 已有处理方式

### 5.2 新增文件清单

```
fittrack_flutter/lib/
├── services/
│   ├── share_card_service.dart         # A1 分享卡片生成
│   ├── achievement_service.dart        # B4 徽章解锁逻辑
│   ├── redeem_service.dart             # C3 兑换码 HMAC 验证
│   ├── iap_service.dart                # C1 IAP 购买流程
│   ├── ad_service.dart                 # C2 广告位接口（预留）
│   └── smart_push_service.dart         # B3 智能推送策略
├── pages/
│   ├── achievement_page.dart           # B4 徽章墙
│   ├── redeem_page.dart                # C3 兑换码输入
│   ├── data_privacy_page.dart          # F3 数据与隐私
│   ├── privacy_policy_page.dart        # F1 隐私政策展示
│   └── user_agreement_page.dart        # F2 用户协议展示
├── widgets/
│   ├── heatmap_grid.dart               # A2 日历热力图组件
│   ├── achievement_badge.dart          # B4 徽章组件
│   ├── celebration_overlay.dart        # B2 庆祝动画浮层
│   ├── onboarding_coach.dart           # B1 新手引导浮层
│   └── share_card_frame.dart           # A1 分享卡片画框
└── data/
    └── legal/
        ├── privacy_policy.md           # F1 隐私政策正文
        └── user_agreement.md           # F2 用户协议正文
```

### 5.3 修改文件清单

| 文件 | 修改点 | 关联模块 |
|------|--------|---------|
| `lib/main.dart` | 初始化新 Service（IAP / Achievement / SmartPush） | C1/B3/B4 |
| `lib/router.dart` | 新增 6 个独立路由（/achievements /redeem /data-privacy /privacy /agreement /share-preview） | 全模块 |
| `lib/data/storage.dart` | 新增 settings 字段（isPremium/redeemedCodes/channelSource/anonStatsOptIn/...）+ isPremiumNotifier | C1/C3/D1/D3 |
| `lib/data/database_helper.dart` | DB v2 → v3 升级，新增 `achievements` 表 | B4 |
| `lib/pages/home_page.dart` | 顶部插入 HeatmapGrid（占屏高 20%） | A2 |
| `lib/pages/training_page.dart` | _saveAndReturn 接入 ShareCard / Celebration / Achievement / SmartPush | A1/B2/B3/B4 |
| `lib/pages/questionnaire_page.dart` | 新增渠道来源单选题 | D1 |
| `lib/pages/settings_page.dart` | 新增"数据与隐私"/"兑换码"/"成就墙"/"评分"入口 | F3/C3/B4/D2 |
| `lib/pages/theme_settings_page.dart` | 非 Pro 用户点击 Pro 主题时弹购买引导 | C1 |
| `lib/pages/profile_page.dart` | 个人中心加 Pro 标识 + 升级入口 | C1 |
| `lib/widgets/common_widgets.dart` | 新增通用组件：ProBadge / RatingPromptSheet | C1/D2 |

---

## 6. 模块详细设计

### 6.1 A1 — 训练完成分享卡片

**目标**：训练完成后一键生成 9:16 分享图，引流朋友圈/小红书。

**技术方案**：
- 使用 `RepaintBoundary` + `RenderRepaintBoundary.toImage()` 将 Widget 树渲染为 PNG
- `ShareCardFrame` Widget：1080×1920 画布，含训练名称/总重量/总组数/时长/日期/品牌水印/二维码
- 二维码：本地生成 SVG（不引入 QR 库，使用纯算法或预置 PNG 模板）
- 生成后通过 `share_plus` 唤起系统分享面板

**集成点**：
- 触发位置：`TrainingPage._saveAndReturn()` 完成后弹出的总结页底部新增"分享"按钮
- 图片临时存储：`path_provider.getTemporaryDirectory()` + `share_card_{timestamp}.png`
- 文件大小目标：< 500KB

**关键接口**：
```dart
class ShareCardService {
  static Future<String> generateShareCard(Map<String, dynamic> record);
  static Future<void> shareImage(String imagePath);
}
```

**验收标准**：
- [ ] 生成时间 < 1 秒
- [ ] 图片清晰度满足朋友圈/小红书展示
- [ ] OHOS 平台分享面板正常唤起（或退化为保存到相册）

---

### 6.2 A2 — 训练日历热力图

**目标**：首页顶部展示近 365 天训练频次热力图（GitHub 风格）。

**技术方案**：
- `HeatmapGrid` Widget：13×7 网格（13 周 × 7 天），自定义 CustomPaint
- 数据源：`Storage.getRecords()` 按 `date` 字段聚合为 `{YYYY-MM-DD: 训练强度}` 映射
- 训练强度分级：0（无训练）→ 浅灰 #EBEEF0；1-3 组 → 浅蓝；>60min → 深蓝 #1976D2 + 高光边框
- 月份分隔标签：1月/2月/.../12月 横向标签
- 渲染性能：单次 CustomPaint 绘制，目标 < 100ms

**集成点**：
- `HomePage` build 方法顶部插入 `HeatmapGrid`，高度约屏高 20%
- 数据变化监听：`Storage.dataChanged` ValueNotifier 触发热力图重绘

**关键接口**：
```dart
class HeatmapGrid extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  const HeatmapGrid({required this.records, super.key});
  // 内部按 date 聚合，渲染 13×7 网格
}
```

**验收标准**：
- [ ] 首屏渲染时间 < 100ms
- [ ] 完成训练后回到首页，热力图立即更新
- [ ] 7 套主题下颜色协调（通过 FitTrackColors 适配，不硬编码）

---

### 6.3 B1 — 新手 5 分钟首次记录引导

**目标**：跳过 5 步问卷，新用户首屏直接进入"开始第一次训练"浮层。

**技术方案**：
- 新增 `OnboardingCoach` Widget：浮层式 Coach Mark，3 步引导
- 触发条件：`Storage.hasData() == false && Storage.getSettings()['onboardingDone'] != true`
- 流程：
  1. 首页浮层："今天练什么部位？"（胸/背/腿/肩/手臂/核心 6 选 1）
  2. 展示 3 个推荐动作（从 MockData 拉取）
  3. 引导用户记录第一组 → 完成弹"B2 庆祝动画"（联动）
- 问卷页保留但**不阻塞**：用户可在"我的 → 完善健身档案"中补完

**集成点**：
- `SplashPage` 路由判断：
  - `hasData()` 为真 → `/home`
  - `hasData()` 为假 + `onboardingDone != true` → `/home`（带 `showCoach: true` 参数）
  - `privacyAgreed != true` → `/privacy`
- `HomePage` initState 检测 `showCoach` 参数，挂载 `OnboardingCoach`

**关键接口**：
```dart
class OnboardingCoach extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  const OnboardingCoach({required this.onComplete, required this.onSkip, super.key});
}
```

**验收标准**：
- [ ] 90% 新用户在 5 分钟内完成第一次训练记录
- [ ] 跳过后不再骚扰（写 `onboardingDone=true`）
- [ ] 与 B2 庆祝动画无缝衔接

---

### 6.4 B2 — 训练完成庆祝动画

**目标**：训练完成时弹 3 秒星空烟花动画 + 与上次成绩对比文案。

**技术方案**：
- `CelebrationOverlay` Widget：FullScreen Overlay + CustomPaint 粒子系统
- 粒子算法：50 个粒子从屏幕中心放射，3 秒内淡出
- 对比文案：读取上一次相同部位训练记录，对比总重量/时长
  - "比上次快了近 5 分钟"
  - "总重量提升 5%"
  - 首次训练："你的健身旅程开始了 🎉"（仅文案，不依赖动画）
- 不阻塞用户操作：点击任意位置关闭

**集成点**：
- `TrainingPage._saveAndReturn()` 中，导航回首页前先 `await CelebrationOverlay.show(context, record, previousRecord)`

**关键接口**：
```dart
class CelebrationOverlay {
  static Future<void> show(BuildContext context, {
    required Map<String, dynamic> record,
    Map<String, dynamic>? previousRecord,
  });
}
```

**验收标准**：
- [ ] 动画 ≥ 30fps
- [ ] 3 秒内不阻塞用户操作
- [ ] 文案对比逻辑正确（首训/增重/减重/持平四态）

---

### 6.5 B3 — 精准推送训练提醒

**目标**：基于训练日历状态智能调度提醒，避免打扰。

**技术方案**：
- 新增 `SmartPushService` 单例，封装推送时机策略
- 状态判断（基于 `Storage.getRecords()`）：
  - 状态 A：今天未训练 + 今天是训练日 → 20:00 推送
  - 状态 B：连续训练 ≥ 7 天 → 推送激励文案
  - 状态 C：≥ 3 天未训练 → 不推送（避免打扰）
- 频次限制：同一用户 7 天内最多 2 次（用 `SharedPreferences` 记录 `lastPushDate` + `pushCountIn7Days`）
- 文案策略：成就型而非督促型："你的训练日历有 28 个连续方块，今天别断！"
- 底层复用现有 `RestNotificationService` + `OhosReminderService`

**集成点**：
- `main.dart` 初始化：`SmartPushService.instance.init()` + 注册每日定时检查
- 训练完成时：`SmartPushService.instance.onTrainingCompleted()` 重置当日状态
- 设置页：新增"智能推送"开关（默认开启）

**关键接口**：
```dart
class SmartPushService {
  static final SmartPushService instance = SmartPushService._();
  Future<void> init();
  Future<void> onTrainingCompleted();
  Future<void> scheduleDailyCheck();  // 每日 20:00 检查并决定是否推送
}
```

**验收标准**：
- [ ] 7 天内同一用户最多收到 2 次推送
- [ ] 连续训练 ≥ 7 天时推送激励文案
- [ ] ≥ 3 天未训练时不推送
- [ ] 用户可在设置中关闭

---

### 6.6 B4 — 成就徽章系统

**目标**：纯本地徽章系统，触发解锁动画，强化留存。

**技术方案**：
- 新增 `achievements` 表（DatabaseHelper v3 升级）：
  ```
  achievements(id TEXT PK, category TEXT, unlockedAt INTEGER, metadata TEXT)
  ```
- 徽章类别（21 个）：
  - 连续打卡：7/30/100/365 天（4 个）
  - 重量里程碑：1t/10t/50t/100t（4 个）
  - 劳勤：24h/100h/500h（3 个）
  - 连续月坚持：3/6/12 月（3 个）
  - 探索：训练 15/20/25 个动作（3 个）
  - 计划首张完成（1 个）
  - 分享徽章：首次分享 / 3 次分享 / 10 次分享（3 个）
- 解锁逻辑：`AchievementService.checkAndUnlock(record)` 在训练完成时调用
- 解锁动画：`AchievementDialog`（已在 common_widgets 中）+ 星光闪烁

**集成点**：
- `main.dart` 初始化：`AchievementService.instance.init()` 加载已解锁徽章到内存
- `TrainingPage._saveAndReturn()`：调用 `AchievementService.checkAndUnlock(record)`，若解锁新徽章则弹 `AchievementDialog`
- 新增 `/achievements` 路由：徽章墙页面（已解锁高亮 + 未解锁灰显）

**关键接口**：
```dart
class AchievementService {
  static final AchievementService instance = AchievementService._();
  Future<void> init();
  Future<List<String>> checkAndUnlock(Map<String, dynamic> record);
  List<Achievement> getAll();
  List<Achievement> getUnlocked();
}

class Achievement {
  final String id;
  final String category;
  final String title;
  final String description;
  final String icon;  // SVG 或 emoji
  final bool unlocked;
  final int? unlockedAt;
}
```

**验收标准**：
- [ ] 21 个徽章全部可在离线状态下解锁
- [ ] 解锁动画流畅，不阻塞训练完成流程
- [ ] 徽章墙页面正确展示已解锁/未解锁状态
- [ ] DB 升级不丢失 v1 数据

---

### 6.7 C1 — Pro 买断（IAP + 本地解锁码兜底）

**目标**：用户通过应用商店 IAP 或兑换码解锁 Pro 权益，永久生效。

**技术方案**：
- `IapService` 单例，封装 `in_app_purchase` 插件
- 双通道解锁：
  - **通道 A（Android）**：`in_app_purchase` 购买 `fittrack_pro_lifetime` 商品 → 本地校验 → 写 `Storage.setPremium(true)`
  - **通道 B（OHOS / 测试 / 无 IAP 环境）**：通过 C3 兑换码本地解锁
- Pro 权益落地：
  - 主题：非 Pro 用户只能用 `vitality-sport` + `fresh-minimal` 2 套
  - 历史记录：免费版仅显示近 30 天
  - 数据导出：仅 Pro 可用
  - 桌面卡片：仅 Pro 可添加（OHOS）
  - 广告：Pro 后 `AdService.disableAds()`
- 全局 Pro 状态：`Storage.isPremiumNotifier`（`ValueNotifier<bool>`），UI 订阅自动响应

**集成点**：
- `main.dart` 初始化：`IapService.instance.init()`（Android 平台）
- `ThemeSettingsPage._selectTheme(themeId)`：非 Pro 主题点击时弹购买引导
- `RecordsPage`：非 Pro 用户仅显示近 30 天记录
- `SettingsPage` 数据导出按钮：非 Pro 灰显 + 引导购买
- `ProfilePage`：显示 Pro 徽章 / 升级按钮

**关键接口**：
```dart
class IapService {
  static final IapService instance = IapService._();
  final ValueNotifier<bool> isPremium = Storage.isPremiumNotifier;
  Future<void> init();
  Future<bool> purchasePro();
  Future<void> restorePurchases();
  // 本地兜底（兑换码解锁后调用）
  Future<void> markPremiumLocally(String source);
}
```

**验收标准**：
- [ ] Android 真机购买流程正常
- [ ] OHOS 通过兑换码解锁路径正常
- [ ] Pro 解锁后所有受限功能立即生效
- [ ] 卸载重装后 IAP 可恢复购买（Android）

---

### 6.8 C2 — 激励视频广告位接口预留

**目标**：本期不接入广告 SDK，但定义清晰的接口供 Phase 3 接入。

**技术方案**：
- `AdService` 抽象类，定义广告位接口
- 三个广告位（与运营方案一致）：
  - `showRewardedVideo()` — 训练完成总结页（用户主动点击）
  - `showNativeBanner()` — 组间休息页底部（每 3 组最多 1 次）
  - `showSplashAd()` — 冷启动开屏（每天最多 1 次）
- 本期实现：所有方法返回 `AdResult.notAvailable`，UI 检测后跳过广告展示
- 频次控制：`SharedPreferences` 记录 `lastAdShown_{position}` 时间戳

**集成点**：
- `TrainingPage` 总结页：检查 `AdService.instance.shouldShowRewarded()`，true 时显示"看广告解锁详细报告"按钮
- 训练休息页：底部预留 80px 高度容器，`AdService.instance.getNativeBannerWidget()` 返回空 Widget
- `main.dart` 启动后：`AdService.instance.maybeShowSplashAd()`（异步，不阻塞）

**关键接口**：
```dart
enum AdPosition { rewarded, nativeBanner, splash }
enum AdResult { success, notAvailable, userDismissed, error }

abstract class AdService {
  static final AdService instance = _NoOpAdService();  // 本期空实现
  bool shouldShowRewarded();
  Future<AdResult> showRewardedVideo();
  Widget getNativeBannerWidget();
  Future<void> maybeShowSplashAd();
}

class _NoOpAdService implements AdService {
  // 所有方法返回 notAvailable / 空 Widget
}
```

**验收标准**：
- [ ] UI 在 Pro 状态下完全跳过广告路径
- [ ] 接口设计兼容 Phase 3 接入华为 Ads / 穿山甲 SDK
- [ ] 频次控制逻辑可被 Phase 3 复用

---

### 6.9 C3 — 兑换码本地验证

**目标**：离线 HMAC 验证兑换码，无服务器也能用。

**技术方案**：
- 兑换码格式：`FITT-XXXX-XXXX-XXXX`（16 字符 + 连字符）
- 算法：HMAC-SHA256，截取后 4 字符作为校验位
- 密钥：预置 2 个密钥（`v1_2025` / `v2_2026`），支持季度轮换
- 已兑换列表：`SharedPreferences` 存 `redeemed_codes` JSON 数组（防同设备重复兑换）
- 生成脚本：Python `generate_codes.py`（本地运行，密钥与 APP 内一致）

**集成点**：
- 新增 `/redeem` 路由 → `RedeemPage`
- `RedeemPage` 提交按钮 → `RedeemService.verifyAndRedeem(code)`
- 验证通过 → `IapService.markPremiumLocally('redeem_code')` + 写入已兑换列表
- 设置页与个人中心：新增"兑换码"入口

**关键接口**：
```dart
class RedeemService {
  static final RedeemService instance = RedeemService._();
  static const List<String> _secrets = [
    'fitTrack_secret_v1_2025',
    'fitTrack_secret_v2_2026',
  ];

  RedeemResult verifyAndRedeem(String code);
  List<String> getRedeemedCodes();
  bool isAlreadyRedeemed(String code);
}

enum RedeemResult { success, invalidFormat, invalidSignature, alreadyRedeemed }
```

**Python 生成脚本**（`scripts/generate_redeem_codes.py`）：
```python
import hmac, hashlib, random, string
SECRET = 'fitTrack_secret_v1_2025'
def generate_code(secret):
    rand_part = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
    content = f'{rand_part[:4]}-{rand_part[4:]}'
    sig = hmac.new(secret.encode(), content.encode(), hashlib.sha256).hexdigest()[:4].upper()
    return f'FITT-{content[:4]}-{content[5:]}-{sig}'
```

**验收标准**：
- [ ] 单个兑换码兑换成功率 ≥ 95%
- [ ] 同一设备无法重复兑换同一码
- [ ] 错误格式码立即拒绝
- [ ] Python 脚本生成的码可在 APP 内验证通过

---

### 6.10 D1 — 问卷渠道来源追踪

**目标**：在健身问卷末尾增加渠道来源单选题，本地记录。

**技术方案**：
- `QuestionnairePage` 末尾新增第 6 题："你从哪里找到 FitTrack？"
  - 选项：应用商店搜索 / 小红书 / 抖音 / 朋友推荐 / 健身房 / 其他
- 选择结果写入 `Storage.getSettings()['channelSource']`
- 数据导出 JSON 时包含此字段，便于离线分析渠道 ROI

**集成点**：
- `QuestionnairePage` 问卷数据模型扩展 `channelSource` 字段
- `Storage.saveQuestionnaire(profileData)` 时一并保存

**验收标准**：
- [ ] 问卷提交后 channelSource 字段正确持久化
- [ ] 导出 JSON 包含此字段
- [ ] 不阻塞问卷主流程（用户可跳过此题）

---

### 6.11 D2 — 应用商店评分引导

**目标**：训练 2 次后弹评分引导，每 30 天最多 1 次。

**技术方案**：
- `RatingPromptSheet` Widget（FitBottomSheet 派生）
- 触发逻辑：
  - 用户训练次数 ≥ 2（从 stats.totalTrainings 读取）
  - 距上次弹窗 ≥ 30 天（`Storage.getSettings()['ratingPromptLastShown']`）
  - 用户未点过"不再提醒"（`Storage.getSettings()['ratingPromptNeverAsk']`）
- 文案："你已经用 FitTrack 完成了 X 次训练！给个好评让更多独立开发者坚持下去吧 ❤️"
- 按钮："去评分"（调用 `in_app_review` 或打开应用商店 URL） / "稍后" / "不再提醒"

**集成点**：
- `TrainingPage._saveAndReturn()` 完成后，检查触发条件，必要时弹 `RatingPromptSheet`

**关键接口**：
```dart
class RatingPromptSheet {
  static Future<void> maybeShow(BuildContext context);
}
```

**验收标准**：
- [ ] 第 2 次训练完成后首次弹出
- [ ] 30 天内最多 1 次
- [ ] "不再提醒"后永久关闭
- [ ] 不打断训练流程

---

### 6.12 D3 — 训练数据匿名统计开关

**目标**：为 Phase 3 排行榜做准备，本期仅做开关 UI + 数据脱敏格式定义。

**技术方案**：
- `Storage.getSettings()['anonStatsOptIn']`（默认 `false`）
- `SettingsPage` 或 `DataPrivacyPage` 新增开关："参与全国训练排行榜"
- 开关文案明确："仅上传脱敏后的总训练数据（日期、总重量、总时长），不包含任何个人信息和训练动作细节"
- 本期**不实现实际上传**，仅持久化开关状态
- 定义脱敏数据格式（文档化）：
  ```json
  {
    "device_id": "uuid-v4",
    "date": "2026-07-13",
    "total_weight": 3250,
    "duration": 3120,
    "total_sets": 16
  }
  ```

**集成点**：
- `DataPrivacyPage`（F3）中作为开关项之一
- `Storage.init()` 时若 `anonStatsOptIn` 为 true，本地生成 `device_id`（UUID v4）

**验收标准**：
- [ ] 开关状态正确持久化
- [ ] 默认关闭
- [ ] 隐私文案明确说明数据范围
- [ ] device_id 生成一次后稳定不变

---

### 6.13 F1 — 隐私政策更新

**目标**：覆盖 PIPL 7 大类信息要求，可通过设置页全屏查看。

**技术方案**：
- 新增 `lib/data/legal/privacy_policy.md`：完整隐私政策正文
- 新增 `PrivacyPolicyPage`：Markdown 渲染（使用 `flutter_markdown` 或自渲染）
  - **决策**：本期为减少新依赖，使用自渲染方案——将隐私政策拆分为章节 List，用 `SingleChildScrollView + Text` 渲染
- 新增条款覆盖：
  - 收集的个人信息类型（设备标识符、推送 Token）
  - 训练数据匿名统计说明
  - 第三方 SDK（广告/IAP）信息共享说明
  - 未成年人保护条款
  - 数据存储位置（本地 / 服务器）
  - 用户权利（查询/更正/删除/撤回授权）
  - 联系方式

**集成点**：
- 首次启动隐私弹窗（`_PrivacyPolicyPage`）链接到完整政策
- `SettingsPage` 新增"隐私政策"入口 → `/privacy`

**验收标准**：
- [ ] 条款覆盖 PIPL 7 大类信息
- [ ] 页面可在设置中随时访问
- [ ] 隐私政策版本号可追溯（顶部显示 v2.0 / 更新日期）

---

### 6.14 F2 — 用户协议更新

**目标**：覆盖各应用商店用户协议模板要求。

**技术方案**：
- 新增 `lib/data/legal/user_agreement.md`
- 新增 `UserAgreementPage`（与 PrivacyPolicyPage 同构）
- 新增条款：
  - 虚拟商品不退换说明（Pro 买断）
  - 用户行为规范
  - 个人开发者免责声明
  - 账号注销流程（Phase 3 服务器接入后补全）
  - 知识产权声明
  - 争议解决条款

**集成点**：
- `SettingsPage` 新增"用户协议"入口 → `/agreement`

**验收标准**：
- [ ] 条款覆盖四大应用商店用户协议模板要求
- [ ] 与 Pro 买断流程衔接（购买前可查看）

---

### 6.15 F3 — 数据授权管理页面

**目标**：集中管理用户隐私授权，提供数据清除入口。

**技术方案**：
- 新增 `DataPrivacyPage`，整合以下管理项：
  - 匿名参与排行榜开关（D3）
  - 推送通知开关（已有，迁移到此页统一管理）
  - 数据导出（已有，Pro 用户可用）
  - 数据清除（本地全部数据，二次确认）
  - 账号注销（Phase 3 服务器接入后启用，本期灰显 + "敬请期待"）
- "数据清除"流程：
  1. 第一次点击 → 弹确认对话框（红色警告）
  2. 第二次点击 → 输入"删除"文字二次确认
  3. 调用 `Storage.clearAll()` → 跳转到 `/splash` 重新走启动流程

**集成点**：
- `SettingsPage` 新增"数据与隐私"入口 → `/data-privacy`
- `ReminderSettingsPage` 中的推送开关可保留或迁移

**关键接口**：
```dart
// DataPrivacyPage 内部方法
Future<void> _clearAllData() async {
  // 二次确认 + 输入"删除" + Storage.clearAll() + 重启路由
}
```

**验收标准**：
- [ ] 二次确认机制防止误操作
- [ ] 清除后 APP 恢复至首次启动状态
- [ ] 各开关状态正确持久化
- [ ] 账号注销项明确标注"敬请期待"

---

## 7. 数据库与存储扩展

### 7.1 DatabaseHelper v2 → v3 升级

新增 `achievements` 表：

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | TEXT PK | 徽章 ID（如 `streak_7` / `weight_1t`） |
| `category` | TEXT | 类别（streak/weight/duration/month/explore/plan/share） |
| `unlockedAt` | INTEGER | 解锁时间戳（0=未解锁） |
| `metadata` | TEXT | JSON 元数据（如解锁时的具体数值） |

**升级脚本**：
```dart
// database_helper.dart _onUpgrade
if (oldVersion < 3) {
  await db.execute('''
    CREATE TABLE achievements (
      id TEXT PRIMARY KEY,
      category TEXT NOT NULL,
      unlockedAt INTEGER NOT NULL DEFAULT 0,
      metadata TEXT NOT NULL DEFAULT '{}'
    )
  ''');
  await db.execute('CREATE INDEX idx_achievements_category ON achievements(category)');
}
```

### 7.2 Storage 新增字段

`Storage.getSettings()` 默认值扩展：

| 键 | 默认值 | 说明 |
|----|--------|------|
| `isPremium` | `false` | Pro 解锁状态 |
| `premiumSource` | `''` | 解锁来源（iap/redeem/test） |
| `redeemedCodes` | `[]` | 已兑换码列表 |
| `channelSource` | `''` | 渠道来源（D1） |
| `anonStatsOptIn` | `false` | 匿名统计开关（D3） |
| `deviceId` | `''` | 设备 ID（UUID v4，首次启动生成） |
| `ratingPromptLastShown` | `0` | 上次评分弹窗时间戳（D2） |
| `ratingPromptNeverAsk` | `false` | 永久关闭评分引导（D2） |
| `smartPushEnabled` | `true` | 智能推送开关（B3） |
| `lastPushDate` | `''` | 上次推送日期（B3） |
| `pushCountIn7Days` | `0` | 7 天内推送次数（B3） |
| `onboardingV2Done` | `false` | B1 新手引导完成标记 |
| `adConfig` | `{}` | 广告位频次控制配置（C2） |

### 7.3 新增 ValueNotifier

```dart
// storage.dart
static final ValueNotifier<bool> isPremiumNotifier = ValueNotifier<bool>(false);
static final ValueNotifier<List<String>> unlockedAchievementsNotifier =
    ValueNotifier<List<String>>([]);
```

初始化时从 settings 加载到对应 notifier。

---

## 8. 验收标准

### 8.1 功能验收

| 模块 | 验收项 |
|------|--------|
| A1 | 分享卡片生成 < 1s，图片 < 500KB，分享面板正常 |
| A2 | 首屏渲染 < 100ms，训练后立即更新，7 主题适配 |
| B1 | 90% 新用户 5 分钟内完成首训，跳过后不再骚扰 |
| B2 | 动画 ≥ 30fps，3s 内不阻塞，4 态文案正确 |
| B3 | 7 天内最多 2 次推送，3 态策略正确 |
| B4 | 21 徽章离线可解锁，DB 升级不丢数据 |
| C1 | Android IAP 真机验证通过，OHOS 兑换码解锁路径正常 |
| C2 | Pro 状态下完全跳过广告路径 |
| C3 | 单码兑换成功率 ≥ 95%，防重复兑换 |
| D1 | 渠道字段持久化，可导出 |
| D2 | 第 2 次训练后首次弹窗，30 天上限 |
| D3 | 开关默认关闭，文案明确 |
| F1 | 覆盖 PIPL 7 大类 |
| F2 | 覆盖四大商店模板要求 |
| F3 | 二次确认防误操作 |

### 8.2 非功能验收

- [ ] `flutter analyze` 无警告
- [ ] 首次启动时间 ≤ 2 秒（与 v1 持平）
- [ ] OHOS 桌面卡片功能不受影响（回归测试）
- [ ] 7 套主题下所有新 UI 适配
- [ ] DatabaseHelper v3 升级路径在 v1/v2 数据上验证通过

---

## 9. 风险与依赖

### 9.1 技术风险

| 风险 | 影响 | 概率 | 应对 |
|------|------|:----:|------|
| `in_app_purchase` 在 OHOS 不支持 | C1 OHOS 不可用 | 高 | OHOS 走兑换码兜底，明确文档化 |
| `share_plus` 在 OHOS 行为不一致 | A1 分享失败 | 中 | 加 Platform 守卫，OHOS 退化为保存图片 |
| 兑换码密钥泄漏 | C3 被破解 | 中 | 季度轮换密钥 + 多密钥校验 |
| DB v3 升级失败 | 数据丢失 | 低 | 升级前自动备份 + try-catch 容错 |
| 21 徽章解锁逻辑漏判 | B4 体验差 | 中 | 单元测试覆盖每个徽章触发条件 |

### 9.2 外部依赖

- 华为 AppGallery 开发者账号（C1 上架）
- 穿山甲后台 app_id（Phase 3 接入 C2 时需要）
- Python 3.x 运行环境（C3 兑换码生成）

### 9.3 兼容性约束

- **Dart SDK**: `>=2.19.6 <3.0.0`（不升级）
- **win32**: 继续通过 `dependency_overrides` 锁定 ≤3.1.4
- **新增依赖**: 需评估 OHOS 兼容性，必要时走 gitcode 定制分支

---

## 10. 里程碑与交付节奏

### 10.1 6 周里程碑

| 周次 | 里程碑 | 交付物 |
|:----:|--------|--------|
| W1 | 合规底座就绪 | F1/F2/F3 上线，D3 开关 UI |
| W2 | 流量工具上线 | A2 热力图 + A1 分享卡片 |
| W3 | 留存体验上线 | B1 新手引导 + B2 庆祝动画 |
| W4 | 留存机制上线 | B3 智能推送 + B4 成就徽章 |
| W5 | 变现能力上线 | C3 兑换码 + C1 Pro 解锁 + C2 接口预留 |
| W6 | 数据驱动收尾 + 联调 | D1 渠道追踪 + D2 评分引导 + 全量回归测试 |

### 10.2 测试策略

- **W2 起每周**：跑 `flutter analyze` + 7 主题手动回归
- **W4 末**：DB v3 升级路径专项测试（在 v1/v2 数据库上验证）
- **W6**：完整端到端测试，覆盖所有 15 个功能模块
- **W6 末**：OHOS 真机回归测试（桌面卡片/实况窗/通知服务）

### 10.3 上架准备

- **W6 末**：四大应用商店审核材料就绪
- 软著登记证书（提前申请）
- 隐私政策/用户协议最终版
- 应用截图更新（含热力图/分享卡片新功能）

---

## 附录 A：与现有文档的关系

| 文档 | 关系 |
|------|------|
| [CODE_WIKI.md](file:///d:/app/projects/health_training/CODE_WIKI.md) | v1 架构基线，Phase 2 在其基础上扩展 |
| [FitTrack运营方案.md](file:///d:/app/projects/health_training/docs/FitTrack运营方案.md) | 运营策略来源，Phase 2 落地其中的"变现/流量/留存"机制 |
| [FitTrack_v2_产品需求文档.md](file:///d:/app/projects/health_training/docs/FitTrack_v2_产品需求文档.md) | v2 PRD 来源，Phase 2 实现 A/B/C/D/F 模块（不含 E） |
| [实施计划](file:///d:/app/projects/health_training/docs/superpowers/plans/2026-07-13-phase2-operations-enhancement.md) | 配套的逐步执行计划，含代码与测试用例 |

## 附录 B：变更记录

| 版本 | 日期 | 变更内容 | 作者 |
|------|------|---------|------|
| v1.0 | 2026-07-13 | 初稿，定义 Phase 2 范围、模块清单、架构、验收 | AI Assistant |

---

> **下一步**：阅读配套的 [Phase 2 实施计划](file:///d:/app/projects/health_training/docs/superpowers/plans/2026-07-13-phase2-operations-enhancement.md) 获取逐步任务清单与代码模板。
