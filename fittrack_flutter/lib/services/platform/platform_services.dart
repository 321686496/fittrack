import 'dart:io';
import '../../utils/platform_utils.dart';
import 'rest_reminder_service.dart';
import 'live_view_service.dart';
import 'widget_card_service.dart';
import 'invite_url_service.dart';
import 'noop_platform_services.dart';
import 'implementations/ohos_rest_reminder_service.dart';
import 'implementations/ohos_live_view_service.dart';
import 'implementations/ohos_widget_card_service.dart';
import 'implementations/ohos_invite_url_service.dart';
import 'implementations/android_rest_reminder_service.dart';
import 'implementations/android_invite_url_service.dart';
import 'implementations/ios_rest_reminder_service.dart';
import 'implementations/ios_invite_url_service.dart';

class PlatformServices {
  static late final RestReminderService restReminder;
  static late final LiveViewService liveView;
  static late final WidgetCardService widgetCard;
  static late final InviteUrlService inviteUrl;

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    if (isOhos) {
      restReminder = OhosRestReminderService();
      liveView = OhosLiveViewService();
      widgetCard = OhosWidgetCardService();
      inviteUrl = OhosInviteUrlService();
    } else if (Platform.isAndroid) {
      restReminder = AndroidRestReminderService();
      liveView = NoopLiveViewService();
      widgetCard = NoopWidgetCardService();
      inviteUrl = AndroidInviteUrlService();
    } else if (Platform.isIOS) {
      restReminder = IosRestReminderService();
      // iOSLiveViewService / IosWidgetCardService 在 Batch 3 创建
      liveView = NoopLiveViewService();
      widgetCard = NoopWidgetCardService();
      inviteUrl = IosInviteUrlService();
    } else {
      restReminder = NoopRestReminderService();
      liveView = NoopLiveViewService();
      widgetCard = NoopWidgetCardService();
      inviteUrl = NoopInviteUrlService();
    }

    await restReminder.init();
    await widgetCard.init();

    _initialized = true;
  }

  static OhosLiveViewService? get ohosLiveView =>
      liveView is OhosLiveViewService ? liveView as OhosLiveViewService : null;

  static OhosWidgetCardService? get ohosWidgetCard =>
      widgetCard is OhosWidgetCardService
          ? widgetCard as OhosWidgetCardService
          : null;
}
