import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../invite_url_service.dart';

/// iOS 邀请链接服务（通过 CFBundleURLTypes 处理 fittrack:// URL）
class IosInviteUrlService implements InviteUrlService {
  static const _channel = MethodChannel('com.fp.fitplan/invite');

  Future<void> Function(Uri)? _handler;

  @override
  Future<void> registerHandler(Future<void> Function(Uri uri) handler) async {
    _handler = handler;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onInviteUrl') {
        final url = call.arguments as String;
        try {
          await _handler?.call(Uri.parse(url));
        } catch (e) {
          debugPrint('[IosInvite] handler error: $e');
        }
      }
    });
  }

  @override
  Future<void> launchInviteUrl(Uri uri) async {
    try {
      await _channel.invokeMethod<bool>('launchInviteUrl', uri.toString());
    } catch (e) {
      debugPrint('[IosInvite] launchInviteUrl error: $e');
    }
  }
}
