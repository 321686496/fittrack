import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'poster_theme.dart';

/// 训练计划海报（海报4，对应 HTML #4）
///
/// 宽度 1080、高度 2274（对齐 HTML 设计稿 304×640 的宽高比，px() 按 1080/304
/// 等比放大，高度 = 640 × (1080/304) ≈ 2274，避免内容挤压导致的排版错乱）。
/// 使用 [PosterBackground] 跟随主题。
/// 布局：品牌头、计划信息卡（名称 + 标签）、训练日列表、底部扫码导入。
class PlanPosterWidget extends StatelessWidget {
  final Map<String, dynamic> plan;
  final String shareCode;
  final String shareString;

  /// 海报主题 ID；为 null 时从全局 Settings 读取当前主题
  final String? themeId;

  const PlanPosterWidget({
    super.key,
    required this.plan,
    required this.shareCode,
    required this.shareString,
    this.themeId,
  });

  /// 海报宽度常量
  static const double posterWidth = 1080.0;

  /// 海报高度常量
  static const double posterHeight = 2274.0;

  @override
  Widget build(BuildContext context) {
    final colors = PosterColors.fromThemeId(themeId);
    final name = plan['name'] as String? ?? '未命名计划';
    final type = plan['type'] as String? ?? '';
    final difficulty = plan['difficulty'] as String? ?? '';
    final frequency = plan['frequency'] as String? ?? '';
    final author = plan['author'] as String?;

    return SizedBox(
      width: posterWidth,
      height: posterHeight,
      child: PosterBackground(
        colors: colors,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            PosterBrandHeader(colors: colors, subtitle: 'PLAN'),
            // ── 计划信息卡 ───────────────────────
            SizedBox(height: px(16)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: px(16), vertical: px(14)),
              decoration: BoxDecoration(
                color: colors.cardBg,
                borderRadius: BorderRadius.circular(px(16)),
                border: Border.all(color: colors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: colors.brand.withOpacity(0.10),
                    blurRadius: px(9),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '训练计划 · PLAN',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: px(9),
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: px(5)),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: px(17),
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: px(9)),
                  Wrap(
                    spacing: px(6),
                    runSpacing: px(6),
                    children: [
                      if (type.isNotEmpty) PostBadge(text: type, colors: colors),
                      if (difficulty.isNotEmpty)
                        PostBadge(text: difficulty, colors: colors),
                      if (frequency.isNotEmpty)
                        PostBadge(text: frequency, colors: colors),
                      if (author != null && author.isNotEmpty)
                        PostBadge(text: 'by $author', colors: colors),
                    ],
                  ),
                ],
              ),
            ),
            // ── 训练日列表 ───────────────────────
            SizedBox(height: px(13)),
            Column(
              children: _buildDays(colors),
            ),
            // ── 底部扫码导入 ─────────────────────
            const Spacer(),
            _buildFooter(colors),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDays(PosterColors colors) {
    final days = plan['days'] as List? ?? [];
    return List.generate(days.length.clamp(0, 5), (i) {
      final day = days[i] as Map<String, dynamic>;
      final isRest = day['isRest'] == true;
      final label = day['label'] as String? ?? '第${i + 1}天';
      final muscle = day['muscle'] as String? ?? '';
      final exercises = (day['exercises'] as List?) ?? [];
      final totalSets = exercises.fold<int>(
        0,
        (sum, ex) => sum + (((ex as Map)['sets'] as int?) ?? 0),
      );

      String title;
      String sub;
      if (isRest) {
        title = '休息日 · 充分恢复';
        sub = '拉伸 / 放松';
      } else {
        title = label;
        final parts = <String>[
          if (muscle.isNotEmpty) muscle,
          '${exercises.length}个动作',
          '$totalSets组',
        ];
        sub = parts.join(' · ');
      }

      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: px(7)),
        padding: EdgeInsets.symmetric(horizontal: px(10), vertical: px(7)),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(px(11)),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Row(
          children: [
            // 序号块
            Container(
              width: px(24),
              height: px(24),
              decoration: BoxDecoration(
                color: isRest
                    ? colors.brandSecondary.withOpacity(0.25)
                    : colors.brand,
                borderRadius: BorderRadius.circular(px(7)),
              ),
              alignment: Alignment.center,
              child: Text(
                isRest ? 'R' : '${i + 1}',
                style: TextStyle(
                  fontSize: px(11),
                  fontWeight: FontWeight.w800,
                  color: isRest
                      ? colors.brandSecondary
                      : Colors.white,
                ),
              ),
            ),
            SizedBox(width: px(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: px(12),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: px(3)),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: px(9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFooter(PosterColors colors) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(px(14)),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(px(16)),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(color: colors.brand.withOpacity(0.10), blurRadius: px(9)),
        ],
      ),
      child: Row(
        children: [
          // 二维码
          Container(
            width: px(52),
            height: px(52),
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
            child: shareString.length <= 800
                ? QrImageView(
                    data: shareString,
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
                  )
                : Icon(Icons.fitness_center,
                    size: px(20), color: colors.textPrimary),
          ),
          SizedBox(width: px(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '扫码导入计划',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: px(12),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: px(3)),
                Text(
                  '或输入分享码：$shareCode',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: px(9),
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