# App 八项功能优化实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 一次性完成健身卡日期组件/统计页/返回键修复、动作库封面图、对手皮肤 UI 渗透/购买入口、海报断言修复、积分获取途径重构、成就可获积分标记、系统化课程扩容、教学/计划库搜索页共 8 项优化。

**Architecture:** 分三阶段顺序推进。阶段一为 Bug 修复 + UI 打底（4 项，可并行）；阶段二为新页面（2 项，可并行）；阶段三为跨模块大功能（2 项，可并行）。每阶段完成后做回归验证。

**Tech Stack:** Flutter (Dart >=2.19.6)、go_router、sqflite、shared_preferences、新增 `image_picker` + `fl_chart`；主题系统 `FitTrackColors`；通用组件 `common_widgets.dart`。

**Spec:** `docs/superpowers/specs/2026-08-01-app-optimization-design.md`

## Global Constraints

- 项目根：`e:\Project\health_project\health_training`，Flutter 源码在 `fittrack_flutter/`
- 主题色一律通过 `Theme.of(context).extension<FitTrackColors>()!` 获取，不硬编码颜色
- 通用组件优先复用 `common_widgets.dart`（`FitBottomSheet`/`FitTextField`/`FitChipSelector`/`FitToast`/`CardWidget`/`StatCard`/`EmptyState`/`BadgeWidget`）
- 圆角约定：卡片 12~14，输入框 10，按钮 10~14，底部弹层顶部 20
- 数据迁移：SQLite v2→v3 需在 `database_helper.dart` 升级回调处理
- 新依赖先验证 OHOS 适配性，不支持则回退
- 不创建无关文档文件

---

## 阶段一：Bug 修复 + UI 打底

### Task 1.1: 健身卡自定义日期选择器（日历网格）

**Files:**
- Create: `fittrack_flutter/lib/widgets/fit_date_picker_sheet.dart`
- Modify: `fittrack_flutter/lib/pages/gym_card_page.dart`（L277、L311 两处 `showDatePicker` 调用；L257-263 卡类型联动；L210 开卡日期默认值）

**Interfaces:**
- Produces: `FitDatePickerSheet.show(BuildContext context, {required DateTime initialDate, DateTime? firstDate, DateTime? lastDate, String? title}) → Future<DateTime?>`

**实现要点：**

- [ ] **Step 1: 创建 `FitDatePickerSheet` 组件**

```dart
// fittrack_flutter/lib/widgets/fit_date_picker_sheet.dart
class FitDatePickerSheet extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? title;
  const FitDatePickerSheet({
    super.key,
    required this.initialDate,
    this.firstDate,
    this.lastDate,
    this.title,
  });
  static Future<DateTime?> show(BuildContext context, {required DateTime initialDate, DateTime? firstDate, DateTime? lastDate, String? title}) {
    return FitBottomSheet.show<DateTime>(
      context: context,
      maxHeightRatio: 0.6,
      builder: (ctx) => FitDatePickerSheet(initialDate: initialDate, firstDate: firstDate, lastDate: lastDate, title: title),
    );
  }
  @override
  State<FitDatePickerSheet> createState() => _FitDatePickerSheetState();
}
```

- [ ] **Step 2: 实现日历网格 state**

State 持有 `DateTime _displayMonth`（当前显示月份，1 号）与 `DateTime? _selected`。
- `_buildHeader`：年月文本 + 左右箭头（越界禁用）
- `_buildWeekdayRow`：日/一/二/三/四/五/六 7 列
- `_buildDayGrid`：计算本月首日 weekday，前面填空；遍历本月天数生成 7 列网格
  - 范围外（firstDate 之前 / lastDate 之后）：置灰 `textMuted`，`onTap` 无效
  - 今天：描边 `accentSecondary`
  - 选中：填充 `accentGlow` 圆形背景，文字白色
  - 普通日：`textPrimary`
- 底部 Row：左侧"今天"按钮（跳到本月并选今天），右侧"确定"按钮（返回 `_selected`）

- [ ] **Step 3: 替换 `gym_card_page.dart` 日期调用**

开卡日期（L277 附近）：
```dart
final picked = await FitDatePickerSheet.show(
  ctx,
  initialDate: startDate != null ? DateTime.fromMillisecondsSinceEpoch(startDate!) : DateTime.now(),
  firstDate: DateTime(2020),
  lastDate: DateTime(2035),
  title: '选择开卡日期',
);
if (picked != null) {
  setSheetState(() {
    startDate = picked.millisecondsSinceEpoch;
    _autoCalcEndDate(); // 联动重算
  });
}
```
到期日期（L311 附近）同理，`title: '选择到期日期'`。

- [ ] **Step 4: 实现卡类型联动到期日**

