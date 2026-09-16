# 邀请有礼流程详情页 + 奖励链路修复 设计文档

日期：2026-09-09
状态：已获用户批准的设计，待实施

## 背景

邀请有礼模块（`/invitation`，`InvitationPage`）现有 4 步水平流程卡片（分享→注册→训练→获奖）仅作静态展示，无法查看完整流程细节。用户希望：

1. 流程卡片可点击，进入详情页查看从「分享邀请码」到「双方获得全部奖励」的完整流程信息。
2. 核查邀请人奖励链路完整性。

### 奖励链路核查结论（已完成的检查）

奖励核心逻辑位于 `invitation_service.dart` + `points_service.dart`，有测试覆盖：

| 检查项 | 结论 |
|---|---|
| 邀请成功奖励 | 完整：档位制自动发放（1 人→100 分、3 人→300 分、5 人→600 分+限定皮肤、10 人→1200 分+大使称号），另解锁徽章 |
| 邀请人数累加 | 完整：`myReferralCodes` 去重累加，进度卡片同步刷新 |
| 累加奖励领取 | 完整：`addPoints` 自动入账并写入积分流水，无需手动领取 |

但发现 2 个真实缺陷（本次一并修复）：

- **误导性 Toast**：第 2、4、6~9 次成功记录识别码时积分为 0（档位制），但 Toast 仍显示「记录成功！积分奖励已到账」。
- **积分明细标签缺口**：`points_detail_page.dart` 中 `invite_milestone_N` 来源显示为原始字符串；「邀请」筛选器只精确匹配 `invite`，匹配不到 `invited` 与 `invite_milestone_N`，邀请奖励会被筛掉。

## 方案（用户已选定）

- 详情页形式：**独立页面 + 双视角流程**（新增路由 `/invitation/flow`）。
- 上述 2 个奖励链路问题**一并修复**。

## 详细设计

### 1. 新页面 `InvitationFlowDetailPage`

新文件：`lib/pages/invitation_flow_detail_page.dart`

路由：go_router 注册 `/invitation/flow`，`parentNavigatorKey: rootNavigatorKey`（与 `/invitation` 等现有页面规范一致），在 `router.dart` 的 `/invitation` 路由后追加。

页面结构：`PageHeader`（标题「邀请流程详解」，返回）+ `SingleChildScrollView` 滚动内容。沿用 `CardWidget` / `LiftTrackColors` / `app_themes.dart` 主题色与 Material `Icons.*` 图标（与 `InvitationPage` 现有用法一致），不新增自定义颜色。

内容区段（自上而下）：

1. **邀请人视角**（竖向时间线，6 步，每步含圆形图标节点 + 标题 + 操作说明 + 涉及奖励标注）：
   - 步骤 1：分享邀请码 — 复制邀请码或生成邀请海报，通过微信/QQ 发给好友（邀请码永久有效）
   - 步骤 2：好友激活 — 好友在「输入邀请码」中输入你的邀请码，好友立即 +50 积分（一码一绑，激活后不可更换）
   - 步骤 3：好友完成首次有效训练 — 有效训练指完成至少 1 组动作的训练记录
   - 步骤 4：好友出示激活凭证 — 好友在「我的激活凭证」生成 FIT-ACT 识别码（加密签名，含训练数据快照）发给你
   - 步骤 5：你确认记录 — 在「记录邀请成果」中扫码或输入识别码，系统校验达标与防自邀后入账
   - 步骤 6：奖励自动到账 — 按累计档位发放，无需手动领取
2. **被邀请人视角**（4 步时间线）：
   - 获取好友邀请码 → 输入激活立即 +50 积分 → 完成首次训练 → 出示激活凭证（好友确认后，你的邀请关系完成闭环）
3. **奖励对照卡片**：4 档 ×（邀请人 / 被邀请人）两列布局卡片，数据与 `_buildRewardRulesCard` 的档位一致（1/3/5/10 人 → 100/300/600/1200 分；被邀请人恒为 50 分；5 人档含限定皮肤、10 人档含大使称号）
4. **规则说明卡片**：邀请码永久有效、一码一绑、防自邀（不能激活自己的邀请码）、激活凭证每次生成反映最新训练数据、奖励档位制（非每人均有积分）

### 2. 流程卡片可点击入口

`invitation_page.dart` 的 `_buildFlowCard`：

- `CardWidget` 包裹点击（`InkWell`/`GestureDetector`），点击后 `context.push('/invitation/flow')`（与项目 go_router 用法一致）。
- 卡片头部 Row 尾部追加「查看详情」+ chevron_right 图标提示，颜色用 `colors.textMuted`。

### 3. 修复误导 Toast（结构化返回值）

`invitation_service.dart`：

- 新增结果类：

```dart
class ReferralRecordOutcome {
  final bool success;        // 是否成功入账（新识别码）
  final int totalReferrals;  // 入账后累计人数（失败时为当前值）
  final int pointsEarned;    // 本次发放积分（非档位为 0）
  final ReferralMilestone? milestone; // 命中的里程碑（非档位为 null）
}
```

- `recordReferralActivation` 返回类型由 `Future<ReferralMilestone?>` 改为 `Future<ReferralRecordOutcome>`：
  - 校验失败 / 防自邀 / 去重命中 → `success: false`，其余字段为零值/当前值。
  - 入账成功 → `success: true`，`totalReferrals` 为入账后人数，`pointsEarned` / `milestone` 按档位填充。
- `invitation_page.dart` 的 `_recordReceipt` 按 `success` 与 `pointsEarned` 分支提示：
  - 成功且 `pointsEarned > 0`：「记录成功！+X 积分已到账」
  - 成功且 `pointsEarned == 0`：「记录成功！已累计邀请 N 人」
  - 失败：维持原失败提示文案
- `_loadData()` 刷新逻辑不变。

### 4. 修复积分明细标签

`points_detail_page.dart`：

- `_sourceLabel` 的 map 增加：`'invite_milestone_*'` 前缀分支 → 「邀请里程碑奖励（第 N 人）」（在 startsWith 分支区处理，N 从 source 尾部解析）。
- `_matchSource` 的 `invite` 分支改为：`source == 'invite' || source == 'invited' || source.startsWith('invite_milestone_')`。

## 不改动的部分

- 邀请码生成/校验、识别码编解码、防自邀、去重逻辑（`_grantMilestone` 入账顺序）均不变。
- `PointsService.addPoints` 入账与通知机制不变。
- 奖励数值与档位（1/3/5/10 人）不变。
- `InvitationPage` 其余区段（邀请码卡片、进度概览、奖励规则、激活/凭证卡片）不变。

## 错误处理

- 详情页为纯静态展示页，无异步操作，无需错误处理。
- `_recordReceipt` 失败分支维持现状（Toast 错误提示）。

## 测试计划

- 更新 `test/invitation_service_test.dart`：
  - 原 `recordReferralActivation` 返回值断言改为 `ReferralRecordOutcome`（`.success`、`.milestone`、`.pointsEarned`、`.totalReferrals`）。
  - 新增：第 2 次入账（非档位）→ `success: true, pointsEarned: 0`；重复识别码 → `success: false`。
- 运行 `flutter test test/invitation_service_test.dart` 验证。
- 手动验证：邀请页流程卡片点击跳转详情页；详情页双视角与奖励对照渲染正确；积分明细筛选「邀请」能看到 `invited` / `invite_milestone_N` 记录并显示友好标签。
