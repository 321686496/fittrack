// fittrack_flutter/ios/RestLiveActivity/FitTrackWidget.swift
import WidgetKit
import SwiftUI

struct FitTrackWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> FitTrackWidgetEntry {
        .empty
    }

    func getSnapshot(in context: Context, completion: @escaping (FitTrackWidgetEntry) -> Void) {
        completion(.fromDefaults())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FitTrackWidgetEntry>) -> Void) {
        let entry = FitTrackWidgetEntry.fromDefaults()
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60)))
        completion(timeline)
    }
}

struct FitTrackWidget: Widget {
    let kind: String = "FitTrackWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FitTrackWidgetProvider()) { entry in
            FitTrackWidgetView(entry: entry)
        }
        .configurationDisplayName("FitTrack 训练卡片")
        .description("显示今日训练摘要和连续训练天数")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct FitTrackWidgetView: View {
    let entry: FitTrackWidgetEntry

    var body: some View {
        ZStack {
            colorFromHex(entry.bgColor)
            Group {
                if entry.mode == "idle" {
                    IdleView(entry: entry)
                } else if entry.mode == "training" {
                    TrainingView(entry: entry)
                } else if entry.mode == "rest" {
                    RestWidgetView(entry: entry)
                }
            }
            .padding(12)
        }
    }
}

struct IdleView: View {
    let entry: FitTrackWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("今日训练")
                .font(.caption)
                .foregroundColor(colorFromHex(entry.textSecondaryColor))
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(entry.todayTrainings)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(colorFromHex(entry.accentColor))
                Text("次")
                    .font(.caption)
                    .foregroundColor(colorFromHex(entry.textSecondaryColor))
                Spacer()
                Text("\(entry.todayDuration)分钟")
                    .font(.subheadline)
                    .foregroundColor(colorFromHex(entry.textPrimaryColor))
            }
            Divider()
            HStack {
                Text("连续 \(entry.streak) 天")
                    .font(.caption)
                    .foregroundColor(colorFromHex(entry.textPrimaryColor))
                Spacer()
                if !entry.trainingTime.isEmpty {
                    Text("提醒 \(entry.trainingTime)")
                        .font(.caption2)
                        .foregroundColor(colorFromHex(entry.textSecondaryColor))
                }
            }
            if !entry.lastTraining.isEmpty {
                Text("最近：\(entry.lastTraining) \(entry.lastDate)")
                    .font(.caption2)
                    .foregroundColor(colorFromHex(entry.textSecondaryColor))
            }
        }
    }
}

struct TrainingView: View {
    let entry: FitTrackWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("训练中")
                .font(.caption)
                .foregroundColor(colorFromHex(entry.accentColor))
            Text(entry.exerciseName)
                .font(.headline)
                .foregroundColor(colorFromHex(entry.textPrimaryColor))
                .lineLimit(1)
            HStack {
                Text("第 \(entry.currentSet)/\(entry.totalSets) 组")
                    .font(.subheadline)
                    .foregroundColor(colorFromHex(entry.textPrimaryColor))
                Spacer()
                Text("\(entry.exerciseIndex)/\(entry.totalExercises)")
                    .font(.caption)
                    .foregroundColor(colorFromHex(entry.textSecondaryColor))
            }
            ProgressView(value: Double(entry.completedSets), total: Double(max(entry.totalPlanSets, 1)))
                .tint(colorFromHex(entry.accentColor))
        }
    }
}

struct RestWidgetView: View {
    let entry: FitTrackWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("休息中")
                .font(.caption)
                .foregroundColor(colorFromHex(entry.accentColor))
            Text(entry.exerciseName)
                .font(.subheadline)
                .foregroundColor(colorFromHex(entry.textPrimaryColor))
                .lineLimit(1)
            Text("第 \(entry.currentSet)/\(entry.totalSets) 组")
                .font(.caption)
                .foregroundColor(colorFromHex(entry.textSecondaryColor))
        }
    }
}
