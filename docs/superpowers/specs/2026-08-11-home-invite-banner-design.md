# 首页邀请专属 Banner 卡片设计

- **作者**：AI 协作
- **日期**：2026-08-11
- **状态**：Draft
- **覆盖**：为「邀请有礼」在首页推荐轮播中设计专属卡片，固定为第一项并展示动态邀请进度，提高用户邀请意愿

---

## 1. 背景

首页已有推荐轮播 `RecommendationBanner`（[recommendation_banner.dart](../../../fittrack_flutter/lib/widgets/recommendation_banner.dart)），数据由 `RecommendationService.generateBanners()`（[recommendation_service.dart](../../../fittrack_flutter/lib/services/recommendation_service.dart)）生成：教学推荐 + 付费方案 + 训练计划 + 邀请有礼 + 成就挑战，然后整体 `shuffle(Random(DateTime.now().day))`，每天顺序随机。

现状问题：**邀请 banner 参与随机 shuffle，位置不固定、无动态进度信息**（静态文案「最高 2000 积分等你拿」），曝光与驱动力不足。

上一轮已交付激活识别码（FIT-ACT）闭环，邀请激励体系完整可用，本设计提升其曝光转化。

## 2. 设计目标

- 邀请卡片**固定为轮播第一项**，用户一进首页即可见
- 卡片展示**动态邀请进度**（已邀请人数 / 距下里程碑差几人 / 进度条），驱动持续邀请
- 卡片采用**独有专属视觉**，与其他 banner 区分，增强吸引力
- 保持 app 主题色约束（仅用 `LiftTrackColors` 既有色），不新增自定义颜色

## 3. 位置与数据流

### 3.1 置顶策略

