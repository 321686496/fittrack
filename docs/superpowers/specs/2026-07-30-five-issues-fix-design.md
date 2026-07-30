# 五个问题修复设计

- 日期：2026-07-30
- 范围：训练笔记页标题栏、提醒设置测试区块、动作库页面、训练统计热力图、训练页休息弹窗与底部动作指导
- 状态：待评审

## 背景与目标

用户反馈 5 个问题，需修复/增强：

1. 训练笔记页标题栏没有返回按钮
2. 我的页 → 提醒设置中的"测试"区块需移除
3. 动作库页面：用户能自主添加动作；分类项下方留白过多；动作内容需达到专业教学级别（含步骤与每步关键姿势）
4. 训练统计页训练活跃度热力图需基于真实数据，且方块可点击查看详情
5. 训练页休息倒计时弹窗需友好提示（可离开 App、休息结束会通知）；训练页底部需展示当前动作的动作库信息供新手学习

## 已确认的设计决策

- 问题 1：使用与其他独立页面一致的 `PageHeader`（带 `onBack: () => context.pop()`）
- 问题 3a：分类项去掉固定高度、均衡 vertical padding，文字垂直居中
- 问题 3b：用户添加动作采集完整专业级字段（名称、分类、器械、描述、目标肌群、训练步骤含关键姿势）
- 问题 3c：全量细化 21 个内置动作，新增 `keyPoses` 字段
- 问题 4：热力图配色基于真实数据，默认按"训练容量"，可在设置页切换为"训练时长"；**不做休息日单独着色**，无训练日保持灰色
- 问题 4：方块可点击，弹出当日训练详情
- 问题 5a：在休息弹窗进度条与跳过按钮之间插入友好提示文案
- 问题 5b：训练页底部新增可折叠"动作指导"卡片，默认收起

## 架构与约束

- 项目无状态管理框架，数据通过 `Storage`（静态类 + SharedPreferences + SQLite 缓存）和 `MockData`（硬编码常量）管理。
- 动作数据模型为 `Map<String, dynamic>`，分散在 `MockData.exercises` / `exerciseDescriptions` / `exerciseMuscles` / `exerciseSteps`，通过 `id` 关联。自定义动作通过 `Storage.addCustomExercise` 持久化，字段仅 name/category/equip。
- 训练记录 SQLite schema 含 `date`、`duration`、`totalWeight`、`totalSets`、`muscles`、`setRecords` 等字段。
- 通知服务 `RestNotificationService` 已完整实现预约/显示/取消，问题 5a 无需新增通知逻辑。
- 现有设置页 `settings_page.dart` 用 `Storage.getSettings()/saveSettings()`，默认值在 `storage.dart:398-460`。

## 详细设计

### 问题 1：训练笔记页标题栏