在 `_GymCardPageState` 增加 `bool _endDateUserTouched = false;`
卡类型 chip `onChanged`：
```dart
onChanged: (v) {
  setSheetState(() {
    cardType = v;
    _autoCalcEndDate();
  });
},
```
新增方法：
```dart
void _autoCalcEndDate() {
  if (cardType == '次卡' || _endDateUserTouched || startDate == null) return;
  final start = DateTime.fromMillisecondsSinceEpoch(startDate!);
  DateTime end;
  switch (cardType) {
    case '年卡': end = DateTime(start.year + 1, start.month, start.day); break;
    case '季卡': end = DateTime(start.year, start.month + 3, start.day); break;
    case '月卡': end = DateTime(start.year, start.month + 1, start.day); break;
    default: return;
  }
  endDate = end.millisecondsSinceEpoch;
}
```
到期日期用户选择后设 `_endDateUserTouched = true`。
开卡日期默认值：`startDate` 初始为 `DateTime.now().millisecondsSinceEpoch`（替换当前 L210 的 null）。

- [ ] **Step 5: 验证**

手动验证：打开添加健身卡 → 开卡日期默认今天；选年卡 → 到期日自动+1年；手动改到期日后再切卡类型不覆盖；日期弹层为日历网格风格；7 套主题切换颜色正确。

- [ ] **Step 6: Commit**

```bash
git add fittrack_flutter/lib/widgets/fit_date_picker_sheet.dart fittrack_flutter/lib/pages/gym_card_page.dart
git commit -m "feat: 健身卡自定义日历日期选择器 + 卡类型联动到期日"
```

---

### Task 1.2: 修复返回键 `_dependents.isEmpty` 报错

**Files:**
- Modify: `fittrack_flutter/lib/pages/gym_card_page.dart`（`_GymCardPageState` 与 `_showAddCardSheet` L191-480）

**实现要点：**

- [ ] **Step 1: 控制器上移到 State**

在 `_GymCardPageState` 增加成员控制器：
```dart
late final TextEditingController _nameCtrl;
late final TextEditingController _gymNameCtrl;
late final TextEditingController _priceCtrl;
late final TextEditingController _phoneCtrl;
late final TextEditingController _remarkCtrl;
late final TextEditingController _totalCountCtrl;
late final TextEditingController _remainingCountCtrl;

@override
void initState() {
  super.initState();
  _nameCtrl = TextEditingController();
  _gymNameCtrl = TextEditingController();
  _priceCtrl = TextEditingController();
  _phoneCtrl = TextEditingController();
  _remarkCtrl = TextEditingController();
  _totalCountCtrl = TextEditingController();
  _remainingCountCtrl = TextEditingController();
}

@override
void dispose() {
  _nameCtrl.dispose();
  _gymNameCtrl.dispose();
  _priceCtrl.dispose();
  _phoneCtrl.dispose();
  _remarkCtrl.dispose();
  _totalCountCtrl.dispose();
  _remainingCountCtrl.dispose();
  super.dispose();
}
```

- [ ] **Step 2: 改造 `_showAddCardSheet`**

- 删除方法内 `TextEditingController` 创建（L195-208）
- 删除 `disposeControllers` 函数与 `.whenComplete(disposeControllers)`（L479）
- 打开 sheet 时清空控制器：`_nameCtrl.clear(); ...`（编辑模式则填入 `existingCard` 值）
- 所有 `setState`/`setSheetState` 前加 `if (!mounted) return;`
- 保留 `FitBottomSheet.show` 的 `.whenComplete` 仅做状态清理（如 `_endDateUserTouched = false`）

- [ ] **Step 3: 验证**

打开添加健身卡 → 按手机返回键 → 无报错；打开后选日期弹层中按返回键 → 无报错；编辑卡同样无报错。

- [ ] **Step 4: Commit**

```bash
git add fittrack_flutter/lib/pages/gym_card_page.dart
git commit -m "fix: 健身卡表单返回键 _dependents.isEmpty 报错"
```

---

### Task 1.3: 动作库封面图上传 + 默认封面

**Files:**
- Modify: `fittrack_flutter/pubspec.yaml`（新增 `image_picker`）
- Create: `fittrack_flutter/lib/widgets/default_exercise_cover.dart`
- Modify: `fittrack_flutter/lib/pages/exercise_page.dart`（`_AddExerciseSheetState` L1288-1862；网格 L243-249；详情 L284-400）
- Modify: `fittrack_flutter/lib/data/storage.dart`（`addCustomExercise` L933-948 保留 image 字段）

**实现要点：**

- [ ] **Step 1: 添加依赖并验证平台**

`pubspec.yaml` dependencies 增加 `image_picker: ^1.0.4`。
运行 `flutter pub get`。验证 OHOS：若编译失败或运行时报平台不支持的 channel，回退方案——改用 `file_picker` 或自建 MethodChannel（记录回退决策）。实施 subagent 先在 pubspec 加依赖并跑 `flutter pub get`，若 OHOS 报错则切换方案。

- [ ] **Step 2: 创建默认封面组件**

