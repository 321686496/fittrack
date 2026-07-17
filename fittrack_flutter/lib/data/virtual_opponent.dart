import 'dart:math';

/// v1 虚拟对手系统 —— 数据模型与生成引擎
///
/// 依据：docs/versions/v1-获客留存版/02_功能清单.md §E1
/// 设计要点：
/// - 4层水平分布（休闲/规律/活跃/硬核）
/// - 每个对手含 id/nickname/level/avatarSeed/persona
/// - 按真实日历时间独立推进（不依赖用户训练事件）
/// - 胜负分布真实化：碾压局(25%)/胶着局(50%)/被吊打局(25%)

/// 简单整数区间（Dart 2.x 兼容，替代 Dart 3 records 语法）
class Range {
  final int min;
  final int max;
  const Range(this.min, this.max);
}

/// 对战结果（用户得分 / 对手得分）
class MatchOutcome {
  final double userScore;
  final double opponentScore;
  const MatchOutcome(this.userScore, this.opponentScore);
}

/// 对手水平层级
enum OpponentTier {
  casual, // 休闲：每周1-2次，40-60min，轻重量
  regular, // 规律：每周2-3次，60-75min，中等重量
  active, // 活跃：每周3-4次，60-90min，中上重量
  hardcore, // 硬核：每周4-7次，75-90min，大重量
}

extension OpponentTierExt on OpponentTier {
  String get label {
    switch (this) {
      case OpponentTier.casual:
        return '休闲';
      case OpponentTier.regular:
        return '规律';
      case OpponentTier.active:
        return '活跃';
      case OpponentTier.hardcore:
        return '硬核';
    }
  }

  /// 该层级每周训练次数范围
  Range get weeklyTrainingRange {
    switch (this) {
      case OpponentTier.casual:
        return const Range(1, 2);
      case OpponentTier.regular:
        return const Range(2, 3);
      case OpponentTier.active:
        return const Range(3, 4);
      case OpponentTier.hardcore:
        return const Range(4, 7);
    }
  }

  /// 该层级单次训练时长范围（分钟）
  Range get sessionDurationRange {
    switch (this) {
      case OpponentTier.casual:
        return const Range(40, 60);
      case OpponentTier.regular:
        return const Range(60, 75);
      case OpponentTier.active:
        return const Range(60, 90);
      case OpponentTier.hardcore:
        return const Range(75, 90);
    }
  }

  /// 该层级单次训练总重量范围（kg）
  Range get sessionWeightRange {
    switch (this) {
      case OpponentTier.casual:
        return const Range(800, 2500);
      case OpponentTier.regular:
        return const Range(2000, 5000);
      case OpponentTier.active:
        return const Range(4000, 9000);
      case OpponentTier.hardcore:
        return const Range(7000, 15000);
    }
  }
}

/// 虚拟对手数据模型
class VirtualOpponent {
  final String id;
  final String nickname;
  final OpponentTier tier;
  final String avatarSeed;
  final String persona; // 人设模板，如"周三雷打不动练腿的程序员"

  /// 当前周训练数据（由引擎推进）
  int weeklyTrainings;
  int weeklyWeight; // 本周累计总重量（kg）
  int weeklyDuration; // 本周累计训练时长（min）

  /// 上周训练数据（用于对比展示）
  int lastWeekTrainings;
  int lastWeekWeight;

  /// 偶尔动态（"今天加班没练"等），null 表示本周无动态
  String? currentStatus;

