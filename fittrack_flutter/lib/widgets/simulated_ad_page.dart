import 'package:flutter/material.dart';
import '../themes/app_themes.dart';

class SimulatedAdPage extends StatefulWidget {
  final VoidCallback onComplete;
  const SimulatedAdPage({super.key, required this.onComplete});

  @override
  State<SimulatedAdPage> createState() => _SimulatedAdPageState();
}

class _SimulatedAdPageState extends State<SimulatedAdPage> {
  int _countdown = 3;
  bool _canSkip = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() async {
    for (var i = 3; i > 0; i--) {
      if (!mounted) return;
      setState(() { _countdown = i; });
      await Future.delayed(const Duration(seconds: 1));
    }
    if (!mounted) return;
    setState(() { _canSkip = true; });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;
    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _canSkip
                  ? TextButton(
                      onPressed: widget.onComplete,
                      child: const Text('跳过', style: TextStyle(fontSize: 14)),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.bgCard,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text('$_countdown s', style: TextStyle(
                        color: colors.textSecondary, fontSize: 13,
                      )),
                    ),
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.ondemand_video, size: 64, color: colors.accentGlow),
                    const SizedBox(height: 16),
                    Text('广告模拟中...', style: TextStyle(
                      color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600,
                    )),
                    const SizedBox(height: 8),
                    Text('真实SDK接入后替换此处', style: TextStyle(
                      color: colors.textMuted, fontSize: 13,
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
