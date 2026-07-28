// fittrack_flutter/ios/RestLiveActivity/RestLiveActivityAttributes.swift
import Foundation
import ActivityKit

@available(iOS 16.1, *)
struct RestLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var exerciseName: String
        var remainingSeconds: Int
        var totalRestSeconds: Int
        var restEndTime: Date
    }

    var exerciseName: String
}
