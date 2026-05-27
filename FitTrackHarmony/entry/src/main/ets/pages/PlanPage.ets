import { getCurrentTheme, ThemeColors } from '../common/ThemeConstants'
import { PLANS, PlanItem } from '../common/MockData'
import { PageHeader } from '../components/PageHeader'
import { ProgressIndicator } from '../components/ProgressIndicator'
import { TagBadge } from '../components/TagBadge'
import { router } from '@kit.ArkUI'

@Component
export struct PlanPage {
  @StorageProp('themeId') themeId: string = 'iron-forge'
  onNavigate: (page: string) => void = () => {}

  build() {
    Column() {
      PageHeader({ title: '训练计划', subtitle: '管理你的专属训练方案' })
      Scroll() {
        Column({ space: this.t().cardSpacing }) {
          ForEach(PLANS, (plan: PlanItem) => {
            this.PlanCard(plan)
          }, (plan: PlanItem) => plan.id)
        }
        .padding({
          left: this.t().cardSpacing,
          right: this.t().cardSpacing,
          top: this.t().cardSpacing * 0.6,
          bottom: this.t().cardSpacing * 0.6,
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

  private getBadgeType(status: string): string {
    if (status === 'active') {
      return 'accent'
    } else if (status === 'done') {
      return 'success'
    }
    return 'info'
  }

  @Builder
  PlanCard(plan: PlanItem) {
    Column() {
      Row() {
        Text(plan.name)
          .fontSize(14 * this.t().fontSizeScale).fontWeight(500).fontColor(this.t().textPrimary)
          .layoutWeight(1)
        TagBadge({ text: plan.badge, type: this.getBadgeType(plan.status) })
      }
      .width('100%')
      .margin({ bottom: 8 })
      Row({ space: 12 }) {
        Text(plan.frequency).fontSize(12 * this.t().fontSizeScale).fontColor(this.t().textSecondary)
        Text(`${plan.difficulty}难度`).fontSize(12 * this.t().fontSizeScale).fontColor(this.t().textSecondary)
        Text(plan.status === 'pending' ? `${plan.totalWeeks}周周期` : `第${plan.week}周`)
          .fontSize(12 * this.t().fontSizeScale).fontColor(this.t().textSecondary)
      }
      .margin({ bottom: plan.status !== 'pending' ? 12 : 0 })
      if (plan.status !== 'pending') {
        ProgressIndicator({ progress: plan.progress })
      }
    }
    .width('100%')
    .padding(this.t().cardPadding)
    .borderRadius(this.t().radiusLg)
    .borderWidth(this.t().borderWidth).borderStyle(BorderStyle.Solid).borderColor(this.t().borderColor)
    .backgroundColor(this.t().bgCard)
    .onClick(() => {
      if (plan.status === 'active') {
        router.pushUrl({ url: 'pages/TrainingPage' }).then(() => {}).catch(() => {})
      }
    })
  }
}
