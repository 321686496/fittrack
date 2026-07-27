# 用户增长与留存体系重构设计（B/C/D/E/F/G）

- **作者**：AI 协作
- **日期**：2026-07-27
- **状态**：Draft（待用户审阅）
- **覆盖子项目**：B（推荐排序）、C（邀请奖励积分化）、D（虚拟物品价格表）、E（教学分章节改造）、F（对手功能 P0）、G（邀请流程卡对齐）
- **不覆盖**：A（"我的"页设置入口，用户已确认现状可接受）

---

## 1. 背景

当前 FitTrack 的留存/裂变体系存在以下问题：

1. **邀请奖励承诺未兑现**：5 人邀请奖励承诺的"专属虚拟对手皮肤"在 `storage.dart:428` 有字段定义，但全代码库无任何消费逻辑，等于欺骗用户。
2. **邀请奖励链路单一**：邀请人奖励靠"解锁教学/徽章"，被邀请人奖励仅 7 天高级统计体验，缺乏普适吸引力。
3. **教学解锁路径单一**：Tutorial 仅"邀请解锁"一条路径，无积分/广告解锁，用户无自主选择。
4. **对手功能半成品**：卡片不可点击、无详情页、皮肤未兑现、对手每周才推进一次（对日活零贡献）、胜负算法是 25/50/25 概率分布。
5. **推荐排序不考虑免费/付费**：精品计划与免费计划混排，引导页可能首推付费计划劝退新用户。
6. **邀请页流程卡片纵向对齐错位**：`invitation_page.dart:565-601` 外层 Row 未指定 `crossAxisAlignment`，4 个图标顶端不对齐，chevron_right 错位。

## 2. 设计目标

- 兑现承诺（修复口碑）
- 通过积分体系打通"邀请—消费—留存"闭环
- 让对手功能从"装饰背景板"升级为"长期情感锚点"
- 提升引导页转化率（免费优先）
- 修复明显的视觉瑕疵

## 3. 总体架构与依赖关系

```
┌──────────────────────────────────────────────────────────────┐
│  D 虚拟物品价格表（virtual_goods.dart）—— 基础数据层          │
└──────────────────────────────────────────────────────────────┘
       ▲                              ▲
       │                              │
   ┌───┴────────┐              ┌──────┴──────────┐
   │ C 邀请奖励  │              │ F 对手皮肤兑现   │
   │ 积分化      │              │ （消费皮肤字段） │
   └────────────┘              └─────────────────┘
   ┌────────────────────────────────────────────────────┐
   │ E 教学分章节+积分/广告解锁（独立，复用 UnlockPanel）│
   └────────────────────────────────────────────────────┘
   ┌──────────────────────────────────┐
   │ B 推荐排序免费优先（独立）        │
   └──────────────────────────────────┘
   ┌──────────────────────────────────┐
   │ G 邀请流程卡对齐修复（独立小改）  │
   └──────────────────────────────────┘
```

实施顺序：**D → G → B → E → C → F**

## 4. 子项目 D：虚拟物品价格表（基础数据层）

### 4.1 目标

建立项目首个统一的虚拟物品数据模型与价格表，作为 C（邀请奖励）与 F（对手皮肤）的依据。

### 4.2 数据模型

新建 `fittrack_flutter/lib/data/virtual_goods.dart`：

```dart
enum GoodCategory {
  opponentSkin,    // 对手皮肤
  badge,           // 徽章
  avatarFrame,     // 头像框
  title,           // 称号
}

class VirtualGood {
  final String id;                  // 如 'skin_iron_warrior'
  final String name;                // 如 '钢铁战士'
  final GoodCategory category;
  final int pointsCost;             // 积分价格
  final String emoji;               // 视觉标识（emoji）
  final String? unlockCondition;    // 解锁条件描述（如"累计邀请5人"，纯积分购买时为 null）
  final bool isLimited;             // 是否限定款
  final Map<String, dynamic>? metadata; // 扩展（如皮肤对应的配色、头像 emoji 等）
}

class VirtualGoodsStore {
  static const List<VirtualGood> kAllGoods = [...];
  static List<VirtualGood> byCategory(GoodCategory c);
  static VirtualGood? byId(String id);
  static List<VirtualGood> affordableWith(int points);
}
```

