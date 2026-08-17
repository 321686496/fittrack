// lib/pages/plan_weight_confirm_page.dart
// 系统训练计划采用前的重量确认页：展示并允许修改每个动作的建议重量
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/storage.dart';
import '../data/system_plan_library.dart';
import '../services/weight_recommendation_service.dart';
import '../themes/app_themes.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

class PlanWeightConfirmPage extends StatefulWidget {
  final SystemPlan plan;
  const PlanWeightConfirmPage({super.key, required this.plan});

  @override
  State<PlanWeightConfirmPage> createState() => _PlanWeightConfirmPageState();
}

class _PlanWeightConfirmPageState extends State<PlanWeightConfirmPage> {
  late final Map<String, ExerciseWeightSuggestion> _suggestions;
  final Map<String, TextEditingController> _controllers = {};
  bool _bodyInfoMissing = false;

  @override
  void initState() {
    super.initState();
    _suggestions =
        WeightRecommendationService.instance.recommendForSystemPlan(widget.plan);
    final bodyData = Storage.getBodyData();
    final bodyWeight = (bodyData['weight'] as num?)?.toDouble() ?? 0;
    _bodyInfoMissing = bodyWeight <= 0;
    for (final day in widget.plan.days) {
      for (final ex in day.exercises) {
        final sug = _suggestions[ex.id];
        if (sug != null && sug.source != WeightSource.bodyweight) {
          final c = TextEditingController(
            text: sug.weight != null ? _fmt(sug.weight!) : '',
          );
          _controllers[ex.id] = c;
        }
      }
    }
  }

  static String _fmt(double w) =>
      w == w.roundToDouble() ? w.round().toString() : w.toString();

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _confirm() {
    // 校验所有非自重动作重量非空且 > 0
    final weights = <String, double>{};
    String? firstEmptyId;
    for (final day in widget.plan.days) {
      for (final ex in day.exercises) {
        final sug = _suggestions[ex.id];
        if (sug == null || sug.source == WeightSource.bodyweight) continue;
        final c = _controllers[ex.id];
        if (c == null) continue;
        final v = double.tryParse(c.text.trim());
        if (v == null || v <= 0) {
          firstEmptyId ??= ex.id;
          continue;
        }
        weights[ex.id] = v;
      }
    }
    if (firstEmptyId != null) {
      FitToast.error(context, '请为每个动作填写有效重量');
      _focusId = firstEmptyId;
      setState(() {});
      return;
    }
    Navigator.of(context).pop(weights);
  }

  String? _focusId;

  @override
  Widget build(BuildContext context) {
    final ft = Theme.of(context).extension<LiftTrackColors>()!;
    return Scaffold(
      backgroundColor: ft.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            title: '确认建议重量',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_bodyInfoMissing)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ft.warningColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: ft.warningColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '未检测到你的体重信息，按 65kg 估算，可修改下方重量',
                            style: TextStyle(color: ft.warningColor, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  '${widget.plan.name} · ${widget.plan.days.length} 个训练日',
                  style: TextStyle(
                    color: ft.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                for (final day in widget.plan.days) _buildDayCard(day, ft),
              ],
            ),
          ),
          _buildBottomBar(ft),
        ],
      ),
    );
  }

  Widget _buildDayCard(SystemPlanDay day, LiftTrackColors ft) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ft.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ft.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '第 ${day.day} 天 · ${day.label}',
            style: TextStyle(
              color: ft.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          for (final ex in day.exercises) _buildExerciseRow(ex, ft),
        ],
      ),
    );
  }

  Widget _buildExerciseRow(SystemPlanExercise ex, LiftTrackColors ft) {
    final sug = _suggestions[ex.id];
    final isBodyweight = sug?.source == WeightSource.bodyweight;
    final controller = _controllers[ex.id];
    final invalid = _focusId == ex.id;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ft.borderColor.withOpacity(0.6)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ex.name,
                  style: TextStyle(color: ft.textPrimary, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '${ex.sets} 组 × ${ex.reps} 次',
                  style: TextStyle(color: ft.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          if (isBodyweight)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: ft.bgSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '自重',
                style: TextStyle(color: ft.textSecondary, fontSize: 12),
              ),
            )
          else ...[
            SizedBox(
              width: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ft.textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      isDense: true,
                      suffixText: 'kg',
                      suffixStyle:
                          TextStyle(color: ft.textSecondary, fontSize: 12),
                      hintText: '重量',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: invalid ? Colors.red : ft.borderColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: invalid ? Colors.red : ft.borderColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sug?.source == WeightSource.history ? '历史记录' : '估算',
                    style: TextStyle(
                      color: sug?.source == WeightSource.history
                          ? ft.accentSecondary
                          : ft.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(LiftTrackColors ft) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: ft.bgCard,
        border: Border(top: BorderSide(color: ft.borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: ft.accentGlow,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('确认并使用计划'),
          ),
        ),
      ),
    );
  }
}
