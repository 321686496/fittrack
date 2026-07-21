# App 批量优化设计规范

> 日期：2026-07-21
> 范围：13 项 UI/功能优化与新功能（分享系统统一、Toast 统一、最大重量卡片等）
> 实施方式：subagent-driven-development，一次性实施全部 13 项

## 目标

修复用户反馈的 13 项问题，覆盖 UI 对齐、列表显示、分享系统、新功能、Toast 统一五个工作流。所有改动在同一批次内完成并通过 `flutter analyze` 验证。

## 全局约束

- **Dart SDK**：`>=2.19.6 <3.0.0`（禁止 Dart 3+ records / patterns / switch 表达式）
- **Flutter**：3.7.12-ohos（OHOS fork），禁止 `SliverList.separated`、`state.pathParameters`，使用 `state.params`
- **平台判断**：统一使用 `lib/utils/platform_utils.dart` 的 `isOhos` getter，不直接用 `Platform.isOhos`
- **主题扩展**：`lib/themes/app_themes.dart`（复数）的 `FitTrackColors`，字段 `bgCard/bgSecondary/bgElevated/borderColor/accentGlow/textPrimary/textSecondary/textMuted/successColor/warningColor/purpleColor/infoColor/accentSecondary`
- **页面头部组件**：所有新页面/重构页面统一使用 `lib/widgets/page_header.dart` 的 `PageHeader`，不用 Material `AppBar`
- **路由**：跳转到详情/子页面用 `context.push()`（可返回），仅 tab 切换/采用计划后跳转用 `context.go()`
- **自定义 UI 组件**：`lib/widgets/common_widgets.dart` 已有 `FitToast`、`ConfirmDialog`、`InfoDialog`、`CardWidget`、`DividerWidget`、`FitBottomSheet`
- **现有分享模式**：`lib/widgets/note_poster.dart` 与 `lib/services/share_card_service.dart` 使用 `RepaintBoundary` + `toImage(pixelRatio: 3.0)` + `Share.shareXFiles` 模式，本次复用

---

## 工作流 A：UI 对齐与排版修复

### A1. 训练活跃度卡片 Overflow 修复（任务 2）

**文件**：`lib/pages/stats_page.dart` 方法 `_buildHeatmap`（行 594-805）

**问题**：月份标签 `Positioned` + `clipBehavior: Clip.none` 在小屏机型可能溢出 Stack 边界；嵌套 `Row > Column > Row` 在窄屏可能溢出。

**修复方案**：
1. 用 `LayoutBuilder` 包裹整个 Row 主体，基于 `constraints.maxWidth` 重新计算 `cellSize` 与 `gridWidth`
2. 月份标签外层加 `ClipRect`，防止 `Positioned` 子项溢出 Stack
3. 整个 Row 主体用 `SingleChildScrollView(scrollDirection: Axis.horizontal)` 包裹兜底（仅当宽度不足时启用滚动）
4. 删除 `clipBehavior: Clip.none`，改为默认 `Clip.hardEdge`

### A2. 首页 banner 与其他卡片对齐（任务 3）

**文件**：`lib/widgets/recommendation_banner.dart` 行 46-47

**问题**：banner 自身 `EdgeInsets.symmetric(horizontal: 16)` + 父级 `home_page.dart` 行 344 `padding: EdgeInsets.all(16)` = 双重 32px 边距，与其他卡片（仅 16px）不对齐。

**修复方案**：删除 `recommendation_banner.dart` 行 46-47 的 `Padding` 包装，让 banner 直接占据父级给的 16px 边距内宽度。banner 内部 margin 改为 `EdgeInsets.symmetric(horizontal: 0)`（保留 4px 改为 0）。

### A3. 计划页推荐卡片对齐（任务 3）

**文件**：`lib/pages/plan_page.dart` 方法 `_buildRecommendedSection`（行 340-398）

**问题**：父级 padding 16 + 推荐区段自身 `padding/margin: horizontal: 16` = 32px 边距，比上方区段多 16px。

