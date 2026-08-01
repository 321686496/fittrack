# App 八项功能优化设计

- **日期**：2026-08-01
- **范围**：健身卡（日期选择/统计/返回键报错）、动作库（封面图）、对手皮肤（UI 渗透/购买入口）、海报生成（断言报错）、积分模块（获取途径）、成就模块（可获积分）、教学/计划库（搜索页）、系统化课程（扩容）
- **依赖前置**：调研报告已确认全部改造点与文件位置
- **推进方式**：分三阶段一次性规划并实现，使用 subagent 方式分阶段交付

---

## 阶段一：Bug 修复 + UI 打底

### 1.1 健身卡自定义日期选择器（日历网格）+ 卡类型联动到期

**目标**：替换原生 `showDatePicker`，提供贴合 app 主题的日历网格弹层；开卡日期默认今天，卡类型变化时按规则联动到期日。

**新组件**：`fittrack_flutter/lib/widgets/fit_date_picker_sheet.dart`

- 视觉：底部弹层（复用 `FitBottomSheet` 外壳），顶部年月切换 + 左右箭头，中部 7 列日历网格，底部"今天 / 确定"按钮
- 主题：通过 `Theme.of(context).extension<FitTrackColors>()!` 取色，7 套主题自适应；选中日高亮 `accentGlow`，今天描边 `accentSecondary`
- 交互：
  - 月份切换：左右箭头或左右滑动手势
  - 范围外日期（`firstDate` 之前 / `lastDate` 之后）置灰不可选
  - "今天"按钮：跳到本月并选中今天
  - 单击日期：立即选中并高亮，点"确定"返回或双击直接返回
- 入参：`initialDate / firstDate / lastDate / title`，返回 `Future<DateTime?>`

**改造点**：`fittrack_flutter/lib/pages/gym_card_page.dart`

- L277 开卡日期：替换 `showDatePicker` 为 `FitDatePickerSheet.show(...)`
- L311 到期日期：同上
- `cardType` chip 的 `onChanged`（L257-263）增加联动逻辑：
  - 年卡 → 到期日 = 开卡日 + 1 年
  - 季卡 → +3 个月
  - 月卡 → +1 个月
  - 次卡 → 隐藏到期日字段
- 联动规则：到期日为空 或 等于上次自动计算值时自动重算；用户手动改过（标记 `_endDateUserTouched`）则不再覆盖
- 开卡日期默认值改为 `DateTime.now()`（当前无默认）

### 1.2 返回键 `_dependents.isEmpty` 报错修复

**根因**：`_showAddCardSheet`（gym_card_page.dart L191-480）在方法作用域创建控制器，`.whenComplete(disposeControllers)` 与 `showDatePicker` 异步关闭存在时序竞争——控制器被 dispose 后仍被 `_DatePickerDialog` 内部 `AnimatedBuilder` 依赖，触发 `_dependents.isEmpty` 断言。

**修复方案**：

1. 控制器生命周期上移到 `_GymCardPageState`（作为成员变量），随页面 `dispose()` 统一释放
2. `_showAddCardSheet` 不再创建/释放控制器，改用页面级控制器；打开 sheet 时 `clear()` 重置文本
3. 所有 `setState`/`setSheetState` 前加 `if (!mounted) return;` 守卫
4. 改用自定义日期弹层（1.1）后，原生 `showDatePicker` 的竞争点自然消除
5. 审计 sheet 关闭路径（返回键 / 滑动关闭 / 系统回退），确保关闭流程不再触发控制器 dispose

### 1.3 动作库封面图上传 + 默认封面

**新依赖**：`image_picker`（pubspec.yaml 增加）；若 OHOS 不支持则回退 `file_picker` 或自建 MethodChannel，实施时先验证平台支持性。

**表单改造**：`fittrack_flutter/lib/pages/exercise_page.dart` 的 `_AddExerciseSheetState`（L1288-1862）

- 新增状态：`String? _coverImagePath`
- UI：在 `_buildNameField` 上方插入封面选择区
  - 已选：显示 `Image.file` 预览（圆角 12，高 160）
  - 未选：显示默认封面预览（按分类生成的渐变 + emoji）
  - 点击弹出选择：相册 / 拍照 / 使用默认
- 保存：`_onSave`（L1369-1406）在保存 map 中追加 `'image': _coverImagePath`
- 列表/详情：`exercise_page.dart` 网格（L243-249）与详情页（L284-400）支持 `Image.file` 渲染自定义封面

**默认封面**：纯代码绘制，无需额外资源

