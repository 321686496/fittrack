import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/tutorial_content.dart';
import 'poster_theme.dart';

/// 动作分享海报 #6（教学动作分享卡片，对应 HTML #6）
///
/// 结构：品牌头(右上肌群徽标) → 动作名+副标 → 2×2 步骤卡片网格 → 分割线
/// → 输入邀请码 + 二维码。
///
/// 步骤卡片数据由调用方通过 [steps] 传入（来自 MockData.exerciseSteps）：
/// - 有图片：卡片主体为正方形示意图
/// - 无图片：省略示意图，仅编号 + 标题 + 描述
///
/// 宽度 1080、高度随内容自适应（可变高度，能展示全部步骤）。
/// 使用 [PosterBackground] 跟随主题。
class TutorialPoster extends StatelessWidget {
  final Tutorial tutorial;

  /// 二维码内容（默认指向 LiftTrack 教学入口）
  final String qrData;

  /// 展示的邀请码（底部展示）
  final String inviteCode;

  /// 训练步骤数据（含 title/desc/image）；为空时回退为「动作要点」列表
  final List<Map<String, dynamic>> steps;

  /// 海报主题 ID；为 null 时从全局 Settings 读取当前主题
  final String? themeId;

  const TutorialPoster({
    super.key,
    required this.tutorial,
    this.qrData = 'fittrack://tutorial',
    this.inviteCode = '',
    this.steps = const [],
    this.themeId,
  });

  static const double posterWidth = 1080.0;

  @override
  Widget build(BuildContext context) {
    final colors = PosterColors.fromThemeId(themeId);
    final t = tutorial;

    // 固定宽度 + 高度随内容自适应（步骤卡片网格/要点行数动态变化）。
    // 由捕获层 Path B（OverflowBox minHeight:0, maxHeight: 有限大）包裹，
    // RepaintBoundary 会随内容收缩到真实高度，不会因步骤数/是否有图
    // 变化而触发 RenderFlex overflow，也不会留下底部大段空白。
    return SizedBox(
      width: posterWidth,
      child: PosterBackground(
        colors: colors,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            PosterBrandHeader(
              colors: colors,
              subtitle: 'TUTORIAL',
              trailing: PostBadge(text: t.primaryMuscle.label, colors: colors),
            ),
            SizedBox(height: px(8)),
            SizedBox(height: px(16)),
            Text(
              '${t.name} · 标准动作',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: px(19),
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            SizedBox(height: px(4)),
            Text(
              '${t.difficulty.label} · ${t.equipment ?? '无器械'} · ${t.coachName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textMuted,
                fontSize: px(10),
              ),
            ),
            SizedBox(height: px(12)),
            _buildContent(colors),
            SizedBox(height: px(14)),
            _buildFooter(colors),
          ],
        ),
      ),
    );
  }

  /// 有步骤 → 每行 2 个，展示全部步骤；无步骤 → 编号动作要点列表
  Widget _buildContent(PosterColors colors) {
    if (steps.isNotEmpty) {
      // 每行 2 个，遍历所有步骤
      final rows = <Widget>[];
      for (int i = 0; i < steps.length; i += 2) {
        rows.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: _stepCard(
                    colors,
                    step: (i < steps.length) ? steps[i] : null,
                    index: i + 1)),
            if (i + 1 < steps.length) SizedBox(width: px(9)),
            if (i + 1 < steps.length)
              Expanded(
                  child: _stepCard(
                      colors,
                      step: (i + 1 < steps.length) ? steps[i + 1] : null,
                      index: i + 2)),
          ],
        ));
        if (i + 2 < steps.length) rows.add(SizedBox(height: px(9)));
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '动作要点',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: px(12),
            fontWeight: FontWeight.w800,
            letterSpacing: px(1),
          ),
        ),
        SizedBox(height: px(8)),
        ...tutorial.keyPoints.map((p) => _keyPointRow(colors, p)),
      ],
    );
  }

  Widget _keyPointRow(PosterColors colors, String p) {
    return Padding(
      padding: EdgeInsets.only(bottom: px(7)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: px(14),
            height: px(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.brand, colors.brandSecondary],
              ),
              borderRadius: BorderRadius.circular(px(4)),
            ),
            alignment: Alignment.center,
            margin: EdgeInsets.only(top: px(2)),
            child: Icon(Icons.check, size: px(9), color: Colors.white),
          ),
          SizedBox(width: px(6)),
          Expanded(
            child: Text(
              p,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: px(10),
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepCard(
    PosterColors colors, {
    required Map<String, dynamic>? step,
    required int index,
  }) {
    final title = (step?['title'] as String?) ?? '';
    final desc = (step?['desc'] as String?) ?? '';
    final image = (step?['image'] as String?) ?? '';
    final hasImage = image.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(px(8)),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(px(13)),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(color: colors.brand.withOpacity(0.10), blurRadius: px(7)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(px(9)),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => Container(
                    color: colors.cardBorder,
                  ),
                ),
              ),
            ),
            SizedBox(height: px(7)),
          ],
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _stepNumBadge(colors, index),
              SizedBox(width: px(5)),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: px(10),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: px(3)),
          if (desc.isNotEmpty)
            Text(
              desc,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: px(8),
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }

  Widget _stepNumBadge(PosterColors colors, int index) {
    return Container(
      width: px(14),
      height: px(14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.brand,
        borderRadius: BorderRadius.circular(px(4)),
      ),
      child: Text(
        '$index',
        style: TextStyle(
          color: Colors.white,
          fontSize: px(8),
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildFooter(PosterColors colors) {
    final code = inviteCode.isNotEmpty ? inviteCode : 'FIT-INV-XXXXXX';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(height: px(1), color: colors.cardBorder),
        SizedBox(height: px(12)),
        Row(
          children: [
            Icon(Icons.card_giftcard, size: px(16), color: colors.brand),
            SizedBox(width: px(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '输入邀请码，双方得福利',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: px(9),
                    ),
                  ),
                  SizedBox(height: px(2)),
                  Text(
                    code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.brand,
                      fontSize: px(14),
                      fontWeight: FontWeight.w800,
                      letterSpacing: px(2),
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: px(10)),
            Container(
              width: px(40),
              height: px(40),
              padding: EdgeInsets.all(px(4)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(px(11)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: px(10),
                    offset: Offset(0, px(4)),
                  ),
                ],
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                gapless: true,
                backgroundColor: Colors.white,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: colors.textPrimary,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: colors.textPrimary,
                ),
                // 兜底：数据过长无法编码时，避免渲染成白底空容器
                errorStateBuilder: (context, error) => Center(
                  child:
                      Icon(Icons.qr_code, size: px(9), color: colors.textMuted),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}