```dart
// fittrack_flutter/lib/widgets/default_exercise_cover.dart
import 'package:flutter/material.dart';
import '../themes/app_themes.dart';

class DefaultExerciseCover extends StatelessWidget {
  final String category;
  final double? size;
  const DefaultExerciseCover({super.key, required this.category, this.size});

  static const _map = <String, ({String emoji, List<Color> colors})>{
    '胸': (emoji: '💪', colors: [Color(0xFFef4444), Color(0xFFf97316)]),
    '肩': (emoji: '🤸', colors: [Color(0xFF3b82f6), Color(0xFF06b6d4)]),
    '背': (emoji: '🏹', colors: [Color(0xFF8b5cf6), Color(0xFF6366f1)]),
    '腿': (emoji: '🦵', colors: [Color(0xFF10b981), Color(0xFF059669)]),
    '臂': (emoji: '💪', colors: [Color(0xFFf59e0b), Color(0xFFef4444)]),
    '核心': (emoji: '🎯', colors: [Color(0xFFec4899), Color(0xFFf43f5e)]),
    '有氧': (emoji: '🏃', colors: [Color(0xFF06b6d4), Color(0xFF3b82f6)]),
  };
  static const _fallback = (emoji: '🏋️', colors: [Color(0xFF64748b), Color(0xFF475569)]);

  @override
  Widget build(BuildContext context) {
    final cfg = _map[category] ?? _fallback;
    return SizedBox(
      width: size, height: size,
      child: CustomPaint(
        painter: _CoverPainter(cfg.colors, cfg.emoji),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CoverPainter extends CustomPainter {
  final List<Color> colors;
  final String emoji;
  _CoverPainter(this.colors, this.emoji);
  @override
  void paint(Canvas canvas, Size size) {
    // 对角渐变背景
    final rect = Offset.zero & size;
    final paint = Paint()..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors).createShader(rect);
    canvas.drawRect(rect, paint);
    // 居中 emoji（用 TextPainter）
    final tp = TextPainter(text: TextSpan(text: emoji, style: TextStyle(fontSize: size.width * 0.4)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
  }
  @override
  bool shouldRepaint(covariant _CoverPainter old) => old.colors != colors || old.emoji != emoji;
}
```

- [ ] **Step 3: 表单增加封面图选择**

在 `_AddExerciseSheetState`（L1288-1335 状态区）增加：
```dart
String? _coverImagePath;
```
在 `build` 表单 Column 中（L1422-1434 之间，`_buildNameField` 之前）插入封面选择区：
```dart
Widget _buildCoverPicker(StateSetter setSheetState) {
  return GestureDetector(
    onTap: () => _pickCover(setSheetState),
    child: Container(
      height: 160,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Theme.of(context).extension<FitTrackColors>()!.bgElevated),
      clipBehavior: Clip.antiAlias,
      child: _coverImagePath != null
        ? Image.file(File(_coverImagePath!), fit: BoxFit.cover, width: double.infinity, height: 160)
        : Stack(children: [
            DefaultExerciseCover(category: _selectedCategory, size: 160),
            Positioned(bottom: 8, right: 8, child: Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)), child: Text('点击选择封面', style: TextStyle(color: Colors.white, fontSize: 12)))),
          ]),
    ),
  );
}
```
新增 `_pickCover`：
```dart
Future<void> _pickCover(StateSetter setSheetState) async {
  // 弹选择：相册/拍照/使用默认
  final action = await showModalBottomSheet<String>(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
    ListTile(leading: Icon(Icons.photo), title: Text('从相册'), onTap: () => Navigator.pop(ctx, 'gallery')),
    ListTile(leading: Icon(Icons.camera_alt), title: Text('拍照'), onTap: () => Navigator.pop(ctx, 'camera')),
    ListTile(leading: Icon(Icons.image), title: Text('使用默认封面'), onTap: () => Navigator.pop(ctx, 'default')),
  ])));
  if (action == null) return;
  if (action == 'default') { setSheetState(() => _coverImagePath = null); return; }
  final picker = ImagePicker();
  final xfile = action == 'gallery' ? await picker.pickImage(source: ImageSource.gallery) : await picker.pickImage(source: ImageSource.camera);
  if (xfile != null) setSheetState(() => _coverImagePath = xfile.path);
}
```

- [ ] **Step 4: 保存逻辑追加 image 字段**

`_onSave`（L1369-1406）保存 map 追加：
```dart
if (_coverImagePath != null) data['image'] = _coverImagePath;
```
`Storage.addCustomExercise`（storage.dart L933-948）无需改动——它已是泛型 map 写入，自动保留 image 字段。

- [ ] **Step 5: 列表/详情渲染自定义封面**

