import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';
import '../services/share_code_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

/// v1 训练计划分享码页面
///
/// 依据：docs/versions/v1-获客留存版/02_功能清单.md §E4
/// UI规格：docs/versions/v1-获客留存版/05_UI设计文档.md §7.4
///
/// 两大区域：
/// 1. 生成分享码（选计划 → 生成 FITT-XXXXXX 码 + 完整分享串）
/// 2. 导入分享码（粘贴分享串 → 校验 → 导入计划）
class ShareCodePage extends StatefulWidget {
  const ShareCodePage({super.key});

  @override
  State<ShareCodePage> createState() => _ShareCodePageState();
}

class _ShareCodePageState extends State<ShareCodePage> {
  // ── 生成分享码 ──
  List<Map<String, dynamic>> _plans = [];
  String? _selectedPlanId;
  String? _generatedCode;
  String? _generatedShareString;

  // ── 导入分享码 ──
  final _importController = TextEditingController();
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  void _loadPlans() {
    _plans = Storage.getPlans();
    setState(() {});
  }

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            title: '计划分享',
            subtitle: '生成分享码或导入好友的计划',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGenerateCard(colors),
                  const SizedBox(height: 16),
                  _buildImportCard(colors),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 生成分享码 ──────────────────────────────────────────────

  Widget _buildGenerateCard(FitTrackColors colors) {
    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.qr_code, size: 20, color: colors.accentGlow),
              const SizedBox(width: 8),
              Text(
                '生成分享码',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_plans.isEmpty)
            _buildEmptyPlans(colors)
          else ...[
            _buildPlanSelector(colors),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedPlanId == null ? null : _generateCode,
                icon: const Icon(Icons.qr_code_2, size: 18),
                label: const Text('生成分享码'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentGlow,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
          if (_generatedCode != null) ...[
            const SizedBox(height: 16),
            _buildGeneratedResult(colors),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyPlans(FitTrackColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: colors.textMuted),
          const SizedBox(height: 8),
          Text(
            '暂无训练计划',
            style: TextStyle(color: colors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelector(FitTrackColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择要分享的计划',
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 8),
        ..._plans.map((plan) => _buildPlanOption(colors, plan)),
      ],
    );
  }

  Widget _buildPlanOption(FitTrackColors colors, Map<String, dynamic> plan) {
    final planId = plan['id'] as String? ?? '';
    final isSelected = _selectedPlanId == planId;

    return GestureDetector(
      onTap: () => _selectPlan(planId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.accentGlow.withOpacity(0.08)
              : colors.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colors.accentGlow.withOpacity(0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: isSelected ? colors.accentGlow : colors.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan['name'] as String? ?? '未命名计划',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${plan['frequency'] ?? ''} · ${plan['difficulty'] ?? ''}',
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectPlan(String planId) {
    setState(() {
      _selectedPlanId = planId;
      _generatedCode = null;
      _generatedShareString = null;
    });
  }

  void _generateCode() {
    if (_selectedPlanId == null) return;
    final plan = _plans.firstWhere(
      (p) => p['id'] == _selectedPlanId,
      orElse: () => <String, dynamic>{},
    );
    if (plan.isEmpty) return;

    // 清理计划数据用于分享（去掉本地状态字段）
    final shareData = Map<String, dynamic>.from(plan);
    shareData.remove('id');
    shareData.remove('status');
    shareData.remove('progress');
    shareData.remove('createTime');
    shareData.remove('updateTime');

    // 添加作者署名
    final settings = Storage.getSettings();
    final author = settings['nickname'] as String? ?? '匿名用户';
    ShareCodeService.instance.attachAuthorSignature(shareData, author);

    final shareString = ShareCodeService.instance.generateShareableString(shareData);
    final code = shareString.split('|').first;

    setState(() {
      _generatedCode = code;
      _generatedShareString = shareString;
    });
  }

  Widget _buildGeneratedResult(FitTrackColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: colors.accentGlow.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.accentGlow.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Text(
                '分享码',
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 4),
              SelectableText(
                _generatedCode!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.accentGlow,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '完整分享串（含计划数据，可复制发送）：',
          style: TextStyle(color: colors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.bgSecondary,
            borderRadius: BorderRadius.circular(8),
          ),
          constraints: const BoxConstraints(maxHeight: 80),
          child: SingleChildScrollView(
            child: SelectableText(
              _generatedShareString!,
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _copyString(colors),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('复制分享串'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.accentGlow,
                  side: BorderSide(color: colors.accentGlow.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _shareString(),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('分享'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentGlow,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _copyString(FitTrackColors colors) {
    Clipboard.setData(ClipboardData(text: _generatedShareString!));
    FitToast.success(context, '分享串已复制');
  }

  void _shareString() {
    Share.share(
      _generatedShareString!,
      subject: 'FitTrack 训练计划分享',
    );
  }

  // ── 导入分享码 ──────────────────────────────────────────────

  Widget _buildImportCard(FitTrackColors colors) {
    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.download_for_offline, size: 20, color: colors.accentGlow),
              const SizedBox(width: 8),
              Text(
                '导入计划',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '粘贴好友发送的分享串（FITT-XXXXXX|... 格式）',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _importController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '粘贴分享串...',
              hintStyle: TextStyle(color: colors.textMuted),
              filled: true,
              fillColor: colors.bgSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
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
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _importing ? null : _import,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentGlow,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: _importing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('导入计划', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      _importController.text = data!.text!;
    }
  }

  Future<void> _import() async {
    final input = _importController.text.trim();
    if (input.isEmpty) {
      FitToast.info(context, '请粘贴分享串');
      return;
    }

    setState(() => _importing = true);
    final result = ShareCodeService.instance.importFromString(input);
    setState(() => _importing = false);

    if (!mounted) return;

    final colors = Theme.of(context).extension<FitTrackColors>()!;

    // 处理结果
    switch (result.result) {
      case ShareCodeResult.success:
        if (result.planData != null) {
          // 有完整计划数据，检查警告
          if (result.warning == ImportWarning.excessiveVolume) {
            _showWarningDialog(
              colors,
              '训练量偏大',
              '该计划单日训练组数超过50组，可能不适合新手。确定要导入吗？',
              () => _doImport(result.planData!, colors),
            );
          } else if (result.warning == ImportWarning.excessiveFrequency) {
            _showWarningDialog(
              colors,
              '训练频率偏高',
              '该计划每周训练超过7次，恢复压力较大。确定要导入吗？',
              () => _doImport(result.planData!, colors),
            );
          } else {
            _doImport(result.planData!, colors);
          }
        } else {
          // 仅6位码，无计划内容
          FitToast.warning(
            context,
            '分享码验证通过，但未包含计划数据。\n请让好友复制完整分享串发送。',
          );
        }
        break;
      case ShareCodeResult.invalidFormat:
        FitToast.error(context, '格式错误：应以 FITT- 开头');
        break;
      case ShareCodeResult.invalidSignature:
        FitToast.error(context, '分享码签名无效，可能已损坏');
        break;
      case ShareCodeResult.payloadTooLarge:
        FitToast.error(context, '计划数据过大');
        break;
      case ShareCodeResult.decodeError:
        FitToast.error(context, '解析失败，分享串可能不完整');
        break;
    }
  }

  void _showWarningDialog(
    FitTrackColors colors,
    String title,
    String content,
    VoidCallback onConfirm,
  ) {
    ConfirmDialog.show(
      context,
      title: title,
      content: content,
      confirmText: '确定导入',
      cancelText: '取消',
      confirmColor: colors.warningColor,
      icon: Icons.warning_amber_rounded,
    ).then((confirmed) {
      if (confirmed == true) {
        onConfirm();
      }
    });
  }

  void _doImport(Map<String, dynamic> planData, FitTrackColors colors) {
    // 清理分享方字段，生成本地新计划
    final newPlan = Map<String, dynamic>.from(planData);
    newPlan.remove('author');
    newPlan.remove('sharedAt');
    newPlan['status'] = 'active';
    newPlan['progress'] = 0;

    final author = ShareCodeService.instance.getAuthor(planData);
    Storage.addPlan(newPlan);

    FitToast.success(
      context,
      author != null
          ? '已导入「${planData['name'] ?? '计划'}」（来自$author）'
          : '已导入「${planData['name'] ?? '计划'}」',
    );

    _importController.clear();
    _loadPlans();
  }
}
