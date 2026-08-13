/// 官方联系方式数据源
///
/// ⚠️ 上线前请将占位信息替换为真实联系方式：
/// - QQ 群：真实群号（进群二维码可在 QQ 群管理中生成）
/// - 微信群：真实群二维码图片链接/群号
/// - 客服微信：真实微信号
/// - 邮箱：真实客服邮箱
class ContactChannel {
  final String type; // qq_group / wechat_group / wechat / email
  final String label;
  final String value;
  final String hint;
  final String? qrData; // 群二维码内容（群号/进群链接），null 表示无需二维码

  const ContactChannel({
    required this.type,
    required this.label,
    required this.value,
    required this.hint,
    this.qrData,
  });
}

const List<ContactChannel> kContactChannels = [
  ContactChannel(
    type: 'qq_group',
    label: 'QQ 群',
    value: '123456789',
    hint: '复制群号到 QQ 搜索加入，或直接扫码进群',
    qrData: 'https://qm.qq.com/q/example-group',
  ),
  ContactChannel(
    type: 'wechat_group',
    label: '微信群',
    value: 'LiftTrack 官方交流群',
    hint: '扫码添加客服微信后邀请进群',
    qrData: 'wechat-group-example',
  ),
  ContactChannel(
    type: 'wechat',
    label: '客服微信',
    value: 'LiftTrack_Support',
    hint: '添加时备注"LiftTrack 用户"，可获取进群邀请',
  ),
  ContactChannel(
    type: 'email',
    label: '邮箱',
    value: 'support@lifttrack.cn',
    hint: '反馈问题请附上设备型号、系统版本与问题截图',
  ),
];
