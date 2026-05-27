import { getCurrentTheme, ThemeColors } from '../common/ThemeConstants'

@Component
export struct TagBadge {
  @StorageProp('themeId') themeId: string = 'iron-forge'
  text: string = ''
  type: string = 'accent'

  build() {
    Text(this.text)
      .fontSize(11 * this.getTheme().fontSizeScale)
      .fontWeight(600)
      .fontColor(this.getTypeColor())
      .backgroundColor(this.getTypeBg())
      .borderRadius(this.getTheme().radiusBadge)
      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
      .letterSpacing(this.getTheme().letterSpacingDisplay * 0.5)
  }

  private getTheme(): ThemeColors {
    return getCurrentTheme()
  }

  private getTypeColor(): ResourceColor {
    const t = this.getTheme()
    if (this.type === 'success') {
      return t.success
    } else if (this.type === 'info') {
      return t.info
    } else if (this.type === 'purple') {
      return t.purple
    }
    return t.accentPrimary
  }

  private getTypeBg(): ResourceColor {
    const t = this.getTheme()
    if (this.type === 'success') {
      return t.successBg
    } else if (this.type === 'info') {
      return t.infoBg
    } else if (this.type === 'purple') {
      return t.purpleBg
    }
    return t.accentGlow
  }
}
