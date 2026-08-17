# Task 5: 采用流程接入确认页 — 执行报告

## 实现内容

修改 `lib/pages/plan_library_detail_page.dart` 的 `_adoptPlan` 方法，在采用系统计划时先跳转重量确认页（`/plan-weight-confirm`），用户确认/修改重量后携带 `Map<String, double>` 返回，再执行暂停现有 active 计划、保存新计划（含确认重量）、toast + 跳转首页。

## 验证结果与适配

- **当前 `_adoptPlan` 形状与计划假设完全一致**：无额外 premium/points 逻辑（解锁逻辑在 `_handleAction` 中，不受影响），可直接按计划替换
- **现有 imports 已满足**：`go_router`、`storage.dart`、`common_widgets.dart`、`system_plan_library.dart` 均已在文件顶部存在，无需追加
- **Task 3/4 前置条件均已完成**：`toStoragePlan({Map<String, double>? weights})` 已实现，`plan_weight_confirm_page.dart` 已创建，`/plan-weight-confirm` 路由已注册
- **未做任何适配改动** — 当前代码与计划预期完全匹配

## 测试结果

| 命令 | 结果 |
|------|------|
| `flutter analyze lib/pages/plan_library_detail_page.dart` | No issues found |
| `flutter test test/weight_recommendation_service_test.dart test/plan_adopt_bug_test.dart` | 17/17 ALL PASS |

## 变更文件

- `lib/pages/plan_library_detail_page.dart` — `_adoptPlan` 方法：增加重量确认页跳转，`toStoragePlan` 调用传入 `weights` 参数

## 自审发现

- 无问题。方法简短明了，重量确认页取消时 `weights == null` 直接 return，不执行任何副作用
- 无关文件（`daily_reminder_service.dart`、`platform_utils.dart`）未改动
- 仅 `git add` 了本任务涉及的文件

## 问题与关注

无。