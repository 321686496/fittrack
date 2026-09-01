import 'package:flutter/material.dart';
import '../data/storage.dart';
import '../services/share_code_service.dart';
import '../themes/app_themes.dart';
import '../widgets/plan_poster_widget.dart';
import '../widgets/poster_capture_helper.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

class PlanPosterPage extends StatefulWidget {
  final String planId;
  const PlanPosterPage({super.key, required this.planId});

  @override
  State<PlanPosterPage> createState() => _PlanPosterPageState();
}

class _PlanPosterPageState extends State<PlanPosterPage> {
  Map<String, dynamic>? _plan;
  String? _shareString;
  String? _shareCode;

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
    final ft = Theme.of(context).extension<LiftTrackColors>()!;
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

  Widget _buildPreview(LiftTrackColors ft) {
    // 预览：将固定 1080×2274 的海报等比缩放到屏幕宽度以内，
    // 保持原始宽高比，避免在窄屏上被挤压/裁剪导致布局变形。
    // 实际截图仍走 PosterCaptureHelper 离屏渲染（固定 1080px 宽度）。
    return LayoutBuilder(
      builder: (context, constraints) {
        final availWidth = constraints.maxWidth - 32; // 减去左右 padding
        final scale = (availWidth / PlanPosterWidget.posterWidth).clamp(0.2, 1.0);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                width: availWidth > 0 ? availWidth : 1,
                height: PlanPosterWidget.posterHeight * scale,
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: PlanPosterWidget.posterWidth,
                    height: PlanPosterWidget.posterHeight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: PlanPosterWidget(
                        plan: _plan!,
                        shareCode: _shareCode!,
                        shareString: _shareString!,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _savePoster,
                  icon: const Icon(Icons.save_alt, size: 20),
                  label: const Text('保存海报'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ft.accentGlow,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Future<void> _savePoster() async {
    try {
      await PosterCaptureHelper.captureAndPreview(
        context,
        posterWidget: PlanPosterWidget(
          plan: _plan!,
          shareCode: _shareCode!,
          shareString: _shareString!,
        ),
        posterWidth: PlanPosterWidget.posterWidth,
        title: '计划海报',
        fileNamePrefix: 'fittrack_plan_poster',
      );
    } catch (e) {
      if (mounted) {
        FitToast.error(context, '海报生成失败：$e');
      }
    }
  }
}
