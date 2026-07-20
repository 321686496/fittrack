# 训练计划库系统设计

> 日期：2026-07-20
> 状态：已审阅通过

## 1. 概述

对训练计划页面进行全面优化，新增系统计划库独立页面（三层分类 + 瀑布流首页）、推荐算法（4 项信号评分）、精品计划解锁机制（积分支付 + 90 天有效期）、以及主页三段式布局改造。

## 2. 架构方案

**选定方案：方案 B — JSON 配置文件 + 独立推荐服务 + 独立解锁管理**

理由：数据与代码解耦、50+ 计划按目标分 5 个 JSON 文件便于维护、为 Phase 3 远程下发预留平滑迁移路径。

## 3. 数据结构

### 3.1 JSON 文件组织

```
assets/data/system_plans/
├── bulk.json       # 增肌（~12个，6精品）
├── cut.json        # 减脂（~10个，5精品）
├── shape.json      # 塑形（~10个，5精品）
├── keep.json       # 保持健康（~8个，3精品）
└── strength.json   # 力量（~10个，6精品）
```

总计 ~50 个计划，25 个精品均匀分布。

### 3.2 单个计划 JSON Schema

```json
{
  "id": "bulk_3day_beginner_01",
  "name": "新手增肌·三分化入门",
  "goal": "bulk",
  "difficulty": "beginner",
  "trainingType": "3day_split",
  "isPremium": false,
  "pointsCost": 0,
  "totalWeeks": 8,
  "defaultRestTime": 90,
  "description": "专为增肌新手设计的三分化训练，每周3练...",
  "coverEmoji": "💪",
  "coverColors": ["#FF6B6B", "#C44D4D"],
  "tags": ["新手友好", "低疲劳"],
  "recommendedFrequency": 3,
  "suitableFor": "体脂率15-25%，无训练基础或停练超过3个月",
  "days": [
    {
      "day": 1,
      "label": "推胸日",
      "muscle": "胸部",
      "exercises": [
        {"id": "ex_bp_01", "name": "杠铃卧推", "sets": 4, "reps": 10, "restTime": 90}
      ]
    }
  ]
}
```

### 3.3 三层分类体系

| 层 | 维度 | 值 |
|---|------|------|
| L1 目标 | goal | bulk / cut / shape / keep / strength |
| L2 难度 | difficulty | beginner / elementary / intermediate / advanced |
| L3 训练类型 | trainingType | 3day_split / 4day_split / 5day_split / full_body / hiit |

## 4. 系统计划库加载（Dart 类）

### 4.1 SystemPlanLibrary（新建 `lib/data/system_plan_library.dart`）

- 单例模式
- `Future<void> load()` — 启动时异步加载全部 5 个 JSON，合并为 `List<SystemPlan>` 缓存
- `List<SystemPlan> getByGoal(goal)` — 按目标筛选
- `List<SystemPlan> getByDifficulty(difficulty)` — 按难度筛选
- `List<SystemPlan> getByGoalAndDifficulty(goal, difficulty)` — 组合筛选
- `SystemPlan? getById(id)` — 按 ID 获取
- `List<SystemPlan> recommend(...)` — 推荐入口（调用 PlanRecommendationService）

### 4.2 SystemPlan 数据类

```dart
class SystemPlan {
  final String id;
  final String name;
  final String goal;           // bulk/cut/shape/keep/strength
  final String difficulty;     // beginner/elementary/intermediate/advanced
  final String trainingType;   // 3day_split/4day_split/5day_split/full_body/hiit
  final bool isPremium;
  final int pointsCost;
  final int totalWeeks;
  final int defaultRestTime;
  final String description;
  final String coverEmoji;
  final List<String> coverColors;
  final List<String> tags;
  final int recommendedFrequency;
  final String suitableFor;
  final List<SystemPlanDay> days;
}
```

## 5. 推荐算法

### 5.1 PlanRecommendationService（新建 `lib/services/plan_recommendation_service.dart`）

**输入信号（4 项）：**

| 信号 | 数据源 | 计算方式 |
|------|--------|----------|
| 身体数据 | `Storage.getBodyData()` | BMI 区间匹配 + 体脂率分层 + 静止心率参考 |
| 实际训练强度 | `Storage.getRecords()` (近 30 天) | 平均组数 × 平均重量 × 组数 → 推断 fitnessLevel |
| 实际训练频率 | `Storage.getRecords()` (近 30 天) | 去重天数 / 30 → 匹配 recommendedFrequency |
| 近 30 天肌群分布 | `Storage.getRecords()` | 每个 exercise 的 muscle 出现频次 → 推断训练偏好 |