- 方案：按动作 `category` 映射 `coverEmoji + coverColors`（沿用教学/计划库模式）
- 实现：新增 `fittrack_flutter/lib/widgets/default_exercise_cover.dart`
  - `DefaultExerciseCover({required String category, double? size})`
  - 内部 `CustomPaint` 绘制渐变背景 + 居中 emoji + 右下角分类标签
  - 分类映射表：胸→💪/肩→🤸/背→🏹/腿→🦵/臂→💪/核心→🎯/有氧→🏃/其他→🏋️，每类配一对渐变色
- `Storage.addCustomExercise`（storage.dart L933-948）默认不写 `image` 字段；列表渲染时 `image == null` 则用 `DefaultExerciseCover`

### 1.4 海报 `!debugNeedsPaint` 修复

**根因**：`RenderRepaintBoundary.toImage()` 在 debug 模式下断言 `!debugNeedsPaint`；离屏 Overlay 模式含 `QrImageView` 等异步组件时，固定 30~50ms 等待不可靠，首帧 paint 未完成即触发。

**修复方案**：统一走"等待 paint 完成"安全路径

**改造 `fittrack_flutter/lib/services/poster_generator.dart`**：

- `capture()` 方法增加 `waitForPaint()` 内部逻辑：
  ```
  for (int i = 0; i < 10; i++) {
    if (!boundary.debugNeedsPaint) break;
    await WidgetsBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 30));
  }
  if (boundary.debugNeedsPaint) {
    throw Exception('RepaintBoundary 尚未完成绘制，请重试');
  }
  ```
- 调用方捕获异常 → 提示"海报生成失败，请重试"而非崩溃

**统一调用方**：

- `poster_capture_helper.dart`：等待逻辑改为调用 `PosterGenerator.capture`（已含安全等待），移除自身的固定 50ms 等待
- `share_card_service.dart` L67-70：改为调用 `PosterGenerator.capture`
- `note_poster_page.dart` L73-76：同上
- `tutorial_share_card.dart` L372-375：同上
- `plan_poster_page.dart`：已在可见树中，无需改动

**错误兜底**：`PosterCaptureHelper.captureAndNormal` 的 `onError` 回调统一弹 `FitToast` 提示重试。

---

## 阶段二：新页面

### 2.1 健身卡统计页

**新页面**：`fittrack_flutter/lib/pages/gym_card_stats_page.dart`

**路由**：`/gym-card-stats`，在 `router.dart` 注册

**入口**：`fittrack_flutter/lib/widgets/page_header.dart`

- 新增 `onStatsTap` 回调参数（L7-23）
- 渲染区（L89-121）追加统计 icon（`Icons.bar_chart`）按钮
- `gym_card_page.dart` L756-760 的 `PageHeader` 传入 `onStatsTap: () => context.push('/gym-card-stats')`

**统计内容**（数据源：`Storage.getGymCards()` 全量卡）：

1. **总览卡**：总卡数 / 活跃 / 已过期 / 即将到期（7 天内）4 个 `StatCard`
2. **卡类型分布**：饼图（`fl_chart` `PieChart`），年/季/月/次/其他占比
3. **投入分析**：总投入金额、日均成本（复用 `_calcDailyCost`）、按卡类型分组投入
4. **健身房分布**：按 `gymName` 分组的条形图（`BarChart`），显示每家健身房卡数
5. **时间分布**：开卡月份分布折线/柱状图，到期月份分布
6. **次卡使用率**：总次数 / 已用次数 / 剩余次数，进度条
7. **即将到期提醒列表**：未来 30 天到期的卡列表（卡名 / 健身房 / 到期日 / 剩余天数）

**新依赖**：`fl_chart`（pubspec.yaml 增加）

### 2.2 更多系统化课程

**数据扩容**：`fittrack_flutter/lib/data/course_content.dart` 的 `CourseLibrary`（当前仅 2 个课程）

新增 5 个课程：

| id | 标题 | 目标 | 难度 | 章节数 | 积分价 |
|---|---|---|---|---|---|
| `course_intermediate_shape` | 中级塑形进阶 | shape | intermediate | 5 | 300 |
| `course_strength_basic` | 力量训练基础 | strength | beginner | 4 | 150 |
| `course_keep_health` | 健康保持指南 | keep | beginner | 4 | 150 |
| `course_advanced_bulk` | 高级增肌突破 | bulk | advanced | 6 | 500 |
| `course_hiit_cut` | HIIT 高效减脂 | cut | intermediate | 5 | 300 |

每课程配 `coverEmoji + coverColors`，每章节 4~6 个 `ContentBlock`（沿用富文本块结构），含 `recommendedExerciseIds` 与 `pointsReward`。

### 2.3 教学库搜索页

**新页面**：`fittrack_flutter/lib/pages/tutorial_search_page.dart`

**路由**：`/tutorial-search`

**入口**：

- `tutorial_list_page.dart`（教学中心 Tab）`PageHeader` 加搜索 icon
- `all_tutorials_page.dart`（全部教学页）顶部加搜索入口

**实现**：

