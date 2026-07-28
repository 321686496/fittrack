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
                    Text(timeString(context.state.remainingSeconds))
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
                Text(timeString(context.state.remainingSeconds))
                    .font(.caption.monospacedDigit())
            } minimal: {
                Text(timeString(context.state.remainingSeconds))
                    .font(.caption2.monospacedDigit())
            }
        }
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
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
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(timeString(context.state.remainingSeconds))
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text("剩余")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
