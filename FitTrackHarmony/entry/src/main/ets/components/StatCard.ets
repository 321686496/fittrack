import { getCurrentTheme, ThemeColors } from '../common/ThemeConstants'

@Component
export struct StatCard {
  @StorageProp('themeId') themeId: string = 'iron-forge'
  value: string = ''
  label: string = ''
  icon: string = ''
  iconColor: string = ''

  build() {
    Column() {
      Row() {
        Text(this.icon)
          .fontSize(20)
          .fontColor(this.getIconTextColor())
      }
      .width(40)
      .height(40)
      .borderRadius(12)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(this.getIconBgColor())
      .margin({ bottom: 12 })

      Text(this.value)
        .fontSize(28 * this.getTheme().fontSizeScale)
        .fontWeight(800)
        .fontColor(this.getTheme().textPrimary)
        .letterSpacing(this.getTheme().letterSpacingDisplay * 0.5)

      Text(this.label)
        .fontSize(12 * this.getTheme().fontSizeScale)
        .fontColor(this.getTheme().textSecondary)
        .margin({ top: 4 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding(this.getTheme().cardPadding)
    .borderRadius(this.getTheme().radiusLg)
    .borderWidth(this.getTheme().borderWidth)
    .borderStyle(BorderStyle.Solid)
    .borderColor(this.getTheme().borderColor)
    .backgroundColor(this.getTheme().bgCard)
  }

  private getTheme(): ThemeColors {
    return getCurrentTheme()
  }

  private getIconBgColor(): ResourceColor {
    const t = this.getTheme()
    if (this.iconColor === 'red') {
      return '#ef44441F'
    } else if (this.iconColor === 'green') {
      return t.successBg
    } else if (this.iconColor === 'blue') {
      return t.infoBg
    } else if (this.iconColor === 'purple') {
      return t.purpleBg
    }
    return t.bgElevated
  }

  private getIconTextColor(): ResourceColor {
    const t = this.getTheme()
    if (this.iconColor === 'red') {
      return '#ef4444'
    } else if (this.iconColor === 'green') {
      return t.success
    } else if (this.iconColor === 'blue') {
      return t.info
    } else if (this.iconColor === 'purple') {
      return t.purple
    }
    return t.textSecondary
  }
}