网格（L243-249）：判断 `ex['image']` 是否为自定义路径（非 `assets/` 开头）：
```dart
ex['image'] != null && !ex['image'].toString().startsWith('assets/')
  ? Image.file(File(ex['image']), fit: BoxFit.cover)
  : (ex['image'] != null
      ? Image.asset(ex['image'], fit: BoxFit.cover)
      : DefaultExerciseCover(category: ex['category'] ?? '其他', size: 190))
```
详情页 hero 图（L284-400）同理。

- [ ] **Step 6: 验证**

添加动作 → 不选封面 → 列表显示默认封面（按分类）；选相册图 → 列表显示该图；拍照 → 显示该图；编辑动作 → 封面正常。

- [ ] **Step 7: Commit**

```bash
git add fittrack_flutter/pubspec.yaml fittrack_flutter/lib/widgets/default_exercise_cover.dart fittrack_flutter/lib/pages/exercise_page.dart
git commit -m "feat: 动作库封面图上传 + 默认封面"
```

---

### Task 1.4: 修复海报 `!debugNeedsPaint` 报错

**Files:**
- Modify: `fittrack_flutter/lib/services/poster_generator.dart`（`capture` 方法 L28-57）
- Modify: `fittrack_flutter/lib/widgets/poster_capture_helper.dart`（等待逻辑 L115-118）
- Modify: `fittrack_flutter/lib/services/share_card_service.dart`（L67-70、L76）
- Modify: `fittrack_flutter/lib/pages/note_poster_page.dart`（L73-76）
- Modify: `fittrack_flutter/lib/widgets/tutorial_share_card.dart`（L372-375）

**实现要点：**

- [ ] **Step 1: 改造 `PosterGenerator.capture` 增加 paint 等待**

```dart
static Future<String> capture(GlobalKey boundaryKey, {double pixelRatio = 2.0, String fileNamePrefix = 'fittrack_poster'}) async {
  final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  // 等待 paint 完成（最多 10 次 × 30ms）
  for (int i = 0; i < 10; i++) {
    if (!boundary.debugNeedsPaint) break;
    await WidgetsBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 30));
  }
  if (boundary.debugNeedsPaint) {
    throw Exception('RepaintBoundary 尚未完成绘制，请重试');
  }
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  // ... 原有 toByteData + 写文件逻辑 ...
}
```

- [ ] **Step 2: 统一各调用方移除自身固定等待**

`poster_capture_helper.dart` L115-118：删除固定 50ms 等待，保留 `overlay.insert(entry)` 后直接调用 `PosterGenerator.capture`（capture 内已含等待）。
`share_card_service.dart` L67-70：删除固定 30ms 等待，L76 改为调用 `PosterGenerator.capture(boundaryKey)` 而非直接 `boundary.toImage`。
`note_poster_page.dart` L73-76、`tutorial_share_card.dart` L372-375：同上，删除自身等待，依赖 `PosterGenerator.capture`。

- [ ] **Step 3: 错误兜底**

`PosterCaptureHelper.captureAndNormal` 的 `onError` 回调统一弹 `FitToast`：
```dart
onError: (e) {
  FitToast.show(context, message: '海报生成失败，请重试');
},
```

- [ ] **Step 4: 验证**

邀请页"立即分享" → 海报正常生成；训练记录分享 → 正常；教学动作分享 → 正常；笔记海报 → 正常；计划海报 → 正常；健身卡海报 → 正常。无 `!debugNeedsPaint` 报错。

- [ ] **Step 5: Commit**

```bash
git add fittrack_flutter/lib/services/poster_generator.dart fittrack_flutter/lib/widgets/poster_capture_helper.dart fittrack_flutter/lib/services/share_card_service.dart fittrack_flutter/lib/pages/note_poster_page.dart fittrack_flutter/lib/widgets/tutorial_share_card.dart
git commit -m "fix: 海报生成 !debugNeedsPaint 断言报错"
```

---

## 阶段二：新页面

### Task 2.1: 健身卡统计页

**Files:**
- Modify: `fittrack_flutter/pubspec.yaml`（新增 `fl_chart`）
- Modify: `fittrack_flutter/lib/widgets/page_header.dart`（新增 `onStatsTap` 回调与渲染）
- Modify: `fittrack_flutter/lib/pages/gym_card_page.dart`（L756-760 传入 `onStatsTap`）
- Create: `fittrack_flutter/lib/pages/gym_card_stats_page.dart`
- Modify: `fittrack_flutter/lib/router.dart`（注册 `/gym-card-stats`）

**实现要点：**

- [ ] **Step 1: 添加 fl_chart 依赖**

`pubspec.yaml` 增加 `fl_chart: ^0.66.0`，`flutter pub get`。

- [ ] **Step 2: PageHeader 增加 stats 入口**

`page_header.dart` L7-23 增加参数 `VoidCallback? onStatsTap;`，渲染区（L89-121）追加：
```dart
if (onStatsTap != null)
  IconButton(icon: const Icon(Icons.bar_chart), onPressed: onStatsTap, tooltip: '统计'),
```

