# 计划导入导出优化 + 音效系统 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复训练计划导入内容缺失 bug，新增二维码/海报导出与扫码导入，搭建音效系统并集成到核心功能。

**Architecture:** 修复 ShareCodeService 的类型归一化与深拷贝问题；新增 PlanQrCodePage/ScanImportPage/PlanPosterPage 三个页面复用现有海报体系；新增 SoundService 单例管理音效播放，合成生成 8 个音效文件。

**Tech Stack:** Flutter, qr_flutter, mobile_scanner, audioplayers, dart:convert, crypto

## Global Constraints

- 项目路径：`e:\Project\health_project\health_training\fittrack_flutter`
- 平台：OHOS + Android，音效库需兼容两端
- 现有海报体系：PosterGenerator.capture() + PosterPreviewDialog.show()
- 现有分享码格式：`FITT-XXXXXX|base64Url(json)`
- 不创建测试文件（项目无测试套件），用 `flutter analyze` 验证

---

### Task 1: 修复导入内容缺失 Bug

**Files:**
- Modify: `lib/services/share_code_service.dart` — 新增 `deepNormalizePlan()` 方法
- Modify: `lib/pages/share_code_page.dart` — 修复 `_generateCode()` 和 `_doImport()`

**Interfaces:**
- Produces: `ShareCodeService.deepNormalizePlan(Map<String, dynamic>) → Map<String, dynamic>`

- [ ] **Step 1: 在 share_code_service.dart 新增 deepNormalizePlan 方法**

在 `ShareCodeService` 类末尾（`validateCode` 方法之后）新增：

```dart
/// 深拷贝并归一化计划数据
///
/// 修复 JSON 反序列化后的类型问题：
/// - List<dynamic> → List<Map<String, dynamic>>
/// - int weight → double weight
/// - 保留 isRest 字段
static Map<String, dynamic> deepNormalizePlan(Map<String, dynamic> input) {
  final result = <String, dynamic>{};
  for (final entry in input.entries) {
    result[entry.key] = _normalizeValue(entry.value);
  }
  return result;
}

static dynamic _normalizeValue(dynamic value) {
  if (value is Map) {
    final normalized = <String, dynamic>{};
    for (final entry in value.entries) {
      if (entry.key is String) {
        normalized[entry.key as String] = _normalizeValue(entry.value);
      }
    }
    return normalized;
  }
  if (value is List) {
    return value.map(_normalizeValue).toList();
  }
  // weight 字段统一转为 double
  if (value is int) {
    // 检查上下文是否为 weight 字段（无法在此层判断字段名，统一保留 int）
    return value;
  }
  return value;
}

/// 归一化计划中的 weight 字段为 double
static void _normalizeWeightFields(Map<String, dynamic> planData) {
  final days = planData['days'] as List?;
  if (days == null) return;
  for (final day in days) {
    if (day is! Map) continue;
    final exercises = day['exercises'] as List?;
    if (exercises == null) continue;
    for (final ex in exercises) {
      if (ex is! Map) continue;
      final w = ex['weight'];
      if (w is int) {
        ex['weight'] = w.toDouble();
      }
      // setConfig 中的 weight 也归一化
      final setConfig = ex['setConfig'] as List?;
      if (setConfig != null) {
        for (final cfg in setConfig) {
          if (cfg is! Map) continue;
          final cw = cfg['weight'];
          if (cw is int) {
            cfg['weight'] = cw.toDouble();
          }
        }
      }
    }
  }
}
```

- [ ] **Step 2: 在 importFromString 中调用归一化**

修改 `importFromString` 方法，在 `return ShareCodeImportResult(...)` 前添加归一化：

找到（约第172-178行）：
```dart
        final planData = jsonDecode(jsonStr) as Map<String, dynamic>;
        final warning = _validatePlan(planData);
        return ShareCodeImportResult(
          result: ShareCodeResult.success,
          warning: warning,
          planData: planData,
        );
```

替换为：
```dart
        final rawPlanData = jsonDecode(jsonStr) as Map<String, dynamic>;
        final planData = deepNormalizePlan(rawPlanData);
        _normalizeWeightFields(planData);
        final warning = _validatePlan(planData);
        return ShareCodeImportResult(
          result: ShareCodeResult.success,
          warning: warning,
          planData: planData,
        );
```

- [ ] **Step 3: 修复 _generateCode 中 attachAuthorSignature 返回值丢弃**

在 `share_code_page.dart` 的 `_generateCode()` 方法中：

找到（约第247-251行）：
```dart
    final settings = Storage.getSettings();
    final author = settings['nickname'] as String? ?? '匿名用户';
    ShareCodeService.instance.attachAuthorSignature(shareData, author);

    final shareString = ShareCodeService.instance.generateShareableString(shareData);
```

