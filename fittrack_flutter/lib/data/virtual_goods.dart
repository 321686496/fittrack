import 'dart:convert';
import 'storage.dart';

/// 虚拟物品类别
enum GoodCategory {
  opponentSkin, // 对手皮肤
  badge,        // 徽章
  avatarFrame,  // 头像框
  title,        // 称号
}

/// 虚拟物品数据模型
class VirtualGood {
  final String id;
  final String name;
  final GoodCategory category;
  final int pointsCost;
  final String emoji;
  final String? unlockCondition; // 非空表示不可纯积分购买（需通过里程碑解锁）
  final bool isLimited;
  final Map<String, dynamic>? metadata;

  const VirtualGood({
    required this.id,
    required this.name,
    required this.category,
    required this.pointsCost,
    required this.emoji,
    this.unlockCondition,
    this.isLimited = false,
    this.metadata,
  });

  /// 是否可纯积分购买（false 表示需通过里程碑解锁）
  bool get isPurchasableWithPoints => unlockCondition == null;
}

/// 虚拟物品价格表与查询
class VirtualGoodsStore {
  VirtualGoodsStore._();

  /// 全部商品清单
  static const List<VirtualGood> kAllGoods = [
    // ── 对手皮肤 ──
    VirtualGood(
      id: 'skin_beginner',
      name: '健身小白',
      category: GoodCategory.opponentSkin,
      pointsCost: 100,
      emoji: '🐣',
    ),
    VirtualGood(
      id: 'skin_iron_warrior',
      name: '钢铁战士',
      category: GoodCategory.opponentSkin,
      pointsCost: 300,
      emoji: '🤖',
    ),
    VirtualGood(
      id: 'skin_cyber_ninja',
      name: '赛博忍者',
      category: GoodCategory.opponentSkin,
      pointsCost: 600,
      emoji: '🥷',
    ),
    VirtualGood(
      id: 'skin_ambassador',
      name: '燃力大使',
      category: GoodCategory.opponentSkin,
      pointsCost: 1200,
      emoji: '👑',
      unlockCondition: '累计邀请 5 人',
      isLimited: true,
    ),
    // ── 徽章 ──
    VirtualGood(
      id: 'badge_standard',
      name: '标准徽章',
      category: GoodCategory.badge,
      pointsCost: 300,
      emoji: '🏅',
    ),
    // ── 头像框 ──
    VirtualGood(
      id: 'frame_basic',
      name: '基础头像框',
      category: GoodCategory.avatarFrame,
      pointsCost: 100,
      emoji: '🖼️',
    ),
    VirtualGood(
      id: 'frame_premium',
      name: '精品头像框',
      category: GoodCategory.avatarFrame,
      pointsCost: 600,
      emoji: '🖼️',
    ),
    // ── 称号 ──
    VirtualGood(
      id: 'title_ambassador',
      name: '燃力大使称号',
      category: GoodCategory.title,
      pointsCost: 1200,
      emoji: '🎖️',
      unlockCondition: '累计邀请 10 人',
      isLimited: true,
    ),
  ];

  /// 按 id 查询
  static VirtualGood? byId(String id) {
    for (final g in kAllGoods) {
      if (g.id == id) return g;
    }
    return null;
  }

  /// 按类别查询
  static List<VirtualGood> byCategory(GoodCategory c) {
    return kAllGoods.where((g) => g.category == c).toList();
  }

  /// 查询当前积分可负担的商品（限定款/里程碑款排除）
  static List<VirtualGood> affordableWith(int points) {
    return kAllGoods.where((g) {
      if (!g.isPurchasableWithPoints) return false;
      return g.pointsCost <= points;
    }).toList();
  }

  /// 查询物品是否已解锁
  /// key 约定：`good_<id>`（如 `good_skin_iron_warrior`）
  static bool isUnlocked(String goodId) {
    final settings = Storage.getSettings();
    final raw = settings['unlockedFeatures'] as String? ?? '[]';
    try {
      final list = (jsonDecode(raw) as List).cast<String>();
      return list.contains('good_$goodId');
    } catch (_) {
      return false;
    }
  }

  /// 解锁物品（积分购买）—— 仅可购买 isPurchasableWithPoints=true 的物品
  /// 返回是否解锁成功（积分不足或不可购买时返回 false）
  static Future<bool> unlock(String goodId) async {
    final good = byId(goodId);
    if (good == null || !good.isPurchasableWithPoints) return false;
    if (isUnlocked(goodId)) return true;

    final settings = Storage.getSettings();
    final current = settings['points'] as int? ?? 0;
    if (current < good.pointsCost) return false;

    // 扣减积分
    settings['points'] = current - good.pointsCost;
    final spent = settings['pointsSpentTotal'] as int? ?? 0;
    settings['pointsSpentTotal'] = spent + good.pointsCost;

    // 写入解锁列表
    final raw = settings['unlockedFeatures'] as String? ?? '[]';
    final list = (jsonDecode(raw) as List).cast<String>();
    list.add('good_$goodId');
    settings['unlockedFeatures'] = jsonEncode(list);

    // 写入积分日志
    final logRaw = settings['pointsLog'] as String? ?? '[]';
    final logs = (jsonDecode(logRaw) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    logs.insert(0, {
      'time': DateTime.now().millisecondsSinceEpoch,
      'delta': -good.pointsCost,
      'source': 'unlock_good_$goodId',
      'balance': current - good.pointsCost,
    });
    if (logs.length > 50) logs.removeRange(50, logs.length);
    settings['pointsLog'] = jsonEncode(logs);

    Storage.saveSettings(settings);
    Storage.dataChanged.value = !Storage.dataChanged.value;
    return true;
  }
}
