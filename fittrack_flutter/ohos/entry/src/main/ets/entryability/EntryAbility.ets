import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import MethodChannel from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { MethodCallHandler, MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import MethodCall from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodCall';
import StandardMethodCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMethodCodec';
import { formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { preferences } from '@kit.ArkData';
import { Want, AbilityConstant, wantAgent, WantAgent, bundleManager, common, abilityAccessCtrl } from '@kit.AbilityKit';
import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { liveViewManager } from '@kit.LiveViewKit';
import { notificationManager } from '@kit.NotificationKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileUri } from '@kit.CoreFileKit';
import fs from '@ohos.file.fs';

const PREFERENCES_NAME: string = 'fittrack_form_data';
const KEY_FORM_DATA: string = 'form_data';
const FORM_CHANNEL_NAME: string = 'com.fp.fitplan/form';
const REMINDER_CHANNEL_NAME: string = 'com.fp.fitplan/reminder';
const POSTER_CHANNEL_NAME: string = 'com.fp.fitplan/poster';
const REST_LIVE_VIEW_ID: number = 30001;

const CAPSULE_ICON: string = 'liveview_icon.png';

// 休息倒计时降级持续通知的 ID（实况窗不可用时使用）
const REST_FALLBACK_NOTIFICATION_ID: number = 200;

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

/// 海报保存/分享 MethodChannel handler
/// 在 OHOS 平台实现：
/// - requestWritePermission: 请求 WRITE_IMAGEVIDEO 权限
/// - checkWritePermission: 检查 WRITE_IMAGEVIDEO 权限
/// - saveToGallery: 通过 photoAccessHelper 保存 PNG 到系统相册
/// - share: 通过系统 Want 拉起分享面板
class PosterShareHandler implements MethodCallHandler {
  private ability: EntryAbility;

  constructor(ability: EntryAbility) {
    this.ability = ability;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method === 'saveToGallery') {
      const srcPath: string = call.args as string;
      this.saveToGallery(srcPath, result);
    } else if (call.method === 'share') {
      const srcPath: string = call.args as string;
      this.share(srcPath, result);
    } else if (call.method === 'requestWritePermission') {
      this.requestWritePermission(result);
    } else if (call.method === 'checkWritePermission') {
      this.checkWritePermission(result);
    } else {
      result.notImplemented();
    }
  }

  /// 请求写入图片/视频权限
  private async requestWritePermission(result: MethodResult): Promise<void> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const tokenId: number = this.ability.context.applicationInfo.accessTokenId;
      const status = await atManager.checkAccessToken(tokenId, 'ohos.permission.WRITE_IMAGEVIDEO');
      console.info('[FitTrack] WRITE_IMAGEVIDEO status=' + status);

      if (status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        result.success(true);
        return;
      }

      // 请求权限
      const context = this.ability.context as common.UIAbilityContext;
      const grantStatus = await atManager.requestPermissionsFromUser(context, ['ohos.permission.WRITE_IMAGEVIDEO']);
      const granted = grantStatus.authResults.length > 0 &&
        grantStatus.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
      console.info('[FitTrack] requestWritePermission result=' + granted);
      result.success(granted);
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      console.error('[FitTrack] requestWritePermission failed: code=' + err.code + ', msg=' + err.message);
      result.success(false);
    }
  }

  /// 检查写入图片/视频权限
  private async checkWritePermission(result: MethodResult): Promise<void> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const tokenId: number = this.ability.context.applicationInfo.accessTokenId;
      const status = await atManager.checkAccessToken(tokenId, 'ohos.permission.WRITE_IMAGEVIDEO');
      const granted = status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
      console.info('[FitTrack] checkWritePermission=' + granted);
      result.success(granted);
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      console.error('[FitTrack] checkWritePermission failed: code=' + err.code + ', msg=' + err.message);
      result.success(false);
    }
  }

  /// 保存图片到系统相册
  private async saveToGallery(srcPath: string, result: MethodResult): Promise<void> {
    try {
      console.info('[FitTrack] saveToGallery start, srcPath=' + srcPath);

      // 1. 检查源文件是否存在
      if (!fs.accessSync(srcPath)) {
        result.error('FILE_NOT_FOUND', '源文件不存在: ' + srcPath, null);
        return;
      }

      // 2. 检查权限
      const atManager = abilityAccessCtrl.createAtManager();
      const tokenId: number = this.ability.context.applicationInfo.accessTokenId;
      const permStatus = await atManager.checkAccessToken(tokenId, 'ohos.permission.WRITE_IMAGEVIDEO');
      if (permStatus !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        result.error('PERMISSION_DENIED', '未授予保存图片权限，请在设置中开启', null);
        return;
      }

      // 3. 通过 photoAccessHelper 创建媒体资产（返回 URI）
      const helper: photoAccessHelper.PhotoAccessHelper =
        photoAccessHelper.getPhotoAccessHelper(this.ability.context);
      const assetUri: string = await helper.createAsset(
        photoAccessHelper.PhotoType.IMAGE, 'png'
      );
      console.info('[FitTrack] saveToGallery createAsset uri=' + assetUri);

      // 4. 打开源文件和目标文件，复制数据
      const srcFile = fs.openSync(srcPath, fs.OpenMode.READ_ONLY);
      const dstFile = fs.openSync(assetUri, fs.OpenMode.WRITE_ONLY);
      try {
        await fs.copyFile(srcFile.fd, dstFile.fd);
        console.info('[FitTrack] saveToGallery copyFile success');
      } finally {
        fs.closeSync(srcFile);
        fs.closeSync(dstFile);
      }

      result.success(assetUri);
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      console.error(`[FitTrack] saveToGallery failed: code=${err.code}, msg=${err.message}`);
      result.error('SAVE_FAILED', `保存失败: ${err.message}`, null);
    }
  }

  /// 拉起系统分享面板
  ///
  /// 使用 ohos.want.action.sendData + entity.system.share 实体：
  /// - action: 'ohos.want.action.sendData' 表示向其他应用发送数据
  /// - entities: ['entity.system.share'] 表示目标是系统分享面板
  /// - type: 'image/png' 限定可接收的应用为支持 PNG 图片的应用
  /// - 'ability.params.stream': [fileUri] 以文件流形式传递图片 URI
  ///
  /// 之前未指定 entities 导致系统找不到对应的分享 ability，
  /// 报错 "the specified ability does not exist"。
  private async share(srcPath: string, result: MethodResult): Promise<void> {
    try {
      console.info('[FitTrack] share start, srcPath=' + srcPath);

      // 检查源文件是否存在
      if (!fs.accessSync(srcPath)) {
        result.error('FILE_NOT_FOUND', '源文件不存在: ' + srcPath, null);
        return;
      }

      // 将文件路径转换为 file URI，供其他应用访问
      const fileUriStr: string = fileUri.getUriFromPath(srcPath);
      console.info('[FitTrack] share fileUri=' + fileUriStr);

      // 通过 Want 拉起系统分享面板
      // 关键：必须包含 entities: ['entity.system.share'] 才能匹配系统分享面板
      const context = this.ability.context as common.UIAbilityContext;
      const want: Want = {
        action: 'ohos.want.action.sendData',
        entities: ['entity.system.share'],
        type: 'image/png',
        parameters: {
          'ability.params.stream': [fileUriStr]
        }
      };

      await context.startAbility(want);
      console.info('[FitTrack] share startAbility success');
      result.success(null);
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      console.error(`[FitTrack] share failed: code=${err.code}, msg=${err.message}`);
      result.error('SHARE_FAILED', `分享失败: ${err.message}`, null);
    }
  }
}

