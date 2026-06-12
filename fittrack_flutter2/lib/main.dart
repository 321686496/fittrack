import 'package:flutter/material.dart';
import 'themes/app_themes.dart';
import 'data/storage.dart';
import 'services/permission_service.dart';
import 'pages/home_page.dart';
import 'pages/plan_page.dart';
import 'pages/training_page.dart';
import 'pages/stats_page.dart';
import 'pages/exercise_page.dart';
import 'pages/profile_page.dart';
import 'pages/settings_page.dart';
import 'pages/records_page.dart';
import 'widgets/bottom_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  // 请求核心权限（通知、振动）
  await PermissionService.requestCorePermissions();
  runApp(const FitTrackApp());
}

class FitTrackApp extends StatefulWidget {
  const FitTrackApp({super.key});

  @override
  State<FitTrackApp> createState() => _FitTrackAppState();
}

class _FitTrackAppState extends State<FitTrackApp> {
  String _themeId = 'vitality-sport';

  @override
  void initState() {
    super.initState();
    final settings = Storage.getSettings();
    _themeId = settings['theme'] ?? 'vitality-sport';
    if (!Storage.hasData()) {
      Storage.initDemoData();
    }
  }

  void _switchTheme(String id) {
    setState(() {
      _themeId = id;
      final settings = Storage.getSettings();
      Storage.saveSettings({...settings, 'theme': id});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '燃力',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(_themeId),
      home: SplashScreen(onThemeChanged: _switchTheme),
    );
  }
}

// ============================================================
// Splash Screen - 启动页
// ============================================================
class SplashScreen extends StatefulWidget {
  final void Function(String themeId) onThemeChanged;

  const SplashScreen({super.key, required this.onThemeChanged});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _textOpacity;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _lineProgress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.75, curve: Curves.easeOut),
      ),
    );

    _lineProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    // 自动跳转到主页
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => AppShell(
              onThemeChanged: widget.onThemeChanged,
            ),
            transitionDuration: const Duration(milliseconds: 500),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF6B35),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF8C5A),
              Color(0xFFFF6B35),
              Color(0xFFE85D2C),
            ],
          ),
        ),
        child: Stack(
          children: [
            // 背景装饰 - 运动轨迹线条
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _lineProgress,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _SplashLinePainter(_lineProgress.value),
                  );
                },
              ),
            ),
            // 主内容
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo 图标
                  AnimatedBuilder(
                    animation: _logoScale,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScale.value,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 应用名称
                  AnimatedBuilder(
                    animation: _textOpacity,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _textOpacity.value,
                        child: child,
                      );
                    },
                    child: const Text(
                      '燃力',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 副标题
                  AnimatedBuilder(
                    animation: _subtitleOpacity,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _subtitleOpacity.value,
                        child: child,
                      );
                    },
                    child: const Text(
                      '你的私人健身教练',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 底部版本号
            Positioned(
              left: 0,
              right: 0,
              bottom: 48,
              child: FadeTransition(
                opacity: _subtitleOpacity,
                child: const Text(
                  'v1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white38,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Splash 背景运动轨迹线条绘制器
class _SplashLinePainter extends CustomPainter {
  final double progress;

  _SplashLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 右上角折线轨迹
    final path1 = Path();
    path1.moveTo(size.width * 0.7, size.height * 0.1);
    path1.lineTo(size.width * 0.85, size.height * 0.15);
    path1.lineTo(size.width * 0.8, size.height * 0.25);
    path1.lineTo(size.width * 0.92, size.height * 0.3);

    // 左下角折线轨迹
    final path2 = Path();
    path2.moveTo(size.width * 0.1, size.height * 0.75);
    path2.lineTo(size.width * 0.2, size.height * 0.8);
    path2.lineTo(size.width * 0.15, size.height * 0.88);
    path2.lineTo(size.width * 0.28, size.height * 0.92);

    // 小圆点装饰
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final currentProgress = progress.clamp(0.0, 1.0);

    canvas.drawPath(
      _createAnimatedPath(path1, currentProgress),
      paint,
    );
    canvas.drawPath(
      _createAnimatedPath(path2, currentProgress),
      paint,
    );

    // 画小圆点
    if (currentProgress > 0.3) {
      canvas.drawCircle(
        Offset(size.width * 0.88, size.height * 0.12),
        4,
        dotPaint,
      );
      canvas.drawCircle(
        Offset(size.width * 0.22, size.height * 0.78),
        3,
        dotPaint,
      );
    }
  }

  Path _createAnimatedPath(Path originalPath, double progress) {
    final pathMetrics = originalPath.computeMetrics();
    final animatedPath = Path();
    for (final metric in pathMetrics) {
      final length = metric.length * progress;
      animatedPath.addPath(metric.extractPath(0, length), Offset.zero);
    }
    return animatedPath;
  }

  @override
  bool shouldRepaint(covariant _SplashLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ============================================================
// Animated Builder helper (兼容旧版Flutter)
// ============================================================
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Listenable animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}

class AppShell extends StatefulWidget {
  final void Function(String themeId) onThemeChanged;

  const AppShell({super.key, required this.onThemeChanged});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  String _currentPage = 'home';
  Map<String, dynamic>? _trainingParams;
  final List<String> _navHistory = [];

  static const _navPages = ['home', 'plan', 'records', 'stats', 'profile'];

  // 独立页面（无底部导航栏，支持返回）
  static const _noNavPages = ['training', 'settings', 'exercise'];

  void _navigate(String page, {Map<String, dynamic>? params}) {
    if (page == 'training' && params != null) {
      _trainingParams = params;
    }
    _navHistory.add(_currentPage);
    setState(() {
      _currentPage = page;
    });
  }

  void _goBack() {
    if (_navHistory.isNotEmpty) {
      final prev = _navHistory.removeLast();
      setState(() {
        _currentPage = prev;
      });
    }
  }

  int get _navIndex {
    switch (_currentPage) {
      case 'home':
        return 0;
      case 'plan':
        return 1;
      case 'records':
        return 2;
      case 'stats':
        return 3;
      case 'profile':
        return 4;
      default:
        return 0;
    }
  }

  bool get _showNav => !_noNavPages.contains(_currentPage);

  Widget _buildPage() {
    switch (_currentPage) {
      case 'home':
        return HomePage(onNavigate: _navigate);
      case 'plan':
        return PlanPage(onNavigate: _navigate);
      case 'training':
        return TrainingPage(
          params: _trainingParams ?? {},
          onNavigate: _navigate,
        );
      case 'stats':
        return StatsPage(onNavigate: _navigate);
      case 'exercise':
        return ExercisePage(onNavigate: _navigate);
      case 'profile':
        return ProfilePage(onNavigate: _navigate);
      case 'settings':
        return SettingsPage(
          onNavigate: _navigate,
          onThemeChanged: widget.onThemeChanged,
        );
      case 'records':
        return RecordsPage(onNavigate: _navigate);
      default:
        return HomePage(onNavigate: _navigate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_navHistory.isNotEmpty) {
          _goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: Stack(
          children: [
            // 主内容 - 占满全屏，内容可滚动到导航栏下方
            Positioned.fill(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: _buildPage(),
                ),
              ),
            ),
            // 悬浮底部导航栏 - 只拦截圆角卡片区域的触摸
            if (_showNav)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: BottomNav(
                      currentIndex: _navIndex,
                      onTap: (index) {
                        final target = _navPages[index];
                        if (target != _currentPage) {
                          _navHistory.clear();
                          setState(() {
                            _currentPage = target;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
