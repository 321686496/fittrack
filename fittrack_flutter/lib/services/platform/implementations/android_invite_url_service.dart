import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../invite_url_service.dart';

class AndroidInviteUrlService implements InviteUrlService {
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
          debugPrint('[AndroidInvite] handler error: $e');
        }
      }
    });
  }

  @override
  Future<void> launchInviteUrl(Uri uri) async {}
}
