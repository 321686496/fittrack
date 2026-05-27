import { getCurrentTheme, ThemeColors } from '../common/ThemeConstants'

@Component
export struct SectionHeader {
  @StorageProp('themeId') themeId: string = 'iron-forge'
  title: string = ''
  moreText: string = ''
  onMore: () => void = () => {}

  build() {
    Row() {
      Text(this.title)
        .fontSize(16 * this.getTheme().fontSizeScale)
        .fontWeight(this.getTheme().fontWeightDisplay)
        .fontColor(this.getTheme().textPrimary)
        .letterSpacing(this.getTheme().letterSpacingDisplay)

      Blank()

      if (this.moreText !== '') {
        Text(this.moreText)
          .fontSize(12 * this.getTheme().fontSizeScale)
          .fontColor(this.getTheme().accentPrimary)
          .fontWeight(500)
          .onClick(() => {
            this.onMore()
          })
      }
    }
    .width('100%')
    .padding({ bottom: 8 })
    .margin({ bottom: this.getTheme().cardSpacing * 0.7 })
  }

  private getTheme(): ThemeColors {
    return getCurrentTheme()
  }
}
