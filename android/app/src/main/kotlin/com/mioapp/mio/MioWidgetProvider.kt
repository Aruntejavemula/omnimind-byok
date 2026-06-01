package com.mioapp.mio

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Minimal native glue for the Mio home-screen widget. The layout + data are
 * driven from Dart via the `home_widget` package, so no Kotlin app logic is
 * needed beyond rendering the saved values and wiring the tap to launch the app.
 */
class MioWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.mio_widget).apply {
                val subtitle = widgetData.getString("mio_widget_subtitle", null)
                    ?: "Tap to start a new chat"
                setTextViewText(R.id.widget_subtitle, subtitle)

                // Tapping anywhere on the widget opens the app to a new chat.
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("mio://widget?action=new_chat")
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
