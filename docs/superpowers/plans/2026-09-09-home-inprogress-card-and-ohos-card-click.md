# 首页"训练进行中"卡片 + OHOS 桌面卡片点击修复 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 首页"今日训练"卡片在训练进行中时显示"进行中"徽章、组维度进度条、已练时长与"继续训练"按钮（含放弃入口）；修复 OHOS 桌面卡片点击把训练页踢回首页的 bug。

**Architecture:** 复用训练页已有的 In-Progress Training 草稿持久化机制（Storage.getSharedPreferences），通过 `Storage.dataChanged` 通知首页刷新；训练页挂载时注册 `OhosReminderService.onTrainingCardAction` 原地处理桌面卡片点击，fallback 场景（训练页不在栈中）按草稿恢复训练路由。

**Tech Stack:** Flutter 3.7.12 / Dart >=2.19.6 <3.0.0 / GoRouter / SharedPreferences

**设计文档:** `docs/superpowers/specs/2026-09-09-home-inprogress-card-and-ohos-card-click-design.md`

## Global Constraints

- Dart SDK 约束：>=2.19.6 <3.0.0（不可用 Dart 3 语法，如 switch 表达式、records、patterns）
- OHOS 原生侧（EntryAbility.ets / FitTrackWidget.ets）零改动，纯 Flutter 侧修复
- 不引入新依赖；图标用 Material Icons（项目现状）
- `_skipRest()` 非幂等：任何调用前必须 `_isResting` 防护，否则空闲误调会写入错误休息记录并推进组数
- 所有命令在 `fittrack_flutter/` 目录下执行
- 代码注释使用中文（项目现状）

---

### Task 1: Storage 草稿变更触发 dataChanged 通知

**Files:**
- Modify: `fittrack_flutter/lib/data/storage.dart:603-632`
- Test: `fittrack_flutter/test/storage_in_progress_test.dart`

**Interfaces:**
- Consumes: 现有 `Storage.dataChanged`（`ValueNotifier<bool>`，L371）
- Produces: `saveInProgressTraining` / `clearInProgressTraining` 保存/清除草稿后翻转 `dataChanged`，首页 `_loadData` 监听方自动刷新

- [ ] **Step 1: 写失败测试**

在 `fittrack_flutter/test/storage_in_progress_test.dart` 的 `main()` 内追加两个测试：

```dart
  test('saveInProgressTraining toggles dataChanged notifier', () async {
    await Storage.init();
    final before = Storage.dataChanged.value;
    await Storage.saveInProgressTraining({'planId': 'test'});
    expect(Storage.dataChanged.value, !before);
  });

  test('clearInProgressTraining toggles dataChanged notifier', () async {
    await Storage.init();
    await Storage.saveInProgressTraining({'planId': 'test'});
    final before = Storage.dataChanged.value;
    await Storage.clearInProgressTraining();
    expect(Storage.dataChanged.value, !before);
    expect(Storage.getInProgressTraining(), isNull);
  });
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/storage_in_progress_test.dart`
Expected: 新增两个测试 FAIL（`dataChanged.value` 未翻转）

- [ ] **Step 3: 实现**

`fittrack_flutter/lib/data/storage.dart`，`saveInProgressTraining`（L603-607）末尾追加翻转：

```dart
  /// 保存进行中的训练数据（异步落盘）
  static Future<void> saveInProgressTraining(Map<String, dynamic> data) async {
    data['lastPersistedAt'] = DateTime.now().millisecondsSinceEpoch;
    _store[_inProgressKey] = data;
    _prefs?.setString('$_keyPrefsPrefix$_inProgressKey', jsonEncode(data));
    // 通知监听方（首页等）刷新"进行中"状态
    dataChanged.value = !dataChanged.value;
  }
```

`clearInProgressTraining`（L628-632）末尾追加翻转：

