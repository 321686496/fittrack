import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PlanPosterWidget extends StatelessWidget {
  final Map<String, dynamic> plan;
  final String shareCode;
  final String shareString;

  const PlanPosterWidget({
    super.key,
    required this.plan,
    required this.shareCode,
    required this.shareString,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080,
      height: 1920,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              _buildPlanInfo(),
              const SizedBox(height: 30),
              Expanded(child: _buildDaysList()),
              const SizedBox(height: 20),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: const Color(0xFFFF6B35), borderRadius: BorderRadius.circular(16)),
          child: const Center(child: Text('💪', style: TextStyle(fontSize: 28))),
        ),
        const SizedBox(width: 16),
        const Text('FitTrack', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        const Spacer(),
        Text('训练计划', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 20)),
      ],
    );
  }

  Widget _buildPlanInfo() {
    final name = plan['name'] as String? ?? '未命名计划';
    final type = plan['type'] as String? ?? '';
    final difficulty = plan['difficulty'] as String? ?? '';
    final frequency = plan['frequency'] as String? ?? '';
    final author = plan['author'] as String?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              if (type.isNotEmpty) _buildTag(type),
              if (difficulty.isNotEmpty) ...[const SizedBox(width: 10), _buildTag(difficulty)],
              if (frequency.isNotEmpty) ...[const SizedBox(width: 10), _buildTag(frequency)],
            ],
          ),
          if (author != null) ...[
            const SizedBox(height: 8),
            Text('by $author', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 18)),
          ],
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFFF6B35).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 16)),
    );
  }

  Widget _buildDaysList() {
    final days = plan['days'] as List? ?? [];
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      itemBuilder: (ctx, i) {
        final day = days[i] as Map<String, dynamic>;
        final isRest = day['isRest'] == true;
        final label = day['label'] as String? ?? '第${i + 1}天';
        final muscle = day['muscle'] as String? ?? '';
        final exercises = (day['exercises'] as List?) ?? [];
        final totalSets = exercises.fold<int>(0, (sum, ex) => sum + (((ex as Map)['sets'] as int?) ?? 0));

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isRest ? const Color(0xFF4FC3F7).withOpacity(0.08) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isRest ? const Color(0xFF4FC3F7).withOpacity(0.2) : Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: isRest ? const Color(0xFF4FC3F7).withOpacity(0.2) : const Color(0xFFFF6B35).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text('${i + 1}', style: TextStyle(color: isRest ? const Color(0xFF4FC3F7) : const Color(0xFFFF6B35), fontSize: 18, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(isRest ? '休息日 · 充分恢复' : '$muscle · ${exercises.length}个动作 · $totalSets组',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16)),
                  ],
                ),
              ),
              Text(isRest ? '😴' : '🏋️', style: const TextStyle(fontSize: 24)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          if (shareString.length <= 800)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: QrImageView(data: shareString, version: QrVersions.auto, size: 120, gapless: true),
            )
          else
            Container(
              width: 136, height: 136,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('💪', style: TextStyle(fontSize: 48))),
            ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('扫码导入计划', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('或输入分享码：$shareCode', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16)),
                const SizedBox(height: 8),
                Text('在 FitTrack App 中导入即可使用', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