**修复方案**：
- 行 351-352 标题行 padding 改为 `EdgeInsets.fromLTRB(0, 24, 0, 12)`
- 行 381 "浏览系统计划库"按钮 padding 改为 `EdgeInsets.symmetric(vertical: 12)`
- 行 407-408 推荐卡片 margin 改为 `EdgeInsets.symmetric(vertical: 6)`

### A4. 创建计划页推荐移至底部（任务 4）

**文件**：`lib/pages/add_plan_page.dart` 行 179-198

**问题**：当前"为你推荐"在顶部，自定义表单在下，与用户习惯相反。

**修复方案**：将行 179-198 的推荐区段整体移动到保存按钮（行 294-301）之前。调整顺序为：
1. "或自定义计划" 标题
2. 计划表单
3. Divider
4. "为你推荐" 区段（含推荐卡片列表）
5. 保存按钮

### A5. 个人信息卡片重设计（任务 6）

**文件**：`lib/pages/profile_page.dart` 方法 `_buildProfileHeader`（行 327-431）

**用户反馈**："目前的个人信息卡片看起来太卡通了，没有任何设计感"

**重设计方向**：去掉卡通感（如 emoji、过强的渐变），参考 Apple Fitness / Strava / Nike Training Club 的克制设计语言。

**新布局**：
```
┌─────────────────────────────────────────────┐
│ [头像48] 用户名                    编辑图标  │
│         副标题 · 已坚持训练 X 天              │
│                                              │
│ ──────── 数据带（三列分隔）─────────         │
│ 累计获得    消耗    连续打卡                  │
│ 1,234      500     12 天                     │
└─────────────────────────────────────────────┘

┌──── 积分独立卡 ────┐
│ 1,234    积分 →   │
└───────────────────┘
```

**设计要点**：
1. 头像缩至 48px（原 56），无装饰边框
2. 卡片背景：单色 `bgCard` + 1px `borderColor` 描边（删除渐变）
3. 用户名 16号 semibold + 副标题 12号 textSecondary
4. 数据带：三列分隔（累计获得 / 消耗 / 连续打卡天数），用细竖线分隔
5. 积分单独成卡：放在个人信息卡下方，右侧 chevron_right 进入积分明细页
6. 字号统一：标题 16 / 副标题 12 / 数字 16 semibold / 标签 11

### A6. 身体数据卡片重排版 + 趋势标识（任务 9）

**文件**：`lib/pages/profile_page.dart` 方法 `_buildBodyData`（行 910-997）

**问题**：当前 4 列网格信息密度过高，无趋势对比。

**重排版方案**：
1. 改为 3 列布局（原 4 列），每项更宽敞
2. 每个字段下方增加趋势箭头：
   - 调用 `Storage.getBodyDataHistory()` 取倒数第二条记录
   - 对比当前值与上一次值，差值 > 0 显示 ↑（红色，体重/体脂上升为负向），< 0 显示 ↓（绿色），= 0 不显示
   - BMI / 心率不显示趋势（这两个本身是衍生值或瞬时值）
   - 趋势箭头字号 11，颜色 successColor（正向）或 warningColor（负向）
3. 字段顺序调整：身高 → 体重 → BMI → 体脂率 → 胸围 → 腰围 → 臀围 → 上臂围 → 大腿围 → 目标体重 → 静息心率
4. 卡片右上角增加"更新时间"小字（取 `body['lastUpdate']`）

**趋势逻辑**：
- 体重/体脂率/胸围/腰围/臀围/上臂围/大腿围：下降为正向（绿色 ↓），上升为负向（红色 ↑）
- 目标体重：根据方向判断（用户目标是减重则下降正向，增重则上升正向），简单起见统一不显示
- 静息心率：下降为正向（绿色 ↓）
- 身高：不显示趋势

---

## 工作流 B：列表显示与排序

### B1. 教学中心页只显示推荐 + 完整列表入口（任务 5）

**文件**：`lib/pages/tutorial_list_page.dart`

**问题**：当前页混合了推荐横滑区段 + 系统化课程 + 动作教学三块，信息量大。

**改造方案**：
1. 教学中心页保留：
   - "为你推荐"横滑区段（行 41-46）：只显示前 3 项
   - "系统化课程"区段（行 51-53）：只显示前 2 项
   - "动作教学"区段（行 56-58）：只显示前 4 项
   - 底部新增"查看全部教学"按钮（OutlinedButton，跳转 `/all-tutorials`）
