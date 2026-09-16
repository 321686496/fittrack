import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';

/// 用户名与头像生成系统
/// 根据用户填写的问卷信息（性别、健身目标、健身水平等）
/// 自动匹配生成贴切的用户名和头像
class UserProfileGenerator {
  UserProfileGenerator._();

  static final _random = Random();

  // ==================== 用户名生成 ====================

  // 男性用户名前缀
  static const _malePrefixes = [
    '铁血', '力量', '钢铁', '猛虎', '雄鹰',
    '战神', '雷霆', '烈焰', '狂风', '磐石',
    '苍狼', '龙腾', '破晓', '星辰', '山岳',
  ];

  // 女性用户名前缀
  static const _femalePrefixes = [
    '灵动', '优雅', '柔韧', '飞燕', '花语',
    '晨曦', '清露', '蝶舞', '星月', '流云',
    '彩霞', '碧波', '紫烟', '梦蝶', '雪舞',
  ];

  // 中性用户名前缀
  static const _neutralPrefixes = [
    '自由', '无畏', '坚韧', '超越', '突破',
    '逐梦', '奋进', '凌云', '追光', '破浪',
  ];

  // 健身目标对应后缀
  static const _goalSuffixes = {
    '增肌': ['巨兽', '重炮', '铁壁', '堡垒', '重装'],
    '减脂': ['轻风', '利刃', '闪电', '疾风', '锋芒'],
    '塑形': ['精工', '匠人', '雕塑', '流线', '完美'],
    '保持健康': ['行者', '达人', '健将', '活力', '常青'],
  };

  // 健身水平对应修饰词
  static const _levelModifiers = {
    '新手': '萌新',
    '初级': '新锐',
    '中级': '精英',
    '高级': '大师',
  };

  /// 根据问卷信息生成用户名
  static String generateUserName({
    required String gender,
    required String fitnessGoal,
    required String fitnessLevel,
  }) {
    // 选择前缀
    List<String> prefixes;
    if (gender == '女') {
      prefixes = _femalePrefixes;
    } else if (gender == '男') {
      prefixes = _malePrefixes;
    } else {
      prefixes = _neutralPrefixes;
    }

    final prefix = prefixes[_random.nextInt(prefixes.length)];

    // 选择后缀
    final suffixes = _goalSuffixes[fitnessGoal] ?? _goalSuffixes['保持健康']!;
    final suffix = suffixes[_random.nextInt(suffixes.length)];

    // 30% 概率加入水平修饰词
    if (_random.nextDouble() < 0.3) {
      final modifier = _levelModifiers[fitnessLevel] ?? '';
      if (modifier.isNotEmpty) {
        return '$prefix$modifier$suffix';
      }
    }

    return '$prefix$suffix';
  }

  // ==================== 头像生成 ====================

  /// 头像配置：emoji + 背景色
  static const _avatarConfigs = [
    {'emoji': '💪', 'bgColor': 0xFFFF6B35}, // 橙色
    {'emoji': '🏋️', 'bgColor': 0xFF4ECDC4}, // 青色
    {'emoji': '🔥', 'bgColor': 0xFFE74C3C}, // 红色
    {'emoji': '⚡', 'bgColor': 0xFFF39C12}, // 金色
    {'emoji': '🎯', 'bgColor': 0xFF3498DB}, // 蓝色
    {'emoji': '🌟', 'bgColor': 0xFF9B59B6}, // 紫色
    {'emoji': '🦁', 'bgColor': 0xFFE67E22}, // 深橙
    {'emoji': '🦅', 'bgColor': 0xFF1ABC9C}, // 绿松石
    {'emoji': '🐯', 'bgColor': 0xFFE74C3C}, // 红色
    {'emoji': '🐉', 'bgColor': 0xFF8E44AD}, // 深紫
    {'emoji': '🦊', 'bgColor': 0xFFE84393}, // 粉色
    {'emoji': '🐻', 'bgColor': 0xFF6C5CE7}, // 靛蓝
    {'emoji': '🐺', 'bgColor': 0xFF2D3436}, // 深灰
    {'emoji': '🦄', 'bgColor': 0xFFA29BFE}, // 淡紫
    {'emoji': '🐬', 'bgColor': 0xFF00B894}, // 翠绿
    {'emoji': '🦋', 'bgColor': 0xFFFD79A8}, // 浅粉
  ];

