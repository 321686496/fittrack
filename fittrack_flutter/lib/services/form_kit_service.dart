import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../data/storage.dart';

/// OHOS 桌面卡片（Form Kit）服务
///
/// 数据流设计：
/// - Flutter 侧通过 MethodChannel 将卡片数据推送到 EntryAbility
/// - EntryAbility 将数据保存到 preferences（跨进程共享存储）
/// - FormExtensionAbility 在 onUpdateForm 时从 preferences 读取数据
/// - 卡片点击通过 postCardAction router 事件跳转到应用
///
/// 卡片三态：
/// - idle: 显示今日训练概览 + 训练提醒时间
/// - training: 显示当前训练动作/组数进度
/// - rest: 显示倒计时 + 动作信息
class FormKitService {
  FormKitService._();

  static final FormKitService instance = FormKitService._();

  static const String _channelName = 'com.example.fittrack_flutter/form';

  final MethodChannel _channel = const MethodChannel(_channelName);

  bool _initialized = false;

  /// 当前训练态数据（非 null 表示正在训练中）
  Map<String, dynamic>? _trainingState;

  /// 初始化（应用启动时调用一次）
  void init() {
    if (_initialized) return;
    _initialized = true;

    // 首次启动时推送一次数据
    pushFormData();
  }

  // ============================================================
  // 训练态管理
  // ============================================================

  /// 训练开始，初始化训练态
  void startTraining({
    required String exerciseName,
    required int currentSet,
    required int totalSets,
    required int exerciseIndex,
    required int totalExercises,
    required int completedSets,
    required int totalPlanSets,
  }) {
    _trainingState = {
      'mode': 'training',
      'exerciseName': exerciseName,
      'currentSet': currentSet,
      'totalSets': totalSets,
      'exerciseIndex': exerciseIndex,
      'totalExercises': totalExercises,
      'completedSets': completedSets,
      'totalPlanSets': totalPlanSets,
    };
    pushFormData();
  }

  /// 进入休息状态
  void startRest({
    required String exerciseName,
    required int restSeconds,
    required int totalRestSeconds,
    required int currentSet,
    required int totalSets,
    required int exerciseIndex,
    required int totalExercises,
    required int completedSets,
    required int totalPlanSets,
  }) {
    _trainingState = {
      'mode': 'rest',
      'exerciseName': exerciseName,
      'restSeconds': restSeconds,
      'totalRestSeconds': totalRestSeconds,
      'currentSet': currentSet,
      'totalSets': totalSets,
      'exerciseIndex': exerciseIndex,
      'totalExercises': totalExercises,
      'completedSets': completedSets,
      'totalPlanSets': totalPlanSets,
    };
    pushFormData();
  }

  /// 训练状态更新（set变化等）
  void updateTrainingState({
    required String exerciseName,
    required int currentSet,
    required int totalSets,
    required int exerciseIndex,
    required int totalExercises,
    required int completedSets,
    required int totalPlanSets,
  }) {
    _trainingState = {
      'mode': 'training',
      'exerciseName': exerciseName,
      'currentSet': currentSet,
      'totalSets': totalSets,
      'exerciseIndex': exerciseIndex,
      'totalExercises': totalExercises,
      'completedSets': completedSets,
      'totalPlanSets': totalPlanSets,
    };
    pushFormData();
  }

  /// 训练结束，切回空闲态
  void endTraining() {
    _trainingState = null;
    pushFormData();
  }

  // ============================================================
  // 数据构建
  // ============================================================

