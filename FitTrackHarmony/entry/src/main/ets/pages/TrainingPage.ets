import { router } from '@kit.ArkUI'
import { getCurrentTheme, ThemeColors } from '../common/ThemeConstants'
import { TODAY_PLAN, ExerciseItem } from '../common/MockData'
import { ProgressIndicator } from '../components/ProgressIndicator'
import { TagBadge } from '../components/TagBadge'

class RestLogEntry {
  exName: string = ''
  restPlanned: number = 0
  restActual: number = 0
}

@Entry
@Component
struct TrainingPage {
  @StorageProp('themeId') themeId: string = 'iron-forge'
  @State currentExIdx: number = 2
  @State completed: boolean[] = []
  @State weight: string = '55'
  @State reps: string = '12'
  @State showRest: boolean = false
  @State restSeconds: number = 90
  @State restLog: RestLogEntry[] = []
  @State trainingDone: boolean = false
  private timerId: number = -1

  aboutToAppear() {
    const arr: boolean[] = []
    for (const ex of TODAY_PLAN.exercises) {
      arr.push(ex.completed)
    }
    this.completed = arr
  }

  aboutToDisappear() {
    if (this.timerId !== -1) {
      clearInterval(this.timerId)
    }
  }

  private t(): ThemeColors {
    return getCurrentTheme()
  }

  private countCompleted(): number {
    let count = 0
    for (const c of this.completed) {
      if (c) {
        count++
      }
    }
    return count
  }

  private getCurrentExName(): string {
    if (this.currentExIdx < TODAY_PLAN.exercises.length) {
      return TODAY_PLAN.exercises[this.currentExIdx].name
    }
    return ''
  }

  private getCurrentExRestTime(): number {
    if (this.currentExIdx < TODAY_PLAN.exercises.length) {
      return TODAY_PLAN.exercises[this.currentExIdx].restTime
    }
    return 90
  }

  private getRestProgress(): number {
    if (this.restSeconds <= 0) {
      return 100
    }
    const planned = this.getCurrentExRestTime()
    const elapsed = planned - this.restSeconds
    return Math.round(elapsed / planned * 100)
  }

  private startRestTimer(restTime: number) {
    this.showRest = true
    this.restSeconds = restTime
    if (this.timerId !== -1) {
      clearInterval(this.timerId)
    }
    let sec = restTime
    this.timerId = setInterval(() => {
      sec -= 1
      this.restSeconds = sec
      if (sec <= 0) {
        clearInterval(this.timerId)
        this.timerId = -1
        this.showRest = false
        this.advanceToNext(restTime - sec)
      }
    }, 1000)
  }

  private advanceToNext(actualRest: number) {
    if (this.currentExIdx >= TODAY_PLAN.exercises.length) {
      return
    }
    const ex = TODAY_PLAN.exercises[this.currentExIdx]
    const entry = new RestLogEntry()
    entry.exName = ex.name
    entry.restPlanned = ex.restTime
    entry.restActual = actualRest
    this.restLog = [...this.restLog, entry]
    const updated = [...this.completed]
    updated[this.currentExIdx] = true
    this.completed = updated
    this.showRest = false
    if (this.currentExIdx + 1 >= TODAY_PLAN.exercises.length) {
      this.trainingDone = true
    } else {
      this.currentExIdx = this.currentExIdx + 1
    }
  }

  build() {
    Stack() {
      Column() {
        if (this.trainingDone) {
          this.TrainingCompleteView()
        } else {
          this.TrainingActiveView()
        }
      }
      .width('100%').height('100%')
      .backgroundColor(this.t().bgPrimary)

      if (this.showRest) {
        this.RestOverlay()
      }
    }
    .width('100%').height('100%')
  }