```dart
  /// 清除进行中的训练数据
  static Future<void> clearInProgressTraining() async {
    _store.remove(_inProgressKey);
    await _prefs?.remove('$_keyPrefsPrefix$_inProgressKey');
    // 通知监听方（首页等）刷新回"待开始"
    dataChanged.value = !dataChanged.value;
  }
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/storage_in_progress_test.dart`
Expected: 全部 PASS（含原有 4 个测试）

- [ ] **Step 5: Commit**

```bash
git add fittrack_flutter/lib/data/storage.dart fittrack_flutter/test/storage_in_progress_test.dart
git commit -m "feat: 草稿保存/清除触发 dataChanged，首页可感知训练进行中状态"
```

---

### Task 2: 训练页草稿保留语义（返回不清除 + dispose 兜底 + dayIndex 字段）

**Files:**
- Modify: `fittrack_flutter/lib/pages/training_page.dart`

**Interfaces:**
- Consumes: 现有 `_persistInProgressTraining()`（内部 `_trainingDone || _exercises.isEmpty` 时自动跳过）、`Storage.saveInProgressTraining`
- Produces: 草稿数据新增 `dayIndex` 字段（int），供 Task 4 首页"继续训练"按钮与 Task 3 fallback 路由使用

- [ ] **Step 1: State 增加 `_initialDayIndex` 字段并初始化**

`_TrainingPageState` 的 `// ── Training state ──` 区（`bool _trainingDone = false;` L62 附近）新增：

```dart
  bool _trainingDone = false;

  /// 路由传入的训练日索引（持久化到草稿，供首页"继续训练"与
  /// OHOS 卡片 fallback 恢复训练路由使用）
  int _initialDayIndex = 0;
```

`initState` 中（`_startTime = DateTime.now();` L118 之后）新增：

```dart
    _startTime = DateTime.now();
    _initialDayIndex = widget.params['dayIndex'] as int? ?? 0;
```

- [ ] **Step 2: `_persistInProgressTraining` 草稿数据增加 dayIndex**

`_persistInProgressTraining`（L661-692）的 data map 中，`'dayConfig': _dayConfig,` 一行后新增：

```dart
        'planId': _plan?['id'],
        'planName': _plan?['name'],
        'dayConfig': _dayConfig,
        'dayIndex': _initialDayIndex,
        'exercises': _exercises,
```

- [ ] **Step 3: 恢复草稿时同步 dayIndex**

`_restoreInProgressTraining`（L718-770）中，`_startTime = DateTime.fromMillisecondsSinceEpoch(data['startedAt'] as int);` 之后新增：

```dart
      _startTime =
          DateTime.fromMillisecondsSinceEpoch(data['startedAt'] as int);
      _initialDayIndex = data['dayIndex'] as int? ?? _initialDayIndex;
```

- [ ] **Step 4: `_onBackPressed` 移除清除草稿，改为退出前持久化**

将（L213-221）：

```dart
  /// 顶部返回按钮：先恢复卡片空闲态，再返回上一页。
  void _onBackPressed() {
    // 主动退出：清理进行中训练持久化
    if (!_trainingDone) {
      Storage.clearInProgressTraining();
    }
    _resetWidgetOnExit();
    context.pop();
  }
```

改为：

```dart
  /// 顶部返回按钮：先恢复卡片空闲态，再返回上一页。
  /// 训练未完成时保留草稿（首页显示"进行中"，可继续）；
  /// 放弃训练入口在首页"进行中"卡片上。
  void _onBackPressed() {
    _persistInProgressTraining();
    _resetWidgetOnExit();
    context.pop();
  }
```

- [ ] **Step 5: dispose 兜底持久化**

`dispose()`（L160-176）中，`_resetWidgetOnExit();` 之前新增一行：

```dart
    // 兜底：系统手势退出时补一次草稿持久化
    // （_trainingDone / _exercises 为空时内部自动跳过；异步 fire-and-forget）
    _persistInProgressTraining();
    _resetWidgetOnExit();
```

- [ ] **Step 6: 运行 analyze 验证**

Run: `flutter analyze`
Expected: No issues found!

- [ ] **Step 7: Commit**

