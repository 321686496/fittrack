let storage: LocalStorage = LocalStorage.getShared()

@Entry(storage)
@Component
struct FitTrackWidget {
  // 模式
  @LocalStorageProp('mode') mode: string = 'idle'
  // 空闲态字段
  @LocalStorageProp('todayTrainings') todayTrainings: number = 0
  @LocalStorageProp('todayDuration') todayDuration: number = 0
  @LocalStorageProp('todayWeight') todayWeight: number = 0
  @LocalStorageProp('streak') streak: number = 0
  @LocalStorageProp('lastTraining') lastTraining: string = ''
  @LocalStorageProp('lastDate') lastDate: string = ''
  // 训练态字段
  @LocalStorageProp('exerciseName') exerciseName: string = ''
  @LocalStorageProp('currentSet') currentSet: number = 1
  @LocalStorageProp('totalSets') totalSets: number = 0
  @LocalStorageProp('exerciseIndex') exerciseIndex: number = 1
  @LocalStorageProp('totalExercises') totalExercises: number = 0
  @LocalStorageProp('completedSets') completedSets: number = 0
  @LocalStorageProp('totalPlanSets') totalPlanSets: number = 0
  // 休息态字段
  @LocalStorageProp('restEndTime') restEndTime: number = 0
  @LocalStorageProp('restSeconds') restSeconds: number = 0
  @LocalStorageProp('totalRestSeconds') totalRestSeconds: number = 0
  // 主题颜色
  @LocalStorageProp('accentColor') accentColor: string = '#FF6B35'
  @LocalStorageProp('bgColor') bgColor: string = '#FFFFFF'
  @LocalStorageProp('textPrimaryColor') textPrimaryColor: string = '#222222'
  @LocalStorageProp('textSecondaryColor') textSecondaryColor: string = '#999999'
  // 训练提醒时间
  @LocalStorageProp('trainingTime') trainingTime: string = ''

  // 训练总进度
  private trainingProgress(): number {
    if (this.totalPlanSets <= 0) {
      return 0;
    }
    return this.completedSets / this.totalPlanSets;
  }

  build() {
    if (this.mode === 'rest') {
      this.RestView()
    } else if (this.mode === 'training') {
      this.TrainingView()
    } else {
      this.IdleView()
    }
  }

  // ============================================================
  // 空闲态：今日训练概要 + 训练提醒
  // ============================================================
  @Builder
  IdleView() {
    Column() {
      // 标题
      Row() {
        Text('LiftTrack')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimaryColor)
        Blank()
        Text('今日训练')
          .fontSize(10)
          .fontColor(this.textSecondaryColor)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 4 })

      // 数据指标
      Row() {
        Column() {
          Text(this.todayTrainings.toString())
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.accentColor)
          Text('训练次数')
            .fontSize(9)
            .fontColor(this.textSecondaryColor)
            .margin({ top: 2 })
        }
        .layoutWeight(1)

