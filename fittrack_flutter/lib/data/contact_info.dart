/// 官方联系方式数据源
class ContactChannel {
  final String type; // qq_group / wechat_group / wechat / email
  final String label;
  final String value;
  final String hint;
  final String? qrData; // 群二维码内容（群号/进群链接），null 表示无需二维码
  final bool copyable; // 是否支持复制（微信群无群号，不支持复制）

  const ContactChannel({
    required this.type,
    required this.label,
    required this.value,
    required this.hint,
    this.qrData,
    this.copyable = true,
  });
}

const List<ContactChannel> kContactChannels = [
  ContactChannel(
    type: 'qq_group',
    label: 'QQ 群',
    value: '1036134802',
    hint: '保存二维码后打开 QQ 扫一扫进群',
    copyable: true,
  ),
  ContactChannel(
    type: 'wechat_group',
    label: '微信群',
    value: '扫码加入交流群',
    hint: '保存二维码后打开微信扫一扫进群',
    copyable: false,
  ),
  ContactChannel(
    type: 'wechat',
    label: '客服微信',
    value: 'h15575801283',
    hint: '添加时备注"用户"，可获取进群邀请',
  ),
  ContactChannel(
    type: 'email',
    label: '邮箱',
    value: '15575712021@163.com',
    hint: '反馈问题请附上设备型号、系统版本与问题截图',
  ),
];
