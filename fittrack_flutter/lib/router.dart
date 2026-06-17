import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'data/storage.dart';
import 'themes/app_themes.dart';
import 'pages/splash_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/questionnaire_page.dart';
import 'pages/plan_recommend_page.dart';
import 'pages/home_page.dart';
import 'pages/plan_page.dart';
import 'pages/training_page.dart';
import 'pages/stats_page.dart';
import 'pages/exercise_page.dart';
import 'pages/profile_page.dart';
import 'pages/settings_page.dart';
import 'pages/records_page.dart';
import 'pages/notification_test_page.dart';
import 'widgets/bottom_nav.dart';

// 全局 NavigatorKey
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// 主题变更回调（由 main.dart 设置）
void Function(String themeId)? onThemeChanged;

// 当前 tab 索引（供 Shell 使用）
final ValueNotifier<int> currentTabIndex = ValueNotifier<int>(0);

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      // ==================== 启动流程路由 ====================
      GoRoute(
        path: '/splash',
        builder: (context, state) => SplashPage(
          onReady: () => context.go('/home'),
          onShowPrivacy: () {
            final settings = Storage.getSettings();
            if (settings['privacyAgreed'] != true) {
              context.go('/privacy');
            } else if (settings['onboardingDone'] != true) {
              context.go('/onboarding');
            } else {
              context.go('/home');
            }
          },
          onShowOnboarding: () {
            final settings = Storage.getSettings();
            if (settings['privacyAgreed'] != true) {
              context.go('/privacy');
            } else if (settings['onboardingDone'] != true) {
              context.go('/onboarding');
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => _PrivacyPolicyPage(
          onAgree: () {
            final settings = Storage.getSettings();
            settings['privacyAgreed'] = true;
            Storage.saveSettings(settings);
            context.go('/onboarding');
          },
          onDecline: () => SystemNavigator.pop(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => OnboardingPage(
          onComplete: () {
            final settings = Storage.getSettings();
            settings['onboardingDone'] = true;
            Storage.saveSettings(settings);
            context.go('/home');
          },
          onQuestionnaireComplete: (_) => context.go('/questionnaire'),
        ),
      ),
      GoRoute(
        path: '/questionnaire',
        builder: (context, state) => QuestionnairePage(
          onComplete: (profileData) => context.go('/recommend', extra: profileData),
          onSkip: () {
            final settings = Storage.getSettings();
            settings['onboardingDone'] = true;
            Storage.saveSettings(settings);
            context.go('/home');
          },
        ),
      ),
      GoRoute(
        path: '/recommend',
        builder: (context, state) {
          final profileData = state.extra as Map<String, dynamic>? ?? {};
          return PlanRecommendPage(
            profileData: profileData,
            onComplete: () {
              final settings = Storage.getSettings();
              settings['onboardingDone'] = true;
              Storage.saveSettings(settings);
              context.go('/home');
            },
          );
        },
      ),

      // ==================== 主页面（带底部导航栏 Shell） ====================
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          // 根据当前路径确定 tab 索引
          final path = state.location;
          int tabIndex = 0;
          if (path.startsWith('/plan')) tabIndex = 1;
          if (path.startsWith('/records')) tabIndex = 2;
          if (path.startsWith('/stats')) tabIndex = 3;
          if (path.startsWith('/profile')) tabIndex = 4;
          currentTabIndex.value = tabIndex;

          return AppShell(
            currentIndex: tabIndex,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomePage(),
            ),
          ),
          GoRoute(
            path: '/plan',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlanPage(),
            ),
          ),
          GoRoute(
            path: '/records',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: RecordsPage(),
            ),
          ),
          GoRoute(
            path: '/stats',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: StatsPage(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfilePage(),
            ),
          ),
        ],
      ),

      // ==================== 子页面（无底部导航栏，使用 root navigator） ====================
      GoRoute(
        path: '/training',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final planId = state.queryParams['planId'] ?? '';
          final dayIndex = int.tryParse(state.queryParams['dayIndex'] ?? '0') ?? 0;
          return TrainingPage(params: {'planId': planId, 'dayIndex': dayIndex});
        },
      ),
      GoRoute(
        path: '/exercise',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ExercisePage(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => SettingsPage(
          onThemeChanged: onThemeChanged ?? (_) {},
        ),
      ),
      GoRoute(
        path: '/notification-test',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationTestPage(),
      ),
    ],
  );
}

/// 带 BottomNav 的 Shell - 使用 IndexedStack 保持所有 tab 页面存活
class AppShell extends StatefulWidget {
  final int currentIndex;
  final Widget child;

  const AppShell({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // 缓存每个 tab 的 child，避免反复创建销毁导致 Ink splash 崩溃
  final List<Widget> _children = List.filled(5, const SizedBox.shrink());
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    // 首次构建时初始化所有 tab
    if (!_initialized) {
      _children[0] = const HomePage();
      _children[1] = const PlanPage();
      _children[2] = const RecordsPage();
      _children[3] = const StatsPage();
      _children[4] = const ProfilePage();
      _initialized = true;
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: widget.currentIndex,
              children: _children,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNav(
              currentIndex: widget.currentIndex,
              onTap: (index) {
                const paths = ['/home', '/plan', '/records', '/stats', '/profile'];
                if (index < paths.length) {
                  context.go(paths[index]);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 隐私政策页面
class _PrivacyPolicyPage extends StatelessWidget {
  final VoidCallback onAgree;
  final VoidCallback onDecline;

  const _PrivacyPolicyPage({required this.onAgree, required this.onDecline});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Icon(Icons.privacy_tip, size: 56, color: colors.accentGlow),
              const SizedBox(height: 20),
              Text(
                '用户隐私政策',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      '欢迎使用 FitTrack！\n\n'
                      '我们非常重视您的隐私保护。在您使用本应用之前，请仔细阅读以下隐私政策：\n\n'
                      '1. 数据收集：我们仅收集您主动提供的个人信息（如身高、体重、健身目标等），用于为您推荐训练计划。所有数据均存储在您的设备本地，不会上传至任何服务器。\n\n'
                      '2. 数据使用：您的数据仅用于提供健身训练服务，包括训练计划推荐、训练记录统计、身体数据追踪等功能。\n\n'
                      '3. 数据存储：所有数据通过本地安全存储方式保存在您的设备上，我们不会将您的任何数据传输到第三方。\n\n'
                      '4. 数据删除：您可以随时在设置中清除所有个人数据，清除后数据将不可恢复。\n\n'
                      '5. 权限使用：应用可能需要网络权限用于获取在线资源，不会访问您的通讯录、相册等敏感权限。\n\n'
                      '点击"同意"即表示您已阅读并同意本隐私政策。',
                      style: TextStyle(color: colors.textSecondary, fontSize: 14, height: 1.6),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onAgree,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentGlow,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('同意', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.textMuted),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('不同意并退出', style: TextStyle(color: colors.textMuted, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
