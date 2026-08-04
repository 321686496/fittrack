import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../themes/app_themes.dart';

/// 自定义时间选择器 —— 不依赖系统 showTimePicker，
/// 提供符合 LiftTrack 深色主题风格的滚轮式时间选择。
class CustomTimePicker extends StatefulWidget {
  /// 是否返回 null（点击取消），true 表示将返回 null 而非当前选中的时间。
  final void Function(TimeOfDay? time)? onConfirm;
  final TimeOfDay initialTime;

  const CustomTimePicker({
    super.key,
    required this.initialTime,
    this.onConfirm,
  });

  /// 弹出自定义选择器对话框，返回用户选择的时间（null 表示取消）
  static Future<TimeOfDay?> show(
    BuildContext context, {
    required TimeOfDay initialTime,
  }) {
    return showDialog<TimeOfDay>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: CustomTimePicker(
          initialTime: initialTime,
          onConfirm: (time) => Navigator.of(ctx).pop(time),
        ),
      ),
    );
  }

  @override
  State<CustomTimePicker> createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  late int _hour;
  late int _minute;
  late FixedScrollController _hourController;
  late FixedScrollController _minuteController;

  static const double _itemExtent = 48;
  static const int _hourCount = 24;
  static const int _minuteCount = 60;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hour;
    _minute = widget.initialTime.minute;
    _hourController = FixedScrollController(initialItem: _hour);
    _minuteController = FixedScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_time, size: 20, color: colors.accentGlow),
              const SizedBox(width: 8),
              Text(
                '选择提醒时间',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 时钟可视化预览
          SizedBox(
            height: 120,
            width: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 表盘
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.borderColor),
                    color: colors.bgCard.withOpacity(0.2),
                  ),
                ),
                // 刻度
                ...List.generate(12, (i) {
                  final angle = i * 30 * 3.14159 / 180;
                  return Transform.translate(
                    offset: Offset(85 * math.cos(angle), 85 * math.sin(angle)),
                    child: Container(
                      width: 4, height: 12,
                      decoration: BoxDecoration(
                        color: colors.textMuted,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
                // 时针
                Transform.rotate(
                  angle: (_hour % 12 + _minute / 60) * 30 * 3.14159 / 180,
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 4, height: 60,
                    margin: const EdgeInsets.only(bottom: 40),
                    decoration: BoxDecoration(
                      color: colors.accentGlow,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // 分针
                Transform.rotate(
                  angle: _minute * 6 * 3.14159 / 180,
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 3, height: 74,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: colors.textPrimary,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
                // 中心点
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.accentGlow,
                  ),
                ),
                // 选中数字高亮
                Positioned(
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.accentGlow.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$_hour:${_minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: colors.accentGlow,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 滚轮选择器
          SizedBox(
            height: 160,
            child: Row(
              children: [
                // 小时
                Expanded(
                  child: Column(
                    children: [
                      Text('时', style: TextStyle(color: colors.textMuted, fontSize: 12)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _buildWheel(
                          colors: colors,
                          count: _hourCount,
                          controller: _hourController,
                          selectedValue: _hour,
                          onChanged: (v) => setState(() => _hour = v),
                          label: '时',
                        ),
                      ),
                    ],
                  ),
                ),
                // 分隔符
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(
                    ':',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // 分钟
                Expanded(
                  child: Column(
                    children: [
                      Text('分', style: TextStyle(color: colors.textMuted, fontSize: 12)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _buildWheel(
                          colors: colors,
                          count: _minuteCount,
                          controller: _minuteController,
                          selectedValue: _minute,
                          onChanged: (v) => setState(() => _minute = v),
                          label: '分',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 快捷时间
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _quickChip(colors, '06:00', 6, 0),
              _quickChip(colors, '07:00', 7, 0),
              _quickChip(colors, '12:00', 12, 0),
              _quickChip(colors, '18:00', 18, 0),
              _quickChip(colors, '19:00', 19, 0),
              _quickChip(colors, '21:00', 21, 0),
            ],
          ),
          const SizedBox(height: 20),

          // 按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => widget.onConfirm?.call(null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textSecondary,
                    side: BorderSide(color: colors.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => widget.onConfirm?.call(TimeOfDay(hour: _hour, minute: _minute)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentGlow,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('确认', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWheel({
    required LiftTrackColors colors,
    required int count,
    required FixedScrollController controller,
    required int selectedValue,
    required ValueChanged<int> onChanged,
    required String label,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: _itemExtent,
      physics: const FixedExtentScrollPhysics(),
      perspective: 0.003,
      diameterRatio: 1.5,
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: (context, index) {
          final isSelected = index == selectedValue;
          return Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: TextStyle(
                color: isSelected ? colors.accentGlow : colors.textMuted,
                fontSize: isSelected ? 28 : 22,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              child: Text(index.toString().padLeft(2, '0')),
            ),
          );
        },
      ),
    );
  }

  Widget _quickChip(LiftTrackColors colors, String label, int h, int m) {
    final isSelected = _hour == h && _minute == m;
    return GestureDetector(
      onTap: () {
        setState(() {
          _hour = h;
          _minute = m;
        });
        _hourController.animateToItem(h, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
        _minuteController.animateToItem(m, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentGlow.withOpacity(0.15) : colors.bgCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? colors.accentGlow : colors.borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? colors.accentGlow : colors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
     ),
    );
  }
}

/// 简单的 FixedScrollController 扩展，支持 animateToItem
class FixedScrollController extends FixedExtentScrollController {
  FixedScrollController({required int initialItem}) : super(initialItem: initialItem);
}