2. 新增 `lib/pages/all_tutorials_page.dart`：
   - `PageHeader(title: '全部教学', onBack: Navigator.pop)`
   - 顶部肌群筛选 Chip
   - 完整系统化课程列表
   - 完整动作教学列表
   - 复用 `tutorial_list_page.dart` 中的卡片样式
3. `router.dart` 新增路由 `/all-tutorials` → `AllTutorialsPage()`

### B2. 荣誉墙显示所有徽章（任务 7）

**文件**：`lib/pages/honor_wall_page.dart`

**问题**：当前只显示 `_unlocked`（行 21-23），未解锁的完全不显示。

**改造方案**：
1. 行 21-23 改为：`_all = AchievementService.instance.getAll();`，分别取 `_unlocked` 与 `_locked`
2. 顶部统计卡：已解锁 X / 总数 Y
3. "最近解锁"大展示：保持不变（仅 `_unlocked.isNotEmpty` 时显示）
4. 荣誉墙网格显示全部徽章：
   - 已解锁：彩色徽章 + 标题 + 解锁日期
   - 未解锁：灰度显示（`ColorFiltered` 灰度矩阵）+ `Icons.lock` 覆盖 + 标题 + "未解锁"
5. 点击未解锁徽章：弹出 `InfoDialog` 显示解锁条件（如"完成 10 次训练"）
6. 网格内排序：已解锁按解锁时间倒序，未解锁按原始顺序排在已解锁之后

### B3. 成就墙按解锁状态优先排序（任务 8）

**文件**：`lib/pages/achievement_page.dart`

**问题**：当前按 category 分组，组内不排序。

**改造方案**：
1. 行 82-87 分组逻辑保留，但每组内排序：
   - 已解锁排前，按 `unlockedAt` 倒序
   - 未解锁排后，按原始顺序
2. 已解锁成就项右上角显示 `unlockedAt` 相对时间（如"3 天前"），用 `timeago` 风格文案
3. 已解锁图标容器背景改为 `accentGlow.withOpacity(0.15)`，未解锁保持 `borderColor.withOpacity(0.3)`

### B4. 删除"动作教学"菜单项（任务 12）

**文件**：`lib/pages/profile_page.dart` 行 1112

**操作**：从 `_menuItems` List 中删除 `{'icon': Icons.school_outlined, 'label': '动作教学', 'page': 'tutorial'}` 项。

**注意**：路由 `/tutorial` 保留（教学中心页仍可通过其他入口访问），只删除我的页菜单项。

---

## 工作流 C：分享系统统一

### C1. 引入 image_gallery_saver 插件

**pubspec.yaml**：新增 `image_gallery_saver: ^2.0.3`（兼容 Flutter 3.7.12 + Dart 2.x）

**Android 权限**：`android/app/src/main/AndroidManifest.xml` 新增：
```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
```

**OHOS 兼容**：image_gallery_saver 在 OHOS 平台不支持，调用时通过 `isOhos` 判断降级为保存到沙盒 + FitToast 提示路径。

### C2. PosterPreviewDialog 统一弹窗组件

**新增文件**：`lib/widgets/poster_preview_dialog.dart`

**功能**：弹窗显示生成的海报图片预览，底部两个操作按钮：
- "保存到相册"：调用 `ImageGallerySaver.saveFile(imagePath)`，成功后 `FitToast.success`
- "分享到平台"：调用 `Share.shareXFiles([XFile(imagePath)])` 调起系统分享 sheet

**API**：
```dart
class PosterPreviewDialog {
  /// 显示海报预览弹窗
  /// [imagePath] 已生成的海报 PNG 文件路径
  /// [title] 弹窗标题（如"训练笔记海报"）
  static Future<void> show(BuildContext context, {
    required String imagePath,
    required String title,
  });
}
```