**文件**：[fittrack_flutter/lib/pages/note_list_page.dart](file:///d:/app/projects/health_training/fittrack_flutter/lib/pages/note_list_page.dart)

**改动**：第 94-99 行 `PageHeader` 调用增加 `onBack: () => context.pop()`，移除 `isTabPage: true`。文件已导入 go_router，无需其他改动。使其与 `reminder_settings_page.dart:85-88` 风格一致。

### 问题 2：移除提醒设置"测试"区块

**文件**：[fittrack_flutter/lib/pages/reminder_settings_page.dart](file:///d:/app/projects/health_training/fittrack_flutter/lib/pages/reminder_settings_page.dart)

**改动**：
- 删除第 308-331 行（前导 `SizedBox(20)` + `SectionHeader('测试')` + `SizedBox(10)` + `CardWidget` 含"发送测试通知""测试振动"两项）
- 删除第 64-75 行 `_testNotification()`、`_testVibration()` 方法
- 删除第 5 行 `import '../services/rest_notification_service.dart';`（确认仅被测试方法使用）

### 问题 3：动作库页面

#### 3a. 分类项留白优化

**文件**：[fittrack_flutter/lib/pages/exercise_page.dart](file:///d:/app/projects/health_training/fittrack_flutter/lib/pages/exercise_page.dart) 第 113-154 行

**改动**：移除外层 `Container(height: 44)`，改为 `Align(alignment: Alignment.center)` 或直接让内层自适应高度；内层 `vertical` padding 从 8 调整为 6，使文字上下留白均衡。保留水平 padding 16 与选中态背景色逻辑。

#### 3b. 用户自主添加动作（完整专业级）

**入口**：动作库列表页右下角新增 `FloatingActionButton`（图标 `Icons.add`），点击打开添加动作弹窗。

**新增弹窗 `_showAddExerciseDialog`**（在 `exercise_page.dart` 内实现）：
- 字段采集：
  - 名称（文本输入，必填）
  - 分类（下拉选择，复用 `MockData.categories` 去掉"全部"）
  - 器械（文本输入）
  - 动作描述（多行文本，必填）
  - 目标肌群（多选标签，复用现有肌群集合）
  - 训练步骤（动态增删列表，每步含：步骤标题、步骤描述、关键姿势 1-3 条）
- 保存时调用扩展后的 `Storage.addCustomExercise`，将上述字段写入动作对象。

**Storage 扩展**：[fittrack_flutter/lib/data/storage.dart](file:///d:/app/projects/health_training/fittrack_flutter/lib/data/storage.dart) 第 930 行 `addCustomExercise` 方法

当前仅写入 id/isCustom/createTime/name/category/equip。扩展为同时写入：
- `description`（String）
- `muscles`（List<String>）
- `steps`（List<Map>，每项含 `title`/`desc`/`keyPoses`，与 `MockData.exerciseSteps` 结构一致）

持久化到 SharedPreferences 的 `fittrack_customExercises`，结构兼容现有读取逻辑。

**详情页适配**：[exercise_page.dart](file:///d:/app/projects/health_training/fittrack_flutter/lib/pages/exercise_page.dart) `_buildDetailView`（第 264-375 行）与 `_buildStepCard`（第 377-471 行）

当前详情页按 id 查 `MockData.exerciseDescriptions[id]` 等。改为：
- 描述：优先 `exercise['description']`（自定义动作自带），回退 `MockData.exerciseDescriptions[id]`
- 肌群：优先 `exercise['muscles']`，回退 `MockData.exerciseMuscles[id]`
- 步骤：优先 `exercise['steps']`，回退 `MockData.exerciseSteps[id]`

这样内置动作与自定义动作在详情页展示一致。

#### 3c. 内置动作全量细化 + 关键姿势

**文件**：[fittrack_flutter/lib/data/mock_data.dart](file:///d:/app/projects/health_training/fittrack_flutter/lib/data/mock_data.dart) 第 280-376 行 `exerciseSteps`

**改动**：
- 在每个 step Map 中新增 `keyPoses` 字段（`List<String>`，1-3 条关键姿势要点，如"杠铃轨迹保持垂直""核心收紧不塌腰"）
- 重写全部 21 个内置动作（e1-e21）的步骤列表，使每步描述更细致专业，达到教学级别（步骤数 4-6 步，描述具体到关节角度、发力方向、呼吸节奏）

**步骤卡片渲染**：[exercise_page.dart](file:///d:/app/projects/health_training/fittrack_flutter/lib/pages/exercise_page.dart) `_buildStepCard`（第 377-471 行）

在步骤描述下方新增"关键姿势"小节：
- 小标题"关键姿势" + 图标（如 Phosphor `target`）
- 列出 `step['keyPoses']`，每条前缀小圆点
- 若该步无 keyPoses 则不渲染该小节
- 同时被问题 5b 的训练页底部动作指导卡片复用

### 问题 4：训练活跃度热力图

**文件**：[fittrack_flutter/lib/pages/stats_page.dart](file:///d:/app/projects/health_training/fittrack_flutter/lib/pages/stats_page.dart)

#### 数据（已是真实数据，无需更换数据源）

当前 `_computeDailyCounts()`（第 86-95 行）按 `date` 聚合训练记录条数。新增 `_computeDailyMetrics()` 替代之，同时聚合：
- `count`（记录条数，保留）
- `capacity`（当日 `totalWeight` 总和）
- `duration`（当日 `duration` 总和）

数据源仍为 `Storage.getRecords()`，字段已存在于训练记录 schema。

#### 配色模式设置

**新增默认值**：[storage.dart](file:///d:/app/projects/health_training/fittrack_flutter/lib/data/storage.dart) 第 459 行后新增：
```
'activityColorMode': 'capacity',  // 'capacity' 或 'duration'
```

**设置页 UI**：[settings_page.dart](file:///d:/app/projects/health_training/fittrack_flutter/lib/pages/settings_page.dart)

在"训练设置"区块（第 348 行）之后、"音效设置"（第 352 行）之前插入新区块"活跃度配色"，用分段控件切换「训练容量 / 训练时长」。保存通过 `Storage.saveSettings`，参考现有 `_saveTrainingDefaults` 模式。

#### 热力图配色改造

[stats_page.dart](file:///d:/app/projects/health_training/fittrack_flutter/lib/pages/stats_page.dart) 第 635-640 行配色函数改造：
- 读取 `Storage.getSettings()['activityColorMode']`（缓存到字段，build 时读取一次）
- `capacity` 模式：按当日 `capacity` 总和分档 0 / 低 / 中 / 高（阈值待定，如 0 / <2000 / <5000 / >=5000 kg）
- `duration` 模式：按当日 `duration` 总和分档（如 0 / <30 / <60 / >=60 分钟）
- 阈值可在实现时根据实际数据分布微调
- **无训练日（count=0）保持灰色**，不做休息日单独着色

#### 方块可点击查看详情

[stats_page.dart](file:///d:/app/projects/health_training/fittrack_flutter/lib/pages/stats_page.dart) 第 742-768 行 `Builder` 改造：
- 将 `Container` 包裹 `GestureDetector`（或 `InkWell`），`onTap` 弹出底部 sheet
- 底部 sheet 内容：
  - 标题：该日期（如"2026-07-30 周三"）
  - 若有训练记录：列出每条记录（动作名/计划名、组数、总重量、时长、目标肌群徽章）
  - 若无记录：显示"当日无训练记录"
- 底部 sheet 复用项目现有 `showModalBottomSheet` 模式与 `CardWidget`/`BadgeWidget` 组件
- 数据源：从 `_records` 过滤该日期的所有记录

### 问题 5：训练页休息弹窗 + 底部动作指导

**文件**：[fittrack_flutter/lib/pages/training_page.dart](file:///d:/app/projects/health_training/fittrack_flutter/lib/pages/training_page.dart)

#### 5a. 休息弹窗友好提示

在第 1065 行（进度条之后、跳过按钮之前）插入提示文案：
- 半透明白色文字（与弹窗黑色遮罩协调，符合莫兰迪柔色）
- 文案示例："你可以离开 App 去喝口水、活动一下，休息结束时我们会发送通知提醒你开始下一组。"
- 可加一个小图标（如 Phosphor `info` 或 `coffee`）
- 通知机制已由 `RestNotificationService.scheduleRestEndNotification`（`_startRest` 第 356-364 行调用）实现，无需新增逻辑。

#### 5b. 底部可折叠动作指导卡片

在第 999 行（`Expanded` 结束后、Column 闭合前）新增可折叠 `CardWidget`：
- 收起态：一行"动作指导 · {当前动作名}" + 展开图标（Phosphor `caret-down`）
- 展开态：动作描述、目标肌群徽章、训练步骤列表（每步标题 + 描述 + 关键姿势，复用问题 3c 的数据）
- 状态：新增 `bool _actionGuideExpanded = false;` 字段，点击切换
- 数据来源：用 `_exercises[_currentExIdx]['id']` 查询
  - 描述：优先 `_exercises[_currentExIdx]['description']`，回退 `MockData.exerciseDescriptions[id]`
  - 肌群：优先 `_exercises[_currentExIdx]['muscles']`，回退 `MockData.exerciseMuscles[id]`
  - 步骤：优先 `_exercises[_currentExIdx]['steps']`，回退 `MockData.exerciseSteps[id]`
- 切换动作（`_currentExIdx` 变化）时卡片自动更新，收起态保持收起
- 默认收起，避免占用训练操作空间
- 高度限制：展开态内容用 `SingleChildScrollView` 包裹，并限制最大高度（如屏幕高度 30%），避免挤压训练卡片

## 错误处理

- 问题 3b 添加动作：名称/描述为空时禁用保存按钮并提示；步骤至少 1 步
- 问题 4 设置页：`activityColorMode` 读取为 null 或非法值时回退到 `'capacity'`
- 问题 4 热力图：日期无记录时 `capacity`/`duration` 为 0，正常渲染灰色
- 问题 5b：动作无描述/步骤时显示"暂无动作指导"，不报错

## 测试

- 问题 1：进入训练笔记页，标题栏左侧显示返回按钮，点击返回上一页
- 问题 2：进入提醒设置页，不再显示"测试"区块；测试通知/振动功能不可达
- 问题 3a：分类项文字上下留白均衡，无多余空白
- 问题 3b：动作库 FAB 可打开添加弹窗；填写完整字段保存后，列表出现新动作且详情页展示完整内容（描述、肌群、步骤、关键姿势）
- 问题 3c：21 个内置动作详情页均显示细化后的步骤与关键姿势小节
- 问题 4：设置页可切换活跃度配色模式；热力图按所选模式着色；无训练日为灰色；点击方块弹出当日详情
- 问题 5a：进入休息状态，弹窗显示友好提示文案
- 问题 5b：训练页底部显示可折叠动作指导卡片；切换动作时内容更新；展开显示完整步骤与关键姿势

## 不在本次范围

- 不重构动作数据模型为独立 Exercise 类（保持 Map 结构）
- 不为休息日做单独着色（用户已确认）
- 不新增通知逻辑（复用现有 RestNotificationService）
- 不修改 SQLite schema（训练记录字段已足够）
