import { getCurrentTheme, ThemeColors } from '../common/ThemeConstants'

@Component
export struct PageHeader {
  @StorageProp('themeId') themeId: string = 'iron-forge'
  title: string = ''
  subtitle: string = ''
  showBack: boolean = false
  onBack: () => void = () => {}
  onBell: () => void = () => {}
  onCalendar: () => void = () => {}

  build() {
    Row() {
      if (this.showBack) {
        Button() {
          Text('<')
            .fontSize(18)
            .fontColor(this.getTheme().textSecondary)
        }
        .width(40)
        .height(40)
        .borderRadius(this.getTheme().radiusMd)
        .borderWidth(this.getTheme().borderWidth)
        .borderStyle(BorderStyle.Solid)
        .borderColor(this.getTheme().borderColor)
        .backgroundColor(this.getTheme().bgCard)
        .onClick(() => {
          this.onBack()
        })

        Blank()

        Text(this.title)
          .fontSize(this.getTheme().logoFontSize)
          .fontWeight(this.getTheme().fontWeightDisplay)
          .fontColor(this.getTheme().textPrimary)
          .letterSpacing(this.getTheme().letterSpacingDisplay)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Blank()

        Row().width(40).height(40)
      } else {
        Text('FITPLAN')
          .fontSize(this.getTheme().logoFontSize)
          .fontWeight(this.getTheme().fontWeightDisplay)
          .fontColor(this.getTheme().textPrimary)
          .letterSpacing(this.getTheme().letterSpacingDisplay)

        if (this.subtitle !== '') {
          Text(this.subtitle)
            .fontSize(12 * this.getTheme().fontSizeScale)
            .fontColor(this.getTheme().textSecondary)
            .margin({ left: 8 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }

        Blank()

        Row({ space: 8 }) {
          Button() {
            Text('🔔')
              .fontSize(16)
          }
          .width(40)
          .height(40)
          .borderRadius(this.getTheme().radiusMd)
          .borderWidth(this.getTheme().borderWidth)
          .borderStyle(BorderStyle.Solid)
          .borderColor(this.getTheme().borderColor)
          .backgroundColor(this.getTheme().bgCard)
          .onClick(() => {
            this.onBell()
          })

          Button() {
            Text('📅')
              .fontSize(16)
          }
          .width(40)
          .height(40)
          .borderRadius(this.getTheme().radiusMd)
          .borderWidth(this.getTheme().borderWidth)
          .borderStyle(BorderStyle.Solid)
          .borderColor(this.getTheme().borderColor)
          .backgroundColor(this.getTheme().bgCard)
          .onClick(() => {
            this.onCalendar()
          })
        }
      }
    }
    .width('100%')
    .padding({
      left: this.getTheme().cardPadding * 0.8,
      right: this.getTheme().cardPadding * 0.8,
      top: 16,
      bottom: 16,
    })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(this.getTheme().bgOverlay)
    .borderWidth({ bottom: 1 })
    .borderColor(this.getTheme().borderColor)
  }

  private getTheme(): ThemeColors {
    return getCurrentTheme()
  }
}