### 4.3 价格梯度表

| 档位 | 积分价格 | 对手皮肤举例 | 其他物品举例 |
|---|---|---|---|
| 入门款 | 100 | "健身小白" | 基础头像框 |
| 标准款 | 300 | "钢铁战士" | 标准徽章 |
| 精品款 | 600 | "赛博忍者" | 精品头像框 |
| 典藏款 | 1200 | "燃力大使"（限定） | 独占称号 |

### 4.4 初始商品清单（对手皮肤）

| id | name | price | limited | 解锁条件 |
|---|---|---|---|---|
| `skin_beginner` | 健身小白 | 100 | 否 | 无 |
| `skin_iron_warrior` | 钢铁战士 | 300 | 否 | 无 |
| `skin_cyber_ninja` | 赛博忍者 | 600 | 否 | 无 |
| `skin_ambassador` | 燃力大使 | 1200 | 是 | 累计邀请 5 人 |

> `skin_ambassador` 是邀请奖励兑现的"专属虚拟对手皮肤"，不可纯积分购买，仅可通过累计邀请 5 人解锁。

### 4.5 设置字段（沿用现有，不新增）

`storage.dart` 已有：
- `unlockedOpponentSkin: bool` —— 本次开始真正消费
- `unlockedFeatures: List<String>` —— 通用积分解锁列表

新增约定（不新增字段，仅约定写入规则）：
- 纯积分购买的皮肤 → 写入 `unlockedFeatures`，key = `good_<id>`（如 `good_skin_iron_warrior`）
- 邀请里程碑解锁的皮肤 → 写入 `unlockedFeatures` + 同时把 `unlockedOpponentSkin = true`（仅累计 5 人档）

## 5. 子项目 G：邀请流程卡片纵向对齐修复

### 5.1 问题

`invitation_page.dart:565-601` 外层 `Row` 未指定 `crossAxisAlignment`，默认 `center`，导致：
1. 4 个步骤的圆形图标（44×44）顶端不对齐
2. chevron_right 垂直居中于整个 Column 高度（约 70-80px），落到标题位置而非图标中线

### 5.2 修复方案

```dart
// invitation_page.dart:565 外层 Row
Row(
  crossAxisAlignment: CrossAxisAlignment.start, // 新增
  children: steps.asMap().entries.map((entry) {
    final idx = entry.key;
    final s = entry.value;
    final isLast = idx == steps.length - 1;
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // 新增
        children: [
          Expanded(
            child: Column(
              children: [
                Container(width: 44, height: 44, /* ... */),
                const SizedBox(height: 8),
                Text(s.title, /* ... */),
                const SizedBox(height: 2),
                Text(s.desc, /* ... */),
              ],
            ),
          ),
          if (!isLast)
            // 用 SizedBox 限定高度，让 chevron_right 与圆形图标中线对齐
            SizedBox(
              height: 44,
              child: Center(
                child: Icon(Icons.chevron_right, color: colors.textMuted, size: 18),
              ),
            ),
        ],
      ),
    );
  }).toList(),
),
```

## 6. 子项目 B：引导页推荐计划免费优先

### 6.1 问题

`plan_recommendation_service.dart:81-82` 仅按 `score` 降序，免费/付费混排。

### 6.2 修复方案

在排序阶段增加二级排序键：

```dart
// 原：
scored.sort((a, b) => b.score.compareTo(a.score));

// 改为：
scored.sort((a, b) {
  final scoreDiff = b.score.compareTo(a.score);
  if (scoreDiff != 0) {
    // 同段判定：score 差 ≤ 5 视为同段
    if ((b.score - a.score).abs() > 5) return scoreDiff;
  }
  // 同段内免费（isPremium=false）排前
  final aPremium = a.plan.isPremium ? 1 : 0;
  final bPremium = b.plan.isPremium ? 1 : 0;
  return aPremium.compareTo(bPremium);
});
```

### 6.3 不变更

- 评分维度（难度/频率/BMI/肌群/新颖度）保持不变
- top5 总数保持不变
- 仅调整同段内顺序，避免免费低质计划挤掉付费高质计划

