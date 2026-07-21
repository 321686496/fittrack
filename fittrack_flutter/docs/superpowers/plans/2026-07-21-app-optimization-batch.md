# App 批量优化实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完成 13 项 UI/功能优化（分享/对齐/列表/最大重量/Toast），分 7 个独立任务实施。

**Architecture:** 5 个工作流 → 7 个独立任务。分享体系：PosterGenerator 统一截图 → PosterPreviewDialog 统一预览 → image_gallery_saver 保存相册 + share_plus 调起分享。最大重量：MaxWeightService 扫描训练记录 → 趣味对比阈值表 → MaxWeightCard + 详情页。其他为现有页面的独立修改。

**Tech Stack:** Flutter 3.7.12, Dart >=2.19.6 <3.0.0, image_gallery_saver ^2.0.3, share_plus ^7.0.0

## Global Constraints

- Dart SDK `>=2.19.6 <3.0.0`：禁止 Dart 3+ records/patterns/switch 表达式。使用 if-else 替代 switch，class 替代 record 语法
- Flutter 3.7.12-ohos：禁止 `SliverList.separated`、`state.pathParameters`，使用 `state.params`
- 平台判断统一使用 `lib/utils/platform_utils.dart` 的 `isOhos` getter，不用 `Platform.isOhos`
- 主题：`lib/themes/app_themes.dart`（复数）的 `FitTrackColors`，字段：bgCard/bgSecondary/bgElevated/borderColor/accentGlow/textPrimary/textSecondary/textMuted/successColor/warningColor/purpleColor/infoColor/accentSecondary
- 页面头部用 `lib/widgets/page_header.dart` 的 `PageHeader`，不用 Material `AppBar`
- 路由跳转子页面用 `context.push()`（可返回），仅 tab 切换用 `context.go()`
- 自定义 UI 组件路径：`lib/widgets/common_widgets.dart`（FitToast/ConfirmDialog/InfoDialog/CardWidget/DividerWidget/FitBottomSheet）
- **所有新页面无需写测试文件**（项目无测试体系）
- **image_gallery_saver** 添加前先 `flutter pub add image_gallery_saver` 验证兼容性；若不兼容，降级为 `gal` 或直接用 share_plus 分享 sheet 模式

---
## 依赖关系图

```
Task 4 [实力页改造] ───┐
                       ├── 并行 Wave 1 ──┐
Task 5 [UI 对齐] ──────┤                │
                                         ├── 全部独立，可并行
Task 6 [列表/排序] ────┤                │
                                         │
Task 1 [分享基础设施] ──┘                │
       │                                 │
       ├── Task 2 [邀请码+笔记海报]       │
       └── Task 3 [动作+健身卡+训练记录]   │
                                         │
Task 7 [Toast 统一] ← 最后执行（依赖所有  │
                       文件最终版本）      │
```

---

### Task 1: 分享基础设施（PosterGenerator + PosterPreviewDialog + image_gallery_saver）

**Files:**
- Modify: `pubspec.yaml`（新增 image_gallery_saver）
- Modify: `android/app/src/main/AndroidManifest.xml`（存储权限）
- Create: `lib/services/poster_generator.dart`
- Create: `lib/widgets/poster_preview_dialog.dart`

**Produces:**
- `PosterGenerator.capture(key, {pixelRatio, fileNamePrefix}) → Future<String>`（返回 PNG 路径）
- `PosterPreviewDialog.show(context, {imagePath, title}) → void`

- [ ] **Step 1: 添加 image_gallery_saver 依赖**

Run: `cd fittrack_flutter && flutter pub add image_gallery_saver`

Expected: pubspec.yaml 自动添加 `image_gallery_saver: ^2.0.3`（或兼容版本）

如果报错，尝试手动写入：
```yaml
image_gallery_saver: ^2.0.3
```
然后 `flutter pub get`。

如果仍不兼容，报错后改用 `gal: ^2.0.0`。

- [ ] **Step 2: 添加 Android 存储权限**

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<!-- 在 <manifest> 内 <application> 之前添加： -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
```

- [ ] **Step 3: 创建 poster_generator.dart**

```dart
// lib/services/poster_generator.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class PosterGenerator {
  /// 通过 RepaintBoundary key 截取 widget 为 PNG
  /// 返回 PNG 文件绝对路径
  static Future<String> capture(GlobalKey boundaryKey, {
    double pixelRatio = 3.0,
    String fileNamePrefix = 'fittrack_poster',
  }) async {
    try {
      final boundary = boundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/${fileNamePrefix}_$timestamp.png');
      await file.writeAsBytes(pngBytes);
      return file.path;
    } catch (e) {
      rethrow;
    }
  }
}
```

- [ ] **Step 4: 创建 poster_preview_dialog.dart**

```dart
// lib/widgets/poster_preview_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../themes/app_themes.dart';
import '../utils/platform_utils.dart';
import '../widgets/common_widgets.dart';

