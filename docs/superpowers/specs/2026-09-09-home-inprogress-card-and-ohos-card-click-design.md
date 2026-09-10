# 首页"训练进行中"卡片 + OHOS 桌面卡片点击修复 设计文档

日期：2026-09-09
状态：已确认（用户批准）

## 背景与目标

### 问题 A：首页训练卡片状态不联动
用户在训练页开始训练后退出到首页，首页"今日训练"卡片仍显示"待开始"。
根因：
- 首页 `_computeTodayPlan()` 只读两条路径：今日训练记录（已完成）/ 活跃计划（待开始），**从不读取 `Storage.getInProgressTraining()` 草稿**。
- 训练页已有完整草稿持久化机制（30 秒定时 + 每组完成后即时落盘），但：
  - 页内返回按钮 `_onBackPressed` 会主动清除草稿；
  - 草稿的保存/清除不触发 `Storage.dataChanged`，首页无感知。

### 问题 B：OHOS 桌面卡片点击返回首页
训练中用户点击 OHOS 桌面卡片按钮（"回到应用"/"结束休息"），应用从训练页被踢回首页。
根因：`OhosReminderService.onTrainingCardAction` 声明了但训练页从未注册（全工程无赋值），`main.dart` 的 `onCardClick` 回调永远走 fallback `_globalRouter?.go('/home')`，销毁训练页。

### 目标
1. 首页卡片在训练进行中（当天草稿存在）时显示"进行中"徽章、组维度进度条、已练时长，按钮为"继续训练"；并提供"放弃训练"入口。
2. 训练页挂载期间点击 OHOS 桌面卡片按钮原地处理（skipRest / 不导航），不销毁训练页。

## 决策记录

- **退出语义**（用户选定）：页内返回按钮与系统手势退出**一律保留草稿**，放弃训练的入口放在首页"进行中"卡片上（小号"放弃"文本按钮 + 确认对话框）。
- **进度维度**：统一使用**组数**（已完成组/总计划组），与 OHOS 桌面卡片口径一致。
- **草稿优先级**：进行中草稿 > 今日已完成记录 > 活跃计划待开始（覆盖当天练完一次又开始第二次的场景）。

## Part A：首页"训练进行中"状态

### A1. storage.dart
- `saveInProgressTraining()` / `clearInProgressTraining()` 末尾翻转 `dataChanged.value`，首页（及其他监听方）自动刷新。

### A2. training_page.dart
- `_onBackPressed`：移除 `Storage.clearInProgressTraining()`；退出前调用 `_persistInProgressTraining()` 确保最新状态落盘（`_trainingDone` 时该方法内部自动跳过）。
- `dispose()`：补一次 `_persistInProgressTraining()` 兜底（覆盖系统手势退出；`_trainingDone` 时自动跳过；异步 fire-and-forget，不 await）。
- `_persistInProgressTraining()` 草稿数据增加 `dayIndex` 字段（来自路由参数 `widget.params['dayIndex']`，存入 State 字段），供首页"继续训练"与 OHOS 恢复路由使用。

### A3. home_page.dart — 数据层
`_computeTodayPlan()` 在今日记录检查**之前**插入草稿分支：

```
inProgress = Storage.getInProgressTraining()
若存在且 startedAtDate == 今天：
  completed  = setRecords 各动作记录数总和（组）
  totalSets  = exercises 各动作 sets 总和（组）
  duration   = now - startedAt 的分钟数
  返回 {
    name: dayConfig.label ?? planName ?? '今日训练',
    muscle: dayConfig.muscle ?? '',
    duration,                    // 已练 X 分钟
    exerciseCount: exercises.length,
    totalSets,
    completed,
    isInProgress: true,
    planId: inProgress.planId,
    dayIndex: inProgress.dayIndex ?? 0,
  }
```

跨天草稿（startedAtDate != 今天）不显示进行中，仍走"待开始"，由训练页现有的跨天弹窗处理。

