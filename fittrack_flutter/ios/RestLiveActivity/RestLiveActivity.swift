// fittrack_flutter/ios/RestLiveActivity/RestLiveActivity.swift
import WidgetKit
import SwiftUI
import ActivityKit

@available(iOS 16.1, *)
struct RestLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestLiveActivityAttributes.self) { context in
            // 锁屏显示
            LockScreenView(context: context)
                .padding(16)
                .activityBackgroundTint(Color(red: 0xFF/255, green: 0x6B/255, blue: 0x35/255))
                .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("休息中")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    // I1 修复：用 Text(timerInterval:) 让系统自动逐秒刷新，
                    // 避免 remainingSeconds 静态渲染后冻结。
                    Text(timerInterval: Date()...context.state.restEndTime, countsDown: true)
                        .font(.title2.monospacedDigit())
                        .foregroundColor(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.exerciseName)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundColor(.orange)
            } compactTrailing: {
                // I1 修复：紧凑视图同样使用 timerInterval 驱动倒计时。
                Text(timerInterval: Date()...context.state.restEndTime, countsDown: true)
                    .font(.caption.monospacedDigit())
            } minimal: {
                // I1 修复：极简视图同样使用 timerInterval 驱动倒计时。
                Text(timerInterval: Date()...context.state.restEndTime, countsDown: true)
                    .font(.caption2.monospacedDigit())
            }
        }
    }
}

@available(iOS 16.1, *)
struct LockScreenView: View {
    let context: ActivityViewContext<RestLiveActivityAttributes>

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("FitTrack - 休息中")
                    .font(.headline)
                    .foregroundColor(.white)
                Text(context.state.exerciseName)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                // I3 修复：锁屏 Live Activity 提供"结束休息"链接，
                // 通过 fittrack://action?cardAction=skipRest URL 拉起 App，
                // AppDelegate 的 URL handler 将其路由到 reminderChannel.onCardClick。
                Link(destination: URL(string: "fittrack://action?cardAction=skipRest")!) {
                    Text("结束休息")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(8)
                }
                .padding(.top, 4)
            }
            Spacer()
            VStack(alignment: .trailing) {
                // I1 修复：锁屏倒计时使用 Text(timerInterval:) 逐秒刷新。
                Text(timerInterval: Date()...context.state.restEndTime, countsDown: true)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundColor(.white)
                Text("剩余")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}
