import { getCurrentTheme, ThemeColors, DEFAULT_THEME_ID } from '../common/ThemeConstants'
import { HomePage } from './HomePage'
import { PlanPage } from './PlanPage'
import { StatsPage } from './StatsPage'
import { ExercisePage } from './ExercisePage'
import { ProfilePage } from './ProfilePage'

@Entry
@Component
struct Index {
  @StorageProp('themeId') themeId: string = DEFAULT_THEME_ID
  @State currentTab: number = 0

  aboutToAppear() {
    AppStorage.setOrCreate('themeId', DEFAULT_THEME_ID)
  }

  build() {
    Column() {
      Tabs({ index: this.currentTab }) {
        TabContent() {
          HomePage({ onNavigate: (page: string) => { this.handleNavigate(page) } })
        }
        .tabBar(this.HomeTabBar)

        TabContent() {
          PlanPage({ onNavigate: (page: string) => { this.handleNavigate(page) } })
        }
        .tabBar(this.PlanTabBar)

        TabContent() {
          StatsPage()
        }
        .tabBar(this.StatsTabBar)

        TabContent() {
          ExercisePage()
        }
        .tabBar(this.ExerciseTabBar)

        TabContent() {
          ProfilePage({ onNavigate: (page: string) => { this.handleNavigate(page) } })
        }
        .tabBar(this.ProfileTabBar)
      }
      .scrollable(false)
      .barPosition(BarPosition.End)
      .barBackgroundColor(this.t().bgOverlay)
      .onChange((index: number) => {
        this.currentTab = index
      })
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.t().bgPrimary)
  }

  private t(): ThemeColors {
    return getCurrentTheme()
  }

  private handleNavigate(page: string) {
    if (page === 'plan') {
      this.currentTab = 1
    } else if (page === 'stats') {
      this.currentTab = 2
    } else if (page === 'exercise') {
      this.currentTab = 3
    } else if (page === 'profile') {
      this.currentTab = 4
    }
  }

  @Builder
  HomeTabBar() {
    Column({ space: 4 }) {
      Row() {
        Text('🏠')
          .fontSize(22)
          .fontColor(this.currentTab === 0 ? this.t().accentPrimary : this.t().textMuted)
      }
      .borderRadius(this.t().radiusMd)
      .padding({ left: 12, right: 12, top: 4, bottom: 4 })
      .backgroundColor(this.currentTab === 0 ? this.t().accentGlow : Color.Transparent)
      Text('首页')
        .fontSize(10)
        .fontWeight(600)
        .fontColor(this.currentTab === 0 ? this.t().accentPrimary : this.t().textMuted)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  PlanTabBar() {
    Column({ space: 4 }) {
      Row() {
        Text('📋')
          .fontSize(22)
          .fontColor(this.currentTab === 1 ? this.t().accentPrimary : this.t().textMuted)
      }
      .borderRadius(this.t().radiusMd)
      .padding({ left: 12, right: 12, top: 4, bottom: 4 })
      .backgroundColor(this.currentTab === 1 ? this.t().accentGlow : Color.Transparent)
      Text('计划')
        .fontSize(10)
        .fontWeight(600)
        .fontColor(this.currentTab === 1 ? this.t().accentPrimary : this.t().textMuted)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  StatsTabBar() {
    Column({ space: 4 }) {
      Row() {
        Text('📊')
          .fontSize(22)
          .fontColor(this.currentTab === 2 ? this.t().accentPrimary : this.t().textMuted)
      }
      .borderRadius(this.t().radiusMd)
      .padding({ left: 12, right: 12, top: 4, bottom: 4 })
      .backgroundColor(this.currentTab === 2 ? this.t().accentGlow : Color.Transparent)
      Text('统计')
        .fontSize(10)
        .fontWeight(600)
        .fontColor(this.currentTab === 2 ? this.t().accentPrimary : this.t().textMuted)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ExerciseTabBar() {
    Column({ space: 4 }) {
      Row() {
        Text('🏋')
          .fontSize(22)
          .fontColor(this.currentTab === 3 ? this.t().accentPrimary : this.t().textMuted)
      }
      .borderRadius(this.t().radiusMd)
      .padding({ left: 12, right: 12, top: 4, bottom: 4 })
      .backgroundColor(this.currentTab === 3 ? this.t().accentGlow : Color.Transparent)
      Text('动作')
        .fontSize(10)
        .fontWeight(600)
        .fontColor(this.currentTab === 3 ? this.t().accentPrimary : this.t().textMuted)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ProfileTabBar() {
    Column({ space: 4 }) {
      Row() {
        Text('👤')
          .fontSize(22)
          .fontColor(this.currentTab === 4 ? this.t().accentPrimary : this.t().textMuted)
      }
      .borderRadius(this.t().radiusMd)
      .padding({ left: 12, right: 12, top: 4, bottom: 4 })
      .backgroundColor(this.currentTab === 4 ? this.t().accentGlow : Color.Transparent)
      Text('我的')
        .fontSize(10)
        .fontWeight(600)
        .fontColor(this.currentTab === 4 ? this.t().accentPrimary : this.t().textMuted)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
