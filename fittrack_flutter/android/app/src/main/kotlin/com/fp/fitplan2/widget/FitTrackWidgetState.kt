// fittrack_flutter/android/app/src/main/kotlin/com/fp/fitplan/widget/FitTrackWidgetState.kt
package com.fp.fitplan2.widget

import org.json.JSONObject

/// 桌面卡片状态
data class FitTrackWidgetState(
    val mode: String = "idle",  // idle / training / rest
    val exerciseName: String = "",
    val currentSet: Int = 0,
    val totalSets: Int = 0,
    val exerciseIndex: Int = 0,
    val totalExercises: Int = 0,
    val completedSets: Int = 0,
    val totalPlanSets: Int = 0,
    val todayTrainings: Int = 0,
    val todayDuration: Int = 0,
    val todayWeight: Int = 0,
    val streak: Int = 0,
    val lastTraining: String = "",
    val lastDate: String = "",
    val trainingTime: String = "",
    val accentColor: String = "#FF6B35",
    val bgColor: String = "#FFFFFF",
    val textPrimaryColor: String = "#222222",
    val textSecondaryColor: String = "#999999"
) {
    companion object {
        fun fromJson(jsonStr: String): FitTrackWidgetState {
            return try {
                val json = JSONObject(jsonStr)
                FitTrackWidgetState(
                    mode = json.optString("mode", "idle"),
                    exerciseName = json.optString("exerciseName", ""),
                    currentSet = json.optInt("currentSet", 0),
                    totalSets = json.optInt("totalSets", 0),
                    exerciseIndex = json.optInt("exerciseIndex", 0),
                    totalExercises = json.optInt("totalExercises", 0),
                    completedSets = json.optInt("completedSets", 0),
                    totalPlanSets = json.optInt("totalPlanSets", 0),
                    todayTrainings = json.optInt("todayTrainings", 0),
                    todayDuration = json.optInt("todayDuration", 0),
                    todayWeight = json.optInt("todayWeight", 0),
                    streak = json.optInt("streak", 0),
                    lastTraining = json.optString("lastTraining", ""),
                    lastDate = json.optString("lastDate", ""),
                    trainingTime = json.optString("trainingTime", ""),
                    accentColor = json.optString("accentColor", "#FF6B35"),
                    bgColor = json.optString("bgColor", "#FFFFFF"),
                    textPrimaryColor = json.optString("textPrimaryColor", "#222222"),
                    textSecondaryColor = json.optString("textSecondaryColor", "#999999")
                )
            } catch (e: Exception) {
                FitTrackWidgetState()
            }
        }
    }
}
