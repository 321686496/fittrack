import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common/src/utils.dart' as sqflite_utils;
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/l10n/i18n.dart';
import 'package:fittrack_flutter/themes/app_themes.dart';

import 'package:fittrack_flutter/pages/about_page.dart';
import 'package:fittrack_flutter/pages/achievement_page.dart';
import 'package:fittrack_flutter/pages/add_plan_page.dart';
import 'package:fittrack_flutter/pages/banner_notification_guide_page.dart';
import 'package:fittrack_flutter/pages/contact_page.dart';
import 'package:fittrack_flutter/pages/course_list_page.dart';
import 'package:fittrack_flutter/pages/data_privacy_page.dart';
import 'package:fittrack_flutter/pages/gym_card_page.dart';
import 'package:fittrack_flutter/pages/gym_card_stats_page.dart';
import 'package:fittrack_flutter/pages/help_feedback_page.dart';
import 'package:fittrack_flutter/pages/home_page.dart';
import 'package:fittrack_flutter/pages/honor_wall_page.dart';
import 'package:fittrack_flutter/pages/invitation_page.dart';
import 'package:fittrack_flutter/pages/max_weight_detail_page.dart';
import 'package:fittrack_flutter/pages/note_edit_page.dart';
import 'package:fittrack_flutter/pages/note_list_page.dart';
import 'package:fittrack_flutter/pages/plan_create_guide_page.dart';
import 'package:fittrack_flutter/pages/points_detail_page.dart';
import 'package:fittrack_flutter/pages/privacy_policy_page.dart';
import 'package:fittrack_flutter/pages/privacy_security_page.dart';
import 'package:fittrack_flutter/pages/records_page.dart';
import 'package:fittrack_flutter/pages/redeem_page.dart';
import 'package:fittrack_flutter/pages/reminder_settings_page.dart';
import 'package:fittrack_flutter/pages/share_code_page.dart';
import 'package:fittrack_flutter/pages/tutorial_list_page.dart';
import 'package:fittrack_flutter/pages/user_agreement_page.dart';

/// 多语言布局冒烟（页面级批量扫描）。
///
/// 英文文案普遍比中文长 30%~50%，中文不溢出不代表英文不溢出。
/// 这里在 iPhone 14 逻辑尺寸下逐页渲染 zh / en 两遍，断言没有抛异常。
///
/// flutter_test 用等宽测试字体，拉丁字母按 1em 计宽，比真机更宽，
/// 因此这是**悲观**断言：能过，真机基本不会溢出。
///
/// 已排除的页面（无法在纯测试环境 pump，非布局问题）：
/// - qr_scan_page / scan_import_page：依赖 RomAdaptationService 原生通道
/// - notification_test_page：依赖本地通知插件
void main() {
  const phone = Size(390, 844);

  /// 页面名 -> 构造函数。全部无必填参数。
  final pages = <String, Widget Function()>{
    '关于页': () => AboutPage(),
    '成就页': () => AchievementPage(),
    '新增计划页': () => AddPlanPage(),
    '横幅通知引导页': () => BannerNotificationGuidePage(),
    '联系我们页': () => ContactPage(),
    '课程列表页': () => CourseListPage(),
    '数据隐私页': () => DataPrivacyPage(),
    '健身卡页': () => GymCardPage(),
    '健身卡统计页': () => GymCardStatsPage(),
    '帮助反馈页': () => HelpFeedbackPage(),
    '首页': () => HomePage(),
    '荣誉墙页': () => HonorWallPage(),
    '邀请页': () => InvitationPage(),
    '最大重量详情页': () => MaxWeightDetailPage(),
    '笔记编辑页': () => NoteEditPage(),
    '笔记列表页': () => NoteListPage(),
    '计划创建引导页': () => PlanCreateGuidePage(),
    '积分明细页': () => PointsDetailPage(),
    '隐私政策页': () => PrivacyPolicyPage(),
    '隐私安全页': () => PrivacySecurityPage(),
    '训练记录页': () => RecordsPage(),
    '兑换页': () => RedeemPage(),
    '提醒设置页': () => ReminderSettingsPage(),
    '分享码页': () => ShareCodePage(),
    '教程列表页': () => TutorialListPage(),
    '用户协议页': () => UserAgreementPage(),
  };

  setUpAll(() {
    // 部分页面（成就页 / 笔记列表页等）会在 initState 里读 sqlite，
    // 纯测试环境必须先接上 ffi 工厂，否则报 databaseFactory not initialized。
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // 关掉 sqflite 的锁等待 Timer：fake_async 下它不会被触发，会留下 pending Timer
    sqflite_utils.lockWarningDuration = null;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  tearDown(() {
    LocaleController.instance.debugOverrideLanguage(AppLanguage.zh);
  });

  Future<void> pumpPage(
    WidgetTester tester,
    Widget page, {
    required String languageCode,
  }) async {
    LocaleController.instance.debugOverrideLanguage(
      languageCode == 'en' ? AppLanguage.en : AppLanguage.zh,
    );
    await tester.binding.setSurfaceSize(phone);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(LocaleScope(
      controller: LocaleController.instance,
      child: MaterialApp(
        theme: AppTheme.getTheme('vitality-sport'),
        home: page,
      ),
    ));
    // 多 pump 几帧：让 post-frame 回调 / 异步加载落地后再取异常
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    // 推进假时钟，把页面里短生命周期的定时器（Toast 自动消失等）跑完，
    // 否则 teardown 时会因残留 pending Timer 而失败
    await tester.pump(const Duration(seconds: 5));
  }

  for (final entry in pages.entries) {
    for (final code in ['zh', 'en']) {
      testWidgets(
        '${entry.key}（$code）无布局溢出',
        (tester) async {
          await pumpPage(tester, entry.value(), languageCode: code);
          expect(
            tester.takeException(),
            isNull,
            reason: '$code ${entry.key} 出现布局异常',
          );
        },
        timeout: const Timeout(Duration(seconds: 30)),
      );
    }
  }
}
