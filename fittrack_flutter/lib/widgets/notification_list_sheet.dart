/// lib/widgets/notification_list_sheet.dart

import 'package:flutter/material.dart';
import '../data/storage.dart';
import '../themes/app_themes.dart';

/// 通知列表底部弹窗
///
/// 从 Storage 读取真实通知记录并展示。
/// 支持标记已读、清空操作。
/// profile_page 和 home_page 的通知入口复用此组件。
class NotificationListSheet {
  /// 展示通知列表
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _NotificationListContent(),
    );
  }
}

class _NotificationListContent extends StatefulWidget {
  const _NotificationListContent();

  @override
  State<_NotificationListContent> createState() =>
      _NotificationListContentState();
}

class _NotificationListContentState extends State<_NotificationListContent> {
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    setState(() {
      _notifications = Storage.getNotifications();
    });
  }

  /// 图标映射
  IconData _iconForType(String type) {
    switch (type) {
      case 'gym_card':
        return Icons.card_membership_outlined;
      case 'daily_training':
        return Icons.fitness_center;
      case 'rest_end':
        return Icons.timer;
      default:
        return Icons.info;
    }
  }

  /// 相对时间格式化
  String _formatTime(int createdAt) {
    final now = DateTime.now();
    final dt = DateTime.fromMillisecondsSinceEpoch(createdAt);
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${dt.month}/${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    // 主题色映射说明：
    // 计划中使用了 bgPrimary/textTertiary/divider/accent，但 LiftTrackColors 未提供这些字段。
    // 这里使用实际存在的等价字段：bgCard / textMuted / borderColor / accentGlow。
    final colors = Theme.of(context).extension<LiftTrackColors>()!;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.7,
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 顶部标题栏
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('通知', style: Theme.of(context).textTheme.titleLarge),
                Row(
                  children: [
                    if (_notifications.any((n) => n['read'] != true))
                      TextButton(
                        onPressed: () {
                          Storage.markAllNotificationsRead();
                          _loadNotifications();
                        },
                        child: const Text('全部已读'),
                      ),
                    if (_notifications.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          Storage.clearNotifications();
                          _loadNotifications();
                        },
                        child: const Text('清空'),
                      ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 通知列表
          Expanded(
            child: _notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_none,
                            size: 64, color: colors.textMuted),
                        const SizedBox(height: 12),
                        Text('暂无通知',
                            style: TextStyle(color: colors.textSecondary)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, indent: 56, color: colors.borderColor),
                    itemBuilder: (ctx, idx) {
                      final n = _notifications[idx];
                      final isUnread = n['read'] != true;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colors.bgSecondary,
                          child: Icon(_iconForType(n['type'] as String? ?? ''),
                              color: colors.accentGlow),
                        ),
                        title: Row(
                          children: [
                            if (isUnread)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: colors.accentGlow,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Expanded(
                              child: Text(n['title'] as String? ?? '',
                                  style: TextStyle(
                                    fontWeight: isUnread
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  )),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          n['body'] as String? ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.textSecondary),
                        ),
                        trailing: Text(
                          _formatTime(n['createdAt'] as int? ?? 0),
                          style: TextStyle(
                              color: colors.textMuted, fontSize: 12),
                        ),
                        onTap: () {
                          if (isUnread) {
                            Storage.markNotificationRead(
                                n['id'] as String? ?? '');
                            _loadNotifications();
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
