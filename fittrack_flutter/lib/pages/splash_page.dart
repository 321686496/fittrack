import 'dart:async';
import 'package:flutter/material.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';

class SplashPage extends StatefulWidget {
  final VoidCallback onReady;
  final VoidCallback onShowPrivacy;
  final VoidCallback onShowOnboarding;

  const SplashPage({
    super.key,
    required this.onReady,
    required this.onShowPrivacy,
    required this.onShowOnboarding,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startTimer();
  }

  void _startTimer() {
    _navTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      final settings = Storage.getSettings();
      final privacyAgreed = settings['privacyAgreed'] == true;
      final onboardingDone = settings['onboardingDone'] == true;

      if (privacyAgreed && onboardingDone) {
        widget.onReady();
      } else if (!privacyAgreed) {
        widget.onShowPrivacy();
      } else {
        widget.onShowOnboarding();
      }
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              colors.bgSecondary,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: colors.accentGlow.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colors.accentGlow.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.fitness_center,
                  size: 50,
                  color: colors.accentGlow,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'LiftTrack',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '你的智能健身伙伴',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
