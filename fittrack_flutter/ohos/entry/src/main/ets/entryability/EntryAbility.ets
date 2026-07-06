import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import MethodChannel from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { MethodCallHandler, MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import MethodCall from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodCall';
import StandardMethodCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMethodCodec';
import { formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { preferences } from '@kit.ArkData';
import { Want, AbilityConstant } from '@kit.AbilityKit';

const PREFERENCES_NAME: string = 'fittrack_form_data';
const KEY_FORM_DATA: string = 'form_data';
const FORM_CHANNEL_NAME: string = 'com.example.fittrack_flutter/form';
const REMINDER_CHANNEL_NAME: string = 'com.example.fittrack_flutter/reminder';

class FormDataCallHandler implements MethodCallHandler {
  private ability: EntryAbility;

  constructor(ability: EntryAbility) {
    this.ability = ability;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method === 'updateFormData') {
      this.ability.updateFormData(call, result);
    } else {
      result.notImplemented();
    }
  }
}

export default class EntryAbility extends FlutterAbility {
  private formChannel: MethodChannel | null = null;
  private reminderChannel: MethodChannel | null = null;

  // 倒计时定时器：主进程每 3 秒调用 reloadForms 触发卡片刷新生效
  // 区别于 formProvider.updateForm（10 次/分钟限制），reloadForms 无此限制
  private countdownTimerId: number = -1;

  configureFlutterEngine(flutterEngine: FlutterEngine): void {
    super.configureFlutterEngine(flutterEngine);
    GeneratedPluginRegistrant.registerWith(flutterEngine);

    // 注册卡片数据 MethodChannel
    this.formChannel = new MethodChannel(
      flutterEngine.getDartExecutor().getBinaryMessenger(),
      FORM_CHANNEL_NAME,
      StandardMethodCodec.INSTANCE
    );
    this.formChannel.setMethodCallHandler(new FormDataCallHandler(this));

    // 注册提醒/卡片交互 MethodChannel（用于卡片点击回调到 Flutter）
    this.reminderChannel = new MethodChannel(
      flutterEngine.getDartExecutor().getBinaryMessenger(),
      REMINDER_CHANNEL_NAME,
      StandardMethodCodec.INSTANCE
    );
  }

  /**
   * 卡片点击通过 router postCardAction 触发 onNewWant，
   * 从中提取 cardAction 参数并通过 MethodChannel 回调到 Flutter。
   */
  onNewWant(want: Want, launchParams: AbilityConstant.LaunchParam): void {
    super.onNewWant(want, launchParams);
    try {
      let params: Record<string, Object> = want.parameters as Record<string, Object>;
      if (params !== null && params !== undefined) {
        let targetPage: string = this.getStringParam(params, 'targetPage');
        let cardAction: string = this.getStringParam(params, 'cardAction');
        console.info('[FitTrack] onNewWant: targetPage=' + targetPage + ', cardAction=' + cardAction);

        if (cardAction === 'skipRest' || cardAction === 'resume') {
          this.invokeFlutterMethod('onCardClick', params);
        }
      }
    } catch (e) {
      console.error('[FitTrack] onNewWant error: ' + e);
    }
  }

  private invokeFlutterMethod(method: string, args: Record<string, Object>): void {
    if (this.reminderChannel !== null) {
      try {
        let jsonStr: string = JSON.stringify(args);
        this.reminderChannel.invokeMethod(method, jsonStr);
        console.info('[FitTrack] invokeFlutterMethod: ' + method + ' success');
      } catch (e) {
        console.error('[FitTrack] invokeFlutterMethod error: ' + e);
      }
    }
  }

  private getStringParam(params: Record<string, Object>, key: string): string {
    let val: Object = params[key];
    if (val !== undefined && val !== null) {
      return val.toString();
    }
    return '';
  }

  /**
   * 更新卡片数据
   * 等待 reloadForms 完成后才返回，确保 Flutter 侧串行化队列正确工作
   * 同时根据 mode 管理倒计时定时器的起停
   */
  updateFormData(call: MethodCall, result: MethodResult): void {
    try {
      const dataStr: string = call.args as string;

      let prefs: preferences.Preferences = preferences.getPreferencesSync(this.context, { name: PREFERENCES_NAME });
      prefs.putSync(KEY_FORM_DATA, dataStr);
      prefs.flushSync();

      console.info(`[FitTrack] FormData saved to preferences: ${dataStr}`);

      // 根据 mode 管理倒计时定时器
      this.manageCountdownTimer(dataStr);

      formProvider.reloadForms(this.context, 'entry', 'FitTrackFormExtension', 'FitTrack训练卡片')
        .then((reloadNum: number) => {
          console.info(`[FitTrack] reloadForms success, reload number: ${reloadNum}`);
          result.success(`reloadNum=${reloadNum}`);
        })
        .catch((err: BusinessError) => {
          console.error(`[FitTrack] reloadForms failed: ${err.code} - ${err.message}`);
          result.success(`reloadForms_error code=${err.code} msg=${err.message}`);
        });
    } catch (e) {
      console.error(`[FitTrack] updateFormData exception: ${e}`);
      result.error('EXCEPTION', `${e}`, null);
    }
  }

  /**
   * 从推送的 JSON 中解析 mode，决定是否启动倒计时定时器。
   * rest 态时：每 3 秒调用一次 reloadForms，触发 FormExtension.onUpdateForm，
   * 其返回值由系统自动刷到卡片 UI——不调用 formProvider.updateForm，
   * 因此不触发 10 次/分钟的限制。
   */
  private manageCountdownTimer(dataStr: string): void {
    try {
      const parsed: Record<string, Object> = JSON.parse(dataStr) as Record<string, Object>;
      const mode: string = (parsed['mode'] as string) ?? '';
      if (mode === 'rest') {
        this.startCountdownTimer();
      } else {
        this.stopCountdownTimer();
      }
    } catch (e) {
      this.stopCountdownTimer();
    }
  }

  private startCountdownTimer(): void {
    if (this.countdownTimerId !== -1) return;
    console.info('[FitTrack] startCountdownTimer');
    this.countdownTimerId = setInterval(() => {
      formProvider.reloadForms(this.context, 'entry', 'FitTrackFormExtension', 'FitTrack训练卡片')
        .then((reloadNum: number) => {
          console.info(`[FitTrack] countdown reloadForms success, reloadNum=${reloadNum}`);
        })
        .catch((err: BusinessError) => {
          console.error(`[FitTrack] countdown reloadForms failed: ${err.code} - ${err.message}`);
        });
    }, 1000);
  }

  private stopCountdownTimer(): void {
    if (this.countdownTimerId !== -1) {
      console.info('[FitTrack] stopCountdownTimer');
      clearInterval(this.countdownTimerId);
      this.countdownTimerId = -1;
    }
  }
}
