import { router } from '@kit.ArkUI'
import { getCurrentTheme, ThemeColors, THEME_LIST, ThemeColors as ThemeColorsType, switchTheme } from '../common/ThemeConstants'

@Entry
@Component
struct SettingsPage {
  @StorageProp('themeId') themeId: string = 'iron-forge'

  build() {
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
        Text('设置')
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
        Column() {
          this.ThemeSection()
          Row().width('100%').height(1).backgroundColor(this.t().borderColor)
            .margin({ top: this.t().cardSpacing, bottom: this.t().cardSpacing })
          this.SettingsMenu()
        }
        .padding({
          left: this.t().cardSpacing, right: this.t().cardSpacing,
          top: this.t().cardSpacing * 0.5, bottom: this.t().cardSpacing,
        })
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
    }
    .width('100%').height('100%')
    .backgroundColor(this.t().bgPrimary)
  }

  private t(): ThemeColors {
    return getCurrentTheme()
  }

  @Builder
  ThemeSection() {
    Column() {
      Row() {
        Text('🎨 风格主题')
          .fontSize(14 * this.t().fontSizeScale).fontWeight(this.t().fontWeightDisplay)
          .fontColor(this.t().textSecondary).letterSpacing(this.t().letterSpacingDisplay)
      }
      .width('100%').padding({ left: this.t().cardPadding, bottom: 12 })
      Grid() {
        ForEach(THEME_LIST, (theme: ThemeColorsType) => {
          GridItem() {
            this.ThemeCard(theme)
          }
        }, (theme: ThemeColorsType) => theme.id)
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(this.t().cardSpacing * 0.6)
      .rowsGap(this.t().cardSpacing * 0.6)
      .width('100%')
      .padding({ left: this.t().cardPadding, right: this.t().cardPadding })
    }
  }

  @Builder
  ThemeCard(theme: ThemeColorsType) {
    Column() {
      Column() {
        Row().width('100%').height(16)
          .borderRadius({ topLeft: theme.radiusSm, topRight: theme.radiusSm })
          .backgroundColor(theme.bgPrimary)
        Row().width('100%').height(16).backgroundColor(theme.accentPrimary)
        Row().width('100%').height(16)
          .borderRadius({ bottomLeft: theme.radiusSm, bottomRight: theme.radiusSm })
          .backgroundColor(theme.accentSecondary)
      }
      .width('100%').height(48)
      .borderRadius(theme.radiusSm)
      .borderWidth(1).borderStyle(BorderStyle.Solid).borderColor(this.t().borderColor)
      .clip(true)
      .margin({ bottom: 10 })
      Text(`${theme.icon} ${theme.name}`)
        .fontSize(13 * this.t().fontSizeScale).fontWeight(700)
        .fontColor(this.t().textPrimary).letterSpacing(this.t().letterSpacingDisplay * 0.5)
      Text(theme.desc)
        .fontSize(11 * this.t().fontSizeScale).fontColor(this.t().textSecondary).margin({ top: 2 })
    }
    .width('100%').padding(16)
    .borderRadius(this.t().radiusLg)
    .borderWidth(this.themeId === theme.id ? 2 : this.t().borderWidth)
    .borderStyle(BorderStyle.Solid)
    .borderColor(this.themeId === theme.id ? this.t().accentPrimary : this.t().borderColor)
    .backgroundColor(this.t().bgCard)
    .onClick(() => { switchTheme(theme.id) })
  }

  @Builder
  SettingsMenu() {
    Column({ space: 2 }) {
      this.MenuItem('🔔', '训练提醒')
      this.MenuItem('🌙', '深色模式')
      this.MenuItem('📱', '数据同步')
      this.MenuItem('🛡', '隐私设置')
      this.MenuItem('❓', '关于')
    }
  }

  @Builder
  MenuItem(icon: string, label: string) {
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
  }
}
