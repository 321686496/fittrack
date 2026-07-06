import { FormExtensionAbility, formBindingData, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

const PREFERENCES_NAME: string = 'fittrack_form_data';
const KEY_FORM_DATA: string = 'form_data';

class FormDataRecord {
  // 卡片模式: idle | training | rest
  mode: string = 'idle'
  // 空闲态字段
  todayTrainings: number = 0
  todayDuration: number = 0
  todayWeight: number = 0
  streak: number = 0
  lastTraining: string = ''
  lastDate: string = ''
  // 训练态字段
  exerciseName: string = ''
  currentSet: number = 1
  totalSets: number = 0
  exerciseIndex: number = 1
  totalExercises: number = 0
  completedSets: number = 0
  totalPlanSets: number = 0
  // 休息态字段
  restSeconds: number = 0
  restEndTime: number = 0
  totalRestSeconds: number = 0
  // 主题颜色
  accentColor: string = '#FF6B35'
  bgColor: string = '#FFFFFF'
  textPrimaryColor: string = '#222222'
  textSecondaryColor: string = '#999999'
  // 训练提醒时间
  trainingTime: string = ''
}

export default class FitTrackFormExtension extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    console.info('[FitTrackForm] onAddForm');
    let data: FormDataRecord = this.buildFormData();
    return formBindingData.createFormBindingData(data);
  }

  onUpdateForm(formId: string): formBindingData.FormBindingData {
    console.info('[FitTrackForm] onUpdateForm, formId: ' + formId);
    let data: FormDataRecord = this.buildFormData();
    let binddata: formBindingData.FormBindingData = formBindingData.createFormBindingData(data);
    // 主动推送：onUpdateForm 的返回值由系统处理，但卡片 UI 的 @LocalStorageProp
    // 只有通过 formProvider.updateForm 才能更新。两者一起使用确保卡片刷新。
    formProvider.updateForm(formId, binddata).catch((e: ESObject) => {
      console.info('[FitTrack] update form error: ' + JSON.stringify(e));
    });
    return binddata;
  }

  onRemoveForm(formId: string): void {
    console.info('[FitTrackForm] onRemoveForm, formId: ' + formId);
  }

  private buildFormData(): FormDataRecord {
    let data: FormDataRecord = new FormDataRecord();

    try {
      // 关键：preferences 不支持多进程共享。写入方（EntryAbility 主进程）flush 到磁盘后，
      // 本 Form extension 进程若已缓存过 preferences 实例，getSync 只会读进程内旧缓存。
      // 因此每次读取前先移除缓存，强制从磁盘重新加载主进程写入的最新数据。
      preferences.removePreferencesFromCacheSync(this.context, { name: PREFERENCES_NAME });

      let prefs: preferences.Preferences = preferences.getPreferencesSync(this.context, { name: PREFERENCES_NAME });
      let saved: string = prefs.getSync(KEY_FORM_DATA, '').toString();
      if (saved !== '') {
        let parsed: Record<string, Object> = JSON.parse(saved) as Record<string, Object>;
        data.mode = this.getStringValue(parsed, 'mode', 'idle');
        data.todayTrainings = this.getNumberValue(parsed, 'todayTrainings', 0);
        data.todayDuration = this.getNumberValue(parsed, 'todayDuration', 0);
        data.todayWeight = this.getNumberValue(parsed, 'todayWeight', 0);
        data.streak = this.getNumberValue(parsed, 'streak', 0);
        data.lastTraining = this.getStringValue(parsed, 'lastTraining', '');
        data.lastDate = this.getStringValue(parsed, 'lastDate', '');
        data.exerciseName = this.getStringValue(parsed, 'exerciseName', '');
        data.currentSet = this.getNumberValue(parsed, 'currentSet', 1);
        data.totalSets = this.getNumberValue(parsed, 'totalSets', 0);
        data.exerciseIndex = this.getNumberValue(parsed, 'exerciseIndex', 1);
        data.totalExercises = this.getNumberValue(parsed, 'totalExercises', 0);
        data.completedSets = this.getNumberValue(parsed, 'completedSets', 0);
        data.totalPlanSets = this.getNumberValue(parsed, 'totalPlanSets', 0);

        // 休息态倒计时字段：用 restEndTime（epoch ms）实时计算剩余秒数
        data.restEndTime = this.getNumberValue(parsed, 'restEndTime', 0);
        data.totalRestSeconds = this.getNumberValue(parsed, 'totalRestSeconds', 0);
        if (data.mode === 'rest' && data.restEndTime > 0) {
          data.restSeconds = Math.max(0, Math.round((data.restEndTime - Date.now()) / 1000));
        } else {
          data.restSeconds = this.getNumberValue(parsed, 'restSeconds', 0);
        }

        data.accentColor = this.getStringValue(parsed, 'accentColor', '#FF6B35');
        data.bgColor = this.getStringValue(parsed, 'bgColor', '#FFFFFF');
        data.textPrimaryColor = this.getStringValue(parsed, 'textPrimaryColor', '#222222');
        data.textSecondaryColor = this.getStringValue(parsed, 'textSecondaryColor', '#999999');
        data.trainingTime = this.getStringValue(parsed, 'trainingTime', '');
      }
    } catch (e) {
      console.warn('[FitTrackForm] read preferences error: ' + e);
    }

    return data;
  }

  private getStringValue(obj: Record<string, Object>, key: string, defaultVal: string): string {
    let val: Object = obj[key];
    if (val !== undefined && val !== null) {
      return val.toString();
    }
    return defaultVal;
  }

  private getNumberValue(obj: Record<string, Object>, key: string, defaultVal: number): number {
    let val: Object = obj[key];
    if (val !== undefined && val !== null) {
      return Number(val);
    }
    return defaultVal;
  }
}
