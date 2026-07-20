import 'dart:math';
import '../data/storage.dart';
import '../data/course_content.dart';
import '../data/tutorial_content.dart';
import 'plan_recommendation_service.dart';
import '../data/system_plan_library.dart';

class BannerItem {
  final String type; // teaching / premium / invitation / achievement
  final String title;
  final String subtitle;
  final String? icon; // Material icon name
  final String? route;
  final Map<String, dynamic>? extra;

  const BannerItem({
    required this.type,
    required this.title,
    required this.subtitle,
    this.icon,
    this.route,
    this.extra,
  });

  factory BannerItem.invitation() => const BannerItem(
    type: 'invitation',
    title: '邀请有礼',
    subtitle: '最高 2000 积分等你拿',
    icon: 'card_giftcard',
    route: '/invitation',
  );

  factory BannerItem.achievementChallenge() => const BannerItem(
    type: 'achievement',
    title: '成就挑战',
    subtitle: '解锁新徽章',
    icon: 'emoji_events',
    route: '/achievements',
  );
}

class RecommendationService {
  static List<BannerItem> generateBanners() {
    final settings = Storage.getSettings();
    final goalStr = settings['fitnessGoal'] as String? ?? 'bulk';
    FitnessGoal goal;
    switch (goalStr) {
      case 'cut':
        goal = FitnessGoal.cut;
        break;
      case 'maintain':
        goal = FitnessGoal.maintain;
        break;
      default:
        goal = FitnessGoal.bulk;
    }

    final items = <BannerItem>[];

    // 1. 教学推荐（按目标筛选）
    final tutorials = TutorialLibrary.getBasic().where((t) => t.goal == goal).take(3).toList();
    for (final t in tutorials) {
      items.add(BannerItem(
        type: 'teaching',
        title: t.name,
        subtitle: '推荐教学 · ${t.difficulty}',
        icon: 'school',
        route: '/tutorial/${t.id}',
      ));
    }

    // 2. 付费方案推广
    final premiumCourses = CourseLibrary.courses.where((c) => c.pointsCost > 0).take(2).toList();
    for (final c in premiumCourses) {
      items.add(BannerItem(
        type: 'premium',
        title: c.title,
        subtitle: '${c.pointsCost} 积分解锁',
        icon: 'lock',
        route: '/course/${c.id}',
      ));
    }

    // 训练计划推荐 banner
    if (SystemPlanLibrary.instance.isLoaded) {
      final planRecs = PlanRecommendationService.instance.recommend(limit: 1);
      if (planRecs.isNotEmpty) {
        final rec = planRecs.first;
        items.add(BannerItem(
          type: 'plan',
          title: '推荐计划：${rec.plan.name}',
          subtitle: rec.reasons.isNotEmpty ? rec.reasons.first : '为你智能推荐',
          icon: 'fitness_center',
          route: '/plan-library/detail/${rec.plan.id}',
          extra: {'planId': rec.plan.id, 'score': rec.score},
        ));
      }
    }

    // 3. 内部推广
    items.add(BannerItem.invitation());
    items.add(BannerItem.achievementChallenge());

    // 每日固定顺序（基于日期 seed，每天顺序不同但同一天内稳定）
    items.shuffle(Random(DateTime.now().day));
    return items;
  }
}
