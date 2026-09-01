import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/storage.dart';
import '../data/training_note.dart';
import '../themes/app_themes.dart';
import '../widgets/common_widgets.dart';
import '../widgets/note_poster.dart';
import '../widgets/page_header.dart';
import '../widgets/poster_capture_helper.dart';

/// 训练笔记详情页
///
/// 点击笔记列表卡片进入，展示该笔记的完整内容：
/// - 日期 / 感受 / 精选标记 / 心情贴纸
/// - 绑定的训练记录摘要（可跳转训练详情）
/// - 最满意动作 / 酸痛部位 / 完整心得
///
/// 提供：分享海报、编辑、标记/取消精选、删除。
class NoteDetailPage extends StatefulWidget {
  final String noteId;

  const NoteDetailPage({super.key, required this.noteId});

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  TrainingNote? _note;
  Map<String, dynamic>? _record;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    Storage.dataChanged.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    Storage.dataChanged.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    await Storage.reloadNotesAsync();
    final raw = Storage.getNotes();
    Map<String, dynamic>? noteMap;
    try {
      noteMap = raw.firstWhere((n) => n['id'] == widget.noteId);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _note = noteMap != null ? TrainingNote.fromMap(noteMap) : null;
      _record = _note?.recordId != null
          ? Storage.getRecordById(_note!.recordId!)
          : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _note == null
              ? _buildMissing(colors)
              : Column(
                  children: [
                    PageHeader(
                      title: '笔记详情',
                      subtitle: _note!.dateLabel,
                      onBack: () => context.pop(),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                        children: [
                          _buildNoteCard(colors),
                          if (_record != null) ...[
                            const SizedBox(height: 14),
                            _buildRecordCard(colors),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: _note == null ? null : _buildActionBar(colors),
    );
  }

  Widget _buildMissing(LiftTrackColors colors) {
    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: Column(
        children: [
          PageHeader(title: '笔记详情', onBack: () => context.pop()),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_alt_outlined,
                      size: 64, color: colors.textMuted),
                  const SizedBox(height: 16),
                  Text('笔记不存在或已删除',
                      style: TextStyle(
                          color: colors.textSecondary, fontSize: 15)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 笔记正文卡片 ──────────────────────────────────────────────

  Widget _buildNoteCard(LiftTrackColors colors) {
    final note = _note!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: note.isFeatured
              ? colors.accentGlow.withOpacity(0.3)
              : colors.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部：感受 + 心情 + 精选
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.accentGlow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '感受 · ${note.feelingLabel}',
                  style: TextStyle(
                    color: colors.accentGlow,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              if (note.moodSticker.isNotEmpty) ...[
                Icon(
                  _moodIcon(note.moodSticker),
                  size: 15,
                  color: colors.accentGlow,
                ),
                const SizedBox(width: 4),
                Text(
                  MoodStickers.labelOf(note.moodSticker),
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
              if (note.isFeatured) ...[
                const SizedBox(width: 10),
                Icon(Icons.bookmark, size: 16, color: colors.accentGlow),
              ],
            ],
          ),
          // 最满意动作
          if (note.bestExercise.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.star, size: 14, color: colors.accentGlow),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    note.bestExercise,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          // 完整心得
          if (note.content.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bgSecondary,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: colors.borderColor.withOpacity(0.4)),
              ),
              child: Text(
                note.content,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
          ],
          // 酸痛部位
          if (note.soreParts.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: note.soreParts.map((p) => _soreTag(colors, p)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _soreTag(LiftTrackColors colors, String p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.borderColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        p,
        style: TextStyle(color: colors.textSecondary, fontSize: 11),
      ),
    );
  }

  // ── 绑定的训练记录 ───────────────────────────────────────────

  Widget _buildRecordCard(LiftTrackColors colors) {
    final r = _record!;
    final muscles = (r['muscles'] as List?)?.cast<String>() ?? [];
    final duration = ((r['duration'] ?? 0) as num).toInt();
    final totalWeight = ((r['totalWeight'] ?? 0) as num).toInt();
    final totalSets = ((r['totalSets'] ?? 0) as num).toInt();
    final mins = (duration / 60).round();
    final muscleStr = muscles.isNotEmpty ? muscles.join('、') : '全身训练';
    final planName =
        r['planName'] as String? ?? r['name'] as String? ?? '训练记录';

    return GestureDetector(
      onTap: () => context.push('/records/${r['id']}'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.accentGlow.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.accentGlow.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.link, size: 14, color: colors.accentGlow),
                const SizedBox(width: 6),
                Text(
                  '关联训练记录',
                  style: TextStyle(
                    color: colors.accentGlow,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, size: 16, color: colors.textMuted),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              planName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              muscleStr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _miniStat(colors, Icons.timer_outlined, '${mins}min'),
                const SizedBox(width: 14),
                _miniStat(colors, Icons.monitor_weight_outlined,
                    '${totalWeight}kg'),
                const SizedBox(width: 14),
                _miniStat(colors, Icons.repeat, '$totalSets 组'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(LiftTrackColors colors, IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: colors.textMuted),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ── 底部操作栏 ───────────────────────────────────────────────

  Widget _buildActionBar(LiftTrackColors colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        border: Border(top: BorderSide(color: colors.borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _share,
                icon: const Icon(Icons.share_outlined, size: 17),
                label: const Text('分享海报'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentGlow,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.push('/note/edit/${_note!.id}').then((_) => _load()),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('编辑'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.accentGlow,
                  side: BorderSide(color: colors.accentGlow.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: _showMore,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textSecondary,
                side: BorderSide(color: colors.borderColor),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: const Icon(Icons.more_horiz, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  void _showMore() {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;
    final note = _note!;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: colors.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(
                note.isFeatured
                    ? Icons.bookmark_remove_outlined
                    : Icons.bookmark_add_outlined,
                color: colors.accentGlow,
              ),
              title: Text(
                note.isFeatured ? '取消精选' : '标记精选',
                style: TextStyle(color: colors.textPrimary),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await Storage.updateNoteAsync(
                    note.id, {'isFeatured': !note.isFeatured});
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
              title: Text('删除笔记',
                  style: TextStyle(color: Colors.red.shade400)),
              onTap: () async {
                Navigator.pop(ctx);
                final confirmed = await ConfirmDialog.show(
                  context,
                  title: '删除笔记',
                  content: '确定删除这篇笔记？此操作不可恢复。',
                  confirmText: '删除',
                  cancelText: '取消',
                  confirmColor: Colors.red.shade400,
                  icon: Icons.delete_outline_rounded,
                );
                if (confirmed == true) {
                  await Storage.deleteNoteAsync(note.id);
                  if (mounted) context.pop();
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _share() async {
    await PosterCaptureHelper.captureAndPreview(
      context,
      posterWidget: NotePosterContent(note: _note!, boundRecord: _record),
      posterWidth: NotePosterContent.posterWidth,
      title: '训练笔记海报',
      fileNamePrefix: 'fittrack_note',
    );
  }

  IconData _moodIcon(String id) {
    const map = {
      'local_fire_department': Icons.local_fire_department,
      'bolt': Icons.bolt,
      'fitness_center': Icons.fitness_center,
      'spa': Icons.spa,
      'trending_up': Icons.trending_up,
      'star': Icons.star,
      'coffee': Icons.coffee,
      'bedtime': Icons.bedtime,
    };
    final icon = MoodStickers.iconOf(id);
    return map[icon] ?? Icons.mood;
  }
}