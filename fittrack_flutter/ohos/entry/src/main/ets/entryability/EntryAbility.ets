import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import MethodChannel from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { MethodCallHandler, MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import MethodCall from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodCall';
import StandardMethodCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMethodCodec';
import { formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { preferences } from '@kit.ArkData';
import { Want, AbilityConstant, bundleManager } from '@kit.AbilityKit';
import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { notificationManager } from '@kit.NotificationKit';

const PREFERENCES_NAME: string = 'fittrack_form_data';
const KEY_FORM_DATA: string = 'form_data';
const FORM_CHANNEL_NAME: string = 'com.example.fittrack_flutter/form';
const REMINDER_CHANNEL_NAME: string = 'com.example.fittrack_flutter/reminder';
// 休息倒计时进度条通知 ID
const REST_COUNTDOWN_NOTIFICATION_ID: number = 20001;
// 休息结束通知 ID
const REST_END_NOTIFICATION_ID: number = 20002;

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

  // 休息倒计时定时器：仅 APP 前台时运行
  private countdownTimerId: number = -1;
  // 当前休息结束时间戳（epoch ms）
  private restEndTime: number = 0;
  // 当前休息总秒数
  private totalRestSeconds: number = 0;
  // 当前动作名
  private currentExerciseName: string = '';
  // 代理提醒 ID
  private currentReminderId: number = -1;

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

  /**
   * APP 切到后台时：停止倒计时定时器（APP 进程将被挂起，定时器无法运行）
   * reminderAgentManager 代理提醒已在进入休息态时发布，系统会代理发出休息结束通知
   */
  onBackground(): void {
    super.onBackground();
    console.info('[FitTrack] onBackground');
    this.stopCountdownTimer();
    this.cancelRestCountdownNotification();
  }

  /**
   * APP 回到前台时：重新启动倒计时定时器
   */
  onForeground(): void {
    super.onForeground();
    console.info('[FitTrack] onForeground');
    if (this.restEndTime > 0 && this.restEndTime > Date.now()) {
      this.startCountdownTimer();
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
   * 保存到 preferences → reloadForms 刷新卡片 → 根据模式管理倒计时通知/代理提醒
   */
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

  /**
   * 根据推送的 JSON 数据管理训练状态
   * 注意：不依赖后台任务保活，因为 HarmonyOS 长时任务无法支撑每秒刷新的场景
   */
  private manageTrainingState(dataStr: string): void {
    try {
      const parsed: Record<string, Object> = JSON.parse(dataStr) as Record<string, Object>;
      const mode: string = (parsed['mode'] as string) ?? 'idle';

      if (mode === 'rest') {
        const restEndTime: number = Number(parsed['restEndTime'] ?? 0);
        const totalRestSeconds: number = Number(parsed['totalRestSeconds'] ?? 0);
        this.restEndTime = restEndTime;
        this.totalRestSeconds = totalRestSeconds;
        this.currentExerciseName = (parsed['exerciseName'] as string) ?? '';

        // 启动倒计时定时器（仅 APP 前台时有效）
        this.startCountdownTimer();

        // 发布代理提醒：系统在休息结束时自动发出通知，即使 APP 已被杀死
        const restSeconds: number = Math.max(1, Math.round((restEndTime - Date.now()) / 1000));
        this.scheduleRestReminder(restSeconds);
      } else {
        // 非休息态：停止倒计时，取消所有通知和代理提醒
        this.stopCountdownTimer();
        this.cancelRestCountdownNotification();
        this.cancelRestEndNotification();
        this.cancelRestReminder();
      }
    } catch (e) {
      console.error('[FitTrack] manageTrainingState exception: ' + e);
    }
  }

  /**
   * 启动倒计时定时器
   * 仅 APP 前台时运行：每秒更新通知栏进度条通知显示倒计时
   * APP 切到后台时定时器自动停止（onBackground），回到前台时重启（onForeground）
   */
  private startCountdownTimer(): void {
    if (this.countdownTimerId !== -1) return;
    console.info('[FitTrack] startCountdownTimer');
    this.countdownTimerId = setInterval(() => {
      if (this.restEndTime <= 0) return;

      const remaining: number = Math.round((this.restEndTime - Date.now()) / 1000);
      console.info(`[FitTrack] countdown tick, remaining=${remaining}s`);

      if (remaining <= 0) {
        // 倒计时结束，发送结束通知
        this.publishRestEndNotification();
        this.stopCountdownTimer();
        this.cancelRestCountdownNotification();
      } else {
        // 更新进度条通知
        this.publishRestCountdownNotification(remaining);
      }
    }, 1000);
  }

  private stopCountdownTimer(): void {
    if (this.countdownTimerId !== -1) {
      console.info('[FitTrack] stopCountdownTimer');
      clearInterval(this.countdownTimerId);
      this.countdownTimerId = -1;
    }
  }

  /**
   * 发布/更新休息倒计时进度条通知
   */
  private publishRestCountdownNotification(remainingSeconds: number): void {
    try {
      let progressValue: number = 0;
      if (this.totalRestSeconds > 0) {
        progressValue = Math.round((remainingSeconds / this.totalRestSeconds) * 100);
      }

      let notificationRequest: notificationManager.NotificationRequest = {
        id: REST_COUNTDOWN_NOTIFICATION_ID,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: 'FitTrack - 休息中',
            text: '剩余 ' + remainingSeconds + ' 秒',
            additionalText: this.currentExerciseName,
          }
        },
        notificationSlotType: notificationManager.SlotType.SERVICE_INFORMATION,
        template: {
          name: 'downloadTemplate',
          data: {
            title: '休息倒计时',
            fileName: this.currentExerciseName,
            progressValue: progressValue,
          }
        }
      };

      notificationManager.publish(notificationRequest)
        .then(() => {
        })
        .catch((err: BusinessError) => {
          console.error(`[FitTrack] publishRestCountdownNotification failed: ${err.code} - ${err.message}`);
        });
    } catch (e) {
      console.error('[FitTrack] publishRestCountdownNotification exception: ' + e);
    }
  }

  private cancelRestCountdownNotification(): void {
    notificationManager.cancel(REST_COUNTDOWN_NOTIFICATION_ID)
      .then(() => {
      })
      .catch((err: BusinessError) => {
      });
  }

  /**
   * 发布休息结束通知
   */
  private publishRestEndNotification(): void {
    try {
      let notificationRequest: notificationManager.NotificationRequest = {
        id: REST_END_NOTIFICATION_ID,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: 'FitTrack',
            text: '休息时间到！开始下一组？',
            additionalText: '训练提醒',
          }
        },
        notificationSlotType: notificationManager.SlotType.SERVICE_INFORMATION,
      };

      notificationManager.publish(notificationRequest)
        .then(() => {
          console.info('[FitTrack] publishRestEndNotification success');
        })
        .catch((err: BusinessError) => {
          console.error(`[FitTrack] publishRestEndNotification failed: ${err.code} - ${err.message}`);
        });
    } catch (e) {
      console.error('[FitTrack] publishRestEndNotification exception: ' + e);
    }
  }

  private cancelRestEndNotification(): void {
    notificationManager.cancel(REST_END_NOTIFICATION_ID)
      .then(() => {
      })
      .catch((err: BusinessError) => {
      });
  }

  /**
   * 通过 reminderAgentManager 发布代理提醒
   * 系统在倒计时结束时自动发出通知，即使 APP 已被杀死也能准时送达
   */
  private scheduleRestReminder(restSeconds: number): void {
    this.cancelRestReminder();

    try {
      const bundleInfo: bundleManager.BundleInfo =
        bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);

      let reminderRequest: reminderAgentManager.ReminderRequestTimer = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_TIMER,
        triggerTimeInSeconds: restSeconds,
        title: 'FitTrack',
        content: '休息时间到！开始下一组？',
        wantAgent: {
          pkgName: bundleInfo.name,
          abilityName: 'EntryAbility',
        },
      };

      reminderAgentManager.publishReminder(reminderRequest).then((reminderId: number) => {
        this.currentReminderId = reminderId;
        console.info(`[FitTrack] scheduleRestReminder success, id=${reminderId}, seconds=${restSeconds}`);
      }).catch((err: BusinessError) => {
        console.error(`[FitTrack] publishReminder failed: ${err.code} - ${err.message}`);
      });
    } catch (e) {
      console.error(`[FitTrack] scheduleRestReminder exception: ${e}`);
    }
  }

  private cancelRestReminder(): void {
    if (this.currentReminderId === -1) return;
    try {
      let id: number = this.currentReminderId;
      this.currentReminderId = -1;
      reminderAgentManager.cancelReminder(id).then(() => {
      }).catch((err: BusinessError) => {
      });
    } catch (e) {
    }
  }
}
