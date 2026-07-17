import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../data/training_note.dart';
import '../services/invitation_service.dart';
import '../themes/app_themes.dart';
import '../utils/platform_utils.dart';

/// v1 训练笔记海报生成组件
///
/// 依据：docs/versions/v1-获客留存版/02_功能清单.md V1-11-07
///
/// 自动排版：
/// - 日期 + 训练数据（绑定时）+ 心得 + 感受 + 最满意动作
/// - 底部含 APP 名称 + logo + 邀请码 FIT-INV-XXXXXX
/// - 支持保存图片 / 分享海报
class NotePosterSheet extends StatefulWidget {
  final TrainingNote note;
  final Map<String, dynamic>? boundRecord;

  const NotePosterSheet({
    super.key,
    required this.note,
    this.boundRecord,
  });

  static Future<void> show(
    BuildContext context,
    TrainingNote note, {
    Map<String, dynamic>? boundRecord,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotePosterSheet(
        note: note,
        boundRecord: boundRecord,
      ),
    );
  }

  @override
  State<NotePosterSheet> createState() => _NotePosterSheetState();
}

class _NotePosterSheetState extends State<NotePosterSheet> {
  final _posterKey = GlobalKey();
  late String _inviteCode;

  @override
  void initState() {
    super.initState();
    _inviteCode = InvitationService.instance.generateInvitationCode();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final note = widget.note;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部抓手
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: colors.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // 标题
          Row(
            children: [
              Icon(Icons.photo_library_outlined,
                  size: 18, color: colors.accentGlow),
              const SizedBox(width: 6),
              Text(
                '笔记海报',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(Icons.close, size: 20, color: colors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 海报预览
          _buildPoster(colors, note),
          const SizedBox(height: 16),
          // 操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _savePoster,
                  icon: const Icon(Icons.save_alt, size: 16),
                  label: const Text('保存图片'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.accentGlow,
                    side: BorderSide(color: colors.accentGlow.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _sharePoster,
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('立即分享'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentGlow,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 海报预览 ───────────────────────────────────────────────

  Widget _buildPoster(FitTrackColors colors, TrainingNote note) {
    final hasRecord = widget.boundRecord != null;

    return RepaintBoundary(
      key: _posterKey,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.accentGlow.withOpacity(0.10),
              colors.accentGlow.withOpacity(0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.accentGlow.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部品牌
            Row(
              children: [
                Icon(Icons.fitness_center, size: 16, color: colors.accentGlow),
                const SizedBox(width: 6),
                Text(
                  'FitTrack 燃力',
                  style: TextStyle(
                    color: colors.accentGlow,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                if (note.isFeatured)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.accentGlow.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('精选',
                        style: TextStyle(
                            color: colors.accentGlow,
                            fontSize: 9,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // 日期 + 感受
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: colors.textMuted),
                const SizedBox(width: 4),
                Text(note.dateLabel,
                    style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentGlow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('感受 · ${note.feelingLabel}',
                      style: TextStyle(
                          color: colors.accentGlow,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 心得标题
            if (note.content.isNotEmpty)
              Text(
                note.content,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            // 训练数据（绑定时）
            if (hasRecord) ...[
              const SizedBox(height: 14),
              _buildTrainingData(colors),
            ],
            // 最满意动作
            if (note.bestExercise.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.star, size: 14, color: colors.accentGlow),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '最满意：${note.bestExercise}',
                      style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
            // 酸痛部位
            if (note.soreParts.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: note.soreParts
                    .take(5)
                    .map((p) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.borderColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(p,
                              style: TextStyle(
                                  color: colors.textMuted, fontSize: 10)),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            // 分割线
            Container(height: 1, color: colors.borderColor),
            const SizedBox(height: 14),
            // 底部邀请码 + 二维码
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '输入邀请码，双方得福利',
                        style: TextStyle(color: colors.textMuted, fontSize: 10),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _inviteCode,
                        style: TextStyle(
                          color: colors.accentGlow,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                // V1-08a 二维码
                Container(
                  width: 56,
                  height: 56,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: QrImageView(
                    data: 'fittrack://invite?code=$_inviteCode',
                    version: QrVersions.auto,
                    size: 48,
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
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 训练数据展示 ───────────────────────────────────────────

  Widget _buildTrainingData(FitTrackColors colors) {
    final r = widget.boundRecord!;
    final muscles = (r['muscles'] as List?)?.cast<String>() ?? [];
    final duration = ((r['duration'] ?? 0) as num).toInt();
    final totalWeight = ((r['totalWeight'] ?? 0) as num).toInt();
    final totalSets = ((r['totalSets'] ?? 0) as num).toInt();
    final mins = (duration / 60).round();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildDataItem(colors, '${mins}min', '时长'),
          _verticalDivider(colors),
          _buildDataItem(colors, '${totalWeight}kg', '总重量'),
          _verticalDivider(colors),
          _buildDataItem(colors, '$totalSets', '组数'),
          if (muscles.isNotEmpty) ...[
            _verticalDivider(colors),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    muscles.take(2).join('/'),
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text('部位',
                      style: TextStyle(color: colors.textMuted, fontSize: 10)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataItem(FitTrackColors colors, String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(value,
              style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: colors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _verticalDivider(FitTrackColors colors) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: colors.borderColor,
    );
  }

  // ── 图片截图与分享 ─────────────────────────────────────────

  Future<File?> _capturePoster() async {
    try {
      final boundary = _posterKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      if (byteData == null) return null;
      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/fittrack_note_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      return file;
    } catch (_) {
      return null;
    }
  }

  Future<void> _sharePoster() async {
    final file = await _capturePoster();
    if (file == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('海报生成失败，请重试')),
        );
      }
      return;
    }
    if (isOhos) {
      // OHOS 不支持 Share.shareXFiles，降级为保存 + SnackBar 提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('海报已保存到：${file.path}')),
        );
      }
      return;
    }
    await Share.shareXFiles(
      [XFile(file.path)],
      text: '我的训练笔记 - FitTrack 燃力',
    );
  }

  Future<void> _savePoster() async {
    final file = await _capturePoster();
    if (file == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('海报生成失败，请重试')),
        );
      }
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('海报已保存到：${file.path}')),
      );
    }
  }
}