```bash
git add fittrack_flutter/lib/pages/training_page.dart
git commit -m "feat: 训练页退出保留草稿（返回按钮不再清除）+ 草稿增加 dayIndex"
```

---

### Task 3: OHOS 桌面卡片点击修复（训练页注册 handler + main.dart fallback）

**Files:**
- Modify: `fittrack_flutter/lib/pages/training_page.dart`
- Modify: `fittrack_flutter/lib/main.dart:102-117`

**Interfaces:**
- Consumes: `OhosReminderService.instance.onTrainingCardAction`（`Function(Map<String, dynamic>)?`，ohos_reminder_service.dart L35）、Task 2 的草稿 `dayIndex` 字段、`_isResting` getter（L79）
- Produces: 训练页挂载期间桌面卡片点击原地处理；训练页不在栈中时 fallback 按当天草稿恢复 `/training` 路由

- [ ] **Step 1: 训练页增加 import**

`fittrack_flutter/lib/pages/training_page.dart` 头部 import 区新增（`import '../services/permission_service.dart';` 附近）：

```dart
import '../services/ohos_reminder_service.dart';
```

- [ ] **Step 2: initState 注册回调**

`initState` 末尾（`_persistenceTimer = Timer.periodic(...)` L139-141 之后）新增：

```dart
    // OHOS 桌面卡片交互：训练页挂载期间原地处理（skipRest / 回到应用不导航），
    // 避免卡片点击走 fallback 跳转首页销毁训练页导致数据丢失
    OhosReminderService.instance.onTrainingCardAction = _onTrainingCardAction;
```

- [ ] **Step 3: dispose 注销回调**

`dispose()` 中（`_resetWidgetOnExit();` 之前，Task 2 新增的兜底持久化之后）新增：

```dart
    // 注销桌面卡片交互回调（恢复 main.dart fallback 逻辑）
    OhosReminderService.instance.onTrainingCardAction = null;
```

- [ ] **Step 4: 实现 handler**

`_onNotificationClicked` 方法（L183-198）之后新增：

```dart
  /// OHOS 桌面卡片点击（训练页挂载期间）：
  /// - skipRest：结束休息进入下一组（必须 _isResting 防护——
  ///   _skipRest 非幂等，空闲时误调会写入错误休息记录并推进组数）
  /// - resume：仅回到应用，原地不动（原生侧 Want 已拉起应用到前台）
  void _onTrainingCardAction(Map<String, dynamic> args) {
    if (!mounted) return;
    final cardAction = args['cardAction'] as String?;
    if (cardAction == 'skipRest' && _isResting) {
      _skipRest();
    }
    // 'resume' 及其他：不做导航，保留当前训练页
  }
```

- [ ] **Step 5: main.dart fallback 按草稿恢复训练页**

将 `main.dart`（L102-117）：

```dart
      OhosReminderService.instance.onCardClick = (args) {
        final targetPage = args['targetPage'] as String?;
        if (targetPage == 'training') {
          final handler = OhosReminderService.instance.onTrainingCardAction;
          if (handler != null) {
            handler(args);
          } else {
            _globalRouter?.go('/home');
          }
        } else if (targetPage == 'home') {
          _globalRouter?.go('/home');
        }
        // 转发到 PAL 事件流（WidgetCardService.onCardClick / LiveViewService.onUserAction）
        ohosWidgetCard.handleCardClick(args);
        ohosLiveView.handleCardClick(args);
      };
```

改为：

