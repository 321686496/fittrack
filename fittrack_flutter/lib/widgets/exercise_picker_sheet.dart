import 'package:flutter/material.dart';
import '../themes/app_themes.dart';
import '../data/mock_data.dart';

/// 训练动作选择器 —— 共享组件
///
/// 从动作库中选择动作并配置参数（组数/次数/重量/休息时间），
/// 支持统一参数与逐组设置两种模式。
/// 被 plan_page.dart（编辑计划弹窗）与 add_plan_page.dart（创建计划页）共用。
class ExercisePickerSheet extends StatefulWidget {
  final int defaultSets;
  final int defaultReps;
  final double defaultWeight;
  final int defaultRestTime;
  final Map<String, dynamic>? initialExercise;
  final List<Map<String, dynamic>>? initialSetConfig;
  final void Function(
      Map<String, dynamic> exercise,
      int sets,
      String reps,
      double weight,
      int restTime,
      List<Map<String, dynamic>>? setConfig) onPick;

  const ExercisePickerSheet({
    super.key,
    required this.onPick,
    this.defaultSets = 3,
    this.defaultReps = 10,
    this.defaultWeight = 20.0,
    this.defaultRestTime = 90,
    this.initialExercise,
    this.initialSetConfig,
  });

  @override
  State<ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<ExercisePickerSheet> {
  Map<String, dynamic>? _selectedExercise;
  late TextEditingController _setsCtrl;
  late TextEditingController _repsCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _restTimeCtrl;

  // 模式：true = 逐组设置，false = 统一参数
  bool _perSetMode = false;

  // 逐组设置模式的控制器列表
  final List<TextEditingController> _setRepsCtrls = [];
  final List<TextEditingController> _setWeightCtrls = [];
  final List<TextEditingController> _setRestCtrls = [];

  @override
  void initState() {
    super.initState();
    _setsCtrl = TextEditingController(text: '${widget.defaultSets}');
    _repsCtrl = TextEditingController(text: '${widget.defaultReps}');
    _weightCtrl = TextEditingController(text: '${widget.defaultWeight}');
    _restTimeCtrl = TextEditingController(text: '${widget.defaultRestTime}');
    // 如果有初始动作，直接选中以显示配置视图
    if (widget.initialExercise != null) {
      _selectedExercise = widget.initialExercise;
    }
    // 如果有初始逐组配置，初始化逐组模式
    if (widget.initialSetConfig != null && widget.initialSetConfig!.length > 1) {
      _perSetMode = true;
      _syncSetControllers(widget.defaultSets, widget.initialSetConfig!);
    } else {
      _syncSetControllers(widget.defaultSets, null);
    }
  }

  void _syncSetControllers(int count, List<Map<String, dynamic>>? initialConfig) {
    final current = _setRepsCtrls.length;
    if (count > current) {
      for (int i = current; i < count; i++) {
        String reps;
        String weight;
        String rest;
        if (initialConfig != null && i < initialConfig.length) {
          final cfg = initialConfig[i];
          reps = cfg['reps']?.toString() ?? '${widget.defaultReps}';
          weight = cfg['weight']?.toString() ?? '${widget.defaultWeight}';
          rest = cfg['restTime']?.toString() ?? '${widget.defaultRestTime}';
        } else if (i > 0) {
          reps = _setRepsCtrls[i - 1].text;
          weight = _setWeightCtrls[i - 1].text;
          rest = _setRestCtrls[i - 1].text;
        } else {
          reps = '${widget.defaultReps}';
          weight = '${widget.defaultWeight}';
          rest = '${widget.defaultRestTime}';
        }
        _setRepsCtrls.add(TextEditingController(text: reps));
        _setWeightCtrls.add(TextEditingController(text: weight));
        _setRestCtrls.add(TextEditingController(text: rest));
      }
    } else if (count < current) {
      for (int i = current - 1; i >= count; i--) {
        _setRepsCtrls[i].dispose();
        _setWeightCtrls[i].dispose();
        _setRestCtrls[i].dispose();
        _setRepsCtrls.removeAt(i);
        _setWeightCtrls.removeAt(i);
        _setRestCtrls.removeAt(i);
      }
    }
  }

  void _copyFromPrevious(int index) {
    if (index <= 0 || index >= _setRepsCtrls.length) return;
    _setRepsCtrls[index].text = _setRepsCtrls[index - 1].text;
    _setWeightCtrls[index].text = _setWeightCtrls[index - 1].text;
    _setRestCtrls[index].text = _setRestCtrls[index - 1].text;
    setState(() {});
  }

  @override
  void dispose() {
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    _restTimeCtrl.dispose();
    for (final c in _setRepsCtrls) {
      c.dispose();
    }
    for (final c in _setWeightCtrls) {
      c.dispose();
    }
    for (final c in _setRestCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  _selectedExercise != null ? '设置动作参数' : '选择动作',
                  style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(Icons.close, color: colors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedExercise != null)
            Expanded(child: _buildConfigView(colors))
          else
            Expanded(child: _buildExerciseList(colors)),
        ],
      ),
    );
  }

  Widget _buildExerciseList(FitTrackColors colors) {
    const exercises = MockData.exercises;
    const categories = MockData.categories;

    return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: categories.map((category) {
          final filtered = category == '全部'
              ? exercises
              : exercises.where((e) => e['category'] == category).toList();
          if (filtered.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (category != '全部')
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 8),
                  child: Text(
                    category,
                    style: TextStyle(color: colors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ...filtered.map((ex) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        _selectedExercise = ex;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.fitness_center, size: 18, color: colors.accentGlow),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${ex['name']}',
                                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${ex['category']} · ${ex['equip']}',
                                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.add, size: 20, color: colors.accentGlow),
                        ],
                      ),
                    ),
                  )),
            ],
          );
        }).toList(),
    );
  }

  Widget _buildConfigView(FitTrackColors colors) {
    final ex = _selectedExercise!;
    final sets = int.tryParse(_setsCtrl.text) ?? widget.defaultSets;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 选中动作信息
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.accentGlow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.fitness_center, size: 24, color: colors.accentGlow),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ex['name'] as String,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${ex['category']} · ${ex['equip']}',
                        style: TextStyle(color: colors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 模式切换：统一参数 / 逐组设置
          _buildModeToggle(colors),
          const SizedBox(height: 16),
          // 组数（共用）
          _buildLabelRow(colors, '组数', '共 ${_setsCtrl.text} 组'),
          const SizedBox(height: 6),
          _buildStepperRow(
            colors,
            controller: _setsCtrl,
            unit: '组',
            step: 1,
            min: 1,
            isInt: true,
            onChanged: () {
              final v = int.tryParse(_setsCtrl.text) ?? 1;
              if (v >= 1) _syncSetControllers(v, null);
              setState(() {});
            },
          ),
          const SizedBox(height: 16),

          if (!_perSetMode) ...[
            // 统一参数：次数 / 重量 / 休息
            _buildLabelRow(colors, '每组次数', '所有组相同'),
            const SizedBox(height: 6),
            _buildStepperRow(
              colors,
              controller: _repsCtrl,
              unit: '次/组',
              step: 1,
              min: 1,
              isInt: true,
            ),
            const SizedBox(height: 16),
            _buildLabelRow(colors, '每组重量', '所有组相同'),
            const SizedBox(height: 6),
            _buildStepperRow(
              colors,
              controller: _weightCtrl,
              unit: 'kg',
              step: 2.5,
              min: 0,
              isInt: false,
            ),
            const SizedBox(height: 16),
            _buildLabelRow(colors, '组间休息', '所有组相同'),
            const SizedBox(height: 6),
            _buildStepperRow(
              colors,
              controller: _restTimeCtrl,
              unit: '秒',
              step: 15,
              min: 0,
              isInt: true,
            ),
          ] else ...[
            // 逐组设置：每组独立的次数 / 重量 / 休息
            _buildPerSetEditor(colors, sets),
          ],

          const SizedBox(height: 24),
          // 确认按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final setsVal = int.tryParse(_setsCtrl.text) ?? widget.defaultSets;
                if (_perSetMode) {
                  final setConfig = <Map<String, dynamic>>[];
                  final n = setsVal < _setRepsCtrls.length ? setsVal : _setRepsCtrls.length;
                  for (int i = 0; i < n; i++) {
                    setConfig.add({
                      'reps': _setRepsCtrls[i].text.isNotEmpty ? _setRepsCtrls[i].text : '${widget.defaultReps}',
                      'weight': double.tryParse(_setWeightCtrls[i].text) ?? widget.defaultWeight,
                      'restTime': int.tryParse(_setRestCtrls[i].text) ?? widget.defaultRestTime,
                    });
                  }
                  widget.onPick(
                    ex,
                    setsVal,
                    setConfig.isNotEmpty ? setConfig.first['reps'].toString() : '${widget.defaultReps}',
                    setConfig.isNotEmpty ? (setConfig.first['weight'] as double) : widget.defaultWeight,
                    setConfig.isNotEmpty ? (setConfig.first['restTime'] as int) : widget.defaultRestTime,
                    setConfig,
                  );
                } else {
                  final reps = int.tryParse(_repsCtrl.text) ?? widget.defaultReps;
                  final weight = double.tryParse(_weightCtrl.text) ?? widget.defaultWeight;
                  final restTime = int.tryParse(_restTimeCtrl.text) ?? widget.defaultRestTime;
                  widget.onPick(ex, setsVal, '$reps', weight, restTime, null);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentGlow,
                foregroundColor: colors.bgCard,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                widget.initialExercise != null ? '确认修改' : '确认添加',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── 模式切换 ──────────────────────────────────────────────────
  Widget _buildModeToggle(FitTrackColors colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleItem(colors, '统一参数', Icons.layers, !_perSetMode, () {
              setState(() => _perSetMode = false);
            }),
          ),
          Expanded(
            child: _buildToggleItem(colors, '逐组设置', Icons.view_list, _perSetMode, () {
              setState(() => _perSetMode = true);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem(FitTrackColors colors, String label, IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? colors.accentGlow.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: active ? colors.accentGlow : colors.textMuted),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: active ? colors.accentGlow : colors.textMuted,
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 逐组编辑器 ────────────────────────────────────────────────
  Widget _buildPerSetEditor(FitTrackColors colors, int sets) {
    final count = sets < _setRepsCtrls.length ? sets : _setRepsCtrls.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('逐组参数设置', style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
            const Spacer(),
            Text('每组可独立调整', style: TextStyle(color: colors.textMuted, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 8),
        // 表头
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: colors.borderColor.withOpacity(0.2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            children: [
              SizedBox(width: 38, child: Text('组', style: TextStyle(color: colors.textMuted, fontSize: 10, fontWeight: FontWeight.w600))),
              Expanded(child: Text('次数', style: TextStyle(color: colors.textMuted, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
              Expanded(child: Text('重量(kg)', style: TextStyle(color: colors.textMuted, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
              Expanded(child: Text('休息(秒)', style: TextStyle(color: colors.textMuted, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
              const SizedBox(width: 28),
            ],
          ),
        ),
        // 每组输入行
        ...List.generate(count, (i) => _buildPerSetRow(colors, i)),
      ],
    );
  }

  Widget _buildPerSetRow(FitTrackColors colors, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: colors.bgCard.withOpacity(0.4),
        border: Border(
          bottom: BorderSide(color: colors.borderColor.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text('第${index + 1}组', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
          Expanded(
            child: _buildMiniField(colors, _setRepsCtrls[index], TextInputType.number),
          ),
          Expanded(
            child: _buildMiniField(colors, _setWeightCtrls[index], const TextInputType.numberWithOptions(decimal: true)),
          ),
          Expanded(
            child: _buildMiniField(colors, _setRestCtrls[index], TextInputType.number),
          ),
          SizedBox(
            width: 28,
            child: index > 0
                ? GestureDetector(
                    onTap: () => _copyFromPrevious(index),
                    child: Icon(Icons.copy, size: 14, color: colors.textMuted),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniField(FitTrackColors colors, TextEditingController controller, TextInputType kbType) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: TextField(
        controller: controller,
        keyboardType: kbType,
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: colors.bgCard,
          contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: colors.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: colors.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: colors.accentGlow),
          ),
        ),
      ),
    );
  }

  // ── 通用组件 ──────────────────────────────────────────────────
  Widget _buildLabelRow(FitTrackColors colors, String label, String hint) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(hint, style: TextStyle(color: colors.textMuted, fontSize: 11)),
      ],
    );
  }

  Widget _buildStepperRow(
    FitTrackColors colors, {
    required TextEditingController controller,
    required String unit,
    required double step,
    required double min,
    required bool isInt,
    VoidCallback? onChanged,
  }) {
    return Row(
      children: [
        _buildNumberButton(colors, Icons.remove, () {
          if (isInt) {
            final v = int.tryParse(controller.text) ?? 0;
            final nv = (v - step.toInt()).clamp(min.toInt(), 9999);
            controller.text = '$nv';
          } else {
            final v = double.tryParse(controller.text) ?? 0;
            final nv = (v - step).clamp(min, 9999.0);
            controller.text = _formatDouble(nv);
          }
          onChanged?.call();
        }),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: TextField(
            controller: controller,
            keyboardType: isInt ? TextInputType.number : const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              filled: true,
              fillColor: colors.bgCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.accentGlow),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (_) => onChanged?.call(),
          ),
        ),
        const SizedBox(width: 8),
        _buildNumberButton(colors, Icons.add, () {
          if (isInt) {
            final v = int.tryParse(controller.text) ?? 0;
            controller.text = '${v + step.toInt()}';
          } else {
            final v = double.tryParse(controller.text) ?? 0;
            controller.text = _formatDouble(v + step);
          }
          onChanged?.call();
        }),
        const SizedBox(width: 8),
        Text(unit, style: TextStyle(color: colors.textMuted, fontSize: 14)),
      ],
    );
  }

  String _formatDouble(double v) {
    return v == v.toInt().toDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
  }

  Widget _buildNumberButton(FitTrackColors colors, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.borderColor),
        ),
        child: Icon(icon, size: 18, color: colors.accentGlow),
      ),
    );
  }
}
