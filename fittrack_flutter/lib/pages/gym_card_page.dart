import 'package:flutter/material.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';
import '../services/poster_generator.dart';
import '../widgets/common_widgets.dart';
import '../widgets/gym_card_poster.dart';
import '../widgets/page_header.dart';
import '../widgets/poster_preview_dialog.dart';

class GymCardPage extends StatefulWidget {
  const GymCardPage({super.key});

  @override
  State<GymCardPage> createState() => _GymCardPageState();
}

class _GymCardPageState extends State<GymCardPage> {
  List<Map<String, dynamic>> _cards = [];
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  void _loadCards() {
    setState(() {
      _cards = Storage.getGymCards();
    });
  }

  /// 获取健身卡状态信息
  Map<String, dynamic> _getCardStatus(Map<String, dynamic> card) {
    final now = DateTime.now();
    final endDate = card['endDate'] as int? ?? 0;
    final remainingCount = card['remainingCount'] as int? ?? -1;
    final cardType = card['cardType'] as String? ?? '';

    // 次卡：根据剩余次数判断
    if (cardType == '次卡' && remainingCount >= 0) {
      if (remainingCount == 0) {
        return {
          'status': 'used_up',
          'label': '已用完',
          'color': Colors.grey,
          'icon': Icons.block_outlined,
          'tip': '该次卡已用完所有次数',
        };
      } else if (remainingCount <= 3) {
        return {
          'status': 'low_count',
          'label': '即将用完',
          'color': Colors.orange,
          'icon': Icons.warning_amber_rounded,
          'tip': '仅剩 $remainingCount 次，注意续卡',
        };
      } else {
        return {
          'status': 'active',
          'label': '使用中',
          'color': Colors.green,
          'icon': Icons.check_circle_outline,
          'tip': '剩余 $remainingCount 次',
        };
      }
    }

    // 期限卡：根据到期日期判断
    if (endDate > 0) {
      final end = DateTime.fromMillisecondsSinceEpoch(endDate);
      final diff = end.difference(now).inDays;

      if (diff < 0) {
        return {
          'status': 'expired',
          'label': '已过期',
          'color': Colors.red,
          'icon': Icons.error_outline,
          'tip': '已过期 ${-diff} 天，请及时续卡',
        };
      } else if (diff == 0) {
        return {
          'status': 'expiring_today',
          'label': '今天到期',
          'color': Colors.red,
          'icon': Icons.alarm_on,
          'tip': '今天到期，请及时续卡！',
        };
      } else if (diff <= 7) {
        return {
          'status': 'expiring_soon',
          'label': '即将到期',
          'color': Colors.orange,
          'icon': Icons.warning_amber_rounded,
          'tip': '还有 $diff 天到期，建议尽快续卡',
        };
      } else if (diff <= 30) {
        return {
          'status': 'normal',
          'label': '使用中',
          'color': Colors.green,
          'icon': Icons.check_circle_outline,
          'tip': '还有 $diff 天到期',
        };
      } else {
        return {
          'status': 'active',
          'label': '使用中',
          'color': Colors.green,
          'icon': Icons.check_circle_outline,
          'tip': '还有 $diff 天到期',
        };
      }
    }

    return {
      'status': 'unknown',
      'label': '未设置',
      'color': Colors.grey,
      'icon': Icons.help_outline,
      'tip': '未设置有效期信息',
    };
  }

  /// 计算日均费用
  String _calcDailyCost(Map<String, dynamic> card) {
    final price = (card['price'] as num?)?.toDouble() ?? 0;
    final startDate = card['startDate'] as int? ?? 0;
    final endDate = card['endDate'] as int? ?? 0;
    final cardType = card['cardType'] as String? ?? '';
    final totalCount = card['totalCount'] as int? ?? -1;

    if (price <= 0) return '--';

    // 次卡：按次数算单次费用
    if (cardType == '次卡' && totalCount > 0) {
      final perTime = price / totalCount;
      return '${perTime.toStringAsFixed(1)}元/次';
    }

    // 期限卡：按天数算日均费用
    if (startDate > 0 && endDate > 0) {
      final start = DateTime.fromMillisecondsSinceEpoch(startDate);
      final end = DateTime.fromMillisecondsSinceEpoch(endDate);
      final days = end.difference(start).inDays;
      if (days > 0) {
        final daily = price / days;
        return '${daily.toStringAsFixed(1)}元/天';
      }
    }

    return '--';
  }

