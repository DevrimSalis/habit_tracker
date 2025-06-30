import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/habit.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  factory NotificationService() => _instance;

  static Future<void> initialize() async {
    tz.initializeTimeZones();
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

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Android 13+ için bildirim izni iste
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  static Future<void> scheduleHabitReminder(Habit habit) async {
    if (!habit.isReminderEnabled || habit.reminderTime == null) return;

    // Mevcut bildirimi iptal et
    await cancelHabitReminder(habit.id!);

    final now = tz.TZDateTime.now(tz.local);
    final reminderTime = habit.reminderTime!;
        
    // Hatırlatma zamanını 5 dakika öncesine ayarla
    final notificationTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      reminderTime.hour,
      reminderTime.minute - 5, // 5 dakika önce
    );

    // Eğer zaman geçmişse, yarına ayarla
    final scheduledTime = notificationTime.isBefore(now)
        ? notificationTime.add(const Duration(days: 1))
        : notificationTime;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      habit.id!,
      'Alışkanlık Hatırlatması',
      '${habit.name} için zamanınız yaklaştı! 5 dakika kaldı.',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminders',
          'Alışkanlık Hatırlatmaları',
          channelDescription: 'Alışkanlık hatırlatma bildirimleri',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, // Her gün tekrarla
    );
  }

  static Future<void> cancelHabitReminder(int habitId) async {
    await flutterLocalNotificationsPlugin.cancel(habitId);
  }

  static Future<void> cancelAllReminders() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  static String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}