- 顶部搜索框（`FitTextField` 风格）+ 取消按钮
- 搜索维度：名称 / 肌群 / 器械 / 难度 / 教练名（模糊匹配）
- 数据源：`TutorialLibrary.basicTutorials + advancedTutorials + topicTutorials + masterTutorials` 全量合并
- 历史搜索：最近 10 条存 `SharedPreferences['tutorialSearchHistory']`
- 空状态：`EmptyState` 提示"未找到匹配的教学"
- 结果列表：复用教学卡片样式（封面 + 标题 + 难度 + 肌群标签）

### 2.4 计划库搜索页

**新页面**：`fittrack_flutter/lib/pages/plan_search_page.dart`

**路由**：`/plan-search`

**入口**：`plan_library_home_page.dart` `PageHeader` 加搜索 icon

**实现**：

- 顶部搜索框 + 筛选 chip（目标 / 难度 / 训练类型，可折叠）
- 搜索维度：名称 / 目标 / 难度 / 训练类型 / 标签 / 适合人群
- 数据源：`SystemPlanLibrary.instance.getByGoal` 全目标合并
- 历史搜索：最近 10 条
- 结果列表：复用计划卡片样式（封面 + 标题 + 目标 + 难度 + 周数）
- 已解锁状态显示：精品计划显示已解锁/积分解锁状态

---

## 阶段三：大功能

### 3.1 对手皮肤渗透 + 购买入口 + 限定皮肤突出

**皮肤主题扩展**：`fittrack_flutter/lib/widgets/opponent/opponent_skin_config.dart`

`OpponentSkinConfig` 增加 `cardTheme` 字段：

```dart
class SkinCardTheme {
  final Color borderColor;
  final Color glowColor;
  final Color badgeColor;
  final String badgeEmoji;
  final List<Color> gradientColors;
  final bool showShimmer;
}
```

4 款皮肤的 `cardTheme`：

- `skinBeginner`：柔和绿边框 + 🐣 角标 + 浅绿渐变
- `skinIronWarrior`：金属灰边框 + 🤖 角标 + 钢蓝渐变 + 微光
- `skinCyberNinja`：紫色霓虹边框 + 🥷 角标 + 紫黑渐变 + 闪烁
- `skinAmbassador`：金色边框 + 👑 角标 + 金黑渐变 + 强光闪烁（限定款专属）

**渗透点改造**：

1. **首页 `VirtualOpponentCard`**（`fittrack_flutter/lib/widgets/virtual_opponent_card.dart` L164-315）：
   - 卡片外层包裹 `Container` + `BoxDecoration`，边框色取 `cardTheme.borderColor`
   - 顶部加角标 emoji + 限定款闪烁效果（`AnimatedOpacity`）
   - 进度条颜色用 `cardTheme.glowColor`
   - 背景 `gradientColors` 渐变

2. **对手详情页**（`fittrack_flutter/lib/pages/opponent_detail_page.dart`）：
   - `_buildHeaderCard`（L75-121）：背景渐变 + 光晕
   - `_buildWeeklyStatsCard`（L123-142）：数据卡边框用皮肤色
   - `_buildSkinCard`（L175-269）：当前皮肤卡加 `showShimmer` 效果

3. **训练结束 PK 卡**（`fittrack_flutter/lib/pages/training_page.dart` L1557-1680 `_buildOpponentPKCard`）：
   - 对手侧卡片应用皮肤边框 + 角标
   - 招式名称用皮肤色高亮

**购买入口（双入口）**：

1. **对手详情页皮肤区**：保留并优化（L175-269），每个未解锁皮肤显示价格 + "积分购买"按钮，点击调用 `VirtualGoodsStore.unlock(goodId)`
2. **积分中心入口**：`fittrack_flutter/lib/pages/points_detail_page.dart` 新增"对手皮肤"入口卡 → 跳转 `/opponent-detail` 锚定皮肤区

**ambassador 限定皮肤突出**：

- 邀请页（`invitation_page.dart` L392-487 奖励规则区）：
  - 5 人档奖励项增加 ambassador 皮肤预览（96×96 `OpponentRenderer`）
  - 显示解锁进度条（当前邀请人数 / 5）
  - "立即邀请解锁"按钮
- 详情页皮肤区：ambassador 卡片加"限定"角标 + 金色光晕动画

### 3.2 积分获取途径重构 + 成就可获积分标记

#### 3.2.1 每日训练得积分

**改造点**：`fittrack_flutter/lib/pages/training_page.dart` 训练完成逻辑（L560-570 附近）

- 训练记录保存成功后调用：
  ```dart
  await PointsService.instance.addDailyTrainingPoints();
  ```
