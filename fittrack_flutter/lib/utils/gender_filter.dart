import '../data/storage.dart';

/// 性别推荐过滤工具
///
/// 用户在问卷中填写性别后，推荐对应适用人群（male/female）的计划与教学，
/// 未填写性别（或未做问卷）时展示全部人群（all）内容。

/// 返回用户的性别键：'male' / 'female' / null（未填写）
String? userGenderKey() {
  final g = Storage.getSettings()['gender'] as String?;
  if (g == '男') return 'male';
  if (g == '女') return 'female';
  return null;
}

/// 判断内容的适用人群是否对当前用户可见
/// [gender] 为内容标签：'male' / 'female' / 'all'
bool genderMatchesUser(String? gender) {
  final ug = userGenderKey();
  if (ug == null) return true;
  final g = gender ?? 'all';
  return g == ug || g == 'all';
}
