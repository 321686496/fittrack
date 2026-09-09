# 训练记录 UI 优化设计

日期：2026-09-09
涉及文件：`fittrack_flutter/lib/pages/records_page.dart`、`fittrack_flutter/lib/pages/record_detail_page.dart`

## 背景

用户反馈三个问题：
1. 训练记录列表卡片 UI 需要优化
2. 详情页训练动作卡片看不到动作名称与汇总信息
3. 详情页需要一个可视化图表卡片

## Bug 根因：动作名称不显示

`record_detail_page.dart` 中动作名称仅从 `MockData.exercises`（内置 e1~e21）反查。
自定义动作（id 形如 `customex_xxx`）与计划内嵌动作名查不到，卡片头部直接渲染原始 id 字符串，
用户侧表现为"看不到动作名称"。同时动作卡片只有「N组」+ 逐组数据，没有任何汇总信息。

修复：建立三级名称反查链——
1. `Storage.getCustomExercises()`（自定义动作库）
2. `Storage.getPlans()` → `days[].exercises` 内嵌 `{id, name}`（覆盖已删除的自定义动作残留 id）
3. `MockData.exercises`（内置动作）

全部未命中时显示「未知动作」，不再显示原始 id。

## 方案

### 1. 列表卡片（records_page.dart `_buildRecordCard`）

- 统计区改为 **2×2 网格**：时长 / 组数 / 重量 / 动作数（新增动作数 stat），
  每格 icon + 数值 + label，浅色分隔线，紧凑边距
- 移除底部「查看详情」提示行；标题行右侧加 chevron 暗示可点击
- 保留 CardWidget、主题色（LiftTrackColors）、删除按钮交互不变

### 2. 详情页动作卡片（record_detail_page.dart `_buildExerciseDetailCard`）

- 头部：动作图标 + 名称（修复后）+「N组」徽章，样式沿用现有头部结构
- **新增汇总行**（头部下方、逐组列表上方）：
  - 总容量 = Σ(weight × reps)
  - 最重组 = max(weight) × 该组 reps（显示为「60kg×8」形式）
  - 总次数 = Σ(reps)
  - 布局：三列等分（数量少、数值短，三列比两列更整齐；超长自动省略）
- 逐组列表保持现有结构，样式微调对齐

### 3. 可视化图表卡片（详情页新增）

位置：训练概要卡片之后、训练动作列表之前。

- 标题「容量分析」+ 右侧本次总容量合计（如「3,240kg」）
- 内容：各动作总容量柱状图，fl_chart `BarChart`（项目已有依赖 0.61.0，
  复用 gym_card_stats_page.dart 的使用模式，不引新库）
- X 轴：动作名（超 4 字截断为「首4字…」），柱体 `accentGlow`
- Y 轴显示容量刻度；点击柱体 tooltip 显示完整动作名与容量（fl_chart 0.61 不支持柱顶内置数值标签，以 Y 轴刻度替代）
- 数据来自 `setRecords` 逐动作计算容量；≤1 个动作或无有效数据时隐藏卡片

### 4. 数据流

```
record['setRecords'] : Map<动作id, List<{weight, reps, set?, rest?}>>
  → 名称：三级反查链
  → 汇总：per-exercise volume / best set / total reps
  → 图表：List<{name, volume}> 传入 BarChart
```

## 错误处理

- setRecords 为空 / 全部空组：隐藏「训练动作」区与图表卡片（沿用现有 isNotEmpty 判断）
- weight/reps 为 null：按 0 参与计算（沿用现有 `as num? ?? 0` 模式）
- 名称未命中任何来源：显示「未知动作」

## 验证

- `flutter analyze` 无新增告警
- 手动验证：含自定义动作的训练记录详情页名称正常显示、汇总行与图表数值正确
- 列表卡片 2×2 网格在窄屏（320dp 逻辑宽度）不溢出

## 范围

仅修改两个页面文件，不改数据层、不改其他页面。
