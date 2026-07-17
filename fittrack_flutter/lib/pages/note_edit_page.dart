import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/storage.dart';
import '../data/training_note.dart';
import '../themes/app_themes.dart';
import '../widgets/note_poster.dart';
import '../widgets/page_header.dart';

/// v1 训练笔记编写页
///
/// 依据：docs/versions/v1-获客留存版/02_功能清单.md V1-11-02
///
/// 结构化引导编写：
/// - 绑定训练（可选，从训练完成页进入时自动绑定）
/// - 感受滑块 1-5 档
/// - 最满意动作（绑定时可从动作列表选择）
/// - 身体状态酸痛部位标记
/// - 自由心得 200 字 + 字数统计
/// - 心情贴纸选择
class NoteEditPage extends StatefulWidget {
  final String? recordId;
  final String? noteId;

  const NoteEditPage({super.key, this.recordId, this.noteId});

  @override
  State<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends State<NoteEditPage> {
  int _feeling = 3;
  String _bestExercise = '';
  final List<String> _soreParts = [];
  final TextEditingController _contentCtrl = TextEditingController();
  String _moodSticker = '';
  bool _isFeatured = false;
  bool _saving = false;

  Map<String, dynamic>? _boundRecord;
  List<String> _exerciseOptions = [];
  bool _loading = true;
  TrainingNote? _existingNote;

  @override
  void initState() {
    super.initState();
    _contentCtrl.addListener(() => setState(() {}));
    _loadData();
  }

  Future<void> _loadData() async {
    // 编辑现有笔记
    if (widget.noteId != null) {
      await Storage.reloadNotesAsync();
      final notes = Storage.getNotes();
      try {
        final noteMap = notes.firstWhere((n) => n['id'] == widget.noteId);
        _existingNote = TrainingNote.fromMap(noteMap);
        _feeling = _existingNote!.feeling;
        _bestExercise = _existingNote!.bestExercise;
        _soreParts.addAll(_existingNote!.soreParts);
        _contentCtrl.text = _existingNote!.content;
        _moodSticker = _existingNote!.moodSticker;
        _isFeatured = _existingNote!.isFeatured;
        // 如果笔记绑定了训练记录，加载训练数据
        if (_existingNote!.recordId != null) {
          final records = Storage.getRecords();
          try {
            _boundRecord = records.firstWhere(
                (r) => r['id'] == _existingNote!.recordId);
            final setRecords = _boundRecord!['setRecords'];
            if (setRecords is Map) {
              _exerciseOptions =
                  setRecords.keys.map((k) => k.toString()).toList();
            }
          } catch (_) {}
        }
      } catch (_) {}
    } else if (widget.recordId != null) {
      // 从训练完成页进入，绑定训练记录
      final records = Storage.getRecords();
      try {
        final record = records.firstWhere((r) => r['id'] == widget.recordId);
        _boundRecord = record;
        final setRecords = record['setRecords'];
        if (setRecords is Map) {
          _exerciseOptions = setRecords.keys.map((k) => k.toString()).toList();
        }
      } catch (_) {}
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            title: _boundRecord != null ? '训练笔记' : '写笔记',
            subtitle: _boundRecord != null ? '记录这次训练的感受' : '记录你的健身心得',
            isTabPage: true,
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_boundRecord != null) _buildBoundRecordCard(colors),
                        const SizedBox(height: 14),
                        _buildFeelingSection(colors),
                        const SizedBox(height: 14),
                        _buildBestExerciseSection(colors),
                        const SizedBox(height: 14),
                        _buildSorePartsSection(colors),
                        const SizedBox(height: 14),
                        _buildContentSection(colors),
                        const SizedBox(height: 14),
                        _buildMoodStickerSection(colors),
                        const SizedBox(height: 14),
                        _buildFeaturedToggle(colors),
                        const SizedBox(height: 24),
                        _buildActions(colors),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── 绑定的训练记录摘要 ─────────────────────────────────────

  Widget _buildBoundRecordCard(FitTrackColors colors) {
    final r = _boundRecord!;
    final muscles = (r['muscles'] as List?)?.cast<String>() ?? [];
    final duration = ((r['duration'] ?? 0) as num).toInt();
    final totalWeight = ((r['totalWeight'] ?? 0) as num).toInt();
    final totalSets = ((r['totalSets'] ?? 0) as num).toInt();
    final mins = (duration / 60).round();

    return Container(
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
              const SizedBox(width: 4),
              Text(
                '关联训练',
                style: TextStyle(
                  color: colors.accentGlow,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (muscles.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: muscles
                      .take(3)
                      .map((m) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.accentGlow.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(m,
                                style: TextStyle(
                                    color: colors.accentGlow, fontSize: 10)),
                          ))
                      .toList(),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // 双列数据
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(colors, '时长', '${mins}min'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat(colors, '总重量', '${totalWeight}kg'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat(colors, '总组数', '$totalSets'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(FitTrackColors colors, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: colors.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
      ],
    );
  }

  // ── 训练感受滑块 ───────────────────────────────────────────

  Widget _buildFeelingSection(FitTrackColors colors) {
    return _buildSection(
      colors,
      icon: Icons.tune,
      title: '训练感受',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('轻松',
                  style: TextStyle(color: colors.textMuted, fontSize: 11)),
              Text(_feelingLabel(_feeling),
                  style: TextStyle(
                      color: colors.accentGlow,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              Text('爆炸',
                  style: TextStyle(color: colors.textMuted, fontSize: 11)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colors.accentGlow,
              inactiveTrackColor: colors.borderColor,
              thumbColor: colors.accentGlow,
              overlayColor: colors.accentGlow.withOpacity(0.12),
              trackHeight: 4,
            ),
            child: Slider(
              value: _feeling.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              onChanged: (v) => setState(() => _feeling = v.round()),
            ),
          ),
        ],
      ),
    );
  }

  String _feelingLabel(int f) {
    switch (f) {
      case 1:
        return '轻松';
      case 2:
        return '尚可';
      case 3:
        return '适中';
      case 4:
        return '吃力';
      case 5:
        return '爆炸';
      default:
        return '适中';
    }
  }

  // ── 最满意动作 ─────────────────────────────────────────────

  Widget _buildBestExerciseSection(FitTrackColors colors) {
    return _buildSection(
      colors,
      icon: Icons.star_outline,
      title: '最满意动作',
      child: _exerciseOptions.isNotEmpty
          ? Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _exerciseOptions.map((ex) {
                final selected = _bestExercise == ex;
                return GestureDetector(
                  onTap: () => setState(() {
                    _bestExercise = selected ? '' : ex;
                  }),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? colors.accentGlow
                          : colors.bgCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? colors.accentGlow
                            : colors.borderColor,
                      ),
                    ),
                    child: Text(
                      ex,
                      style: TextStyle(
                        color: selected ? Colors.white : colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            )
          : TextField(
              decoration: InputDecoration(
                hintText: '如：杠铃卧推 80kg×8',
                hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                filled: true,
                fillColor: colors.bgCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.borderColor),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: TextStyle(color: colors.textPrimary, fontSize: 13),
              onChanged: (v) => _bestExercise = v,
            ),
    );
  }

  // ── 酸痛部位 ───────────────────────────────────────────────

  Widget _buildSorePartsSection(FitTrackColors colors) {
    return _buildSection(
      colors,
      icon: Icons.accessibility_new,
      title: '身体状态 · 酸痛部位',
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: SorePartOptions.parts.map((part) {
          final selected = _soreParts.contains(part);
          return GestureDetector(
            onTap: () => setState(() {
              if (selected) {
                _soreParts.remove(part);
              } else {
                _soreParts.add(part);
              }
            }),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? colors.accentGlow.withOpacity(0.12)
                    : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected
                      ? colors.accentGlow
                      : colors.borderColor,
                ),
              ),
              child: Text(
                part,
                style: TextStyle(
                  color: selected ? colors.accentGlow : colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── 自由心得 ───────────────────────────────────────────────

  Widget _buildContentSection(FitTrackColors colors) {
    final count = _contentCtrl.text.length;
    return _buildSection(
      colors,
      icon: Icons.edit_note,
      title: '自由心得',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _contentCtrl,
            maxLength: 200,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: '记录今天训练的感悟、突破或不足...',
              hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
              counterStyle: const TextStyle(fontSize: 0),
              filled: true,
              fillColor: colors.bgCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.borderColor),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: TextStyle(color: colors.textPrimary, fontSize: 13),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$count/200',
              style: TextStyle(
                color: count > 200 ? Colors.red : colors.textMuted,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 心情贴纸 ───────────────────────────────────────────────

  Widget _buildMoodStickerSection(FitTrackColors colors) {
    return _buildSection(
      colors,
      icon: Icons.mood_outlined,
      title: '心情贴纸',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: MoodStickers.options.map((opt) {
          final selected = _moodSticker == opt['id'];
          return GestureDetector(
            onTap: () => setState(() {
              _moodSticker = selected ? '' : opt['id']!;
            }),
            child: Container(
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? colors.accentGlow.withOpacity(0.12)
                    : colors.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? colors.accentGlow
                      : colors.borderColor,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _iconData(opt['icon']!),
                    size: 20,
                    color: selected
                        ? colors.accentGlow
                        : colors.textMuted,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    opt['label']!,
                    style: TextStyle(
                      color: selected
                          ? colors.accentGlow
                          : colors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _iconData(String name) {
    const map = {
      'local_fire_department': Icons.local_fire_department,
      'bolt': Icons.bolt,
      'fitness_center': Icons.fitness_center,
      'spa': Icons.spa,
      'trending_up': Icons.trending_up,
      'star': Icons.star,
      'coffee': Icons.coffee,
      'bedtime': Icons.bedtime,
      'mood': Icons.mood,
    };
    return map[name] ?? Icons.mood;
  }

  // ── 精选标记 ───────────────────────────────────────────────

  Widget _buildFeaturedToggle(FitTrackColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.bookmark_outline, size: 16, color: colors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '标记为精选',
              style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Switch(
            value: _isFeatured,
            onChanged: (v) => setState(() => _isFeatured = v),
            activeColor: colors.accentGlow,
          ),
        ],
      ),
    );
  }

  // ── 操作按钮 ───────────────────────────────────────────────

  Widget _buildActions(FitTrackColors colors) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _saving
                ? null
                : () => context.pop(),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('取消'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textSecondary,
              side: BorderSide(color: colors.borderColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check, size: 16),
            label: Text(_saving ? '保存中' : '保存'),
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
    );
  }

  // ── 通用 Section 容器 ──────────────────────────────────────

  Widget _buildSection(
    FitTrackColors colors, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: colors.accentGlow),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  // ── 保存 ───────────────────────────────────────────────────

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final noteMap = <String, dynamic>{
      'feeling': _feeling,
      'bestExercise': _bestExercise,
      'soreParts': _soreParts,
      'content': _contentCtrl.text.trim(),
      'moodSticker': _moodSticker,
      'isFeatured': _isFeatured,
    };

    if (_existingNote != null) {
      // 更新现有笔记
      noteMap['recordId'] = _existingNote!.recordId;
      await Storage.updateNoteAsync(_existingNote!.id, noteMap);
    } else {
      // 新建笔记
      noteMap['recordId'] = widget.recordId;
      Storage.addNote(noteMap);
    }

    if (!mounted) return;
    // 询问是否生成海报（仅新建时询问）
    if (_existingNote == null) {
      final shouldPoster = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(ctx).extension<FitTrackColors>()!.bgSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('笔记已保存',
              style: TextStyle(
                  color: Theme.of(ctx).extension<FitTrackColors>()!.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          content: Text('是否生成笔记海报分享？',
              style: TextStyle(
                  color: Theme.of(ctx).extension<FitTrackColors>()!.textSecondary,
                  fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('稍后'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Theme.of(ctx).extension<FitTrackColors>()!.accentGlow,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('生成海报'),
            ),
          ],
        ),
      );

      if (shouldPoster == true && mounted) {
        final notes = Storage.getNotes();
        if (notes.isNotEmpty) {
          final note = TrainingNote.fromMap(notes.first);
          await NotePosterSheet.show(context, note, boundRecord: _boundRecord);
        }
      }
    }
    if (mounted) context.pop();
  }
}
