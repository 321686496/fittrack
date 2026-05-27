import { getCurrentTheme, ThemeColors } from '../common/ThemeConstants'

@Component
export struct ProgressIndicator {
  @StorageProp('themeId') themeId: string = 'iron-forge'
  progress: number = 0
  barHeight: number = 8

  build() {
    Stack() {
      Row()
        .width('100%')
        .height(this.barHeight)
        .borderRadius(this.getTheme().radiusProgress)
        .backgroundColor(this.getTheme().bgElevated)
        .borderWidth(1)
        .borderStyle(BorderStyle.Solid)
        .borderColor(this.getTheme().borderColor)

      Row()
        .width(`${this.progress}%`)
        .height(this.barHeight)
        .borderRadius(this.getTheme().radiusProgress)
        .linearGradient({
          direction: GradientDirection.Right,
          colors: [[this.getTheme().accentPrimary, 0.0], [this.getTheme().accentSecondary, 1.0]]
        })
    }
    .width('100%')
    .alignContent(Alignment.Start)
  }

  private getTheme(): ThemeColors {
    return getCurrentTheme()
  }
}
