import '../invite_url_service.dart';

class OhosInviteUrlService implements InviteUrlService {
  @override
  Future<void> registerHandler(Future<void> Function(Uri uri) handler) async {}

  @override
  Future<void> launchInviteUrl(Uri uri) async {}
}
