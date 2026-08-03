import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

/// 身体数据页面：查看与编辑身体数据，自动计算 BMI，并展示完整历史趋势
class BodyDataPage extends StatefulWidget {
  const BodyDataPage({super.key});

  @override
  State<BodyDataPage> createState() => _BodyDataPageState();
}

class _BodyDataPageState extends State<BodyDataPage> {
  // 表单控制器
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _bodyFatController = TextEditingController();
  final TextEditingController _chestController = TextEditingController();
  final TextEditingController _waistController = TextEditingController();
  final TextEditingController _hipController = TextEditingController();
  final TextEditingController _armCircumferenceController = TextEditingController();
  final TextEditingController _thighCircumferenceController = TextEditingController();
  final TextEditingController _targetWeightController = TextEditingController();
  final TextEditingController _restingHeartRateController = TextEditingController();

  // 当前已保存的身体数据（用于历史对比和保存时入历史库）
  Map<String, dynamic> _savedBodyData = {};
  // 历史记录（用于趋势展示）
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    // 监听身高/体重输入变化，自动刷新 BMI 显示
    _heightController.addListener(_onBasicChange);
    _weightController.addListener(_onBasicChange);
    _loadData();
  }

  void _onBasicChange() {
    if (mounted) setState(() {});
  }

  void _loadData() {
    final body = Storage.getBodyData();
    _savedBodyData = Map<String, dynamic>.from(body);
    _history = Storage.getBodyDataHistory();

    // 预填当前值（过滤 0/null）
    _heightController.text = _formatValue(body['height']);
    _weightController.text = _formatValue(body['weight']);
    _bodyFatController.text = _formatValue(body['bodyFat']);
    _chestController.text = _formatValue(body['chest']);
    _waistController.text = _formatValue(body['waist']);
    _hipController.text = _formatValue(body['hip']);
    _armCircumferenceController.text = _formatValue(body['armCircumference']);
    _thighCircumferenceController.text = _formatValue(body['thighCircumference']);
    _targetWeightController.text = _formatValue(body['targetWeight']);
    _restingHeartRateController.text = _formatValue(body['restingHeartRate']);
    setState(() {});
  }

  /// 格式化数字：去除末尾的 .0，0 或 null 返回空字符串
  String _formatValue(dynamic v) {
    if (v == null) return '';
    if (v is num) {
      if (v == 0) return '';
      // 整数去掉 .0
      if (v == v.toInt()) return v.toInt().toString();
      return v.toString();
    }
    final s = v.toString();
    return s == '0' || s == '0.0' ? '' : s;
  }

  /// 自动计算 BMI：weight / (height/100)^2，保留 1 位小数
  String _calculateBMI() {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    if (height == null || weight == null || height <= 0) return '--';
    final heightM = height / 100;
    final bmi = weight / (heightM * heightM);
    return bmi.toStringAsFixed(1);
  }

  String _getBMICategory() {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    if (height == null || weight == null || height <= 0) return '';
    final heightM = height / 100;
    final bmi = weight / (heightM * heightM);
    if (bmi < 18.5) return '偏瘦';
    if (bmi < 24) return '正常';
    if (bmi < 28) return '偏胖';
    return '肥胖';
  }

  void _save() {
    final height = double.tryParse(_heightController.text) ?? 0;
    final weight = double.tryParse(_weightController.text) ?? 0;
    if (height <= 0 || weight <= 0) {
      FitToast.warning(context, '请填写身高和体重');
      return;
    }

    // 计算新 BMI
    final heightM = height / 100;
    final bmi = double.parse((weight / (heightM * heightM)).toStringAsFixed(1));

    final newData = <String, dynamic>{
      'height': height,
      'weight': weight,
      'bmi': bmi,
      'bodyFat': double.tryParse(_bodyFatController.text) ?? 0,
      'chest': double.tryParse(_chestController.text) ?? 0,
      'waist': double.tryParse(_waistController.text) ?? 0,
      'hip': double.tryParse(_hipController.text) ?? 0,
      'armCircumference': double.tryParse(_armCircumferenceController.text) ?? 0,
      'thighCircumference': double.tryParse(_thighCircumferenceController.text) ?? 0,
      'targetWeight': double.tryParse(_targetWeightController.text) ?? 0,
      'restingHeartRate': double.tryParse(_restingHeartRateController.text) ?? 0,
      'lastUpdate': '刚刚',
    };

    // 保存前先将旧数据存入历史（仅当旧数据非空时）
    if (_savedBodyData.isNotEmpty) {
      Storage.saveBodyDataHistory(_savedBodyData);
    }

    Storage.saveBodyData(newData);

    // 同步更新 settings 中的身高/体重（保持其他页面一致）
    final settings = Storage.getSettings();
    settings['height'] = height;
    settings['weight'] = weight;
    Storage.saveSettings(settings);

    FitToast.success(context, '身体数据已保存');

    // 重新加载历史与已保存数据，刷新展示
    _loadData();
  }

  @override
  void dispose() {
    _heightController.removeListener(_onBasicChange);
    _weightController.removeListener(_onBasicChange);
    _heightController.dispose();
    _weightController.dispose();
    _bodyFatController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    _armCircumferenceController.dispose();
    _thighCircumferenceController.dispose();
    _targetWeightController.dispose();
    _restingHeartRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            title: '身体数据',
            subtitle: '记录与更新你的身体数据',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 基础数据 + BMI
                  _buildBasicSection(colors),
                  const SizedBox(height: 20),
                  const SectionHeader(title: '详细身体数据'),
                  const SizedBox(height: 10),
                  _buildDetailsGrid(colors),
                  const SizedBox(height: 20),
                  // 身体变化趋势（情绪文案 + 折线图）
                  const SectionHeader(title: '身体变化趋势'),
                  const SizedBox(height: 10),
                  _buildTrendSection(colors),
                  const SizedBox(height: 20),
                  // 历史记录列表
                  const SectionHeader(title: '历史记录'),
                  const SizedBox(height: 10),
                  _buildHistoryList(colors),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          // 底部保存按钮
          _buildBottomSaveBar(colors),
        ],
      ),
    );
  }

  /// 基础数据区块：身高、体重 + 自动计算 BMI
  Widget _buildBasicSection(LiftTrackColors colors) {
    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '基础数据',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FitTextField(
                  controller: _heightController,
                  label: '身高 (cm)',
                  hint: '例如：175',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FitTextField(
                  controller: _weightController,
                  label: '体重 (kg)',
                  hint: '例如：72.5',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // BMI 自动计算展示
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.accentGlow.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.accentGlow.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.monitor_weight, color: colors.accentGlow, size: 24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BMI 指数',
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _calculateBMI(),
                      style: TextStyle(
                        color: colors.accentGlow,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  _getBMICategory(),
                  style: TextStyle(color: colors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 详细身体数据：2 列布局（Row + Column），每个字段用 Expanded 包裹，避免溢出
  Widget _buildDetailsGrid(LiftTrackColors colors) {
    final fields = <List<dynamic>>[
      ['体脂率 (%)', _bodyFatController, '5 - 50'],
      ['胸围 (cm)', _chestController, '50 - 150'],
      ['腰围 (cm)', _waistController, '40 - 130'],
      ['臀围 (cm)', _hipController, '50 - 150'],
      ['上臂围 (cm)', _armCircumferenceController, '15 - 60'],
      ['大腿围 (cm)', _thighCircumferenceController, '30 - 80'],
      ['目标体重 (kg)', _targetWeightController, '30 - 200'],
      ['静息心率 (bpm)', _restingHeartRateController, '40 - 120'],
    ];

    // 每 2 个字段为一行，用 Expanded 包裹避免固定宽高比导致的溢出
    final rows = <Widget>[];
    for (int i = 0; i < fields.length; i += 2) {
      final left = fields[i];
      final right = (i + 1 < fields.length) ? fields[i + 1] : null;
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: FitTextField(
              controller: left[1] as TextEditingController,
              label: left[0] as String,
              hint: left[2] as String,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: right != null
                ? FitTextField(
                    controller: right[1] as TextEditingController,
                    label: right[0] as String,
                    hint: right[2] as String,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ));
      if (i + 2 < fields.length) {
        rows.add(const SizedBox(height: 14));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  /// 身体变化趋势区块：情绪文案 + 体重折线图
  Widget _buildTrendSection(LiftTrackColors colors) {
    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 情绪价值文案
          _buildEmotionalText(colors),
          // 趋势图或提示
          if (_history.length < 2)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  '保存至少 2 次数据后显示趋势图',
                  style: TextStyle(color: colors.textMuted, fontSize: 13),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _WeightTrendChart(
                history: _history,
                lineColor: colors.accentGlow,
                bgColor: colors.bgElevated,
                textColor: colors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  /// 情绪价值文案：根据体重变化趋势显示鼓励/提醒
  Widget _buildEmotionalText(LiftTrackColors colors) {
    if (_history.length < 2) {
      return const SizedBox.shrink();
    }

    final first = _history.first;
    final latest = _history.last;

    final firstWeight = _toNum(first['weight']);
    final latestWeight = _toNum(latest['weight']);

    if (firstWeight <= 0 || latestWeight <= 0) {
      return const SizedBox.shrink();
    }

    final diff = latestWeight - firstWeight;
    final absDiff = diff.abs();

    // 判断是否为增肌目标（目标体重 > 当前体重）
    final targetWeight = _toNum(latest['targetWeight']);
    final isMuscleGainGoal = targetWeight > 0 && targetWeight > latestWeight;

    String text;
    Color color;
    IconData icon;

    if (absDiff < 0.1) {
      // 体重持平
      text = '体重保持稳定，继续坚持！';
      color = colors.textSecondary;
      icon = Icons.trending_flat;
    } else if (diff < 0) {
      // 体重下降
      text = '已减重 ${absDiff.toStringAsFixed(1)} kg，继续加油！💪';
      color = colors.successColor;
      icon = Icons.trending_down;
    } else {
      // 体重上升
      if (isMuscleGainGoal) {
        text = '肌肉增长中，离目标越来越近！💪';
        color = colors.successColor;
      } else {
        text = '体重增加 ${absDiff.toStringAsFixed(1)} kg，注意饮食控制';
        color = colors.warningColor;
      }
      icon = Icons.trending_up;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 历史记录列表：完整历史，按时间倒序排列（最新在上）
  Widget _buildHistoryList(LiftTrackColors colors) {
    if (_history.isEmpty) {
      return CardWidget(
        child: Column(
          children: [
            Icon(Icons.history, size: 36, color: colors.textMuted),
            const SizedBox(height: 8),
            Text(
              '暂无历史记录',
              style: TextStyle(color: colors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              '保存后将显示历史记录',
              style: TextStyle(color: colors.textMuted, fontSize: 11),
            ),
          ],
        ),
      );
    }

    // 倒序排列（最新在上）
    final reversed = List<Map<String, dynamic>>.from(_history.reversed);

    return Column(
      children: reversed
          .map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildHistoryRecordCard(colors, r),
              ))
          .toList(),
    );
  }

  /// 单条历史记录卡片：显示日期、体重、体脂率、BMI（0 或 null 的字段不显示）
  Widget _buildHistoryRecordCard(LiftTrackColors colors, Map<String, dynamic> record) {
    // 日期
    final ts = record['timestamp'];
    String dateStr = '未知日期';
    if (ts is int) {
      final d = DateTime.fromMillisecondsSinceEpoch(ts);
      dateStr = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }

    // 各字段值（0 或 null 不显示）
    final weight = _toNum(record['weight']);
    final bodyFat = _toNum(record['bodyFat']);
    final bmi = _toNum(record['bmi']);

    final stats = <Widget>[];
    if (weight > 0) {
      stats.add(_buildStatChip(colors, '体重', '${_formatNum(weight)} kg', colors.accentGlow));
    }
    if (bodyFat > 0) {
      stats.add(_buildStatChip(colors, '体脂率', '${_formatNum(bodyFat)} %', colors.infoColor));
    }
    if (bmi > 0) {
      stats.add(_buildStatChip(colors, 'BMI', _formatNum(bmi), colors.purpleColor));
    }

    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: colors.textMuted),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
            ],
          ),
          if (stats.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: stats,
            ),
          ],
        ],
      ),
    );
  }

  /// 统计数据小标签
  Widget _buildStatChip(LiftTrackColors colors, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: TextStyle(color: colors.textMuted, fontSize: 11),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 底部保存按钮栏
  Widget _buildBottomSaveBar(LiftTrackColors colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        border: Border(
          top: BorderSide(color: colors.borderColor, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accentGlow,
              foregroundColor: Theme.of(context).brightness == Brightness.dark
                  ? colors.textPrimary
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              '保存',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 将动态值转为 double，非数字或 null 返回 0
  double _toNum(dynamic v) {
    if (v is num) return v.toDouble();
    return 0;
  }

  /// 格式化数字：整数去掉 .0，否则保留 1 位小数
  String _formatNum(double v) {
    if (v == v.toInt()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}

/// 体重变化趋势折线图（CustomPaint 自绘）
class _WeightTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  final Color lineColor;
  final Color bgColor;
  final Color textColor;

  const _WeightTrendChart({
    required this.history,
    required this.lineColor,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      width: double.infinity,
      child: CustomPaint(
        painter: _WeightTrendPainter(
          history: history,
          lineColor: lineColor,
          bgColor: bgColor,
          textColor: textColor,
        ),
      ),
    );
  }
}

/// 体重趋势折线图画笔
class _WeightTrendPainter extends CustomPainter {
  final List<Map<String, dynamic>> history;
  final Color lineColor;
  final Color bgColor;
  final Color textColor;

  _WeightTrendPainter({
    required this.history,
    required this.lineColor,
    required this.bgColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 过滤出 weight > 0 的数据点
    final points = <Map<String, dynamic>>[];
    for (final h in history) {
      final w = h['weight'];
      if (w is num && w.toDouble() > 0) {
        points.add(h);
      }
    }

    // 最多显示最近 20 条数据
    if (points.length > 20) {
      points.removeRange(0, points.length - 20);
    }

    // 不足 2 个数据点不绘制
    if (points.length < 2) return;

    final width = size.width;
    final height = size.height;
    const leftPadding = 30.0;
    const bottomPadding = 20.0;
    final chartWidth = width - leftPadding;
    final chartHeight = height - bottomPadding;

    // 计算 Y 轴范围：min(weight) - 2 到 max(weight) + 2
    double minW = double.infinity;
    double maxW = double.negativeInfinity;
    for (final p in points) {
      final w = (p['weight'] as num).toDouble();
      if (w < minW) minW = w;
      if (w > maxW) maxW = w;
    }
    final yMin = minW - 2;
    final yMax = maxW + 2;
    final yRange = math.max(yMax - yMin, 1.0); // 防止除以 0

    // 绘制图表背景
    final bgPaint = Paint()..color = bgColor;
    canvas.drawRect(
      Rect.fromLTRB(leftPadding, 0, width, chartHeight),
      bgPaint,
    );

    // 绘制坐标轴
    final axisPaint = Paint()
      ..color = textColor.withOpacity(0.3)
      ..strokeWidth = 1;

    // Y 轴
    canvas.drawLine(
      const Offset(leftPadding, 0),
      Offset(leftPadding, chartHeight),
      axisPaint,
    );
    // X 轴
    canvas.drawLine(
      Offset(leftPadding, chartHeight),
      Offset(width, chartHeight),
      axisPaint,
    );

    // Y 轴标签（顶部最大值、底部最小值、中间值）
    _drawText(canvas, _formatWeight(yMax), const Offset(2, 0), textColor, 9);
    _drawText(canvas, _formatWeight(yMin), Offset(2, chartHeight - 12), textColor, 9);
    _drawText(
      canvas,
      _formatWeight((yMax + yMin) / 2),
      Offset(2, (chartHeight - 12) / 2),
      textColor,
      9,
    );

    // 计算各数据点坐标
    final offsets = <Offset>[];
    final n = points.length;
    for (int i = 0; i < n; i++) {
      final w = (points[i]['weight'] as num).toDouble();
      final x = leftPadding + chartWidth * i / (n - 1);
      final y = chartHeight - (w - yMin) / yRange * chartHeight;
      offsets.add(Offset(x, y));
    }

    // 绘制折线
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(offsets.first.dx, offsets.first.dy);
    for (int i = 1; i < offsets.length; i++) {
      path.lineTo(offsets[i].dx, offsets[i].dy);
    }
    canvas.drawPath(path, linePaint);

    // 绘制数据点（小圆圈）
    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    final pointBorderPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;

    for (final o in offsets) {
      canvas.drawCircle(o, 4, pointBorderPaint);
      canvas.drawCircle(o, 3, pointPaint);
    }

    // X 轴标签（首尾日期）
    final firstTs = points.first['timestamp'];
    final lastTs = points.last['timestamp'];

    if (firstTs is int) {
      _drawText(
        canvas,
        _formatDate(firstTs),
        Offset(leftPadding, chartHeight + 4),
        textColor,
        9,
      );
    }
    if (lastTs is int && n > 1) {
      final label = _formatDate(lastTs);
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(color: textColor, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      // 末尾标签右对齐
      tp.paint(canvas, Offset(width - tp.width, chartHeight + 4));
    }
  }

  /// 绘制文本
  void _drawText(Canvas canvas, String text, Offset offset, Color color, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, offset);
  }

  /// 格式化体重值：整数去掉 .0，否则保留 1 位小数
  String _formatWeight(double w) {
    if (w == w.toInt()) return w.toInt().toString();
    return w.toStringAsFixed(1);
  }

  /// 格式化日期为 MM-DD
  String _formatDate(int timestamp) {
    final d = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  bool shouldRepaint(covariant _WeightTrendPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.bgColor != bgColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.history.length != history.length;
  }
}
