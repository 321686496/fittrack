import '../l10n/i18n.dart';
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

  TrainingNote({
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
        return trn('轻松');
      case 2:
        return trn('尚可');
      case 3:
        return trn('适中');
      case 4:
        return trn('吃力');
      case 5:
        return trn('爆炸');
      default:
        return trn('适中');
    }
  }

  /// 创建时间格式化
  String get dateLabel {
    final d = DateTime.fromMillisecondsSinceEpoch(createTime);
    return trn('${d.year}年${d.month}月${d.day}日');
  }
}

/// 心情贴纸选项（使用文字标签，避免 emoji）
class MoodStickers {
  static List<Map<String, String>> get options => _optionsMemo.value;
  static final LocaleMemo<List<Map<String, String>>> _optionsMemo = LocaleMemo(() => [
    {'id': 'fire', 'label': trn('燃烧'), 'icon': 'local_fire_department'},
    {'id': 'bolt', 'label': trn('来电'), 'icon': 'bolt'},
    {'id': 'fitness', 'label': trn('充实'), 'icon': 'fitness_center'},
    {'id': 'spa', 'label': trn('舒缓'), 'icon': 'spa'},
    {'id': 'trending_up', 'label': trn('进步'), 'icon': 'trending_up'},
    {'id': 'star', 'label': trn('满意'), 'icon': 'star'},
    {'id': 'coffee', 'label': trn('疲惫'), 'icon': 'coffee'},
    {'id': 'sleep', 'label': trn('休息'), 'icon': 'bedtime'},
  ]);

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
  static List<String> get parts => _partsMemo.value;
  static final LocaleMemo<List<String>> _partsMemo = LocaleMemo(() => [
    trn('胸'),
    trn('背'),
    trn('肩'),
    trn('手臂'),
    trn('前臂'),
    trn('大腿'),
    trn('小腿'),
    trn('臀部'),
    trn('核心'),
    trn('腰'),
    trn('颈部'),
    trn('全身'),
  ]);
}
