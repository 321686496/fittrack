import 'package:flutter/material.dart';
import '../data/storage.dart';
import '../data/mock_data.dart';

class OnboardingCoach extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  const OnboardingCoach({
    required this.onComplete,
    required this.onSkip,
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
          children: [
            Text('今天练什么部位？',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
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
        final exercises = MockData.exercises
            .where((e) => _matchesPart(e, _selectedPart))
            .take(3)
            .toList();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('为你推荐 3 个动作', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...exercises.map((e) => ListTile(
                  leading: const Icon(Icons.fitness_center),
                  title: Text(e['name'] as String? ?? ''),
                  dense: true,
                )),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                    onPressed: () => setState(() => _step = 0),
                    child: const Text('上一步')),
                FilledButton(
                  onPressed: _finish,
                  child: const Text('开始记录'),
                ),
              ],
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  // Resolution 2: MockData.exercises uses 'category' field (e.g. '胸部', '背部'),
  // NOT 'muscles'. Match against category.
  bool _matchesPart(Map<String, dynamic> exercise, String? part) {
    if (part == null) return true;
    final category = exercise['category'] as String? ?? '';
    return category.contains(part);
  }

  void _finish() {
    final settings = Storage.getSettings();
    settings['onboardingV2Done'] = true;
    Storage.saveSettings(settings);
    widget.onComplete();
  }
}
