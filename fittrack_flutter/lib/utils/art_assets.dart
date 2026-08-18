/// 美术资源路径工具
///
/// 由 scripts/generate_cover_art.py 生成，均带渐变兜底，图片缺失时
/// 调用方应回退到原有 gradient + emoji 方案。

/// 目标主题封面（训练计划/教程共用）
const Map<String, String> kGoalArtAssets = {
  'bulk': 'assets/images/art/goal_bulk.png',
  'cut': 'assets/images/art/goal_cut.png',
  'shape': 'assets/images/art/goal_shape.png',
  'keep': 'assets/images/art/goal_keep.png',
  'strength': 'assets/images/art/goal_strength.png',
  'maintain': 'assets/images/art/goal_keep.png',
  // 肌群目标封面
  'arms_male': 'assets/images/art/goal_arms_male.png',
  'arms_female': 'assets/images/art/goal_arms_female.png',
  'shoulders_male': 'assets/images/art/goal_shoulders_male.png',
  'shoulders_female': 'assets/images/art/goal_shoulders_female.png',
  'abs_male': 'assets/images/art/goal_abs_male.png',
  'abs_female': 'assets/images/art/goal_abs_female.png',
  'legs_male': 'assets/images/art/goal_legs_male.png',
  'legs_female': 'assets/images/art/goal_legs_female.png',
  'back_male': 'assets/images/art/goal_back_male.png',
  'back_female': 'assets/images/art/goal_back_female.png',
};

/// 系统课程封面（按课程 id 定位）
String courseArtAsset(String courseId) => 'assets/images/art/$courseId.png';

/// 详情内容配图（按目标主题定位）
String detailArtAsset(String? goal) {
  switch (goal) {
    case 'cut':
      return 'assets/images/art/detail_cut.png';
    case 'shape':
      return 'assets/images/art/detail_shape.png';
    case 'strength':
      return 'assets/images/art/detail_strength.png';
    case 'keep':
    case 'maintain':
      return 'assets/images/art/detail_keep.png';
    case 'arms':
      return 'assets/images/art/detail_arms.png';
    case 'shoulders':
      return 'assets/images/art/detail_shoulders.png';
    case 'abs':
      return 'assets/images/art/detail_abs.png';
    case 'legs':
      return 'assets/images/art/detail_legs.png';
    case 'back':
      return 'assets/images/art/detail_back.png';
    case 'recovery':
      return 'assets/images/art/detail_recovery.png';
    case 'hiit':
      return 'assets/images/art/detail_hiit.png';
    default:
      return 'assets/images/art/detail_bulk.png';
  }
}

/// 首页 Banner 背景（按 banner type 定位）
const Map<String, String> kBannerArtAssets = {
  'teaching': 'assets/images/banners/banner_teaching.png',
  'premium': 'assets/images/banners/banner_premium.png',
  'plan': 'assets/images/banners/banner_plan.png',
  'achievement': 'assets/images/banners/banner_achievement.png',
  'invitation': 'assets/images/banners/banner_invitation.png',
  'recovery': 'assets/images/banners/banner_recovery.png',
  'hiit': 'assets/images/banners/banner_hiit.png',
  'muscle_group': 'assets/images/banners/banner_muscle_group.png',
};

String? goalArtAsset(String? goal) =>
    goal == null ? null : kGoalArtAssets[goal];

String? bannerArtAsset(String? type) =>
    type == null ? null : kBannerArtAssets[type];
