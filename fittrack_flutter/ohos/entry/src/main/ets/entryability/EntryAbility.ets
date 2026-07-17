import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import MethodChannel from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { MethodCallHandler, MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import MethodCall from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodCall';
import StandardMethodCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMethodCodec';
import { formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { preferences } from '@kit.ArkData';
import { Want, AbilityConstant, wantAgent, WantAgent, bundleManager } from '@kit.AbilityKit';
import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { liveViewManager } from '@kit.LiveViewKit';
import { notificationManager } from '@kit.NotificationKit';

const PREFERENCES_NAME: string = 'fittrack_form_data';
const KEY_FORM_DATA: string = 'form_data';
const FORM_CHANNEL_NAME: string = 'com.fp.fitplan/form';
const REMINDER_CHANNEL_NAME: string = 'com.fp.fitplan/reminder';
const REST_LIVE_VIEW_ID: number = 30001;

const CAPSULE_ICON: string = 'liveview_icon.png';

class FormDataCallHandler implements MethodCallHandler {
  private ability: EntryAbility;

  constructor(ability: EntryAbility) {
    this.ability = ability;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method === 'updateFormData') {
      this.ability.updateFormData(call, result);
    } else if (call.method === 'getFormData') {
      let prefs: preferences.Preferences = preferences.getPreferencesSync(this.ability.context, { name: PREFERENCES_NAME });
      let data: string = prefs.getSync(KEY_FORM_DATA, '') as string;
      result.success(data);
    } else {
      result.notImplemented();
    }
  }
}

export default class EntryAbility extends FlutterAbility {
  private formChannel: MethodChannel | null = null;
  private reminderChannel: MethodChannel | null = null;

  private restEndTime: number = 0;
  private totalRestSeconds: number = 0;
  private currentExerciseName: string = '';
  private liveViewSequence: number = 0;
  private liveViewWantAgent: WantAgent | null = null;
  private currentReminderId: number = -1;
  private liveViewActive: boolean = false;

  configureFlutterEngine(flutterEngine: FlutterEngine): void {
    super.configureFlutterEngine(flutterEngine);
    GeneratedPluginRegistrant.registerWith(flutterEngine);

    this.formChannel = new MethodChannel(
      flutterEngine.getDartExecutor().getBinaryMessenger(),
      FORM_CHANNEL_NAME,
      StandardMethodCodec.INSTANCE
    );
    this.formChannel.setMethodCallHandler(new FormDataCallHandler(this));

    this.reminderChannel = new MethodChannel(
      flutterEngine.getDartExecutor().getBinaryMessenger(),
      REMINDER_CHANNEL_NAME,
      StandardMethodCodec.INSTANCE
    );
  }

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

  updateFormData(call: MethodCall, result: MethodResult): void {
    try {
      const dataStr: string = call.args as string;

      let prefs: preferences.Preferences = preferences.getPreferencesSync(this.context, { name: PREFERENCES_NAME });
      prefs.putSync(KEY_FORM_DATA, dataStr);
      prefs.flushSync();

      console.info(`[FitTrack] FormData saved: ${dataStr}`);

      this.manageTrainingState(dataStr);

      formProvider.reloadForms(this.context, 'entry', 'FitTrackFormExtension', 'FitTrack训练卡片')
        .then((reloadNum: number) => {
          console.info(`[FitTrack] reloadForms success, reloadNum=${reloadNum}`);
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

  private manageTrainingState(dataStr: string): void {
    try {
      const parsed: Record<string, Object> = JSON.parse(dataStr) as Record<string, Object>;
      const mode: string = (parsed['mode'] as string) ?? 'idle';

      console.info(`[FitTrack] manageTrainingState: mode=${mode}`);

      if (mode === 'rest') {
        const restEndTime: number = Number(parsed['restEndTime'] ?? 0);
        const totalRestSeconds: number = Number(parsed['totalRestSeconds'] ?? 0);
        this.restEndTime = restEndTime;
        this.totalRestSeconds = totalRestSeconds;
        this.currentExerciseName = (parsed['exerciseName'] as string) ?? '';

        // 休息开始：创建实况窗 + 发布代理提醒
        this.startRestLiveView();

        const restSeconds: number = Math.max(1, Math.round((restEndTime - Date.now()) / 1000));
        this.scheduleRestReminder(restSeconds);
      } else {
        // 休息结束（或非休息状态）：停止实况窗 + 取消尚未触发的代理提醒
        // 修复：跳过休息 / 休息自然结束时，必须显式取消已发布的 reminderAgentManager 代理提醒，
        // 否则提醒会一直保留到设定时间触发，弹出"休息时间到"的过期通知。
        // 震动仅在训练结束时由 Flutter 侧 HapticFeedback 触发
        this.stopRestLiveView();
        this.cancelRestReminder();
      }
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      console.error(`[FitTrack] manageTrainingState 异常: code=${err.code}, msg=${err.message}`);
    }
  }

  private async buildLiveViewWantAgent(): Promise<void> {
    try {
      const bundleInfo: bundleManager.BundleInfo =
        bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);

      let wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [{
          bundleName: bundleInfo.name,
          abilityName: 'EntryAbility',
          parameters: { targetPage: 'training', cardAction: 'resume' }
        }],
        actionType: wantAgent.OperationType.START_ABILITY,
        requestCode: 0,
        actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
      };

      this.liveViewWantAgent = await wantAgent.getWantAgent(wantAgentInfo);
      console.info('[FitTrack] buildLiveViewWantAgent success');
    } catch (err) {
      console.error('[FitTrack] buildLiveViewWantAgent failed: ' + err);
    }
  }

  private async startRestLiveView(): Promise<void> {
    try {
      // 校验实况窗开关是否打开
      // 注意：模拟器上可能返回 false，也可能因实况窗权益未申请而无法创建
      let enabled: boolean = true;
      try {
        enabled = await liveViewManager.isLiveViewEnabled();
      } catch (checkErr) {
        const checkError: BusinessError = checkErr as BusinessError;
        console.warn(`[FitTrack] isLiveViewEnabled 调用异常: code=${checkError.code}, msg=${checkError.message}，将继续尝试创建实况窗`);
      }
      if (!enabled) {
        console.warn('[FitTrack] 实况窗开关未开启，无法创建实况窗。可能原因：1) 用户未在设置中开启实况窗开关；2) 模拟器环境限制；3) 实况窗权益未申请');
        return;
      }

      await this.buildLiveViewWantAgent();
      // 如果 wantAgent 创建失败，则无法继续创建实况窗
      if (this.liveViewWantAgent === null) {
        console.error('[FitTrack] liveViewWantAgent 创建失败，无法创建实况窗');
        return;
      }

      // 每次开始休息时重置 sequence 从 1 开始
      this.liveViewSequence = 1;
      const remainingMs: number = Math.max(0, this.restEndTime - Date.now());

      let liveView: liveViewManager.LiveView = {
        id: REST_LIVE_VIEW_ID,
        event: 'TIMER',
        sequence: this.liveViewSequence,
        isMute: false,
        timer: {
          time: remainingMs,
          isCountdown: true,
          isPaused: false,
        },
        liveViewData: {
          primary: {
            title: 'FitTrack - 休息中',
            content: [
              { text: '剩余 ' },
              { text: '${placeholder.timer}', textColor: '#FFFF6B35' },
              { text: ' | ' },
              { text: this.currentExerciseName, textColor: '#FFFF6B35' }
            ],
            keepTime: 1,
            clickAction: this.liveViewWantAgent!,
            layoutData: {
              layoutType: liveViewManager.LayoutType.LAYOUT_TYPE_PICKUP,
              title: '休息倒计时',
              content: '${placeholder.timer}',
              underlineColor: '#FFFF6B35',
              descPic: "liveview_icon.png"
            }
          },
          capsule: {
            type: liveViewManager.CapsuleType.CAPSULE_TYPE_TIMER,
            status: 1,
            icon: CAPSULE_ICON,
            content: '${placeholder.timer}',
            time: remainingMs,
            isCountdown: true,
            isPaused: false,
            backgroundColor: '#FFFF6B35',
          }
        }
      };

      console.info(`[FitTrack] 开始创建实况窗, id=${REST_LIVE_VIEW_ID}, sequence=${this.liveViewSequence}, remainingMs=${remainingMs}`);

      let result: liveViewManager.LiveViewResult = await liveViewManager.startLiveView(liveView);
      this.liveViewActive = true;
      console.info(`[FitTrack] startRestLiveView 成功, result: ${JSON.stringify(result)}`);
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      console.error(`[FitTrack] startRestLiveView 失败: code=${err.code}, msg=${err.message}`);
      // 1003500004: 实况窗开关关闭
      // 1003500005: 实况窗权益未申请（需在 AppGallery Connect 申请）
      // 1003500006: 实况窗已存在（可能未正确停止上一次）
      // 1003500007: 无法连接服务器（模拟器常见）
      if (err.code === 1003500006) {
        // 实况窗已存在：先停止再重试一次
        console.info('[FitTrack] 实况窗已存在，尝试先停止再重新创建');
        this.liveViewActive = true;
        await this.stopRestLiveView();
        try {
          this.liveViewSequence = 1;
          const retryRemainingMs: number = Math.max(0, this.restEndTime - Date.now());
          let retryView: liveViewManager.LiveView = {
            id: REST_LIVE_VIEW_ID,
            event: 'TIMER',
            sequence: this.liveViewSequence,
            isMute: false,
            timer: {
              time: retryRemainingMs,
              isCountdown: true,
              isPaused: false,
            },
            liveViewData: {
              primary: {
                title: 'FitTrack - 休息中',
                content: [
                  { text: '剩余 ' },
                  { text: '${placeholder.timer}', textColor: '#FFFF6B35' },
                  { text: ' | ' },
                  { text: this.currentExerciseName, textColor: '#FFFF6B35' }
                ],
                keepTime: 1,
                clickAction: this.liveViewWantAgent!,
                layoutData: {
                  layoutType: liveViewManager.LayoutType.LAYOUT_TYPE_PICKUP,
                  title: '休息倒计时',
                  content: '${placeholder.timer}',
                  underlineColor: '#FFFF6B35',
                  descPic: "liveview_icon.png"
                }
              },
              capsule: {
                type: liveViewManager.CapsuleType.CAPSULE_TYPE_TIMER,
                status: 1,
                icon: CAPSULE_ICON,
                content: '${placeholder.timer}',
                time: retryRemainingMs,
                isCountdown: true,
                isPaused: false,
                backgroundColor: '#FFFF6B35',
              }
            }
          };
          await liveViewManager.startLiveView(retryView);
          this.liveViewActive = true;
          console.info('[FitTrack] startRestLiveView 重试成功');
        } catch (retryErr) {
          const retryError: BusinessError = retryErr as BusinessError;
          console.error(`[FitTrack] startRestLiveView 重试失败: code=${retryError.code}, msg=${retryError.message}`);
        }
      }
    }
  }

  private async stopRestLiveView(): Promise<void> {
    // 如果实况窗未启动，则无需停止
    if (!this.liveViewActive) {
      console.info('[FitTrack] stopRestLiveView 跳过：实况窗未启动');
      return;
    }

    // 确保 wantAgent 已创建，否则无法构造停止请求
    if (this.liveViewWantAgent === null) {
      console.warn('[FitTrack] stopRestLiveView 跳过：liveViewWantAgent 为空');
      this.liveViewActive = false;
      return;
    }

    try {
      // 停止时需要递增 sequence，否则会报 1003500011（sequence 不正确）
      this.liveViewSequence = this.liveViewSequence + 1;

      let liveView: liveViewManager.LiveView = {
        id: REST_LIVE_VIEW_ID,
        event: 'TIMER',
        sequence: this.liveViewSequence,
        isMute: false,
        liveViewData: {
          primary: {
            title: 'FitTrack',
            content: [{ text: '休息结束' }],
            keepTime: 1,
            clickAction: this.liveViewWantAgent!,
            layoutData: {
              layoutType: liveViewManager.LayoutType.LAYOUT_TYPE_PICKUP,
              title: '休息完成',
              content: '休息时间已结束',
              underlineColor: '#FF4CAF50',
            }
          },
          capsule: {
            type: liveViewManager.CapsuleType.CAPSULE_TYPE_TIMER,
            status: 0,
            icon: CAPSULE_ICON,
            content: '完成',
            backgroundColor: '#FF999999',
          }
        }
      };

      await liveViewManager.stopLiveView(liveView);
      this.liveViewActive = false;
      console.info(`[FitTrack] stopRestLiveView 成功, sequence=${this.liveViewSequence}`);
    } catch (e) {
      this.liveViewActive = false;
      const err: BusinessError = e as BusinessError;
      // 1003500009: 实况窗不存在（可能已被系统清理），属于正常情况
      // 1003500010: 实况窗已结束，也属于正常情况
      if (err.code === 1003500009 || err.code === 1003500010) {
        console.info(`[FitTrack] stopRestLiveView 实况窗已不存在或已结束: code=${err.code}`);
      } else {
        console.error(`[FitTrack] stopRestLiveView 失败: code=${err.code}, msg=${err.message}`);
      }
    }
  }

  private scheduleRestReminder(restSeconds: number): void {
    this.cancelRestReminder();

    // 注意：代理提醒从 API version 20 开始支持模拟器开发
    // 如果在低于 API 20 的模拟器上运行，代理提醒将无法触发
    console.info(`[FitTrack] 准备发布代理提醒, restSeconds=${restSeconds}（注意：模拟器需 API 20+ 才支持代理提醒）`);

    try {
      const bundleInfo: bundleManager.BundleInfo =
        bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);

      let reminderRequest: reminderAgentManager.ReminderRequestTimer = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_TIMER,
        triggerTimeInSeconds: restSeconds,
        title: 'FitTrack',
        content: '休息时间到！开始下一组？',
        notificationId: 100,
        slotType: notificationManager.SlotType.CONTENT_INFORMATION,
        wantAgent: {
          pkgName: bundleInfo.name,
          abilityName: 'EntryAbility',
        },
      };

      reminderAgentManager.publishReminder(reminderRequest).then((reminderId: number) => {
        this.currentReminderId = reminderId;
        console.info(`[FitTrack] 代理提醒发布成功, id=${reminderId}, seconds=${restSeconds}`);
      }).catch((err: BusinessError) => {
        console.error(`[FitTrack] 代理提醒发布失败: code=${err.code}, msg=${err.message}`);
        // 常见失败原因：
        // 1) 模拟器 API 版本低于 20，不支持代理提醒
        // 2) 应用未在 AppGallery Connect 申请代理提醒权益（管控限制）
        // 3) 用户未授予通知权限
        // 4) 触发时间过短（triggerTimeInSeconds 需大于 0）
      });
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      console.error(`[FitTrack] scheduleRestReminder 异常: code=${err.code}, msg=${err.message}`);
    }
  }

  private cancelRestReminder(): void {
    if (this.currentReminderId === -1) {
      return;
    }
    try {
      let id: number = this.currentReminderId;
      this.currentReminderId = -1;
      reminderAgentManager.cancelReminder(id).then(() => {
        console.info(`[FitTrack] 代理提醒已取消, id=${id}`);
      }).catch((err: BusinessError) => {
        console.error(`[FitTrack] 取消代理提醒失败: code=${err.code}, msg=${err.message}`);
      });
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      console.error(`[FitTrack] cancelRestReminder 异常: code=${err.code}, msg=${err.message}`);
    }
  }

}