- [ ] **Step 3: gym_card_page 传入入口**

L756-760 的 `PageHeader` 增加 `onStatsTap: () => context.push('/gym-card-stats')`。

- [ ] **Step 4: 创建统计页**

`gym_card_stats_page.dart`：
- `_loadStats()`：`Storage.getGymCards()` 全量卡
- 总览卡：4 个 `StatCard`（总卡数 / 活跃 / 已过期 / 即将到期 7 天内），复用 `gym_card_page` 的 `_getCardStatus`
- 卡类型分布：`PieChart`（年/季/月/次/其他占比）
- 投入分析：总金额、日均成本（复用 `_calcDailyCost`）、按类型分组金额
- 健身房分布：`BarChart`（按 `gymName` 分组卡数）
- 时间分布：开卡月份、到期月份柱状图
- 次卡使用率：总次数/已用/剩余，`ProgressBar`
- 即将到期列表：未来 30 天到期的卡 `ListView`
- 主题色取 `FitTrackColors`，图表配色用 `accentGlow/accentSecondary/successColor/warningColor/infoColor/purpleColor`

- [ ] **Step 5: 注册路由**

`router.dart` 增加：
```dart
GoRoute(path: '/gym-card-stats', builder: (ctx, state) => const GymCardStatsPage()),
```

- [ ] **Step 6: 验证**

健身卡页右上角统计 icon → 进入统计页；7 套主题下图表配色正确；空数据状态正常显示。

- [ ] **Step 7: Commit**

```bash
git add fittrack_flutter/pubspec.yaml fittrack_flutter/lib/widgets/page_header.dart fittrack_flutter/lib/pages/gym_card_page.dart fittrack_flutter/lib/pages/gym_card_stats_page.dart fittrack_flutter/lib/router.dart
git commit -m "feat: 健身卡统计页"
```

---

### Task 2.2: 系统化课程扩容 + 教学库/计划库搜索页

**Files:**
- Modify: `fittrack_flutter/lib/data/course_content.dart`（`CourseLibrary` 新增 5 课程）
- Create: `fittrack_flutter/lib/pages/tutorial_search_page.dart`
- Modify: `fittrack_flutter/lib/pages/tutorial_list_page.dart`（搜索入口）
- Modify: `fittrack_flutter/lib/pages/all_tutorials_page.dart`（搜索入口）
- Create: `fittrack_flutter/lib/pages/plan_search_page.dart`
- Modify: `fittrack_flutter/lib/pages/plan_library_home_page.dart`（搜索入口）
- Modify: `fittrack_flutter/lib/router.dart`（注册 `/tutorial-search` `/plan-search`）

**实现要点：**

- [ ] **Step 1: 新增 5 个系统化课程**

`course_content.dart` 的 `CourseLibrary` 新增 5 个 `Course`（每个 4~6 章，每章 4~6 个 `ContentBlock`）：

| id | 标题 | 目标 | 难度 | 章节数 | 积分价 |
|---|---|---|---|---|---|
| course_intermediate_shape | 中级塑形进阶 | shape | intermediate | 5 | 300 |
| course_strength_basic | 力量训练基础 | strength | beginner | 4 | 150 |
| course_keep_health | 健康保持指南 | keep | beginner | 4 | 150 |
| course_advanced_bulk | 高级增肌突破 | bulk | advanced | 6 | 500 |
| course_hiit_cut | HIIT 高效减脂 | cut | intermediate | 5 | 300 |

每课程配 `coverEmoji + coverColors`，每章 `pointsReward: 10`，含 `recommendedExerciseIds`（从 `MockData.exercises` 取）。

- [ ] **Step 2: 创建教学库搜索页**

`tutorial_search_page.dart`：
- 顶部 `FitTextField` 搜索框 + 取消按钮，autofocus
- 搜索维度：名称/肌群/器械/难度/教练名（模糊匹配，`toLowerCase().contains`）
- 数据源：`[...TutorialLibrary.basicTutorials, ...advancedTutorials, ...topicTutorials, ...masterTutorials]`
- 历史搜索：`SharedPreferences['tutorialSearchHistory']`，最近 10 条，点击直接搜
- 结果列表：复用教学卡片样式（封面渐变 + emoji + 标题 + 难度 chip + 肌群标签）
- 空状态：`EmptyState`
- 进入详情：`context.push('/tutorial/${tutorial.id}')`

- [ ] **Step 3: 教学库加搜索入口**

`tutorial_list_page.dart` 的 `PageHeader` 加 `onStatsTap` 改为搜索 icon：实际用 `PageHeader` 的 `onBellTap` 或新增 `onSearchTap`（复用 `onStatsTap` 参数名或新增）。最简方案：在 `PageHeader` 已有的右侧 icon 槽位中，教学中心页传 `onBellTap: () => context.push('/tutorial-search')` 并把铃铛换搜索图标——更优是 `PageHeader` 新增 `onSearchTap` 与搜索图标。
决定：`PageHeader` 新增 `onSearchTap` 参数与 `Icons.search` 渲染（与 `onStatsTap` 同模式）。
`tutorial_list_page.dart` 与 `all_tutorials_page.dart` 的 `PageHeader` 传 `onSearchTap`。

