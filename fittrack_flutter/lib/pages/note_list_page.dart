import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/storage.dart';
import '../data/training_note.dart';
import '../themes/app_themes.dart';
import '../widgets/common_widgets.dart';
import '../widgets/note_poster.dart';
import '../widgets/page_header.dart';
import '../widgets/poster_capture_helper.dart';

/// v1 训练笔记列表页
///
/// 依据：docs/versions/v1-获客留存版/02_功能清单.md V1-11-03
///
/// - 按时间倒序展示所有笔记
/// - 按月份分组
/// - 支持编辑/删除
/// - 支持标记/取消精选
class NoteListPage extends StatefulWidget {
  const NoteListPage({super.key});

  @override
  State<NoteListPage> createState() => _NoteListPageState();
}

class _NoteListPageState extends State<NoteListPage> {
  List<TrainingNote> _notes = [];
  bool _loading = true;
  bool _featuredOnly = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    Storage.dataChanged.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    _loadNotes();
  }

  @override
  void dispose() {
    Storage.dataChanged.removeListener(_onDataChanged);
    super.dispose();
  }

  Future<void> _loadNotes() async {
    await Storage.reloadNotesAsync();
    final raw = Storage.getNotes();
    final notes = raw.map(TrainingNote.fromMap).toList();
    setState(() {
      _notes = notes;
      _loading = false;
    });
  }

  List<TrainingNote> get _filteredNotes {
    if (!_featuredOnly) return _notes;
    return _notes.where((n) => n.isFeatured).toList();
  }

  /// 按月份分组
  Map<String, List<TrainingNote>> get _groupedNotes {
    final map = <String, List<TrainingNote>>{};
    for (final n in _filteredNotes) {
      final d = DateTime.fromMillisecondsSinceEpoch(n.createTime);
      final key = '${d.year}年${d.month}月';
      map.putIfAbsent(key, () => []).add(n);
    }
    // 按月倒序
    final sortedKeys = map.keys.toList()
      ..sort((a, b) {
        // 解析 "2026年7月" 格式
        int parseYear(String s) => int.parse(
            s.replaceAll(RegExp(r'[^\d]'), ' ').trim().split(' ').first);
        int parseMonth(String s) => int.parse(
            s.replaceAll(RegExp(r'[^\d]'), ' ').trim().split(' ').last);
        final yA = parseYear(a), yB = parseYear(b);
        if (yA != yB) return yB - yA;
        return parseMonth(b) - parseMonth(a);
      });
    return {for (final k in sortedKeys) k: map[k]!};
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            onBack: () => context.pop(),
            title: '训练笔记',
            subtitle:
                '${_notes.length} 篇笔记 · ${_notes.where((n) => n.isFeatured).length} 篇精选',
          ),
          // v1 V1-11: 筛选条
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                _buildFilterChip(colors, '全部', !_featuredOnly, () {
                  setState(() => _featuredOnly = false);
                }),
                const SizedBox(width: 8),
                _buildFilterChip(colors, '精选', _featuredOnly, () {
                  setState(() => _featuredOnly = true);
                }),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredNotes.isEmpty
                    ? _buildEmpty(colors)
                    : RefreshIndicator(
                        color: colors.accentGlow,
                        onRefresh: _loadNotes,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: _groupedNotes.length,
                          itemBuilder: (ctx, idx) {
                            final entry = _groupedNotes.entries.elementAt(idx);
                            return _buildMonthGroup(
                                colors, entry.key, entry.value);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/note/edit');
          _loadNotes();
        },
        backgroundColor: colors.accentGlow,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── 空状态 ─────────────────────────────────────────────────

  Widget _buildFilterChip(
      LiftTrackColors colors, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? colors.accentGlow : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: active ? colors.accentGlow : colors.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(LiftTrackColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_alt_outlined,
              size: 64, color: colors.textMuted.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            _featuredOnly ? '还没有精选笔记' : '还没有训练笔记',
            style: TextStyle(
                color: colors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            _featuredOnly ? '在笔记详情中标记精选' : '点击右下角按钮开始记录',
            style: TextStyle(color: colors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── 月份分组 ───────────────────────────────────────────────

  Widget _buildMonthGroup(
      LiftTrackColors colors, String monthLabel, List<TrainingNote> notes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(
            monthLabel,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...notes.map((n) => _buildNoteCard(colors, n)),
      ],
    );
  }

  // ── 笔记卡片 ───────────────────────────────────────────────

  Widget _buildNoteCard(LiftTrackColors colors, TrainingNote note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: note.isFeatured
              ? colors.accentGlow.withOpacity(0.3)
              : colors.borderColor.withOpacity(0.5),
        ),
      ),
      child: GestureDetector(
        onTap: () async {
          await context.push('/note/${note.id}');
          _loadNotes();
        },
        onLongPress: () => _showActions(colors, note),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部行：日期 + 感受 + 精选标记
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: colors.textMuted),
                const SizedBox(width: 4),
                Text(
                  note.dateLabel,
                  style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentGlow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    note.feelingLabel,
                    style: TextStyle(
                        color: colors.accentGlow,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.share_outlined,
                      size: 16, color: colors.textMuted),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: () {
                    // 取该笔记绑定的训练记录，让海报展示时长/总重量/组数/部位数据条
                    final record = note.recordId != null
                        ? Storage.getRecordById(note.recordId!)
                        : null;
                    PosterCaptureHelper.captureAndPreview(
                      context,
                      posterWidget:
                          NotePosterContent(note: note, boundRecord: record),
                      posterWidth: NotePosterContent.posterWidth,
                      title: '训练笔记海报',
                      fileNamePrefix: 'fittrack_note',
                    );
                  },
                ),
                if (note.isFeatured) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.bookmark, size: 14, color: colors.accentGlow),
                ],
              ],
            ),
            // 最满意动作
            if (note.bestExercise.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star, size: 12, color: colors.accentGlow),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      note.bestExercise,
                      style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
            // 绑定的训练记录信息
            ..._buildRecordSection(colors, note),
            // 心得内容
            if (note.content.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                note.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: colors.textSecondary, fontSize: 12, height: 1.5),
              ),
            ],
            // 底部：心情贴纸 + 酸痛部位
            if (note.moodSticker.isNotEmpty || note.soreParts.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  if (note.moodSticker.isNotEmpty)
                    _buildTag(colors, MoodStickers.labelOf(note.moodSticker),
                        icon: true),
                  ...note.soreParts
                      .take(4)
                      .map((p) => _buildTag(colors, p, isSore: true)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 绑定的训练记录横幅：展示肌群 · 时长 · 总重量 · 组数
  List<Widget> _buildRecordSection(
      LiftTrackColors colors, TrainingNote note) {
    if (note.recordId == null) return const [];
    final record = Storage.getRecordById(note.recordId!);
    if (record == null) return const [];
    return [
      const SizedBox(height: 8),
      _buildRecordBanner(colors, record),
    ];
  }

  /// 绑定的训练记录横幅内容：肌群 · 时长 · 总重量 · 组数
  Widget _buildRecordBanner(LiftTrackColors colors, Map<String, dynamic> r) {
    final muscles = (r['muscles'] as List?)?.cast<String>() ?? [];
    final duration = ((r['duration'] ?? 0) as num).toInt();
    final totalWeight = ((r['totalWeight'] ?? 0) as num).toInt();
    final totalSets = ((r['totalSets'] ?? 0) as num).toInt();
    final mins = (duration / 60).round();
    final muscleStr = muscles.isNotEmpty ? muscles.join('、') : '全身训练';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.accentGlow.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.accentGlow.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.accentGlow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.fitness_center,
                size: 16, color: colors.accentGlow),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  muscleStr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${mins}min · $totalWeight kg · $totalSets 组',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Icon(Icons.link, size: 14, color: colors.accentGlow),
        ],
      ),
    );
  }

  Widget _buildTag(LiftTrackColors colors, String label,
      {bool icon = false, bool isSore = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSore
            ? colors.borderColor.withOpacity(0.3)
            : colors.accentGlow.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon)
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Icon(Icons.mood, size: 10, color: colors.accentGlow),
            ),
          Text(
            label,
            style: TextStyle(
              color: isSore ? colors.textMuted : colors.accentGlow,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── 长按操作菜单 ───────────────────────────────────────────

  void _showActions(LiftTrackColors colors, TrainingNote note) {
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
                _loadNotes();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
              title: Text('删除笔记', style: TextStyle(color: Colors.red.shade400)),
              onTap: () async {
                Navigator.pop(ctx);
                final confirmed = await _confirmDelete(colors);
                if (confirmed == true) {
                  await Storage.deleteNoteAsync(note.id);
                  _loadNotes();
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(LiftTrackColors colors) {
    return ConfirmDialog.show(
      context,
      title: '删除笔记',
      content: '确定删除这篇笔记？此操作不可恢复。',
      confirmText: '删除',
      cancelText: '取消',
      confirmColor: Colors.red.shade400,
      icon: Icons.delete_outline_rounded,
    );
  }
}
