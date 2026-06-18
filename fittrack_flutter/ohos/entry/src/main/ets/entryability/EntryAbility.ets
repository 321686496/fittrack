import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import MethodChannel from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { MethodCallHandler, MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import MethodCall from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodCall';
import StandardMethodCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMethodCodec';
import { formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { preferences } from '@kit.ArkData';
import { Want } from '@kit.AbilityKit';

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
  onNewWant(want: Want): void {
    super.onNewWant(want);
    try {
      let params: Record<string, Object> = want.parameters as Record<string, Object>;
      if (params !== null && params !== undefined) {
        let targetPage: string = this.getStringParam(params, 'targetPage');
        let cardAction: string = this.getStringParam(params, 'cardAction');
        console.info('[FitTrack] onNewWant: targetPage=' + targetPage + ', cardAction=' + cardAction);

        if (cardAction === 'skipRest' || cardAction === 'resume') {
          // 卡片训练交互：通知 Flutter 处理
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
   */
  updateFormData(call: MethodCall, result: MethodResult): void {
    try {
      const dataStr: string = call.args as string;

      let prefs: preferences.Preferences = preferences.getPreferencesSync(this.context, { name: PREFERENCES_NAME });
      prefs.putSync(KEY_FORM_DATA, dataStr);
      prefs.flushSync();

      console.info(`[FitTrack] FormData saved to preferences: ${dataStr}`);

      this.reloadAllForms();

      result.success(true);
    } catch (e) {
      console.error(`[FitTrack] updateFormData exception: ${e}`);
      result.error('EXCEPTION', `${e}`, null);
    }
  }

  private reloadAllForms(): void {
    try {
      formProvider.reloadForms(this.context, 'entry', 'FitTrackFormExtension', 'FitTrack训练卡片').then((reloadNum: number) => {
        console.info(`[FitTrack] reloadForms success, reload number: ${reloadNum}`);
      }).catch((err: BusinessError) => {
        console.error(`[FitTrack] reloadForms failed: ${err.code} - ${err.message}`);
      });
    } catch (e) {
      console.error(`[FitTrack] reloadForms exception: ${e}`);
    }
  }
}