- [ ] **Step 4: 创建计划库搜索页**

`plan_search_page.dart`：
- 顶部搜索框 + 可折叠筛选 chip（目标/难度/训练类型）
- 搜索维度：名称/目标/难度/训练类型/标签/适合人群
- 数据源：5 个目标 `getByGoal` 合并全量
- 历史搜索：`SharedPreferences['planSearchHistory']`
- 结果列表：复用计划卡片样式，显示已解锁状态（`PlanUnlockService.instance.isUnlocked(plan.id)`）

- [ ] **Step 5: 计划库加搜索入口**

`plan_library_home_page.dart` 的 `PageHeader` 传 `onSearchTap: () => context.push('/plan-search')`。

- [ ] **Step 6: 注册路由**

```dart
GoRoute(path: '/tutorial-search', builder: (ctx, state) => const TutorialSearchPage()),
GoRoute(path: '/plan-search', builder: (ctx, state) => const PlanSearchPage()),
```

- [ ] **Step 7: 验证**

教学中心搜索 icon → 搜索页；输入关键词 → 结果正确；历史搜索；空状态。计划库同理。系统化课程列表显示 7 个课程。

- [ ] **Step 8: Commit**

```bash
git add fittrack_flutter/lib/data/course_content.dart fittrack_flutter/lib/pages/tutorial_search_page.dart fittrack_flutter/lib/pages/plan_search_page.dart fittrack_flutter/lib/pages/tutorial_list_page.dart fittrack_flutter/lib/pages/all_tutorials_page.dart fittrack_flutter/lib/pages/plan_library_home_page.dart fittrack_flutter/lib/widgets/page_header.dart fittrack_flutter/lib/router.dart
git commit -m "feat: 系统化课程扩容 + 教学库/计划库搜索页"
```

---

## 阶段三：大功能

### Task 3.1: 对手皮肤 UI 渗透 + 购买入口 + 限定皮肤突出

**Files:**
- Modify: `fittrack_flutter/lib/widgets/opponent/opponent_skin_config.dart`（新增 `SkinCardTheme` 与 4 款皮肤配置）
- Modify: `fittrack_flutter/lib/widgets/virtual_opponent_card.dart`（首页 PK 卡 L164-315）
- Modify: `fittrack_flutter/lib/pages/opponent_detail_page.dart`（详情页 L75-269）
- Modify: `fittrack_flutter/lib/pages/training_page.dart`（训练结束 PK 卡 L1557-1680）
- Modify: `fittrack_flutter/lib/pages/invitation_page.dart`（L392-487 ambassador 突出）
- Modify: `fittrack_flutter/lib/pages/points_detail_page.dart`（新增对手皮肤入口卡）

**实现要点：**

- [ ] **Step 1: 扩展皮肤配置**

`opponent_skin_config.dart` 新增：
```dart
class SkinCardTheme {
  final Color borderColor;
  final Color glowColor;
  final Color badgeColor;
  final String badgeEmoji;
  final List<Color> gradientColors;
  final bool showShimmer;
  const SkinCardTheme({required this.borderColor, required this.glowColor, required this.badgeColor, required this.badgeEmoji, required this.gradientColors, this.showShimmer = false});
}
```
`OpponentSkinConfig` 增加 `final SkinCardTheme cardTheme;` 字段，4 款皮肤各配一套：
- beginner：绿边框 `0xFF10b981` + 🐣 + 浅绿渐变
- iron_warrior：钢灰 `0xFF64748b` + 🤖 + 钢蓝渐变 + 微光
- cyber_ninja：紫 `0xFFd946ef` + 🥷 + 紫黑渐变 + 闪烁
- ambassador：金 `0xFFf59e0b` + 👑 + 金黑渐变 + 强光闪烁

- [ ] **Step 2: 首页 PK 卡渗透**

`virtual_opponent_card.dart` build 方法：获取当前皮肤 `OpponentSkinConfig.byId(opponent.appliedSkinId)`，卡片区用 `Container` + `BoxDecoration`：
```dart
decoration: BoxDecoration(
  gradient: LinearGradient(colors: skin.cardTheme.gradientColors),
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: skin.cardTheme.borderColor, width: 1.5),
  boxShadow: [BoxShadow(color: skin.cardTheme.glowColor.withOpacity(0.3), blurRadius: 12)],
),
```
右上角 `Positioned` 放角标 emoji；`showShimmer` 时用 `AnimatedOpacity` 做呼吸光效。进度条颜色用 `cardTheme.glowColor`。

- [ ] **Step 3: 对手详情页渗透**

