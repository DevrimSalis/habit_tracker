import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/habit.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  static const platform = MethodChannel('com.devira.basitaliskanliktakipcim/battery');

  NotificationService._internal();

  factory NotificationService() => _instance;

  static Future<void> init() async {
    await initialize();
  }

  static Future<void> initialize() async {
    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'habit_tracker_channel',
        'Alışkanlık Hatırlatıcıları',
        description: 'Günlük alışkanlık takibi için bildirimler',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  static Future<bool> requestAllPermissions() async {
    try {
      // Android 13+ bildirim izni
      await Permission.notification.request();
      
      // Exact alarm izni
      await Permission.scheduleExactAlarm.request();

      // Native platform izni
      try {
        await platform.invokeMethod('requestNotificationPermission');
      } catch (e) {
        // Hata durumunda devam et
      }

      // Flutter plugin izni
      final androidImpl = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImpl != null) {
        await androidImpl.requestNotificationsPermission();
        await androidImpl.requestExactAlarmsPermission();
      }

      return await checkAllPermissions();
    } catch (e) {
      return false;
    }
  }

  static Future<bool> checkAllPermissions() async {
    try {
      bool hasNotification = await Permission.notification.isGranted;
      bool hasExactAlarm = await Permission.scheduleExactAlarm.isGranted;
      
      final androidImpl = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      bool areEnabled = true;
      if (androidImpl != null) {
        areEnabled = await androidImpl.areNotificationsEnabled() ?? false;
      }

      return hasNotification && hasExactAlarm && areEnabled;
    } catch (e) {
      return false;
    }
  }

  static Future<void> scheduleHabitReminder(Habit habit) async {
    if (!habit.isReminderEnabled || habit.reminderTime == null) {
      return;
    }

    try {
      await cancelHabitReminder(habit.id!);

      final now = DateTime.now();
      final reminderTime = habit.reminderTime!;
              
      var notificationDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        reminderTime.hour,
        reminderTime.minute,
      );

      if (notificationDateTime.isBefore(now) || notificationDateTime.isAtSameMomentAs(now)) {
        notificationDateTime = notificationDateTime.add(const Duration(days: 1));
      }

      // DOĞRUDAN TZDateTime oluştur - TELEFONDA ÇALIŞIR
      final notificationTime = tz.TZDateTime(
        tz.getLocation('Europe/Istanbul'),
        notificationDateTime.year,
        notificationDateTime.month,
        notificationDateTime.day,
        notificationDateTime.hour,
        notificationDateTime.minute,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        habit.id!,
        '🔔 Alışkanlık Hatırlatması',
        '${habit.name} yapma zamanı geldi! 💪',
        notificationTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_tracker_channel',
            'Alışkanlık Hatırlatıcıları',
            channelDescription: 'Günlük alışkanlık takibi için bildirimler',
            importance: Importance.max,
            priority: Priority.max,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
            autoCancel: false,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation: 
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  static Future<void> cancelHabitReminder(int habitId) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(habitId);
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  static Future<void> openNotificationSettings() async {
    try {
      await platform.invokeMethod('openNotificationSettings');
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  static String formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}