### A4. home_page.dart — 卡片 UI（`_buildTodayPlanCard`）
- 徽章：`isInProgress` → "进行中"（BadgeVariant.accent）；已完成 → success；待开始 → info。
- 进度条与文案统一组维度：`progress = totalSets > 0 ? completed / totalSets : 0`；进行中文案 `'$completed/$totalSets 组已完成'`。
- 时长行：进行中显示 `'已练 ${duration}min'`（timer 图标前缀，样式同现状）。
- 主按钮：
  - 进行中 → "继续训练" → `push('/training?planId=…&dayIndex=…')`，训练页现有 `_checkInProgressTraining` 自动恢复草稿。
  - 已完成 → "查看记录"（现状不变）。
  - 待开始 → "开始训练"（现状不变）。
- 放弃入口（仅进行中显示）：进度文案行右侧小号文本按钮"放弃"（textMuted 色），点击弹 `AlertDialog`：
  - 标题"放弃本次训练？"，内容"已完成 X 组的记录将被丢弃。"
  - 操作：取消 / 放弃（确认后 `Storage.clearInProgressTraining()`，`dataChanged` 触发首页自动回到"待开始"）。

## Part B：OHOS 桌面卡片点击修复

### B1. training_page.dart — 注册/注销回调
- `initState`：`OhosReminderService.instance.onTrainingCardAction = _onTrainingCardAction;`
- `dispose`：`OhosReminderService.instance.onTrainingCardAction = null;`
- 纯 Dart 回调注册，非 OHOS 平台无副作用（无人触发）。

### B2. handler `_onTrainingCardAction(Map args)`
- `cardAction == 'skipRest'`：**必须带 `_isResting` 保护**再调用 `_skipRest()`——`_skipRest` 不幂等，空闲时误调会写入错误休息记录并推进组数。
- `cardAction == 'resume'`（回到应用）：不导航，原地留在训练页（原生侧 Want 已通过 `UPDATE_PRESENT_FLAG` 拉起应用）。

### B3. main.dart — fallback 改进
训练页不在栈中（handler 为 null）时，`targetPage == 'training'` 分支：
- 若存在**今天的**草稿 → `_globalRouter?.go('/training?planId=$planId&dayIndex=$dayIndex')` 恢复训练页（草稿中的 planId/dayIndex）。
- 否则维持 `go('/home')`。

OHOS 原生侧（EntryAbility.ets / FitTrackWidget.ets）零改动。

## 边界场景
- 当天完成一次训练后又开始第二次：草稿优先 → 显示"进行中"；完成后 `_autoSaveTraining` 清草稿 → `_findTodayRecord` 取最新记录。
- 跨天草稿：首页不显示进行中；下次进入训练页由现有跨天弹窗（保存为记录/丢弃）处理。
- 草稿对应计划已被删除：训练页恢复逻辑现有 catch 兜底清除草稿；首页"继续训练"进入后 `_exercises` 由草稿 dayConfig 提供。
- 0 组完成退出：草稿仍保留，卡片显示"进行中 0/N 组"（训练确实已开始，计时已启动）；用户可通过放弃入口清理。

## 涉及文件
| 文件 | 改动 |
|---|---|
| `lib/data/storage.dart` | save/clear 草稿翻转 dataChanged |
| `lib/pages/training_page.dart` | 返回按钮/dispose 持久化、草稿加 dayIndex、注册/注销 onTrainingCardAction、handler |
| `lib/pages/home_page.dart` | `_computeTodayPlan` 草稿分支、卡片 UI（徽章/进度/时长/继续按钮/放弃入口） |
| `lib/main.dart` | onCardClick fallback：有草稿恢复训练页 |

## 验证方式
- Flutter analyze 通过。
- 手动验证（OHOS 模拟器/真机）：
  1. 开始训练 → 完成数组 → 侧滑/返回退出到首页 → 卡片显示"进行中 X/Y 组"、进度条、"已练 Xmin"、按钮"继续训练"；点继续恢复进度。
  2. 进行中卡片点"放弃" → 确认 → 卡片回到"待开始"。
  3. 训练页内点 OHOS 桌面卡片"回到应用" → 留在训练页（不再跳首页）。
  4. 训练页休息中点桌面卡片"结束休息，开始下一组" → 原地结束休息进入下一组。
  5. 退出到首页后点桌面卡片"回到应用" → 恢复训练页（草稿进度还原）。