```dart
      OhosReminderService.instance.onCardClick = (args) {
        final targetPage = args['targetPage'] as String?;
        if (targetPage == 'training') {
          final handler = OhosReminderService.instance.onTrainingCardAction;
          if (handler != null) {
            // 训练页在栈中：原地处理（skipRest / 不导航）
            handler(args);
          } else {
            // 训练页不在栈中：有今天的草稿则恢复训练页，否则回首页
            final inProgress = Storage.getInProgressTraining();
            final now = DateTime.now();
            final today = '${now.year}-${now.month}-${now.day}';
            final planId = inProgress?['planId'] as String?;
            final dayIndex = inProgress?['dayIndex'] as int? ?? 0;
            if (inProgress != null &&
                inProgress['startedAtDate'] == today &&
                planId != null &&
                planId.isNotEmpty) {
              _globalRouter?.go('/training?planId=$planId&dayIndex=$dayIndex');
            } else {
              _globalRouter?.go('/home');
            }
          }
        } else if (targetPage == 'home') {
          _globalRouter?.go('/home');
        }
        // 转发到 PAL 事件流（WidgetCardService.onCardClick / LiveViewService.onUserAction）
        ohosWidgetCard.handleCardClick(args);
        ohosLiveView.handleCardClick(args);
      };
```

- [ ] **Step 6: 运行 analyze 验证**

Run: `flutter analyze`
Expected: No issues found!

- [ ] **Step 7: Commit**

```bash
git add fittrack_flutter/lib/pages/training_page.dart fittrack_flutter/lib/main.dart
git commit -m "fix: OHOS 桌面卡片点击不再踢回首页——训练页原地处理，无训练页时按草稿恢复"
```

---

### Task 4: 首页数据层 —— `_computeTodayPlan` 草稿分支

**Files:**
- Modify: `fittrack_flutter/lib/pages/home_page.dart:168-212`

**Interfaces:**
- Consumes: `Storage.getInProgressTraining()`（草稿含 Task 2 的 `dayIndex`）、草稿字段 `setRecords: Map<String, List>`、`exercises: List<Map>`、`startedAt: int(ms)`
- Produces: `_computeTodayPlan()` 返回 map 新增 `isInProgress: true` 键（Task 5 UI 依赖）；待开始分支新增 `totalSets` 键（组维度进度分母）

- [ ] **Step 1: `_computeTodayPlan` 插入草稿分支（优先级最高）**

在 `_computeTodayPlan()` 方法体内、`// 今天已有完成的训练` 注释（L171）之前插入：

```dart
  Map<String, dynamic>? _computeTodayPlan() {
    final active = _activePlanCache;

    // 今天有进行中的训练草稿：优先显示"进行中"
    // （优先级：进行中草稿 > 今日已完成 > 待开始，
    //  覆盖当天练完一次又开始第二次的场景；跨天草稿不显示，
    //  由训练页现有的跨天弹窗处理）
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    final inProgress = Storage.getInProgressTraining();
    if (inProgress != null && inProgress['startedAtDate'] == today) {
      final setRecords = inProgress['setRecords'] as Map? ?? {};
      final completedSets = setRecords.values.fold<int>(
          0, (sum, list) => sum + (list as List).length);
      final exercises = (inProgress['exercises'] as List?) ?? [];
      final totalSets = exercises.fold<int>(
          0, (sum, ex) => sum + (((ex as Map)['sets'] as num?) ?? 0).toInt());
      final dayConfig = inProgress['dayConfig'] as Map? ?? {};
      final startedAt =
          inProgress['startedAt'] as int? ?? now.millisecondsSinceEpoch;
      final elapsedMin = now
          .difference(DateTime.fromMillisecondsSinceEpoch(startedAt))
          .inMinutes;
      return {
        'name': dayConfig['label'] ?? inProgress['planName'] ?? '今日训练',
        'muscle': dayConfig['muscle'] ?? '',
        'duration': elapsedMin,
        'exerciseCount': exercises.length,
        'totalSets': totalSets,
        'completed': completedSets,
        'isInProgress': true,
        'planId': inProgress['planId'],
        'dayIndex': inProgress['dayIndex'] ?? 0,
      };
    }

    // 今天已有完成的训练：展示已完成状态（含实际训练时长），而不是推进后的下一日内容
    final todayRecord = _findTodayRecord();
```

（此后现有代码保持不变）

- [ ] **Step 2: 待开始分支补充 totalSets**

活跃计划分支的 return（L200-208）增加 `totalSets` 键：