**实现要点**：
- 使用 `showDialog` + `Dialog`（insetPadding: 0，让弹窗接近全屏）
- 海报图片用 `Image.file(File(imagePath))` 显示，宽度 80% 屏宽，高度自适应
- 顶部标题 + 关闭按钮
- 底部 Row：两个 Expanded 按钮（保存 / 分享），中间 12 间距
- OHOS 平台"保存到相册"按钮文案改为"保存到本地"，调用 `File.copy` 到 `getTemporaryDirectory()`

### C3. 五类海报模板

#### C3.1 邀请码海报（新增）

**新增文件**：`lib/widgets/invite_poster.dart`

**模板内容**（9:16 竖版，1080×1920）：
- 顶部品牌区：FitTrack 燃力 logo 文字
- 中间大字：邀请码 `FIT-INV-XXXXXX`（高亮显示）
- 下方说明文字："扫码加入 FitTrack，与我一起训练"
- 底部二维码：`qr_flutter` 生成 `fittrack://invite?code=FIT-INV-XXXXXX`
- 装饰：左下/右上点缀色块

**集成点**：`lib/pages/invitation_page.dart` 行 191-197 `_shareCode()` 改为：
1. 通过 `RepaintBoundary` 渲染 `InvitePoster` 到 PNG
2. 调用 `PosterPreviewDialog.show(imagePath: ..., title: '邀请码海报')`

#### C3.2 笔记海报（已有，统一改造）

**文件**：`lib/widgets/note_poster.dart`

**当前状态**：已能生成 PNG 海报，但流程是"页面内预览 + 立即分享按钮"，未走 PosterPreviewDialog。

**改造**：
1. `NotePosterPage` 改为内部直接生成 PNG（onInit 触发）
2. 生成后调用 `PosterPreviewDialog.show(imagePath: ..., title: '训练笔记海报')`
3. 删除当前页面内的"立即分享"和"保存图片"按钮
4. `NotePosterContent` widget 保留作为海报模板渲染

#### C3.3 动作分享海报（新增）

**新增文件**：`lib/widgets/tutorial_poster.dart`

**模板内容**（9:16 竖版）：
- 顶部动作名 + 副标题（教练名）
- 中间动作示意图（暂用动作 emoji + 渐变背景占位，未来可扩展为真实动作图）
- 下方动作要点（3-4 条）
- 底部二维码 + "扫码查看完整动作教学"

**集成点**：`lib/widgets/tutorial_share_card.dart` 行 105-119 "立即分享"按钮改为：
1. 通过 `RepaintBoundary` 渲染 `TutorialPoster` 到 PNG
2. 调用 `PosterPreviewDialog.show(imagePath: ..., title: '动作分享海报')`
3. 删除当前 `_shareText(t)` 纯文本分享逻辑

#### C3.4 健身卡进度海报（新增）

**新增文件**：`lib/widgets/gym_card_poster.dart`

**模板内容**（9:16 竖版，进度海报样式）：
- 顶部标题："我在 X 健身房坚持训练"
- 大数字：坚持天数 / 剩余天数
- 中间进度条（圆形或线性）
- 下方健身房名称 + 卡类型
- 底部品牌 + 二维码（App 下载入口）

**集成点**：`lib/pages/gym_card_page.dart` 新增分享按钮（卡片右上角 `Icons.share_outlined`），点击：
1. 通过 `RepaintBoundary` 渲染 `GymCardPoster` 到 PNG
2. 调用 `PosterPreviewDialog.show(imagePath: ..., title: '健身卡海报')`

#### C3.5 训练记录海报（已有，统一改造）

**文件**：`lib/services/share_card_service.dart` + `lib/widgets/share_card_frame.dart`

**当前状态**：已能生成 PNG 并通过 `Share.shareXFiles` 分享，未走 PosterPreviewDialog。

**改造**：
1. `ShareCardService.generateShareCard()` 返回 imagePath（已经是）
2. `lib/pages/training_page.dart` 行 597-622 `_shareTrainingCard()` 改为：
   - 生成 PNG
   - 调用 `PosterPreviewDialog.show(imagePath: ..., title: '训练记录海报')`
3. 删除直接调用 `ShareCardService.shareImage()`

### C4. 海报生成通用工具

**新增文件**：`lib/services/poster_generator.dart`

**功能**：封装 `RepaintBoundary` 截图通用逻辑，避免每个海报重复实现。