export default class EntryAbility extends FlutterAbility {
  private formChannel: MethodChannel | null = null;
  private reminderChannel: MethodChannel | null = null;
  private posterChannel: MethodChannel | null = null;

  private restEndTime: number = 0;
  private totalRestSeconds: number = 0;
  private currentExerciseName: string = '';
  private liveViewSequence: number = 0;
  private liveViewWantAgent: WantAgent | null = null;
  private currentReminderId: number = -1;
  private liveViewActive: boolean = false;
  // 每日训练提醒（代理提醒）ID，-1 表示未发布
  private trainingReminderId: number = -1;
  // 健身卡到期提醒（代理提醒）ID，-1 表示未发布
  private gymCardReminderId: number = -1;

  // 休息结束刷新桌面卡片用的原生定时器 ID（-1 表示未启动）
  // 代理提醒触发时系统只会发通知，不会回调应用刷新卡片；
  // 这里用 setTimeout 在休息结束时主动更新 preferences + reloadForms，
  // 让桌面卡片从"休息中"切回"训练中"。
  private restRefreshTimerId: number = -1;

  // 实况窗降级持续通知相关
  // 实况窗权益未申请/开关未开启/真机不支持时，发布横幅通知告知用户"休息中"
  private restFallbackActive: boolean = false;

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
    this.reminderChannel.setMethodCallHandler(new ReminderCallHandler(this));

