// fittrack_flutter/android/app/src/main/kotlin/com/fp/fitplan/widget/FitTrackGlanceWidget.kt
package com.lt.lifttrack.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.*
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.*
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.lt.lifttrack.MainActivity

class FitTrackGlanceWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val state = WidgetDataStore.getState(context)
        provideContent {
            WidgetContent(state)
        }
    }
}

@Composable
fun WidgetContent(state: FitTrackWidgetState) {
    val accentColor = parseColor(state.accentColor)
    val bgColor = parseColor(state.bgColor)
    val textPrimary = parseColor(state.textPrimaryColor)
    val textSecondary = parseColor(state.textSecondaryColor)

    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(ColorProvider(bgColor))
            .padding(12.dp)
            .clickable(actionStartActivity<MainActivity>())
    ) {
        when (state.mode) {
            "idle" -> IdleView(state, accentColor, textPrimary, textSecondary)
            "training" -> TrainingView(state, accentColor, textPrimary, textSecondary)
            "rest" -> RestView(state, accentColor, textPrimary, textSecondary)
        }
    }
}

@Composable
fun IdleView(
    state: FitTrackWidgetState,
    accentColor: Color,
    textPrimary: Color,
    textSecondary: Color
) {
    Column(
        modifier = GlanceModifier.fillMaxSize(),
        verticalAlignment = Alignment.Top,
        horizontalAlignment = Alignment.Start
    ) {
        Text(
            text = "今日训练",
            style = TextStyle(color = ColorProvider(textSecondary), fontSize = 12.sp)
        )
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.Bottom
        ) {
            Text(
                text = "${state.todayTrainings}",
                style = TextStyle(
                    color = ColorProvider(accentColor),
                    fontSize = 28.sp,
                    fontWeight = FontWeight.Bold
                )
            )
            Spacer(modifier = GlanceModifier.width(4.dp))
            Text(
                text = "次",
                style = TextStyle(color = ColorProvider(textSecondary), fontSize = 12.sp)
            )
            Spacer(modifier = GlanceModifier.defaultWeight())
            Text(
                text = "${state.todayDuration}分钟",
                style = TextStyle(color = ColorProvider(textPrimary), fontSize = 14.sp)
            )
        }
        Spacer(modifier = GlanceModifier.height(8.dp))
        Row(
            modifier = GlanceModifier.fillMaxWidth()
        ) {
            Text(
                text = "连续 ${state.streak} 天",
                style = TextStyle(color = ColorProvider(textPrimary), fontSize = 12.sp)
            )
            Spacer(modifier = GlanceModifier.defaultWeight())
            if (state.trainingTime.isNotEmpty()) {
                Text(
                    text = "提醒 ${state.trainingTime}",
                    style = TextStyle(color = ColorProvider(textSecondary), fontSize = 10.sp)
                )
            }
        }
        if (state.lastTraining.isNotEmpty()) {
            Spacer(modifier = GlanceModifier.height(4.dp))
            Text(
                text = "最近：${state.lastTraining} ${state.lastDate}",
                style = TextStyle(color = ColorProvider(textSecondary), fontSize = 10.sp)
            )
        }
    }
}

@Composable
fun TrainingView(
    state: FitTrackWidgetState,
    accentColor: Color,
    textPrimary: Color,
    textSecondary: Color
) {
    Column(
        modifier = GlanceModifier.fillMaxSize(),
        verticalAlignment = Alignment.Top
    ) {
        Text(
            text = "训练中",
            style = TextStyle(color = ColorProvider(accentColor), fontSize = 12.sp)
        )
        Text(
            text = state.exerciseName,
            style = TextStyle(
                color = ColorProvider(textPrimary),
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold
            )
        )
        Row(
            modifier = GlanceModifier.fillMaxWidth()
        ) {
            Text(
                text = "第 ${state.currentSet}/${state.totalSets} 组",
                style = TextStyle(color = ColorProvider(textPrimary), fontSize = 14.sp)
            )
            Spacer(modifier = GlanceModifier.defaultWeight())
            Text(
                text = "${state.exerciseIndex}/${state.totalExercises}",
                style = TextStyle(color = ColorProvider(textSecondary), fontSize = 12.sp)
            )
        }
    }
}

@Composable
fun RestView(
    state: FitTrackWidgetState,
    accentColor: Color,
    textPrimary: Color,
    textSecondary: Color
) {
    Column(
        modifier = GlanceModifier.fillMaxSize(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "休息中",
            style = TextStyle(color = ColorProvider(accentColor), fontSize = 12.sp)
        )
        Text(
            text = state.exerciseName,
            style = TextStyle(color = ColorProvider(textPrimary), fontSize = 14.sp)
        )
        Text(
            text = "第 ${state.currentSet}/${state.totalSets} 组",
            style = TextStyle(color = ColorProvider(textSecondary), fontSize = 12.sp)
        )
    }
}

fun parseColor(hex: String): Color {
    val cleaned = hex.removePrefix("#")
    return try {
        val color = cleaned.toLong(16)
        Color(
            red = ((color shr 16) and 0xFF) / 255f,
            green = ((color shr 8) and 0xFF) / 255f,
            blue = (color and 0xFF) / 255f
        )
    } catch (e: Exception) {
        Color(0xFFFF6B35)
    }
}