**API**：
```dart
class PosterGenerator {
  /// 通过 RepaintBoundary key 截取 widget 为 PNG
  /// [boundaryKey] 包裹海报的 RepaintBoundary 的 key
  /// 返回 PNG 文件路径
  static Future<String> capture(GlobalKey boundaryKey, {
    double pixelRatio = 3.0,
    String fileNamePrefix = 'fittrack_poster',
  });
}
```

**实现**：复用 `note_poster.dart` 行 378-393 的逻辑，提取到独立服务。

---

## 工作流 D：最大重量卡片（任务 11）

### D1. MaxWeightService 数据服务

**新增文件**：`lib/services/max_weight_service.dart`

**功能**：扫描训练记录，按动作汇总历史最大重量。

**API**：
```dart
class MaxWeightService {
  static final MaxWeightService instance = MaxWeightService._();

  /// 获取全局最大重量（kg）
  /// 扫描 Storage.getRecords() 中所有 exercises[].sets[].weight
  /// 返回 MaxWeightRecord?（null 表示无记录）
  MaxWeightRecord? getGlobalMax();

  /// 按部位分组获取 Top 5 动作最大重量
  /// 部位分类：chest / back / legs / shoulders / arms / core / other
  Map<String, List<MaxWeightRecord>> getTopByMuscleGroup({int limit = 5});
}

class MaxWeightRecord {
  final String exerciseName;
  final double weight;  // kg
  final String muscleGroup;
  final DateTime date;
  final String? recordId;
}
```

**部位推断**：复用 `lib/data/exercise_library.dart` 中动作的 `muscleGroup` 字段；若动作不在库中，根据动作名关键字推断（"卧推"→chest，"硬拉"/"划船"→back 等）。

### D2. 趣味对比文案

**新增文件**：`lib/data/weight_comparisons.dart`

**对比阈值表**（按重量区间）：
```dart
const List<WeightComparison> kWeightComparisons = [
  WeightComparison(minKg: 0, maxKg: 20, label: '一只小猫', emoji: '🐱'),
  WeightComparison(minKg: 20, maxKg: 50, label: '一袋大米', emoji: '🍚'),
  WeightComparison(minKg: 50, maxKg: 80, label: '一个成年人', emoji: '🧑'),
  WeightComparison(minKg: 80, maxKg: 120, label: '一只成年猩猩', emoji: '🦍'),
  WeightComparison(minKg: 120, maxKg: 180, label: '一只熊猫', emoji: '🐼'),
  WeightComparison(minKg: 180, maxKg: 250, label: '一辆摩托车', emoji: '🏍️'),
  WeightComparison(minKg: 250, maxKg: 400, label: '一头牛', emoji: '🐂'),
  WeightComparison(minKg: 400, maxKg: 600, label: '一匹马', emoji: '🐎'),
  WeightComparison(minKg: 600, maxKg: 1000, label: '一辆小汽车', emoji: '🚗'),
  WeightComparison(minKg: 1000, maxKg: 1500, label: '一头大象幼崽', emoji: '🐘'),
  WeightComparison(minKg: 1500, maxKg: double.infinity, label: '一辆小货车', emoji: '🚚'),
];

class WeightComparison {
  final double minKg;
  final double maxKg;
  final String label;
  final String emoji;
  const WeightComparison({...);
  static WeightComparison forWeight(double kg);
}
```

### D3. MaxWeightCard 组件

**新增文件**：`lib/widgets/max_weight_card.dart`

**布局**：
```
┌─────────────────────────────────────────┐
│ [Icons.fitness_center] 举起最大重量   → │
│                                          │
│         150 kg                          │
│         🦍 相当于一只成年猩猩             │
│                                          │
│  最近一次：卧推 · 3 天前                  │
└─────────────────────────────────────────┘
```

**要点**：
- 卡片整体可点击，跳转 `/max-weight-detail`
- 标题图标用 `Icons.fitness_center`（Material Icons，非 emoji）
- 大数字 32号 bold accentGlow
- 趣味对比 emoji + label 14号 textSecondary（此处 emoji 为内容数据，非 UI 装饰图标，保留）
- 底部小字 12号 textMuted
- 无训练记录时显示空状态："开始训练记录你的最大重量"

