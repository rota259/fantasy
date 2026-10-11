package com.example.fantasy_5omasi

import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    /**
     * قنوات الإشعارات — كل نوع بصوته (والأبلكيشن مقفول كمان). السيرفر بيبعت channel_id مع كل إشعار.
     * صوت القناة بيتثبّت أول ما تتعمل: لو عايز تغيّر صوت، غيّر الـ id (مثلًا _v2) هنا وفي فانكشن push.
     */
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        val audio = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val channels = listOf(
            Triple("khomasi_goal", "أهداف وأحداث الماتش", "goal"),
            Triple("khomasi_match", "الماتشات (بداية · نهاية · مواعيد)", "whistle"),
            Triple("khomasi_lineup", "التشكيلات", "lineup"),
            Triple("khomasi_win", "شارات · تحدّيات · تصويت", "win"),
            Triple("khomasi_general", "إشعارات عامة", "soft"),
        )
        for ((id, name, sound) in channels) {
            val channel = NotificationChannel(id, name, NotificationManager.IMPORTANCE_HIGH)
            channel.setSound(Uri.parse("android.resource://$packageName/raw/$sound"), audio)
            channel.enableVibration(true)
            manager.createNotificationChannel(channel)
        }
    }
}
