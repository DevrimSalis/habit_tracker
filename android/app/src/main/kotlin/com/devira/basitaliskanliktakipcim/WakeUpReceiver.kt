package com.devira.basitaliskanliktakipcim

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.util.Log
import android.view.WindowManager
import android.app.KeyguardManager
import android.os.Build

class WakeUpReceiver : BroadcastReceiver() {
    private val TAG = "WakeUpReceiver"

    override fun onReceive(context: Context, intent: Intent) {
        try {
            Log.d(TAG, "🔔 WakeUpReceiver tetiklendi")
            
            // PowerManager ile ekranı uyandır
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val wakeLock = powerManager.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or 
                PowerManager.ACQUIRE_CAUSES_WAKEUP or 
                PowerManager.ON_AFTER_RELEASE,
                "HabitTracker:WakeUpReceiver"
            )
            
            wakeLock.acquire(15000) // 15 saniye
            
            // MainActivity'yi başlat
            val activityIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_BROUGHT_TO_FRONT
                putExtra("FROM_NOTIFICATION", true)
            }
            
            context.startActivity(activityIntent)
            
            Log.d(TAG, "✅ Ekran uyandırıldı ve MainActivity başlatıldı")
        } catch (e: Exception) {
            Log.e(TAG, "WakeUpReceiver error: ${e.message}", e)
        }
    }
}