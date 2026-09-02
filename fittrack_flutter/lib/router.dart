import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'data/storage.dart';
import 'data/system_plan_library.dart';
import 'pages/splash_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/questionnaire_page.dart';
import 'pages/plan_recommend_page.dart';
import 'pages/home_page.dart';
import 'pages/honor_wall_page.dart';
import 'pages/plan_page.dart';
import 'pages/training_page.dart';
import 'pages/stats_page.dart';
import 'pages/exercise_page.dart';
import 'pages/profile_page.dart';
import 'pages/settings_page.dart';
import 'pages/theme_settings_page.dart';
import 'pages/records_page.dart';
import 'pages/plan_detail_page.dart';
import 'pages/record_detail_page.dart';
import 'pages/add_plan_page.dart';
import 'pages/plan_create_guide_page.dart';
import 'pages/notification_test_page.dart';
import 'pages/reminder_settings_page.dart';
import 'pages/banner_notification_guide_page.dart';
import 'pages/gym_card_page.dart';
import 'pages/gym_card_stats_page.dart';
import 'pages/body_data_page.dart';
import 'pages/privacy_policy_page.dart';
import 'pages/user_agreement_page.dart';
import 'pages/data_privacy_page.dart';
import 'pages/about_page.dart';
import 'pages/privacy_security_page.dart';
import 'pages/help_feedback_page.dart';
import 'pages/contact_page.dart';
import 'pages/achievement_page.dart';
import 'pages/redeem_page.dart';
import 'pages/invitation_page.dart';
import 'pages/share_code_page.dart';
import 'pages/plan_qr_code_page.dart';
import 'pages/scan_import_page.dart';
import 'pages/plan_poster_page.dart';
import 'pages/tutorial_list_page.dart';
import 'pages/all_tutorials_page.dart';
import 'pages/tutorial_category_page.dart';
import 'pages/tutorial_detail_page.dart';
import 'pages/tutorial_search_page.dart';
import 'pages/course_list_page.dart';
import 'pages/course_detail_page.dart';
import 'pages/chapter_read_page.dart';
import 'pages/note_list_page.dart';
import 'pages/note_edit_page.dart';
import 'pages/note_detail_page.dart';
import 'pages/points_detail_page.dart';
import 'pages/plan_library_home_page.dart';
import 'pages/plan_library_category_page.dart';
import 'pages/plan_library_detail_page.dart';
import 'pages/plan_search_page.dart';
import 'pages/plan_weight_confirm_page.dart';
import 'pages/max_weight_detail_page.dart';
import 'pages/opponent_detail_page.dart';
import 'pages/logo_preview_page.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/common_widgets.dart';

// 全局 NavigatorKey
final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// 主题变更回调（由 main.dart 设置）
void Function(String themeId, {bool? followSystem, String? lightThemeId, String? darkThemeId, String? autoDarkMode, String? timedDarkTime})? onThemeChanged;

