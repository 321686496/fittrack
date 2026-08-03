// fittrack_flutter/android/app/src/main/kotlin/com/fp/fitplan/widget/FitTrackGlanceWidgetReceiver.kt
package com.fp.fitplan2.widget

import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver

class FitTrackGlanceWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = FitTrackGlanceWidget()
}
