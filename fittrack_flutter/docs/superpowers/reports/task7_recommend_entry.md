# Task7 报告：计划推荐入口接入重量确认页

## 概述

将「计划推荐」页 `lib/pages/plan_recommend_page.dart` 的 `_selectPlan` 采用流程改造为与「计划库详情页」`_adoptPlan` 一致：先进入重量确认页（`/plan-weight-confirm`），用户确认/修改重量后再保存计划，两个采用入口行为对齐。

## 改了什么

文件：`d:\app\projects\health_training\fittrack_flutter\lib\pages\plan_recommend_page.dart`（`_selectPlan`，原 L40-71）

1. **插入重量确认页**（解锁检查通过后、`toStoragePlan()` 之前）：
   ```dart
   final weights =
       await context.push<Map<String, double>>('/plan-weight-confirm',
           extra: rec.plan);
   if (!mounted) return;
   if (weights == null) return; // 用户取消
   ```
2. **保存时注入重量**：`rec.plan.toStoragePlan()` → `rec.plan.toStoragePlan(weights: weights)`。
3. **顺序调整**：将「暂停现有 active 计划」的循环从函数最前面移到确认页返回且 weights 非空之后（对齐 `_adoptPlan` 的副作用顺序）。
4. 其余逻辑保留不变：精品未解锁 → push 详情页解锁并 return；`addPlanAsync`、`dataChanged`、`widget.onComplete()`、catch（toast「采用计划失败，请重试」）均未改动。

## 顺序调整说明

- 改前：先暂停所有 active 计划 → 再检查解锁 → 再直接保存（不进确认页）。
- 改后：先检查解锁 → push 重量确认页 → 取消（weights == null）则 return 不做任何副作用 → 再暂停 active 计划 → 再保存。
- 目的：用户在确认页取消时，不会误暂停其它进行中的 active 计划，避免副作用泄漏。此顺序与 `_adoptPlan`（L535-546）完全一致。

## 前置条件核实

- 路由 `/plan-weight-confirm` 已注册：`lib/router.dart:282`，`builder` 取 `state.extra as SystemPlan`。
- `SystemPlan.toStoragePlan({Map<String, double>? weights})` 签名已存在：`lib/data/system_plan_library.dart:214`。
- `rec.plan` 类型为 `SystemPlan`（本文件已 import `../data/system_plan_library.dart`；`go_router` 已 import，`context.push<T>` 泛型可用），无需新增 import。

## 验证结果

- `flutter analyze lib/pages/plan_recommend_page.dart`
  - 结果：**无 error / warning**。仅 1 个 `info`：`use_build_context_synchronously` @ L183（`_showInviteCodeSheet` 邀请码弹层内 `if (!ctx.mounted) return;`）。
  - 自查：该 info 位于本次改动未触碰的 `_showInviteCodeSheet` 代码（原文件 L176 即有完全相同的语句，行号因本次改动 +7 位移到 L183），为**改动前已存在的历史 lint**，与本次改造无关，未做改动。
  - 本次修改**零新增告警**。
- `flutter test test/weight_recommendation_service_test.dart test/plan_adopt_bug_test.dart`
  - 结果：**All tests passed!**（+17 全部通过，含 toStoragePlan schema 一致性、缓存一致性、采用持久化用例）。

## 文件改动

- `lib/pages/plan_recommend_page.dart`：`_selectPlan` 改造（+6 行净增）。仅此一个文件被提交。
- 未动：`lib/services/daily_reminder_service.dart`、`lib/utils/platform_utils.dart`（仓库既有无关未提交改动，未 add / 未 commit）。

## 自查发现

1. **既有 info lint**（见上）：`_showInviteCodeSheet` 内 `use_build_context_synchronously`，改动前已存在，超出本次任务范围，未修。若后续需要 analyze 完全 clean 可单独处理。
2. 暂停 active 计划的循环使用同步快照 `Storage.getPlans()` 后逐条 `updatePlanAsync`，与 `_adoptPlan` 一致，未引入额外风险。
3. `weights` 局部变量在 Dart 2.19 下经 `context.push<Map<String, double>>` 泛型约束，`toStoragePlan(weights: weights)` 类型匹配，无 Dart 3 语法。