## 7. 子项目 E：教学中心 Tutorial 分章节改造

### 7.1 问题

`tutorial_content.dart` 当前 `Tutorial` 类不分章节，仅"邀请解锁"一条路径，无积分/广告解锁。

### 7.2 数据结构改造

给 `Tutorial` 类新增 `chapters: List<Chapter>` 字段（复用 `course_content.dart` 中已存在的 `Chapter` 类），把现有内容拆为 3 章：

- **第 1 章**：动作要领（由 `keyPoints` 转换为 `ContentBlock` 列表）
- **第 2 章**：常见错误（由 `commonMistakes` 转换）
- **第 3 章**：呼吸方法+进阶变式（`breathingTip` + `alternativeExerciseIds`）

保留 `keyPoints` / `commonMistakes` / `breathingTip` 旧字段作为 fallback（兼容现有 UI 渲染逻辑），新 UI 优先读 `chapters`。

### 7.3 解锁机制

| 类型 | 旧机制 | 新机制 |
|---|---|---|
| `basic` | 免费 | 免费（保持） |
| `advanced` | 邀请 1 人解锁 3 个 | 按章节积分/广告解锁，每章 50 积分；邀请 1 人后所有 advanced 章节免费 |
| `topic` | 累计邀请 3 人 | 按章节积分/广告解锁，每章 80 积分；累计邀请 3 人后所有 topic 章节免费 |
| `master` | 累计邀请 5 人 | 按章节积分/广告解锁，每章 120 积分；累计邀请 5 人后所有 master 章节免费 |

每章支持两种解锁方式（复用 `UnlockPanel`）：
- 看广告免费解锁（受 `AdService.adsEnabled` 开关控制）
- 消耗对应积分解锁

### 7.4 解锁状态字段

沿用现有约定：
- 单章解锁 → 写入 `unlockedFeatures`，key = `tutorial_<tutorialId>_chapter_<chapterId>`
- 整套解锁（邀请里程碑触发）→ 写入 `unlockedFeatures`，key = `tutorial_<tutorialId>_all`

### 7.5 文件改动

- `tutorial_content.dart`：给 `Tutorial` 增加 `chapters` 字段，构建函数把现有字段拆为 3 章
- `tutorial_detail_page.dart`：
  - 渲染逻辑改为按章节列表展示
  - 章节未解锁时点击展开 UnlockPanel
  - 底部"邀请解锁"按钮改为"邀请加速解锁"（保留为可选路径）
- `tutorial_list_page.dart`：`_isTypeUnlocked` 逻辑保持（用于整套解锁判定），单章解锁走 `unlockedFeatures` 查询

## 8. 子项目 C：邀请奖励积分化重构

### 8.1 问题

邀请人奖励靠"解锁教学/徽章/对手皮肤(未兑现)+50 积分"，被邀请人仅 7 天高级统计体验。奖励价值感低、不普适。

### 8.2 新奖励表（依赖子项目 D 价格表）

| 里程碑 | 邀请人奖励 | 被邀请人奖励 |
|---|---|---|
| 首次邀请（1 人） | 100 积分 + "引路人"徽章 | 50 积分 |
| 累计 3 人 | 300 积分 + "布道者"徽章 | 50 积分 |
| 累计 5 人 | 600 积分 + "传道者"徽章 + 解锁限定对手皮肤 `skin_ambassador` | 50 积分 |
| 累计 10 人 | 1200 积分 + "燃力大使"称号 | 50 积分 |

### 8.3 取消项

- 取消"邀请人解锁教学专题"作为里程碑奖励（教学走子项目 E 的积分解锁路径）
- 取消"被邀请人 7 天高级统计体验"改为积分（更普适，避免部分用户不需要高级统计）

### 8.4 文件改动

- `invitation_service.dart`：
  - `recordReferralActivation`：`addPoints(50, 'invite')` 改为按里程碑发放（100/300/600/1200）
  - `_unlockBadge`：累计 5 人时同步把 `unlockedOpponentSkin = true` 并写入 `unlockedFeatures: ['good_skin_ambassador']`
  - `activateInvitationCode`：被邀请人奖励从"7 天高级统计"改为 `addPoints(50, 'invited')`