  @Builder
  TrainingCompleteView() {
    Column() {
      Row() {
        Button() {
          Text('<').fontSize(18).fontColor(this.t().textSecondary)
        }
        .width(40).height(40)
        .borderRadius(this.t().radiusMd)
        .borderWidth(this.t().borderWidth).borderStyle(BorderStyle.Solid).borderColor(this.t().borderColor)
        .backgroundColor(this.t().bgCard)
        .onClick(() => { router.back() })
        Text('完成')
          .fontSize(this.t().logoFontSize).fontWeight(this.t().fontWeightDisplay)
          .fontColor(this.t().textPrimary).letterSpacing(this.t().letterSpacingDisplay)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Row().width(40)
      }
      .width('100%')
      .padding({ left: this.t().cardPadding * 0.8, right: this.t().cardPadding * 0.8, top: 16, bottom: 16 })
      .backgroundColor(this.t().bgOverlay)
      .borderWidth({ bottom: 1 }).borderColor(this.t().borderColor)

      Column({ space: 16 }) {
        Text('✅').fontSize(32)
        Text('训练完成')
          .fontSize(20 * this.t().fontSizeScale).fontWeight(this.t().fontWeightDisplay).fontColor(this.t().textPrimary)
        Text('所有动作已完成')
          .fontSize(14 * this.t().fontSizeScale).fontColor(this.t().textSecondary)
        Button('返回首页')
          .width('80%')
          .height(44)
          .fontSize(14 * this.t().fontSizeScale).fontWeight(700).fontColor(this.t().accentTextColor)
          .borderRadius(this.t().radiusBtn)
          .linearGradient({
            direction: GradientDirection.Right,
            colors: [[this.t().accentPrimary, 0.0], [this.t().accentSecondary, 1.0]]
          })
          .onClick(() => { router.back() })
      }
      .layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    }
  }