`opponent_detail_page.dart`：
- `_buildHeaderCard`：背景渐变 + 光晕
- `_buildWeeklyStatsCard`：3 个数据卡边框用皮肤色
- `_buildSkinCard`：当前皮肤卡 `showShimmer` 闪烁；ambassador 加"限定"角标 + 金色光晕

- [ ] **Step 4: 训练结束 PK 卡渗透**

`training_page.dart` `_buildOpponentPKCard`：对手侧卡片应用皮肤边框 + 角标，招式名用皮肤色。

- [ ] **Step 5: 积分中心入口**

`points_detail_page.dart` 新增"对手皮肤"入口卡（`CardWidget` + 图标），点击 `context.push('/opponent-detail')`。

- [ ] **Step 6: 邀请页 ambassador 突出**

`invitation_page.dart` L392-487 奖励规则区，5 人档：
- 增加 96×96 `OpponentRenderer(skinId: 'skin_ambassador')` 预览
- 显示解锁进度条（当前邀请人数 / 5）
- "立即邀请解锁"按钮 → 滚动到顶部邀请码区或跳分享

- [ ] **Step 7: 购买入口优化**

`opponent_detail_page.dart` `_buildSkinCard`：未解锁皮肤显示价格 + "积分购买"按钮，点击调用 `VirtualGoodsStore.unlock(goodId)`，成功后 `FitToast` + 刷新。

- [ ] **Step 8: 验证**

切换不同皮肤 → 首页/详情/训练结束 3 处卡片边框/光晕/角标变化；ambassador 限定款闪烁；邀请页 5 人档显示皮肤预览；积分中心入口跳转；积分购买皮肤成功。

- [ ] **Step 9: Commit**

```bash
git add fittrack_flutter/lib/widgets/opponent/opponent_skin_config.dart fittrack_flutter/lib/widgets/virtual_opponent_card.dart fittrack_flutter/lib/pages/opponent_detail_page.dart fittrack_flutter/lib/pages/training_page.dart fittrack_flutter/lib/pages/invitation_page.dart fittrack_flutter/lib/pages/points_detail_page.dart
git commit -m "feat: 对手皮肤 UI 渗透 + 购买入口 + 限定皮肤突出"
```

---

### Task 3.2: 积分获取途径重构 + 成就可获积分标记

**Files:**
- Modify: `fittrack_flutter/lib/services/points_service.dart`（新增 `addDailyTrainingPoints` 方法；启用 `trainingPoints`）
- Modify: `fittrack_flutter/lib/pages/training_page.dart`（训练完成调用积分发放 L560-570）
- Modify: `fittrack_flutter/lib/services/achievement_service.dart`（模型扩展字段；分类积分配置；解锁发放；补全 share/month 逻辑）
- Modify: `fittrack_flutter/lib/data/database_helper.dart`（SQLite v2→v3 升级 L158-174）
- Modify: `fittrack_flutter/lib/data/storage.dart`（settings 默认值 `lastTrainingPointsDate` L440-470）
- Modify: `fittrack_flutter/lib/pages/achievement_page.dart`（积分标记 UI）
- Modify: `fittrack_flutter/lib/pages/honor_wall_page.dart`（积分标记 UI）
- Modify: `fittrack_flutter/lib/pages/points_detail_page.dart`（文案对齐 L319）
- Modify: `fittrack_flutter/lib/widgets/poster_capture_helper.dart`（分享成功调用 `recordShare`）
- Modify: `fittrack_flutter/lib/services/share_card_service.dart`（分享成功调用 `recordShare`）

**实现要点：**

- [ ] **Step 1: SQLite v2→v3 升级**

`database_helper.dart` 升级回调（L158-174）增加 v3：
```dart
if (oldVersion < 3) {
  await db.execute('ALTER TABLE achievements ADD COLUMN pointsReward INTEGER NOT NULL DEFAULT 0');
  await db.execute('ALTER TABLE achievements ADD COLUMN canEarnPoints INTEGER NOT NULL DEFAULT 0');
  // 回填：weight 类 canEarnPoints=0，其余=1（积分值按阶梯）
  await db.execute("UPDATE achievements SET canEarnPoints = CASE WHEN category = 'weight' THEN 0 ELSE 1 END");
  // 按 id 回填 pointsReward
  // ...（用 CASE WHEN id IN (...) THEN N ...）
}
```
把 `version` 从 2 改为 3。

- [ ] **Step 2: Achievement 模型扩展**

`achievement_service.dart` L6-24 的 `Achievement` 类增加：
```dart
final int pointsReward;
final bool canEarnPoints;
```
`_allAchievements`（L30-80）每个成就配置 `pointsReward` 与 `canEarnPoints`：
- streak：7天=20/30天=50/100天=100/365天=200，canEarnPoints=true
- weight：全 0，canEarnPoints=false
- duration：24h=30/100h=80/500h=200，true
- month：3月=50/6月=100/12月=200，true
- explore：15=30/20=60/25=100，true
- plan：50，true
- share：首次=20/3次=40/10次=80，true