  VirtualOpponent({
    required this.id,
    required this.nickname,
    required this.tier,
    required this.avatarSeed,
    required this.persona,
    this.weeklyTrainings = 0,
    this.weeklyWeight = 0,
    this.weeklyDuration = 0,
    this.lastWeekTrainings = 0,
    this.lastWeekWeight = 0,
    this.currentStatus,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'tier': tier.name,
        'avatarSeed': avatarSeed,
        'persona': persona,
        'weeklyTrainings': weeklyTrainings,
        'weeklyWeight': weeklyWeight,
        'weeklyDuration': weeklyDuration,
        'lastWeekTrainings': lastWeekTrainings,
        'lastWeekWeight': lastWeekWeight,
        'currentStatus': currentStatus,
      };

  factory VirtualOpponent.fromJson(Map<String, dynamic> json) {
    return VirtualOpponent(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      tier: OpponentTier.values.firstWhere(
        (t) => t.name == json['tier'],
        orElse: () => OpponentTier.casual,
      ),
      avatarSeed: json['avatarSeed'] as String,
      persona: json['persona'] as String,
      weeklyTrainings: json['weeklyTrainings'] as int? ?? 0,
      weeklyWeight: json['weeklyWeight'] as int? ?? 0,
      weeklyDuration: json['weeklyDuration'] as int? ?? 0,
      lastWeekTrainings: json['lastWeekTrainings'] as int? ?? 0,
      lastWeekWeight: json['lastWeekWeight'] as int? ?? 0,
      currentStatus: json['currentStatus'] as String?,
    );
  }
}

/// 虚拟对手生成与推进引擎
class VirtualOpponentEngine {
  static final VirtualOpponentEngine instance = VirtualOpponentEngine._();
  VirtualOpponentEngine._();

  static final _random = Random();

  /// 人设模板池（增加真实感）
  static const List<String> _personaTemplates = [
    '周三雷打不动练腿的程序员',
    '只爱卧推的健身狂热者',
    '晨跑夜练的双修党',
    '减脂期硬核控制饮食的会计师',
    '周末战士·平时加班的运营',
    '追求PR的力量举爱好者',
    '复合动作至上派',
    '孤立动作细节控',
    '三分化严格执行者',
    '五分化进阶玩家',
  ];

  /// 偶尔动态池（含 null 表示无动态，约占 3/8）
  static const List<String?> _statusTemplates = [
    '今天加班没练',
    '感冒了，休息一天',
    '出差中，本周只能练1次',
    '昨天练太狠，今天歇',
    '本周已达标，奖励自己休息',
    null, // 60% 无动态
    null,
    null,
  ];

  /// 生成单个虚拟对手
  VirtualOpponent generateOne(String id, OpponentTier tier) {
    final nickname = _generateNickname();
    final avatarSeed = 'avatar_${id.hashCode.abs()}';
    final persona = _personaTemplates[_random.nextInt(_personaTemplates.length)];

    return VirtualOpponent(
      id: id,
      nickname: nickname,
      tier: tier,
      avatarSeed: avatarSeed,
      persona: persona,
    );
  }

  /// 生成对手池（100对手，按4层分布）
  ///
  /// v1.2调优：原300+工作量大，v1先上100个验证参与率后再扩量
  /// 分布比例：休闲40% / 规律30% / 活跃20% / 硬核10%
  List<VirtualOpponent> generatePool({int total = 100}) {
    final pool = <VirtualOpponent>[];
    final casualCount = (total * 0.40).round();
    final regularCount = (total * 0.30).round();
    final activeCount = (total * 0.20).round();
    final hardcoreCount = total - casualCount - regularCount - activeCount;

    for (int i = 0; i < casualCount; i++) {
      pool.add(generateOne('vo_casual_$i', OpponentTier.casual));
    }
    for (int i = 0; i < regularCount; i++) {
      pool.add(generateOne('vo_regular_$i', OpponentTier.regular));
    }
    for (int i = 0; i < activeCount; i++) {
      pool.add(generateOne('vo_active_$i', OpponentTier.active));
    }
    for (int i = 0; i < hardcoreCount; i++) {
      pool.add(generateOne('vo_hardcore_$i', OpponentTier.hardcore));
    }
    return pool;
  }

