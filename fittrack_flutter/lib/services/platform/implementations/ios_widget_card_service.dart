// fittrack_flutter/lib/services/platform/implementations/ios_widget_card_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../widget_card_service.dart';

/// iOS 桌面卡片服务（通过 WidgetKit + App Group UserDefaults）
class IosWidgetCardService implements WidgetCardService {
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
      debugPrint('[IosWidgetCard] pushCardData error: $e');
    }
  }

  @override
  Future<void> clearCardData() async {
    try {
      await _channel.invokeMethod<bool>('clearCardData');
    } catch (e) {
      debugPrint('[IosWidgetCard] clearCardData error: $e');
    }
  }

  @override
  Stream<WidgetCardClickEvent> get onCardClick => _clickController.stream;
}
