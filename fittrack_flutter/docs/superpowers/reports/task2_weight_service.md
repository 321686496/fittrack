# Task 2 报告：WeightRecommendationService — 历史匹配与计划级编排

## 实现了什么

在 `lib/services/weight_recommendation_service.dart` 中：

1. **顶部追加 imports**：
   - `import '../data/storage.dart';`
   - `import '../data/system_plan_library.dart';`
2. **在 `WeightRecommendationService` 类内追加两个方法**（严格按计划 Step 3 代码）：
   - `recommendForSystemPlan(SystemPlan plan, {records, bodyData, settings, userPlans})`：遍历计划所有 day/exercise，先分类（bodyweight 动作直接返回 weight=null + source=bodyweight），否则优先查历史重量（`_historyWeight`），命中则 source=history，未命中则用 `estimateWeight` 估算（source=estimate）。所有参数可注入（便于测试），缺省时从 `Storage.getRecords()/getBodyData()/getSettings()/getPlans()` 读取。
   - 私有 `_historyWeight(String exerciseName, records, userPlans)`：通过 `userPlans` 构建每个 planId 的 exId→name 映射，遍历 records（最新在前），在 `setRecords` 中按动作名匹配，返回最近一次记录最后一组的 weight（>0）。

在 `test/weight_recommendation_service_test.dart` 中：

1. 顶部追加 `import 'package:fittrack_flutter/data/system_plan_library.dart';`
2. 追加计划 Step 1 的 `group('recommendForSystemPlan', ...)`（3 个测试）+ 测试辅助 `_ex`/`_day`/`_buildPlan`/`_buildUserPlan`。

## 测试与结果

- `flutter test test/weight_recommendation_service_test.dart` → **13/13 全部通过**（原 10 个 + 新增 3 个）。
- `flutter analyze lib/services/weight_recommendation_service.dart` → **No issues found!**
- 文件以换行符结尾（最后字节 = LF，已验证）；此前未使用的 `_defaultBodyWeight` 现已被 `recommendForSystemPlan` 消费，无 analyze 告警。

## TDD 证据

### RED

命令：
```
flutter test test/weight_recommendation_service_test.dart
```

失败输出（关键部分）：
```
test/weight_recommendation_service_test.dart:120:30: Error: The method 'recommendForSystemPlan' isn't defined for the class 'WeightRecommendationService'.
 - 'WeightRecommendationService' is from 'package:fittrack_flutter/services/weight_recommendation_service.dart' ...
      final result = service.recommendForSystemPlan(
                             ^^^^^^^^^^^^^^^^^^^^^^
（同样的报错出现在 140:30、166:30，共 3 处）
Failed to load "...weight_recommendation_service_test.dart": Compilation failed ...
00:00 +0 -1: Some tests failed.
```

原因符合预期：Task 2 新增方法尚未实现，编译失败，测试文件无法加载。

### GREEN

命令：
```
flutter test test/weight_recommendation_service_test.dart
```

通过输出（尾部）：
```
00:00 +10: recommendForSystemPlan 无历史时按身体信息估算，来源为 estimate
00:00 +11: recommendForSystemPlan 有历史记录时优先使用历史重量，来源为 history
00:00 +12: recommendForSystemPlan 自重动作 weight 为 null，来源为 bodyweight
00:00 +13: All tests passed!
```

## 变更文件

- `lib/services/weight_recommendation_service.dart`（+99/-1）
- `test/weight_recommendation_service_test.dart`（+122）

## 提交

```
3e82d4b feat: 训练重量自动填充服务（历史优先 + 计划级编排）
```

- 仅 `git add` 上述两个文件，未用 `git add -A`/`git add .`。
- 提交不含仓库中无关未提交改动（`lib/services/daily_reminder_service.dart`、`lib/utils/platform_utils.dart`），这两个文件保持未提交状态未受影响。
- 提交过程中出现 LF→CRLF 警告，属任务说明中标注的正常现象。

## 自审发现

- **完整性**：Step 1-5 全部完成，RED→GREEN→analyze→提交闭环。
- **与计划的契合度**：实现代码逐字遵循计划 Step 3，测试代码逐字遵循计划 Step 1。
- **签名适配**：计划中的 `_buildPlan`/`_buildUserPlan` 辅助函数与真实 `SystemPlan`/`SystemPlanDay`/`SystemPlanExercise` 构造函数签名完全匹配（`gender` 字段有默认值 `'all'`，计划测试未传，合法），无需调整。
- **Storage 依赖确认**：`Storage.getRecords()`、`Storage.getBodyData()`、`Storage.getSettings()`、`Storage.getPlans()` 均存在于 `lib/data/storage.dart`（分别位于 347/648/403/213 行），与计划 Step 3 假设一致。
- **纪律/YAGNI**：未做任何超出计划的改动，未触碰无关文件，未引入多余抽象。
- **细节**：服务文件末尾已补齐尾换行符。

## 问题与顾虑

- 无阻塞性问题。
- 说明性观察：`_historyWeight` 取的是记录中每组 set 列表的 `last`（最后一组）的重量，这是计划既定逻辑；records 顺序“最新在前”由调用方 `Storage.getRecords()` 保证，注入测试数据时由测试自行控制。
