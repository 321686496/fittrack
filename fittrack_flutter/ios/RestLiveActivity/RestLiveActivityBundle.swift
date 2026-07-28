// fittrack_flutter/ios/RestLiveActivity/RestLiveActivityBundle.swift
import WidgetKit
import SwiftUI

@main
struct RestLiveActivityBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        FitTrackWidget()
        if #available(iOS 16.1, *) {
            RestLiveActivity()
        }
    }
}