```dart
        return {
          'name': dayData['label'] ?? '今日训练',
          'muscle': dayData['muscle'] ?? '',
          'duration': 60,
          'exerciseCount': exercises.length,
          'totalSets': exercises.fold<int>(
              0, (sum, ex) => sum + ((ex['sets'] as num?) ?? 0).toInt()),
          'completed': 0,
          'planId': active['id'],
          'dayIndex': dayIndex,
        };
```

- [ ] **Step 3: 运行 analyze 验证**

Run: `flutter analyze`
Expected: No issues found!

- [ ] **Step 4: Commit**

```bash
git add fittrack_flutter/lib/pages/home_page.dart
git commit -m "feat: 首页今日训练卡片数据层读取进行中草稿（优先级：草稿>已完成>待开始）"
```

---

### Task 5: 首页卡片 UI —— 进行中徽章/组进度/已练时长/继续按钮/放弃入口

**Files:**
- Modify: `fittrack_flutter/lib/pages/home_page.dart:541-642`

**Interfaces:**
- Consumes: Task 4 的 `plan['isInProgress']`、`plan['totalSets']`（进行中/待开始两分支均有）、`plan['duration']`（进行中=已练分钟数）、`Storage.clearInProgressTraining()`（Task 1 触发 dataChanged 自动刷新）
- Produces: 无（叶子 UI 层）

- [ ] **Step 1: 改造 `_buildTodayPlanCard` 状态与进度计算**

将方法开头（L541-547）：

```dart
  Widget _buildTodayPlanCard(LiftTrackColors colors, Map<String, dynamic> plan) {
    final isCompleted = plan['isCompleted'] == true;
    final completed = plan['completed'] as int? ?? 0;
    final total = plan['exerciseCount'] as int? ?? 1;
    final progress = isCompleted
        ? 1.0
        : (total > 0 ? completed / total : 0.0);
```

改为：

```dart
  Widget _buildTodayPlanCard(LiftTrackColors colors, Map<String, dynamic> plan) {
    final isCompleted = plan['isCompleted'] == true;
    final isInProgress = plan['isInProgress'] == true;
    final completed = plan['completed'] as int? ?? 0;
    final total = plan['exerciseCount'] as int? ?? 1; // 动作数（"X个动作"文案）
    // 进度统一组维度：已完成组 / 总计划组（与桌面卡片口径一致）
    final totalSets = (plan['totalSets'] as int?) ?? 0;
    final progress = isCompleted
        ? 1.0
        : (totalSets > 0 ? completed / totalSets : 0.0);
```

- [ ] **Step 2: 徽章显示"进行中"**

将徽章（L562-569）：

```dart
              BadgeWidget(
                text: isCompleted
                    ? '已完成'
                    : (progress > 0 ? '进行中' : '待开始'),
                variant: isCompleted
                    ? BadgeVariant.success
                    : (progress > 0 ? BadgeVariant.accent : BadgeVariant.info),
              ),
```

改为：

```dart
              BadgeWidget(
                text: isCompleted
                    ? '已完成'
                    : (isInProgress ? '进行中' : '待开始'),
                variant: isCompleted
                    ? BadgeVariant.success
                    : (isInProgress ? BadgeVariant.accent : BadgeVariant.info),
              ),
```

- [ ] **Step 3: 时长行进行中显示"已练 Xmin"**

将时长 Text（L585-590）：

```dart
              Icon(Icons.timer_outlined, size: 16, color: colors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${plan['duration'] ?? 0}min',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
```

改为：

```dart
              Icon(Icons.timer_outlined, size: 16, color: colors.textSecondary),
              const SizedBox(width: 4),
              Text(
                isInProgress
                    ? '已练 ${plan['duration'] ?? 0}min'
                    : '${plan['duration'] ?? 0}min',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
```

- [ ] **Step 4: 进度文案统一组维度 + 放弃入口**

将进度文案 Text（L601-608）：

```dart
          ProgressBar(progress: progress),
          const SizedBox(height: 4),
          Text(
            isCompleted
                ? '共${plan['totalSets'] ?? 0}组 · 总负重${plan['totalWeight'] ?? 0}kg'
                : '$completed/$total 已完成',
            style: TextStyle(color: colors.textMuted, fontSize: 12),
          ),
```