`RecommendationService.generateBanners()`（[recommendation_service.dart](../../../fittrack_flutter/lib/services/recommendation_service.dart#L43-L107)）：

- 现实现将 invitation 通过 `items.add(BannerItem.invitation())` 加入（L101），最后 `items.shuffle(Random(DateTime.now().day))`（L105）。改为：**移除 L101 的 add**，在 shuffle 前先从 items 中提取 invitation 项（或记录其下标），仅对**其余** items 执行 shuffle，再将 invitation `items.insert(0, invitation)` 插回首位
- 保证邀请卡片永远是轮播第一项，其余 banner 顺序照旧每日随机

### 3.2 动态数据

`BannerItem.invitation()` 工厂（[recommendation_service.dart](../../../fittrack_flutter/lib/services/recommendation_service.dart#L25-L31)）读取 `InvitationService.instance.getReferralProgress()`（[invitation_service.dart](../../../fittrack_flutter/lib/services/invitation_service.dart#L434-L445)），通过 `extra` 字段携带：

> 注意：现 `factory BannerItem.invitation()` 是 `const`（因 `achievementChallenge()` 同为 const 且整体列表在 `const BannerItem.invitation()` 处被 const 求值）。改为读取动态数据后**必须去掉 const**——将工厂改为非 const，内部读 `getReferralProgress()` 并填充 `extra`。`BannerItem` 类的 const 构造保留（其他静态 banner 仍可 const）。

| extra 字段 | 来源 | 说明 |
|---|---|---|
| `totalReferrals` | `getReferralProgress()['totalReferrals']` | 已邀请人数 |
| `nextMilestone` | `getReferralProgress()['nextMilestone']` | 下一里程碑人数（1/3/5/10） |
| `isAmbassador` | `getReferralProgress()['isAmbassador']` | 是否已达最高档 |

> `BannerItem` 的 `extra` 字段已存在（`Map<String, dynamic>?`），无需改类结构。注意：`generateBanners()` 是静态方法，内部读取 `Storage.getSettings()` 与 `PointsService` 均同步可用，`getReferralProgress()` 同样同步返回。

### 3.3 点击行为

沿用现有：`route: '/invitation'`，点击 `context.push('/invitation')`（[recommendation_banner.dart](../../../fittrack_flutter/lib/widgets/recommendation_banner.dart#L67-L70)）。

## 4. 专属视觉设计

在 `_buildBanner`（[recommendation_banner.dart](../../../fittrack_flutter/lib/widgets/recommendation_banner.dart#L63-L154)）中，`type == 'invitation'` 时特判渲染专属布局，其他 type 走现有逻辑不变。

### 4.1 布局（自上而下）

```
┌───────────────────────────────────────────────┐
│  (右上光晕圆 + 左下小圆，沿用装饰语言)             │
│   [礼物图标] 邀请有礼                [角标]       │
│                                               │
│   已邀请 2 / 3 人                              │
│   ▓▓▓▓▓▓▓░░░░  (线性进度条，圆角3)              │
│                                               │
│   (白色胶囊) 还差 1 人解锁奖励 →                 │
└───────────────────────────────────────────────┘
```

- **渐变背景**：沿用 `_gradientFor` 的 `'invitation'` 分支（`successColor` → `successColor.withOpacity(0.6)`），绿色系专属，符合主题色约束
- **头部**：左为礼物图标（`Icons.card_giftcard`，白色 80% 透明度，20px）+「邀请有礼」加粗标题（白 20px bold）；右为可选角标（已达人时显示「大使」小胶囊）
- **进度文案**：
  - 未达最高档：`已邀请 X / Y 人`（X = totalReferrals，Y = nextMilestone）
  - 已达最高档（isAmbassador）：`已邀请 X 人 · 大使`
- **进度条**：高度 6，圆角 3，`ClipRRect` 包裹，底层白色 25% 透明度、填充白色 90% 透明度，宽度比例 `X / Y`（clamp 0~1）
- **CTA 胶囊**：
  - N = nextMilestone − totalReferrals
  - N > 0：`还差 N 人解锁奖励 →`
  - N ≤ 0（已达下一档或最高档）：`查看全部奖励 →`
  - 样式：白色 20% 透明度底 + 圆角 20 + 白色加粗 12px，与现有 CTA 一致
- 整体 `mainAxisAlignment: spaceBetween` 纵向分布，padding 20，高 150（轮播固定高度不变）

### 4.2 与其他 banner 的区分

- 普通 banner：标题+副标题+CTA 三行静态文本，无进度条无图标
- 邀请专属：加图标、动态进度文案、进度条、动态 CTA，视觉密度更高、信息层级更强

## 5. 边界处理

| 场景 | 表现 |
|---|---|
| `totalReferrals == 0` | 进度条 0%，CTA `邀请好友，双方得积分 →` |
| 0 < X < Y | `已邀请 X / Y 人`，进度条 X/Y，CTA `还差 N 人解锁奖励 →` |
| X ≥ Y 且未达最高档 | 进度条满，CTA `查看全部奖励 →`（nextMilestone 已按 _nextMilestone 递增，实际 X ≥ Y 时 Y 即已升至更高档，故该档位通常由 Y 递增吸收） |
| isAmbassador（X ≥ 10） | `已邀请 X 人 · 大使`，进度条满，CTA `查看全部奖励 →` |
| `extra` 数据缺失（防御） | 按 X=0、Y=1 兜底渲染，不崩溃 |

## 6. 服务/组件改动清单

| 文件 | 改动 |
|---|---|
| `lib/services/recommendation_service.dart` | `generateBanners()`：invitation 固定 insert(0) 且不参与 shuffle；`BannerItem.invitation()` 工厂读进度数据写入 `extra` |
| `lib/widgets/recommendation_banner.dart` | `_buildBanner` 增加 `type == 'invitation'` 专属分支 `_buildInvitationBanner`（新私有方法） |
| `test/recommendation_service_test.dart`（若不存在则新建） | 单测：首项必为 invitation；extra 数据正确 |

## 7. 测试

- 单测 `recommendation_service_test.dart`：
  - `generateBanners()` 非空且 `first.type == 'invitation'`
  - `first.extra['nextMilestone']` 与当前进度一致（模拟无邀请 → nextMilestone 1）
- 回归：`flutter analyze` 无新增问题；首页轮播渲染无 Overflow（150 高度内布局）

## 8. 范围边界（不在本设计内）

- 邀请页本身（`/invitation`）UI 不动
- 其他 banner 的内容/顺序策略不变
- 弹窗/引导类强化曝光方案（如邀请进度浮层）不做
