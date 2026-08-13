import 'package:flutter/material.dart';
import '../themes/app_themes.dart';
import 'common_widgets.dart';

// ==============================================================
// 自定义日期选择器（日历网格）
// 顶部年月切换 + 中部 7 列网格 + 底部"今天/确定"按钮
// ==============================================================

class FitDatePickerSheet extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? title;

  const FitDatePickerSheet({
    super.key,
    required this.initialDate,
    this.firstDate,
    this.lastDate,
    this.title,
  });

  /// 显示日期选择器，返回选中的日期；用户取消返回 null
  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String? title,
  }) {
    return FitBottomSheet.show<DateTime>(
      context: context,
      maxHeightRatio: 0.7,
      builder: (ctx) => FitDatePickerSheet(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        title: title,
      ),
    );
  }

  @override
  State<FitDatePickerSheet> createState() => _FitDatePickerSheetState();
}

class _FitDatePickerSheetState extends State<FitDatePickerSheet> {
  late DateTime _displayedMonth; // 当前显示月份（1 号）
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayedMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
  }

  void _prevMonth() {
    if (!_canGoPrev()) return;
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    });
  }

  void _nextMonth() {
    if (!_canGoNext()) return;
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _displayedMonth = DateTime(date.year, date.month);
    });
  }

  bool _canGoPrev() {
    final first = widget.firstDate;
    if (first == null) return true;
    final prevMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    final firstMonth = DateTime(first.year, first.month);
    // 上一月仍 >= firstDate 所在月才能往前
    return prevMonth.isAfter(firstMonth) || prevMonth.isAtSameMomentAs(firstMonth);
  }

  bool _canGoNext() {
    final last = widget.lastDate;
    if (last == null) return true;
    final nextMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    final lastMonth = DateTime(last.year, last.month);
    return nextMonth.isBefore(lastMonth) || nextMonth.isAtSameMomentAs(lastMonth);
  }

  bool _isInRange(DateTime date) {
    final first = widget.firstDate;
    final last = widget.lastDate;
    if (first != null) {
      final f = DateTime(first.year, first.month, first.day);
      if (date.isBefore(f)) return false;
    }
    if (last != null) {
      final l = DateTime(last.year, last.month, last.day);
      if (date.isAfter(l)) return false;
    }
    return true;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isSelected(DateTime date) {
    return date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 标题
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.title!,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        // 年月切换
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _canGoPrev() ? _prevMonth : null,
                icon: Icon(
                  Icons.chevron_left,
                  color: _canGoPrev() ? colors.textPrimary : colors.textMuted,
                ),
              ),
              Text(
                '${_displayedMonth.year}年${_displayedMonth.month}月',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: _canGoNext() ? _nextMonth : null,
                icon: Icon(
                  Icons.chevron_right,
                  color: _canGoNext() ? colors.textPrimary : colors.textMuted,
                ),
              ),
            ],
          ),
        ),
        // 星期表头
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: ['日', '一', '二', '三', '四', '五', '六']
                .map((w) => Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            w,
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        // 日历网格
        _buildCalendarGrid(colors),
        // 底部按钮
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: () {
                  final now = DateTime.now();
                  if (_isInRange(now)) {
                    _selectDate(now);
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                child: Text('今天', style: TextStyle(color: colors.textSecondary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_selectedDate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentGlow,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    '确定',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(LiftTrackColors colors) {
    final firstOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    // weekday: 周一=1 ... 周日=7，转换为 周日=0
    final firstWeekday = firstOfMonth.weekday % 7;
    final daysInMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;

    final cells = <Widget>[];

    // 前置占位
    for (int i = 0; i < firstWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_displayedMonth.year, _displayedMonth.month, day);
      final inRange = _isInRange(date);
      final isToday = _isToday(date);
      final isSelected = _isSelected(date);

      cells.add(
        GestureDetector(
          onTap: inRange ? () => _selectDate(date) : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? colors.accentGlow : Colors.transparent,
              border: (isToday && !isSelected)
                  ? Border.all(color: colors.accentSecondary, width: 1.5)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : inRange
                        ? colors.textPrimary
                        : colors.textMuted.withOpacity(0.4),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      crossAxisSpacing: 0,
      mainAxisSpacing: 0,
      childAspectRatio: 0.9,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cells,
    );
  }
}
