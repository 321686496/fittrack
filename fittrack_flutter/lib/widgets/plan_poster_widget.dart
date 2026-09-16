import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'poster_theme.dart';

/// 训练计划海报（海报4，对应 HTML #4）
///
/// 宽度 1080 固定、高度随内容自适应（训练日最多 5 天，行数不固定，不使用
/// 固定高度，由捕获层按内容实际高度渲染，避免 RenderFlex 溢出或底部空白、
/// 以及底部二维码被裁剪）。使用 [PosterBackground] 跟随主题。
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

  @override
  Widget build(BuildContext context) {
    final colors = PosterColors.fromThemeId(themeId);
    final name = plan['name'] as String? ?? '未命名计划';
    final type = plan['type'] as String? ?? '';
    final difficulty = plan['difficulty'] as String? ?? '';
    final frequency = plan['frequency'] as String? ?? '';
    final author = plan['author'] as String?;

    // 固定宽度 + 高度随内容自适应。由捕获层按内容实际高度渲染，
    // 训练日（最多 5 天）行数不定时既不会 RenderFlex 溢出，也不留底部空白，
    // 底部扫码二维码始终位于真实内容末尾、不被裁剪。
    return SizedBox(
      width: posterWidth,
      child: PosterBackground(
        colors: colors,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            SizedBox(height: px(13)),
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
            // 真实分享串 = "FITT-XXXXXX|<base64-json>"，扫码即可导入该计划。
            // 使用最低纠错级 L + 自适应版本，最大化可编码容量（version 40 字节模式
            // 约 2953 字节），保证常见计划串能渲染出真实可导入的二维码。
            // 若分享串仍过长无法编码，交给 errorStateBuilder 兜底显示图标，
            // 绝不出现"白底空容器"。
            child: QrImageView(
              data: shareString,
              version: QrVersions.auto,
              errorCorrectionLevel: QrErrorCorrectLevel.L,
              gapless: true,
              backgroundColor: Colors.white,
              // 近黑色高对比，保证缩小后仍清晰可扫（不用主题 textPrimary）
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: const Color(0xFF1C1C1E),
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: const Color(0xFF1C1C1E),
              ),
              errorStateBuilder: (context, error) => Center(
                child: Icon(Icons.fitness_center,
                    size: px(20), color: colors.textPrimary),
              ),
            ),
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