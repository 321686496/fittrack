import { router } from '@kit.ArkUI'
import { getCurrentTheme, ThemeColors } from '../common/ThemeConstants'
import {
  USER, TODAY_PLAN, WEEKLY_STATS, WEEKLY_CALENDAR, STREAK,
  RECENT_TRAININGS, PERSONAL_RECORDS, DAILY_TIP,
  WeeklyCalendarItem, RecentTrainingItem, PersonalRecordItem, getTodayDate, findActivePlan,
} from '../common/MockData'
import { PageHeader } from '../components/PageHeader'
import { ProgressIndicator } from '../components/ProgressIndicator'
import { TagBadge } from '../components/TagBadge'
import { StatCard } from '../components/StatCard'
import { SectionHeader } from '../components/SectionHeader'

@Component
export struct HomePage {
  @StorageProp('themeId') themeId: string = 'iron-forge'
  onNavigate: (page: string) => void = () => {}

  build() {
    Column() {
      PageHeader({
        title: `你好，${USER.name}`,
        subtitle: getTodayDate(),
      })
      Scroll() {
        Column({ space: this.t().sectionGap }) {
          this.TodayPlanCard()
          this.WeeklyStatsSection()
          this.WeeklyCalendarSection()
          this.StreakSection()
          this.RecentTrainingsSection()
          this.PersonalRecordsSection()
          this.DailyTipSection()
          this.CurrentPlanSection()
        }
        .padding({
          left: this.t().cardSpacing,
          right: this.t().cardSpacing,
          top: this.t().cardSpacing * 0.6,
          bottom: this.t().cardSpacing,
        })
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  private t(): ThemeColors {
    return getCurrentTheme()
  }

  private getTodayProgress(): number {
    return Math.round(TODAY_PLAN.completed / TODAY_PLAN.exerciseCount * 100)
  }

  private getActivePlanName(): string {
    const plan = findActivePlan()
    if (plan !== undefined) {
      return plan.name
    }
    return ''
  }

  private getActivePlanFreq(): string {
    const plan = findActivePlan()
    if (plan !== undefined) {
      return `${plan.frequency} · ${plan.difficulty}`
    }
    return ''
  }

  private getActivePlanBadge(): string {
    const plan = findActivePlan()
    if (plan !== undefined) {
      return plan.badge
    }
    return ''
  }

  private getActivePlanWeekInfo(): string {
    const plan = findActivePlan()
    if (plan !== undefined) {
      return `第${plan.week}周 / 共${plan.totalWeeks}周`
    }
    return ''
  }

  private getActivePlanProgress(): number {
    const plan = findActivePlan()
    if (plan !== undefined) {
      return plan.progress
    }
    return 0
  }

  private getActivePlanProgressText(): string {
    const plan = findActivePlan()
    if (plan !== undefined) {
      return `${plan.progress}%`
    }
    return '0%'
  }

  private getActivePlanRemaining(): string {
    const plan = findActivePlan()
    if (plan !== undefined) {
      return `预计还需${plan.totalWeeks - plan.week}周完成`
    }
    return ''
  }

  @Builder
  TodayPlanCard() {
    Column() {
      Column() {
        Text(TODAY_PLAN.name)
          .fontSize(15 * this.t().fontSizeScale)
          .fontWeight(this.t().fontWeightDisplay)
          .fontColor(this.t().textPrimary)
          .letterSpacing(this.t().letterSpacingDisplay)
          .margin({ bottom: 4 })
        Text(TODAY_PLAN.muscle)
          .fontSize(12 * this.t().fontSizeScale)
          .fontColor(this.t().textSecondary)
      }
      .alignItems(HorizontalAlign.Start)
      .borderWidth({ left: 4 })
      .borderColor(this.t().accentPrimary)
      .padding({ left: 16 })
      .width('100%')
      .margin({ bottom: this.t().cardSpacing * 0.5 })

      Row({ space: 20 }) {
        Row({ space: 6 }) {
          Text('⏱').fontSize(14).fontColor(this.t().accentPrimary)
          Text(`~${TODAY_PLAN.duration}min`)
            .fontSize(13 * this.t().fontSizeScale)
            .fontColor(this.t().textSecondary)
        }
        Row({ space: 6 }) {
          Text('🏋').fontSize(14).fontColor(this.t().accentPrimary)
          Text(`${TODAY_PLAN.exerciseCount}个动作`)
            .fontSize(13 * this.t().fontSizeScale)
            .fontColor(this.t().textSecondary)
        }
      }
      .margin({ bottom: 16 })

      Row() {
        Text('训练进度')
          .fontSize(12 * this.t().fontSizeScale)
          .fontColor(this.t().textSecondary)
        Blank()
        Text(`${TODAY_PLAN.completed}/${TODAY_PLAN.exerciseCount}`)
          .fontSize(12 * this.t().fontSizeScale)
          .fontColor(this.t().accentPrimary)
          .fontWeight(700)
      }
      .width('100%')
      .margin({ bottom: 6 })

      ProgressIndicator({ progress: this.getTodayProgress() })

      Button(TODAY_PLAN.completed > 0 ? '继续训练' : '开始训练')
        .width('100%')
        .height(44)
        .fontSize(14 * this.t().fontSizeScale)
        .fontWeight(700)
        .fontColor(this.t().accentTextColor)
        .borderRadius(this.t().radiusBtn)
        .linearGradient({
          direction: GradientDirection.Right,
          colors: [[this.t().accentPrimary, 0.0], [this.t().accentSecondary, 1.0]]
        })
        .margin({ top: 16 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/TrainingPage' }).then(() => {}).catch(() => {})
        })
    }
    .width('100%')
    .padding(this.t().cardPadding)
    .borderRadius(this.t().radiusLg)
    .borderWidth(this.t().borderWidth)
    .borderStyle(BorderStyle.Solid)
    .borderColor(this.t().borderColor)
    .backgroundColor(this.t().bgCard)
  }

  @Builder
  WeeklyStatsSection() {
    Column() {
      SectionHeader({
        title: '本周数据',
        moreText: '全部数据',
        onMore: () => { this.onNavigate('stats') }
      })
      Grid() {
        GridItem() {
          StatCard({ value: `${WEEKLY_STATS.trainings}`, label: '训练次数', icon: '🔥', iconColor: 'red' })
        }
        GridItem() {
          StatCard({ value: WEEKLY_STATS.duration, label: '训练时长', icon: '⏱', iconColor: 'blue' })
        }
        GridItem() {
          StatCard({ value: WEEKLY_STATS.weight, label: '总重量', icon: '🎯', iconColor: 'green' })
        }
        GridItem() {
          StatCard({ value: WEEKLY_STATS.calories, label: '消耗', icon: '⚡', iconColor: 'purple' })
        }
      }
      .columnsTemplate('1fr 1fr')
      .rowsTemplate('1fr 1fr')
      .columnsGap(this.t().cardSpacing)
      .rowsGap(this.t().cardSpacing)
      .width('100%')
      .height(280)
    }
  }

  @Builder
  WeeklyCalendarSection() {
    Column() {
      SectionHeader({ title: '本周训练日历' })
      Row() {
        ForEach(WEEKLY_CALENDAR, (item: WeeklyCalendarItem) => {
          Column({ space: 6 }) {
            Text(item.day)
              .fontSize(11 * this.t().fontSizeScale)
              .fontColor(item.today ? this.t().accentPrimary : this.t().textSecondary)
              .fontWeight(600)
            Stack() {
              Circle()
                .width(10)
                .height(10)
                .fill(Color.Transparent)
                .stroke(item.done ? this.t().success : item.today ? this.t().accentPrimary : this.t().textMuted)
                .strokeWidth(2)
              if (item.done) {
                Circle().width(10).height(10).fill(this.t().success)
              } else if (item.today) {
                Circle().width(10).height(10).fill(this.t().accentPrimary)
              }
            }
            .width(20)
            .height(20)
            Text(item.rest ? '休息' : item.done ? '已练' : item.label)
              .fontSize(9 * this.t().fontSizeScale)
              .fontColor(item.done ? this.t().success : item.today ? this.t().accentPrimary : this.t().textMuted)
              .fontWeight(item.today ? 600 : 400)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .padding({ top: 12, bottom: 12, left: 4, right: 4 })
          .borderRadius(this.t().radiusLg)
          .borderWidth(this.t().borderWidth)
          .borderStyle(BorderStyle.Solid)
          .borderColor(item.today ? this.t().accentPrimary : this.t().borderColor)
          .backgroundColor(item.today ? this.t().accentGlow : this.t().bgCard)
          .opacity(item.rest ? 0.5 : item.done ? 0.85 : 1)
        }, (item: WeeklyCalendarItem) => item.day)
      }
      .width('100%')
    }
  }

  @Builder
  StreakSection() {
    Column() {
      SectionHeader({ title: '连续打卡' })
      Column() {
        Row({ space: 8 }) {
          Text('🔥').fontSize(28)
          Text(`${STREAK.current}`)
            .fontSize(40 * this.t().fontSizeScale)
            .fontWeight(800)
            .fontColor(this.t().accentPrimary)
          Text('天连续训练')
            .fontSize(13 * this.t().fontSizeScale)
            .fontColor(this.t().textSecondary)
        }
        .margin({ bottom: 16 })
        Row({ space: 20 }) {
          Column() {
            Text(`${STREAK.longest}`)
              .fontSize(16 * this.t().fontSizeScale).fontWeight(700).fontColor(this.t().textPrimary)
            Text('最长纪录')
              .fontSize(11 * this.t().fontSizeScale).fontColor(this.t().textSecondary).margin({ top: 2 })
          }
          Row().width(1).height(28).backgroundColor(this.t().borderColor)
          Column() {
            Text(`${STREAK.thisMonth}/${STREAK.monthTotal}`)
              .fontSize(16 * this.t().fontSizeScale).fontWeight(700).fontColor(this.t().textPrimary)
            Text('本月训练')
              .fontSize(11 * this.t().fontSizeScale).fontColor(this.t().textSecondary).margin({ top: 2 })
          }
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .padding(this.t().cardPadding)
      .borderRadius(this.t().radiusLg)
      .borderWidth(this.t().borderWidth).borderStyle(BorderStyle.Solid).borderColor(this.t().borderColor)
      .backgroundColor(this.t().bgCard)
    }
  }

  @Builder
  RecentTrainingsSection() {
    Column() {
      SectionHeader({ title: '最近训练', moreText: '更多', onMore: () => { this.onNavigate('stats') } })
      Column({ space: this.t().cardSpacing * 0.5 }) {
        ForEach(RECENT_TRAININGS, (rt: RecentTrainingItem) => {
          Row() {
            Row({ space: 12 }) {
              Text('🏋')
                .fontSize(16).width(36).height(36).textAlign(TextAlign.Center)
                .borderRadius(this.t().radiusMd).backgroundColor(this.t().accentGlow)
                .fontColor(this.t().accentPrimary)
              Column() {
                Text(rt.name)
                  .fontSize(14 * this.t().fontSizeScale).fontWeight(600).fontColor(this.t().textPrimary)
                  .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`⏱ ${rt.duration} · ${rt.exercises}个动作`)
                  .fontSize(11 * this.t().fontSizeScale).fontColor(this.t().textMuted).margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Start)
            }
            .layoutWeight(1)
            Column() {
              Text(`${rt.calories}`)
                .fontSize(18 * this.t().fontSizeScale).fontWeight(800).fontColor(this.t().accentPrimary)
              Text('千卡')
                .fontSize(10 * this.t().fontSizeScale).fontColor(this.t().textMuted).margin({ top: 1 })
            }
            .alignItems(HorizontalAlign.End)
          }
          .width('100%')
          .padding(this.t().cardPadding)
          .borderRadius(this.t().radiusLg)
          .borderWidth(this.t().borderWidth).borderStyle(BorderStyle.Solid).borderColor(this.t().borderColor)
          .backgroundColor(this.t().bgCard)
        }, (rt: RecentTrainingItem) => rt.id)
      }
    }
  }

  @Builder
  PersonalRecordsSection() {
    Column() {
      SectionHeader({ title: '个人最佳', moreText: '全部', onMore: () => { this.onNavigate('stats') } })
      Row() {
        ForEach(PERSONAL_RECORDS, (pr: PersonalRecordItem) => {
          Column() {
            Text('🏆')
              .fontSize(16).width(32).height(32).textAlign(TextAlign.Center)
              .borderRadius(this.t().radiusMd).backgroundColor(this.t().accentGlow)
              .fontColor(this.t().accentPrimary)
            Text(pr.name)
              .fontSize(12 * this.t().fontSizeScale).fontColor(this.t().textSecondary).margin({ top: 8, bottom: 4 })
            Text(pr.weight)
              .fontSize(20 * this.t().fontSizeScale).fontWeight(800).fontColor(this.t().accentPrimary)
            Text(pr.date)
              .fontSize(10 * this.t().fontSizeScale).fontColor(this.t().textMuted).margin({ top: 4 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .padding(this.t().cardPadding * 0.8)
          .borderRadius(this.t().radiusLg)
          .borderWidth(this.t().borderWidth).borderStyle(BorderStyle.Solid).borderColor(this.t().borderColor)
          .backgroundColor(this.t().bgCard)
        }, (pr: PersonalRecordItem) => pr.name)
      }
      .width('100%')
    }
  }

  @Builder
  DailyTipSection() {
    Column() {
      SectionHeader({ title: '每日建议' })
      Row() {
        Row()
          .width(4)
          .height('100%')
          .borderRadius(this.t().radiusProgress)
          .linearGradient({
            direction: GradientDirection.Bottom,
            colors: [[this.t().accentPrimary, 0.0], [this.t().accentSecondary, 1.0]]
          })
        Column() {
          Text(DAILY_TIP.category)
            .fontSize(10 * this.t().fontSizeScale).fontWeight(600)
            .fontColor(this.t().accentPrimary).backgroundColor(this.t().accentGlow)
            .borderRadius(this.t().radiusBadge)
            .padding({ left: 10, right: 10, top: 3, bottom: 3 })
            .margin({ bottom: 10 })
          Text(DAILY_TIP.text)
            .fontSize(14 * this.t().fontSizeScale).fontColor(this.t().textPrimary).lineHeight(22)
            .padding({ left: 12 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding(this.t().cardPadding)
      .borderRadius(this.t().radiusLg)
      .borderWidth(this.t().borderWidth).borderStyle(BorderStyle.Solid).borderColor(this.t().borderColor)
      .backgroundColor(this.t().bgCard)
    }
  }

  @Builder
  CurrentPlanSection() {
    Column() {
      SectionHeader({ title: '当前计划', moreText: '查看全部', onMore: () => { this.onNavigate('plan') } })
      Column() {
        Row() {
          Column() {
            Text(this.getActivePlanName())
              .fontSize(15 * this.t().fontSizeScale)
              .fontWeight(this.t().fontWeightDisplay)
              .fontColor(this.t().textPrimary)
              .letterSpacing(this.t().letterSpacingDisplay)
              .margin({ bottom: 4 })
            Text(this.getActivePlanFreq())
              .fontSize(12 * this.t().fontSizeScale).fontColor(this.t().textSecondary)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          TagBadge({ text: this.getActivePlanBadge(), type: 'accent' })
        }
        .width('100%')
        .margin({ bottom: 14 })

        Row() {
          Text(this.getActivePlanWeekInfo())
            .fontSize(12 * this.t().fontSizeScale).fontColor(this.t().textSecondary)
          Blank()
          Text(this.getActivePlanProgressText())
            .fontSize(12 * this.t().fontSizeScale).fontColor(this.t().accentPrimary).fontWeight(700)
        }
        .width('100%')
        .margin({ bottom: 6 })
        ProgressIndicator({ progress: this.getActivePlanProgress() })

        Row() {
          Text('📅').fontSize(14).fontColor(this.t().textMuted).margin({ right: 4 })
          Text(this.getActivePlanRemaining())
            .fontSize(12 * this.t().fontSizeScale).fontColor(this.t().textMuted)
          Blank()
          Text('>').fontSize(16).fontColor(this.t().textMuted)
        }
        .width('100%')
        .padding({ top: 10 })
        .borderWidth({ top: 1 })
        .borderColor(this.t().borderColor)
        .margin({ top: 12 })
      }
      .width('100%')
      .padding(this.t().cardPadding)
      .borderRadius(this.t().radiusLg)
      .borderWidth(this.t().borderWidth).borderStyle(BorderStyle.Solid).borderColor(this.t().borderColor)
      .backgroundColor(this.t().bgCard)
      .onClick(() => { this.onNavigate('plan') })
    }
  }
}
