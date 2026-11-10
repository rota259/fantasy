package com.example.fantasy_5omasi

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    private var notify: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        notify = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NotifyChannel.NAME).also {
            it.setMethodCallHandler(NotifyChannel.handler(applicationContext))
        }
        // اتفتح من الضغط على إشعار من بتوعنا والأبلكيشن كان مقفول → Flutter بياخدها بـ launchTap
        NotifyChannel.tapFrom(intent)?.let { NotifyChannel.pendingTap = it }
    }

    // الضغط على إشعار من بتوعنا والأبلكيشن في الخلفية → نفتح الصفحة على طول
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        NotifyChannel.tapFrom(intent)?.let { notify?.invokeMethod("tap", it) }
    }

    /**
     * قنوات الإشعارات — كل نوع بصوته (والأبلكيشن مقفول كمان). السيرفر بيبعت channel_id مع كل إشعار.
     * صوت القناة بيتثبّت أول ما تتعمل: لو عايز تغيّر صوت، غيّر الـ id (مثلًا _v3) هنا وفي فانكشن push.
     */
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        val audio = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        // النغمة بتتثبّت على القناة أول ما تتعمل — فالقنوات القديمة (بنغماتها القديمة) بتتمسح
        for (old in listOf("khomasi_goal", "khomasi_match", "khomasi_lineup", "khomasi_win", "khomasi_general")) {
            manager.deleteNotificationChannel(old)
        }
        val channels = listOf(
            Triple("khomasi_goal_v2", "الأهداف", "goal"),
            Triple("khomasi_match_v2", "بداية ونهاية الماتش", "match"),
            Triple("khomasi_lineup_v2", "التشكيلة نزلت", "lineup"),
            Triple("khomasi_round_v2", "بداية الجولة", "round_start"),
            Triple("khomasi_deadline_v2", "الديدلاين", "deadline"),
            Triple("khomasi_general_v2", "إشعارات عامة", "general"),
        )
        for ((id, name, sound) in channels) {
            val channel = NotificationChannel(id, name, NotificationManager.IMPORTANCE_HIGH)
            channel.setSound(Uri.parse("android.resource://$packageName/raw/$sound"), audio)
            channel.enableVibration(true)
            manager.createNotificationChannel(channel)
        }
    }
}