- `invitation_page.dart`：奖励规则文案同步更新（4 档表格 + 双方获奖说明）
- `storage.dart`：保留 `unlockedOpponentSkin` 字段但开始真正消费；保留 `activatedInvitationCode` 等现有字段

### 8.5 边界

- 单机版限制：邀请人主动输入被邀请人激活码才能记录（沿用现有逻辑）
- 防自邀：沿用现有 deviceId 4 位哈希对比
- 积分日志：每次发放写入 `pointsLog`（最近 50 条）

## 9. 子项目 F：对手功能完善（P0 最小可用版）

### 9.1 问题

- 卡片不可点击（首页卡片虽支持 onTap 但未绑定回调；训练结束页根本不可点击）
- 无对手详情页
- 皮肤字段未消费
- 对手每周才推进一次（对日活零贡献）
- `avatarSeed` 字段未使用，对手仅用通用 Icon

### 9.2 P0 范围

1. 新建对手详情页 `opponent_detail_page.dart`
2. 首页 + 训练结束页对手卡片可点击进入详情页
3. 兑现 5 人邀请皮肤奖励（消费 `unlockedOpponentSkin` + `unlockedFeatures` 中的皮肤 ID）
4. 对手每日动态推送（`VirtualOpponentEngine` 新增 `dailyAdvance()`）
5. 头像渲染（消费 `avatarSeed` + 皮肤 ID）

### 9.3 不在 P0 范围（P1 留下版本）

- 手动挑战机制（"本周PK发起"按钮）
- 胜负算法改为基于真实数据差（去掉 25/50/25 概率）
- 对手分身池可选/切换

### 9.4 对手详情页设计

新建 `fittrack_flutter/lib/pages/opponent_detail_page.dart`：

**页面结构**：
1. **顶部对手卡**：头像（带皮肤）+ 昵称 + 层级标签 + 人设
2. **本周战绩区**：训练次数 / 总重量 / 总时长，3 列数据卡
3. **今日动态区**：对手当天状态（如"今天练了胸+三头，累计 4500kg"）
4. **历史 PK 记录**：最近 4 周的 PK 结果列表（领先/平局/追赶中）
5. **皮肤展示区**：当前应用的皮肤 + 已拥有皮肤列表 + "去邀请解锁更多"入口

**路由**：`/opponent-detail`，从首页卡片和训练结束卡片 onTap 跳转

### 9.5 皮肤应用逻辑

在 `VirtualOpponent` 模型新增 `appliedSkinId: String?` 字段（运行时计算，不持久化）：

```dart
String get appliedSkinId {
  final settings = Storage.getSettings();
  // 优先：邀请里程碑解锁的限定皮肤
  if (settings['unlockedOpponentSkin'] == true) return 'skin_ambassador';
  // 其次：从 unlockedFeatures 中查找已购皮肤
  final unlocked = (settings['unlockedFeatures'] as List?) ?? [];
  for (final id in ['skin_cyber_ninja', 'skin_iron_warrior', 'skin_beginner']) {
    if (unlocked.contains('good_$id')) return id;
  }
  return ''; // 默认无皮肤
}
```

皮肤渲染（替代 `Icon(Icons.sports_kabaddi)`）：

```dart
final skin = VirtualGoodsStore.byId(opponent.appliedSkinId);
final emoji = skin?.emoji ?? '🤖';
Text(emoji, style: TextStyle(fontSize: 32));
```

### 9.6 每日动态推送

`VirtualOpponentEngine` 新增方法：

```dart
/// 每日凌晨推进对手训练状态（不再每周才推进）
/// 职责：仅负责"本周内"的增量推进（训练次数/重量/时长/偶尔动态）
/// 周数据重置由现有 advanceWeekly() 在周日凌晨独立负责，dailyAdvance 不重复触发
void dailyAdvance() {
  // 1. 检查今天是否已推进（用 settings['opponentLastAdvanceDate'] 防重复）
  // 2. 若今天已推进 → 直接 return
  // 3. 若今天是周一（周日刚过完）→ 先调用 advanceWeekly() 把上周数据快照并重置本周
  // 4. 30% 概率对手今天训练（按 tier 调整频率：硬核 60%、活跃 40%、规律 25%、休闲 15%）
  // 5. 若训练：增加 weeklyTrainings/weeklyWeight/weeklyDuration
  // 6. 10% 概率发布偶尔动态（currentStatus）
  // 7. 写入 settings['opponentLastAdvanceDate'] = today
}
```

