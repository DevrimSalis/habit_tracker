# Flutter Local Notifications - Mevcut kurallar
-keep class com.dexterous.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Android Bildirim Sınıfları - YENİ KURALLAR
-keep class androidx.core.app.NotificationCompat { *; }
-keep class androidx.core.app.NotificationManagerCompat { *; }
-keep class android.app.** { *; }
-keep class * extends android.app.Service { *; }
-keep class * extends android.content.BroadcastReceiver { *; }
-dontwarn androidx.core.**
-dontwarn android.support.**

# Scheduled notification receiver için - YENİ KURALLAR
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ForegroundService { *; }

# Flutter plugin'leri için - YENİ KURALLAR
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }

# Method channels için - YENİ KURALLAR
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.plugin.common.MethodChannel { *; }
-keep class io.flutter.plugin.common.MethodChannel$* { *; }

# MainActivity için - YENİ KURALLAR
-keep class com.devira.basitaliskanliktakipcim.MainActivity { *; }
-keep class com.devira.basitaliskanliktakipcim.MainActivity$* { *; }

# Android permissions için - YENİ KURALLAR
-keep class android.Manifest { *; }
-keep class android.Manifest$* { *; }
-keep class android.content.pm.PackageManager { *; }
-keep class androidx.core.app.ActivityCompat { *; }
-keep class androidx.core.content.ContextCompat { *; }

# Notification channels için - YENİ KURALLAR
-keep class android.app.NotificationChannel { *; }
-keep class android.app.NotificationManager { *; }
-keep class android.app.PendingIntent { *; }

# Intent ve URI sınıfları için - YENİ KURALLAR
-keep class android.content.Intent { *; }
-keep class android.net.Uri { *; }
-keep class android.provider.Settings { *; }

# Kotlin reflection - YENİ KURALLAR
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}

# Bundle ve Parcelable için - YENİ KURALLAR
-keep class android.os.Bundle { *; }
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Genel Android kuralları - YENİ KURALLAR
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Enum sınıfları için - YENİ KURALLAR
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Log sınıfları için - YENİ KURALLAR
-keep class android.util.Log { *; }

# Şüpheli durumlar için daha geniş koruma - YENİ KURALLAR
-keepclassmembers class ** {
    @android.webkit.JavascriptInterface <methods>;
}

# Flutter native methods - YENİ KURALLAR
-keepclasseswithmembernames class * {
    native <methods>;
}

# Build config - YENİ KURALLAR
-keep class **.BuildConfig { *; }

# R sınıfları - YENİ KURALLAR
-keep class **.R$* { *; }