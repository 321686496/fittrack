# Task 6 端到端验证报告：系统训练计划自动填充重量

> 日期：2026-08-17
> 范围：`fittrack_flutter`（Flutter 3.7.12 / Dart 2.19）
> 依据计划：`docs/superpowers/plans/2026-08-17-system-plan-weight-recommendation.md` Task 6

## 结论速览

| 步骤 | 结果 |
| --- | --- |
| Step 1 全量测试 `flutter test` | ✅ 147/147 通过，无预存在失败 |
| Step 2 静态检查 `flutter analyze` | ✅ 无 error / warning；209 条 info 级 lint 均与功能文件无关 |
| Step 3 构建 `flutter build apk --debug` | ✅ 构建成功，产出 `app-debug.apk` |
| Step 4 端到端静态走查 | ✅ 流程一致；`weight` 持久化链路完整 |
| Step 5 提交 | 跳过（未发现需修复的 bug，无代码改动） |

## 1. 测试结果（flutter test）

```
00:15 +147: All tests passed!
```

- 通过：147 / 147
- 失败：0
- 预存在失败：无（`widget_test.dart` 的 App launches smoke test 也通过，未出现计划中提及的 Timer 泄漏问题）

## 2. 静态检查（flutter analyze）

```
209 issues found. (ran in 16.3s)
```

- **error / warning：0**
- 209 条全部为 info 级 lint（`prefer_const_constructors`、`unused_import`、`avoid_print`、`await_only_futures`、`use_build_context_synchronously` 等），全部位于既有文件。
- 对功能相关文件单独执行 analyze 确认完全干净：
  ```
  Analyzing 6 items...
  No issues found! (ran in 2.0s)
  ```
  涉及文件：`lib/services/weight_recommendation_service.dart`、`lib/pages/plan_weight_confirm_page.dart`、`lib/router.dart`、`lib/data/system_plan_library.dart`、`lib/pages/plan_library_detail_page.dart`、`test/weight_recommendation_service_test.dart`。

## 3. 构建校验（flutter build apk --debug）

```
√  Built build\app\outputs\flutter-apk\app-debug.apk.
```

- 产物：`d:\app\projects\health_training\fittrack_flutter\build\app\outputs\flutter-apk\app-debug.apk`（约 401 MB，2026/8/17 12:xx 生成）
- 仅有 Gradle/SDK 版本提示（SDK XML v4 vs v3）等无害警告，不影响构建成功。

## 4. 端到端静态走查

环境无可用 Android 模拟器（`flutter devices` 仅显示 OHOS 设备 127.0.0.1:5555、Windows/Chrome/Edge），按任务说明以静态走查替代手工冒烟。

### 4.1 流程链路核验（全部一致）

1. **入口** `lib/pages/plan_library_detail_page.dart` `_adoptPlan`（526-557 行）
   - `await context.push<Map<String, double>>('/plan-weight-confirm', extra: plan)`
   - `weights == null`（用户取消）直接返回 ✅
   - 非空时：暂停现有 active 计划（`updatePlanAsync`，await 确保持久化）→ `plan.toStoragePlan(weights: weights)` → `await Storage.addPlanAsync(newPlan)` → `dataChanged` 通知 → `context.go('/home')` ✅
2. **路由** `lib/router.dart`（281-288 行）
   - `/plan-weight-confirm` 注册在 `/plan-library/:goal` 之后、`/plan-search` 之前，`parentNavigatorKey: rootNavigatorKey`，`builder` 取 `state.extra as SystemPlan` ✅
   - 已 import `pages/plan_weight_confirm_page.dart` 与 `data/system_plan_library.dart` ✅
3. **确认页** `lib/pages/plan_weight_confirm_page.dart`
   - `initState`：`WeightRecommendationService.instance.recommendForSystemPlan(widget.plan)`；体重缺失（≤0）时置 `_bodyInfoMissing` 并展示 65kg 估算提示条 ✅
   - 非自重动作创建 `TextEditingController` 预填建议重量；自重动作不建控制器、UI 显示「自重」标签 ✅
   - `_confirm`：校验所有非自重动作重量非空且 > 0，失败提示并高亮首个空项；成功 `Navigator.of(context).pop(weights)`（`Map<String, double>`）✅
   - 确认页使用主题色均存在于 `LiftTrackColors`（`bgSecondary/bgCard/textPrimary/textSecondary/textMuted/borderColor/accentSecondary/accentGlow/warningColor`），无自定义颜色常量 ✅
4. **服务** `lib/services/weight_recommendation_service.dart`
   - `classifyExercise` 命中顺序、`estimateWeight` 公式/取整/上下限、`recommendForSystemPlan`（history 优先 + 参数注入便于测试）、`_historyWeight`（经 userPlans 解析 record setRecords 的 exId→name，records 最新在前）——全部与计划一致 ✅

### 4.2 关键风险检查：addPlanAsync 是否持久化 weight —— ✅ 通过

链路完整：

1. `toStoragePlan(weights:)`（`lib/data/system_plan_library.dart` 214-245 行）为有重量的动作生成 `{...e.toJson(), 'weight': w}`，自重动作保持 `e.toJson()` 不含 weight ✅
2. `Storage.addPlanAsync`（`lib/data/storage.dart` 228-245 行）将完整 `plan` map（含 `days`）传给 `_db.insertPlan(newPlan)` ✅
3. `DatabaseHelper.insertPlan`（`lib/data/database_helper.dart` 291-296 行）→ `_planMapToRow`（378-388 行）：`days` 是 List，`jsonEncode(days)` 完整序列化为 JSON 字符串存入 SQLite —— **包含每个动作的 `weight` 字段** ✅
4. 读取侧 `_planRowToMap`（364-375 行）：`days` JSON 字符串 `jsonDecode` 还原为 List，`weight` 无损往返 ✅
5. 训练页预填 `lib/pages/training_page.dart` `_prefillWeightReps`（588-610 行）：无逐组 `setConfig` 时读取 `nextEx['weight']` 预填输入框 —— 即确认页持久化下来的重量 ✅

结论：**weight 会被完整持久化并在训练时正确预填，无数据丢失风险。**

### 4.3 其他发现

- 确认页 `_confirm` 对 `_suggestions[ex.id] == null` 的情况 `continue` 跳过（理论上不会发生，因为 `recommendForSystemPlan` 遍历所有动作必然生成建议），行为安全。
- 无关未提交文件 `lib/services/daily_reminder_service.dart`、`lib/utils/platform_utils.dart` 未做任何改动，未纳入任何提交（见下）。

## 5. 修复与提交

- 发现需修复的 bug：无
- 创建提交：无（Task 6 为纯验证任务）
- 工作区无关改动：`lib/services/daily_reminder_service.dart`、`lib/utils/platform_utils.dart`（未提交、未触碰，符合约束）

## 6. 总体判定

**功能就绪，可以交付。**

- 全部测试通过（147/147），静态检查无 error/warning，debug APK 构建成功。
- 端到端流程（采用 → 重量确认/修改 → 持久化 → 训练预填）静态走查完全一致，尤其 `weight` 的 SQLite 持久化链路（toStoragePlan → addPlanAsync → _planMapToRow jsonEncode → _planRowToMap jsonDecode）确认无损。
- 未做任何代码改动，未产生新提交。
