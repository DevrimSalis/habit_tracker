package com.devira.basitaliskanliktakipcim

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class AlarmReceiver : BroadcastReceiver() {
    private val TAG = "AlarmReceiver"
    private val CHANNEL_ID = "ALARM_HABIT_CHANNEL"
    private val NOTIFICATION_ID = 999

    override fun onReceive(context: Context, intent: Intent) {
        try {
            Log.d(TAG, "🚨 AlarmReceiver tetiklendi!")
            
            val habitName = intent.getStringExtra("habit_name") ?: "Alışkanlık"
            val habitId = intent.getIntExtra("habit_id", 0)
            
            // EKRANI UYANDI VE BİLDİRİM GÖSTER
            wakeUpAndNotify(context, habitName, habitId)
            
        } catch (e: Exception) {
            Log.e(TAG, "AlarmReceiver error: ${e.message}", e)
        }
    }
    
    private fun wakeUpAndNotify(context: Context, habitName: String, habitId: Int) {
        try {
            // 1. EKRANI UYANDI
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val wakeLock = powerManager.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or 
                PowerManager.ACQUIRE_CAUSES_WAKEUP,
                "HabitTracker:AlarmWakeLock"
            )
            wakeLock.acquire(30000) // 30 saniye
            
            // 2. BİLDİRİM KANALI OLUŞTUR
            createNotificationChannel(context)
            
            // 3. EKRAN KİLİTLİ DURUMDA BİLDİRİM GÖSTER
            showLockScreenNotification(context, habitName, habitId)
            
            Log.d(TAG, "✅ Ekran uyandırıldı ve bildirim gösterildi: $habitName")
            
        } catch (e: Exception) {
            Log.e(TAG, "wakeUpAndNotify error: ${e.message}", e)
        }
    }
    
    private fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Alarm Bildirimleri",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Ekran kilitli durumda çalışan alarm bildirimleri"
                enableVibration(true)
                enableLights(true)
                setBypassDnd(true) // Rahatsız etme modunu atla
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
            }
            
            val notificationManager = context.getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun showLockScreenNotification(context: Context, habitName: String, habitId: Int) {
        try {
            // MainActivity'yi açacak intent
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("habit_id", habitId)
                putExtra("from_alarm", true)
            }
            
            val pendingIntent = PendingIntent.getActivity(
                context, 
                habitId, 
                intent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            // EKRAN KİLİTLİ DURUMDA ÇALIŞAN BİLDİRİM
            val notification = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_lock_idle_alarm) // Sistem alarm ikonu
                .setContentTitle("🔔 $habitName")
                .setContentText("$habitName yapma zamanı geldi! Dokunun.")
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setContentIntent(pendingIntent)
                .setAutoCancel(true)
                .setOngoing(false)
                .setVibrate(longArrayOf(0, 1000, 500, 1000, 500, 1000))
                .setLights(0xFFFF0000.toInt(), 3000, 1000)
                .setFullScreenIntent(pendingIntent, true) // EKRAN KİLİTLİ İÇİN KRİTİK
                .setWhen(System.currentTimeMillis())
                .setShowWhen(true)
                .build()
            
            // Notification göster
            val notificationManager = NotificationManagerCompat.from(context)
            notificationManager.notify(NOTIFICATION_ID + habitId, notification)
            
            Log.d(TAG, "📱 Ekran kilitli bildirim gösterildi")
            
        } catch (e: Exception) {
            Log.e(TAG, "showLockScreenNotification error: ${e.message}", e)
        }
    }
}