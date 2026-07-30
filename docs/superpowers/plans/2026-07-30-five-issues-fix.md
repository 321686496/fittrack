# 五个问题修复实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复训练笔记页返回按钮、移除提醒设置测试区块、增强动作库（添加动作+分类留白+专业教学级步骤与关键姿势）、训练统计热力图（容量/时长配色+可点击详情）、训练页休息弹窗友好提示+底部可折叠动作指导卡片。

**Architecture:** Flutter 项目无状态管理框架，数据通过 `Storage`（SharedPreferences+SQLite 缓存）和 `MockData`（硬编码常量）管理。动作数据为 `Map<String, dynamic>`。通知服务已存在。本次改造以 UI 调整 + 数据扩展为主，不引入新框架。

**Tech Stack:** Flutter 3.7.12 / Dart >=2.19.6 <3.0.0 / go_router / shared_preferences / sqflite / Phosphor Icons / flutter_local_notifications (OHOS fork)

## Global Constraints

- Dart SDK: `>=2.19.6 <3.0.0`（不可使用 Dart 3+ 特性如 UnmodifiableUint8ListView）
- 平台判断统一使用 `utils/platform_utils.dart` 中的 `isOhos` getter，禁止使用 `Platform.isOhos`
- 测试用 `SharedPreferences.setMockInitialValues({})` + `await Storage.init()` 初始化
- 颜色统一使用 app 定义的 `FitTrackColors` 主色，禁止新增自定义颜色
- 图标使用 Phosphor Icons 或 SVG，禁止使用 emoji
- 海报/卡片圆角遵循项目既有 BorderRadius 规范
- 包名 `com.ft.fittrack`，不修改 Android/HarmonyOS 原生配置
- 不重构动作数据模型为独立 Exercise 类（保持 Map 结构）
- 不修改 SQLite schema
- 不新增通知逻辑（复用现有 RestNotificationService）

