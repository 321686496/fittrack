# Task 3 报告：SystemPlan.toStoragePlan 支持注入重量

**Status:** DONE
**日期:** 2026-08-17
**计划:** `docs/superpowers/plans/2026-08-17-system-plan-weight-recommendation.md`（Task 3 部分）

## 实现内容

修改 `lib/data/system_plan_library.dart` 的 `SystemPlan.toStoragePlan` 方法（212-245 行）：

1. 方法签名增加可选命名参数 `{Map<String, double>? weights}`（`动作id → 重量(kg)`）。
2. 生成每个动作 JSON 时，若 `weights` 中包含该动作 id，则通过 map spread 追加 `'weight': w`；未包含的动作保持 `e.toJson()` 原样（不含 `weight` 字段）。
3. 文档注释补充 `[weights]` 说明。

实现与计划 Step 3 代码完全一致，无偏差。改动仅限上述两点，方法其余字段（id/name/type/frequency/…/isFromSystemLibrary/时间戳）均未改动。

## 测试情况

文件：`test/weight_recommendation_service_test.dart`（追加 `toStoragePlan 重量注入` 分组，含 1 个测试）。

### TDD 证据

**RED**（Step 2，实现前运行）：
```
flutter test test/weight_recommendation_service_test.dart
test/weight_recommendation_service_test.dart:186:42: Error: No named parameter with the name 'weights'.
      final storage = plan.toStoragePlan(weights: {'ex_001': 30.0});
                                         ^^^^^^^
00:00 +0 -1: Some tests failed.
```
与计划预期一致（`toStoragePlan` 不接受 `weights` 命名参数）。

**GREEN**（Step 4，实现后运行）：
```
flutter test test/weight_recommendation_service_test.dart
00:00 +0: classifyExercise 复合动作分类正确
...
00:00 +13: toStoragePlan 重量注入 注入重量后动作 JSON 含 weight，未注入动作不含
00:00 +14: All tests passed!
```
全部 14 个测试通过（含既有 13 个 + 新增 1 个）。

### 静态检查

```
flutter analyze lib/data/system_plan_library.dart
Analyzing system_plan_library.dart...
No issues found! (ran in 2.0s)
```

## 提交

```
da74d9e feat: toStoragePlan 支持注入建议重量
 2 files changed, 24 insertions(+), 2 deletions(-)
```
仅 `git add lib/data/system_plan_library.dart test/weight_recommendation_service_test.dart`，未使用 `git add -A`。提交内容仅含本任务两个文件；无关未提交改动（`lib/services/daily_reminder_service.dart`、`lib/utils/platform_utils.dart`）保持未动、未提交。提交时出现 LF→CRLF 警告（计划允许的正常现象）。

## 变更文件

- `lib/data/system_plan_library.dart`（修改，+8/-2 行）
- `test/weight_recommendation_service_test.dart`（修改，+16 行）

## 自审

- **完整性**：TDD 四步（测试→RED→实现→GREEN）全部完成；analyze 通过；提交完成。
- **质量**：符合 Dart 2.19 约束（map spread `{...}` 为 Dart 2.3+ 语法，非 Dart 3 特性；无 records/switch 表达式/patterns 等 Dart 3 语法）；注释为中文。
- **YAGNI**：未添加计划之外的任何功能或抽象。
- **兼容性**：未提供 `weights` 时行为与旧版完全一致（各动作 JSON 无 `weight` 字段），不影响既有调用方与 `plan_adopt_bug_test`。

## 计划 vs 现实的适配说明

1. **测试插入位置适配**：计划 Step 1 写"在测试文件末尾追加"，但当前测试文件的结构为 `main()` 在 177 行已闭合、其后方为 `_ex/_day/_buildPlan/_buildUserPlan` 等辅助函数。若真追加到文件末尾会导致 `group()` 位于顶层（不合法）。因此将新分组插入 `main()` 内、`recommendForSystemPlan` 分组之后、`main()` 闭合 `}` 之前。测试代码本身与计划完全一致。
2. **无需新增 import/辅助函数**：`data/system_plan_library.dart` 的 import 及 `_buildPlan/_day/_ex` 辅助已在 Task 2 添加，Task 3 测试可直接复用。
3. **实现零适配**：计划的 Step 3 代码与现库中 `toStoragePlan` 结构完全吻合，按计划代码原样应用。

## 问题与关注点

- 无遗留问题。后续 Task 4/5 将依赖本方法的新参数（确认页返回 `Map<String, double>` 后调用 `plan.toStoragePlan(weights: ...)`）。