调用时机：`HomePage.initState` 时调用一次（每天首次打开 App 推进）。

### 9.7 文件改动

- `virtual_opponent.dart`：
  - `VirtualOpponent` 新增 `appliedSkinId` getter
  - `VirtualOpponentEngine` 新增 `dailyAdvance()` 方法
- `virtual_opponent_card.dart`：
  - onTap 跳转 `/opponent-detail`
  - 头像渲染改为消费皮肤 emoji
- `training_page.dart:1377-1468` `_buildOpponentPKCard`：用 InkWell 包裹，onTap 跳转 `/opponent-detail`
- `home_page.dart`：`initState` 调用 `VirtualOpponentEngine.instance.dailyAdvance()`
- 新建 `opponent_detail_page.dart`
- `router.dart`：新增 `/opponent-detail` 路由

## 10. 测试策略

- **单元测试**：
  - `VirtualGoodsStore` 查询方法（byCategory/byId/affordableWith）
  - `PlanRecommendationService.recommend` 同段内免费优先
  - `VirtualOpponent.appliedSkinId` getter 不同解锁状态下的返回值
  - `VirtualOpponentEngine.dailyAdvance` 防重复推进
- **集成测试**：
  - 邀请激活完整流程：激活码 → 邀请人/被邀请人积分发放 → 里程碑徽章/皮肤解锁
  - Tutorial 章节解锁：积分扣减 → unlockedFeatures 写入 → 章节可访问
- **UI 测试**：
  - 邀请页流程卡片 4 个图标顶端在同一水平线（用截图对比）
  - 对手详情页跳转：首页卡片点击 → 详情页加载 → 返回
- **回归测试**：
  - `flutter analyze` 零新增 error
  - 现有邀请/教学/对手功能不受影响

## 11. 风险与缓解

| 风险 | 缓解 |
|---|---|
| 邀请奖励数值改大后导致积分通胀 | 保留 `pointsEarnedTotal` 监控，必要时引入积分有效期 |
| 教学分章节后内容拆分质量下降 | 保留旧字段 fallback，UI 优先读 chapters 但旧字段仍在 |
| 对手详情页开发量超预期 | P0 范围严格限定，手动挑战/分身池明确放 P1 |
| `dailyAdvance` 每日调用导致数据漂移 | 用 `opponentLastAdvanceDate` 严格防重复 |
| 限定皮肤 `skin_ambassador` 被邀请5人后所有对手都展示 | 设计时明确：皮肤是"对手显示的视觉"，不是"对手本身"，所有对手都用当前应用皮肤 |

## 12. 不在范围

- 子项目 A（"我的"页设置入口优化）—— 用户已确认现状可接受
- 对手手动挑战机制 —— P1
- 对手胜负算法改造 —— P1
- 对手分身池 —— P2
- 积分商城独立页面 —— 本次仅建价格表，商城页放下个版本
- 邀请码服务器化 —— Phase 3 联网版

## 13. 验收标准

- [ ] `flutter analyze` 零新增 error
- [ ] 邀请页流程卡片 4 个圆形图标顶端在同一水平线，chevron_right 与图标中线对齐
- [ ] 引导页推荐计划列表中，同评分段内免费计划排在付费计划前面
- [ ] Tutorial 详情页按章节渲染，每章可单独积分解锁或广告解锁
- [ ] 邀请激活成功后，邀请人按里程碑获得 100/300/600/1200 积分，被邀请人获得 50 积分
- [ ] 累计邀请 5 人后 `unlockedOpponentSkin = true` 且 `unlockedFeatures` 包含 `good_skin_ambassador`
- [ ] 首页对手卡片可点击进入对手详情页
- [ ] 训练结束页对手 PK 卡片可点击进入对手详情页
- [ ] 对手详情页展示皮肤（5 人邀请后展示 `skin_ambassador`）
- [ ] 每日首次打开 App 时对手推进一次（防重复推进）
- [ ] 单元测试 + 集成测试通过