    this.posterChannel = new MethodChannel(
      flutterEngine.getDartExecutor().getBinaryMessenger(),
      POSTER_CHANNEL_NAME,
      StandardMethodCodec.INSTANCE
    );
    this.posterChannel.setMethodCallHandler(new PosterShareHandler(this));

    // 应用启动时主动请求通知权限 + 预创建 SOCIAL_COMMUNICATION 渠道
    // 横幅通知开关由用户在系统设置中控制，应用无法通过 API 强制开启，
    // 但 SOCIAL_COMMUNICATION 渠道类型默认支持横幅，用户开启横幅后即可显示
    this.requestNotificationPermissionAndCreateSlot();
  }

  /// 请求通知权限并预创建 SOCIAL_COMMUNICATION 渠道
  /// - requestEnableNotification：首次调用会弹出系统授权对话框
  /// - addSlot(SOCIAL_COMMUNICATION)：预创建横幅通知渠道
  /// - 横幅通知的显示开关由用户在 设置 > 通知管理 > LiftTrack 中控制
  private requestNotificationPermissionAndCreateSlot(): void {
    notificationManager.requestEnableNotification(this.context)
      .then(() => {
        console.info('[FitTrack] 通知权限已授予');
        // 权限授予后预创建 SOCIAL_COMMUNICATION 渠道
        return notificationManager.addSlot(notificationManager.SlotType.SOCIAL_COMMUNICATION);
      })
      .then(() => {
        console.info('[FitTrack] SOCIAL_COMMUNICATION 渠道预创建成功');
      })
      .catch((err: BusinessError) => {
        console.warn(`[FitTrack] 通知权限/渠道创建: code=${err.code}, msg=${err.message}`);
      });
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

      // 代理提醒触发后用户点击通知拉起应用：此时 want.parameters 可能为空
      // 检测休息是否已结束（restEndTime > 0 且已过期），若是则刷新桌面卡片
      // 并通知 Flutter 端执行 skipRest
      this.checkRestExpiredAndRefresh();
    } catch (e) {
      console.error('[FitTrack] onNewWant error: ' + e);
    }
  }

  /// 应用回到前台时检查休息是否已结束
  /// 解决：应用在后台时代理提醒触发通知，但 setTimeout 被冻结无法刷新卡片；
  /// 用户回到应用时在此兜底刷新卡片 + 通知 Flutter 跳过休息
  onForeground(): void {
    super.onForeground();
    console.info('[FitTrack] onForeground: 检查休息是否已结束');
    this.checkRestExpiredAndRefresh();
  }

  /// 检测休息是否已结束（restEndTime > 0 且已过期）
  /// 若是则：1) 刷新桌面卡片为训练态 2) 通知 Flutter 端执行 skipRest
  private checkRestExpiredAndRefresh(): void {
    if (this.restEndTime <= 0) {
      return;
    }
    const now: number = Date.now();
    if (now < this.restEndTime) {
      console.info(`[FitTrack] 休息未结束, restEndTime=${this.restEndTime}, now=${now}`);
      return;
    }

    console.info('[FitTrack] 检测到休息已结束，刷新卡片 + 通知 Flutter');
    // 刷新桌面卡片
    this.refreshCardAfterRest();
    // 通知 Flutter 端执行 skipRest（让 UI 切换到下一个动作）
    const params: Record<string, Object> = {
      'targetPage': 'training',
      'cardAction': 'skipRest'
    };
    this.invokeFlutterMethod('onCardClick', params);
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

      formProvider.reloadForms(this.context, 'entry', 'FitTrackFormExtension', 'LiftTrack训练卡片')
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
        // 休息结束（或非休息状态）：停止实况窗 + 降级持续通知 + 取消卡片刷新定时器
        this.stopRestLiveView();
        this.stopRestFallbackNotification();
        this.cancelRestRefreshTimer();

        // 仅在用户主动跳过休息时取消代理提醒；
        // 休息自然结束（Dart Timer 触发，restSkipped 未传或为 false）时不取消，
        // 让 reminderAgentManager 代理提醒按预定时间触发，向用户发送"休息结束"通知。
        //
        // 注意：不能用 Date.now() < restEndTime 判断"是否跳过"，
        // 因为 Dart Timer 会比 restEndTime 早约 1 秒触发（Timer 精度问题），
        // 导致自然结束时也被误判为跳过而取消通知。
        const restSkipped: boolean = (parsed['restSkipped'] as boolean) ?? false;
        if (restSkipped) {
          console.info('[FitTrack] 休息被跳过，取消尚未触发的代理提醒');
          this.cancelRestReminder();
        } else {
          console.info('[FitTrack] 休息自然结束，保留代理提醒等待触发');
        }

        // 重置 restEndTime，避免跨训练周期误用
        this.restEndTime = 0;
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
        console.warn('[FitTrack] 实况窗开关未开启，无法创建实况窗。可能原因：1) 用户未在设置中开启实况窗开关；2) 模拟器环境限制；3) 实况窗权益未申请。降级为持续通知');
        // 实况窗不可用：降级为持续通知显示休息倒计时（保留实况窗代码，仅降级）
        this.startRestFallbackNotification();
        return;
      }

      await this.buildLiveViewWantAgent();
      // 如果 wantAgent 创建失败，则无法继续创建实况窗
      if (this.liveViewWantAgent === null) {
        console.error('[FitTrack] liveViewWantAgent 创建失败，无法创建实况窗，降级为持续通知');
        this.startRestFallbackNotification();
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
            title: 'LiftTrack - 休息中',
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
                title: 'LiftTrack - 休息中',
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
          // 重试仍失败：降级为持续通知
          this.startRestFallbackNotification();
        }
      } else {
        // 其他错误（权益未申请/开关关闭/服务器不可达）：降级为持续通知
        this.startRestFallbackNotification();
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
            title: 'LiftTrack',
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
    this.cancelRestRefreshTimer();

    // 注意：代理提醒从 API version 20 开始支持模拟器开发
    // 如果在低于 API 20 的模拟器上运行，代理提醒将无法触发
    console.info(`[FitTrack] 准备发布代理提醒, restSeconds=${restSeconds}（注意：模拟器需 API 20+ 才支持代理提醒）`);

    // 关键修复：发布代理提醒前，显式创建 SOCIAL_COMMUNICATION 槽位
    // 代理提醒触发时（倒计时结束）由系统代理发布通知，若该槽位不存在，
    // 系统会回退到默认 OTHER_TYPES 槽位（无横幅、无振动），导致用户看不到顶部横幅。
    // startRestFallbackNotification 中的 addSlot 是异步且依赖 startRestLiveView（async），
    // 可能在 scheduleRestReminder 执行时尚未完成，因此这里独立调用一次确保槽位就绪。
    notificationManager.addSlot(notificationManager.SlotType.SOCIAL_COMMUNICATION)
      .then(() => {
        console.info('[FitTrack] scheduleRestReminder: SOCIAL_COMMUNICATION 槽位已就绪');
      })
      .catch((err: BusinessError) => {
        // 槽位已存在时会报错，属于正常情况，不影响后续通知发布
        console.warn(`[FitTrack] scheduleRestReminder: addSlot 失败(可能已存在): code=${err.code}, msg=${err.message}`);
      });

    try {
      const bundleInfo: bundleManager.BundleInfo =
        bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);

      // 修复：使用 SOCIAL_COMMUNICATION 高优先级槽位，确保真机后台触发时
      // 能横幅弹出 + 振动，不再静默（CONTENT_INFORMATION 为低优先级静默槽）
      let reminderRequest: reminderAgentManager.ReminderRequestTimer = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_TIMER,
        triggerTimeInSeconds: restSeconds,
        title: 'LiftTrack',
        content: '休息时间到！开始下一组？',
        notificationId: 100,
        slotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
        wantAgent: {
          pkgName: bundleInfo.name,
          abilityName: 'EntryAbility',
        },
        // 锁屏下也显示通知，确保用户一定能看到
        // MaxScreenWantAgent 仅支持 pkgName + abilityName，不支持 parameters
        maxScreenWantAgent: {
          pkgName: bundleInfo.name,
          abilityName: 'EntryAbility',
        },
        // 添加操作按钮：点击直接拉起应用并触发 skipRest（开始下一组）
        actionButton: [
          {
            title: '开始下一组',
            type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE,
          },
        ],
      };

      reminderAgentManager.publishReminder(reminderRequest).then((reminderId: number) => {
        this.currentReminderId = reminderId;
        console.info(`[FitTrack] 代理提醒发布成功, id=${reminderId}, seconds=${restSeconds}`);
        // 启动原生定时器：休息结束时主动刷新桌面卡片
        // 代理提醒触发时系统只发通知，不会回调应用刷新卡片；
        // 这里用 setTimeout 在 restSeconds 后主动更新 preferences + reloadForms，
        // 让桌面卡片从"休息中"切回"训练中"
        this.scheduleRestRefresh(restSeconds);
      }).catch((err: BusinessError) => {
        console.error(`[FitTrack] 代理提醒发布失败: code=${err.code}, msg=${err.message}`);
        // 常见失败原因：
        // 1) 模拟器 API 版本低于 20，不支持代理提醒
        // 2) 应用未在 AppGallery Connect 申请代理提醒权益（管控限制）
        // 3) 用户未授予通知权限
        // 4) 触发时间过短（triggerTimeInSeconds 需大于 0）
        // 代理提醒发布失败时，仍启动卡片刷新定时器（保底让卡片能切换）
        this.scheduleRestRefresh(restSeconds);
      });
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      console.error(`[FitTrack] scheduleRestReminder 异常: code=${err.code}, msg=${err.message}`);
      // 异常时也启动卡片刷新定时器保底
      this.scheduleRestRefresh(restSeconds);
    }
  }

  /// 启动原生定时器，休息结束时主动刷新桌面卡片为训练态
  /// 解决：应用在后台时，代理提醒触发通知但桌面卡片仍停留在"休息中"的问题
  private scheduleRestRefresh(restSeconds: number): void {
    this.cancelRestRefreshTimer();
    const delayMs: number = restSeconds * 1000;
    this.restRefreshTimerId = setTimeout(() => {
      this.restRefreshTimerId = -1;
      this.refreshCardAfterRest();
    }, delayMs);
    console.info(`[FitTrack] scheduleRestRefresh 已启动, ${restSeconds}s 后刷新卡片`);
  }

  /// 取消休息结束刷新卡片的定时器
  private cancelRestRefreshTimer(): void {
    if (this.restRefreshTimerId !== -1) {
      clearTimeout(this.restRefreshTimerId);
      this.restRefreshTimerId = -1;
      console.info('[FitTrack] cancelRestRefreshTimer 已取消');
    }
  }

  /// 休息结束后，主动更新桌面卡片为训练态
  /// 1. 读取 preferences 中的 form_data
  /// 2. 将 mode 从 'rest' 改为 'training'，清除休息相关字段
  /// 3. 写回 preferences 并调用 formProvider.reloadForms 刷新桌面卡片
  private refreshCardAfterRest(): void {
    try {
      const prefs: preferences.Preferences =
        preferences.getPreferencesSync(this.context, { name: PREFERENCES_NAME });
      const saved: string = prefs.getSync(KEY_FORM_DATA, '').toString();
      if (saved === '') {
        console.info('[FitTrack] refreshCardAfterRest: 无 form_data，跳过');
        return;
      }

      const parsed: Record<string, Object> = JSON.parse(saved) as Record<string, Object>;
      const currentMode: string = (parsed['mode'] as string) ?? 'idle';
      // 仅在当前为休息态时才切换（避免误覆盖训练态/空闲态）
      if (currentMode !== 'rest') {
        console.info(`[FitTrack] refreshCardAfterRest: 当前 mode=${currentMode}，无需切换`);
        return;
      }

      // 切换到训练态，清除休息相关字段
      parsed['mode'] = 'training';
      parsed['restEndTime'] = 0;
      parsed['restSeconds'] = 0;

      const newDataStr: string = JSON.stringify(parsed);
      prefs.putSync(KEY_FORM_DATA, newDataStr);
      prefs.flushSync();
      console.info(`[FitTrack] refreshCardAfterRest: 已写入训练态, data=${newDataStr}`);

      // 重置内存中的休息结束时间，避免 onForeground/onNewWant 重复触发
      this.restEndTime = 0;

      formProvider.reloadForms(this.context, 'entry', 'FitTrackFormExtension', 'LiftTrack训练卡片')
        .then((reloadNum: number) => {
          console.info(`[FitTrack] refreshCardAfterRest reloadForms 成功, reloadNum=${reloadNum}`);
        })
        .catch((err: BusinessError) => {
          console.error(`[FitTrack] refreshCardAfterRest reloadForms 失败: ${err.code} - ${err.message}`);
        });

      // 同时停止降级持续通知（如果存在）
      this.stopRestFallbackNotification();
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      console.error(`[FitTrack] refreshCardAfterRest 异常: code=${err.code}, msg=${err.message}`);
    }
  }

  private cancelRestReminder(): void {
    // 同时取消休息结束刷新卡片的定时器
    this.cancelRestRefreshTimer();
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

  // ============================================================
  // 实况窗降级：休息开始时发布一条横幅通知
  // ============================================================
  // 当实况窗权益未申请/开关未开启/真机不支持时，发布一条 SOCIAL_COMMUNICATION
  // 横幅通知告知用户"休息中"。倒计时过程不实时更新（系统 isCountDown 等字段
  // 均为"预留能力，暂未支持"，setInterval 在应用后台时会被冻结）。
  // 休息结束时由代理提醒触发新的横幅通知（带声音+振动+横幅）。
  // 桌面卡片刷新在用户点击通知拉起应用时由 onNewWant 触发。

  /// 启动降级通知（实况窗不可用时调用）
  /// 发布一条 SOCIAL_COMMUNICATION 横幅通知，告知用户休息开始
  private startRestFallbackNotification(): void {
    // 先清理上一次的降级通知
    this.stopRestFallbackNotification();

    const remainingMs: number = Math.max(0, this.restEndTime - Date.now());
    const remainingSec: number = Math.max(1, Math.ceil(remainingMs / 1000));
    const totalSec: number = Math.max(1, Math.round(this.totalRestSeconds));

    // 先确保 SOCIAL_COMMUNICATION 渠道已创建（横幅通知必需）
    // 不创建渠道直接发布通知时，系统可能使用默认 OTHER_TYPES 渠道（无横幅）
    notificationManager.addSlot(notificationManager.SlotType.SOCIAL_COMMUNICATION)
      .then(() => {
        console.info('[FitTrack] SOCIAL_COMMUNICATION 渠道已创建/已存在');
        this.publishRestFallbackNotification(remainingSec, totalSec);
      })
      .catch((err: BusinessError) => {
        console.warn(`[FitTrack] addSlot SOCIAL_COMMUNICATION 失败(可能已存在): code=${err.code}, msg=${err.message}`);
        // 即使创建失败也尝试发布通知（渠道可能已存在）
        this.publishRestFallbackNotification(remainingSec, totalSec);
      });
  }

  /// 实际发布降级横幅通知
  private publishRestFallbackNotification(remainingSec: number, totalSec: number): void {
    try {
      const request: notificationManager.NotificationRequest = {
        id: REST_FALLBACK_NOTIFICATION_ID,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: 'LiftTrack - 休息中',
            text: `${this.currentExerciseName} · 休息 ${totalSec} 秒`,
            additionalText: `休息结束会自动提醒你（剩余约 ${remainingSec} 秒）`,
          },
        },
        // 使用 SOCIAL_COMMUNICATION 确保顶部横幅弹出（SERVICE_INFORMATION 无横幅）
        notificationSlotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
        isAlertOnce: true,    // 仅首次弹出横幅
      };

      notificationManager.publish(request).then(() => {
        this.restFallbackActive = true;
        console.info('[FitTrack] 降级横幅通知发布成功');
      }).catch((err: BusinessError) => {
        console.error(`[FitTrack] 降级横幅通知发布失败: code=${err.code}, msg=${err.message}`);
      });
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      console.error(`[FitTrack] startRestFallbackNotification 异常: code=${err.code}, msg=${err.message}`);
    }
  }

  /// 停止降级通知（休息结束/跳过休息时调用）
  private stopRestFallbackNotification(): void {
    if (!this.restFallbackActive) {
      return;
    }
    this.restFallbackActive = false;
    try {
      notificationManager.cancel(REST_FALLBACK_NOTIFICATION_ID);
      console.info('[FitTrack] 降级横幅通知已取消');
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      console.warn(`[FitTrack] 取消降级通知失败: code=${err.code}, msg=${err.message}`);
    }
  }

  /// 发布每日训练提醒（按 HH:mm 每日重复）
  /// 使用 ReminderRequestCalendar 实现每日定点重复
  scheduleTrainingReminder(title: string, content: string, timeStr: string): void {
    this.cancelTrainingReminder();

    // 解析 "HH:mm"
    const parts: string[] = timeStr.split(':');
    if (parts.length !== 2) {
      console.error(`[FitTrack] scheduleTrainingReminder 时间格式错误: ${timeStr}`);
      return;
    }
    const hour: number = parseInt(parts[0], 10);
    const minute: number = parseInt(parts[1], 10);
    if (isNaN(hour) || isNaN(minute) || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      console.error(`[FitTrack] scheduleTrainingReminder 时间非法: ${timeStr}`);
      return;
    }

    console.info(`[FitTrack] 准备发布每日训练提醒, time=${timeStr}`);

    try {
      const bundleInfo: bundleManager.BundleInfo =
        bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);

      // ReminderRequestCalendar：按日历时间重复
      // dateTime 指定首次触发时间，repeatMonths/repeatDays/repeatDaysOfWeek 为空表示每日重复
      let reminderRequest: reminderAgentManager.ReminderRequestCalendar = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
        dateTime: {
          year: new Date().getFullYear(),
          month: new Date().getMonth() + 1,
          day: new Date().getDate(),
          hour: hour,
          minute: minute,
          second: 0,
        },
        // 每日重复：所有月份、所有日期都触发
        repeatMonths: [],
        repeatDays: [],
        title: title,
        content: content,
        notificationId: 3001,
        // 使用 SOCIAL_COMMUNICATION 高优先级槽位，确保真机触发时能横幅弹出 + 振动
        slotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
        wantAgent: {
          pkgName: bundleInfo.name,
          abilityName: 'EntryAbility',
        },
        actionButton: [
          {
            title: '开始训练',
            type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE,
          },
        ],
      };

      reminderAgentManager.publishReminder(reminderRequest).then((reminderId: number) => {
        this.trainingReminderId = reminderId;
        console.info(`[FitTrack] 每日训练提醒发布成功, id=${reminderId}, time=${timeStr}`);
      }).catch((err: BusinessError) => {
        console.error(`[FitTrack] 每日训练提醒发布失败: code=${err.code}, msg=${err.message}`);
      });
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      console.error(`[FitTrack] scheduleTrainingReminder 异常: code=${err.code}, msg=${err.message}`);
    }
  }

  /// 取消每日训练提醒
  cancelTrainingReminder(): void {
    if (this.trainingReminderId === -1) {
      return;
    }
    try {
      let id: number = this.trainingReminderId;
      this.trainingReminderId = -1;
      reminderAgentManager.cancelReminder(id).then(() => {
        console.info(`[FitTrack] 每日训练提醒已取消, id=${id}`);
      }).catch((err: BusinessError) => {
        console.error(`[FitTrack] 取消每日训练提醒失败: code=${err.code}, msg=${err.message}`);
      });
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      console.error(`[FitTrack] cancelTrainingReminder 异常: code=${err.code}, msg=${err.message}`);
    }
  }

  /// 调度健身卡到期提醒（后台代理提醒）
  /// [dateStr] 格式 "YYYY-MM-DD"，提醒时间固定为当天 10:00
  scheduleGymCardReminder(title: string, content: string, dateStr: string): void {
    this.cancelGymCardReminder();

    // 解析 dateStr "YYYY-MM-DD"
    const parts: string[] = dateStr.split('-');
    if (parts.length !== 3) {
      console.error(`[FitTrack] scheduleGymCardReminder 日期格式错误: ${dateStr}`);
      return;
    }
    const year: number = parseInt(parts[0], 10);
    const month: number = parseInt(parts[1], 10);
    const day: number = parseInt(parts[2], 10);
    if (isNaN(year) || isNaN(month) || isNaN(day) ||
      month < 1 || month > 12 || day < 1 || day > 31) {
      console.error(`[FitTrack] scheduleGymCardReminder 日期非法: ${dateStr}`);
      return;
    }

    console.info(`[FitTrack] 准备发布健身卡到期提醒, date=${dateStr}, time=10:00`);

    try {
      const bundleInfo: bundleManager.BundleInfo =
        bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);

      // ReminderRequestCalendar：按指定日历时间触发（一次性，不重复）
      // 注意：MaxScreenWantAgent 不支持 parameters 字段，wantAgent 只填 pkgName + abilityName
      let reminderRequest: reminderAgentManager.ReminderRequestCalendar = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
        dateTime: {
          year: year,
          month: month,
          day: day,
          hour: 10,
          minute: 0,
          second: 0,
        },
        // 空数组表示不按月/日重复，仅触发一次
        repeatMonths: [],
        repeatDays: [],
        title: title,
        content: content,
        notificationId: 4001,
        // 使用 SOCIAL_COMMUNICATION 高优先级槽位，确保真机触发时能横幅弹出 + 振动
        slotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
        wantAgent: {
          pkgName: bundleInfo.name,
          abilityName: 'EntryAbility',
        },
        actionButton: [
          {
            title: '查看',
            type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE,
          },
        ],
      };

      reminderAgentManager.publishReminder(reminderRequest).then((reminderId: number) => {
        this.gymCardReminderId = reminderId;
        console.info(`[FitTrack] 健身卡代理提醒发布成功, id=${reminderId}, date=${dateStr}`);
      }).catch((err: BusinessError) => {
        console.error(`[FitTrack] 健身卡代理提醒发布失败: code=${err.code}, msg=${err.message}`);
      });
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      console.error(`[FitTrack] scheduleGymCardReminder 异常: code=${err.code}, msg=${err.message}`);
    }
  }

  /// 取消健身卡到期提醒
  cancelGymCardReminder(): void {
    if (this.gymCardReminderId === -1) {
      return;
    }
    try {
      let id: number = this.gymCardReminderId;
      this.gymCardReminderId = -1;
      reminderAgentManager.cancelReminder(id).then(() => {
        console.info(`[FitTrack] 健身卡代理提醒已取消, id=${id}`);
      }).catch((err: BusinessError) => {
        console.error(`[FitTrack] 取消健身卡代理提醒失败: code=${err.code}, msg=${err.message}`);
      });
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      console.error(`[FitTrack] cancelGymCardReminder 异常: code=${err.code}, msg=${err.message}`);
    }
  }

}

