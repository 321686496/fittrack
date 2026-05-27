import { getCurrentTheme, ThemeColors } from '../common/ThemeConstants'
import { EXERCISES, CATEGORIES, ExerciseLibItem, filterExercisesByCategory } from '../common/MockData'
import { PageHeader } from '../components/PageHeader'

@Component
export struct ExercisePage {
  @StorageProp('themeId') themeId: string = 'iron-forge'
  @State selectedCat: string = '全部'
  @State filteredExercises: ExerciseLibItem[] = EXERCISES
  private catScroller: Scroller = new Scroller()

  build() {
    Column() {
      PageHeader({ title: '动作库', subtitle: `${EXERCISES.length}个专业训练动作` })
      Scroll() {
        Column({ space: this.t().sectionGap }) {
          Scroll(this.catScroller) {
            Row({ space: 8 }) {
              ForEach(CATEGORIES, (cat: string) => {
                Button(cat)
                  .height(32).fontSize(12 * this.t().fontSizeScale).fontWeight(600)
                  .fontColor(this.selectedCat === cat ? this.t().accentTextColor : this.t().textPrimary)
                  .borderRadius(this.t().radiusBtn)
                  .backgroundColor(this.selectedCat === cat ? this.t().accentPrimary : this.t().bgElevated)
                  .borderWidth(this.selectedCat === cat ? 0 : this.t().borderWidth)
                  .borderStyle(BorderStyle.Solid).borderColor(this.t().borderColor)
                  .padding({ left: 16, right: 16 })
                  .onClick(() => {
                    this.selectedCat = cat
                    this.filteredExercises = filterExercisesByCategory(cat)
                  })
              }, (cat: string) => cat)
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')

          Grid() {
            ForEach(this.filteredExercises, (ex: ExerciseLibItem) => {
              GridItem() {
                Column() {
                  Text('🏋')
                    .fontSize(24).width(48).height(48).textAlign(TextAlign.Center)
                    .borderRadius(this.t().radiusLg).backgroundColor(this.t().accentGlow).margin({ bottom: 12 })
                  Text(ex.name)
                    .fontSize(13 * this.t().fontSizeScale).fontWeight(this.t().fontWeightDisplay)
                    .fontColor(this.t().textPrimary).letterSpacing(this.t().letterSpacingDisplay).margin({ bottom: 4 })
                  Text(`${ex.category} · ${ex.equip}`)
                    .fontSize(11 * this.t().fontSizeScale).fontColor(this.t().textSecondary)
                }
                .width('100%').alignItems(HorizontalAlign.Center)
                .padding(this.t().cardPadding)
                .borderRadius(this.t().radiusLg)
                .borderWidth(this.t().borderWidth).borderStyle(BorderStyle.Solid).borderColor(this.t().borderColor)
                .backgroundColor(this.t().bgCard)
              }
            }, (ex: ExerciseLibItem) => ex.id)
          }
          .columnsTemplate('1fr 1fr')
          .columnsGap(this.t().cardSpacing)
          .rowsGap(this.t().cardSpacing)
          .width('100%')
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
}