**设计文档：** [docs/superpowers/specs/2026-07-30-five-issues-fix-design.md](file:///d:/app/projects/health_training/docs/superpowers/specs/2026-07-30-five-issues-fix-design.md)

---

### Task 1: 训练笔记页标题栏返回按钮

**Files:**
- Modify: `fittrack_flutter/lib/pages/note_list_page.dart:94-99`

**Interfaces:**
- Consumes: `PageHeader` 组件（`fittrack_flutter/lib/widgets/page_header.dart`），`context.pop()` from go_router
- Produces: 无（独立 UI 改动）

- [ ] **Step 1: 修改 PageHeader 调用**

打开 `fittrack_flutter/lib/pages/note_list_page.dart`，定位第 94-99 行：

```dart
PageHeader(
  title: '训练笔记',
  subtitle: '${_notes.length} 篇笔记 · ${_notes.where((n) => n.isFeatured).length} 篇精选',
  isTabPage: true,
),
```

改为（参考 `reminder_settings_page.dart:85-88` 风格）：

```dart
PageHeader(
  onBack: () => context.pop(),
  title: '训练笔记',
  subtitle: '${_notes.length} 篇笔记 · ${_notes.where((n) => n.isFeatured).length} 篇精选',
),
```

文件第 2 行已导入 `package:go_router/go_router.dart`，无需新增 import。

- [ ] **Step 2: 验证编译**

Run: `cd fittrack_flutter ; flutter analyze lib/pages/note_list_page.dart`
Expected: 无错误

- [ ] **Step 3: 手动验证**

运行 app，从"我的"页进入"训练笔记"，标题栏左侧显示返回按钮，点击返回上一页。

- [ ] **Step 4: 提交**

```bash
git add fittrack_flutter/lib/pages/note_list_page.dart
git commit -m "fix: 训练笔记页标题栏增加返回按钮"
```

---

### Task 2: 移除提醒设置"测试"区块

**Files:**
- Modify: `fittrack_flutter/lib/pages/reminder_settings_page.dart`

**Interfaces:**
- Consumes: 无
- Produces: 无（独立 UI 改动）

- [ ] **Step 1: 删除测试区块 UI**

打开 `fittrack_flutter/lib/pages/reminder_settings_page.dart`，删除第 308-331 行，即以下整块代码：

```dart
const SizedBox(height: 20),
SectionHeader(title: '测试'),
const SizedBox(height: 10),
CardWidget(
  children: [
    _buildActionTile(
      context,
      icon: Icons.notifications_active_outlined,
      title: '发送测试通知',
      subtitle: '立即发送一条本地通知',
      onTap: _testNotification,
    ),
    DividerWidget(indent: 44),
    _buildActionTile(
      context,
      icon: Icons.vibration_outlined,
      title: '测试振动',
      subtitle: '触发设备振动反馈',
      onTap: _testVibration,
    ),
  ],
),
```

注意：删除时保留其后"提示卡"区块前导的 `SizedBox(height: 20)`，确保间距正常。具体做法：删除从第 308 行的 `const SizedBox(height: 20),` 到第 331 行的 `),`（CardWidget 闭合），但需确认"提示卡"区块前面是否已有自己的 `SizedBox(height: 20)`——若有则保留一个即可。

- [ ] **Step 2: 删除测试方法**

删除第 64-75 行的 `_testNotification()` 和 `_testVibration()` 方法：

```dart
void _testNotification() async {
  // ... 方法体
}

void _testVibration() {
  // ... 方法体
}
```

完整删除这两个方法及其上方注释（如有）。

- [ ] **Step 3: 删除未使用的 import**

删除第 5 行：

```dart
import '../services/rest_notification_service.dart';
```

注意：先用 Grep 确认 `RestNotificationService` 在本文件其他位置无引用（删除测试方法后应已无引用）。

- [ ] **Step 4: 验证编译**

Run: `cd fittrack_flutter ; flutter analyze lib/pages/reminder_settings_page.dart`
Expected: 无错误，无 unused import 警告

- [ ] **Step 5: 手动验证**

运行 app，进入"我的"→"提醒设置"，页面不再显示"测试"分组及其下的"发送测试通知""测试振动"两项。

- [ ] **Step 6: 提交**

```bash
git add fittrack_flutter/lib/pages/reminder_settings_page.dart
git commit -m "fix: 移除提醒设置页测试区块"
```

---

### Task 3: 动作库分类项留白优化

**Files:**
- Modify: `fittrack_flutter/lib/pages/exercise_page.dart:113-154`

**Interfaces:**
- Consumes: `MockData.categories`（List<String>），`FitTrackColors`
- Produces: 无（独立 UI 改动）

- [ ] **Step 1: 修改分类标签 Container**

打开 `fittrack_flutter/lib/pages/exercise_page.dart`，定位第 113-154 行的 `// Category tabs` 区块。

当前第 115 行外层 Container 固定高度 44：
```dart
Container(
  height: 44,
  margin: const EdgeInsets.only(top: 8),
  child: ListView.separated(
    ...
    itemBuilder: (_, index) {
      ...
      return GestureDetector(
        onTap: () => setState(() => _selectedCategory = cat),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ...
        ),
      );
    },
  ),
),
```

改为去掉固定高度，让内层自适应；外层用 `SizedBox` 控制总高度更紧凑，内层 vertical padding 调小：

```dart
SizedBox(
  height: 38,
  child: ListView.separated(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    itemCount: MockData.categories.length,
    separatorBuilder: (_, __) => const SizedBox(width: 8),
    itemBuilder: (_, index) {
      final cat = MockData.categories[index];
      final isActive = cat == _selectedCategory;
      return GestureDetector(
        onTap: () => setState(() => _selectedCategory = cat),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? colors.accentGlow.withOpacity(0.12) : colors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? colors.accentGlow : colors.divider,
              width: 1,
            ),
          ),
          child: Text(
            cat,
            style: TextStyle(
              color: isActive ? colors.accentGlow : colors.textSecondary,
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      );
    },
  ),
),
```

关键变化：
- 外层 `Container(height: 44)` → `SizedBox(height: 38)` 并移除 `margin: top: 8`（保留顶部间距由父布局已有的 padding 提供；若移除后顶部无间距，则保留 `margin: const EdgeInsets.only(top: 8)`）
- 内层 `vertical: 8` → `vertical: 6`
- 内层增加 `alignment: Alignment.center` 让文字垂直居中
- 保留原选中态背景色/边框逻辑（若原代码颜色字段名不同，保持原字段名不变，仅调整高度与 padding）

注意：实施时先 Read 第 113-154 行确认原 `decoration` 内字段名（`colors.accentGlow`/`colors.cardBg`/`colors.divider` 等），保持除高度/padding/alignment 外的其他属性完全不变。

- [ ] **Step 2: 验证编译**

Run: `cd fittrack_flutter ; flutter analyze lib/pages/exercise_page.dart`
Expected: 无错误

- [ ] **Step 3: 手动验证**

运行 app，进入动作库页，分类标签项文字上下留白均衡，无多余空白，选中态正常显示。

- [ ] **Step 4: 提交**

```bash
git add fittrack_flutter/lib/pages/exercise_page.dart
git commit -m "fix: 动作库分类项留白优化"
```

---

### Task 4: 内置动作步骤细化 + keyPoses 字段（数据层）

**Files:**
- Modify: `fittrack_flutter/lib/data/mock_data.dart:280-376`（`exerciseSteps`）
- Test: `fittrack_flutter/test/exercise_steps_test.dart`（新建）

**Interfaces:**
- Consumes: 无
- Produces: `MockData.exerciseSteps` 每个 step 新增 `keyPoses` 字段（`List<String>`，1-3 条）。供 Task 5/7/12 使用。

**重要：** 本任务工作量较大（21 个动作 × 4-6 步 × 每步含 keyPoses）。实施者需对每个动作写出专业教学级别的步骤描述与关键姿势。可参考专业健身教学资料。

- [ ] **Step 1: 编写失败测试**

新建 `fittrack_flutter/test/exercise_steps_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/mock_data.dart';

void main() {
  test('所有内置动作都有步骤数据', () {
    for (final ex in MockData.exercises) {
      final id = ex['id'] as String;
      final steps = MockData.exerciseSteps[id];
      expect(steps, isNotNull, reason: '$id 缺少步骤数据');
      expect(steps, isA<List>(), reason: '$id steps 不是 List');
      expect((steps as List).length, greaterThanOrEqualTo(4),
          reason: '$id 步骤数应 >= 4');
    }
  });

  test('每个步骤都含 title/desc/keyPoses 且 keyPoses 为非空 List<String>', () {
    for (final ex in MockData.exercises) {
      final id = ex['id'] as String;
      final steps = MockData.exerciseSteps[id] as List;
      for (var i = 0; i < steps.length; i++) {
        final step = steps[i] as Map<String, dynamic>;
        expect(step['title'], isA<String>(), reason: '$id step[$i] title 缺失');
        expect((step['title'] as String).isNotEmpty, true,
            reason: '$id step[$i] title 为空');
        expect(step['desc'], isA<String>(), reason: '$id step[$i] desc 缺失');
        expect((step['desc'] as String).length, greaterThan(20),
            reason: '$id step[$i] desc 过短，需专业教学级别描述');
        expect(step['keyPoses'], isA<List>(), reason: '$id step[$i] keyPoses 缺失或非 List');
        final kp = step['keyPoses'] as List;
        expect(kp.length, greaterThanOrEqualTo(1),
            reason: '$id step[$i] keyPoses 至少 1 条');
        expect(kp.length, lessThanOrEqualTo(3),
            reason: '$id step[$i] keyPoses 最多 3 条');
        for (final k in kp) {
          expect(k, isA<String>(), reason: '$id step[$i] keyPose 非字符串');
          expect((k as String).isNotEmpty, true, reason: '$id step[$i] keyPose 为空');
        }
      }
    }
  });

  test('21 个内置动作覆盖全部 id', () {
    expect(MockData.exercises.length, 21);
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd fittrack_flutter ; flutter test test/exercise_steps_test.dart`
Expected: FAIL（当前 steps 无 keyPoses 字段，desc 可能过短）

- [ ] **Step 3: 重写 exerciseSteps 数据**

打开 `fittrack_flutter/lib/data/mock_data.dart`，定位第 280-376 行 `exerciseSteps`。

逐个动作（e1-e21）重写步骤列表。每个 step 结构：

```dart
{
  'title': '准备姿势',  // 步骤标题
  'desc': '仰卧于平凳上，双脚踩实地面，肩胛骨后缩下沉，挺胸收腹。双手正握杠铃，握距略宽于肩，腕关节保持中立位，肘关节微屈。',  // 详细描述（具体到关节角度、发力方向、呼吸）
  'image': 'https://fastly.picsum.photos/...',  // 保留原图 URL
  'keyPoses': [  // 1-3 条关键姿势要点
    '肩胛骨始终保持后缩下沉，不塌肩',
    '双脚踩实地面，臀部贴紧凳面',
  ],
},
```

需重写的 21 个动作（按 MockData.exercises 顺序，实施前先 Read mock_data.dart 第 199-221 行确认每个 id 对应的动作名）：
- e1: 杠铃卧推
- e2: 上斜哑铃卧推
- e3: 双杠臂屈伸
- e4: 哑铃飞鸟
- e5: 高位下拉
- e6: 杠铃划船
- e7: 引体向上
- e8: 坐姿绳索划船
- e9: 杠铃深蹲
- e10: 腿举
- e11: 哑铃弓步蹲
- e12: 罗马尼亚硬拉
- e13: 哑铃肩推
- e14: 侧平举
- e15: 哑铃前平举
- e16: 杠铃弯举
- e17: 锤式弯举
- e18: 绳索下压
- e19: 仰卧臂屈伸
- e20: 平板支撑
- e21: 卷腹

每个动作要求：
- 4-6 个步骤
- 每步 desc 长度 > 20 字符，具体到关节角度/发力方向/呼吸节奏
- 每步 keyPoses 1-3 条，是该步最关键的姿态要点
- 保留原 `image` URL 不变
- 步骤顺序：准备姿势 → 离心阶段 → 底端位置 → 向心阶段 → 顶端位置 → （可选）呼吸/节奏提示

- [ ] **Step 4: 运行测试确认通过**

Run: `cd fittrack_flutter ; flutter test test/exercise_steps_test.dart`
Expected: PASS（3 个测试全过）

- [ ] **Step 5: 运行全量测试确认无回归**

Run: `cd fittrack_flutter ; flutter test`
Expected: 全部通过（含原有 58 个测试）

- [ ] **Step 6: 提交**

```bash
git add fittrack_flutter/lib/data/mock_data.dart fittrack_flutter/test/exercise_steps_test.dart
git commit -m "feat: 内置动作步骤全量细化并新增 keyPoses 字段"
```

---

### Task 5: 扩展 Storage.addCustomExercise 支持完整字段

**Files:**
- Modify: `fittrack_flutter/lib/data/storage.dart:930`（`addCustomExercise` 方法）
- Test: `fittrack_flutter/test/custom_exercise_test.dart`（新建）

**Interfaces:**
- Consumes: `Storage.getCustomExercises()`（storage.dart:921）
- Produces: `Storage.addCustomExercise(Map)` 现在接受并持久化 `description`/`muscles`/`steps` 字段。供 Task 6 使用。

- [ ] **Step 1: 编写失败测试**

新建 `fittrack_flutter/test/custom_exercise_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test('addCustomExercise 持久化完整字段', () {
    final result = Storage.addCustomExercise({
      'name': '测试动作',
      'category': '胸部',
      'equip': '杠铃',
      'description': '这是一个测试动作的详细描述',
      'muscles': ['胸大肌', '三角肌前束'],
      'steps': [
        {
          'title': '准备姿势',
          'desc': '仰卧于平凳上',
          'keyPoses': ['肩胛后缩'],
        },
      ],
    });

    expect(result['id'], isNotNull);
    expect(result['isCustom'], true);
    expect(result['name'], '测试动作');
    expect(result['description'], '这是一个测试动作的详细描述');
    expect(result['muscles'], ['胸大肌', '三角肌前束']);
    expect((result['steps'] as List).length, 1);

    // 重新读取确认持久化
    final all = Storage.getAllExercises();
    final found = all.firstWhere((e) => e['id'] == result['id']);
    expect(found['description'], '这是一个测试动作的详细描述');
    expect(found['muscles'], ['胸大肌', '三角肌前束']);
    expect((found['steps'] as List).length, 1);
  });

  test('自定义动作与内置动作合并后可区分', () {
    Storage.addCustomExercise({
      'name': '自定义',
      'category': '背部',
      'equip': '哑铃',
      'description': 'desc',
      'muscles': ['背阔肌'],
      'steps': [],
    });
    final all = Storage.getAllExercises();
    final custom = all.where((e) => e['isCustom'] == true).toList();
    expect(custom.length, greaterThanOrEqualTo(1));
    expect(custom.any((e) => e['name'] == '自定义'), true);
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd fittrack_flutter ; flutter test test/custom_exercise_test.dart`
Expected: FAIL（当前 addCustomExercise 不写入 description/muscles/steps）

- [ ] **Step 3: 修改 addCustomExercise**

打开 `fittrack_flutter/lib/data/storage.dart`，定位第 930 行 `addCustomExercise` 方法。

先 Read 该方法当前实现（约 930-945 行），保留原有 id 生成、isCustom、createTime 逻辑，在构造 exercise map 时新增三个字段。改造后大致结构：

```dart
static Map<String, dynamic> addCustomExercise(Map<String, dynamic> data) {
  final customs = getCustomExercises();
  final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
  final exercise = <String, dynamic>{
    'id': id,
    'name': data['name'] ?? '',
    'category': data['category'] ?? '其他',
    'equip': data['equip'] ?? '',
    'image': data['image'] ?? '',
    'isCustom': true,
    'createTime': DateTime.now().millisecondsSinceEpoch,
    'description': data['description'] ?? '',
    'muscles': data['muscles'] ?? <String>[],
    'steps': data['steps'] ?? <Map<String, dynamic>>[],
  };
  customs.add(exercise);
  _saveCustomExercises(customs);
  return exercise;
}
```

注意：实施时先 Read 当前方法体，保留原有的 `_saveCustomExercises` 调用方式与 id 生成策略（若原用 UUID 或其他方式则保留）。仅新增三个字段写入。

- [ ] **Step 4: 运行测试确认通过**

Run: `cd fittrack_flutter ; flutter test test/custom_exercise_test.dart`
Expected: PASS（2 个测试全过）

- [ ] **Step 5: 提交**

```bash
git add fittrack_flutter/lib/data/storage.dart fittrack_flutter/test/custom_exercise_test.dart
git commit -m "feat: addCustomExercise 支持持久化 description/muscles/steps"
```

---

### Task 6: 动作库添加动作弹窗（FAB + 表单）

**Files:**
- Modify: `fittrack_flutter/lib/pages/exercise_page.dart`（增加 FAB 与 `_showAddExerciseDialog`）

**Interfaces:**
- Consumes: `Storage.addCustomExercise`（Task 5 产出，接受 description/muscles/steps），`MockData.categories`
- Produces: 无（UI 改动，调用 Task 5 的接口）

- [ ] **Step 1: 在 ExercisePage 增加 FloatingActionButton**

打开 `fittrack_flutter/lib/pages/exercise_page.dart`，定位 `build` 方法中的 `Scaffold`。在 `Scaffold` 中增加 `floatingActionButton`：

```dart
floatingActionButton: FloatingActionButton(
  onPressed: () => _showAddExerciseDialog(context),
  backgroundColor: colors.accentGlow,
  child: Icon(Icons.add, color: Colors.white),
),
```

若当前 Scaffold 无 floatingActionButton 字段，新增；若有，则替换。注意保持原有 `body` 结构不变。

- [ ] **Step 2: 实现 _showAddExerciseDialog 方法**

在 `ExercisePage` 的 State 类中新增方法 `_showAddExerciseDialog(BuildContext context)`。用 `showModalBottomSheet` 或 `Dialog` 呈现表单（参考项目现有弹窗风格，如 `exercise_picker_sheet.dart` 的 `_showCustomExerciseDialog` 第 318-430 行）。

表单字段与控制器：
```dart
final _nameCtrl = TextEditingController();
final _equipCtrl = TextEditingController();
final _descCtrl = TextEditingController();
String _selectedCategory = MockData.categories[1]; // 跳过"全部"
List<String> _selectedMuscles = [];
List<Map<String, dynamic>> _steps = []; // 每项 {title, desc, keyPoses:[]}
```

UI 结构（使用项目现有组件 CardWidget/DividerWidget/SectionHeader 等）：
- 标题"添加动作"
- 名称（TextField，必填）
- 分类（下拉选择，用 DropdownButton，选项为 `MockData.categories.where((c) => c != '全部').toList()`）
- 器械（TextField）
- 动作描述（TextField，maxLines: 3，必填）
- 目标肌群（多选标签，候选肌群集合可从 `MockData.exerciseMuscles.values.expand((l) => l).toSet().toList()` 获取，点击切换选中态）
- 训练步骤（动态列表）：
  - 每步：步骤标题 TextField + 步骤描述 TextField(maxLines:2) + 关键姿势（1-3 个 TextField，可增删）
  - "添加步骤"按钮（最多 6 步）
  - 每步可删除
- 底部"保存"按钮：校验名称与描述非空、至少 1 步，调用 `Storage.addCustomExercise`，成功后 `setState` 刷新列表并关闭弹窗

保存逻辑示例：
```dart
void _onSave() {
  if (_nameCtrl.text.trim().isEmpty) {
    // 提示"请输入动作名称"
    return;
  }
  if (_descCtrl.text.trim().isEmpty) {
    // 提示"请输入动作描述"
    return;
  }
  if (_steps.isEmpty) {
    // 提示"请至少添加一个步骤"
    return;
  }
  Storage.addCustomExercise({
    'name': _nameCtrl.text.trim(),
    'category': _selectedCategory,
    'equip': _equipCtrl.text.trim(),
    'description': _descCtrl.text.trim(),
    'muscles': _selectedMuscles,
    'steps': _steps.map((s) => {
      'title': s['title'] ?? '',
      'desc': s['desc'] ?? '',
      'keyPoses': s['keyPoses'] ?? <String>[],
    }).toList(),
  });
  setState(() {
    _loadExercises(); // 调用现有的列表刷新方法（确认方法名）
  });
  Navigator.of(context).pop();
}
```

注意：实施前先 Read `exercise_page.dart` 确认列表加载方法名（如 `_loadExercises`/`_refresh`）与 State 类结构。

- [ ] **Step 3: 验证编译**

Run: `cd fittrack_flutter ; flutter analyze lib/pages/exercise_page.dart`
Expected: 无错误

- [ ] **Step 4: 手动验证**

运行 app，进入动作库页，右下角 FAB 可点击打开添加动作弹窗；填写完整字段保存后，列表出现新动作，分类筛选可命中，点击进入详情页显示完整内容。

- [ ] **Step 5: 提交**

```bash
git add fittrack_flutter/lib/pages/exercise_page.dart
git commit -m "feat: 动作库支持用户自主添加动作（完整专业级字段）"
```

---

### Task 7: 动作详情页适配 + 步骤卡片关键姿势渲染

**Files:**
- Modify: `fittrack_flutter/lib/pages/exercise_page.dart:264-375`（`_buildDetailView`）、`377-471`（`_buildStepCard`）

**Interfaces:**
- Consumes: `MockData.exerciseDescriptions`/`exerciseMuscles`/`exerciseSteps`（含 Task 4 新增的 keyPoses），自定义动作自带字段（Task 5）
- Produces: 无（UI 改动）

- [ ] **Step 1: 修改 _buildDetailView 数据读取逻辑**

打开 `fittrack_flutter/lib/pages/exercise_page.dart`，定位 `_buildDetailView`（第 264-375 行）。

当前按 id 查 MockData（约第 267-270 行）：
```dart
final desc = MockData.exerciseDescriptions[exId] ?? '暂无描述';
final muscles = MockData.exerciseMuscles[exId] ?? <String>[];
final steps = MockData.exerciseSteps[exId] ?? <Map>[];
```

改为优先从动作对象自身读取（自定义动作自带），回退到 MockData：
```dart
final desc = (exercise['description'] as String?)?.isNotEmpty == true
    ? exercise['description'] as String
    : (MockData.exerciseDescriptions[exId] ?? '暂无描述');
final muscles = (exercise['muscles'] as List?)?.isNotEmpty == true
    ? List<String>.from(exercise['muscles'] as List)
    : (MockData.exerciseMuscles[exId] ?? <String>[]);
final steps = (exercise['steps'] as List?)?.isNotEmpty == true
    ? List<Map<String, dynamic>>.from(exercise['steps'] as List)
    : (MockData.exerciseSteps[exId] ?? <Map<String, dynamic>>[]);
```

注意：实施时先 Read 第 264-375 行确认变量名（`exId`/`exercise` 等），保持其他渲染逻辑不变。

- [ ] **Step 2: 修改 _buildStepCard 增加 keyPoses 渲染**

定位 `_buildStepCard`（第 377-471 行）。在步骤描述渲染之后（约第 467 行后、卡片闭合前）新增"关键姿势"小节：

```dart
// 关键姿势
if ((step['keyPoses'] as List?)?.isNotEmpty == true) ...[
  const SizedBox(height: 10),
  Row(
    children: [
      Icon(PhosphorIcons.target, size: 14, color: colors.accentGlow),
      const SizedBox(width: 4),
      Text(
        '关键姿势',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.accentGlow,
        ),
      ),
    ],
  ),
  const SizedBox(height: 6),
  ...((step['keyPoses'] as List).map((k) => Padding(
    padding: const EdgeInsets.only(left: 18, bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: colors.accentGlow,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            k.toString(),
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
        ),
      ],
    ),
  ))),
],
```

注意：
- 实施 Read 第 377-471 行确认 Phosphor Icons 导入方式（项目用 `phosphor_flutter` 包，导入名为 `PhosphorIcons`）。若项目用其他图标库，改用对应图标。
- 确认 `colors` 变量在 `_buildStepCard` 作用域内可用；若不可用需传入或通过 `Theme.of` 获取。
- `step` 参数类型若是 `Map<String, dynamic>` 则 `step['keyPoses'] as List?` 可用；若类型不同需适配。

- [ ] **Step 3: 验证编译**

Run: `cd fittrack_flutter ; flutter analyze lib/pages/exercise_page.dart`
Expected: 无错误

- [ ] **Step 4: 手动验证**

运行 app，进入动作库：
- 内置动作详情页：每个步骤下方显示"关键姿势"小节，含 1-3 条要点
- 自定义动作详情页：显示用户填写的描述、肌群、步骤、关键姿势
- 无 keyPoses 的步骤不显示该小节（兼容性）

- [ ] **Step 5: 提交**

```bash
git add fittrack_flutter/lib/pages/exercise_page.dart
git commit -m "feat: 动作详情页适配自定义动作并渲染关键姿势"
```

---

### Task 8: 新增 activityColorMode 设置默认值

**Files:**
- Modify: `fittrack_flutter/lib/data/storage.dart:459`（settings defaults）

**Interfaces:**
- Consumes: 无
- Produces: `Storage.getSettings()['activityColorMode']` 返回 `'capacity'`（默认）或 `'duration'`。供 Task 9/10 使用。

- [ ] **Step 1: 编写失败测试**

新建 `fittrack_flutter/test/activity_color_mode_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test('activityColorMode 默认为 capacity', () {
    final s = Storage.getSettings();
    expect(s['activityColorMode'], 'capacity');
  });

  test('saveSettings 后 activityColorMode 可切换为 duration', () {
    final s = Storage.getSettings();
    s['activityColorMode'] = 'duration';
    Storage.saveSettings(s);
    final s2 = Storage.getSettings();
    expect(s2['activityColorMode'], 'duration');
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd fittrack_flutter ; flutter test test/activity_color_mode_test.dart`
Expected: FAIL（默认值不存在）

- [ ] **Step 3: 新增默认值**

打开 `fittrack_flutter/lib/data/storage.dart`，定位 `getSettings` 方法的 `defaults` map（约第 399-460 行）。在第 459 行（`'lastGymCardReminderDate': '',` 之后、第 460 行 `};` 之前）新增：

```dart
'activityColorMode': 'capacity', // 活跃度配色模式：'capacity'（训练容量）或 'duration'（训练时长）
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd fittrack_flutter ; flutter test test/activity_color_mode_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add fittrack_flutter/lib/data/storage.dart fittrack_flutter/test/activity_color_mode_test.dart
git commit -m "feat: 新增 activityColorMode 设置默认值"
```

---

### Task 9: 设置页新增"活跃度配色"区块

**Files:**
- Modify: `fittrack_flutter/lib/pages/settings_page.dart`

**Interfaces:**
- Consumes: `Storage.getSettings()['activityColorMode']`（Task 8），`Storage.saveSettings`
- Produces: 无（UI 改动）

- [ ] **Step 1: 在 build 方法插入新区块**

打开 `fittrack_flutter/lib/pages/settings_page.dart`，定位 build 方法（约第 326-373 行）。在"训练设置"区块（第 348 行 `SectionHeader(title: '训练设置')` 对应的代码之后）与"音效设置"（第 352 行）之间插入：

```dart
const SizedBox(height: 20),
const SectionHeader(title: '活跃度配色'),
const SizedBox(height: 10),
_buildActivityColorModeSettings(colors),
```

具体插入位置：找到 `_buildTrainingSettings(colors)` 调用所在的 Container/Card 之后、`_buildSoundSettings` 之前。

- [ ] **Step 2: 实现 _buildActivityColorModeSettings 方法**

在 `_buildSoundSettings` 方法之前（约第 546 行前）新增方法。用分段控件（SegmentedButton 或自定义两个按钮）切换两种模式。参考项目现有组件风格（CardWidget + Row）：

```dart
Widget _buildActivityColorModeSettings(FitTrackColors colors) {
  final settings = Storage.getSettings();
  final mode = settings['activityColorMode'] ?? 'capacity';
  final isCapacity = mode != 'duration';

  return CardWidget(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text('配色依据', style: TextStyle(fontSize: 14, color: colors.textPrimary)),
            ),
            _buildModeChip(colors, '训练容量', 'capacity', isCapacity),
            const SizedBox(width: 8),
            _buildModeChip(colors, '训练时长', 'duration', !isCapacity),
          ],
        ),
      ),
    ],
  );
}

Widget _buildModeChip(FitTrackColors colors, String label, String value, bool active) {
  return GestureDetector(
    onTap: () {
      final s = Storage.getSettings();
      s['activityColorMode'] = value;
      Storage.saveSettings(s);
      setState(() {});
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? colors.accentGlow.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? colors.accentGlow : colors.divider,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: active ? colors.accentGlow : colors.textSecondary,
          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    ),
  );
}
```

注意：实施前 Read settings_page.dart 确认：
- `FitTrackColors colors` 的获取方式与字段名（`accentGlow`/`textPrimary`/`textSecondary`/`divider`/`cardBg`）
- `CardWidget` 的用法（是否需要 `children` 参数）
- `setState` 在 State 类中可用

- [ ] **Step 3: 验证编译**

Run: `cd fittrack_flutter ; flutter analyze lib/pages/settings_page.dart`
Expected: 无错误

- [ ] **Step 4: 手动验证**

运行 app，进入"设置"页，"训练设置"下方显示"活跃度配色"区块，可在"训练容量"与"训练时长"间切换，切换后重启 app 仍保持选择。

- [ ] **Step 5: 提交**

```bash
git add fittrack_flutter/lib/pages/settings_page.dart
git commit -m "feat: 设置页新增活跃度配色模式切换"
```

---

### Task 10: 训练统计热力图配色改造 + 方块可点击

**Files:**
- Modify: `fittrack_flutter/lib/pages/stats_page.dart`（`_computeDailyCounts`、`_buildHeatmap`、方块 Builder）

**Interfaces:**
- Consumes: `Storage.getRecords()`，`Storage.getSettings()['activityColorMode']`（Task 8），训练记录字段 `date`/`duration`/`totalWeight`/`totalSets`/`muscles`/`name`/`planName`
- Produces: 无（UI 改动）

- [ ] **Step 1: 新增 _computeDailyMetrics 替代 _computeDailyCounts**

打开 `fittrack_flutter/lib/pages/stats_page.dart`，定位第 36 行 `Map<String, int> _dailyCounts = {};` 与第 86-95 行 `_computeDailyCounts()`。

新增字段（替换或并存，保持兼容）：
```dart
Map<String, int> _dailyCounts = {};           // 记录条数
Map<String, int> _dailyCapacity = {};         // 当日总重量
Map<String, int> _dailyDuration = {};         // 当日总时长（分钟）
```

新增方法（保留原 `_computeDailyCounts` 或替换为 `_computeDailyMetrics`）：
```dart
void _computeDailyMetrics() {
  _dailyCounts = {};
  _dailyCapacity = {};
  _dailyDuration = {};
  for (final r in _records) {
    final ts = r['date'] as int? ?? r['createTime'] as int?;
    if (ts == null) continue;
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    final key = '${d.year}-${d.month}-${d.day}';
    _dailyCounts[key] = (_dailyCounts[key] ?? 0) + 1;
    _dailyCapacity[key] = (_dailyCapacity[key] ?? 0) + ((r['totalWeight'] as num?)?.toInt() ?? 0);
    _dailyDuration[key] = (_dailyDuration[key] ?? 0) + ((r['duration'] as num?)?.toInt() ?? 0);
  }
}
```

在 `initState`/`onTabBecameActive`/`_onRefresh` 中调用 `_computeDailyMetrics()`（替换原 `_computeDailyCounts()` 调用，若其他地方仍用 `_dailyCounts` 则保留两者）。

- [ ] **Step 2: 改造热力图配色函数**

定位第 635-640 行配色逻辑。新增方法获取方块颜色：

```dart
Color _heatColor(String key, FitTrackColors colors) {
  final count = _dailyCounts[key] ?? 0;
  if (count == 0) return colors.divider.withOpacity(0.3); // 无训练灰色

  final mode = Storage.getSettings()['activityColorMode'] ?? 'capacity';
  int value;
  if (mode == 'duration') {
    value = _dailyDuration[key] ?? 0;
    // 时长分档：0 / <30 / <60 / >=60 分钟
    if (value >= 60) return colors.accentGlow;
    if (value >= 30) return colors.accentGlow.withOpacity(0.7);
    return colors.accentGlow.withOpacity(0.4);
  } else {
    value = _dailyCapacity[key] ?? 0;
    // 容量分档：0 / <2000 / <5000 / >=5000 kg
    if (value >= 5000) return colors.accentGlow;
    if (value >= 2000) return colors.accentGlow.withOpacity(0.7);
    return colors.accentGlow.withOpacity(0.4);
  }
}
```

在方块渲染处（约第 758 行 `final count = _dailyCounts[key] ?? 0;` 后的颜色判断）改为调用 `_heatColor(key, colors)`。注意保留原 count 用于 tooltip 等显示。

- [ ] **Step 3: 方块包裹 GestureDetector 并实现点击详情**

定位第 742-768 行方块 `Builder`。将内层 `Container` 包裹 `GestureDetector`：

```dart
GestureDetector(
  onTap: () => _showDayDetail(key),
  child: Container(
    // 原有 decoration 等
  ),
),
```

新增方法 `_showDayDetail(String key)`：

```dart
void _showDayDetail(String key) {
  // 解析 key 为 DateTime
  final parts = key.split('-');
  if (parts.length != 3) return;
  final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

  // 过滤当日记录
  final dayRecords = _records.where((r) {
    final ts = r['date'] as int? ?? r['createTime'] as int?;
    if (ts == null) return false;
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    return d.year == date.year && d.month == date.month && d.day == date.day;
  }).toList();

  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final colors = FitTrackColors.of(context);
      final weekDay = '周${['一','二','三','四','五','六','日'][date.weekday - 1]}';
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$key $weekDay',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary),
              ),
              const SizedBox(height: 4),
              if (dayRecords.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('当日无训练记录', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
                  ),
                )
              else ...[
                Text('${dayRecords.length} 条训练记录',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                const SizedBox(height: 12),
                ...dayRecords.map((r) => _buildDayRecordCard(r, colors)),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildDayRecordCard(Map<String, dynamic> r, FitTrackColors colors) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: colors.cardBg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          (r['name'] as String?) ?? '训练',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary),
        ),
        if ((r['planName'] as String?)?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('计划：${r['planName']}',
                style: TextStyle(fontSize: 12, color: colors.textSecondary)),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _metricChip(colors, '组数', '${r['totalSets'] ?? 0}'),
            _metricChip(colors, '总量', '${r['totalWeight'] ?? 0} kg'),
            _metricChip(colors, '时长', '${r['duration'] ?? 0} 分钟'),
            _metricChip(colors, '动作', '${r['exerciseCount'] ?? 0} 个'),
          ],
        ),
        if ((r['muscles'] as List?)?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: ((r['muscles'] as List).cast<String>()).map((m) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.accentGlow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(m, style: TextStyle(fontSize: 11, color: colors.accentGlow)),
            )).toList(),
          ),
        ],
      ],
    ),
  );
}

Widget _metricChip(FitTrackColors colors, String label, String value) {
  return Text('$label: $value', style: TextStyle(fontSize: 12, color: colors.textSecondary));
}
```

注意：实施前 Read stats_page.dart 确认：
- `FitTrackColors.of(context)` 的获取方式（项目可能是 `FitTrackColors.of(context)` 或通过 `Theme.of`）
- `colors` 字段名（`cardBg`/`textPrimary`/`textSecondary`/`accentGlow`/`divider`）
- 原 `_buildHeatmap` 内是否已有 `colors` 变量在作用域内
- 方块 Builder 当前结构（第 742-768 行）以精确包裹

- [ ] **Step 4: 验证编译**

Run: `cd fittrack_flutter ; flutter analyze lib/pages/stats_page.dart`
Expected: 无错误

- [ ] **Step 5: 手动验证**

运行 app，进入训练统计页：
- 热力图方块按当前配色模式着色（默认容量），有训练日深浅不同，无训练日灰色
- 在设置页切换"训练时长"后返回统计页，配色变化
- 点击任意方块，弹出底部 sheet 显示该日期与训练记录详情；无训练日显示"当日无训练记录"

- [ ] **Step 6: 提交**

```bash
git add fittrack_flutter/lib/pages/stats_page.dart
git commit -m "feat: 热力图支持容量/时长配色模式与方块点击详情"
```

---

### Task 11: 训练页休息弹窗友好提示

**Files:**
- Modify: `fittrack_flutter/lib/pages/training_page.dart:1007-1092`（`_buildRestOverlay`）

**Interfaces:**
- Consumes: 无（通知机制已存在）
- Produces: 无（UI 改动）

- [ ] **Step 1: 在休息弹窗插入提示文案**

打开 `fittrack_flutter/lib/pages/training_page.dart`，定位 `_buildRestOverlay`（第 1007-1092 行）。

在第 1065 行（进度条 `Container` 闭合之后、第 1067 行"跳过休息"按钮之前）插入提示文案：

```dart
const SizedBox(height: 24),
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 12),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(PhosphorIcons.coffee, size: 16, color: Colors.white.withOpacity(0.7)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          '你可以离开 App 去喝口水、活动一下，休息结束时我们会发送通知提醒你开始下一组。',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
            height: 1.5,
          ),
        ),
      ),
    ],
  ),
),
```

注意：
- 实施 Read 第 1007-1092 行确认 Phosphor Icons 导入与原弹窗结构
- 若项目用其他图标库，改用对应图标名
- 确认 `Colors.white` 在该作用域可用（弹窗已是黑色遮罩背景）

- [ ] **Step 2: 验证编译**

Run: `cd fittrack_flutter ; flutter analyze lib/pages/training_page.dart`
Expected: 无错误

- [ ] **Step 3: 手动验证**

运行 app，开始训练，完成一组后进入休息状态，弹窗显示倒计时与友好提示文案"你可以离开 App..."。

- [ ] **Step 4: 提交**

```bash
git add fittrack_flutter/lib/pages/training_page.dart
git commit -m "feat: 休息弹窗新增友好提示文案"
```

---

### Task 12: 训练页底部可折叠动作指导卡片

**Files:**
- Modify: `fittrack_flutter/lib/pages/training_page.dart`（新增字段与 `_buildActionGuide` 方法，在第 999 行后插入）

**Interfaces:**
- Consumes: `_exercises[_currentExIdx]`（当前动作），`MockData.exerciseDescriptions`/`exerciseMuscles`/`exerciseSteps`（含 Task 4 的 keyPoses）
- Produces: 无（UI 改动）

- [ ] **Step 1: 新增状态字段**

打开 `fittrack_flutter/lib/pages/training_page.dart`，定位 State 类字段区（约第 45-61 行）。在 `_restEndNotified` 等字段附近新增：

```dart
bool _actionGuideExpanded = false;
```

- [ ] **Step 2: 实现 _buildActionGuide 方法**

在 `_buildTrainingContent` 方法之后或附近新增方法：

```dart
Widget _buildActionGuide(FitTrackColors colors) {
  if (_exercises.isEmpty || _currentExIdx >= _exercises.length) {
    return const SizedBox.shrink();
  }
  final ex = _exercises[_currentExIdx];
  final exId = ex['id'] as String?;

  // 数据读取（优先动作自带字段，回退 MockData）
  final desc = (ex['description'] as String?)?.isNotEmpty == true
      ? ex['description'] as String
      : (exId != null ? (MockData.exerciseDescriptions[exId] ?? '') : '');
  final muscles = (ex['muscles'] as List?)?.isNotEmpty == true
      ? List<String>.from(ex['muscles'] as List)
      : (exId != null ? (MockData.exerciseMuscles[exId] ?? <String>[]) : <String>[]);
  final steps = (ex['steps'] as List?)?.isNotEmpty == true
      ? List<Map<String, dynamic>>.from(ex['steps'] as List)
      : (exId != null ? (MockData.exerciseSteps[exId] ?? <Map<String, dynamic>>[]) : <Map<String, dynamic>>[]);

  final exName = ex['name'] as String? ?? '当前动作';
  final hasContent = desc.isNotEmpty || muscles.isNotEmpty || steps.isNotEmpty;

  return CardWidget(
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
    child: Column(
      children: [
        // 标题行（点击展开/收起）
        InkWell(
          onTap: () => setState(() => _actionGuideExpanded = !_actionGuideExpanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(PhosphorIcons.lightbulb, size: 16, color: colors.accentGlow),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '动作指导 · $exName',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary),
                  ),
                ),
                Icon(
                  _actionGuideExpanded ? PhosphorIcons.caretUp : PhosphorIcons.caretDown,
                  size: 14,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (_actionGuideExpanded) ...[
          DividerWidget(indent: 14),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.3,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: hasContent
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (desc.isNotEmpty) ...[
                        Text('动作说明', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.accentGlow)),
                        const SizedBox(height: 4),
                        Text(desc, style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.5)),
                        const SizedBox(height: 10),
                      ],
                      if (muscles.isNotEmpty) ...[
                        Text('目标肌群', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.accentGlow)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: muscles.map((m) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.accentGlow.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(m, style: TextStyle(fontSize: 11, color: colors.accentGlow)),
                          )).toList(),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (steps.isNotEmpty) ...[
                        Text('训练步骤', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.accentGlow)),
                        const SizedBox(height: 6),
                        ...steps.asMap().entries.map((e) {
                          final i = e.key;
                          final s = e.value;
                          final kp = (s['keyPoses'] as List?) ?? [];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${i + 1}. ${s['title'] ?? ''}',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                                if ((s['desc'] as String?)?.isNotEmpty == true)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2, left: 12),
                                    child: Text(s['desc'],
                                        style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4)),
                                  ),
                                if (kp.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  ...kp.map((k) => Padding(
                                    padding: const EdgeInsets.only(left: 24, bottom: 2),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('· ', style: TextStyle(fontSize: 12, color: colors.accentGlow)),
                                        Expanded(child: Text(k.toString(),
                                            style: TextStyle(fontSize: 11, color: colors.textSecondary))),
                                      ],
                                    ),
                                  )),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text('暂无动作指导', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                    ),
                  ),
            ),
          ),
        ],
      ],
    ),
  );
}
```

注意：实施前 Read training_page.dart 确认：
- `CardWidget` 的构造参数（是 `child` 还是 `children`，是否接受 `margin`）——若与上方不符，改为 `CardWidget(child: Padding(...))` 或用 `Container`+`decoration` 自行实现
- `DividerWidget` 用法
- Phosphor Icons 导入与可用图标名（`lightbulb`/`caretUp`/`caretDown`）——若不可用改用 Material Icons
- `colors` 变量获取方式

- [ ] **Step 3: 在 _buildTrainingContent Column 中插入卡片**

定位 `_buildTrainingContent`（第 697-1003 行）的 Column。在第 999 行 `Expanded` 闭合之后、第 1000 行 `],`（Column 闭合）之前插入：

```dart
if (_exercises.isNotEmpty && _currentExIdx < _exercises.length)
  _buildActionGuide(colors),
```

注意：确认 `colors` 在 `_buildTrainingContent` 作用域内可用；若变量名不同需适配。

- [ ] **Step 4: 验证编译**

Run: `cd fittrack_flutter ; flutter analyze lib/pages/training_page.dart`
Expected: 无错误

- [ ] **Step 5: 手动验证**

运行 app，开始训练：
- 训练卡片下方显示"动作指导 · {当前动作名}"收起态卡片
- 点击展开，显示动作说明、目标肌群、训练步骤（含关键姿势）
- 切换到下一个动作时，卡片内容更新，保持收起态
- 展开态内容超过屏幕 30% 时可滚动

- [ ] **Step 6: 提交**

```bash
git add fittrack_flutter/lib/pages/training_page.dart
git commit -m "feat: 训练页底部新增可折叠动作指导卡片"
```

---

## 实施顺序建议

按依赖关系与风险递增：
1. **Task 1, 2, 3, 11**（独立简单 UI 改动，可并行）
2. **Task 8**（数据默认值，Task 9/10 依赖）
3. **Task 4**（数据层，Task 7/12 依赖）
4. **Task 5**（数据层，Task 6 依赖）
5. **Task 9**（设置页，依赖 Task 8）
6. **Task 7**（详情页，依赖 Task 4）
7. **Task 6**（添加动作，依赖 Task 5）
8. **Task 10**（热力图，依赖 Task 8）
9. **Task 12**（动作指导，依赖 Task 4）

## 验证清单

实施完成后整体回归：
- [ ] `cd fittrack_flutter ; flutter test` 全部通过
- [ ] `cd fittrack_flutter ; flutter analyze` 无错误
- [ ] 手动走查 5 个问题的全部场景