**算法步骤：**
1. 筛：用户 `fitnessGoal` 匹配 `plan.goal` → 候选池
2. 排：对候选池每个 plan 计算匹配度 `score = 0~100`
   - difficulty 匹配度（~30 分）
   - frequency 匹配度（~25 分）
   - BMI 区间匹配（~15 分）
   - 肌群偏好匹配（~15 分）
   - 未训练过的计划加分（~15 分）
3. 截：返回 top 5

### 5.2 Banner 扩展

在 `RecommendationService.generateBanners()` 中新增 `type: 'plan'` 类型 banner，取 `recommend()` top1。

## 6. 精品计划解锁机制

### 6.1 PlanUnlockService（新建 `lib/services/plan_unlock_service.dart`）

**解锁流程：**
1. 用户点击精品计划 → 检查 `isPlanUnlocked(planId)`
2. 已解锁且在 90 天有效期内 → 直接采用
3. 已解锁但已过期 → 提示重新支付
4. 未解锁 → 弹确认窗 → `PointsService.spendPoints()` → 写入解锁记录

**存储结构：**
```
Storage.getSettings()['planUnlockRecords'] = [
  {"planId": "bulk_5day_advanced_01", "unlockTime": 1778000000000, "expireTime": 1785776000000}
]
```
- `expireTime = unlockTime + 90 * 24 * 60 * 60 * 1000`
- `isPlanUnlocked()` 每次检查时做过期清理

### 6.2 价格体系（按难度）

| 难度 | 积分 |
|------|------|
| 入门 (beginner) | 100 |
| 初级 (elementary) | 200 |
| 进阶 (intermediate) | 400 |
| 高级 (advanced) | 800 |

## 7. 页面路由架构

### 7.1 新增路由

| 路由 | 页面 | 导航方式 |
|------|------|----------|
| `/plan-library` | `PlanLibraryHomePage` | 全屏（rootNavigatorKey） |
| `/plan-library/:goal` | `PlanLibraryCategoryPage` | 全屏 |
| `/plan-library/detail/:planId` | `PlanLibraryDetailPage` | 全屏 |

### 7.2 plan_page 三段式布局

```
1. 当前训练计划（1 个 active 计划，进度条 + "继续训练"）
2. 自定义计划 Top 3（排序算法：创建时间 30% + 使用次数 70%）
3. 推荐计划区段（始终展示，3 个推荐 + "查看全部系统计划"入口按钮）
```

### 7.3 页面功能

- **PlanLibraryHomePage**：瀑布流大图卡片展示 5 个目标分类（SliverGrid crossAxisCount=2），每个卡片含 emoji + 目标名 + 计划数 + 精品数
- **PlanLibraryCategoryPage**：目标子页，顶部 Chip 筛选（难度单选、训练类型多选），计划列表卡片含精品标记
- **PlanLibraryDetailPage**：计划详情展示 + 解锁按钮 + "采用此计划"按钮

## 8. 文件清单

### 新建文件
- `lib/data/system_plan_library.dart` — SystemPlanLibrary 加载 + 数据类
- `lib/services/plan_recommendation_service.dart` — 推荐算法
- `lib/services/plan_unlock_service.dart` — 精品解锁
- `lib/pages/plan_library_home_page.dart` — 系统计划库首页
- `lib/pages/plan_library_category_page.dart` — 目标子类页
- `lib/pages/plan_library_detail_page.dart` — 计划详情页
- `assets/data/system_plans/bulk.json` ~ `strength.json` × 5 个 JSON 文件（种子数据，含 D2C 内容）

### 修改文件
- `lib/pages/plan_page.dart` — 三段式布局改造，推荐区段始终展示
- `lib/pages/home_page.dart` — 接收 'plan' 类型 banner
- `lib/services/recommendation_service.dart` — 新增 'plan' 类型 banner
- `lib/pages/questionnaire_page.dart` — 推荐数据源改为从系统计划库获取
- `lib/pages/plan_recommend_page.dart` — 推荐数据源改为从系统计划库获取
- `lib/pages/add_plan_page.dart` — 推荐数据源改为从系统计划库获取
- `lib/router.dart` — 新增 3 条路由
- `pubspec.yaml` — `assets/data/system_plans/` 目录注册

## 9. 边界条件

- **未完成问卷的用户**：推荐算法回退为仅根据 records 推断（无 settings goal 时展示全目标 top 混合）
- **零训练记录的新用户**：返回新手向计划（difficulty=beginner）+ 首页展示引导填写问卷
- **积分不足**：解锁弹窗显示差额，引导用户赚取积分
- **JSON 加载失败**：`load()` 返回空列表，所有 getter 优雅降级（空态提示：数据加载失败）
- **解锁记录数据损坏**：`isPlanUnlocked()` 捕获异常，返回 false（即未解锁）
- **自定义计划不足 3 个**：全部展示，不补位
- **推荐结果不足 3 个**：展示全部可用结果，不凑数
