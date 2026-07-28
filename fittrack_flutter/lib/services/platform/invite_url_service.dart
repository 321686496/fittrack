import 'dart:async';

abstract class InviteUrlService {
  Future<void> registerHandler(Future<void> Function(Uri uri) handler);
  Future<void> launchInviteUrl(Uri uri);
}
