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
    final withAuthor = ShareCodeService.instance.attachAuthorSignature(shareData, author);

    final shareString = ShareCodeService.instance.generateShareableString(withAuthor);
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
          PageHeader(title: '计划海报', isTabPage: false, onBack: () => Navigator.of(context).pop()),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: RepaintBoundary(
              key: _posterKey,
              child: PlanPosterWidget(plan: _plan!, shareCode: _shareCode!, shareString: _shareString!),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generating ? null : _savePoster,
              icon: _generating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_alt, size: 20),
              label: Text(_generating ? '生成中...' : '保存海报'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ft.accentGlow,
                foregroundColor: Colors.white,
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

  Future<void> _savePoster() async {
    setState(() => _generating = true);
    try {
      final imagePath = await PosterGenerator.capture(_posterKey);
      if (!mounted) return;
      await PosterPreviewDialog.show(context, imagePath: imagePath, title: '计划海报');
    } catch (e) {
      // 忽略
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }
}
