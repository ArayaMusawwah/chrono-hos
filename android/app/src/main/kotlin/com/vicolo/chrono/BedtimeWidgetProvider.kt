package com.vicolo.chrono

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class BedtimeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val isActive = widgetData.getBoolean("bedtime_enabled", false)
        val bedtimeTime = widgetData.getString("bedtime_time", "--:--")
        val wakeTime = widgetData.getString("bedtime_wake", "--:--")
        val sunriseTime = widgetData.getString("bedtime_sunrise", "--:--")

        appWidgetIds.forEach { appWidgetId ->
            val views = RemoteViews(context.packageName, R.layout.bedtime_widget).apply {
                // Status text
                setTextViewText(R.id.bedtime_status_text,
                    if (isActive) "Bedtime active" else "Bedtime off")

                // Next wake preview
                val wakeText = if (isActive) {
                    "Wake: $wakeTime  🌅 $sunriseTime"
                } else {
                    "Disabled"
                }
                setTextViewText(R.id.bedtime_next_wake, wakeText)

                // Tap to open app
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    android.net.Uri.parse("chrono://bedtimeClicked")
                )
                setOnClickPendingIntent(R.id.bedtime_status_icon, pendingIntent)
                setOnClickPendingIntent(R.id.bedtime_status_text, pendingIntent)
                setOnClickPendingIntent(R.id.bedtime_next_wake, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