/// 处理 Flutter → 原生的 MethodChannel 调用（reminderChannel）
/// 方法：publishReminder / cancelReminder / cancelAllReminders（休息提醒，由 EntryAbility 内部使用）
///       scheduleTrainingReminder / cancelTrainingReminder（每日训练提醒）
class ReminderCallHandler implements MethodCallHandler {
  private ability: EntryAbility;

  constructor(ability: EntryAbility) {
    this.ability = ability;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case 'scheduleTrainingReminder': {
        const args = call.args as Record<string, Object>;
        const title = (args['title'] as string) ?? '训练时间到';
        const content = (args['content'] as string) ?? '今天也要坚持训练哦！';
        const timeStr = (args['timeStr'] as string) ?? '';
        this.ability.scheduleTrainingReminder(title, content, timeStr);
        result.success(null);
        break;
      }
      case 'cancelTrainingReminder': {
        this.ability.cancelTrainingReminder();
        result.success(null);
        break;
      }
      case 'scheduleGymCardReminder': {
        const args = call.args as Record<string, Object>;
        const title = (args['title'] as string) ?? '';
        const content = (args['content'] as string) ?? '';
        const dateStr = (args['dateStr'] as string) ?? '';
        this.ability.scheduleGymCardReminder(title, content, dateStr);
        result.success(null);
        break;
      }
      case 'cancelGymCardReminder': {
        this.ability.cancelGymCardReminder();
        result.success(null);
        break;
      }
      default:
        // 其他方法（publishReminder/cancelReminder/cancelAllReminders）
        // 仍由原生侧主动调用，无需 Flutter → 原生
        result.notImplemented();
        break;
    }
  }
}