### D4. MaxWeightDetailPage 详情页

**新增文件**：`lib/pages/max_weight_detail_page.dart`

**布局**：
- PageHeader(title: '最大重量纪录', onBack: Navigator.pop)
- 顶部总览卡片：全局最大重量 + 趣味对比
- 按部位分组的 Top 5 动作列表：
  - 胸部 / 背部 / 腿部 / 肩膀 / 手臂 / 核心
  - 每组：SectionHeader + 排序后的动作卡片列表
  - 单个动作卡片：动作名 + 最大重量 + 创纪录日期
- 路由：`/max-weight-detail` → `MaxWeightDetailPage()`

### D5. 集成到我的页

**文件**：`lib/pages/profile_page.dart`

**插入位置**：身体数据卡片下方、菜单列表上方。

**逻辑**：
```dart
// 在 _buildBodyData 后插入
MaxWeightCard(onTap: () => context.push('/max-weight-detail')),
```

---

## 工作流 E：Toast/弹窗统一（任务 13）

### E1. 扫描与替换规则

**目标**：全项目替换 `ScaffoldMessenger.showSnackBar(SnackBar(...))` 和 `showDialog(... AlertDialog ...)`。

**替换映射**：

| 原调用 | 替换为 | 备注 |
|---|---|---|
| `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('成功...')))` | `FitToast.success(context, '成功...')` | |
| `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('失败...')))` | `FitToast.error(context, '失败...')` | |
| `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('提示...')))` | `FitToast.info(context, '提示...')` | |
| `showDialog(context: ..., builder: ... AlertDialog(...)` with actions | `ConfirmDialog.show(...)` | 双按钮确认弹窗 |
| `showDialog(context: ..., builder: ... AlertDialog(...)` 单按钮 | `InfoDialog.show(...)` | 单按钮信息弹窗 |

### E2. 服务层处理

**原则**：服务层中已传入 `BuildContext` 的 SnackBar 调用，就地改为 `FitToast.xxx(context, ...)`，不改架构。

