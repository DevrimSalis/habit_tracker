package com.devira.basitaliskanliktakipcim

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
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
            
            // Otomatik izin kontrolü - Release modda daha güvenli
            checkAndRequestPermissions()
        } catch (e: Exception) {
            Log.e(TAG, "onCreate error: ${e.message}", e)
        }
    }

    private fun checkAndRequestPermissions() {
        try {
            // Android 13+ için bildirim izni kontrol et
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                if (!checkNotificationPermission()) {
                    Log.d(TAG, "Bildirim izni gerekli - kullanıcı etkileşimi bekleniyor")
                    // İlk açılışta otomatik isteme yerine Flutter tarafından tetiklensin
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "İzin kontrolü hatası: ${e.message}", e)
        }
    }

    private fun requestBatteryOptimization() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val intent = Intent()
                intent.action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                intent.data = Uri.parse("package:$packageName")
                try {
                    startActivity(intent)
                } catch (e: Exception) {
                    Log.w(TAG, "Battery optimization intent failed, trying fallback", e)
                    // Fallback - genel pil optimizasyonu ayarlarına git
                    val fallbackIntent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                    startActivity(fallbackIntent)
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
                    ActivityCompat.requestPermissions(
                        this,
                        arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                        NOTIFICATION_PERMISSION_CODE
                    )
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "requestNotificationPermission error: ${e.message}", e)
        }
    }

    private fun checkNotificationPermission(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == 
                    PackageManager.PERMISSION_GRANTED
            } else {
                // Android 13 altında bildirimler varsayılan olarak açık
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.areNotificationsEnabled()
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
                    }
                    else -> {
                        action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                        data = Uri.parse("package:$packageName")
                    }
                }
            }
            startActivity(intent)
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
                        // İzin verildi, Flutter tarafına bildir
                        Log.d(TAG, "✅ Bildirim izni verildi")
                    } else {
                        // İzin reddedildi
                        Log.w(TAG, "❌ Bildirim izni reddedildi")
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "onRequestPermissionsResult error: ${e.message}", e)
        }
    }
}