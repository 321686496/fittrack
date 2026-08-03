import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final withAuthor = ShareCodeService.instance.attachAuthorSignature(shareData, author);

    final shareString = ShareCodeService.instance.generateShareableString(withAuthor);
    final code = shareString.split('|').first;

    if (shareString.length > 2900) {
      setState(() {
        _errorMessage = '计划数据过大（${shareString.length}字符），二维码无法承载。\n请使用文本分享码方式分享。';
      });
      return;
    }

    setState(() {
      _shareString = shareString;
      _shareCode = code;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ft = Theme.of(context).extension<LiftTrackColors>()!;
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

  Widget _buildError(LiftTrackColors ft) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: ft.warningColor),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center,
                style: TextStyle(color: ft.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(LiftTrackColors ft) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: QrImageView(
              data: _shareString!,
              version: QrVersions.auto,
              size: 240,
              gapless: true,
              errorStateBuilder: (ctx, err) => Center(
                child: Text('二维码生成失败', style: TextStyle(color: ft.warningColor, fontSize: 14)),
              ),
            ),
          ),
          const SizedBox(height: 16),
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
                SelectableText(_shareCode!, style: TextStyle(color: ft.accentGlow, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 2)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('好友可通过扫码或粘贴分享串导入此计划', style: TextStyle(color: ft.textMuted, fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _shareString!));
                FitToast.success(context, '分享串已复制');
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('复制分享串'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ft.accentGlow,
                side: BorderSide(color: ft.accentGlow.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