  /// 构建卡片数据（训练态优先，否则显示今日概要）
  Map<String, dynamic> _buildFormData() {
    try {
      // 训练态数据优先
      if (_trainingState != null) {
        return {
          ..._trainingState!,
          ..._getThemeColorsForWidget(),
          'trainingTime': _getTrainingTime(),
        };
      }

      // 空闲态：今日训练概要
      final records = Storage.getRecords();
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      int todayTrainings = 0;
      int todayDuration = 0;
      int todayWeight = 0;

      for (final r in records) {
        final ts = r['date'] ?? r['createTime'];
        if (ts is int) {
          final d = DateTime.fromMillisecondsSinceEpoch(ts);
          final dStr =
              '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          if (dStr == todayStr) {
            todayTrainings++;
            todayDuration += (r['duration'] as num?)?.toInt() ?? 0;
            todayWeight += (r['totalWeight'] as num?)?.toInt() ?? 0;
          }
        }
      }

      int streak = 0;
      if (records.isNotEmpty) {
        final dates = <String>{};
        for (final r in records) {
          final ts = r['date'] ?? r['createTime'];
          if (ts is int) {
            final d = DateTime.fromMillisecondsSinceEpoch(ts);
            dates.add(
                '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
          }
        }
        var checkDate = DateTime.now();
        while (dates.contains(
            '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}')) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        }
      }

      String lastTraining = '';
      String lastDate = '';
      if (records.isNotEmpty) {
        final last = records.last;
        lastTraining = last['name'] as String? ?? '';
        final ts = last['date'] ?? last['createTime'];
        if (ts is int) {
          final d = DateTime.fromMillisecondsSinceEpoch(ts);
          lastDate = '${d.month}/${d.day}';
        }
      }

      return {
        'mode': 'idle',
        'todayTrainings': todayTrainings,
        'todayDuration': todayDuration,
        'todayWeight': todayWeight,
        'streak': streak,
        'lastTraining': lastTraining,
        'lastDate': lastDate,
        ..._getThemeColorsForWidget(),
        'trainingTime': _getTrainingTime(),
      };
    } catch (e) {
      debugPrint('[FormKit] _buildFormData error: $e');
      return {
        'mode': 'idle',
        'todayTrainings': 0,
        'todayDuration': 0,
        'todayWeight': 0,
        'streak': 0,
        'lastTraining': '',
        'lastDate': '',
        ..._getThemeColorsForWidget(),
        'trainingTime': _getTrainingTime(),
      };
    }
  }

  String _getTrainingTime() {
    final settings = Storage.getSettings();
    return settings['trainingTime'] as String? ?? '';
  }

  /// 推送卡片数据到原生 preferences
  Future<void> pushFormData() async {
    if (!Platform.isOhos) return;
    try {
      final data = _buildFormData();
      final jsonStr = jsonEncode(data);
      await _channel.invokeMethod<void>('updateFormData', jsonStr);
      debugPrint('[FormKit] pushFormData success, mode: ${data['mode']}');
    } catch (e) {
      debugPrint('[FormKit] pushFormData error: $e');
    }
  }

  /// 请求刷新卡片（训练完成后调用）
  Future<void> requestFormUpdate() async {
    if (!Platform.isOhos) return;
    await pushFormData();
  }

  /// 根据当前主题ID获取卡片所需的颜色配置
  static Map<String, String> _getThemeColorsForWidget() {
    final settings = Storage.getSettings();
    final themeId = settings['theme'] ?? 'vitality-sport';
    const themeColorMap = <String, Map<String, String>>{
      'vitality-sport': {
        'accentColor': '#FF6B35',
        'bgColor': '#FFFFFF',
        'textPrimaryColor': '#222222',
        'textSecondaryColor': '#999999',
      },
      'iron-forge': {
        'accentColor': '#EF4444',
        'bgColor': '#141C28',
        'textPrimaryColor': '#F1F5F9',
        'textSecondaryColor': '#94A3B8',
      },
      'blossom': {
        'accentColor': '#EC4899',
        'bgColor': '#FFFFFF',
        'textPrimaryColor': '#1E1B2E',
        'textSecondaryColor': '#A89BB8',
      },
      'silver-care': {
        'accentColor': '#059669',
        'bgColor': '#FFFFFF',
        'textPrimaryColor': '#111827',
        'textSecondaryColor': '#6B7280',
      },
      'fresh-minimal': {
        'accentColor': '#0EA5E9',
        'bgColor': '#FFFFFF',
        'textPrimaryColor': '#0F172A',
        'textSecondaryColor': '#94A3B8',
      },
      'neon-cyber': {
        'accentColor': '#D946EF',
        'bgColor': '#15002E',
        'textPrimaryColor': '#F5F3FF',
        'textSecondaryColor': '#A78BFA',
      },
      'black-gold': {
        'accentColor': '#F59E0B',
        'bgColor': '#1A1612',
        'textPrimaryColor': '#FEF3C7',
        'textSecondaryColor': '#A89F84',
      },
    };
    return themeColorMap[themeId] ?? themeColorMap['vitality-sport']!;
  }
}
