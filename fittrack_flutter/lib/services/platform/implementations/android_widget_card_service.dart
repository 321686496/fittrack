import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../widget_card_service.dart';

/// Android 桌面卡片服务（Glance AppWidget）
class AndroidWidgetCardService implements WidgetCardService {
  static const _channel = MethodChannel('com.fp.fitplan/widget');

  final StreamController<WidgetCardClickEvent> _clickController =
      StreamController<WidgetCardClickEvent>.broadcast();

  @override
  Future<void> init() async {
    // 首次启动时推送一次空闲态数据
    await pushCardData(const WidgetCardData(mode: WidgetCardMode.idle));
  }

  @override
  Future<void> pushCardData(WidgetCardData data) async {
    try {
      final jsonStr = jsonEncode(data.toJson());
      await _channel.invokeMethod<bool>('pushCardData', jsonStr);
    } catch (e) {
      debugPrint('[AndroidWidgetCard] pushCardData error: $e');
    }
  }

  @override
  Future<void> clearCardData() async {
    try {
      await _channel.invokeMethod<bool>('clearCardData');
    } catch (e) {
      debugPrint('[AndroidWidgetCard] clearCardData error: $e');
    }
  }

  @override
  Stream<WidgetCardClickEvent> get onCardClick => _clickController.stream;
}