  @Builder
  TrainingActiveView() {
    Column() {
      Row() {
        Button() {
          Text('<').fontSize(18).fontColor(this.t().textSecondary)
        }
        .width(40).height(40)
        .borderRadius(this.t().radiusMd)
        .borderWidth(this.t().borderWidth).borderStyle(BorderStyle.Solid).borderColor(this.t().borderColor)
        .backgroundColor(this.t().bgCard)
        .onClick(() => { router.back() })
        Text(this.getCurrentExName())
          .fontSize(this.t().logoFontSize).fontWeight(this.t().fontWeightDisplay)
          .fontColor(this.t().textPrimary).letterSpacing(this.t().letterSpacingDisplay)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Row().width(40)
      }
      .width('100%')
      .padding({ left: this.t().cardPadding * 0.8, right: this.t().cardPadding * 0.8, top: 16, bottom: 16 })
      .backgroundColor(this.t().bgOverlay)
      .borderWidth({ bottom: 1 }).borderColor(this.t().borderColor)

      Scroll() {
        Column({ space: this.t().cardSpacing }) {
          this.CurrentExerciseCard()
          this.RestLogSection()
          this.ExerciseListSection()
        }
        .padding({
          left: this.t().cardSpacing, right: this.t().cardSpacing,
          top: this.t().cardSpacing * 0.6, bottom: this.t().cardSpacing * 0.6,
        })
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
    }
  }

  @Builder
  CurrentExerciseCard() {
    Column() {
      Row() {
        Column() {
          Text(this.getCurrentExName())
            .fontSize(15 * this.t().fontSizeScale).fontWeight(this.t().fontWeightDisplay)
            .fontColor(this.t().textPrimary).letterSpacing(this.t().letterSpacingDisplay).margin({ bottom: 2 })
          Text(`第${this.currentExIdx + 1}个动作 / 共${TODAY_PLAN.exercises.length}个`)
            .fontSize(12 * this.t().fontSizeScale).fontColor(this.t().textSecondary)
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
        TagBadge({
          text: `${TODAY_PLAN.exercises[this.currentExIdx].sets}组 × ${TODAY_PLAN.exercises[this.currentExIdx].reps}次`,
          type: 'accent'
        })
      }
      .width('100%').margin({ bottom: 8 })

      Row({ space: 12 }) {
        Column() {
          Text('重量').fontSize(12 * this.t().fontSizeScale).fontColor(this.t().textSecondary).margin({ bottom: 4 })
          Row() {
            TextInput({ text: this.weight })
              .type(InputType.Number).width('100%').height(40)
              .fontSize(14 * this.t().fontSizeScale).fontColor(this.t().textPrimary)
              .backgroundColor(Color.Transparent).borderWidth(0)
              .onChange((val: string) => { this.weight = val })
            Text('kg').fontSize(12 * this.t().fontSizeScale).fontColor(this.t().textSecondary)
          }
          .borderRadius(this.t().radiusInput)
          .borderWidth(this.t().borderWidth).borderStyle(BorderStyle.Solid).borderColor(this.t().borderColor)
          .backgroundColor(this.t().bgElevated).padding({ right: 10 })
        }
        .layoutWeight(1)
        Column() {
          Text('次数').fontSize(12 * this.t().fontSizeScale).fontColor(this.t().textSecondary).margin({ bottom: 4 })
          Row() {
            TextInput({ text: this.reps })
              .type(InputType.Number).width('100%').height(40)
              .fontSize(14 * this.t().fontSizeScale).fontColor(this.t().textPrimary)
              .backgroundColor(Color.Transparent).borderWidth(0)
              .onChange((val: string) => { this.reps = val })
            Text('次').fontSize(12 * this.t().fontSizeScale).fontColor(this.t().textSecondary)
          }
          .borderRadius(this.t().radiusInput)
          .borderWidth(this.t().borderWidth).borderStyle(BorderStyle.Solid).borderColor(this.t().borderColor)
          .backgroundColor(this.t().bgElevated).padding({ right: 10 })
        }
        .layoutWeight(1)
      }
      .margin({ bottom: 16 })

      Button('完成本组')
        .width('100%').height(40)
        .fontSize(12 * this.t().fontSizeScale).fontWeight(700)
        .fontColor(this.t().success).borderRadius(this.t().radiusBtn)
        .borderWidth(this.t().borderWidth).borderStyle(BorderStyle.Solid).borderColor(this.t().success)
        .backgroundColor(this.t().successBg)
        .onClick(() => { this.startRestTimer(this.getCurrentExRestTime()) })
    }
    .width('100%').padding(this.t().cardPadding)
    .borderRadius(this.t().radiusLg)
    .borderWidth(this.t().borderWidth).borderStyle(BorderStyle.Solid).borderColor(this.t().borderColor)
    .backgroundColor(this.t().bgCard)
  }

  @Builder
  RestLogSection() {
    if (this.restLog.length > 0) {
      Column() {
        Text('休息记录')
          .fontSize(16 * this.t().fontSizeScale).fontWeight(this.t().fontWeightDisplay)
          .fontColor(this.t().textPrimary).letterSpacing(this.t().letterSpacingDisplay)
          .width('100%')
          .margin({ bottom: this.t().cardSpacing * 0.7 })
        Column({ space: 6 }) {
          ForEach(this.restLog, (log: RestLogEntry, idx: number) => {
            Row() {
              Text(log.exName)
                .fontSize(13 * this.t().fontSizeScale).fontWeight(500).fontColor(this.t().textPrimary)
                .layoutWeight(1)
              Row({ space: 4 }) {
                Text('⏱').fontSize(12)
                Text(`休息 ${log.restActual}秒`)
                  .fontSize(12 * this.t().fontSizeScale).fontColor(this.t().textSecondary)
                if (log.restActual < log.restPlanned) {
                  Text(`(提前${log.restPlanned - log.restActual}s)`)
                    .fontSize(12 * this.t().fontSizeScale).fontColor(this.t().warning).margin({ left: 6 })
                }
              }
            }
            .width('100%')
            .padding({ left: 14, right: 14, top: 10, bottom: 10 })
            .borderRadius(this.t().radiusMd)
            .borderWidth(1).borderStyle(BorderStyle.Solid).borderColor(this.t().borderColor)
            .backgroundColor(this.t().bgElevated)
          }, (log: RestLogEntry, idx: number) => `${idx}`)
        }
      }
    }
  }

  @Builder
  ExerciseListSection() {
    Column() {
      Row() {
        Text('动作列表')
          .fontSize(16 * this.t().fontSizeScale).fontWeight(this.t().fontWeightDisplay)
          .fontColor(this.t().textPrimary).letterSpacing(this.t().letterSpacingDisplay)
        Blank()
        Text(`${this.countCompleted()}/${TODAY_PLAN.exercises.length}`)
          .fontSize(12 * this.t().fontSizeScale).fontColor(this.t().textSecondary)
      }
      .width('100%').margin({ bottom: this.t().cardSpacing * 0.5 })
      Column({ space: this.t().cardSpacing * 0.5 }) {
        ForEach(TODAY_PLAN.exercises, (ex: ExerciseItem, idx: number) => {
          Row() {
            Text(this.completed[idx] ? '✓' : `${idx + 1}`)
              .fontSize(14 * this.t().fontSizeScale).fontWeight(700)
              .fontColor(this.completed[idx] ? this.t().success : this.t().accentPrimary)
              .width(28).textAlign(TextAlign.Center)
            Column() {
              Text(ex.name)
                .fontSize(14 * this.t().fontSizeScale).fontWeight(500).fontColor(this.t().textPrimary)
              Text(`${ex.sets}组 × ${ex.reps}次`)
                .fontSize(12 * this.t().fontSizeScale).fontColor(this.t().textSecondary)
            }
            .layoutWeight(1).alignItems(HorizontalAlign.Start)
            if (this.completed[idx]) {
              TagBadge({ text: '完成', type: 'success' })
            } else if (idx === this.currentExIdx) {
              TagBadge({ text: '进行中', type: 'accent' })
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .borderRadius(this.t().radiusMd)
          .borderWidth(1).borderStyle(BorderStyle.Solid)
          .borderColor(idx === this.currentExIdx ? this.t().accentPrimary : this.t().borderColor)
          .backgroundColor(idx === this.currentExIdx ? this.t().accentGlow : this.t().bgElevated)
        }, (ex: ExerciseItem) => ex.id)
      }
    }
  }

  @Builder
  RestOverlay() {
    Stack() {
      Column() {
        Text('组间休息')
          .fontSize(14 * this.t().fontSizeScale).fontWeight(this.t().fontWeightDisplay)
          .fontColor(this.t().textSecondary).letterSpacing(this.t().letterSpacingDisplay).margin({ bottom: 16 })
        Text(`${this.restSeconds}`)
          .fontSize(64 * this.t().fontSizeScale).fontWeight(800).fontColor(this.t().accentPrimary)
        Text('秒后继续')
          .fontSize(13 * this.t().fontSizeScale).fontColor(this.t().textSecondary).margin({ bottom: 20 })
        ProgressIndicator({ progress: this.getRestProgress(), barHeight: 4 })
        Button('跳过休息')
          .height(44)
          .fontSize(14 * this.t().fontSizeScale).fontWeight(700).fontColor(this.t().accentTextColor)
          .borderRadius(this.t().radiusBtn)
          .linearGradient({
            direction: GradientDirection.Right,
            colors: [[this.t().accentPrimary, 0.0], [this.t().accentSecondary, 1.0]]
          })
          .margin({ top: 24 })
          .onClick(() => {
            if (this.timerId !== -1) {
              clearInterval(this.timerId)
              this.timerId = -1
            }
            const planned = this.getCurrentExRestTime()
            const actual = planned - this.restSeconds
            this.advanceToNext(actual)
          })
      }
      .width(280)
      .padding({ top: 40, bottom: 40, left: 32, right: 32 })
      .borderRadius(this.t().radiusXl)
      .borderWidth(this.t().borderWidth).borderStyle(BorderStyle.Solid).borderColor(this.t().borderColor)
      .backgroundColor(this.t().bgCard)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%').height('100%')
    .backgroundColor('#000000AA')
    .alignContent(Alignment.Center)
    .position({ x: 0, y: 0 })
    .zIndex(300)
  }
}
