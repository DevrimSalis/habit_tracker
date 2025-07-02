import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/habit.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static const platform = MethodChannel('com.devira.basitaliskanliktakipcim/battery');

  NotificationService._internal();

  factory NotificationService() => _instance;

  static Future<void> init() async {
    await initialize();
  }

  static Future<void> initialize() async {
    try {
      debugPrint('🚀 NotificationService (AlarmManager) başlatılıyor...');
      debugPrint('✅ AlarmManager NotificationService başarıyla başlatıldı');
    } catch (e) {
      debugPrint('❌ NotificationService başlatma hatası: $e');
    }
  }

  static Future<bool> requestAllPermissions() async {
    try {
      debugPrint('🔐 İzinler isteniyor...');
      
      // Temel izinler
      await Permission.notification.request();
      await Permission.scheduleExactAlarm.request();

      // Native izinler
      try {
        await platform.invokeMethod('requestNotificationPermission');
        await platform.invokeMethod('requestBatteryOptimization');
        debugPrint('🤖 Native izinler istendi');
      } catch (e) {
        debugPrint('⚠️ Native izin hatası: $e');
      }

      final hasAllPermissions = await checkAllPermissions();
      debugPrint(hasAllPermissions ? '✅ Tüm izinler tamam' : '❌ İzinler eksik');
      return hasAllPermissions;
    } catch (e) {
      debugPrint('❌ İzin alma genel hatası: $e');
      return false;
    }
  }

  static Future<bool> checkAllPermissions() async {
    try {
      final hasNotification = await Permission.notification.isGranted;
      final hasExactAlarm = await Permission.scheduleExactAlarm.isGranted;

      // Native izinleri kontrol et
      bool hasBatteryOptimization = false;
      
      try {
        hasBatteryOptimization = await platform.invokeMethod('checkBatteryOptimization');
      } catch (e) {
        debugPrint('⚠️ Native izin kontrolü hatası: $e');
      }

      debugPrint('📊 İzin Durumları:');
      debugPrint('  📱 Bildirim: $hasNotification');
      debugPrint('  ⏰ Exact Alarm: $hasExactAlarm');
      debugPrint('  🔋 Pil Opt.: $hasBatteryOptimization');

      return hasNotification && hasExactAlarm;
    } catch (e) {
      debugPrint('❌ İzin kontrol hatası: $e');
      return false;
    }
  }

  // ALARMMANAGER İLE BİLDİRİM ZAMANLAMA
  static Future<void> scheduleHabitReminder(Habit habit) async {
    if (!habit.isReminderEnabled || habit.reminderTime == null) {
      debugPrint('⚠️ Hatırlatma kapalı veya saat belirlenmemiş');
      return;
    }

    try {
      debugPrint('⏰ ALARMMANAGER ile bildirim zamanlanıyor: "${habit.name}"');
      
      // AlarmManager ile zamanla
      await platform.invokeMethod('scheduleAlarm', {
        'habitId': habit.id!,
        'habitName': habit.name,
        'hour': habit.reminderTime!.hour,
        'minute': habit.reminderTime!.minute,
      });

      debugPrint('✅ AlarmManager bildirimi zamanlandı: ${habit.name}');

      // Test için - 10 saniye sonra (debug modda)
      if (kDebugMode) {
        final now = DateTime.now();
        final testTime = now.add(const Duration(seconds: 10));
        
        await platform.invokeMethod('scheduleAlarm', {
          'habitId': habit.id! + 999,
          'habitName': '🧪 TEST: ${habit.name}',
          'hour': testTime.hour,
          'minute': testTime.minute,
        });

        debugPrint('🧪 Test alarm 10 saniye sonra zamanlandı');
      }

    } catch (e) {
      debugPrint('❌ AlarmManager zamanlama hatası: $e');
    }
  }

  static Future<void> cancelHabitReminder(int habitId) async {
    try {
      await platform.invokeMethod('cancelAlarm', {'habitId': habitId});
      await platform.invokeMethod('cancelAlarm', {'habitId': habitId + 999}); // Test
      debugPrint('🗑️ AlarmManager bildirimi iptal edildi: ID $habitId');
    } catch (e) {
      debugPrint('❌ Alarm iptal hatası: $e');
    }
  }

  static Future<void> openNotificationSettings() async {
    try {
      await platform.invokeMethod('openNotificationSettings');
      debugPrint('⚙️ Bildirim ayarları açıldı');
    } catch (e) {
      debugPrint('❌ Ayarlar açma hatası: $e');
    }
  }

  static String formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}