替换为：
```dart
    final settings = Storage.getSettings();
    final author = settings['nickname'] as String? ?? '匿名用户';
    final withAuthor = ShareCodeService.instance.attachAuthorSignature(shareData, author);

    final shareString = ShareCodeService.instance.generateShareableString(withAuthor);
```

- [ ] **Step 4: 在 _generateCode 中移除 currentDayIndex**

在 `_generateCode()` 的移除字段列表中添加 `currentDayIndex`：

找到：
```dart
    shareData.remove('id');
    shareData.remove('status');
    shareData.remove('progress');
    shareData.remove('createTime');
    shareData.remove('updateTime');
```

替换为：
```dart
    shareData.remove('id');
    shareData.remove('status');
    shareData.remove('progress');
    shareData.remove('createTime');
    shareData.remove('updateTime');
    shareData.remove('currentDayIndex');
```

- [ ] **Step 5: 修复 _doImport 中重置字段**

在 `share_code_page.dart` 的 `_doImport()` 方法中：

找到（约第544-553行）：
```dart
  void _doImport(Map<String, dynamic> planData, FitTrackColors colors) {
    // 清理分享方字段，生成本地新计划
    final newPlan = Map<String, dynamic>.from(planData);
    newPlan.remove('author');
    newPlan.remove('sharedAt');
    newPlan['status'] = 'active';
    newPlan['progress'] = 0;
```

替换为：
```dart
  void _doImport(Map<String, dynamic> planData, FitTrackColors colors) {
    // 清理分享方字段，生成本地新计划（深拷贝 + 类型归一化）
    final newPlan = ShareCodeService.deepNormalizePlan(planData);
    newPlan.remove('author');
    newPlan.remove('sharedAt');
    newPlan['status'] = 'active';
    newPlan['progress'] = 0;
    newPlan['currentDayIndex'] = 0;
    ShareCodeService.instance.normalizeWeightFieldsPublic(newPlan);
```

- [ ] **Step 6: 将 _normalizeWeightFields 改为公开方法**

在 `share_code_service.dart` 中，将 `_normalizeWeightFields` 重命名为 `normalizeWeightFieldsPublic` 并改为 static（供外部调用）：

找到：
```dart
static void _normalizeWeightFields(Map<String, dynamic> planData) {
```

替换为：
```dart
static void normalizeWeightFieldsPublic(Map<String, dynamic> planData) {
```

- [ ] **Step 7: 验证**

Run: `flutter analyze lib/services/share_code_service.dart lib/pages/share_code_page.dart`
Expected: 无 error

---

### Task 2: 计划页快捷分享按钮

**Files:**
- Modify: `lib/pages/plan_page.dart` — 在"我的计划"卡片添加分享按钮 + 底部菜单

**Interfaces:**
- Consumes: `ShareCodeService`, `Storage.getPlans()`
- Produces: `_showShareMenu()` 方法

- [ ] **Step 1: 在 plan_page.dart 的计划卡片中添加分享按钮**

找到计划卡片渲染代码中每个卡片的 `Row` 或 `trailing` 区域，添加分享图标按钮。具体位置需根据 plan_page.dart 实际结构调整。在卡片的操作区域添加：

```dart
IconButton(
  icon: Icon(Icons.share_outlined, size: 18, color: colors.textMuted),
  onPressed: () => _showShareMenu(colors, plan),
  tooltip: '分享计划',
),
```

- [ ] **Step 2: 添加 _showShareMenu 方法**

在 `_PlanPageState` 类中添加：

```dart
void _showShareMenu(FitTrackColors colors, Map<String, dynamic> plan) {
  final planId = plan['id'] as String?;
  if (planId == null) return;

  showModalBottomSheet(
    context: context,
    backgroundColor: colors.bgCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '分享「${plan['name'] ?? '计划'}」',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildShareOption(colors, Icons.qr_code_2, '生成分享码', () {
            Navigator.pop(ctx);
            context.push('/share-code');
          }),
          _buildShareOption(colors, Icons.qr_code, '生成二维码', () {
            Navigator.pop(ctx);
            context.push('/plan-qr/$planId');
          }),
          _buildShareOption(colors, Icons.image_outlined, '生成海报', () {
            Navigator.pop(ctx);
            context.push('/plan-poster/$planId');
          }),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Widget _buildShareOption(
    FitTrackColors colors, IconData icon, String label, VoidCallback onTap) {
  return ListTile(
    leading: Icon(icon, color: colors.accentGlow),
    title: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
    trailing: Icon(Icons.chevron_right, color: colors.textMuted, size: 20),
    onTap: onTap,
  );
}
```

- [ ] **Step 3: 验证**

Run: `flutter analyze lib/pages/plan_page.dart`
Expected: 无 error

---

### Task 3: 二维码导出页面（PlanQrCodePage）

**Files:**
- Create: `lib/pages/plan_qr_code_page.dart`
- Modify: `lib/router.dart` — 添加路由
- Modify: `pubspec.yaml` — 确认 qr_flutter 依赖

