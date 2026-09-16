import 'package:flutter/material.dart';
import '../data/storage.dart';

class OnboardingCoach extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  /// 用户在选定身体部位后触发的跳转（如进入系统训练计划库）。
  final VoidCallback onChoosePlan;
  const OnboardingCoach({
    required this.onComplete,
    required this.onSkip,
    required this.onChoosePlan,
    super.key,
  });
  @override
  State<OnboardingCoach> createState() => _OnboardingCoachState();
}

class _OnboardingCoachState extends State<OnboardingCoach> {
  int _step = 0;
  String? _selectedPart;

  static const _parts = ['胸', '背', '腿', '肩', '手臂', '核心'];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _buildStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('今天练什么部位？',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _parts.map((p) {
                return ChoiceChip(
                  label: Text(p),
                  selected: _selectedPart == p,
                  onSelected: (_) => setState(() => _selectedPart = p),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: widget.onSkip, child: const Text('跳过')),
                FilledButton(
                  onPressed: _selectedPart == null
                      ? null
                      : () => setState(() => _step = 1),
                  child: const Text('下一步'),
                ),
              ],
            ),
          ],
        );
      case 1:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('选择适合你的训练计划',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(
              '已记录你想练『$_selectedPart』，可前往系统训练计划库，'
              '按你的目标（增肌/减脂/塑形等）选择针对所需部位的综合训练计划。',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                    onPressed: () => setState(() => _step = 0),
                    child: const Text('上一步')),
                FilledButton(
                  onPressed: widget.onChoosePlan,
                  child: const Text('去选择训练计划'),
                ),
              ],
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }
}