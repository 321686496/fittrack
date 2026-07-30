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
    let data: Record<string, Object> = this.buildFormData();
    return formBindingData.createFormBindingData(data);
  }

  onUpdateForm(formId: string): formBindingData.FormBindingData {
    console.info('[FitTrackForm] onUpdateForm, formId: ' + formId);
    let data: Record<string, Object> = this.buildFormData();
    let binddata: formBindingData.FormBindingData = formBindingData.createFormBindingData(data);
    formProvider.updateForm(formId, binddata).catch((e: ESObject) => {
      console.info('[FitTrackForm] updateForm error: ' + JSON.stringify(e));
    });
    return binddata;
  }

  onRemoveForm(formId: string): void {
    console.info('[FitTrackForm] onRemoveForm, formId: ' + formId);
  }

  private buildFormData(): Record<string, Object> {
    // 使用普通对象（Record）而非 class 实例，确保所有属性可被 formBindingData 正确序列化
    let data: Record<string, Object> = {
      'mode': 'idle',
      'todayTrainings': 0,
      'todayDuration': 0,
      'todayWeight': 0,
      'streak': 0,
      'lastTraining': '',
      'lastDate': '',
      'exerciseName': '',
      'currentSet': 1,
      'totalSets': 0,
      'exerciseIndex': 1,
      'totalExercises': 0,
      'completedSets': 0,
      'totalPlanSets': 0,
      'restSeconds': 0,
      'restEndTime': 0,
      'totalRestSeconds': 0,
      'accentColor': '#FF6B35',
      'bgColor': '#FFFFFF',
      'textPrimaryColor': '#222222',
      'textSecondaryColor': '#999999',
      'trainingTime': '',
    };

    try {
      preferences.removePreferencesFromCacheSync(this.context, { name: PREFERENCES_NAME });

      let prefs: preferences.Preferences = preferences.getPreferencesSync(this.context, { name: PREFERENCES_NAME });
      let saved: string = prefs.getSync(KEY_FORM_DATA, '').toString();
      if (saved !== '') {
        // 诊断日志：打印 preferences 中的原始 JSON，用于排查数据传递问题
        console.info(`[FitTrackForm] raw saved JSON: ${saved}`);
        let parsed: Record<string, Object> = JSON.parse(saved) as Record<string, Object>;
        // 诊断日志：打印关键字字的原始值和运行时类型，用于排查 ArkTS 类型转换问题
        console.info(`[FitTrackForm] raw values: currentSet=${parsed['currentSet']}(typeof=${typeof parsed['currentSet']}), totalSets=${parsed['totalSets']}(typeof=${typeof parsed['totalSets']}), exerciseIndex=${parsed['exerciseIndex']}(typeof=${typeof parsed['exerciseIndex']}), totalExercises=${parsed['totalExercises']}(typeof=${typeof parsed['totalExercises']})`);
        data['mode'] = this.getStringValue(parsed, 'mode', 'idle');
        data['todayTrainings'] = this.getNumberValue(parsed, 'todayTrainings', 0);
        data['todayDuration'] = this.getNumberValue(parsed, 'todayDuration', 0);
        data['todayWeight'] = this.getNumberValue(parsed, 'todayWeight', 0);
        data['streak'] = this.getNumberValue(parsed, 'streak', 0);
        data['lastTraining'] = this.getStringValue(parsed, 'lastTraining', '');
        data['lastDate'] = this.getStringValue(parsed, 'lastDate', '');
        data['exerciseName'] = this.getStringValue(parsed, 'exerciseName', '');
        data['currentSet'] = this.getNumberValue(parsed, 'currentSet', 1);
        data['totalSets'] = this.getNumberValue(parsed, 'totalSets', 0);
        data['exerciseIndex'] = this.getNumberValue(parsed, 'exerciseIndex', 1);
        data['totalExercises'] = this.getNumberValue(parsed, 'totalExercises', 0);
        data['completedSets'] = this.getNumberValue(parsed, 'completedSets', 0);
        data['totalPlanSets'] = this.getNumberValue(parsed, 'totalPlanSets', 0);

        const restEndTime: number = this.getNumberValue(parsed, 'restEndTime', 0);
        const totalRestSeconds: number = this.getNumberValue(parsed, 'totalRestSeconds', 0);
        data['restEndTime'] = restEndTime;
        data['totalRestSeconds'] = totalRestSeconds;

        const mode: string = this.getStringValue(parsed, 'mode', 'idle');
        if (mode === 'rest' && restEndTime > 0) {
          const remainingSec = Math.max(0, Math.round((restEndTime - Date.now()) / 1000));
          if (remainingSec > 0) {
            data['restSeconds'] = remainingSec;
          } else {
            // 休息倒计时已结束但卡片未被刷新（App 可能后台挂起）
            // 自动切换到训练态显示，避免卡片停留在"休息中 0秒"
            data['mode'] = 'training';
            data['restSeconds'] = 0;
          }
        } else {
          data['restSeconds'] = this.getNumberValue(parsed, 'restSeconds', 0);
        }

        data['accentColor'] = this.getStringValue(parsed, 'accentColor', '#FF6B35');
        data['bgColor'] = this.getStringValue(parsed, 'bgColor', '#FFFFFF');
        data['textPrimaryColor'] = this.getStringValue(parsed, 'textPrimaryColor', '#222222');
        data['textSecondaryColor'] = this.getStringValue(parsed, 'textSecondaryColor', '#999999');
        data['trainingTime'] = this.getStringValue(parsed, 'trainingTime', '');

        console.info(`[FitTrackForm] buildFormData: mode=${data['mode']}, currentSet=${data['currentSet']}, totalSets=${data['totalSets']}, exerciseIndex=${data['exerciseIndex']}, totalExercises=${data['totalExercises']}, completedSets=${data['completedSets']}, totalPlanSets=${data['totalPlanSets']}`);
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
    if (val === undefined || val === null) {
      return defaultVal;
    }
    // 优先处理 number 类型（运行时检查）
    if (typeof val === 'number') {
      return val as number;
    }
    // 处理字符串或其他装箱类型：用 String() 转换更稳健（避免 toString() 在某些 Object 上返回 "[object Object]"）
    const str: string = String(val);
    const num: number = Number(str);
    if (!isNaN(num) && str.trim() !== '') {
      return num;
    }
    return defaultVal;
  }
}