        Column() {
          Text(this.todayDuration.toString())
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.accentColor)
          Text('时长(分)')
            .fontSize(9)
            .fontColor(this.textSecondaryColor)
            .margin({ top: 2 })
        }
        .layoutWeight(1)

        Column() {
          Text(this.streak.toString())
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.accentColor)
          Text('连续(天)')
            .fontSize(9)
            .fontColor(this.textSecondaryColor)
            .margin({ top: 2 })
        }
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 6, bottom: 4 })

      // 最近训练
      if (this.lastTraining !== '') {
        Row() {
          Text('最近: ' + this.lastTraining)
            .fontSize(9)
            .fontColor(this.textSecondaryColor)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .padding({ left: 12, right: 12, bottom: 2 })
      }

      // 训练提醒时间
      if (this.trainingTime !== '') {
        Row() {
          Text('训练提醒 ' + this.trainingTime)
            .fontSize(9)
            .fontColor(this.accentColor)
        }
        .width('100%')
        .padding({ left: 12, right: 12, bottom: 4 })
      }

      // 底部操作按钮
      Row() {
        Text(this.trainingTime !== '' ? '开始训练 →' : '设置提醒时间')
          .fontSize(11)
          .fontColor(this.accentColor)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .padding({ left: 12, right: 12, bottom: 8 })
      .onClick(() => {
        postCardAction(this, {
          action: 'router',
          bundleName: 'com.lt.lifttrack',
          abilityName: 'EntryAbility',
          params: {
            targetPage: 'home'
          }
        });
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.bgColor)
    .borderRadius(16)
  }

  // ============================================================
  // 训练态：当前动作 + 组数进度
  // ============================================================
  @Builder
  TrainingView() {
    Column() {
      // 标题
      Row() {
        Text('训练中')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.accentColor)
        Blank()
        Text(this.exerciseIndex + '/' + this.totalExercises)
          .fontSize(10)
          .fontColor(this.textSecondaryColor)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 2 })

      // 动作名
      Text(this.exerciseName)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textPrimaryColor)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .padding({ left: 12, right: 12 })

      // 组数进度
      Text('第' + this.currentSet + '/' + this.totalSets + '组')
        .fontSize(13)
        .fontColor(this.accentColor)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .padding({ left: 12, right: 12, top: 4 })

      // 总进度条
      Row() {
        Progress({ value: this.trainingProgress(), total: 100, type: ProgressType.Linear })
          .width('100%')
          .height(4)
          .color(this.accentColor)
          .style({ strokeWidth: 4, strokeRadius: 2 })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 6, bottom: 4 })

      // 总进度文字
      Text('总进度 ' + this.completedSets + '/' + this.totalPlanSets + '组')
        .fontSize(9)
        .fontColor(this.textSecondaryColor)
        .width('100%')
        .padding({ left: 12, right: 12, bottom: 6 })

      // 底部操作
      Row() {
        Text('回到应用 →')
          .fontSize(11)
          .fontColor(this.accentColor)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .padding({ left: 12, right: 12, bottom: 8 })
      .onClick(() => {
        postCardAction(this, {
          action: 'router',
          bundleName: 'com.lt.lifttrack',
          abilityName: 'EntryAbility',
          params: {
            targetPage: 'training',
            cardAction: 'resume'
          }
        });
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.bgColor)
    .borderRadius(16)
  }

  // ============================================================
  // 休息态：静态状态显示（倒计时由通知栏进度条通知展示）
  // ============================================================
  @Builder
  RestView() {
    Column() {
      // 标题
      Row() {
        Text('休息中')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.accentColor)
        Blank()
        Text(this.exerciseIndex + '/' + this.totalExercises)
          .fontSize(10)
          .fontColor(this.textSecondaryColor)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 2 })

      // 动作名
      Text(this.exerciseName)
        .fontSize(14)
        .fontColor(this.textSecondaryColor)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .padding({ left: 12, right: 12 })

      // 提示：倒计时见通知栏
      Text('休息倒计时')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.accentColor)
        .width('100%')
        .padding({ left: 12, right: 12, top: 8 })
        .textAlign(TextAlign.Center)

      Text('请查看通知栏')
        .fontSize(10)
        .fontColor(this.textSecondaryColor)
        .width('100%')
        .textAlign(TextAlign.Center)

      // 下一组信息
      Text('下一组: 第' + this.currentSet + '/' + this.totalSets + '组')
        .fontSize(10)
        .fontColor(this.textSecondaryColor)
        .width('100%')
        .padding({ left: 12, right: 12, top: 8, bottom: 4 })

      // 操作按钮
      Row() {
        Text('结束休息，开始下一组 →')
          .fontSize(11)
          .fontColor(this.accentColor)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .padding({ left: 12, right: 12, bottom: 8 })
      .onClick(() => {
        postCardAction(this, {
          action: 'router',
          bundleName: 'com.lt.lifttrack',
          abilityName: 'EntryAbility',
          params: {
            targetPage: 'training',
            cardAction: 'skipRest'
          }
        });
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.bgColor)
    .borderRadius(16)
  }
}
