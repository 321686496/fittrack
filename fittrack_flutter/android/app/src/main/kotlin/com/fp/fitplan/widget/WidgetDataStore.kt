// fittrack_flutter/android/app/src/main/kotlin/com/fp/fitplan/widget/WidgetDataStore.kt
package com.fp.fitplan.widget

import android.content.Context
import androidx.glance.appwidget.GlanceAppWidgetManager
import kotlinx.coroutines.runBlocking

/// 卡片数据存储（SharedPreferences）
object WidgetDataStore {
    private const val PREFS_NAME = "fittrack_widget_prefs"
    private const val KEY_WIDGET_DATA = "widget_data"

    fun saveState(context: Context, jsonStr: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_WIDGET_DATA, jsonStr).apply()
        // 触发 Glance 卡片刷新
        runBlocking {
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
        runBlocking {
            val manager = GlanceAppWidgetManager(context)
            val glanceIds = manager.getGlanceIds(FitTrackGlanceWidget::class.java)
            val widget = FitTrackGlanceWidget()
            glanceIds.forEach { id ->
                widget.update(context, id)
            }
        }
    }
}
