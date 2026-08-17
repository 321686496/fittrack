# Task 1 报告：WeightRecommendationService — 动作分类与估算（纯函数）

**日期：** 2026-08-17
**状态：** DONE

## 实现内容

创建了系统训练计划自动填充重量的纯函数核心：

- `lib/services/weight_recommendation_service.dart`
  - `enum ExerciseCategory { compoundPush, compoundPull, compoundLeg, isolationUpper, isolationLower, bodyweight }`
  - `enum WeightSource { history, estimate, bodyweight }`
  - `class ExerciseWeightSuggestion { final double? weight; final WeightSource source; }`
  - `ExerciseCategory classifyExercise(String name)` — 按关键词分类（命中顺序：自重/有氧 → 复合下肢 → 复合上肢推 → 复合上肢拉 → 孤立下肢 → 孤立上肢；未命中回退 `isolationUpper`）
  - `double estimateWeight({bodyWeight, category, fitnessLevel, gender})` — 体重 × 类别占比 × 水平系数 × 性别系数，取整到 2.5kg，下限 2.5kg；复合动作上限 150kg、孤立动作上限 50kg
  - `class WeightRecommendationService`（私有构造 + `instance` 单例，Task 2 将追加 `recommendForSystemPlan`）

实现严格照搬实施计划 Step 3 的代码，注释为中文，无 Dart 3 语法（兼容 Dart 2.19 / Flutter 3.7.12）。

## 测试内容与结果

- `test/weight_recommendation_service_test.dart`（严格照搬计划 Step 1 测试代码）
- 10 个测试用例：复合动作分类（12 断言）、孤立动作分类（8）、自重/有氧分类（7）、未命中回退（1）、估算公式与取整、性别系数 0.70、水平系数 1.45、下限 2.5kg、上下限（50/150kg）、未知水平/性别按 1.0

**结果：10/10 通过（All tests passed!），输出干净。**

## TDD 证据

### RED（Step 2）

命令：`flutter test test/weight_recommendation_service_test.dart`

输出（摘录）：
```
test/weight_recommendation_service_test.dart:3:8: Error: Error when reading 'lib/services/weight_recommendation_service.dart': 系统找不到指定的文件。
test/weight_recommendation_service_test.dart:8:14: Error: Method not found: 'classifyExercise'.
test/weight_recommendation_service_test.dart:8:40: Error: Undefined name 'ExerciseCategory'.
...（classifyExercise / estimateWeight / ExerciseCategory 未定义，大量同类错误）
00:00 +0 -1: Some tests failed.
```

预期原因：实现文件尚不存在，`classifyExercise`/`estimateWeight`/`ExerciseCategory` 均未定义 —— 符合 TDD 先红后绿。

### GREEN（Step 4）

命令：`flutter test test/weight_recommendation_service_test.dart`

输出：
```
00:00 +0: classifyExercise 复合动作分类正确
00:00 +1: classifyExercise 孤立动作分类正确
00:00 +2: classifyExercise 自重/有氧动作分类正确
00:00 +3: classifyExercise 未命中回退孤立上肢
00:00 +4: estimateWeight 公式与取整：65kg 新手男性复合推
00:00 +5: estimateWeight 性别系数：女性 0.70
00:00 +6: estimateWeight 水平系数：高级 1.45
00:00 +7: estimateWeight 下限 2.5kg
00:00 +8: estimateWeight 孤立动作上限 50kg，复合动作上限 150kg
00:00 +9: estimateWeight 未知水平/性别按 1.0 处理
00:00 +10: All tests passed!
```

## 验证

`flutter analyze lib/services/weight_recommendation_service.dart test/weight_recommendation_service_test.dart`

结果：1 issue（info 级）
```
info - The declaration '_defaultBodyWeight' isn't referenced - lib\services\weight_recommendation_service.dart:44:14 - unused_element
```

说明：`_defaultBodyWeight`（默认体重 65kg）按计划在 Task 1 提前定义，将在 Task 2 的 `recommendForSystemPlan` 中使用。属计划内设计，无 error/warning，不改动。

## 文件变更

- 新增：`lib/services/weight_recommendation_service.dart`（120 行）
- 新增：`test/weight_recommendation_service_test.dart`（110 行）

## 提交

- `8e4bd2f` feat: 训练重量自动填充服务（动作分类与估算公式）
- 仅 `git add` 上述两个文件（未使用 `git add -A` / `git add .`）
- 仓库无关改动 `lib/services/daily_reminder_service.dart`、`lib/utils/platform_utils.dart` 未被暂存/改动
- 提交时出现 LF→CRLF 警告，属计划所述正常现象

## 自审

- **完整性**：4 个 TDD 步骤 + 验证 + 提交全部完成；测试代码与实现代码均逐字照搬计划。
- **质量**：符合全部全局约束（取整 2.5kg、下限 2.5kg、复合 150kg/孤立 50kg、默认 65kg、水平/性别存储值、中文注释、无 Dart 3 语法）；单例模式符合项目惯例（同 `PlanRecommendationService.instance`）。
- **纪律/YAGNI**：未添加任何超出计划的功能/文件；未触碰无关文件；未改动任务范围外代码。
- **测试**：10/10 通过，输出干净。

## 关注点

- `_defaultBodyWeight` 目前未被引用（analyze info 级提示），Task 2 接入后消除。属预期，无需处理。
