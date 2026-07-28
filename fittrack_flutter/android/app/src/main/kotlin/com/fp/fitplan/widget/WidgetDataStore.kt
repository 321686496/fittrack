// fittrack_flutter/android/app/src/main/kotlin/com/fp/fitplan/widget/WidgetDataStore.kt
package com.fp.fitplan.widget

import android.content.Context
import androidx.glance.appwidget.GlanceAppWidgetManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/// 卡片数据存储（SharedPreferences）
object WidgetDataStore {
    private const val PREFS_NAME = "fittrack_widget_prefs"
    private const val KEY_WIDGET_DATA = "widget_data"

    // Application-scoped supervisor job — children survive caller cancellation
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    fun saveState(context: Context, jsonStr: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_WIDGET_DATA, jsonStr).apply()
        // Async refresh — fire-and-forget; Dart side treats as best-effort
        scope.launch {
            val manager = GlanceAppWidgetManager(context)
            val glanceIds = manager.getGlanceIds(FitTrackGlanceWidget::class.java)
            val widget = FitTrackGlanceWidget()
            glanceIds.forEach { id ->
                widget.update(context, id)
            }
        }
    }

    fun getState(context: Context): FitTrackWidgetState {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val jsonStr = prefs.getString(KEY_WIDGET_DATA, "") ?: ""
        return if (jsonStr.isEmpty()) FitTrackWidgetState() else FitTrackWidgetState.fromJson(jsonStr)
    }

    fun clearState(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().remove(KEY_WIDGET_DATA).apply()
        // Async refresh — fire-and-forget
        scope.launch {
            val manager = GlanceAppWidgetManager(context)
            val glanceIds = manager.getGlanceIds(FitTrackGlanceWidget::class.java)
            val widget = FitTrackGlanceWidget()
            glanceIds.forEach { id ->
                widget.update(context, id)
            }
        }
    }
}