  /// 周日凌晨推进对手数据（不依赖用户训练事件）
  ///
  /// 算法：
  /// 1. 上周数据归档到 lastWeek*
  /// 2. 本周数据按层级随机生成（符合健身规律）
  /// 3. 10% 概率发布偶尔动态
  void advanceWeekly(VirtualOpponent opponent) {
    opponent.lastWeekTrainings = opponent.weeklyTrainings;
    opponent.lastWeekWeight = opponent.weeklyWeight;

    final trainingRange = opponent.tier.weeklyTrainingRange;
    final durationRange = opponent.tier.sessionDurationRange;
    final weightRange = opponent.tier.sessionWeightRange;

    final sessionCount =
        _random.nextInt(trainingRange.max - trainingRange.min + 1) + trainingRange.min;
    opponent.weeklyTrainings = sessionCount;

    int totalWeight = 0;
    int totalDuration = 0;
    for (int i = 0; i < sessionCount; i++) {
      final duration = _random.nextInt(durationRange.max - durationRange.min + 1) +
          durationRange.min;
      final weight = _random.nextInt(weightRange.max - weightRange.min + 1) +
          weightRange.min;
      totalDuration += duration;
      totalWeight += weight;
    }
    opponent.weeklyWeight = totalWeight;
    opponent.weeklyDuration = totalDuration;

    // 偶尔动态（10%概率发布非null动态）
    opponent.currentStatus = _statusTemplates[_random.nextInt(_statusTemplates.length)];
  }

  /// 胜负分布算法（真实化）
  ///
  /// 分布：碾压局(25%) / 胶着局(50%) / 被吊打局(25%)
  /// 返回 MatchOutcome（userScore / opponentScore，0-1 区间）
  MatchOutcome computeOutcome(
      int userWeeklyTrainings, VirtualOpponent opponent) {
    final roll = _random.nextDouble();
    double userScore, opponentScore;

    if (roll < 0.25) {
      // 碾压局：用户大幅领先
      userScore = 0.75 + _random.nextDouble() * 0.20; // 0.75-0.95
      opponentScore = 0.10 + _random.nextDouble() * 0.20; // 0.10-0.30
    } else if (roll < 0.75) {
      // 胶着局：差距小
      userScore = 0.45 + _random.nextDouble() * 0.20; // 0.45-0.65
      opponentScore = 0.40 + _random.nextDouble() * 0.20; // 0.40-0.60
    } else {
      // 被吊打局：用户落后
      userScore = 0.15 + _random.nextDouble() * 0.20; // 0.15-0.35
      opponentScore = 0.70 + _random.nextDouble() * 0.20; // 0.70-0.90
    }

    return MatchOutcome(userScore, opponentScore);
  }

  /// 计算用户在同水平层的超越百分比
  ///
  /// 例如：用户本周训练3次，匹配"规律"层
  /// 引擎采样100个规律层对手，统计用户超越多少对手
  int computePercentile(int userWeeklyTrainings, OpponentTier tier,
      {int sampleSize = 100}) {
    final range = tier.weeklyTrainingRange;
    int below = 0;
    for (int i = 0; i < sampleSize; i++) {
      final opponentTrainings =
          _random.nextInt(range.max - range.min + 1) + range.min;
      if (opponentTrainings < userWeeklyTrainings) below++;
    }
    return ((below / sampleSize) * 100).round();
  }

  /// 冷启动匹配：根据用户自报训练频率选择匹配层
  ///
  /// 用户回答"每周打算练几次"：
  /// - 1-2次 → 休闲层
  /// - 3次 → 规律层
  /// - 4-5次 → 活跃层
  /// - 6+次 → 硬核层
  OpponentTier matchTierByWeeklyTarget(int weeklyTarget) {
    if (weeklyTarget <= 2) return OpponentTier.casual;
    if (weeklyTarget == 3) return OpponentTier.regular;
    if (weeklyTarget <= 5) return OpponentTier.active;
    return OpponentTier.hardcore;
  }

  String _generateNickname() {
    const prefixes = ['钢铁', '肌肉', '力量', '健身', '燃力', '铁血', '极致', '永不'];
    const suffixes = ['小子', '达人', '战士', '教练', '老铁', '队长', '先生', '小姐'];
    return '${prefixes[_random.nextInt(prefixes.length)]}'
        '${suffixes[_random.nextInt(suffixes.length)]}';
  }
}
