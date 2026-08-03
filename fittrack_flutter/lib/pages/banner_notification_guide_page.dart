import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../themes/app_themes.dart';
import '../widgets/page_header.dart';
import '../services/permission_service.dart';

/// 横幅通知引导页
///
/// 引导用户去系统设置开启横幅通知开关。
/// 横幅通知是用户级隐私设置，应用无法通过 API 强制开启。
class BannerNotificationGuidePage extends StatefulWidget {
  const BannerNotificationGuidePage({super.key});

  @override
  State<BannerNotificationGuidePage> createState() =>
      _BannerNotificationGuidePageState();
}

class _BannerNotificationGuidePageState
    extends State<BannerNotificationGuidePage> {
  bool _notificationGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await PermissionService.isNotificationGranted();
    if (mounted) {
      setState(() => _notificationGranted = granted);
    }
  }

  Future<void> _openSettings() async {
    // permission_handler 提供的顶层函数，跳转系统应用设置页
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            onBack: () => context.pop(),
            title: '横幅通知引导',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 说明卡片
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notifications_active,
                            color: colors.accentGlow, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('为什么需要开启横幅通知？',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Text(
                                '休息结束时，横幅通知会在屏幕顶部弹出提醒，类似微信消息通知。\n\n'
                                '由于系统限制，横幅通知需要您手动开启，应用无法自动开启此开关。',
                                style: TextStyle(color: colors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 步骤卡片
                  Text('开启步骤', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _buildStep(colors, 1, '打开手机「设置」'),
                  _buildStep(colors, 2, '进入「通知管理」> 找到「LiftTrack」'),
                  _buildStep(colors, 3, '开启「横幅通知」开关'),
                  const SizedBox(height: 20),
                  // 状态指示器
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _notificationGranted
                          ? colors.accentGlow.withOpacity(0.1)
                          : colors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _notificationGranted
                              ? Icons.check_circle
                              : Icons.info_outline,
                          color: _notificationGranted
                              ? Colors.green
                              : colors.textMuted,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _notificationGranted
                                ? '通知权限已开启，请确认横幅通知开关也已开启'
                                : '通知权限未开启，请先开启通知权限',
                            style: TextStyle(color: colors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 底部按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _openSettings,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('去开启'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(LiftTrackColors colors, int num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colors.accentGlow,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$num',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}