  /// 计算使用进度
  double _calcProgress(Map<String, dynamic> card) {
    final cardType = card['cardType'] as String? ?? '';
    final startDate = card['startDate'] as int? ?? 0;
    final endDate = card['endDate'] as int? ?? 0;
    final remainingCount = card['remainingCount'] as int? ?? -1;
    final totalCount = card['totalCount'] as int? ?? -1;

    // 次卡
    if (cardType == '次卡' && totalCount > 0) {
      final used = totalCount - (remainingCount >= 0 ? remainingCount : 0);
      return (used / totalCount).clamp(0.0, 1.0);
    }

    // 期限卡
    if (startDate > 0 && endDate > 0) {
      final start = DateTime.fromMillisecondsSinceEpoch(startDate);
      final end = DateTime.fromMillisecondsSinceEpoch(endDate);
      final now = DateTime.now();
      final total = end.difference(start).inMilliseconds;
      final elapsed = now.difference(start).inMilliseconds;
      if (total > 0) {
        return (elapsed / total).clamp(0.0, 1.0);
      }
    }

    return 0;
  }

  String _formatDate(int timestamp) {
    if (timestamp <= 0) return '未设置';
    final d = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void _showAddCardSheet({Map<String, dynamic>? existingCard}) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final isEdit = existingCard != null;

    final nameCtrl = TextEditingController(text: existingCard?['name']?.toString() ?? '');
    final gymNameCtrl = TextEditingController(text: existingCard?['gymName']?.toString() ?? '');
    final priceCtrl = TextEditingController(text: existingCard?['price']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: existingCard?['phone']?.toString() ?? '');
    final remarkCtrl = TextEditingController(text: existingCard?['remark']?.toString() ?? '');
    // 次卡总次数/剩余次数 controller（避免在 StatefulBuilder.builder 中重复创建，丢失焦点）
    final _tc = existingCard?['totalCount'] as int?;
    final _rc = existingCard?['remainingCount'] as int?;
    final totalCountCtrl = TextEditingController(
      text: (_tc != null && _tc > 0) ? _tc.toString() : '',
    );
    final remainingCountCtrl = TextEditingController(
      text: (_rc != null && _rc >= 0) ? _rc.toString() : '',
    );

    String cardType = existingCard?['cardType'] as String? ?? '年卡';
    int startDate = existingCard?['startDate'] as int? ?? 0;
    int endDate = existingCard?['endDate'] as int? ?? 0;
    int remainingCount = existingCard?['remainingCount'] as int? ?? -1;
    int totalCount = existingCard?['totalCount'] as int? ?? -1;

    void disposeControllers() {
      nameCtrl.dispose();
      gymNameCtrl.dispose();
      priceCtrl.dispose();
      phoneCtrl.dispose();
      remarkCtrl.dispose();
      totalCountCtrl.dispose();
      remainingCountCtrl.dispose();
    }

    FitBottomSheet.show(
      context: context,
      maxHeightRatio: 0.9,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? '编辑健身卡' : '添加健身卡',
                    style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  FitTextField(
                    controller: nameCtrl,
                    label: '卡名称 *',
                    hint: '如：金吉鸟年卡',
                  ),
                  const SizedBox(height: 12),
                  FitTextField(
                    controller: gymNameCtrl,
                    label: '健身房名称',
                    hint: '如：金吉鸟健身(万达店)',
                  ),
                  const SizedBox(height: 12),
                  Text('卡类型', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  FitChipSelector(
                    options: const ['年卡', '季卡', '月卡', '次卡', '其他'],
                    selected: cardType,
                    onChanged: (v) => setSheetState(() => cardType = v),
                  ),
                  const SizedBox(height: 12),
                  FitTextField(
                    controller: priceCtrl,
                    label: '价格 (元)',
                    hint: '0',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  // 开卡日期
                  Text('开卡日期', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: startDate > 0 ? DateTime.fromMillisecondsSinceEpoch(startDate) : DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setSheetState(() => startDate = picked.millisecondsSinceEpoch);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.bgElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.borderColor),
                      ),
                      child: Text(
                        startDate > 0 ? _formatDate(startDate) : '选择日期',
                        style: TextStyle(
                          color: startDate > 0 ? colors.textPrimary : colors.textMuted,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 到期日期（非次卡显示）
                  if (cardType != '次卡') ...[
                    Text('到期日期', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: endDate > 0 ? DateTime.fromMillisecondsSinceEpoch(endDate) : DateTime.now().add(const Duration(days: 365)),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setSheetState(() => endDate = picked.millisecondsSinceEpoch);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: colors.bgElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colors.borderColor),
                        ),
                        child: Text(
                          endDate > 0 ? _formatDate(endDate) : '选择日期',
                          style: TextStyle(
                            color: endDate > 0 ? colors.textPrimary : colors.textMuted,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // 次卡：总次数和剩余次数
                  if (cardType == '次卡') ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('总次数', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: totalCountCtrl,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: colors.textPrimary, fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: '如：30',
                                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                                  filled: true,
                                  fillColor: colors.bgElevated,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: colors.borderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: colors.borderColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: colors.accentGlow, width: 1.5),
                                  ),
                                  counterText: '',
                                ),
                                onChanged: (v) => totalCount = int.tryParse(v) ?? -1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('剩余次数', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: remainingCountCtrl,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: colors.textPrimary, fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: '如：15',
                                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                                  filled: true,
                                  fillColor: colors.bgElevated,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: colors.borderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: colors.borderColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: colors.accentGlow, width: 1.5),
                                  ),
                                  counterText: '',
                                ),
                                onChanged: (v) => remainingCount = int.tryParse(v) ?? -1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  FitTextField(
                    controller: phoneCtrl,
                    label: '联系电话',
                    hint: '健身房联系电话',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  FitTextField(
                    controller: remarkCtrl,
                    label: '备注',
                    hint: '其他备注信息',
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameCtrl.text.trim().isEmpty) {
                          FitToast.warning(context, '请输入卡名称');
                          return;
                        }
                        final data = <String, dynamic>{
                          'name': nameCtrl.text.trim(),
                          'gymName': gymNameCtrl.text.trim(),
                          'cardType': cardType,
                          'price': double.tryParse(priceCtrl.text) ?? 0,
                          'startDate': startDate,
                          'endDate': endDate,
                          'remainingCount': remainingCount,
                          'totalCount': totalCount,
                          'phone': phoneCtrl.text.trim(),
                          'remark': remarkCtrl.text.trim(),
                        };
                        if (isEdit) {
                          Storage.updateGymCard(existingCard['id'] as String, data);
                          FitToast.success(context, '修改成功');
                        } else {
                          Storage.addGymCard(data);
                          FitToast.success(context, '添加成功');
                        }
                        Navigator.of(ctx).pop();
                        _loadCards();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accentGlow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(isEdit ? '保存修改' : '添加', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(disposeControllers);
  }

  void _showCardDetail(Map<String, dynamic> card) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final statusInfo = _getCardStatus(card);
    final dailyCost = _calcDailyCost(card);
    final progress = _calcProgress(card);
    final cardType = card['cardType'] as String? ?? '';
    final remainingCount = card['remainingCount'] as int? ?? -1;
    final totalCount = card['totalCount'] as int? ?? -1;
    final price = (card['price'] as num?)?.toDouble() ?? 0;

    FitBottomSheet.show(
      context: context,
      maxHeightRatio: 0.75,
      builder: (ctx) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Row(
                children: [
                  Expanded(
                    child: Text(
                      card['name'] as String? ?? '',
                      style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  BadgeWidget(
                    text: statusInfo['label'] as String,
                    variant: _statusToBadgeVariant(statusInfo['status'] as String),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if ((card['gymName'] as String? ?? '').isNotEmpty)
                Text(
                  card['gymName'] as String,
                  style: TextStyle(color: colors.textSecondary, fontSize: 14),
                ),
              const SizedBox(height: 16),

              // 状态提示
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (statusInfo['color'] as Color).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (statusInfo['color'] as Color).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(statusInfo['icon'] as IconData, color: statusInfo['color'] as Color, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        statusInfo['tip'] as String,
                        style: TextStyle(
                          color: statusInfo['color'] as Color,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 进度条
              if (progress > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cardType == '次卡' ? '使用进度' : '有效期进度',
                      style: TextStyle(color: colors.textSecondary, fontSize: 13),
                    ),
                    Text(
                      cardType == '次卡'
                          ? '${totalCount > 0 ? totalCount - (remainingCount >= 0 ? remainingCount : 0) : 0}/${totalCount > 0 ? totalCount : 0}次'
                          : '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ProgressBar(
                  progress: progress,
                  fillColor: _getProgressColor(statusInfo['status'] as String, colors),
                ),
                const SizedBox(height: 16),
              ],

              // 详细信息
              _buildDetailRow(colors, Icons.card_membership_outlined, '卡类型', cardType),
              if (price > 0) ...[
                _buildDetailRow(colors, Icons.payments_outlined, '价格', '¥${price.toStringAsFixed(0)}'),
                _buildDetailRow(colors, Icons.calculate_outlined, '日均费用', dailyCost),
              ],
              if (card['startDate'] != null && (card['startDate'] as int) > 0)
                _buildDetailRow(colors, Icons.play_circle_outline, '开卡日期', _formatDate(card['startDate'] as int)),
              if (cardType != '次卡' && card['endDate'] != null && (card['endDate'] as int) > 0)
                _buildDetailRow(colors, Icons.event_outlined, '到期日期', _formatDate(card['endDate'] as int)),
              if (cardType == '次卡') ...[
                if (totalCount > 0)
                  _buildDetailRow(colors, Icons.format_list_numbered, '总次数', '$totalCount 次'),
                if (remainingCount >= 0)
                  _buildDetailRow(colors, Icons.filter_9_plus_outlined, '剩余次数', '$remainingCount 次'),
              ],
              if ((card['phone'] as String? ?? '').isNotEmpty)
                _buildDetailRow(colors, Icons.phone_outlined, '联系电话', card['phone'] as String),
              if ((card['remark'] as String? ?? '').isNotEmpty)
                _buildDetailRow(colors, Icons.note_outlined, '备注', card['remark'] as String),

              const SizedBox(height: 20),
              // 操作按钮
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _confirmDelete(card);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colors.warningColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('删除', style: TextStyle(color: colors.warningColor, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _showAddCardSheet(existingCard: card);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accentGlow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('编辑', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 次卡扣减次数
  void _useOneCount(Map<String, dynamic> card) {
    final remaining = card['remainingCount'] as int? ?? -1;
    if (remaining <= 0) {
      FitToast.warning(context, '次数已用完');
      return;
    }
    Storage.updateGymCard(card['id'] as String, {'remainingCount': remaining - 1});
    FitToast.success(context, '已扣减1次，剩余 ${remaining - 1} 次');
    _loadCards();
  }

  /// 海报分享：通过 [Overlay] 离屏渲染 [GymCardPoster]，
  /// 用 [PosterGenerator.capture] 截图，最后弹出 [PosterPreviewDialog]。
  ///
  /// 参考 Task 2 invitation_page._shareCode 的实现模式。
  Future<void> _shareCardPoster(Map<String, dynamic> card) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundaryKey = GlobalKey();
      final overlay = Overlay.of(context);
      const posterWidth = GymCardPoster.posterWidth;
      const posterHeight = GymCardPoster.posterHeight;

      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => Positioned(
          left: -posterWidth,
          top: -posterHeight,
          width: posterWidth,
          height: posterHeight,
          child: Material(
            color: Colors.transparent,
            child: OverflowBox(
              minWidth: posterWidth,
              maxWidth: posterWidth,
              minHeight: posterHeight,
              maxHeight: posterHeight,
              child: RepaintBoundary(
                key: boundaryKey,
                child: GymCardPoster(card: card),
              ),
            ),
          ),
        ),
      );
      overlay.insert(entry);

      // 等待多帧，确保 layout + paint 完成
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 30));
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 30));

      try {
        final imagePath = await PosterGenerator.capture(
          boundaryKey,
          fileNamePrefix: 'fittrack_gym_card',
        );
        entry.remove();
        if (!mounted) return;
        await PosterPreviewDialog.show(
          context,
          imagePath: imagePath,
          title: '健身卡海报',
        );
      } catch (e) {
        entry.remove();
        if (!mounted) return;
        FitToast.error(context, '海报生成失败：$e');
      }
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
      }
    }
  }

  void _confirmDelete(Map<String, dynamic> card) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: '删除健身卡',
      content: '确定要删除「${card['name']}」吗？删除后无法恢复。',
      confirmText: '删除',
      confirmColor: Colors.red,
      icon: Icons.delete_outline,
    );
    if (confirmed == true && mounted) {
      Storage.deleteGymCard(card['id'] as String);
      FitToast.success(context, '已删除');
      _loadCards();
    }
  }

  BadgeVariant _statusToBadgeVariant(String status) {
    switch (status) {
      case 'active':
      case 'normal':
        return BadgeVariant.success;
      case 'expiring_soon':
      case 'low_count':
        return BadgeVariant.accent;
      case 'expired':
      case 'expiring_today':
        return BadgeVariant.info;
      case 'used_up':
        return BadgeVariant.purple;
      default:
        return BadgeVariant.accent;
    }
  }

  Color _getProgressColor(String status, FitTrackColors colors) {
    switch (status) {
      case 'expired':
      case 'expiring_today':
        return Colors.red;
      case 'expiring_soon':
      case 'low_count':
        return Colors.orange;
      default:
        return colors.accentGlow;
    }
  }

  Widget _buildDetailRow(FitTrackColors colors, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.textMuted),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const Spacer(),
          Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    // 统计即将到期/过期的卡片数量
    int alertCount = 0;
    for (final card in _cards) {
      final status = _getCardStatus(card)['status'] as String;
      if (['expired', 'expiring_today', 'expiring_soon', 'low_count', 'used_up'].contains(status)) {
        alertCount++;
      }
    }

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            title: '健身卡',
            subtitle: '管理你的健身卡信息',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: _cards.isEmpty
                ? _buildEmptyState(colors)
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 提醒横幅
                        if (alertCount > 0) ...[
                          _buildAlertBanner(colors, alertCount),
                          const SizedBox(height: 16),
                        ],
                        // 卡片列表
                        ..._cards.map((card) => _buildCardItem(colors, card)),
                        const SizedBox(height: 16),
                        // 添加按钮
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _showAddCardSheet(),
                            icon: Icon(Icons.add, color: colors.accentGlow),
                            label: Text('添加健身卡', style: TextStyle(color: colors.accentGlow, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: colors.accentGlow.withOpacity(0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner(FitTrackColors colors, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.warningColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.warningColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active_outlined, color: colors.warningColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '你有 $count 张健身卡需要关注',
              style: TextStyle(color: colors.warningColor, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(FitTrackColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.card_membership_outlined, size: 64, color: colors.textMuted),
          const SizedBox(height: 16),
          Text('还没有健身卡', style: TextStyle(color: colors.textMuted, fontSize: 16)),
          const SizedBox(height: 8),
          Text('添加你的健身卡，随时查看到期提醒', style: TextStyle(color: colors.textMuted, fontSize: 13)),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: ElevatedButton.icon(
              onPressed: () => _showAddCardSheet(),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('添加健身卡', style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentGlow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem(FitTrackColors colors, Map<String, dynamic> card) {
    final statusInfo = _getCardStatus(card);
    final progress = _calcProgress(card);
    final dailyCost = _calcDailyCost(card);
    final cardType = card['cardType'] as String? ?? '';
    final remainingCount = card['remainingCount'] as int? ?? -1;
    final gymName = card['gymName'] as String? ?? '';
    final price = (card['price'] as num?)?.toDouble() ?? 0;

    return GestureDetector(
      onTap: () => _showCardDetail(card),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _shouldHighlight(statusInfo['status'] as String)
                ? (statusInfo['color'] as Color).withOpacity(0.3)
                : colors.borderColor,
            width: _shouldHighlight(statusInfo['status'] as String) ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 第一行：名称 + 分享按钮 + 状态标签
            Row(
              children: [
                Expanded(
                  child: Text(
                    card['name'] as String? ?? '',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _sharing ? null : () => _shareCardPoster(card),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Icon(Icons.share_outlined,
                        size: 16, color: colors.textMuted),
                  ),
                ),
                BadgeWidget(
                  text: statusInfo['label'] as String,
                  variant: _statusToBadgeVariant(statusInfo['status'] as String),
                ),
              ],
            ),
            // 第二行：健身房名称
            if (gymName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(gymName, style: TextStyle(color: colors.textMuted, fontSize: 13)),
            ],
            const SizedBox(height: 12),
            // 第三行：关键信息
            Row(
              children: [
                _buildInfoChip(colors, Icons.card_membership_outlined, cardType),
                const SizedBox(width: 12),
                if (price > 0)
                  _buildInfoChip(colors, Icons.payments_outlined, '¥${price.toStringAsFixed(0)}'),
                if (price > 0) const SizedBox(width: 12),
                if (dailyCost != '--')
                  _buildInfoChip(colors, Icons.calculate_outlined, dailyCost),
              ],
            ),
            const SizedBox(height: 10),
            // 进度条
            if (progress > 0) ...[
              ProgressBar(
                progress: progress,
                fillColor: _getProgressColor(statusInfo['status'] as String, colors),
              ),
              const SizedBox(height: 6),
            ],
            // 提示信息
            Text(
              statusInfo['tip'] as String,
              style: TextStyle(
                color: statusInfo['color'] as Color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            // 次卡扣减按钮
            if (cardType == '次卡' && remainingCount > 0) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _useOneCount(card),
                  icon: Icon(Icons.remove_circle_outline, size: 18, color: colors.accentGlow),
                  label: Text('使用1次 (剩余$remainingCount次)', style: TextStyle(color: colors.accentGlow, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.accentGlow.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _shouldHighlight(String status) {
    return ['expired', 'expiring_today', 'expiring_soon', 'low_count', 'used_up'].contains(status);
  }

  Widget _buildInfoChip(FitTrackColors colors, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.textMuted),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