改为：

```dart
          ProgressBar(progress: progress),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                isCompleted
                    ? '共${plan['totalSets'] ?? 0}组 · 总负重${plan['totalWeight'] ?? 0}kg'
                    : '$completed/$totalSets 组已完成',
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
              if (isInProgress) ...[
                const Spacer(),
                GestureDetector(
                  onTap: () => _confirmAbandonTraining(completed),
                  child: Text(
                    '放弃',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                      decorationColor: colors.textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
```

- [ ] **Step 5: 新增放弃确认对话框方法**

在 `_buildTodayPlanCard` 方法之后新增：

```dart
  /// 放弃进行中的训练：确认后清除草稿，卡片经 dataChanged 自动回到"待开始"
  void _confirmAbandonTraining(int completedSets) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('放弃本次训练？'),
        content: Text(completedSets > 0
            ? '已完成 $completedSets 组的记录将被丢弃。'
            : '当前训练进度将被丢弃。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Storage.clearInProgressTraining();
            },
            child: const Text('放弃'),
          ),
        ],
      ),
    );
  }
```

- [ ] **Step 6: 主按钮进行中显示"继续训练"**

将按钮（L610-638）的 `onPressed` else 分支与 `child` Text 改为：

```dart
            onPressed: () {
              if (isCompleted) {
                // 已完成：直接跳转到今日这次训练的记录详情
                // 使用 push 保留首页在栈中，返回时回到首页
                final recordId = plan['recordId'] as String?;
                if (recordId != null && recordId.isNotEmpty) {
                  context.push('/records/$recordId');
                } else {
                  context.push('/records');
                }
              } else {
                // 进行中/待开始：进入训练页（训练页 _checkInProgressTraining
                // 自动恢复草稿进度）
                context.push('/training?planId=${plan['planId'] ?? _activePlan?['id'] ?? 'plan1'}&dayIndex=${plan['dayIndex'] ?? 0}');
              }
            },
```

按钮文案：

```dart
              child: Text(
                isCompleted
                    ? '查看记录'
                    : (isInProgress ? '继续训练' : '开始训练'),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
```

- [ ] **Step 7: 运行 analyze 验证**

Run: `flutter analyze`
Expected: No issues found!

- [ ] **Step 8: Commit**

```bash
git add fittrack_flutter/lib/pages/home_page.dart
git commit -m "feat: 首页训练卡片进行中状态（组进度/已练时长/继续训练/放弃入口）"
```

---

## 整体回归验证（Task 5 完成后执行）

- [ ] **Run: `flutter analyze`** — Expected: No issues found!
- [ ] **Run: `flutter test`** — Expected: 全部 PASS

### 手动验证清单（OHOS 模拟器/真机，Medium_Phone_4k AVD 不适用于 OHOS，用 OHOS 模拟器）

1. 开始训练 → 完成数组 → 顶部返回按钮退出到首页 → 卡片显示"进行中 X/Y 组"徽章、进度条、"已练 Xmin"、按钮"继续训练"；点继续训练恢复草稿进度。
2. 训练中系统侧滑退出到首页 → 同上（草稿兜底持久化生效）。
3. 进行中卡片点"放弃" → 确认对话框 → 确认 → 卡片回到"待开始"（0 组时文案"当前训练进度将被丢弃"）。
4. 训练页内点 OHOS 桌面卡片"回到应用 →" → 留在训练页（不再跳首页）。
5. 训练页休息中点桌面卡片"结束休息，开始下一组 →" → 原地结束休息进入下一组；休息空闲态点该按钮 → 无副作用（不推进组数）。
6. 退出到首页后（有当天草稿）点桌面卡片"回到应用 →" → 恢复训练页（草稿进度还原）。
7. 无草稿时点桌面卡片 → 回到首页（现状不变）。
8. 训练完成 → 草稿自动清除 → 首页卡片显示"已完成"。
