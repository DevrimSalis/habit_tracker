package com.devira.basitaliskanliktakipcim

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.app.NotificationManager
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import android.util.Log
import android.app.AlarmManager
import android.app.PendingIntent
import java.util.*

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.devira.basitaliskanliktakipcim/battery"
    private val NOTIFICATION_PERMISSION_CODE = 1001
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "requestBatteryOptimization" -> {
                        requestBatteryOptimization()
                        result.success(true)
                    }
                    "checkBatteryOptimization" -> {
                        val isOptimized = checkBatteryOptimization()
                        result.success(isOptimized)
                    }
                    "requestNotificationPermission" -> {
                        requestNotificationPermission()
                        result.success(true)
                    }
                    "checkNotificationPermission" -> {
                        val hasPermission = checkNotificationPermission()
                        result.success(hasPermission)
                    }
                    "openNotificationSettings" -> {
                        openNotificationSettings()
                        result.success(true)
                    }
                    "scheduleAlarm" -> {
                        val habitId = call.argument<Int>("habitId") ?: 0
                        val habitName = call.argument<String>("habitName") ?: ""
                        val hour = call.argument<Int>("hour") ?: 0
                        val minute = call.argument<Int>("minute") ?: 0
                        scheduleAlarm(habitId, habitName, hour, minute)
                        result.success(true)
                    }
                    "cancelAlarm" -> {
                        val habitId = call.argument<Int>("habitId") ?: 0
                        cancelAlarm(habitId)
                        result.success(true)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Method channel error: ${e.message}", e)
                result.error("ERROR", e.message, null)
            }
        }
    }

    // ALARMMANAGER İLE BİLDİRİM ZAMANLAMA - EKRAN KİLİTLİ İÇİN
    private fun scheduleAlarm(habitId: Int, habitName: String, hour: Int, minute: Int) {
        try {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            // Önce varsa iptal et
            cancelAlarm(habitId)
            
            // Alarm receiver intent'i
            val intent = Intent(this, AlarmReceiver::class.java).apply {
                putExtra("habit_id", habitId)
                putExtra("habit_name", habitName)
            }
            
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                habitId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            // Alarm zamanını hesapla
            val calendar = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, hour)
                set(Calendar.MINUTE, minute)
                set(Calendar.SECOND, 0)
                
                // Eğer geçmişse yarına al
                if (timeInMillis <= System.currentTimeMillis()) {
                    add(Calendar.DAY_OF_YEAR, 1)
                }
            }
            
            // ALARM ZAMANLA - EN AGRESIF YOL
            when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        calendar.timeInMillis,
                        pendingIntent
                    )
                }
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT -> {
                    alarmManager.setExact(
                        AlarmManager.RTC_WAKEUP,
                        calendar.timeInMillis,
                        pendingIntent
                    )
                }
                else -> {
                    alarmManager.set(
                        AlarmManager.RTC_WAKEUP,
                        calendar.timeInMillis,
                        pendingIntent
                    )
                }
            }
            
            Log.d(TAG, "⏰ Alarm zamanlandı: $habitName - ${calendar.time}")
            
        } catch (e: Exception) {
            Log.e(TAG, "scheduleAlarm error: ${e.message}", e)
        }
    }
    
    // ALARM İPTAL ETME
    private fun cancelAlarm(habitId: Int) {
        try {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(this, AlarmReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                habitId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            alarmManager.cancel(pendingIntent)
            Log.d(TAG, "🗑️ Alarm iptal edildi: $habitId")
            
        } catch (e: Exception) {
            Log.e(TAG, "cancelAlarm error: ${e.message}", e)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        try {
            // Ekran kilitli durumda görünmesi için
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                setShowWhenLocked(true)
                setTurnScreenOn(true)
            } else {
                window.addFlags(
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                )
            }
            
            Log.d(TAG, "✅ MainActivity başarıyla başlatıldı")
        } catch (e: Exception) {
            Log.e(TAG, "onCreate error: ${e.message}", e)
        }
    }

    // MEVCUT METODLAR...
    private fun checkBatteryOptimization(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                val isOptimized = !powerManager.isIgnoringBatteryOptimizations(packageName)
                Log.d(TAG, "🔋 Pil optimizasyonu durumu: $isOptimized")
                isOptimized
            } else {
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Pil optimizasyonu kontrolü hatası: ${e.message}", e)
            false
        }
    }

    private fun requestBatteryOptimization() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                
                if (!powerManager.isIgnoringBatteryOptimizations(packageName)) {
                    Log.d(TAG, "🔋 Pil optimizasyonu izni isteniyor...")
                    
                    val intent = Intent()
                    intent.action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                    intent.data = Uri.parse("package:$packageName")
                    
                    try {
                        startActivity(intent)
                        Log.d(TAG, "✅ Pil optimizasyonu ayarları açıldı")
                    } catch (e: Exception) {
                        Log.w(TAG, "Direkt pil optimizasyonu açılamadı, genel ayarlara yönlendiriliyor", e)
                        val fallbackIntent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                        startActivity(fallbackIntent)
                    }
                } else {
                    Log.d(TAG, "✅ Pil optimizasyonu zaten kapalı")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "requestBatteryOptimization error: ${e.message}", e)
        }
    }

    private fun requestNotificationPermission() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) 
                    != PackageManager.PERMISSION_GRANTED) {
                    
                    Log.d(TAG, "📱 Android 13+ bildirim izni isteniyor...")
                    ActivityCompat.requestPermissions(
                        this,
                        arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                        NOTIFICATION_PERMISSION_CODE
                    )
                } else {
                    Log.d(TAG, "✅ Bildirim izni zaten var")
                }
            } else {
                Log.d(TAG, "✅ Android 13 altı - bildirim izni gerekmiyor")
            }
        } catch (e: Exception) {
            Log.e(TAG, "requestNotificationPermission error: ${e.message}", e)
        }
    }

    private fun checkNotificationPermission(): Boolean {
        return try {
            when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU -> {
                    val hasPermission = ContextCompat.checkSelfPermission(
                        this, 
                        Manifest.permission.POST_NOTIFICATIONS
                    ) == PackageManager.PERMISSION_GRANTED
                    
                    Log.d(TAG, "📱 Android 13+ bildirim izni: $hasPermission")
                    hasPermission
                }
                else -> {
                    val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    val areEnabled = notificationManager.areNotificationsEnabled()
                    
                    Log.d(TAG, "📱 Android 12- bildirim durumu: $areEnabled")
                    areEnabled
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "checkNotificationPermission error: ${e.message}", e)
            false
        }
    }

    private fun openNotificationSettings() {
        try {
            val intent = Intent().apply {
                when {
                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.O -> {
                        action = Settings.ACTION_APP_NOTIFICATION_SETTINGS
                        putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                        Log.d(TAG, "📱 Android 8+ bildirim ayarları açılıyor")
                    }
                    else -> {
                        action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                        data = Uri.parse("package:$packageName")
                        Log.d(TAG, "📱 Uygulama detay ayarları açılıyor")
                    }
                }
            }
            startActivity(intent)
            Log.d(TAG, "✅ Ayarlar başarıyla açıldı")
        } catch (e: Exception) {
            Log.e(TAG, "openNotificationSettings error: ${e.message}", e)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        try {
            when (requestCode) {
                NOTIFICATION_PERMISSION_CODE -> {
                    if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                        Log.d(TAG, "✅ Bildirim izni kullanıcı tarafından verildi")
                    } else {
                        Log.w(TAG, "❌ Bildirim izni kullanıcı tarafından reddedildi")
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "onRequestPermissionsResult error: ${e.message}", e)
        }
    }

    override fun onResume() {
        super.onResume()
        try {
            val hasNotificationPermission = checkNotificationPermission()
            val isBatteryOptimized = checkBatteryOptimization()
            
            Log.d(TAG, "🔍 onResume - İzin durumları:")
            Log.d(TAG, "  📱 Bildirim: $hasNotificationPermission")
            Log.d(TAG, "  🔋 Pil optimizasyonu: $isBatteryOptimized")
        } catch (e: Exception) {
            Log.e(TAG, "onResume error: ${e.message}", e)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "🔄 MainActivity destroyed")
    }
}