// 当前 tab 索引（供 Shell 使用）
final ValueNotifier<int> currentTabIndex = ValueNotifier<int>(0);

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      // ==================== 启动流程路由 ====================
      GoRoute(
        path: '/splash',
        builder: (context, state) => SplashPage(
          onReady: () => context.go('/home'),
          onShowOnboarding: () => context.go('/onboarding'),
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
          if (path.startsWith('/tutorial')) tabIndex = 2;
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
            path: '/tutorial',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TutorialListPage(),
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
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final planId = state.queryParams['planId'] ?? '';
          final dayIndex = int.tryParse(state.queryParams['dayIndex'] ?? '0') ?? 0;
          return TrainingPage(params: {'planId': planId, 'dayIndex': dayIndex});
        },
      ),
      GoRoute(
        path: '/plan/:planId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final planId = state.params['planId'] ?? '';
          return PlanDetailPage(planId: planId);
        },
      ),
      // /records 作为全屏页面（rootNavigatorKey），避免 AppShell IndexedStack 忽略 widget.child 导致渲染 HomePage
      GoRoute(
        path: '/records',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const RecordsPage(),
      ),
      GoRoute(
        path: '/records/:recordId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final recordId = state.params['recordId'] ?? '';
          return RecordDetailPage(recordId: recordId);
        },
      ),
      GoRoute(
        path: '/add-plan',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final editPlanId = state.queryParams['editPlanId'];
          return AddPlanPage(editPlanId: editPlanId);
        },
      ),
      GoRoute(
        path: '/plan-guide',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PlanCreateGuidePage(),
      ),
      // 系统计划库路由（注意：detail 必须在 :goal 之前，避免 :goal 匹配 "detail"）
      GoRoute(
        path: '/plan-library',
        name: 'planLibraryHome',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PlanLibraryHomePage(),
      ),
      GoRoute(
        path: '/plan-library/detail/:planId',
        name: 'planLibraryDetail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => PlanLibraryDetailPage(
          planId: state.params['planId']!,
        ),
      ),
      GoRoute(
        path: '/plan-library/:goal',
        name: 'planLibraryCategory',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => PlanLibraryCategoryPage(
          goal: state.params['goal']!,
        ),
      ),
      GoRoute(
        path: '/plan-weight-confirm',
        name: 'planWeightConfirm',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => PlanWeightConfirmPage(
          plan: state.extra as SystemPlan,
        ),
      ),
      GoRoute(
        path: '/plan-search',
        name: 'planSearch',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => PlanSearchPage(
          initialKeyword: state.extra as String?,
        ),
      ),
      GoRoute(
        path: '/exercise',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ExercisePage(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => SettingsPage(
          onThemeChanged: (themeId, {followSystem, lightThemeId, darkThemeId, autoDarkMode, timedDarkTime}) {
            onThemeChanged?.call(themeId, followSystem: followSystem, lightThemeId: lightThemeId, darkThemeId: darkThemeId, autoDarkMode: autoDarkMode, timedDarkTime: timedDarkTime);
          },
        ),
      ),
      GoRoute(
        path: '/theme-settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final settings = Storage.getSettings();
          return ThemeSettingsPage(
            currentThemeId: settings['theme'] ?? 'vitality-sport',
            autoDarkMode: settings['autoDarkMode'] ?? 'off',
            timedDarkTime: settings['timedDarkTime'] ?? '18:00',
            lightThemeId: settings['lightThemeId'] ?? 'vitality-sport',
            darkThemeId: settings['darkThemeId'] ?? 'iron-forge',
            onThemeChanged: (themeId, {followSystem, lightThemeId, darkThemeId, autoDarkMode, timedDarkTime}) {
              onThemeChanged?.call(themeId, followSystem: followSystem, lightThemeId: lightThemeId, darkThemeId: darkThemeId, autoDarkMode: autoDarkMode, timedDarkTime: timedDarkTime);
            },
          );
        },
      ),
      GoRoute(
        path: '/notification-test',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NotificationTestPage(),
      ),
      GoRoute(
        path: '/reminder-settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ReminderSettingsPage(),
      ),
      GoRoute(
        path: '/banner-notification-guide',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const BannerNotificationGuidePage(),
      ),
      GoRoute(
        path: '/gym-card',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const GymCardPage(),
      ),
      GoRoute(
        path: '/gym-card-stats',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const GymCardStatsPage(),
      ),
      GoRoute(
        path: '/body-data',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const BodyDataPage(),
      ),
      GoRoute(
        path: '/privacy-full',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: '/agreement',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const UserAgreementPage(),
      ),
      GoRoute(
        path: '/data-privacy',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const DataPrivacyPage(),
      ),
      GoRoute(
        path: '/about',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: '/privacy-security',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PrivacySecurityPage(),
      ),
      GoRoute(
        path: '/help-feedback',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const HelpFeedbackPage(),
      ),
      GoRoute(
        path: '/contact',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ContactPage(),
      ),
      GoRoute(
        path: '/achievements',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AchievementPage(),
      ),
      GoRoute(
        path: '/honor-wall',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const HonorWallPage(),
      ),
      GoRoute(
        path: '/redeem',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const RedeemPage(),
      ),
      GoRoute(
        path: '/invitation',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const InvitationPage(),
      ),
      GoRoute(
        path: '/share-code',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ShareCodePage(),
      ),
      GoRoute(
        path: '/plan-qr/:planId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => PlanQrCodePage(
          planId: state.params['planId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/scan-import',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ScanImportPage(),
      ),
      GoRoute(
        path: '/plan-poster/:planId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => PlanPosterPage(
          planId: state.params['planId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/tutorial/:tutorialId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final tutorialId = state.params['tutorialId'] ?? '';
          return TutorialDetailPage(tutorialId: tutorialId);
        },
      ),
      GoRoute(
        path: '/all-tutorials',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AllTutorialsPage(),
      ),
      GoRoute(
        path: '/tutorial-search',
        name: 'tutorialSearch',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const TutorialSearchPage(),
      ),
      // 教学分类详情页（v1.3 新增：瀑布流分类点击进入）
      GoRoute(
        path: '/tutorials/:category',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => TutorialCategoryPage(
          categoryKey: state.params['category'] ?? '',
        ),
      ),
      // 系统化课程路由
      GoRoute(
        path: '/course',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CourseListPage(),
      ),
      GoRoute(
        path: '/course/:courseId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => CourseDetailPage(courseId: state.params['courseId'] ?? ''),
      ),
      GoRoute(
        path: '/course/:courseId/chapter/:chapterId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => ChapterReadPage(
          courseId: state.params['courseId'] ?? '',
          chapterId: state.params['chapterId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/points-detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PointsDetailPage(),
      ),
      GoRoute(
        path: '/max-weight-detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const MaxWeightDetailPage(),
      ),
      GoRoute(
        path: '/opponent-detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const OpponentDetailPage(),
      ),
      GoRoute(
        path: '/logo-preview',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const LogoPreviewPage(),
      ),
      // v1 V1-11: 训练笔记路由
      GoRoute(
        path: '/note',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NoteListPage(),
      ),
      // 注意：静态路由必须放在动态路由之前，否则 `/note/edit` 会被
      // `/note/:noteId` 匹配为 noteId='edit'，跳转到详情页而不是编辑页。
      GoRoute(
        path: '/note/edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NoteEditPage(),
      ),
      GoRoute(
        path: '/note/edit/:recordId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final recordId = state.params['recordId'] ?? '';
          // 如果 recordId 是 note_xxx 格式（编辑现有笔记），不传 recordId
          // 如果是 record_xxx 格式（从训练完成进入），传 recordId
          if (recordId.startsWith('record_')) {
            return NoteEditPage(recordId: recordId);
          }
          // 编辑现有笔记：加载笔记数据后传入
          return NoteEditPage(noteId: recordId);
        },
      ),
      // noteId: note_xxx / UUID（注：必须放在静态路由之后）
      GoRoute(
        path: '/note/:noteId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            NoteDetailPage(noteId: state.params['noteId'] ?? ''),
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
  DateTime? _lastBackPressed;

  /// 首次返回首页时提示用户，再次操作则退出应用。
  Future<bool> _onWillPop() async {
    // 若系统 back 无法从这里被吞掉（例如当前已是最上层且无下层页面），
    // 第一次提示，第二次才真正退出，避免误触直接退出应用。
    final now = DateTime.now();
    if (_lastBackPressed != null &&
        now.difference(_lastBackPressed!) < const Duration(seconds: 2)) {
      _lastBackPressed = null;
      SystemNavigator.pop();
      return false;
    }
    _lastBackPressed = now;
    if (mounted) {
      FitToast.info(context, '再按一次返回键退出应用');
    } else {
      SystemNavigator.pop();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // 首次构建时初始化所有 tab
    if (!_initialized) {
      _children[0] = const HomePage();
      _children[1] = const PlanPage();
      _children[2] = const TutorialListPage();
      _children[3] = const StatsPage();
      _children[4] = const ProfilePage();
      _initialized = true;
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [
            // Tab 页面内容，底部留出悬浮导航栏的空间
            Positioned.fill(
              bottom: 0,
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
                  const paths = ['/home', '/plan', '/tutorial', '/stats', '/profile'];
                  if (index < paths.length) {
                    context.go(paths[index]);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

