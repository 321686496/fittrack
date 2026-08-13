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
};

String? goalArtAsset(String? goal) =>
    goal == null ? null : kGoalArtAssets[goal];

String? bannerArtAsset(String? type) =>
    type == null ? null : kBannerArtAssets[type];
