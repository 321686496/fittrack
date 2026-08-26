# OnboardingCoach 首次引导流程完善设计

## 1. 背景与问题

### 1.1 现状流程

首次使用 App 且无任何数据时，首页会弹出 `OnboardingCoach` 引导弹窗（见 [home_page.dart](../../../fittrack_flutter/lib/pages/home_page.dart) 的 `_maybeShowCoach`）：

1. 第 0 步：询问「今天练什么部位？」（胸/背/腿/肩/手臂/核心）
2. 用户选择部位 → 点击「下一步」
3. 第 1 步：展示「为你推荐 3 个动作」（根据所选部位从 `MockData.exercises` 匹配）
4. 用户点击「开始记录」→ 仅设置 `onboardingV2Done = true` 并关闭弹窗

### 1.2 问题

第 1 步展示推荐动作后，点击「开始记录」**没有任何实际后续**：

- 没有创建训练计划
- 没有开始任何训练
- 用户选完部位、看完推荐后就回到空首页，流程中断

这是不合理的——引导用户做出选择，却没有产生任何结果。

## 2. 目标

完善首次引导流程，使其形成闭环：

**选部位 → 看推荐动作 → 一键创建临时计划并开始训练 → 训练完保存记录 → 计划可在「计划」页管理**

## 3. 设计方案

### 3.1 OnboardingCoach 内部改造（`fittrack_flutter/lib/widgets/onboarding_coach.dart`）

- 第 1 步按钮「开始记录」文案改为「开始训练」
- 点击「开始训练」后执行 `_startTraining()`（改为异步）：
  1. 根据所选部位 + 推荐的 3 个动作构建临时单日计划
  2. 遵循项目现有模式（参考 `plan_recommend_page.dart` `_selectPlan`）：先暂停其他 active 计划，再 `await Storage.addPlanAsync(plan)` 保存
  3. 设置 `settings['onboardingV2Done'] = true` 并保存
  4. 通过回调 `widget.onComplete(plan)` 把新创建的计划返回给首页
- 保存失败时：弹 toast 提示「创建计划失败，请重试」，弹窗不关闭，用户可重试或返回
- 「跳过」按钮行为保持不变（标记完成、关闭弹窗、不创建计划）

#### 临时计划数据结构

与现有 `add_plan_page.dart` / `system_plan_library.dart` 的 plan 格式完全兼容：

```dart
{
  'name': '胸部训练',                // '<部位名>训练'，部位名用完整分类（如「胸部」而非「胸」）
  'type': '自定义',
  'frequency': '1天/周',
  'difficulty': '入门',
  'gender': 'all',
  'totalWeeks': 1,
  'defaultRestTime': 90,
  'days': [
    {
      'day': 1,
      'label': '胸部训练',
      'muscle': '胸部',               // 完整分类名
      'exercises': [
        {'id': 'e1', 'name': '杠铃卧推', 'sets': 3, 'reps': '10-12', 'restTime': 90},
        // ...共 3 个推荐动作
      ],
    },
  ],
  'currentDayIndex': 0,
  'week': 0,
  'progress': 0,
  'status': 'active',
  'badge': '进行中',
  'isOnboardingPlan': 1,             // 标记为引导创建，便于后续识别
}
```

说明：

- `MockData.exercises` 中动作只有 `id/name/category/equip/image`，没有组数/次数/休息时间，因此生成计划时为每个动作补充默认值：`sets=3`、`reps='10-12'`、`restTime=90`
- 不预填重量（`weight` 缺省）。训练页 `_prefillWeightReps` 对无重量动作会留空让用户填写，符合新手第一次训练场景
- `id` 由 `Storage.addPlanAsync` 自动生成（`plan['id'] ?? generateId('plan')`）

### 3.2 首页衔接（`fittrack_flutter/lib/pages/home_page.dart`）

- `OnboardingCoach.onComplete` 回调签名从 `VoidCallback` 改为 `void Function(Map<String, dynamic> plan)`（有创建计划才回调，跳过/异常不触发）
- `_maybeShowCoach` 中 `onComplete` 改为：
  1. `Navigator.pop(context)` 关闭弹窗
  2. 弹 toast「已为你创建「胸部训练」计划，开始训练吧！」
  3. `context.push('/training?planId=<新计划ID>&dayIndex=0)` 直接进入训练页
- `onSkip` 行为保持不变

### 3.3 兼容性

- 临时计划保存后会自动出现在「计划」页，用户可编辑/暂停/删除或创建更完整计划
- 训练完成后按现有逻辑保存训练记录、更新计划 `currentDayIndex`
- 不影响问卷/推荐计划主流程（`/onboarding → /questionnaire → /recommend → /home`）

## 4. 测试

更新 `fittrack_flutter/test/onboarding_coach_test.dart`：

1. 第 0 步渲染「今天练什么部位？」（已有用例保留）
2. 选择部位并点击「下一步」后显示「为你推荐 3 个动作」
3. 点击「开始训练」后：
   - 触发 `onComplete` 回调且传入的计划含 3 个动作、名称含所选部位
   - 设置 `onboardingV2Done = true`
   - 调用 `Storage.addPlanAsync` 后 `Storage.getPlans()` 中存在新计划

## 5. 不在本次范围

- 不改动问卷流程、`PlanRecommendPage` 推荐计划流程
- 不做多训练日/多周临时计划
- 不增加动作次数/重量的智能推荐