class PosterPreviewDialog {
  static Future<void> show(BuildContext context, {
    required String imagePath,
    required String title,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final ft = Theme.of(ctx).extension<FitTrackColors>()!;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部：标题 + 关闭按钮
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
                decoration: BoxDecoration(
                  color: ft.bgCard,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: ft.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: ft.textSecondary),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              // 中间：海报图片预览（80% 宽度，高度自适应）
              ClipRRect(
                child: Image.file(
                  File(imagePath),
                  width: MediaQuery.of(ctx).size.width * 0.8,
                  fit: BoxFit.contain,
                ),
              ),
              // 底部：两个操作按钮
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: ft.bgCard,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _saveToGallery(ctx, imagePath, ft),
                        icon: Icon(Icons.download_rounded, color: ft.purpleColor),
                        label: Text(
                          isOhos ? '保存到本地' : '保存到相册',
                          style: TextStyle(color: ft.purpleColor),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: ft.purpleColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _shareToPlatform(ctx, imagePath),
                        icon: const Icon(Icons.share_rounded, color: Colors.white),
                        label: const Text('分享', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ft.purpleColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _saveToGallery(BuildContext ctx, String imagePath, FitTrackColors ft) async {
    try {
      if (isOhos) {
        final dir = await getTemporaryDirectory();
        final saved = await File(imagePath).copy(
          '${dir.path}/fittrack_saved_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        if (!ctx.mounted) return;
        FitToast.success(ctx, '海报已保存到：${saved.path}');
      } else {
        final result = await ImageGallerySaver.saveFile(imagePath);
        if (!ctx.mounted) return;
        if (result['isSuccess'] == true) {
          FitToast.success(ctx, '已保存到相册');
        } else {
          FitToast.error(ctx, '保存失败，请重试');
        }
      }
    } catch (e) {
      if (ctx.mounted) FitToast.error(ctx, '保存失败：$e');
    }
  }

  static Future<void> _shareToPlatform(BuildContext ctx, String imagePath) async {
    try {
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: 'FitTrack 燃力',
      );
    } catch (e) {
      if (ctx.mounted) FitToast.error(ctx, '分享失败：$e');
    }
  }
}
```

- [ ] **Step 5: 验证**

Run: `cd fittrack_flutter && flutter analyze lib/services/poster_generator.dart lib/widgets/poster_preview_dialog.dart`

Expected: No issues found（或仅 info 级别）

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml android/app/src/main/AndroidManifest.xml lib/services/poster_generator.dart lib/widgets/poster_preview_dialog.dart
git commit -m "feat: 分享基础设施 - PosterGenerator + PosterPreviewDialog + image_gallery_saver"
```

---

### Task 2: 邀请码海报 + 笔记海报改造

**Files:**
- Create: `lib/widgets/invite_poster.dart`
- Modify: `lib/pages/invitation_page.dart`（`_shareCode()` 改海报流程）
- Modify: `lib/pages/note_poster_page.dart`（生成 PNG → PosterPreviewDialog）
- Modify: `lib/widgets/note_poster.dart`（调整内容结构，PosterPreviewDialog 接管保存/分享按钮）

**Consumes:**
- `PosterGenerator.capture(key)` → Task 1
- `PosterPreviewDialog.show(context, {imagePath, title})` → Task 1

- [ ] **Step 1: 创建 invite_poster.dart**

```dart
// lib/widgets/invite_poster.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/poster_generator.dart';
import '../widgets/poster_preview_dialog.dart';

class InvitePoster extends StatelessWidget {
  final String inviteCode;
  final String deepLink;
  const InvitePoster({super.key, required this.inviteCode, required this.deepLink});

  static const double _posterWidth = 1080.0;
  static const double _posterHeight = 1920.0;

  @override
  Widget build(BuildContext context) {
    final ft = Theme.of(context).extension<FitTrackColors>()!;
    return RepaintBoundary(
      child: Container(
        width: _posterWidth,
        height: _posterHeight,
        padding: const EdgeInsets.all(60),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ft.accentGlow.withOpacity(0.08),
              ft.bgSecondary,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            // 品牌区
            Text(
              'FitTrack 燃力',
              style: TextStyle(
                color: ft.textPrimary,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '扫码加入，一起训练',
              style: TextStyle(color: ft.textSecondary, fontSize: 24),
            ),
            const Spacer(),
            // 邀请码（大字高亮）
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              decoration: BoxDecoration(
                color: ft.purpleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                inviteCode,
                style: TextStyle(
                  color: ft.purpleColor,
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
              ),
            ),
            const Spacer(),
            // 二维码
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: deepLink,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '使用 FitTrack 扫码加入',
              style: TextStyle(color: ft.textMuted, fontSize: 20),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  /// 生成海报并弹出预览弹窗
  static Future<void> generateAndShow(BuildContext context, {
    required String inviteCode,
    required String deepLink,
  }) async {
    final key = GlobalKey();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Scaffold(
        backgroundColor: Colors.black.withOpacity(0.6),
        body: Center(child: CircularProgressIndicator()),
      ),
    );
    // 等待 dialog 显示后再渲染海报
    await Future.delayed(Duration(milliseconds: 100));
    // 略复杂，改用直接弹出 InvitePoster 的 RepaintBoundary 页面
  }
}
```

**简化实现**：由于 `RepaintBoundary` 需要 widget 被渲染到树中才能截图，邀请码海报用独立的 `PosterPage` 风格页面来实现，类似 `NotePosterPage`。

实际实现方式：修改 `invitation_page.dart` 中 `_shareCode()` 方法，创建一个 `showDialog` 弹窗，弹窗内渲染 `InvitePosterContent` widget 并用 `RepaintBoundary` 包裹，截图后关闭弹窗再弹出 `PosterPreviewDialog`。

```dart
// 简化版：在弹窗中渲染后截图
Future<void> _shareCode() async {
  final boundaryKey = GlobalKey();
  // 显示一个包含 RepaintBoundary 的临时弹窗来做截图
  final navigator = Navigator.of(context);
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: RepaintBoundary(
          key: boundaryKey,
          child: InvitePosterContent(
            inviteCode: _myCode,
            deepLink: 'fittrack://invite?code=$_myCode',
          ),
        ),
      ),
    ),
  );
  // 等待渲染
  await Future.delayed(const Duration(milliseconds: 300));
  // 截图
  final imagePath = await PosterGenerator.capture(boundaryKey, fileNamePrefix: 'fittrack_invite');
  // 关闭截图弹窗
  navigator.pop();
  if (!mounted) return;
  // 弹出预览弹窗
  PosterPreviewDialog.show(context, imagePath: imagePath, title: '邀请码海报');
}
```

- [ ] **Step 2: 修改 invitation_page.dart `_shareCode()`**

读取当前 `_shareCode()` 方法（行 191-197），替换为上述海报截图 + PosterPreviewDialog 流程。

删除当前的 `Share.share(...)` 调用，改为：
1. 在 Overlay 或 dialog 中渲染 `InvitePosterContent`（只取内容部分）
2. `PosterGenerator.capture(key)` 截图
3. `PosterPreviewDialog.show(...)` 弹出预览

- [ ] **Step 3: 修改 note_poster_page.dart**

阅读当前文件，`NotePosterPage` 页面结构。改为：
1. 页面初始化后自动生成海报 PNG（用 `PosterGenerator.capture(_posterKey)`）
2. 调用 `PosterPreviewDialog.show(imagePath: ..., title: '训练笔记海报')`
3. 删除页面内的"立即分享"和"保存图片"按钮
4. 保留 `NotePosterContent` widget 作为 RepaintBoundary 内的子组件

- [ ] **Step 4: 验证**

Run: `cd fittrack_flutter && flutter analyze lib/widgets/invite_poster.dart lib/pages/invitation_page.dart lib/pages/note_poster_page.dart lib/widgets/note_poster.dart`

Expected: No issues found

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/invite_poster.dart lib/pages/invitation_page.dart lib/pages/note_poster_page.dart lib/widgets/note_poster.dart
git commit -m "feat: 邀请码+笔记海报改造，走 PosterPreviewDialog"
```

---

### Task 3: 动作分享海报 + 健身卡海报 + 训练记录海报

**Files:**
- Create: `lib/widgets/tutorial_poster.dart`
- Create: `lib/widgets/gym_card_poster.dart`
- Modify: `lib/widgets/tutorial_share_card.dart`（改分享逻辑）
- Modify: `lib/pages/gym_card_page.dart`（新增分享按钮 + 海报生成）
- Modify: `lib/pages/training_page.dart`（改走 PosterPreviewDialog）
- Modify: `lib/services/share_card_service.dart`（保留 generateShareCard，新增只返回路径的方法）

**Consumes:**
- `PosterGenerator.capture(key)` → Task 1
- `PosterPreviewDialog.show(context, {imagePath, title})` → Task 1

- [ ] **Step 1: 创建 tutorial_poster.dart**

```dart
// lib/widgets/tutorial_poster.dart
// 动作分享海报模板（1080×1920 竖版）
class TutorialPoster extends StatelessWidget {
  final Tutorial tutorial;

  @override
  Widget build(BuildContext context) {
    final ft = Theme.of(context).extension<FitTrackColors>()!;
    return RepaintBoundary(
      child: Container(
        width: 1080,
        height: 1920,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ft.accentGlow.withOpacity(0.1), ft.bgSecondary],
          ),
        ),
        child: Column(
          children: [
            // 品牌区
            const Spacer(),
            // 动作名
            Text(tutorial.name, style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: ft.textPrimary)),
            Text(tutorial.coach ?? '', style: TextStyle(fontSize: 24, color: ft.textSecondary)),
            const Spacer(),
            // 动作要点
            if (tutorial.keyPoints.isNotEmpty) ...[
              Text('动作要点', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: ft.textPrimary)),
              const SizedBox(height: 16),
              ...tutorial.keyPoints.take(4).map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: ft.successColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(child: Text(p, style: TextStyle(fontSize: 22, color: ft.textSecondary))),
                  ],
                ),
              )),
            ],
            const Spacer(),
            // 底部二维码
            Text('扫码查看完整教学', style: TextStyle(fontSize: 20, color: ft.textMuted)),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 创建 gym_card_poster.dart**

```dart
// lib/widgets/gym_card_poster.dart
import 'package:flutter/material.dart';
import '../themes/app_themes.dart';

class GymCardPoster extends StatelessWidget {
  final Map<String, dynamic> card;
  const GymCardPoster({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final ft = Theme.of(context).extension<FitTrackColors>()!;
    final gymName = card['gymName'] as String? ?? '健身房';
    final cardType = card['cardType'] as String? ?? '';
    final startDate = card['startDate'] as String? ?? '';
    final endDate = card['endDate'] as String? ?? '';

    // 计算天数
    int usedDays = 0, totalDays = 0;
    try {
      final s = DateTime.parse(startDate);
      final e = endDate.isNotEmpty ? DateTime.parse(endDate) : DateTime.now();
      usedDays = DateTime.now().difference(s).inDays;
      totalDays = e.difference(s).inDays;
    } catch (_) {}
    if (totalDays <= 0) totalDays = 1;
    final progress = (usedDays / totalDays).clamp(0.0, 1.0);

    return RepaintBoundary(
      child: Container(
        width: 1080, height: 1920, padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [ft.accentGlow.withOpacity(0.12), ft.bgCard],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, children: [
          const Spacer(flex: 2),
          Text('我在 $gymName 坚持训练',
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('$usedDays',
            style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: ft.accentGlow)),
          Text('天', style: TextStyle(fontSize: 28, color: ft.textSecondary)),
          const SizedBox(height: 32),
          SizedBox(
            width: 400, height: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(children: [
                Container(color: ft.borderColor.withOpacity(0.3)),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [ft.purpleColor, ft.accentGlow]),
                  )),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Text('剩余 ${(totalDays - usedDays).toStringAsFixed(0)} 天',
            style: TextStyle(fontSize: 22, color: ft.textSecondary)),
          const SizedBox(height: 48),
          Text('$cardType · $gymName',
            style: TextStyle(fontSize: 24, color: ft.textSecondary)),
          const Spacer(),
          Text('FitTrack 燃力', style: TextStyle(fontSize: 20, color: ft.textMuted)),
          const Spacer(flex: 2),
        ]),
      ),
    );
  }
}
```

- [ ] **Step 3: 修改 tutorial_share_card.dart**

阅读当前文件，`_shareText(t)` 纯文本分享方法。
替换为：在 sheet 中渲染 RepaintBoundary 包裹的 TutorialPoster → PosterGenerator.capture → PosterPreviewDialog.show

- [ ] **Step 4: 修改 gym_card_page.dart**

在每张卡片的右上角新增分享按钮（`Icons.share_outlined`，12px，textMuted 颜色）。
点击时：
1. 获取当前卡片数据
2. 在 Overlay 中渲染 GymCardPoster
3. PosterGenerator.capture 截图
4. PosterPreviewDialog.show 弹出预览

- [ ] **Step 5: 修改 training_page.dart `_shareTrainingCard()`**

当前行 597-622：`ShareCardService.generateShareCard()` + `ShareCardService.shareImage()`

改为：`ShareCardService.generateShareCard()`（保留）→ `PosterPreviewDialog.show(imagePath: result, title: '训练记录海报')`

删除对 `ShareCardService.shareImage()` 的调用。

- [ ] **Step 6: 验证**

```bash
flutter analyze lib/widgets/tutorial_poster.dart lib/widgets/gym_card_poster.dart lib/widgets/tutorial_share_card.dart lib/pages/gym_card_page.dart lib/pages/training_page.dart lib/services/share_card_service.dart
```

Expected: No issues found

- [ ] **Step 7: Commit**

```bash
git add lib/widgets/tutorial_poster.dart lib/widgets/gym_card_poster.dart lib/widgets/tutorial_share_card.dart lib/pages/gym_card_page.dart lib/pages/training_page.dart lib/services/share_card_service.dart
git commit -m "feat: 动作/健身卡/训练记录海报改造，走 PosterPreviewDialog"
```

---

### Task 4: 我的页完整改造（最大重量 + 个人信息卡重设计 + 身体数据趋势 + 删除菜单项）

**Files:**
- Create: `lib/services/max_weight_service.dart`
- Create: `lib/data/weight_comparisons.dart`
- Create: `lib/widgets/max_weight_card.dart`
- Create: `lib/pages/max_weight_detail_page.dart`
- Modify: `lib/pages/profile_page.dart`（多处修改 → 个人信息卡/A5 + 身体数据趋势/A6 + 插入 MaxWeightCard + 删除动作教学/B4）
- Modify: `lib/router.dart`（新增 `/max-weight-detail` 路由）

**Interfaces:**
- `MaxWeightService.instance.getGlobalMax() → MaxWeightRecord?`
- `MaxWeightService.instance.getTopByMuscleGroup({limit}) → Map<String, List<MaxWeightRecord>>`
- `MaxWeightRecord{ exerciseName, weight, muscleGroup, date, recordId }`
- `WeightComparison.forWeight(double kg) → WeightComparison{ label, emoji }`

- [ ] **Step 1: 创建 weight_comparisons.dart**

```dart
// lib/data/weight_comparisons.dart
class WeightComparison {
  final double minKg;
  final double maxKg;
  final String label;
  final String emoji;

  const WeightComparison({
    required this.minKg,
    required this.maxKg,
    required this.label,
    required this.emoji,
  });

  static WeightComparison forWeight(double kg) {
    for (final c in kWeightComparisons) {
      if (kg >= c.minKg && kg < c.maxKg) return c;
    }
    return kWeightComparisons.last;
  }
}

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
```

- [ ] **Step 2: 创建 max_weight_service.dart**

```dart
// lib/services/max_weight_service.dart
import '../data/storage.dart';

class MaxWeightRecord {
  final String exerciseName;
  final double weight;
  final String muscleGroup;
  final DateTime date;
  final String? recordId;

  MaxWeightRecord({
    required this.exerciseName,
    required this.weight,
    required this.muscleGroup,
    required this.date,
    this.recordId,
  });
}

class MaxWeightService {
  static final MaxWeightService instance = MaxWeightService._();
  MaxWeightService._();

  /// 获取全局最大重量
  MaxWeightRecord? getGlobalMax() {
    final records = Storage.getRecords();
    MaxWeightRecord? best;
    for (final r in records) {
      final exercises = r['exercises'] as List? ?? [];
      for (final e in exercises) {
        final sets = e['sets'] as List? ?? [];
        for (final s in sets) {
          final weight = (s['weight'] as num?)?.toDouble() ?? 0;
          if (weight > 0 && (best == null || weight > best.weight)) {
            best = MaxWeightRecord(
              exerciseName: e['name'] as String? ?? '',
              weight: weight,
              muscleGroup: _inferMuscleGroup(e['name'] as String? ?? ''),
              date: DateTime.fromMillisecondsSinceEpoch(
                (r['timestamp'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
              ),
              recordId: r['id'] as String?,
            );
          }
        }
      }
    }
    return best;
  }

  /// 按部位分组获取 Top N 动作最大重量
  Map<String, List<MaxWeightRecord>> getTopByMuscleGroup({int limit = 5}) {
    final Map<String, List<MaxWeightRecord>> grouped = {};
    final records = Storage.getRecords();
    for (final r in records) {
      final exercises = r['exercises'] as List? ?? [];
      for (final e in exercises) {
        final name = e['name'] as String? ?? '';
        final group = _inferMuscleGroup(name);
        final sets = e['sets'] as List? ?? [];
        double maxW = 0;
        for (final s in sets) {
          final w = (s['weight'] as num?)?.toDouble() ?? 0;
          if (w > maxW) maxW = w;
        }
        if (maxW > 0) {
          grouped.putIfAbsent(group, () => []);
          grouped[group]!.add(MaxWeightRecord(
            exerciseName: name,
            weight: maxW,
            muscleGroup: group,
            date: DateTime.fromMillisecondsSinceEpoch(
              (r['timestamp'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
            ),
            recordId: r['id'] as String?,
          ));
        }
      }
    }
    // 每组排序取 Top N
    final result = <String, List<MaxWeightRecord>>{};
    grouped.forEach((key, list) {
      list.sort((a, b) => b.weight.compareTo(a.weight));
      result[key] = list.take(limit).toList();
    });
    return result;
  }

  /// 简单部位推断（通过动作名关键字）
  static String _inferMuscleGroup(String name) {
    final n = name.toLowerCase();
    if (n.contains('卧推') || n.contains('飞鸟') || n.contains('夹胸') || n.contains('俯卧撑')) return '胸部';
    if (n.contains('硬拉') || n.contains('划船') || n.contains('引体') || n.contains('下拉') || n.contains('高位')) return '背部';
    if (n.contains('深蹲') || n.contains('腿举') || n.contains('腿屈伸') || n.contains('弓步') || n.contains('提踵')) return '腿部';
    if (n.contains('推举') || n.contains('侧平举') || n.contains('前平举') || n.contains('飞鸟') && n.contains('肩')) return '肩膀';
    if (n.contains('弯举') || n.contains('臂屈伸') || n.contains('绳索') && n.contains('臂') || n.contains('锤式')) return '手臂';
    if (n.contains('卷腹') || n.contains('平板支撑') || n.contains('举腿') || n.contains('俄罗斯转体')) return '核心';
    return '其他';
  }

  static const List<String> kMuscleGroups = ['胸部', '背部', '腿部', '肩膀', '手臂', '核心', '其他'];
}
```

- [ ] **Step 3: 创建 max_weight_card.dart**

```dart
// lib/widgets/max_weight_card.dart
import 'package:flutter/material.dart';
import '../themes/app_themes.dart';
import '../services/max_weight_service.dart';
import '../data/weight_comparisons.dart';
import 'common_widgets.dart';

class MaxWeightCard extends StatelessWidget {
  final VoidCallback? onTap;

  /// 显示趣味对比卡片，点击进入详情页
  @override
  Widget build(BuildContext context) {
    final ft = Theme.of(context).extension<FitTrackColors>()!;
    final globalMax = MaxWeightService.instance.getGlobalMax();

    if (globalMax == null) {
      // 空状态
      return CardWidget(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.fitness_center, color: ft.textMuted, size: 28),
              const SizedBox(width: 12),
              Text('开始训练记录你的最大重量', style: TextStyle(color: ft.textMuted, fontSize: 14)),
              const Spacer(),
              Icon(Icons.chevron_right, color: ft.textMuted),
            ],
          ),
        ),
      );
    }

    final comparison = WeightComparison.forWeight(globalMax.weight);

    return CardWidget(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Icon(Icons.fitness_center, color: ft.accentGlow, size: 22),
                const SizedBox(width: 8),
                Text(
                  '举起最大重量',
                  style: TextStyle(color: ft.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text('查看详情 →', style: TextStyle(color: ft.accentGlow, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            // 大数字
            Center(
              child: Text(
                '${globalMax.weight.toStringAsFixed(1)} kg',
                style: TextStyle(
                  color: ft.accentGlow,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // 趣味对比
            Center(
              child: Text(
                '${comparison.emoji} 相当于${comparison.label}',
                style: TextStyle(color: ft.textSecondary, fontSize: 14),
              ),
            ),
            const SizedBox(height: 12),
            // 最近一次
            Center(
              child: Text(
                '最近一次：${globalMax.exerciseName} · ${_formatDate(globalMax.date)}',
                style: TextStyle(color: ft.textMuted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays <= 1) return '今天';
    if (diff.inDays <= 7) return '${diff.inDays}天前';
    return '${d.month}/${d.day}';
  }
}
```

- [ ] **Step 4: 创建 max_weight_detail_page.dart**

```dart
// lib/pages/max_weight_detail_page.dart
import 'package:flutter/material.dart';
import '../themes/app_themes.dart';
import '../data/weight_comparisons.dart';
import '../services/max_weight_service.dart';
import '../widgets/page_header.dart';
import '../widgets/common_widgets.dart';

class MaxWeightDetailPage extends StatelessWidget {
  const MaxWeightDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ft = Theme.of(context).extension<FitTrackColors>()!;
    final globalMax = MaxWeightService.instance.getGlobalMax();
    final muscleGroups = MaxWeightService.instance.getTopByMuscleGroup();

    return Scaffold(
      backgroundColor: ft.bgSecondary,
      body: Column(
        children: [
          PageHeader(title: '最大重量纪录', onBack: () => Navigator.of(context).pop()),
          Expanded(
            child: globalMax == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fitness_center, size: 64, color: ft.textMuted),
                        const SizedBox(height: 16),
                        Text('暂无最大重量记录', style: TextStyle(color: ft.textMuted, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('开始训练并记录你的重量', style: TextStyle(color: ft.textMuted, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildGlobalCard(globalMax, ft),
                      const SizedBox(height: 24),
                      ...MaxWeightService.kMuscleGroups
                          .where((g) => muscleGroups.containsKey(g) && muscleGroups[g]!.isNotEmpty)
                          .map((g) => _buildGroupSection(g, muscleGroups[g]!, ft)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalCard(MaxWeightRecord record, FitTrackColors ft) {
    final comparison = WeightComparison.forWeight(record.weight);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ft.accentGlow.withOpacity(0.12), ft.bgCard],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        const Text('🏆 总纪录', style: TextStyle(fontSize: 14)),
        const SizedBox(height: 8),
        Text('${record.weight.toStringAsFixed(1)} kg',
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: ft.accentGlow)),
        const SizedBox(height: 4),
        Text('${comparison.emoji} 相当于${comparison.label}',
          style: TextStyle(fontSize: 14, color: ft.textSecondary)),
      ]),
    );
  }

  Widget _buildGroupSection(String group, List<MaxWeightRecord> records, FitTrackColors ft) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('💪 $group', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ft.textPrimary)),
      const SizedBox(height: 8),
      ...records.map((r) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ft.bgCard, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ft.borderColor),
        ),
        child: Row(children: [
          Expanded(child: Text(r.exerciseName, style: TextStyle(color: ft.textPrimary, fontSize: 15))),
          Text('${r.weight.toStringAsFixed(1)} kg', style: TextStyle(color: ft.accentGlow, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Text('${r.date.month}/${r.date.day}', style: TextStyle(color: ft.textMuted, fontSize: 12)),
        ]),
      )),
      const SizedBox(height: 16),
    ]);
  }
}
```

- [ ] **Step 5: 新增 `/max-weight-detail` 路由**

在 `lib/router.dart` 中新增：
```dart
GoRoute(
  path: '/max-weight-detail',
  builder: (context, state) => const MaxWeightDetailPage(),
),
```

确保路由在 `/plan-library/detail/:planId` 之后或之前不冲突。

- [ ] **Step 6: 修改 profile_page.dart（核心改动）**

**6a. 个人信息卡重设计（`_buildProfileHeader`）**
- 头像缩至 48px，无装饰边框
- 卡片背景：`ft.bgCard` + `Border.all(color: ft.borderColor)`（删除渐变）
- 用户名 16号 semibold + 副标题 12号 textSecondary
- 数据带：三列分隔（累计获得 / 消耗 / 连续打卡天数），中间用细竖线分割
- 积分单独成卡（新方法 `_buildPointsCard`）
- 删除卡通 emoji、过强的渐变

**6b. 身体数据重排版（`_buildBodyData`）**
- 改为 3 列布局（原 4 列）
- 每个字段下方增加趋势箭头
- 取 `Storage.getBodyDataHistory()` 倒数第二条记录对比
- 趋势逻辑：下降为正向绿色 ↓，上升为负向红色 ↑
- 字段顺序：身高→体重→BMI→体脂率→胸围→腰围→臀围→上臂围→大腿围→目标体重→静息心率
- 右上角增加"更新时间"小字

**6c. 插入 MaxWeightCard**
在 `_buildBodyData` 与 `_buildMenuList` 之间插入：
```dart
const SizedBox(height: 12),
MaxWeightCard(onTap: () => context.push('/max-weight-detail')),
```

**6d. 删除动作教学菜单项**
从 `_menuItems` List 中删除 `{'icon': Icons.school_outlined, 'label': '动作教学', 'page': 'tutorial'}` 项。

- [ ] **Step 7: 验证**

```bash
flutter analyze lib/services/max_weight_service.dart lib/data/weight_comparisons.dart lib/widgets/max_weight_card.dart lib/pages/max_weight_detail_page.dart lib/pages/profile_page.dart lib/router.dart
```

Expected: No issues found

- [ ] **Step 8: Commit**

```bash
git add lib/services/max_weight_service.dart lib/data/weight_comparisons.dart lib/widgets/max_weight_card.dart lib/pages/max_weight_detail_page.dart lib/pages/profile_page.dart lib/router.dart
git commit -m "feat: 完整改造我的页（最大重量+个人信息卡+身体数据趋势+删除动作教学）"
```

---

### Task 5: UI 对齐修复（Overflow + padding + 推荐位置）

**Files:**
- Modify: `lib/pages/stats_page.dart`（训练活跃度 Overflow 修复）
- Modify: `lib/widgets/recommendation_banner.dart`（删除内部 padding）
- Modify: `lib/pages/plan_page.dart`（推荐区段 padding/margin 对齐）
- Modify: `lib/pages/add_plan_page.dart`（推荐移至底部）

- [ ] **Step 1: 修复 stats_page.dart Overflow**

阅读 `_buildHeatmap` 方法（行 594-805）：
1. 将 Row 主体（行 672-770）改为用 `LayoutBuilder` 包裹，基于 `constraints.maxWidth` 计算大小
2. 月份标签 Stack（行 744-768）加 `ClipRect`，`clipBehavior` 改为默认 `Clip.hardEdge`
3. 整个 Row 主体用 `SingleChildScrollView(horizontal)` 兜底

关键改动点：
```dart
// 原：
final screenWidth = MediaQuery.of(context).size.width;
final availableWidth = screenWidth - 32 - 32 - 20;

// 改为 LayoutBuilder:
LayoutBuilder(
  builder: (context, constraints) {
    final availableWidth = constraints.maxWidth - 32 - 20;
    // ...
  },
)
```

- [ ] **Step 2: 修复 recommendation_banner.dart padding**

删除行 46-47 的 Padding 包装：
```dart
// 原：
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: SizedBox(
    height: 150,
    child: PageView.builder( ... ),
  ),
),

// 改为：
SizedBox(
  height: 150,
  child: PageView.builder( ... ),
),
```

同时将每个 banner 内部的 margin 改为 0：
```dart
// 行 75（原）：
margin: EdgeInsets.symmetric(horizontal: 4),
// 改为：
margin: EdgeInsets.zero,
```

- [ ] **Step 3: 修复 plan_page.dart 推荐区段对齐**

阅读 `_buildRecommendedSection` 方法（行 340-398）：
删除区段内所有额外 `horizontal: 16` 的 padding/margin，只保留父级 16px。

具体改动：
- 行 351-352：`EdgeInsets.fromLTRB(16, 24, 16, 12)` → `EdgeInsets.fromLTRB(0, 24, 0, 12)`
- 行 381：`EdgeInsets.symmetric(horizontal: 16, vertical: 12)` → `EdgeInsets.symmetric(vertical: 12)`
- 行 407：`EdgeInsets.symmetric(horizontal: 16, vertical: 6)` → `EdgeInsets.symmetric(vertical: 6)`

- [ ] **Step 4: 修复 add_plan_page.dart 推荐位置**

阅读当前文件结构（行 179-198 + 行 201-301）：
1. 将推荐区段（行 179-198）移动到保存按钮之前
2. 新顺序：
   - "或自定义计划" 标题 + 表单
   - 分隔线（Divider + SizedBox）
   - "为你推荐" 区段（标题行 + 推荐卡片列表）
   - 保存按钮

注意：需要保持 `isEditing` 条件不变，推荐只在非编辑模式下显示。

- [ ] **Step 5: 验证**

```bash
flutter analyze lib/pages/stats_page.dart lib/widgets/recommendation_banner.dart lib/pages/plan_page.dart lib/pages/add_plan_page.dart
```

Expected: No issues found

- [ ] **Step 6: Commit**

```bash
git add lib/pages/stats_page.dart lib/widgets/recommendation_banner.dart lib/pages/plan_page.dart lib/pages/add_plan_page.dart
git commit -m "fix: UI 对齐修复（Overflow+padding+推荐位置）"
```

---

### Task 6: 列表显示与排序（教学中心 + 荣誉墙 + 成就墙）

**Files:**
- Modify: `lib/pages/tutorial_list_page.dart`（只显示推荐 + 入口按钮）
- Create: `lib/pages/all_tutorials_page.dart`
- Modify: `lib/pages/honor_wall_page.dart`（显示全部徽章，未解锁灰显）
- Modify: `lib/pages/achievement_page.dart`（已解锁优先排序）
- Modify: `lib/router.dart`（新增 `/all-tutorials` 路由）

- [ ] **Step 1: 修改 tutorial_list_page.dart**

阅读当前文件，找到三个区段：
1. "为你推荐"横滑区段（行 41-46）：保留，限制为 3 项
2. "系统化课程"区段（行 51-53）：保留，限制为 2 项
3. "动作教学"区段（行 56-58）：保留，限制为 4 项
4. 底部新增："查看全部教学"按钮

```dart
// 在所有区段结束后，底部添加：
Padding(
  padding: const EdgeInsets.all(16),
  child: SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: () => context.push('/all-tutorials'),
      child: const Text('查看全部教学'),
    ),
  ),
),
```

- [ ] **Step 2: 创建 all_tutorials_page.dart**

```dart
// lib/pages/all_tutorials_page.dart
// PageHeader(title: '全部教学', onBack: Navigator.pop)
// 顶部肌群筛选 Chip（复用 tutorial_list_page.dart 的 _buildGoalFilter）
// 完整系统化课程列表（全部 CourseLibrary.courses）
// 完整动作教学列表（全部 TutorialLibrary.getBasic()，按筛选过滤）
// 复用 tutorial_list_page.dart 中的卡片组件样式（_buildCourseSection, _buildTutorialSection）
```

注意：因为卡片组件是 tutorial_list_page.dart 中的私有方法，可以直接复制或提取为可复用方法。
简化方案：所有全部教学列表的样式直接在 AllTutorialsPage 中重新实现（复制卡片样式代码），避免大重构。

- [ ] **Step 3: 新增 `/all-tutorials` 路由**

```dart
// router.dart 中
GoRoute(
  path: '/all-tutorials',
  builder: (context, state) => const AllTutorialsPage(),
),
```

- [ ] **Step 4: 修改 honor_wall_page.dart**

1. 行 21-23 改为取全部徽章：
```dart
_all = AchievementService.instance.getAll();
_unlocked = _all.where((a) => a.unlocked).toList();
_locked = _all.where((a) => !a.unlocked).toList();
```

2. 顶部统计卡改为"已解锁 X / 总数 Y"

3. 荣誉墙网格显示全部：
```dart
// 排序：已锁按解锁时间倒序，未锁按原始顺序
final gridItems = [
  ..._unlocked..sort((a, b) => (b.unlockedAt ?? 0).compareTo(a.unlockedAt ?? 0)),
  ..._locked,
];
```

4. 未解锁徽章渲染：
```dart
ColorFiltered(
  colorFilter: const ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 0.4, 0,
  ]),
  child: // 原有徽章图标
)
```
或更简单的：用 `Colors.grey` 覆盖 + opacity 0.3。

5. 未锁定项覆盖 `Icons.lock` 图标

6. 点击未解锁弹 `InfoDialog` 显示解锁条件

- [ ] **Step 5: 修改 achievement_page.dart**

1. 分组逻辑保留，但每组内排序：
```dart
// 每个 category 内的 items 排序：
items.sort((a, b) {
  if (a.unlocked != b.unlocked) return a.unlocked ? -1 : 1;
  if (a.unlocked && b.unlocked) {
    return (b.unlockedAt ?? 0).compareTo(a.unlockedAt ?? 0);
  }
  return 0;
});
```

2. 已解锁的右上角显示相对时间：
```dart
// 在已有 check_circle 图标旁加时间文字
if (a.unlocked && a.unlockedAt != null) {
  Text(_formatRelativeTime(a.unlockedAt!), style: TextStyle(color: ft.textMuted, fontSize: 11)),
}
```

3. 已解锁背景：
```dart
color: ft.accentGlow.withOpacity(0.15),
// 未解锁保持原样：
color: ft.borderColor.withOpacity(0.3),
```

- [ ] **Step 6: 验证**

```bash
flutter analyze lib/pages/tutorial_list_page.dart lib/pages/all_tutorials_page.dart lib/pages/honor_wall_page.dart lib/pages/achievement_page.dart lib/router.dart
```

Expected: No issues found

- [ ] **Step 7: Commit**

```bash
git add lib/pages/tutorial_list_page.dart lib/pages/all_tutorials_page.dart lib/pages/honor_wall_page.dart lib/pages/achievement_page.dart lib/router.dart
git commit -m "feat: 列表显示与排序（教学中心+荣誉墙+成就墙）"
```

---

### Task 7: Toast/弹窗统一

**Files:**
- 扫描 `lib/` 目录下所有 `.dart` 文件，替换 `ScaffoldMessenger.showSnackBar(SnackBar(...))` 和 `showDialog(... AlertDialog ...)`
- 排除文件：`lib/widgets/common_widgets.dart`（FitToast 定义处）、已自定义的弹窗文件

**Replace rules:**
- `SnackBar(content: Text('成功...'))` → `FitToast.success(ctx, '成功...')`
- `SnackBar(content: Text('失败...'))` → `FitToast.error(ctx, '失败...')`
- `SnackBar(content: Text('提示...'))` → `FitToast.info(ctx, '提示...')`
- `AlertDialog` with actions → `ConfirmDialog.show(ctx, ...)`
- `AlertDialog` 单按钮 → `InfoDialog.show(ctx, ...)`

- [ ] **Step 1: 全项目 SnackBar 替换**

```bash
# 查找所有 SnackBar 调用
flutter analyze 2>&1 | findstr "SnackBar"
```

手动扫描每个匹配文件：
1. 找到所有 `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('...')))` 调用
2. 判断类型（success/error/info）
3. 替换为 `FitToast.success(context, '...')` 等

**需要扫描的文件（根据前期研究）**：
- `lib/services/plan_unlock_service.dart`
- `lib/services/share_code_service.dart`
- `lib/services/share_card_service.dart`
- `lib/services/points_service.dart`
- `lib/pages/*.dart`（多数页面都有 SnackBar 调用）
- `lib/widgets/*.dart`

- [ ] **Step 2: AlertDialog 替换**

扫描 `showDialog(context: ..., builder: (ctx) => AlertDialog(...))`：
- 双按钮确认：`ConfirmDialog.show(ctx, title: ..., content: ..., onConfirm: ...)`
- 单按钮信息：`InfoDialog.show(ctx, title: ..., content: ...)`

- [ ] **Step 3: 特殊处理 note_edit_page.dart**

行 676-722 保存笔记后的 AlertDialog（询问是否生成海报）：
改为 `ConfirmDialog.show`：
```dart
ConfirmDialog.show(
  context,
  title: '笔记已保存',
  content: '已成功保存训练笔记，是否生成海报分享？',
  confirmText: '生成海报',
  cancelText: '稍后再说',
  onConfirm: () {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => NotePosterPage(note: note, boundRecord: _boundRecord),
    ));
  },
);
```

- [ ] **Step 4: 验证**

```bash
flutter analyze
```

Expected: No issues found（或仅有预存在 info 级提示）

- [ ] **Step 5: Commit**

```bash
git add <所有被修改的文件>
git commit -m "refactor: Toast/弹窗统一 - SnackBar→FitToast, AlertDialog→ConfirmDialog/InfoDialog"
```

---

## 实施顺序

推荐执行流程（最大化并行）：

```
Wave 1（并行）：Task 1, Task 4, Task 5, Task 6
         │         │        │        └── 独立，无需等待
         │         │        └── 独立，无需等待
         │         └── 独立，无需等待
         └── Task 2, Task 3 依赖此完成
Wave 2（并行）：Task 2, Task 3
Wave 3（最终）：Task 7（需要所有文件最终版本）
```

每次 Task 完成后执行 `flutter analyze` 验证。

本计划保存为 `docs/superpowers/plans/2026-07-21-app-optimization-batch.md`