  /// 健身目标对应头像
  static const _goalAvatars = {
    '增肌': ['💪', '🏋️', '🦁', '🐉', '🐻'],
    '减脂': ['🔥', '⚡', '🦅', '🐯', '🐺'],
    '塑形': ['🎯', '🌟', '🦄', '🦋', '🐬'],
    '保持健康': ['🌟', '🦊', '🐬', '🦋', '🐻'],
  };

  /// 健身水平对应背景色
  static const _levelColors = {
    '新手': [0xFF4ECDC4, 0xFF1ABC9C, 0xFF00B894], // 清新绿
    '初级': [0xFF3498DB, 0xFF6C5CE7, 0xFF4ECDC4], // 活力蓝
    '中级': [0xFFF39C12, 0xFFE67E22, 0xFFFF6B35], // 进阶橙
    '高级': [0xFFE74C3C, 0xFF8E44AD, 0xFF2D3436], // 强者红/紫
  };

  /// 根据问卷信息生成头像配置
  static Map<String, dynamic> generateAvatar({
    required String gender,
    required String fitnessGoal,
    required String fitnessLevel,
  }) {
    // 选择 emoji
    final goalEmojis = _goalAvatars[fitnessGoal] ?? _goalAvatars['保持健康']!;
    final emoji = goalEmojis[_random.nextInt(goalEmojis.length)];

    // 选择背景色
    final levelColors = _levelColors[fitnessLevel] ?? _levelColors['新手']!;
    final bgColor = levelColors[_random.nextInt(levelColors.length)];

    return {
      'emoji': emoji,
      'bgColor': bgColor,
    };
  }

  /// 获取所有可选头像配置（用于用户手动选择）
  static List<Map<String, dynamic>> getAllAvatars() {
    return _avatarConfigs.map((c) => Map<String, dynamic>.from(c)).toList();
  }

  /// 获取所有可选用户名（用于用户手动选择）
  static List<String> generateUserNameOptions({
    required String gender,
    required String fitnessGoal,
    required String fitnessLevel,
  }) {
    final names = <String>{};
    // 生成6个不重复的用户名
    var attempts = 0;
    while (names.length < 6 && attempts < 20) {
      names.add(generateUserName(
        gender: gender,
        fitnessGoal: fitnessGoal,
        fitnessLevel: fitnessLevel,
      ));
      attempts++;
    }
    return names.toList();
  }

  /// 构建头像 Widget
  /// 若配置包含非空 `avatarPath`（本地图片路径），优先显示自定义头像图片；
  /// 否则按默认逻辑渲染 emoji + 背景色。
  static Widget buildAvatarWidget(
    Map<String, dynamic> avatarConfig, {
    double size = 60,
    double borderWidth = 2,
    Color? borderColor,
  }) {
    final bgColor = Color(avatarConfig['bgColor'] as int);
    final emoji = avatarConfig['emoji'] as String;
    final avatarPath = avatarConfig['avatarPath'] as String?;

    final avatar = avatarPath != null && avatarPath.isNotEmpty
        ? ClipOval(
            child: Image.file(
              File(avatarPath),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: size,
                height: size,
                color: bgColor.withOpacity(0.15),
                alignment: Alignment.center,
                child: Text(
                  emoji,
                  style: TextStyle(fontSize: size * 0.5),
                ),
              ),
            ),
          )
        : Center(
            child: Text(
              emoji,
              style: TextStyle(fontSize: size * 0.5),
            ),
          );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ?? bgColor,
          width: borderWidth,
        ),
      ),
      padding: EdgeInsets.all(borderWidth),
      child: avatar,
    );
  }
}