- `PointsService`（`fittrack_flutter/lib/services/points_service.dart`）新增方法：
  ```dart
  Future<bool> addDailyTrainingPoints() async {
    final today = DateTime.now();
    final lastDate = Storage.settings['lastTrainingPointsDate'];
    final todayStr = '${today.year}-${today.month}-${today.day}';
    if (lastDate == todayStr) return false;
    await addPoints(trainingPoints, PointsSource.training);
    Storage.settings['lastTrainingPointsDate'] = todayStr;
    await Storage.saveSettings();
    return true;
  }
  ```
- `trainingPoints` 常量已存在（L17，值 2），直接启用
- `storage.dart` settings 默认值（L440-470）增加 `'lastTrainingPointsDate': ''`

#### 3.2.2 成就可获积分

**模型扩展**：`fittrack_flutter/lib/services/achievement_service.dart` L6-24

```dart
class Achievement {
  final String id;
  final String category;
  final String title;
  final String description;
  final String icon;
  final bool unlocked;
  final int? unlockedAt;
  final int pointsReward;      // 新增：解锁可获积分，0 表示纯荣誉
  final bool canEarnPoints;    // 新增：是否可获积分
}
```

**分类规则**（仅 `weight` 类不可获积分）：

| category | canEarnPoints | 积分阶梯 |
|---|---|---|
| streak | true | 7天=20 / 30天=50 / 100天=100 / 365天=200 |
| weight | **false** | 0（纯荣誉） |
| duration | true | 24h=30 / 100h=80 / 500h=200 |
| month | true | 3月=50 / 6月=100 / 12月=200 |
| explore | true | 15=30 / 20=60 / 25=100 |
| plan | true | 首个计划=50 |
| share | true | 首次=20 / 3次=40 / 10次=80 |

**解锁发放**：`checkAndUnlock`（L109-188）解锁时：

```dart
if (achievement.canEarnPoints && achievement.pointsReward > 0) {
  await PointsService.instance.addPoints(
    achievement.pointsReward,
    PointsSource.other,
  );
}
```

**UI 标记**：`fittrack_flutter/lib/pages/achievement_page.dart`

- 可获积分成就：徽章右下角显示积分图标 + 数值（`BadgeWidget` purple 变体）
- weight 类：显示"纯荣誉"标识（`BadgeWidget` info 变体，文案"纯荣誉"）
- `honor_wall_page.dart` 同步标记

**积分页文案对齐**：`points_detail_page.dart` L319 "成就解锁获得变量积分"改为分类说明：

- "成就解锁获得积分（部分成就为纯荣誉）"

#### 3.2.3 补全 share / month 成就解锁逻辑

**share 类**（`share_first / share_3 / share_10`）：

- `ShareCardService.generateShareCard` 成功后调用 `AchievementService.instance.recordShare()`
- `PosterCaptureHelper.captureAndNormal` 成功后同样调用
- 新增 `AchievementService.recordShare()`：累计分享次数，达 1/3/10 解锁

**month 类**（`month_3 / month_6 / month_12`）：

- `checkAndUnlock` 增加月份判定：统计 `records` 中不同 `YYYY-MM` 的数量
- ≥3 / ≥6 / ≥12 分别解锁

#### 3.2.4 数据迁移

`fittrack_flutter/lib/data/database_helper.dart` SQLite schema 升级 v2→v3：

- `achievements` 表增加 `pointsReward INTEGER NOT NULL DEFAULT 0` 与 `canEarnPoints INTEGER NOT NULL DEFAULT 0`
- 旧记录回填：按 category 判定，`weight` 类 `canEarnPoints=0`，其余 `canEarnPoints=1` 并按阶梯回填 `pointsReward`

---

## 跨阶段依赖与风险

### 新依赖

- `image_picker`：动作库封面图上传；OHOS 适配性需验证，不支持则回退 `file_picker` 或 MethodChannel
- `fl_chart`：健身卡统计页图表；纯 Flutter 实现，跨平台兼容

### 数据迁移

- SQLite v2→v3：`achievements` 表加字段，旧记录回填默认值
- `Storage.settings` 新增字段：`lastTrainingPointsDate`

### 回归测试点

- 健身卡表单：开卡/编辑/删除/返回键
- 海报分享：邀请/笔记/计划/健身卡/教学/训练记录 6 类海报
- 训练完成流程：积分发放 + 成就解锁
- 对手渲染：4 款皮肤在首页/详情/训练结束 3 处显示
- 课程学习：章节积分发放

---

## 实施顺序

1. **阶段一**（subagent 并行）：①日期组件 + 联动 → ②返回键修复 → ③封面图上传 → ⑥海报修复
2. **阶段二**（subagent 并行）：④统计页 → ⑧课程扩容 + 搜索页
3. **阶段三**（subagent 并行）：⑤皮肤渗透 → ⑦积分重构 + 成就标记

每阶段完成后做回归验证，确保不破坏现有功能。
