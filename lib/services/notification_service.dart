  import 'package:flutter_local_notifications/flutter_local_notifications.dart';
  import 'package:timezone/timezone.dart' as tz;
  import 'package:timezone/data/latest.dart' as tz;
  import 'package:flutter/material.dart';
  import 'package:flutter/foundation.dart';
  import 'package:flutter/services.dart';
  import 'package:permission_handler/permission_handler.dart';
  import '../models/habit.dart';

  class NotificationService {
    static final NotificationService _instance = NotificationService._internal();
    static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    
    static const platform = MethodChannel('com.devira.basitaliskanliktakip/battery');

    NotificationService._internal();

    factory NotificationService() => _instance;

    static Future<void> init() async {
      await initialize();
    }

    static Future<void> initialize() async {
      try {
        tz.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

        // Android kanalı oluştur
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'habit_reminders',
          'Alışkanlık Hatırlatmaları',
          description: 'Günlük alışkanlık hatırlatma bildirimleri',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFF667eea),
        );

        // Kanalı sisteme kaydet
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);

        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');

        const DarwinInitializationSettings initializationSettingsIOS =
            DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          requestCriticalPermission: false,
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

        // İzinleri iste
        await _requestNotificationPermissions();

        if (kDebugMode) {
          debugPrint("✅ NotificationService başarıyla başlatıldı");
          // Test bildirimi gönder
          await showTestNotification();
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint("❌ NotificationService başlatma hatası: $e");
        }
      }
    }

    static Future<void> _requestNotificationPermissions() async {
      try {
        // Android 13+ için bildirim izni
        if (await Permission.notification.isDenied) {
          final status = await Permission.notification.request();
          if (kDebugMode) {
            debugPrint("📱 Bildirim izni: $status");
          }
        }

        // Tam alarm izni (Android 12+)
        if (await Permission.scheduleExactAlarm.isDenied) {
          final status = await Permission.scheduleExactAlarm.request();
          if (kDebugMode) {
            debugPrint("⏰ Tam alarm izni: $status");
          }
        }

        // Android için ek izinler
        final androidImpl = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidImpl != null) {
          final bool? result = await androidImpl.requestNotificationsPermission();
          if (kDebugMode) {
            debugPrint("📱 Android bildirim izni: $result");
          }
          
          // Exact alarm izni kontrolü (Android 12+)
          final bool? exactAlarmResult = await androidImpl.requestExactAlarmsPermission();
          if (kDebugMode) {
            debugPrint("⏰ Exact alarm izni: $exactAlarmResult");
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint("❌ İzin hatası: $e");
        }
      }
    }

    static void _onNotificationTapped(NotificationResponse response) {
      if (kDebugMode) {
        debugPrint("📱 Bildirime tıklandı: ${response.payload}");
      }
    }

    static Future<void> scheduleHabitReminder(Habit habit) async {
      if (!habit.isReminderEnabled || habit.reminderTime == null) {
        if (kDebugMode) {
          debugPrint("❌ Hatırlatma etkin değil veya saat belirlenmemiş");
        }
        return;
      }

      try {
        // Önce eski hatırlatmayı iptal et
        await cancelHabitReminder(habit.id!);

        final now = tz.TZDateTime.now(tz.getLocation('Europe/Istanbul'));
        final reminderTime = habit.reminderTime!;
              
        // Hatırlatma zamanını hesapla
        var notificationTime = tz.TZDateTime(
          tz.getLocation('Europe/Istanbul'),
          now.year,
          now.month,
          now.day,
          reminderTime.hour,
          reminderTime.minute,
        );

        // Eğer zaman geçmişse, ertesi güne ayarla
        if (notificationTime.isBefore(now)) {
          notificationTime = notificationTime.add(const Duration(days: 1));
        }

        if (kDebugMode) {
          debugPrint("🕐 Şu anki zaman: $now");
          debugPrint("⏰ Hedef zaman: $notificationTime");
          debugPrint("📅 Zaman farkı: ${notificationTime.difference(now).inMinutes} dakika");
        }

        // Günlük tekrarlama için
        await flutterLocalNotificationsPlugin.zonedSchedule(
          habit.id!,
          '🔔 Alışkanlık Hatırlatması',
          '${habit.name} yapma zamanı geldi! 💪',
          notificationTime,
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
              autoCancel: false,
              ongoing: false,
              ticker: 'Alışkanlık zamanı!',
              color: Color(0xFF667eea),
              // Tam ekran bildirim
              fullScreenIntent: true,
              // Kategori
              category: AndroidNotificationCategory.reminder,
              // Android için ek ayarlar
              channelShowBadge: true,
              showWhen: true,
              when: null,
              usesChronometer: false,
              onlyAlertOnce: false,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              sound: 'default',
              categoryIdentifier: 'habit_reminder',
              threadIdentifier: 'habit_reminders',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time, // Günlük tekrar
          uiLocalNotificationDateInterpretation: 
              UILocalNotificationDateInterpretation.absoluteTime,
        );

        if (kDebugMode) {
          debugPrint("✅ Hatırlatma zamanlandı: ${habit.name} - ${formatTimeOfDay(reminderTime)}");
          debugPrint("📅 Zamanlanan saat: $notificationTime");
          
          // Bekleyen bildirimleri kontrol et
          final pending = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
          debugPrint("📋 Toplam bekleyen bildirim: ${pending.length}");
          for (var p in pending) {
            debugPrint("  - ID: ${p.id}, Başlık: ${p.title}");
          }
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

    // Test bildirimi - hemen gönderilir
    static Future<void> showTestNotification() async {
      try {
        const AndroidNotificationDetails androidDetails = 
            AndroidNotificationDetails(
          'habit_reminders',
          'Alışkanlık Hatırlatmaları',
          channelDescription: 'Test amaçlı bildirimler',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          ticker: 'Test bildirimi',
          color: Color(0xFF667eea),
          playSound: true,
          enableVibration: true,
        );

        const NotificationDetails notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        );

        await flutterLocalNotificationsPlugin.show(
          999,
          '🎉 Test Bildirimi',
          'Bildirim sistemi çalışıyor! ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          notificationDetails,
        );
        
        if (kDebugMode) {
          debugPrint("✅ Test bildirimi gönderildi");
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint("❌ Test bildirimi hatası: $e");
        }
      }
    }

    // 1 dakika sonra test bildirimi - zamanlama test için
    static Future<void> scheduleTestNotification() async {
      try {
        final now = tz.TZDateTime.now(tz.getLocation('Europe/Istanbul'));
        final scheduledTime = now.add(const Duration(minutes: 1));

        await flutterLocalNotificationsPlugin.zonedSchedule(
          998,
          '⏰ Zamanlı Test',
          'Bu bildirim 1 dakika sonra geldi! Saat: ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}',
          scheduledTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'habit_reminders',
              'Alışkanlık Hatırlatmaları',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              color: Color(0xFF667eea),
              playSound: true,
              enableVibration: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: 
              UILocalNotificationDateInterpretation.absoluteTime,
        );

        if (kDebugMode) {
          debugPrint("✅ Test bildirimi zamanlandı: $scheduledTime");
          debugPrint("🕐 Şu anki zaman: $now");
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint("❌ Test bildirimi zamanlama hatası: $e");
        }
      }
    }

    // İzin durumlarını kontrol et
    static Future<Map<String, bool>> checkPermissions() async {
      final permissions = <String, bool>{};
      
      try {
        permissions['notification'] = await Permission.notification.isGranted;
        permissions['scheduleExactAlarm'] = await Permission.scheduleExactAlarm.isGranted;
        
        final androidImpl = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidImpl != null) {
          permissions['areNotificationsEnabled'] = 
              await androidImpl.areNotificationsEnabled() ?? false;
        }
        
        if (kDebugMode) {
          debugPrint("📱 İzin durumları:");
          permissions.forEach((key, value) {
            debugPrint("  - $key: $value");
          });
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint("❌ İzin kontrolü hatası: $e");
        }
      }
      
      return permissions;
    }

    // İzin kontrolü ve isteme metodları
    static Future<bool> requestAllPermissions() async {
      try {
        // 1. Android native bildirim izni
        final bool? nativePermission = await platform.invokeMethod('requestNotificationPermission');
        
        if (kDebugMode) {
          debugPrint("📱 Native bildirim izni: $nativePermission");
        }
        
        // 2. Flutter plugin izinleri
        await _requestNotificationPermissions();
        
        // 3. Pil optimizasyonu - Sadece gerektiğinde iste
        final bool? batteryOptimized = await platform.invokeMethod('checkBatteryOptimization');
        if (batteryOptimized == true) {
          if (kDebugMode) {
            debugPrint("⚠️ Pil optimizasyonu aktif, kullanıcıya seçenek sunuluyor");
          }
          // Burada kullanıcıya dialog gösterip sorabilirsiniz
          // await platform.invokeMethod('requestBatteryOptimization');
        } else {
          if (kDebugMode) {
            debugPrint("✅ Pil optimizasyonu zaten devre dışı");
          }
        }
        
        // 4. İzin durumunu kontrol et
        final permissions = await checkAllPermissions();
        
        if (kDebugMode) {
          debugPrint("📱 Tüm izin durumları:");
          permissions.forEach((key, value) {
            debugPrint("  - $key: $value");
          });
        }
        
        return permissions.values.every((granted) => granted == true);
      } catch (e) {
        if (kDebugMode) {
          debugPrint("❌ İzin isteme hatası: $e");
        }
        return false;
      }
    }

    static Future<Map<String, bool>> checkAllPermissions() async {
      final permissions = <String, bool>{};
      
      try {
        // Native Android izni
        final bool? nativeCheck = await platform.invokeMethod('checkNotificationPermission');
        permissions['nativeNotification'] = nativeCheck ?? false;
        
        // Plugin izinleri
        permissions['notification'] = await Permission.notification.isGranted;
        permissions['scheduleExactAlarm'] = await Permission.scheduleExactAlarm.isGranted;
        
        // Flutter local notifications
        final androidImpl = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidImpl != null) {
          permissions['areNotificationsEnabled'] = 
              await androidImpl.areNotificationsEnabled() ?? false;
        }
        
      } catch (e) {
        if (kDebugMode) {
          debugPrint("❌ İzin kontrolü hatası: $e");
        }
      }
      
      return permissions;
    }

    static Future<void> openNotificationSettings() async {
      try {
        await platform.invokeMethod('openNotificationSettings');
      } catch (e) {
        if (kDebugMode) {
          debugPrint("❌ Ayarları açma hatası: $e");
        }
      }
    }

    // Pil optimizasyonu kontrolü ve isteği
    static Future<bool> checkAndRequestBatteryOptimization() async {
      try {
        final bool? isOptimized = await platform.invokeMethod('checkBatteryOptimization');
        
        if (kDebugMode) {
          debugPrint("🔋 Pil optimizasyonu durumu: $isOptimized");
        }
        
        if (isOptimized == true) {
          // Kullanıcıya pil optimizasyonunu kapatmayı öner
          return await platform.invokeMethod('requestBatteryOptimization') ?? false;
        }
        
        return true; // Zaten optimizasyon kapalı
      } catch (e) {
        if (kDebugMode) {
          debugPrint("❌ Pil optimizasyonu kontrolü hatası: $e");
        }
        return false;
      }
    }

    // Gelişmiş bildirim test metodu
    static Future<void> testNotificationWithFullCheck() async {
      try {
        if (kDebugMode) {
          debugPrint("🧪 Detaylı bildirim testi başlıyor...");
        }
        
        // İzinleri kontrol et
        final permissions = await checkAllPermissions();
        if (kDebugMode) {
          debugPrint("📋 İzin durumları: $permissions");
        }
        
        // Eksik izin varsa kullanıcıyı uyar
        final hasAllPermissions = permissions.values.every((granted) => granted == true);
        if (!hasAllPermissions) {
          if (kDebugMode) {
            debugPrint("⚠️ Eksik izinler tespit edildi, kullanıcı uyarılacak");
          }
        }
        
        // Test bildirimi gönder
        await showTestNotification();
        
        // 2 dakika sonra zamanlı test
        final now = tz.TZDateTime.now(tz.getLocation('Europe/Istanbul'));
        final testTime = now.add(const Duration(minutes: 2));
        
        await flutterLocalNotificationsPlugin.zonedSchedule(
          997,
          '🔥 Kritik Test',
          'Bu bildirim ${testTime.hour}:${testTime.minute.toString().padLeft(2, '0')} zamanlandı. Geldi mi?',
          testTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'habit_reminders',
              'Alışkanlık Hatırlatmaları',
              channelDescription: 'Test bildirimi',
              importance: Importance.max,
              priority: Priority.max,
              icon: '@mipmap/ic_launcher',
              color: Color(0xFF667eea),
              playSound: true,
              enableVibration: true,
              // Kritical ayarlar
              fullScreenIntent: true,
              category: AndroidNotificationCategory.alarm,
              visibility: NotificationVisibility.public,
              showWhen: true,
              autoCancel: false,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: 
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        
        if (kDebugMode) {
          debugPrint("✅ Test bildirimi 2 dakika sonraya zamanlandı: $testTime");
        }
        
      } catch (e) {
        if (kDebugMode) {
          debugPrint("❌ Test bildirimi hatası: $e");
        }
      }
    }

    static tz.TZDateTime getTurkeyTime() {
      return tz.TZDateTime.now(tz.getLocation('Europe/Istanbul'));
    }

    static String formatTurkeyTime(DateTime dateTime) {
      final turkeyDateTime = tz.TZDateTime.from(dateTime, tz.getLocation('Europe/Istanbul'));
      return '${turkeyDateTime.hour.toString().padLeft(2, '0')}:${turkeyDateTime.minute.toString().padLeft(2, '0')}';
    }

    static Future<List<PendingNotificationRequest>> getPendingReminders() async {
      try {
        final pending = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
        if (kDebugMode) {
          debugPrint("📋 Bekleyen bildirimler: ${pending.length}");
          for (var notification in pending) {
            debugPrint("  - ID: ${notification.id}, Başlık: ${notification.title}");
          }
        }
        return pending;
      } catch (e) {
        if (kDebugMode) {
          debugPrint("❌ Bekleyen hatırlatmaları alma hatası: $e");
        }
        return [];
      }
    }

    static String formatTimeOfDay(TimeOfDay time) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }