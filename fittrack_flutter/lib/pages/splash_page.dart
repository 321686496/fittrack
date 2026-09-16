import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/legal/legal_content.dart';
import '../data/storage.dart';
import '../themes/app_themes.dart';
import '../widgets/privacy_consent_dialog.dart';

import '../l10n/i18n.dart';
class SplashPage extends StatefulWidget {
  final VoidCallback onReady;
  final VoidCallback onShowOnboarding;

  const SplashPage({
    super.key,
    required this.onReady,
    required this.onShowOnboarding,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  static const Duration _fullAnimationDuration = Duration(seconds: 2);
  static const Duration _fastAnimationDuration = Duration(milliseconds: 400);

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _navTimer;

  /// 首次启动或协议版本升级时，需要弹出同意弹窗（走完整动画）
  bool _needConsent = false;
  bool _onboardingDone = false;

  bool get _fastMode => !_needConsent;

  @override
  void initState() {
    super.initState();
    final settings = Storage.getSettings();
    _onboardingDone = settings['onboardingDone'] == true;
    final privacyAgreed = settings['privacyAgreed'] == true;
    final agreedVersion = settings['privacyAgreedVersion'] as String?;
    // 未同意，或已同意的协议版本与当前版本不一致时，需要重新同意
    _needConsent = !privacyAgreed || agreedVersion != privacyPolicyVersion;

    _pulseController = AnimationController(
      vsync: this,
      duration: _fastMode ? _fastAnimationDuration : _fullAnimationDuration,
    );
    if (_fastMode) {
      // 后续进入：一次性快速淡入 + 轻微缩放，不再无限脉冲
      _pulseAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeOutCubic),
      );
      _pulseController.forward();
    } else {
      // 首次进入：保持原有无限脉冲动画
      _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
      );
      _pulseController.repeat(reverse: true);
    }
    _startTimer();
  }

  void _startTimer() {
    final delay = _fastMode ? _fastAnimationDuration : _fullAnimationDuration;
    _navTimer = Timer(delay, () {
      if (!mounted) return;
      if (_needConsent) {
        _showConsentDialog();
      } else if (_onboardingDone) {
        widget.onReady();
      } else {
        widget.onShowOnboarding();
      }
    });
  }

  void _showConsentDialog() {
    _pulseController.stop();
    PrivacyConsentDialog.show(
      context,
      onAgree: () {
        final settings = Storage.getSettings();
        settings['privacyAgreed'] = true;
        settings['privacyAgreedVersion'] = privacyPolicyVersion;
        Storage.saveSettings(settings);
        // 先关闭弹窗再跳转，避免弹窗残留在导航栈上
        Navigator.of(context).pop();
        if (!mounted) return;
        if (_onboardingDone) {
          widget.onReady();
        } else {
          widget.onShowOnboarding();
        }
      },
      onDecline: () => SystemNavigator.pop(),
    );
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
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // iPhone 极简渐变：顶部主背景色向柔和次色过渡
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scaffoldColor,
              colors.bgSecondary,
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 顶部氛围柔光晕（主题色），营造 iOS 启动页光照感
            Positioned(
              top: -160,
              left: -120,
              child: _buildGlowBlob(
                size: 360,
                color: scheme.primary.withOpacity(0.10),
              ),
            ),
            Positioned(
              bottom: -180,
              right: -140,
              child: _buildGlowBlob(
                size: 380,
                color: colors.accentSecondary.withOpacity(0.10),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 扁平抽象 logo + 渐变柔光光圈
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(0, 0),
                          radius: 0.9,
                          colors: [
                            scheme.primary.withOpacity(0.16),
                            scheme.primary.withOpacity(0),
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  Text(
                    'LiftTrack',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 6,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // 品牌标语（装饰性）——细字、大写、宽间距
                  Text(
                    'KEEP MOVING',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 34),
                  Text(
                    tr(context, '你的智能健身伙伴'),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 主题色柔光圆斑，用于背景氛围营造
  Widget _buildGlowBlob({required double size, required Color color}) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withOpacity(0)],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}
