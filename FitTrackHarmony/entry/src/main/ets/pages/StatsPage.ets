import { getCurrentTheme, ThemeColors } from '../common/ThemeConstants'
import { CHART_DATA, MUSCLE_DISTRIBUTION, PERSONAL_RECORDS, ChartDataItem, MuscleDistributionItem, PersonalRecordItem } from '../common/MockData'
import { PageHeader } from '../components/PageHeader'
import { StatCard } from '../components/StatCard'
import { SectionHeader } from '../components/SectionHeader'

@Component
export struct StatsPage {
  @StorageProp('themeId') themeId: string = 'iron-forge'
  @State chartTab: string = 'weekly'

  build() {
    Column() {
      PageHeader({ title: '数据统计', subtitle: '追踪你的训练进步' })
      Scroll() {
        Column({ space: this.t().sectionGap }) {
          this.OverviewSection()
          this.TrainingFrequencySection()
          this.MuscleDistributionSection()
          this.PersonalRecordsSection()
        }
        .padding({
          left: this.t().cardSpacing, right: this.t().cardSpacing,
          top: this.t().cardSpacing * 0.6, bottom: this.t().cardSpacing * 0.6,
        })
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
    }
    .width('100%').height('100%')
  }

  private t(): ThemeColors {
    return getCurrentTheme()
  }

  @Builder
  OverviewSection() {
    Grid() {
      GridItem() { StatCard({ value: '30', label: '总训练', icon: '🔥', iconColor: 'red' }) }
      GridItem() { StatCard({ value: '40h', label: '总时长', icon: '⏱', iconColor: 'blue' }) }
      GridItem() { StatCard({ value: '48t', label: '总重量', icon: '🎯', iconColor: 'green' }) }
      GridItem() { StatCard({ value: '7.2k', label: '卡路里', icon: '⚡', iconColor: 'purple' }) }
    }
    .columnsTemplate('1fr 1fr').rowsTemplate('1fr 1fr')
    .columnsGap(this.t().cardSpacing).rowsGap(this.t().cardSpacing)
    .width('100%').height(280)
  }

  @Builder
  TrainingFrequencySection() {
    Column() {
      Row() {
        Text('训练频率')
          .fontSize(16 * this.t().fontSizeScale).fontWeight(this.t().fontWeightDisplay)
          .fontColor(this.t().textPrimary).letterSpacing(this.t().letterSpacingDisplay)
        Blank()
        Row({ space: 4 }) {
          Button('周')
            .height(28).fontSize(12 * this.t().fontSizeScale).fontWeight(600)
            .fontColor(this.chartTab === 'weekly' ? this.t().accentTextColor : this.t().textPrimary)
            .borderRadius(this.t().radiusBtn)
            .backgroundColor(this.chartTab === 'weekly' ? this.t().accentPrimary : this.t().bgElevated)
            .borderWidth(this.chartTab === 'weekly' ? 0 : this.t().borderWidth)
            .borderStyle(BorderStyle.Solid).borderColor(this.t().borderColor)
            .onClick(() => { this.chartTab = 'weekly' })
          Button('月')
            .height(28).fontSize(12 * this.t().fontSizeScale).fontWeight(600)
            .fontColor(this.chartTab === 'monthly' ? this.t().accentTextColor : this.t().textPrimary)
            .borderRadius(this.t().radiusBtn)
            .backgroundColor(this.chartTab === 'monthly' ? this.t().accentPrimary : this.t().bgElevated)
            .borderWidth(this.chartTab === 'monthly' ? 0 : this.t().borderWidth)
            .borderStyle(BorderStyle.Solid).borderColor(this.t().borderColor)
            .onClick(() => { this.chartTab = 'monthly' })
        }
      }
      .width('100%').margin({ bottom: this.t().cardSpacing * 0.7 })
      Row() {
        ForEach(CHART_DATA, (item: ChartDataItem) => {
          Column() {
            Column()
              .width('100%')
              .height(item.value * 1.5)
              .borderRadius({ topLeft: 4, topRight: 4 })
              .linearGradient({
                direction: GradientDirection.Top,
                colors: [[this.t().accentPrimary, 0.0], [this.t().accentSecondary, 1.0]]
              })
            Text(item.label)
              .fontSize(10 * this.t().fontSizeScale).fontColor(this.t().textMuted).margin({ top: 4 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.End)
        }, (item: ChartDataItem) => item.label)
      }
      .width('100%').height(200)
      .padding({ top: 20, bottom: 10 })
      .alignItems(VerticalAlign.Bottom)
    }
    .width('100%').padding(this.t().cardPadding)
    .borderRadius(this.t().radiusLg)
    .borderWidth(this.t().borderWidth).borderStyle(BorderStyle.Solid).borderColor(this.t().borderColor)
    .backgroundColor(this.t().bgCard)
  }

  @Builder
  MuscleDistributionSection() {
    Column() {
      SectionHeader({ title: '肌群训练分布' })
      Row() {
        ForEach(MUSCLE_DISTRIBUTION, (item: MuscleDistributionItem) => {
          Column() {
            Stack() {
              Circle().width(60).height(60).fill(Color.Transparent)
                .stroke(item.color).strokeWidth(3)
              Text(`${item.pct}%`)
                .fontSize(14 * this.t().fontSizeScale).fontWeight(700).fontColor(item.color)
            }
            .margin({ bottom: 8 })
            Text(item.name)
              .fontSize(12 * this.t().fontSizeScale).fontColor(this.t().textSecondary)
          }
          .layoutWeight(1).alignItems(HorizontalAlign.Center)
        }, (item: MuscleDistributionItem) => item.name)
      }
      .width('100%').padding({ top: 16, bottom: 16 })
    }
    .width('100%').padding(this.t().cardPadding)
    .borderRadius(this.t().radiusLg)
    .borderWidth(this.t().borderWidth).borderStyle(BorderStyle.Solid).borderColor(this.t().borderColor)
    .backgroundColor(this.t().bgCard)
  }

  @Builder
  PersonalRecordsSection() {
    Column() {
      SectionHeader({ title: '个人记录' })
      Column() {
        ForEach(PERSONAL_RECORDS, (pr: PersonalRecordItem, idx: number) => {
          Row() {
            Column() {
              Text(pr.name)
                .fontSize(14 * this.t().fontSizeScale).fontColor(this.t().textSecondary)
              Text(`更新于 ${pr.date}`)
                .fontSize(11 * this.t().fontSizeScale).fontColor(this.t().textMuted)
            }
            .alignItems(HorizontalAlign.Start)
            Blank()
            Text(pr.weight)
              .fontSize(16 * this.t().fontSizeScale).fontWeight(700).fontColor(this.t().accentPrimary)
          }
          .width('100%')
          .padding({ top: 14, bottom: 14 })
          .borderWidth({ bottom: idx < PERSONAL_RECORDS.length - 1 ? 1 : 0 })
          .borderColor(this.t().borderColor)
        }, (pr: PersonalRecordItem) => pr.name)
      }
    }
    .width('100%').padding(this.t().cardPadding)
    .borderRadius(this.t().radiusLg)
    .borderWidth(this.t().borderWidth).borderStyle(BorderStyle.Solid).borderColor(this.t().borderColor)
    .backgroundColor(this.t().bgCard)
  }
}
