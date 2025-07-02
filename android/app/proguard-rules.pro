# Flutter Local Notifications - Temel koruma
-keep class com.dexterous.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Android Bildirim Sistemi - KRİTİK
-keep class androidx.core.app.NotificationCompat** { *; }
-keep class androidx.core.app.NotificationManagerCompat** { *; }
-keep class android.app.NotificationManager** { *; }
-keep class android.app.NotificationChannel** { *; }
-keep class android.app.PendingIntent** { *; }
-keep class android.app.AlarmManager** { *; }

# Bildirim Receivers - ÇOK ÖNEMLİ
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver { 
    <init>(...);
    public void onReceive(android.content.Context, android.content.Intent);
}
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver {
    <init>(...); 
    public void onReceive(android.content.Context, android.content.Intent);
}
-keep class com.dexterous.flutterlocalnotifications.ForegroundService {
    <init>(...);
    public int onStartCommand(android.content.Intent, int, int);
    public android.os.IBinder onBind(android.content.Intent);
}

# MainActivity Method Channels - KRİTİK
-keep class com.devira.basitaliskanliktakipcim.MainActivity {
    <init>(...);
    public void configureFlutterEngine(io.flutter.embedding.engine.FlutterEngine);
    private void requestNotificationPermission();
    private boolean checkNotificationPermission();
    private void openNotificationSettings();
    private void requestBatteryOptimization();
    private boolean checkBatteryOptimization();
}

# Flutter Plugin System - ÇOK ÖNEMLİ
-keep class io.flutter.plugin.common.MethodChannel** { *; }
-keep class io.flutter.plugin.common.MethodCall** { *; }
-keep class io.flutter.plugin.common.MethodChannel$Result** { *; }
-keep class io.flutter.embedding.engine.plugins.** { *; }

# Android İzin Sistemi - KRİTİK
-keep class android.Manifest** { *; }
-keep class android.content.pm.PackageManager** { *; }
-keep class androidx.core.app.ActivityCompat** { *; }
-keep class androidx.core.content.ContextCompat** { *; }

# Intent ve Settings - KRİTİK
-keep class android.content.Intent** { *; }
-keep class android.net.Uri** { *; }
-keep class android.provider.Settings** { *; }
-keep class android.os.PowerManager** { *; }

# Timezone - Bildirim zamanlaması için
-keep class org.threeten.bp.** { *; }
-dontwarn org.threeten.bp.**

# Kotlin Reflection - Flutter için gerekli
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}

# Enums - Android API'leri için
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Annotation'lar - Çalışma zamanı için
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Log sistemi - Debug için
-keep class android.util.Log { *; }

# Parcelable - Android component'ler için
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Native metotlar - Flutter engine için
-keepclasseswithmembernames class * {
    native <methods>;
}

# Javascript Interface - WebView kullanımı için
-keepclassmembers class ** {
    @android.webkit.JavascriptInterface <methods>;
}

# Build Config ve Resources
-keep class **.BuildConfig { *; }
-keep class **.R$* { *; }

# Flutter Engine - Ana sistem
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }

# Android Services - Bildirimler için kritik
-keep class * extends android.app.Service {
    <init>(...);
    public int onStartCommand(android.content.Intent, int, int);
    public android.os.IBinder onBind(android.content.Intent);
}

# Broadcast Receivers - Boot ve bildirimler için
-keep class * extends android.content.BroadcastReceiver {
    <init>(...);
    public void onReceive(android.content.Context, android.content.Intent);
}

# WorkManager - Arka plan işleri için
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# AndroidX Core - Modern Android için
-keep class androidx.core.** { *; }
-dontwarn androidx.core.**

# Genel koruma - Kritik sistem sınıfları
-keep class android.content.Context** { *; }
-keep class android.app.Application** { *; }
-keep class android.os.Bundle** { *; }

# Son güvenlik - R8 agresif optimizasyonları engelle
-dontoptimize
-dontobfuscate