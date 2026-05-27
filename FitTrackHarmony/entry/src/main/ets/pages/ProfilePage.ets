import { getCurrentTheme, ThemeColors } from '../common/ThemeConstants'
import { ACHIEVEMENTS, BODY_DATA, AchievementItem } from '../common/MockData'
import { SectionHeader } from '../components/SectionHeader'
import { router } from '@kit.ArkUI'

@Component
export struct ProfilePage {
  @StorageProp('themeId') themeId: string = 'iron-forge'
  onNavigate: (page: string) => void = () => {}

  build() {
    Column() {
      Scroll() {
        Column() {
          this.ProfileHeader()
          this.AchievementsSection()
          this.BodyDataSection()
          Row().width('100%').height(1).backgroundColor(this.t().borderColor)
            .margin({ top: this.t().cardSpacing, bottom: this.t().cardSpacing })
          this.MenuList()
          Row().width('100%').height(1).backgroundColor(this.t().borderColor)
            .margin({ top: this.t().cardSpacing, bottom: this.t().cardSpacing })
          this.LogoutButton()
        }
        .padding({
          left: this.t().cardSpacing, right: this.t().cardSpacing,
          top: this.t().cardSpacing, bottom: this.t().cardSpacing,
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

  private getUnlockedCount(): number {
    let count = 0
    for (const a of ACHIEVEMENTS) {
      if (a.unlocked) {
        count++
      }
    }
    return count
  }

  private getUnlockedText(): string {
    return `${this.getUnlockedCount()}/${ACHIEVEMENTS.length} 已解锁`
  }

  @Builder
  ProfileHeader() {
    Column({ space: 12 }) {
      Stack() {
        Text('👤')
          .fontSize(40).fontColor(this.t().accentPrimary)
      }
      .width(80).height(80)
      .borderRadius(this.t().radiusAvatar)
      .borderWidth(2).borderStyle(BorderStyle.Solid).borderColor(this.t().accentPrimary)
      .backgroundColor(this.t().accentGlow)
      .alignContent(Alignment.Center)
      Text('健身达人')
        .fontSize(20 * this.t().fontSizeScale).fontWeight(this.t().fontWeightDisplay)
        .fontColor(this.t().textPrimary).letterSpacing(this.t().letterSpacingDisplay)
      Text('user@fitplan.pro')
        .fontSize(13 * this.t().fontSizeScale).fontColor(this.t().textSecondary)
    }
    .width('100%').alignItems(HorizontalAlign.Center)
    .padding({ top: this.t().cardSpacing * 1.2, bottom: this.t().cardSpacing * 1.2 })
  }

  @Builder
  AchievementsSection() {
    Column() {
      Row() {
        Text('训练成就')
          .fontSize(16 * this.t().fontSizeScale).fontWeight(this.t().fontWeightDisplay)
          .fontColor(this.t().textPrimary).letterSpacing(this.t().letterSpacingDisplay)
        Blank()
        Text(this.getUnlockedText())
          .fontSize(12 * this.t().fontSizeScale).fontColor(this.t().accentPrimary)
      }
      .width('100%').margin({ bottom: this.t().cardSpacing * 0.7 })
      Grid() {
        ForEach(ACHIEVEMENTS, (a: AchievementItem) => {
          GridItem() {
            Column({ space: 4 }) {
              Text(a.icon).fontSize(24)
              Text(a.name)
                .fontSize(11 * this.t().fontSizeScale).fontWeight(700)
                .fontColor(this.t().textPrimary).letterSpacing(this.t().letterSpacingDisplay * 0.5)
              Text(a.desc)
                .fontSize(10 * this.t().fontSizeScale).fontColor(this.t().textSecondary)
                .textAlign(TextAlign.Center).lineHeight(13)
            }
            .alignItems(HorizontalAlign.Center)
            .padding({ top: 14, bottom: 14, left: 8, right: 8 })
            .borderRadius(this.t().radiusLg)
            .borderWidth(this.t().borderWidth).borderStyle(BorderStyle.Solid).borderColor(this.t().borderColor)
            .backgroundColor(this.t().bgCard)
            .opacity(a.unlocked ? 1 : 0.45)
          }
        }, (a: AchievementItem) => a.id)
      }
      .columnsTemplate('1fr 1fr 1fr')
      .columnsGap(this.t().cardSpacing * 0.5)
      .rowsGap(this.t().cardSpacing * 0.5)
      .width('100%')
    }
    .margin({ bottom: this.t().sectionGap })
  }

  @Builder
  BodyDataSection() {
    Column() {
      Row() {
        Text('身体数据')
          .fontSize(16 * this.t().fontSizeScale).fontWeight(this.t().fontWeightDisplay)
          .fontColor(this.t().textPrimary).letterSpacing(this.t().letterSpacingDisplay)
        Blank()
        Text(`更新于 ${BODY_DATA.lastUpdate}`)
          .fontSize(12 * this.t().fontSizeScale).fontColor(this.t().textSecondary)
      }
      .width('100%').margin({ bottom: this.t().cardSpacing * 0.7 })
      Column() {
        Grid() {
          GridItem() { this.BodyItem(`${BODY_DATA.height}`, '身高cm') }
          GridItem() { this.BodyItem(`${BODY_DATA.weight}`, '体重kg') }
          GridItem() { this.BodyItem(`${BODY_DATA.bmi}`, 'BMI') }
          GridItem() { this.BodyItem(`${BODY_DATA.bodyFat}`, '体脂率%') }
        }
        .columnsTemplate('1fr 1fr 1fr 1fr').columnsGap(8).width('100%')
        Row().width('100%').height(1).backgroundColor(this.t().borderColor).margin({ top: 12, bottom: 12 })
        Grid() {
          GridItem() { this.BodyDetailItem('胸围', `${BODY_DATA.chest}cm`) }
          GridItem() { this.BodyDetailItem('腰围', `${BODY_DATA.waist}cm`) }
          GridItem() { this.BodyDetailItem('臀围', `${BODY_DATA.hip}cm`) }
        }
        .columnsTemplate('1fr 1fr 1fr').columnsGap(8).width('100%')
      }
      .width('100%').padding(this.t().cardPadding)
      .borderRadius(this.t().radiusLg)
      .borderWidth(this.t().borderWidth).borderStyle(BorderStyle.Solid).borderColor(this.t().borderColor)
      .backgroundColor(this.t().bgCard)
    }
  }

  @Builder
  BodyItem(value: string, label: string) {
    Column() {
      Text(value)
        .fontSize(20 * this.t().fontSizeScale).fontWeight(800).fontColor(this.t().accentPrimary)
      Text(label)
        .fontSize(10 * this.t().fontSizeScale).fontColor(this.t().textSecondary).margin({ top: 2 })
    }
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  BodyDetailItem(label: string, value: string) {
    Column({ space: 2 }) {
      Text(label)
        .fontSize(11 * this.t().fontSizeScale).fontColor(this.t().textSecondary)
      Text(value)
        .fontSize(15 * this.t().fontSizeScale).fontWeight(700).fontColor(this.t().textPrimary)
    }
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  MenuList() {
    Column({ space: 2 }) {
      this.MenuItem('⚙', '设置', true)
      this.MenuItem('🔔', '提醒设置', false)
      this.MenuItem('📱', '设备连接', false)
      this.MenuItem('🛡', '隐私与安全', false)
      this.MenuItem('❓', '帮助与反馈', false)
    }
  }

  @Builder
  MenuItem(icon: string, label: string, isSettings: boolean) {
    Row() {
      Row({ space: 12 }) {
        Text(icon)
          .fontSize(18).width(36).height(36).textAlign(TextAlign.Center)
          .borderRadius(this.t().radiusMd).backgroundColor(this.t().bgElevated)
        Text(label)
          .fontSize(14 * this.t().fontSizeScale).fontColor(this.t().textPrimary)
      }
      Blank()
      Text('>').fontSize(16).fontColor(this.t().textMuted)
    }
    .width('100%')
    .padding({ left: this.t().cardPadding, right: this.t().cardPadding, top: 14, bottom: 14 })
    .borderRadius(this.t().radiusMd)
    .onClick(() => {
      if (isSettings) {
        router.pushUrl({ url: 'pages/SettingsPage' }).then(() => {}).catch(() => {})
      }
    })
  }

  @Builder
  LogoutButton() {
    Row() {
      Text('🚪')
        .fontSize(18).fontColor(this.t().accentPrimary).width(36).height(36)
        .textAlign(TextAlign.Center).borderRadius(this.t().radiusMd).backgroundColor(this.t().bgElevated)
      Text('退出登录')
        .fontSize(14 * this.t().fontSizeScale).fontColor(this.t().accentPrimary).margin({ left: 12 })
    }
    .width('100%')
    .padding({ left: this.t().cardPadding, right: this.t().cardPadding, top: 14, bottom: 14 })
    .borderRadius(this.t().radiusMd)
  }
}
