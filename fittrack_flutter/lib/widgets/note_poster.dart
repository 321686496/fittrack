import 'package:flutter/material.dart';
import '../data/training_note.dart';
import '../services/invitation_service.dart';
import 'poster_theme.dart';

/// 训练笔记海报（海报3，对应 HTML #3）
///
/// 宽度 1080 固定、高度随内容自适应（正文/酸痛标签行数可变，不使用固定高度，
/// 由捕获层 Path B 按内容实际高度渲染，避免 RenderFlex 溢出或底部空白）。
/// 使用 [PosterBackground] 跟随主题。
/// 布局：品牌头 + 精选徽标、日期/感受、心得标题与正文、四列数据条、
/// 最满意动作、酸痛部位标签、底部二维码（输入邀请码）。
class NotePosterContent extends StatelessWidget {
  final TrainingNote note;
  final Map<String, dynamic>? boundRecord;

  /// 海报主题 ID；为 null 时从全局 Settings 读取当前主题
  final String? themeId;

  /// 保留接口兼容，Overlay 模式下由调用方在外层设置 RepaintBoundary key
  final GlobalKey? posterKey;

  const NotePosterContent({
    super.key,
    required this.note,
    this.boundRecord,
    this.themeId,
    this.posterKey,
  });

  /// 海报宽度常量
  static const double posterWidth = 1080.0;

  @override
  Widget build(BuildContext context) {
    final colors = PosterColors.fromThemeId(themeId);
    final hasRecord = boundRecord != null;
    final inviteCode = InvitationService.instance.generateInvitationCode();

    // 心得标题 = 首行非空；正文 = 剩余行
    final lines = note.content
        .split(RegExp(r'\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final title = lines.isNotEmpty ? lines.first : '';
    final body = lines.length > 1 ? lines.skip(1).join('\n').trim() : '';

    // 日期：YYYY-MM-DD
    final d = DateTime.fromMillisecondsSinceEpoch(note.createTime);
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
              subtitle: 'TRAINING NOTE',
              trailing: note.isFeatured
                  ? PostBadge(text: '精选', colors: colors)
                  : null,
            ),
            // ── 日期 + 感受 ──────────────────────
            SizedBox(height: px(16)),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: px(11), color: colors.textMuted),
                SizedBox(width: px(8)),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: px(10),
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(width: px(8)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: px(8), vertical: px(3)),
                  decoration: BoxDecoration(
                    color: colors.cardBg,
                    borderRadius: BorderRadius.circular(px(8)),
                  ),
                  child: Text(
                    '感受 · ${note.feelingLabel}',
                    style: TextStyle(
                      color: colors.brand,
                      fontSize: px(9),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            // ── 心得标题 + 正文 ──────────────────
            if (title.isNotEmpty) ...[
              SizedBox(height: px(14)),
              Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: px(20),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  height: 1.3,
                ),
              ),
            ],
            if (body.isNotEmpty) ...[
              SizedBox(height: px(8)),
              Text(
                body,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: px(15),
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
            ],
            // ── 训练数据条（4 列等分）────────────
            if (hasRecord) ...[
              SizedBox(height: px(16)),
              _buildNoteBar(colors),
            ],
            // ── 最满意动作 ───────────────────────
            if (note.bestExercise.isNotEmpty) ...[
              SizedBox(height: px(12)),
              Row(
                children: [
                  Icon(Icons.star, size: px(14), color: colors.brand),
                  SizedBox(width: px(10)),
                  Expanded(
                    child: Text(
                      '最满意：${note.bestExercise}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: px(11),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            // ── 酸痛部位标签 ─────────────────────
            if (note.soreParts.isNotEmpty) ...[
              SizedBox(height: px(10)),
              Wrap(
                spacing: px(6),
                runSpacing: px(6),
                children: note.soreParts
                    .take(5)
                    .map((p) => PostBadge(text: p, colors: colors))
                    .toList(),
              ),
            ],
            // ── 底部二维码 ───────────────────────
            PosterQrFooter(
              colors: colors,
              qrData: 'fittrack://invite?code=$inviteCode',
              hint: '输入邀请码，双方得福利',
              sub: 'LiftTrack · 训练笔记',
            ),
          ],
        ),
      ),
    );
  }

  /// 训练数据四列条（时长/总重量/组数/部位）
  Widget _buildNoteBar(PosterColors colors) {
    final r = boundRecord!;
    final muscles = (r['muscles'] as List?)?.cast<String>() ?? [];
    final duration = ((r['duration'] ?? 0) as num).toInt();
    final totalWeight = ((r['totalWeight'] ?? 0) as num).toInt();
    final totalSets = ((r['totalSets'] ?? 0) as num).toInt();
    final mins = (duration / 60).round();
    final part = muscles.take(2).join('/');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: px(8), vertical: px(12)),
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
          _noteCol(colors, '${mins}min', '时长'),
          _vDivider(colors),
          _noteCol(colors, '${totalWeight}kg', '总重量'),
          _vDivider(colors),
          _noteCol(colors, '$totalSets', '组数'),
          _vDivider(colors),
          _noteCol(colors, part.isEmpty ? '—' : part, '部位'),
        ],
      ),
    );
  }

  Widget _noteCol(PosterColors colors, String value, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: px(13),
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          SizedBox(height: px(4)),
          Text(
            label,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: px(8),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider(PosterColors colors) {
    return Container(
      width: px(1),
      height: px(36),
      margin: EdgeInsets.symmetric(horizontal: px(6)),
      color: colors.cardBorder,
    );
  }
}