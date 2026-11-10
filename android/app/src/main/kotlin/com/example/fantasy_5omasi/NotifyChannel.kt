package com.example.fantasy_5omasi

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import com.google.firebase.messaging.FirebaseMessaging
import io.flutter.plugin.common.MethodChannel

/**
 * فحص إشعارات الجهاز نفسه (اللي Firebase مبيقدرش يشوفه) + فتح الإعدادات الصح:
 *   status        → الإشعارات مسموحة؟ · كل قناة: مقفولة؟ أهميتها؟ ليها صوت؟ · الشركة · توفير البطارية
 *   openApp       → إعدادات إشعارات الأبلكيشن · openChannel(id) → إعدادات قناة واحدة (الصوت والظهور فوق الشاشة)
 *   openAutostart → التشغيل التلقائي (شاومي/أوبو/فيفو/هواوي) — من غيره الإشعار ممكن ميوصلش والأبلكيشن مقفول
 *   openBattery   → استثناء الأبلكيشن من توفير البطارية
 *   show          → إشعار في شريط الإشعارات والأبلكيشن مفتوح (Firebase مبيعرضش وقتها) — قناة هادية من غير صوت
 *                   ولا ظهور فوق الشاشة، لأن الأبلكيشن نفسه بيعرض شريطه وبيشغّل النغمة
 *   launchTap     → لو الأبلكيشن اتفتح من الضغط على الإشعار ده: الصفحة اللي يفتحها
 */
object NotifyChannel {
    const val NAME = "khomasi/notify"

    fun handler(context: Context) = MethodChannel.MethodCallHandler { call, result ->
        try {
            when (call.method) {
                "status" -> result.success(status(context))
                "openApp" -> result.success(open(context, appSettings(context)))
                "openChannel" -> result.success(open(context, channelSettings(context, call.argument<String>("id") ?: "")))
                "openAutostart" -> result.success(autostart(context))
                "openBattery" -> result.success(open(context, Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)))
                "show" -> {
                    show(context, call.argument<String>("title") ?: "", call.argument<String>("body") ?: "",
                        call.argument<String>("link") ?: "", call.argument<String>("match_id") ?: "")
                    result.success(true)
                }
                // توكن Firebase — ولو فشل: سلسلة الأسباب كاملة (Flutter بيوصّل أول سطر بس)
                "fcmProbe" -> FirebaseMessaging.getInstance().token.addOnCompleteListener { t ->
                    if (t.isSuccessful) {
                        result.success(mapOf("ok" to true))
                    } else {
                        val chain = mutableListOf<String>()
                        var e: Throwable? = t.exception
                        while (e != null && chain.size < 6) {
                            chain.add("${e.javaClass.simpleName}: ${e.message}")
                            e = e.cause
                        }
                        result.success(mapOf("ok" to false, "error" to chain.joinToString(" <- ")))
                    }
                }
                "launchTap" -> {
                    result.success(pendingTap)
                    pendingTap = null
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("notify", e.message, null)
        }
    }

    const val QUIET_CHANNEL = "khomasi_inapp_v1"
    const val EXTRA_LINK = "khomasi_link"
    const val EXTRA_MATCH = "khomasi_match"

    /** الصفحة اللي الأبلكيشن اتفتح عليها من الضغط على إشعار من بتوعنا (بتتاخد مرة واحدة). */
    var pendingTap: Map<String, String>? = null

    private fun show(context: Context, title: String, body: String, link: String, matchId: String) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && manager.getNotificationChannel(QUIET_CHANNEL) == null) {
            val ch = NotificationChannel(QUIET_CHANNEL, "وانت جوه الأبلكيشن", NotificationManager.IMPORTANCE_LOW)
            ch.setSound(null, null)
            manager.createNotificationChannel(ch)
        }
        val open = Intent(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            .putExtra(EXTRA_LINK, link)
            .putExtra(EXTRA_MATCH, matchId)
        val id = (System.currentTimeMillis() % Int.MAX_VALUE).toInt()
        val tap = PendingIntent.getActivity(context, id, open, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, QUIET_CHANNEL)
        } else {
            @Suppress("DEPRECATION") Notification.Builder(context)
        }
        val n = builder.setSmallIcon(R.drawable.ic_stat_khomasi)
            .setColor(0xFF12A150.toInt())
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setAutoCancel(true)
            .setContentIntent(tap)
            .build()
        manager.notify(id, n)
    }

    /** الضغط على إشعار من بتوعنا (الأبلكيشن كان مقفول أو في الخلفية). */
    fun tapFrom(intent: Intent?): Map<String, String>? {
        val link = intent?.getStringExtra(EXTRA_LINK) ?: return null
        val match = intent.getStringExtra(EXTRA_MATCH) ?: ""
        intent.removeExtra(EXTRA_LINK)
        return mapOf("link" to link, "match_id" to match)
    }

    private fun status(context: Context): Map<String, Any?> {
        val manager = context.getSystemService(NotificationManager::class.java)
        val channels = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.notificationChannels.filter { it.id.startsWith("khomasi_") }.map {
                mapOf("id" to it.id, "name" to it.name.toString(), "importance" to it.importance, "sound" to (it.sound != null))
            }.filter { it["id"] != QUIET_CHANNEL }
        } else emptyList()
        val power = context.getSystemService(PowerManager::class.java)
        return mapOf(
            "enabled" to manager.areNotificationsEnabled(),
            "channels" to channels,
            "manufacturer" to Build.MANUFACTURER.lowercase(),
            "sdk" to Build.VERSION.SDK_INT,
            "batteryOptimized" to !(power?.isIgnoringBatteryOptimizations(context.packageName) ?: true),
        )
    }

    private fun appSettings(context: Context) = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
        .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)

    private fun channelSettings(context: Context, id: String) =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && id.isNotEmpty()) {
            Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
                .putExtra(Settings.EXTRA_CHANNEL_ID, id)
        } else appSettings(context)

    private fun autostart(context: Context): Boolean {
        val candidates = listOf(
            ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity"),
            ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity"),
            ComponentName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity"),
            ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"),
            ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"),
        )
        for (c in candidates) {
            if (open(context, Intent().setComponent(c))) return true
        }
        // مفيش شاشة تشغيل تلقائي معروفة: صفحة الأبلكيشن في الإعدادات
        return open(context, Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${context.packageName}")))
    }

    private fun open(context: Context, intent: Intent): Boolean = try {
        context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (_: Exception) {
        false
    }
}
