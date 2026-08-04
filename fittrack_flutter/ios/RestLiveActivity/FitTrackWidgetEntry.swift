// fittrack_flutter/ios/RestLiveActivity/FitTrackWidgetEntry.swift
import WidgetKit
import SwiftUI

struct FitTrackWidgetEntry: TimelineEntry {
    let date: Date
    let mode: String          // idle / training / rest
    let exerciseName: String
    let currentSet: Int
    let totalSets: Int
    let exerciseIndex: Int
    let totalExercises: Int
    let completedSets: Int
    let totalPlanSets: Int
    let todayTrainings: Int
    let todayDuration: Int
    let todayWeight: Int
    let streak: Int
    let lastTraining: String
    let lastDate: String
    let trainingTime: String
    let accentColor: String
    let bgColor: String
    let textPrimaryColor: String
    let textSecondaryColor: String

    static let empty = FitTrackWidgetEntry(
        date: Date(),
        mode: "idle",
        exerciseName: "",
        currentSet: 0,
        totalSets: 0,
        exerciseIndex: 0,
        totalExercises: 0,
        completedSets: 0,
        totalPlanSets: 0,
        todayTrainings: 0,
        todayDuration: 0,
        todayWeight: 0,
        streak: 0,
        lastTraining: "",
        lastDate: "",
        trainingTime: "",
        accentColor: "#FF6B35",
        bgColor: "#FFFFFF",
        textPrimaryColor: "#222222",
        textSecondaryColor: "#999999"
    )

    static func fromDefaults() -> FitTrackWidgetEntry {
        let defaults = UserDefaults(suiteName: "group.com.lt.lifttrack")
        guard let data = defaults?.string(forKey: "widgetData"),
              let json = data.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: json) as? [String: Any] else {
            return .empty
        }

        func string(_ key: String) -> String { dict[key] as? String ?? "" }
        func int(_ key: String) -> Int { dict[key] as? Int ?? 0 }

        return FitTrackWidgetEntry(
            date: Date(),
            mode: string("mode"),
            exerciseName: string("exerciseName"),
            currentSet: int("currentSet"),
            totalSets: int("totalSets"),
            exerciseIndex: int("exerciseIndex"),
            totalExercises: int("totalExercises"),
            completedSets: int("completedSets"),
            totalPlanSets: int("totalPlanSets"),
            todayTrainings: int("todayTrainings"),
            todayDuration: int("todayDuration"),
            todayWeight: int("todayWeight"),
            streak: int("streak"),
            lastTraining: string("lastTraining"),
            lastDate: string("lastDate"),
            trainingTime: string("trainingTime"),
            accentColor: string("accentColor"),
            bgColor: string("bgColor"),
            textPrimaryColor: string("textPrimaryColor"),
            textSecondaryColor: string("textSecondaryColor")
        )
    }
}

func colorFromHex(_ hex: String) -> Color {
    let cleaned = hex.replacingOccurrences(of: "#", with: "")
    let scanner = Scanner(string: cleaned)
    var hexNumber: UInt64 = 0
    scanner.scanHexInt64(&hexNumber)
    let r = Double((hexNumber & 0xFF0000) >> 16) / 255.0
    let g = Double((hexNumber & 0x00FF00) >> 8) / 255.0
    let b = Double(hexNumber & 0x0000FF) / 255.0
    return Color(red: r, green: g, blue: b)
}