**Interfaces:**
- Consumes: `Storage.getPlanById()`, `ShareCodeService.generateShareableString()`
- Produces: `PlanQrCodePage` widget

- [ ] **Step 1: 创建 plan_qr_code_page.dart**

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../data/storage.dart';
import '../services/share_code_service.dart';
import '../themes/app_themes.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

class PlanQrCodePage extends StatefulWidget {
  final String planId;
  const PlanQrCodePage({super.key, required this.planId});

  @override
  State<PlanQrCodePage> createState() => _PlanQrCodePageState();
}

class _PlanQrCodePageState extends State<PlanQrCodePage> {
  Map<String, dynamic>? _plan;
  String? _shareString;
  String? _shareCode;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    final plan = Storage.getPlanById(widget.planId);
    if (plan == null) {
      setState(() => _errorMessage = '计划不存在');
      return;
    }

    final shareData = Map<String, dynamic>.from(plan);
    shareData.remove('id');
    shareData.remove('status');
    shareData.remove('progress');
    shareData.remove('createTime');
    shareData.remove('updateTime');
    shareData.remove('currentDayIndex');

    final settings = Storage.getSettings();
    final author = settings['nickname'] as String? ?? '匿名用户';
    final withAuthor =
        ShareCodeService.instance.attachAuthorSignature(shareData, author);

    final shareString =
        ShareCodeService.instance.generateShareableString(withAuthor);
    final code = shareString.split('|').first;

    // 二维码容量检查（QR 级别 L 最大约 2953 字符）
    if (shareString.length > 2900) {
      setState(() {
        _errorMessage = '计划数据过大（${shareString.length}字符），二维码无法承载。\n请使用文本分享码方式分享。';
      });
      return;
    }

