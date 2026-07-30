/// lib/models/notification_record.dart

/// App 内通知记录模型
class NotificationRecord {
  final String id;
  final String type; // 'gym_card' | 'daily_training' | 'rest_end' | 'system'
  final String title;
  final String body;
  final int createdAt; // millisecondsSinceEpoch
  final bool read;

  const NotificationRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'title': title,
        'body': body,
        'createdAt': createdAt,
        'read': read,
      };

  factory NotificationRecord.fromMap(Map<String, dynamic> map) =>
      NotificationRecord(
        id: map['id'] as String? ?? '',
        type: map['type'] as String? ?? 'system',
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        createdAt: map['createdAt'] as int? ?? 0,
        read: map['read'] as bool? ?? false,
      );

  NotificationRecord copyWith({bool? read}) => NotificationRecord(
        id: id,
        type: type,
        title: title,
        body: body,
        createdAt: createdAt,
        read: read ?? this.read,
      );
}