**涉及文件**：
- `lib/services/share_card_service.dart`
- `lib/services/plan_unlock_service.dart`
- `lib/services/share_code_service.dart`
- `lib/services/points_service.dart`
- 其他 services/*.dart 中的 `ScaffoldMessenger` 调用

### E3. 特殊保留场景

以下场景**保留原调用**，不替换：
1. `note_edit_page.dart` 行 676-722 保存笔记后的 `AlertDialog`（询问是否生成海报）：改为 `ConfirmDialog.show`
2. 任何使用 `showModalBottomSheet` 的底部弹层：保留，不在本次范围
3. `CelebrationDialog` / `AchievementDialog` 等已自定义的弹窗：保留

### E4. FitToast API 扩展

**文件**：`lib/widgets/common_widgets.dart` 行 392-429

**现有 API**：`FitToast.show(context, message, type)` + `FitToast.success/info/error/warning`

**新增 API**（若现有不支持，需补充）：
```dart
// 已有，无需新增。确认 FitToast 提供 success/error/info/warning 四种快捷方法。
```

---

## 文件清单汇总

### 新增文件（11 个）

1. `lib/widgets/poster_preview_dialog.dart` - 海报预览统一弹窗
2. `lib/services/poster_generator.dart` - 海报截图通用服务
3. `lib/widgets/invite_poster.dart` - 邀请码海报模板
4. `lib/widgets/tutorial_poster.dart` - 动作分享海报模板
5. `lib/widgets/gym_card_poster.dart` - 健身卡进度海报模板
6. `lib/pages/all_tutorials_page.dart` - 全部教学列表页
7. `lib/services/max_weight_service.dart` - 最大重量数据服务
8. `lib/data/weight_comparisons.dart` - 趣味对比阈值表
9. `lib/widgets/max_weight_card.dart` - 最大重量卡片
10. `lib/pages/max_weight_detail_page.dart` - 最大重量详情页
11. （可选）`lib/widgets/_poster_templates/` - 海报模板共用组件

### 修改文件（约 20 个）

**工作流 A**：
- `lib/pages/stats_page.dart` - 训练活跃度 Overflow 修复
- `lib/widgets/recommendation_banner.dart` - 删除内部 padding
- `lib/pages/plan_page.dart` - 推荐区段对齐
- `lib/pages/add_plan_page.dart` - 推荐移至底部
- `lib/pages/profile_page.dart` - 个人信息卡 + 身体数据重排版 + 删除动作教学项 + 插入最大重量卡

**工作流 B**：
- `lib/pages/tutorial_list_page.dart` - 只显示推荐 + 入口
- `lib/pages/honor_wall_page.dart` - 显示全部徽章
- `lib/pages/achievement_page.dart` - 排序优化
- `lib/router.dart` - 新增 `/all-tutorials` 与 `/max-weight-detail` 路由

**工作流 C**：
- `lib/pages/invitation_page.dart` - 邀请码分享改海报
- `lib/widgets/note_poster.dart` - 笔记分享走 PosterPreviewDialog
- `lib/widgets/tutorial_share_card.dart` - 动作分享改海报
- `lib/pages/gym_card_page.dart` - 新增健身卡分享按钮
- `lib/pages/training_page.dart` - 训练记录分享走 PosterPreviewDialog
- `lib/services/share_card_service.dart` - 调整 API
- `pubspec.yaml` - 新增 image_gallery_saver
- `android/app/src/main/AndroidManifest.xml` - 新增存储权限

**工作流 D**：
- `lib/pages/profile_page.dart` - 插入 MaxWeightCard（与工作流 A 同文件）

**工作流 E**：
- 约 15-20 个文件中的 SnackBar/AlertDialog 替换为 FitToast/ConfirmDialog/InfoDialog（具体清单实施时扫描确定）

---

## 风险与缓解

1. **image_gallery_saver 插件兼容性**
   - 风险：插件可能不兼容 Flutter 3.7.12-ohos 或 Dart 2.x
   - 缓解：先在 pubspec.yaml 引入并 `flutter pub get` 验证；若失败，降级为 `gal` 或 `share_plus` 分享 sheet 模式

2. **Toast 全项目替换回归风险**
   - 风险：30-50 处替换可能引入行为变化（如 FitToast 不支持 context 失效场景）
   - 缓解：每替换一个文件后 `flutter analyze` 验证；关键页面手动运行验证

3. **海报模板独立设计工作量大**
   - 风险：5 个海报模板 + PosterPreviewDialog + PosterGenerator 共约 1500 行代码
   - 缓解：海报模板复用 NotePoster 和 ShareCardFrame 的布局组件（品牌头/二维码尾/装饰）

4. **个人信息卡重设计需视觉迭代**
   - 风险：用户反馈"太卡通"较主观，可能需要 2-3 轮调整
   - 缓解：参考 Apple Fitness 风格做克制设计，避免渐变和 emoji；实施后让用户预览再调整

5. **OHOS 平台海报保存降级**
   - 风险：image_gallery_saver 不支持 OHOS，需平台判断
   - 缓解：`isOhos` 判断，降级为 `File.copy` 到 `getTemporaryDirectory()` + FitToast 提示路径

---

## 验证清单

实施完成后需通过：
1. `flutter analyze` 全项目零 error
2. 手动验证：
   - 5 个分享入口（邀请码/笔记/动作/健身卡/训练记录）都能生成海报并弹出预览弹窗
   - 海报预览弹窗的"保存到相册"和"分享"按钮都能正常工作
   - 训练活跃度卡片在不同屏幕宽度下不溢出
   - 首页 banner 与其他卡片左右对齐
   - 计划页推荐卡片与其他卡片对齐
   - 创建计划页推荐在最底部
   - 教学中心页底部"查看全部教学"按钮可跳转
   - 荣誉墙显示所有徽章，未解锁灰显
   - 成就墙已解锁优先排序
   - 我的页无"动作教学"菜单项
   - 我的页个人信息卡看起来不卡通
   - 身体数据卡片显示趋势箭头
   - 最大重量卡片显示趣味对比
   - 点击最大重量卡片进入详情页
   - 全项目无 `ScaffoldMessenger.showSnackBar` 调用（除特殊保留场景）