    setState(() {
      _plan = plan;
      _shareString = shareString;
      _shareCode = code;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ft = Theme.of(context).extension<FitTrackColors>()!;
    return Scaffold(
      backgroundColor: ft.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            title: '计划二维码',
            isTabPage: false,
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: _errorMessage != null
                ? _buildError(ft)
                : _shareString != null
                    ? _buildContent(ft)
                    : const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }

  Widget _buildError(FitTrackColors ft) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: ft.warningColor),
            const SizedBox(height: 16),
            Text(_errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: ft.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(FitTrackColors ft) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // 二维码卡片
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: _shareString!,
              version: QrVersions.auto,
              size: 240,
              gapless: true,
              errorStateBuilder: (ctx, err) => Center(
                child: Text('二维码生成失败',
                    style: TextStyle(color: ft.warningColor, fontSize: 14)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 分享码
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: ft.accentGlow.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ft.accentGlow.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Text('分享码', style: TextStyle(color: ft.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                SelectableText(
                  _shareCode!,
                  style: TextStyle(
                    color: ft.accentGlow,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 提示文字
          Text(
            '好友可通过扫码或粘贴分享串导入此计划',
            style: TextStyle(color: ft.textMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // 操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyShareString(ft),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('复制分享串'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ft.accentGlow,
                    side: BorderSide(color: ft.accentGlow.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _copyShareString(FitTrackColors ft) {
    // Clipboard.setData 需要 import services
    // 在文件顶部添加 import 'package:flutter/services.dart';
  }
}
```

- [ ] **Step 2: 补充 import 并修复 _copyShareString**

在文件顶部添加 `import 'package:flutter/services.dart';`，并完善 `_copyShareString`：

```dart
void _copyShareString(FitTrackColors ft) {
  Clipboard.setData(ClipboardData(text: _shareString!));
  FitToast.success(context, '分享串已复制');
}
```

- [ ] **Step 3: 在 router.dart 添加路由**

在 router.dart 中添加 import 和路由：

```dart
import 'pages/plan_qr_code_page.dart';
```

在 `/share-code` 路由附近添加：

```dart
GoRoute(
  path: '/plan-qr/:planId',
  parentNavigatorKey: rootNavigatorKey,
  builder: (context, state) => PlanQrCodePage(
    planId: state.params['planId'] ?? '',
  ),
),
```

- [ ] **Step 4: 验证**

Run: `flutter analyze lib/pages/plan_qr_code_page.dart lib/router.dart`
Expected: 无 error

---

### Task 4: 扫码导入页面（ScanImportPage）

**Files:**
- Modify: `pubspec.yaml` — 添加 mobile_scanner 依赖
- Create: `lib/pages/scan_import_page.dart`
- Modify: `lib/router.dart` — 添加路由
- Modify: `lib/pages/share_code_page.dart` — 添加扫码入口

- [ ] **Step 1: 添加 mobile_scanner 依赖**

在 pubspec.yaml 的 dependencies 中添加：

```yaml
  mobile_scanner: ^3.5.5
```

Run: `flutter pub get`

- [ ] **Step 2: 创建 scan_import_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../data/storage.dart';
import '../services/share_code_service.dart';
import '../themes/app_themes.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

class ScanImportPage extends StatefulWidget {
  const ScanImportPage({super.key});

  @override
  State<ScanImportPage> createState() => _ScanImportPageState();
}

class _ScanImportPageState extends State<ScanImportPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ft = Theme.of(context).extension<FitTrackColors>()!;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // 顶部安全区 + 返回按钮
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ),
          // 扫码区域
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                ),
                // 扫码框装饰
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white70, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                // 底部提示
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Text(
                    '将二维码对准框内即可自动扫描',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_processed) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    _processed = true;
    _controller.stop();

    final result = ShareCodeService.instance.importFromString(raw);
    if (!mounted) return;

    final ft = Theme.of(context).extension<FitTrackColors>()!;

    if (result.result == ShareCodeResult.success && result.planData != null) {
      _doImport(result.planData!, result.warning, ft);
    } else {
      String errorMsg;
      switch (result.result) {
        case ShareCodeResult.invalidFormat:
          errorMsg = '二维码格式无效，不是有效的计划分享码';
          break;
        case ShareCodeResult.invalidSignature:
          errorMsg = '分享码签名无效，可能已损坏';
          break;
        case ShareCodeResult.decodeError:
          errorMsg = '解析失败，二维码可能不完整';
          break;
        default:
          errorMsg = '导入失败，请重试';
      }
      FitToast.error(context, errorMsg);
      setState(() => _processed = false);
      _controller.start();
    }
  }

  void _doImport(Map<String, dynamic> planData, ImportWarning warning,
      FitTrackColors ft) {
    if (warning == ImportWarning.excessiveVolume ||
        warning == ImportWarning.excessiveFrequency) {
      ConfirmDialog.show(
        context,
        title: warning == ImportWarning.excessiveVolume ? '训练量偏大' : '训练频率偏高',
        content: warning == ImportWarning.excessiveVolume
            ? '该计划单日训练组数超过50组，可能不适合新手。确定要导入吗？'
            : '该计划每周训练超过7次，恢复压力较大。确定要导入吗？',
        confirmText: '确定导入',
        cancelText: '取消',
        confirmColor: ft.warningColor,
        icon: Icons.warning_amber_rounded,
      ).then((confirmed) {
        if (confirmed == true) {
          _executeImport(planData, ft);
        } else {
          setState(() => _processed = false);
          _controller.start();
        }
      });
    } else {
      _executeImport(planData, ft);
    }
  }

  void _executeImport(Map<String, dynamic> planData, FitTrackColors ft) {
    final newPlan = ShareCodeService.deepNormalizePlan(planData);
    newPlan.remove('author');
    newPlan.remove('sharedAt');
    newPlan['status'] = 'active';
    newPlan['progress'] = 0;
    newPlan['currentDayIndex'] = 0;
    ShareCodeService.instance.normalizeWeightFieldsPublic(newPlan);

    Storage.addPlan(newPlan);

    final author = ShareCodeService.instance.getAuthor(planData);
    FitToast.success(
      context,
      author != null
          ? '已导入「${planData['name'] ?? '计划'}」（来自$author）'
          : '已导入「${planData['name'] ?? '计划'}」',
    );

    Navigator.of(context).pop();
  }
}
```

- [ ] **Step 3: 在 router.dart 添加路由**

```dart
import 'pages/scan_import_page.dart';
```

添加路由：

```dart
GoRoute(
  path: '/scan-import',
  parentNavigatorKey: rootNavigatorKey,
  builder: (context, state) => const ScanImportPage(),
),
```

- [ ] **Step 4: 在 ShareCodePage 导入区添加扫码按钮**

在 `share_code_page.dart` 的 `_buildImportCard` 中，在"从剪贴板粘贴"按钮旁添加扫码按钮：

找到（约第416-428行）：
```dart
          Row(
            children: [
              TextButton.icon(
                onPressed: _pasteFromClipboard,
                icon: const Icon(Icons.paste, size: 16),
                label: const Text('从剪贴板粘贴'),
```

在 Row 的 children 中添加扫码按钮：

```dart
          Row(
            children: [
              TextButton.icon(
                onPressed: _pasteFromClipboard,
                icon: const Icon(Icons.paste, size: 16),
                label: const Text('从剪贴板粘贴'),
                style: TextButton.styleFrom(
                  foregroundColor: colors.infoColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
              TextButton.icon(
                onPressed: () => context.push('/scan-import'),
                icon: const Icon(Icons.qr_code_scanner, size: 16),
                label: const Text('扫码导入'),
                style: TextButton.styleFrom(
                  foregroundColor: colors.accentGlow,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
```

- [ ] **Step 5: 验证**

Run: `flutter analyze lib/pages/scan_import_page.dart lib/pages/share_code_page.dart lib/router.dart`
Expected: 无 error

---

### Task 5: 海报式计划导出（PlanPosterPage）

**Files:**
- Create: `lib/widgets/plan_poster_widget.dart` — 海报 Widget
- Create: `lib/pages/plan_poster_page.dart` — 海报页面
- Modify: `lib/router.dart` — 添加路由

- [ ] **Step 1: 创建 plan_poster_widget.dart**

```dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../data/storage.dart';
import '../services/share_code_service.dart';
import '../themes/app_themes.dart';

/// 训练计划海报 Widget（用于截图生成 PNG）
class PlanPosterWidget extends StatelessWidget {
  final Map<String, dynamic> plan;
  final String shareCode;
  final String shareString;

  const PlanPosterWidget({
    super.key,
    required this.plan,
    required this.shareCode,
    required this.shareString,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080,
      height: 1920,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部 Logo + 标题
              _buildHeader(),
              const SizedBox(height: 40),
              // 计划信息卡
              _buildPlanInfo(),
              const SizedBox(height: 30),
              // 训练日列表
              Expanded(child: _buildDaysList()),
              const SizedBox(height: 20),
              // 底部二维码 + 分享码
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B35),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text('💪', style: TextStyle(fontSize: 28)),
          ),
        ),
        const SizedBox(width: 16),
        const Text(
          'FitTrack',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Text(
          '训练计划',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanInfo() {
    final name = plan['name'] as String? ?? '未命名计划';
    final type = plan['type'] as String? ?? '';
    final difficulty = plan['difficulty'] as String? ?? '';
    final frequency = plan['frequency'] as String? ?? '';
    final author = plan['author'] as String?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (type.isNotEmpty) _buildTag(type),
              if (difficulty.isNotEmpty) ...[
                const SizedBox(width: 10),
                _buildTag(difficulty),
              ],
              if (frequency.isNotEmpty) ...[
                const SizedBox(width: 10),
                _buildTag(frequency),
              ],
            ],
          ),
          if (author != null) ...[
            const SizedBox(height: 8),
            Text(
              'by $author',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFFFFD700), fontSize: 16),
      ),
    );
  }

  Widget _buildDaysList() {
    final days = plan['days'] as List? ?? [];
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      itemBuilder: (ctx, i) {
        final day = days[i] as Map<String, dynamic>;
        final isRest = day['isRest'] == true;
        final label = day['label'] as String? ?? '第${i + 1}天';
        final muscle = day['muscle'] as String? ?? '';
        final exercises = (day['exercises'] as List?) ?? [];
        final totalSets = exercises.fold<int>(0, (sum, ex) {
          return sum + (((ex as Map)['sets'] as int?) ?? 0);
        });

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isRest
                ? const Color(0xFF4FC3F7).withOpacity(0.08)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRest
                  ? const Color(0xFF4FC3F7).withOpacity(0.2)
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isRest
                      ? const Color(0xFF4FC3F7).withOpacity(0.2)
                      : const Color(0xFFFF6B35).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: isRest ? const Color(0xFF4FC3F7) : const Color(0xFFFF6B35),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isRest
                          ? '休息日 · 充分恢复'
                          : '$muscle · ${exercises.length}个动作 · $totalSets组',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              if (isRest)
                const Text('😴', style: TextStyle(fontSize: 24))
              else
                const Text('🏋️', style: TextStyle(fontSize: 24)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // 二维码（若超限则不显示）
          if (shareString.length <= 800)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: shareString,
                version: QrVersions.auto,
                size: 120,
                gapless: true,
              ),
            )
          else
            Container(
              width: 136,
              height: 136,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('💪', style: TextStyle(fontSize: 48)),
              ),
            ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '扫码导入计划',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '或输入分享码：$shareCode',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '在 FitTrack App 中导入即可使用',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 创建 plan_poster_page.dart**

```dart
import 'package:flutter/material.dart';
import '../data/storage.dart';
import '../services/poster_generator.dart';
import '../services/share_code_service.dart';
import '../themes/app_themes.dart';
import '../widgets/plan_poster_widget.dart';
import '../widgets/poster_preview_dialog.dart';
import '../widgets/page_header.dart';

class PlanPosterPage extends StatefulWidget {
  final String planId;
  const PlanPosterPage({super.key, required this.planId});

  @override
  State<PlanPosterPage> createState() => _PlanPosterPageState();
}

class _PlanPosterPageState extends State<PlanPosterPage> {
  final GlobalKey _posterKey = GlobalKey();
  Map<String, dynamic>? _plan;
  String? _shareString;
  String? _shareCode;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _prepareData();
  }

  void _prepareData() {
    final plan = Storage.getPlanById(widget.planId);
    if (plan == null) return;

    final shareData = Map<String, dynamic>.from(plan);
    shareData.remove('id');
    shareData.remove('status');
    shareData.remove('progress');
    shareData.remove('createTime');
    shareData.remove('updateTime');
    shareData.remove('currentDayIndex');

    final settings = Storage.getSettings();
    final author = settings['nickname'] as String? ?? '匿名用户';
    final withAuthor =
        ShareCodeService.instance.attachAuthorSignature(shareData, author);

    final shareString =
        ShareCodeService.instance.generateShareableString(withAuthor);
    final code = shareString.split('|').first;

    setState(() {
      _plan = plan;
      _shareString = shareString;
      _shareCode = code;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ft = Theme.of(context).extension<FitTrackColors>()!;
    return Scaffold(
      backgroundColor: ft.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            title: '计划海报',
            isTabPage: false,
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: _plan == null
                ? const Center(child: CircularProgressIndicator())
                : _buildPreview(ft),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(FitTrackColors ft) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 海报预览（缩放展示）
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: RepaintBoundary(
              key: _posterKey,
              child: PlanPosterWidget(
                plan: _plan!,
                shareCode: _shareCode!,
                shareString: _shareString!,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // 操作按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generating ? null : _savePoster,
              icon: _generating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_alt, size: 20),
              label: Text(_generating ? '生成中...' : '保存海报'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ft.accentGlow,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _savePoster() async {
    setState(() => _generating = true);
    try {
      final imageBytes = await PosterGenerator.capture(_posterKey);
      if (!mounted) return;
      await PosterPreviewDialog.showFromBytes(context, imageBytes);
    } catch (e) {
      // 忽略
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }
}
```

- [ ] **Step 3: 检查 PosterGenerator 和 PosterPreviewDialog API**

检查 `lib/services/poster_generator.dart` 是否有 `capture(GlobalKey)` 方法，以及 `lib/widgets/poster_preview_dialog.dart` 是否有 `showFromBytes` 方法。若方法名不同，调整调用。

- [ ] **Step 4: 在 router.dart 添加路由**

```dart
import 'pages/plan_poster_page.dart';
```

添加路由：

```dart
GoRoute(
  path: '/plan-poster/:planId',
  parentNavigatorKey: rootNavigatorKey,
  builder: (context, state) => PlanPosterPage(
    planId: state.params['planId'] ?? '',
  ),
),
```

- [ ] **Step 5: 验证**

Run: `flutter analyze lib/widgets/plan_poster_widget.dart lib/pages/plan_poster_page.dart lib/router.dart`
Expected: 无 error

---

### Task 6: 音效系统搭建（SoundService + 素材生成）

**Files:**
- Modify: `pubspec.yaml` — 添加 audioplayers 依赖 + assets/audio/
- Create: `lib/services/sound_service.dart`
- Create: `tools/generate_sounds.py` — 合成音效脚本
- Create: `assets/audio/` 目录 + 8 个 .mp3 文件

- [ ] **Step 1: 添加 audioplayers 依赖**

在 pubspec.yaml 的 dependencies 中添加：

```yaml
  audioplayers: ^5.2.1
```

在 pubspec.yaml 的 assets 中添加：

```yaml
    - assets/audio/
```

Run: `flutter pub get`

- [ ] **Step 2: 创建音效生成脚本 tools/generate_sounds.py**

```python
#!/usr/bin/env python3
"""生成 FitTrack 所需的 8 个音效文件（合成正弦波/方波）"""
import struct
import math
import os
import zlib

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio')

def generate_tone(filename, frequency, duration, volume=0.3, waveform='sine'):
    """生成单音调 WAV 文件"""
    sample_rate = 44100
    num_samples = int(sample_rate * duration)
    samples = []
    for i in range(num_samples):
        t = i / sample_rate
        if waveform == 'sine':
            val = math.sin(2 * math.pi * frequency * t)
        elif waveform == 'square':
            val = 1.0 if math.sin(2 * math.pi * frequency * t) > 0 else -1.0
        else:
            val = math.sin(2 * math.pi * frequency * t)
        # 淡入淡出
        fade_samples = min(int(sample_rate * 0.01), num_samples // 4)
        if i < fade_samples:
            val *= i / fade_samples
        elif i > num_samples - fade_samples:
            val *= (num_samples - i) / fade_samples
        samples.append(int(val * volume * 32767))
    
    filepath = os.path.join(OUTPUT_DIR, filename.replace('.mp3', '.wav'))
    with open(filepath, 'wb') as f:
        # WAV header
        data_size = num_samples * 2
        f.write(b'RIFF')
        f.write(struct.pack('<I', 36 + data_size))
        f.write(b'WAVE')
        f.write(b'fmt ')
        f.write(struct.pack('<IHHIIHH', 16, 1, 1, sample_rate, sample_rate * 2, 2, 16))
        f.write(b'data')
        f.write(struct.pack('<I', data_size))
        for s in samples:
            f.write(struct.pack('<h', s))
    print(f'Generated: {filepath}')

def generate_chime(filename, frequencies, duration=0.3, volume=0.3):
    """生成多音调组合（和弦/旋律）"""
    sample_rate = 44100
    num_samples = int(sample_rate * duration)
    samples = []
    for i in range(num_samples):
        t = i / sample_rate
        val = 0
        for freq in frequencies:
            val += math.sin(2 * math.pi * freq * t) / len(frequencies)
        fade_samples = min(int(sample_rate * 0.02), num_samples // 4)
        if i < fade_samples:
            val *= i / fade_samples
        elif i > num_samples - fade_samples:
            val *= (num_samples - i) / fade_samples
        samples.append(int(val * volume * 32767))
    
    filepath = os.path.join(OUTPUT_DIR, filename.replace('.mp3', '.wav'))
    with open(filepath, 'wb') as f:
        data_size = num_samples * 2
        f.write(b'RIFF')
        f.write(struct.pack('<I', 36 + data_size))
        f.write(b'WAVE')
        f.write(b'fmt ')
        f.write(struct.pack('<IHHIIHH', 16, 1, 1, sample_rate, sample_rate * 2, 2, 16))
        f.write(b'data')
        f.write(struct.pack('<I', data_size))
        for s in samples:
            f.write(struct.pack('<h', s))
    print(f'Generated: {filepath}')

if __name__ == '__main__':
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    # 1. 完成一组 — 清脆短促的高音
    generate_tone('complete_set.wav', 1200, 0.1, volume=0.25)
    
    # 2. 训练完成 — 上升旋律
    generate_chime('complete_training.wav', [523, 659, 784, 1047], duration=0.6, volume=0.3)
    
    # 3. 休息开始 — 柔和中音
    generate_tone('rest_start.wav', 600, 0.2, volume=0.2)
    
    # 4. 休息结束 — 提醒铃声
    generate_chime('rest_end.wav', [880, 1100], duration=0.4, volume=0.3)
    
    # 5. 滴答声 — 短促方波
    generate_tone('tick.wav', 1500, 0.05, volume=0.15, waveform='square')
    
    # 6. 成就解锁 — 闪亮和弦
    generate_chime('achievement.wav', [659, 831, 988], duration=0.5, volume=0.3)
    
    # 7. 积分增加 — 金币声（两个快速高频音）
    generate_chime('points.wav', [1319, 1568], duration=0.15, volume=0.25)
    
    # 8. 按钮点击 — 轻触声
    generate_tone('button_tap.wav', 800, 0.03, volume=0.1)
    
    print('\n所有音效已生成到:', OUTPUT_DIR)
    print('注意：生成的是 WAV 格式，需要用 ffmpeg 转换为 MP3')
    print('批量转换命令：cd assets/audio && for %f in (*.wav) do ffmpeg -i "%f" -codec:a libmp3lame -qscale:a 2 "%~nf.mp3"')
```

- [ ] **Step 3: 运行脚本生成 WAV 音效**

Run: `python tools/generate_sounds.py`

- [ ] **Step 4: 用 ffmpeg 将 WAV 转为 MP3**

Run（在 assets/audio 目录下）:
```
cd assets/audio
for %f in (*.wav) do ffmpeg -i "%f" -codec:a libmp3lame -qscale:a 2 "%~nf.mp3"
```

若系统无 ffmpeg，则保留 WAV 文件，在 pubspec.yaml 中声明 `.wav` 资源。audioplayers 支持 WAV。

- [ ] **Step 5: 创建 sound_service.dart**

```dart
import 'package:audioplayers/audioplayers.dart';
import '../data/storage.dart';

/// 音效类型枚举
enum SoundType {
  completeSet,
  completeTraining,
  restStart,
  restEnd,
  tick,
  achievement,
  points,
  buttonTap,
}

/// 音效服务（单例）
///
/// 管理音效预加载与播放。
/// 通过 Storage.settings['soundEnabled'] 控制开关。
class SoundService {
  static final SoundService instance = SoundService._();
  SoundService._();

  final AudioPlayer _player = AudioPlayer();
  bool _initialized = false;
  bool _enabled = true;

  /// 音效文件路径映射
  static const Map<SoundType, String> _soundPaths = {
    SoundType.completeSet: 'sounds/complete_set.wav',
    SoundType.completeTraining: 'sounds/complete_training.wav',
    SoundType.restStart: 'sounds/rest_start.wav',
    SoundType.restEnd: 'sounds/rest_end.wav',
    SoundType.tick: 'sounds/tick.wav',
    SoundType.achievement: 'sounds/achievement.wav',
    SoundType.points: 'sounds/points.wav',
    SoundType.buttonTap: 'sounds/button_tap.wav',
  };

  /// 初始化（在 app 启动时调用）
  Future<void> init() async {
    if (_initialized) return;
    final settings = Storage.getSettings();
    _enabled = settings['soundEnabled'] != false; // 默认开启
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setVolume(0.6);
    _initialized = true;
  }

  /// 播放音效
  Future<void> play(SoundType type) async {
    if (!_enabled) return;
    if (!_initialized) await init();
    try {
      final path = _soundPaths[type];
      if (path == null) return;
      await _player.stop();
      await _player.play(AssetSource(path));
    } catch (_) {
      // 忽略播放错误（OHOS 兼容性问题等）
    }
  }

  /// 设置音效开关
  void setEnabled(bool enabled) {
    _enabled = enabled;
    final settings = Storage.getSettings();
    settings['soundEnabled'] = enabled;
    Storage.saveSettings(settings);
  }

  /// 获取当前开关状态
  bool get isEnabled => _enabled;
}
```

注意：音效文件放在 `assets/sounds/` 目录下（与 `assets/audio/` 合并，统一用 sounds）。

- [ ] **Step 6: 调整资源目录**

将生成的音效文件从 `assets/audio/` 移动到 `assets/sounds/`，并在 pubspec.yaml 中声明：

```yaml
  assets:
    - assets/data/system_plans/
    - assets/images/exercises/
    - assets/sounds/
```

- [ ] **Step 7: 在 main.dart 中初始化 SoundService**

在 app 启动时调用 `SoundService.instance.init()`。

找到 main.dart 中的初始化代码，在 Storage 初始化之后添加：

```dart
await SoundService.instance.init();
```

- [ ] **Step 8: 验证**

Run: `flutter analyze lib/services/sound_service.dart`
Expected: 无 error

---

### Task 7: 音效集成到核心功能

**Files:**
- Modify: `lib/pages/training_page.dart` — 完成一组/训练完成/休息开始/倒计时滴答
- Modify: `lib/services/rest_notification_service.dart` — 休息结束音效
- Modify: `lib/services/achievement_service.dart` — 成就解锁音效
- Modify: `lib/services/points_service.dart` — 积分增加音效
- Modify: `lib/pages/settings_page.dart` — 音效开关

- [ ] **Step 1: 在 training_page.dart 添加音效 import 和调用**

在文件顶部添加：
```dart
import '../services/sound_service.dart';
```

在 `_completeSet()` 方法中：

找到完成一组的分支（非最后一组），添加：
```dart
    SoundService.instance.play(SoundType.completeSet);
```

找到训练完成分支（`_trainingDone = true` 后），添加：
```dart
    SoundService.instance.play(SoundType.completeTraining);
```

在 `_startRest()` 方法开头添加：
```dart
    SoundService.instance.play(SoundType.restStart);
```

在 `_restartRestTimer()` 的 Timer 回调中，当 `remaining <= 3 && remaining > 0` 时添加：
```dart
      if (remaining <= 3 && remaining > 0) {
        SoundService.instance.play(SoundType.tick);
      }
```

- [ ] **Step 2: 在 rest_notification_service.dart 添加休息结束音效**

在文件顶部添加：
```dart
import 'sound_service.dart';
```

在 `_notifyRestEnd()` 方法中添加：
```dart
    SoundService.instance.play(SoundType.restEnd);
```

- [ ] **Step 3: 在 achievement_service.dart 添加成就解锁音效**

在文件顶部添加：
```dart
import 'sound_service.dart';
```

在成就解锁的方法中添加：
```dart
    SoundService.instance.play(SoundType.achievement);
```

- [ ] **Step 4: 在 points_service.dart 添加积分音效**

在文件顶部添加：
```dart
import 'sound_service.dart';
```

在 `addPoints()` 方法中添加：
```dart
    SoundService.instance.play(SoundType.points);
```

- [ ] **Step 5: 在 settings_page.dart 添加音效开关**

在设置页的"振动"开关附近添加"音效"开关：

```dart
SwitchListTile(
  title: Text('音效', style: TextStyle(color: colors.textPrimary)),
  subtitle: Text('训练反馈与提示音效', style: TextStyle(color: colors.textMuted, fontSize: 12)),
  value: SoundService.instance.isEnabled,
  activeColor: colors.accentGlow,
  onChanged: (val) {
    SoundService.instance.setEnabled(val);
    setState(() {});
    if (val) {
      SoundService.instance.play(SoundType.buttonTap);
    }
  },
),
```

- [ ] **Step 6: 验证**

Run: `flutter analyze lib/pages/training_page.dart lib/services/rest_notification_service.dart lib/services/achievement_service.dart lib/services/points_service.dart lib/pages/settings_page.dart`
Expected: 无 error

---

### Task 8: 最终验证

- [ ] **Step 1: 全量 analyze**

Run: `flutter analyze`
Expected: 无 error

- [ ] **Step 2: 构建验证**

Run: `flutter build apk --debug` 或 `flutter build hap --debug`
Expected: 构建成功

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat: 修复计划导入缺失+新增二维码/海报导出+音效系统"
```
