import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/habit.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  factory NotificationService() => _instance;

  // main.dart'ta çağrılacak init metodu
  static Future<void> init() async {
    await initialize();
  }

  static Future<void> initialize() async {
    try {
      tz.initializeTimeZones();
      // Türkiye saat dilimini ayarla
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Türkçe bildirim izni iste
      await _requestNotificationPermissions();

      if (kDebugMode) {
        debugPrint("✅ NotificationService başarıyla başlatıldı (Türkiye saati)");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ NotificationService başlatma hatası: $e");
      }
    }
  }

  // Türkçe bildirim izinleri
  static Future<void> _requestNotificationPermissions() async {
    // Android için
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      if (kDebugMode) {
        debugPrint("📱 Bildirim izni durumu: $status");
      }
    }

    // Android 12+ için tam alarm izni
    if (await Permission.scheduleExactAlarm.isDenied) {
      final status = await Permission.scheduleExactAlarm.request();
      if (kDebugMode) {
        debugPrint("⏰ Tam zamanlı alarm izni durumu: $status");
      }
    }
  }

  // Bildirime tıklandığında çalışır
  static void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      debugPrint("Bildirime tıklandı: ${response.payload}");
    }
    // Burada istediğiniz işlemi yapabilirsiniz
  }

  static Future<void> scheduleHabitReminder(Habit habit) async {
    if (!habit.isReminderEnabled || habit.reminderTime == null) return;

    try {
      // Mevcut bildirimi iptal et
      await cancelHabitReminder(habit.id!);

      // Türkiye saati ile şimdiki zaman
      final now = tz.TZDateTime.now(tz.getLocation('Europe/Istanbul'));
      final reminderTime = habit.reminderTime!;
             
      // Hatırlatma zamanını Türkiye saati ile ayarla
      final notificationTime = tz.TZDateTime(
        tz.getLocation('Europe/Istanbul'),
        now.year,
        now.month,
        now.day,
        reminderTime.hour,
        reminderTime.minute,
      );

      // Eğer zaman geçmişse, ertesi güne ayarla
      final scheduledTime = notificationTime.isBefore(now)
          ? notificationTime.add(const Duration(days: 1))
          : notificationTime;

      await flutterLocalNotificationsPlugin.zonedSchedule(
        habit.id!,
        '🔔 Alışkanlık Hatırlatması',
        '${habit.name} yapma zamanı geldi! 💪',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_reminders',
            'Alışkanlık Hatırlatmaları',
            channelDescription: 'Günlük alışkanlık hatırlatma bildirimleri',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('notification'),
            ticker: 'Alışkanlık hatırlatması',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation: 
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      if (kDebugMode) {
        debugPrint("✅ Hatırlatma zamanlandı: ${habit.name} - ${formatTimeOfDay(reminderTime)} (Türkiye saati)");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Hatırlatma zamanlama hatası: $e");
      }
    }
  }

  static Future<void> cancelHabitReminder(int habitId) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(habitId);
      if (kDebugMode) {
        debugPrint("✅ Hatırlatma iptal edildi: $habitId");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Hatırlatma iptal etme hatası: $e");
      }
    }
  }

  static Future<void> cancelAllReminders() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      if (kDebugMode) {
        debugPrint("✅ Tüm hatırlatmalar iptal edildi");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Tüm hatırlatmaları iptal etme hatası: $e");
      }
    }
  }

  // Test bildirimi gönder
  static Future<void> showTestNotification() async {
    try {
      const AndroidNotificationDetails androidDetails = 
          AndroidNotificationDetails(
        'test_channel',
        'Test Bildirimleri',
        channelDescription: 'Test amaçlı bildirimler',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        ticker: 'Test bildirimi',
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await flutterLocalNotificationsPlugin.show(
        999,
        '🎉 Test Bildirimi',
        'Bildirim sistemi Türkiye saati ile çalışıyor!',
        notificationDetails,
      );
      
      if (kDebugMode) {
        debugPrint("✅ Test bildirimi gönderildi (Türkiye saati)");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Test bildirimi hatası: $e");
      }
    }
  }

  // Türkiye saati ile şimdiki zamanı al
  static tz.TZDateTime getTurkeyTime() {
    return tz.TZDateTime.now(tz.getLocation('Europe/Istanbul'));
  }

  // Saat formatını Türkiye formatına çevir
  static String formatTurkeyTime(DateTime dateTime) {
    final turkeyDateTime = tz.TZDateTime.from(dateTime, tz.getLocation('Europe/Istanbul'));
    return '${turkeyDateTime.hour.toString().padLeft(2, '0')}:${turkeyDateTime.minute.toString().padLeft(2, '0')}';
  }

  // Bekleyen hatırlatmaları listele
  static Future<List<PendingNotificationRequest>> getPendingReminders() async {
    try {
      return await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Bekleyen hatırlatmaları alma hatası: $e");
      }
      return [];
    }
  }

  static String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}