`getAllAchievements`（读 SQLite）与 `upsertAchievement`（写 SQLite）同步处理新字段。

- [ ] **Step 3: 解锁发放积分**

`checkAndUnlock`（L109-188）解锁成就后：
```dart
if (achievement.canEarnPoints && achievement.pointsReward > 0) {
  await PointsService.instance.addPoints(achievement.pointsReward, PointsSource.other);
}
```

- [ ] **Step 4: 补全 share 成就解锁**

`achievement_service.dart` 新增：
```dart
Future<List<String>> recordShare() async {
  final count = (Storage.settings['shareCount'] as int? ?? 0) + 1;
  Storage.settings['shareCount'] = count;
  await Storage.saveSettings();
  // 复用 checkAndUnlock 的解锁判定，share_first=1, share_3=3, share_10=10
  return _checkShareAchievements(count);
}
```
`poster_capture_helper.dart` 与 `share_card_service.dart` 成功后调用 `AchievementService.instance.recordShare()`。

- [ ] **Step 5: 补全 month 成就解锁**

`checkAndUnlock` 增加月份判定：
```dart
final months = records.map((r) => _monthKey(r['date'])).toSet();
if (months.length >= 3) _unlock('month_3');
if (months.length >= 6) _unlock('month_6');
if (months.length >= 12) _unlock('month_12');
```

- [ ] **Step 6: 每日训练得积分**

`points_service.dart` 新增：
```dart
Future<bool> addDailyTrainingPoints() async {
  final today = DateTime.now();
  final todayStr = '${today.year}-${today.month}-${today.day}';
  if (Storage.settings['lastTrainingPointsDate'] == todayStr) return false;
  await addPoints(trainingPoints, PointsSource.training);
  Storage.settings['lastTrainingPointsDate'] = todayStr;
  await Storage.saveSettings();
  return true;
}
```
`storage.dart` settings 默认值增加 `'lastTrainingPointsDate': ''`。
`training_page.dart` 训练完成（L560-570 附近 `checkAndUnlock` 调用后）：
```dart
await PointsService.instance.addDailyTrainingPoints();
```

- [ ] **Step 7: 成就页积分标记 UI**

`achievement_page.dart` 成就项：
- `canEarnPoints && pointsReward > 0`：右下角 `BadgeWidget` purple 变体显示 `+${pointsReward}积分`
- `!canEarnPoints`：`BadgeWidget` info 变体显示"纯荣誉"
`honor_wall_page.dart` 同步。

- [ ] **Step 8: 积分页文案对齐**

`points_detail_page.dart` L319 "成就解锁获得变量积分"改为"成就解锁获得积分（部分成就为纯荣誉）"。

- [ ] **Step 9: 验证**

训练完成 → 得 2 积分，同日再训练不得；解锁 streak_7 → 得 20 积分；解锁 weight_1t → 0 积分，标"纯荣誉"；分享 1 次 → share_first 解锁 + 20 积分；训练跨 3 个月 → month_3 解锁 + 50 积分；成就页积分标记显示正确。

- [ ] **Step 10: Commit**

```bash
git add fittrack_flutter/lib/data/database_helper.dart fittrack_flutter/lib/services/achievement_service.dart fittrack_flutter/lib/services/points_service.dart fittrack_flutter/lib/data/storage.dart fittrack_flutter/lib/pages/training_page.dart fittrack_flutter/lib/pages/achievement_page.dart fittrack_flutter/lib/pages/honor_wall_page.dart fittrack_flutter/lib/pages/points_detail_page.dart fittrack_flutter/lib/widgets/poster_capture_helper.dart fittrack_flutter/lib/services/share_card_service.dart
git commit -m "feat: 积分获取途径重构 + 成就可获积分标记"
```

---

## Self-Review

**Spec coverage:**
- ①日期组件+联动 → Task 1.1 ✓
- ②返回键报错 → Task 1.2 ✓
- ③封面图+默认封面 → Task 1.3 ✓
- ④统计页 → Task 2.1 ✓
- ⑤皮肤渗透+购买+限定 → Task 3.1 ✓
- ⑥海报报错 → Task 1.4 ✓
- ⑦积分重构+成就标记 → Task 3.2 ✓
- ⑧课程扩容+搜索页 → Task 2.2 ✓

**Placeholder scan:** 无 TBD/TODO，所有任务含具体文件路径与代码骨架。

**Type consistency:**
- `FitDatePickerSheet.show` 签名一致
- `addDailyTrainingPoints` / `recordShare` 方法名一致
- `SkinCardTheme` 字段名一致
- `Achievement.pointsReward` / `canEarnPoints` 字段名一致

## Execution

用户已指定 subagent 方式实施。按阶段顺序派发，阶段内任务可并行。每阶段完成后回归验证。
