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
    // 预览：海报宽度固定 1080，高度随内容自适应（训练日数量不定）。
    // 使用"先测量内容尺寸 → 计算缩放系数 → 外层 SizedBox 按缩放尺寸占位
    // → Transform 实际缩放原图"三步法，彻底避免：
    //  1. FittedBox(scaleDown) 在无界高度下变成无限高度（bug根源）
    //  2. 只缩放视觉不缩放布局导致外层占位不正确（按钮位置过远）
    //  3. 因宽度约束宽松导致 Column.mainAxisSize.min 无法正常收缩
    const posterW = PlanPosterWidget.posterWidth;
    return LayoutBuilder(
      builder: (context, constraints) {
        // 可用宽度 = 屏宽减去 ScrollView 左右内边距
        final availW = constraints.maxWidth - 16 * 2;
        // 缩放系数：确保海报完整适配屏幕宽度，不放大，只缩小
        final scale = (availW / posterW).clamp(0.2, 1.0);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 先通过 _MeasuredPoster 量出海报内容的真实高度（高度随训练日
              // 数量动态变化），再据此构造缩放后的占位布局
              _MeasuredPoster(
                plan: _plan!,
                shareCode: _shareCode!,
                shareString: _shareString!,
                posterWidth: posterW,
                scale: scale,
                builder: (measuredHeight) {
                  // 外层 SizedBox 预留缩放后的尺寸，使按钮位置紧贴海报底部
                  return SizedBox(
                    width: posterW * scale,
                    height: measuredHeight * scale,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Transform.scale(
                        scale: scale,
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: posterW,
                          height: measuredHeight,
                          child: PlanPosterWidget(
                            plan: _plan!,
                            shareCode: _shareCode!,
                            shareString: _shareString!,
                          ),
                        ),
                      ),
                    ),
                  );
                },
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

/// 海报预览测量器
///
/// 海报高度随内容自适应（训练日数量不定），无法预知高度。本组件把海报在
/// Offstage 中按固定宽 [posterWidth] 完整排版一次，通过 RenderBox 拿到真实
/// 内容高度后，调 [builder] 以缩放后的尺寸占位渲染。Offstage 只排版不占
/// 布局空间，因此不会引入多余的滚动高度；测量完成后 setState 触发重建，
/// 外层按 `height * scale` 预留空间，保证保存按钮紧贴海报底部。
class _MeasuredPoster extends StatefulWidget {
  final Map<String, dynamic> plan;
  final String shareCode;
  final String shareString;
  final double posterWidth;
  final double scale;
  final Widget Function(double measuredHeight) builder;

  const _MeasuredPoster({
    required this.plan,
    required this.shareCode,
    required this.shareString,
    required this.posterWidth,
    required this.scale,
    required this.builder,
  });

  @override
  State<_MeasuredPoster> createState() => _MeasuredPosterState();
}

class _MeasuredPosterState extends State<_MeasuredPoster> {
  final GlobalKey _measureKey = GlobalKey();
  double _height = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    if (_height > 0) return;
    final ctx = _measureKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final h = box.size.height;
    if (h > 0 && mounted && h != _height) {
      setState(() => _height = h);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 尺寸未就绪时先占一位，并继续在后续帧重测，直到拿到真实内容高度
    if (_height <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    }
    // 测量用 Offstage 无论是否就绪都排版
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Offstage(
          offstage: true,
          child: SizedBox(
            width: widget.posterWidth,
            height: widget.posterWidth * 6, // 保险上限，实际被子项收缩
            child: OverflowBox(
              minWidth: widget.posterWidth,
              maxWidth: widget.posterWidth,
              minHeight: 0,
              maxHeight: widget.posterWidth * 6,
              alignment: Alignment.topLeft,
              child: SizedBox(
                key: _measureKey,
                width: widget.posterWidth,
                child: PlanPosterWidget(
                  plan: widget.plan,
                  shareCode: widget.shareCode,
                  shareString: widget.shareString,
                ),
              ),
            ),
          ),
        ),
        if (_height > 0) widget.builder(_height),
      ],
    );
  }
}
