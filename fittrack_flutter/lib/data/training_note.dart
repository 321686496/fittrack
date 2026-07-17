/// v1 训练笔记数据模型
///
/// 依据：docs/versions/v1-获客留存版/02_功能清单.md V1-11-01
///
/// 字段：
/// - id: 笔记唯一ID
/// - createTime: 创建时间戳
/// - recordId: 绑定的训练记录ID（可空，不绑定训练时为 null）
/// - feeling: 训练感受 1-5 档（1=轻松，5=爆炸）
/// - bestExercise: 最满意动作（文本）
/// - soreParts: 身体状态酸痛部位标记（数组）
/// - content: 自由心得（限200字）
/// - moodSticker: 心情贴纸（字符串标识）
/// - isFeatured: 是否精选
class TrainingNote {
  final String id;
  final int createTime;
  final String? recordId;
  final int feeling; // 1-5
  final String bestExercise;
  final List<String> soreParts;
  final String content;
  final String moodSticker;
  final bool isFeatured;

  const TrainingNote({
    required this.id,
    required this.createTime,
    this.recordId,
    required this.feeling,
    required this.bestExercise,
    required this.soreParts,
    required this.content,
    required this.moodSticker,
    required this.isFeatured,
  });

  factory TrainingNote.fromMap(Map<String, dynamic> map) {
    return TrainingNote(
      id: map['id'] as String? ?? '',
      createTime: (map['createTime'] as num?)?.toInt() ?? 0,
      recordId: map['recordId'] as String?,
      feeling: (map['feeling'] as num?)?.toInt() ?? 3,
      bestExercise: map['bestExercise'] as String? ?? '',
      soreParts: (map['soreParts'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      content: map['content'] as String? ?? '',
      moodSticker: map['moodSticker'] as String? ?? '',
      isFeatured: map['isFeatured'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createTime': createTime,
      'recordId': recordId,
      'feeling': feeling,
      'bestExercise': bestExercise,
      'soreParts': soreParts,
      'content': content,
      'moodSticker': moodSticker,
      'isFeatured': isFeatured,
    };
  }

  TrainingNote copyWith({
    String? id,
    int? createTime,
    String? recordId,
    int? feeling,
    String? bestExercise,
    List<String>? soreParts,
    String? content,
    String? moodSticker,
    bool? isFeatured,
  }) {
    return TrainingNote(
      id: id ?? this.id,
      createTime: createTime ?? this.createTime,
      recordId: recordId ?? this.recordId,
      feeling: feeling ?? this.feeling,
      bestExercise: bestExercise ?? this.bestExercise,
      soreParts: soreParts ?? this.soreParts,
      content: content ?? this.content,
      moodSticker: moodSticker ?? this.moodSticker,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }

  /// 感受档位文案
  String get feelingLabel {
    switch (feeling) {
      case 1:
        return '轻松';
      case 2:
        return '尚可';
      case 3:
        return '适中';
      case 4:
        return '吃力';
      case 5:
        return '爆炸';
      default:
        return '适中';
    }
  }

  /// 创建时间格式化
  String get dateLabel {
    final d = DateTime.fromMillisecondsSinceEpoch(createTime);
    return '${d.year}年${d.month}月${d.day}日';
  }
}

/// 心情贴纸选项（使用文字标签，避免 emoji）
class MoodStickers {
  static const List<Map<String, String>> options = [
    {'id': 'fire', 'label': '燃烧', 'icon': 'local_fire_department'},
    {'id': 'bolt', 'label': '来电', 'icon': 'bolt'},
    {'id': 'fitness', 'label': '充实', 'icon': 'fitness_center'},
    {'id': 'spa', 'label': '舒缓', 'icon': 'spa'},
    {'id': 'trending_up', 'label': '进步', 'icon': 'trending_up'},
    {'id': 'star', 'label': '满意', 'icon': 'star'},
    {'id': 'coffee', 'label': '疲惫', 'icon': 'coffee'},
    {'id': 'sleep', 'label': '休息', 'icon': 'bedtime'},
  ];

  static String labelOf(String id) {
    return options.firstWhere(
      (o) => o['id'] == id,
      orElse: () => {'label': ''},
    )['label']!;
  }

  static String iconOf(String id) {
    return options.firstWhere(
      (o) => o['id'] == id,
      orElse: () => {'icon': 'mood'},
    )['icon']!;
  }
}

/// 酸痛部位选项
class SorePartOptions {
  static const List<String> parts = [
    '胸',
    '背',
    '肩',
    '手臂',
    '前臂',
    '大腿',
    '小腿',
    '臀部',
    '核心',
    '腰',
    '颈部',
    '全身',
  ];
}
