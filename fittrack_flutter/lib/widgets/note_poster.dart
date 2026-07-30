import 'package:flutter/material.dart';
import '../data/training_note.dart';
import '../services/invitation_service.dart';
import 'poster_theme.dart';

/// 训练笔记海报内容组件
///
/// 宽度固定 1080，高度随内容自适应。
/// 使用 [PosterBackground] 跟随用户当前 App 主题。
/// 调用方通过 [Overlay] + [OverflowBox] 离屏渲染本组件，
/// 用 [PosterGenerator.capture] 截图为 PNG 后弹出 [PosterPreviewDialog]。
class NotePosterContent extends StatefulWidget {
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

  /// 海报宽度常量（高度随内容自适应）
  static const double posterWidth = 1080.0;

  /// 海报高度常量（用于 Overlay 离屏渲染时的固定尺寸）
  static const double posterHeight = 1920.0;

  @override
  State<NotePosterContent> createState() => _NotePosterContentState();
}

class _NotePosterContentState extends State<NotePosterContent> {
  late String _inviteCode;
  late final PosterColors _colors;

  @override
  void initState() {
    super.initState();
    _inviteCode = InvitationService.instance.generateInvitationCode();
    _colors = PosterColors.fromThemeId(widget.themeId);
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final hasRecord = widget.boundRecord != null;

    return PosterBackground(
      colors: _colors,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 72, vertical: 72),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 顶部品牌区 ────────────────────────────
            Row(
              children: [
                PosterBrandHeader(colors: _colors),
                const Spacer(),
                if (note.isFeatured)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_colors.brand, _colors.brandSecondary],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '精选',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 48),
            // ── 日期 + 感受 ──────────────────────────
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 22, color: _colors.textMuted),
                const SizedBox(width: 8),
                Text(
                  note.dateLabel,
                  style: TextStyle(
                    color: _colors.textMuted,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _colors.brand.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '感受 · ${note.feelingLabel}',
                    style: TextStyle(
                      color: _colors.brand,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            // ── 心得文字（核心内容）────────────────────
            if (note.content.isNotEmpty)
              Text(
                note.content,
                style: TextStyle(
                  color: _colors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            const SizedBox(height: 36),
            // ── 训练数据卡片 ─────────────────────────
            if (hasRecord) ...[
              _buildTrainingData(),
              const SizedBox(height: 24),
            ],
            // ── 最满意动作 ───────────────────────────
            if (note.bestExercise.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.star, size: 26, color: _colors.brand),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '最满意：${note.bestExercise}',
                      style: TextStyle(
                        color: _colors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            // ── 酸痛部位 ─────────────────────────────
            if (note.soreParts.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: note.soreParts.take(5).map((p) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _colors.cardBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _colors.cardBorder),
                    ),
                    child: Text(
                      p,
                      style: TextStyle(
                        color: _colors.textSecondary,
                        fontSize: 20,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 48),
            // ── 底部二维码 + 邀请码 ──────────────────
            PosterQrFooter(
              colors: _colors,
              qrData: 'fittrack://invite?code=$_inviteCode',
              hint: '输入邀请码，双方得福利',
            ),
          ],
        ),
      ),
    );
  }

  // ── 训练数据展示 ───────────────────────────────────────────

  Widget _buildTrainingData() {
    final r = widget.boundRecord!;
    final muscles = (r['muscles'] as List?)?.cast<String>() ?? [];
    final duration = ((r['duration'] ?? 0) as num).toInt();
    final totalWeight = ((r['totalWeight'] ?? 0) as num).toInt();
    final totalSets = ((r['totalSets'] ?? 0) as num).toInt();
    final mins = (duration / 60).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _colors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _colors.cardBorder),
      ),
      child: Row(
        children: [
          _buildDataItem('${mins}min', '时长'),
          _verticalDivider(),
          _buildDataItem('${totalWeight}kg', '总重量'),
          _verticalDivider(),
          _buildDataItem('$totalSets', '组数'),
          if (muscles.isNotEmpty) ...[
            _verticalDivider(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    muscles.take(2).join('/'),
                    style: TextStyle(
                      color: _colors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('部位',
                      style:
                          TextStyle(color: _colors.textMuted, fontSize: 18)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataItem(String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(value,
              style: TextStyle(
                  color: _colors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(color: _colors.textMuted, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: _colors.cardBorder,
    );
  }
}
