import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      tz.initializeTimeZones();
      // Use Tokyo time as default for IT Passport (mostly Japanese users)
      // If local detection fails, this ensures a valid location.
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
      } catch (e) {
        // Fallback to UTC if even Tokyo fails
        tz.setLocalLocation(tz.UTC);
      }

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    } catch (e) {
      print('NotificationService init error: $e');
      // Non-blocking error
    }
  }

  Future<void> requestPermission() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleDailyReminder() async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        0, // ID
        '学習の時間です',
        '本日のノルマはまだ達成されていません。少しだけ頑張りましょう！',
        _nextInstance(21, 0), // 21:00
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            'Daily Reminder',
            channelDescription: 'Reminds you to study if you haven\'t finished your quota',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at this time
      );
    } catch (e) {
      print('Schedule error: $e');
    }
  }

  // Cancel specifically for today (actually just cancels the daily recurring ID, then reschedules for tomorrow)
  // But since we use matchDateTimeComponents.time, it repeats daily.
  // To "skip" today, we can just cancel it. 
  // However, cancelling execution 0 means it won't ring tomorrow either unless we reschedule.
  // So the logic should be: call this when quota is reached.
  // It cancels ID 0. Then schedules a ONE-OFF for tomorrow 21:00? 
  // OR: We just let it ring. The user said "if quota is not met". 
  // So checking quota *at the time of notification* is hard with local notifications (needs background execution).
  // Strategy:
  // 1. Always schedule daily at 21:00.
  // 2. When user finishes quota in app -> Cancel ID 0.
  // 3. Then Schedule ID 0 starting from *Tomorrow* 21:00 (Daily).
  Future<void> completeForToday() async {
    await flutterLocalNotificationsPlugin.cancel(0);
    
    // Reschedule for tomorrow
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      '学習の時間です',
      '本日のノルマはまだ達成されていません。少しだけ頑張りましょう！',
      _nextInstance(21, 0, forceTomorrow: true),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminder',
          channelDescription: 'Reminds you to study if you haven\'t finished your quota',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstance(int hour, int minute, {bool forceTomorrow = false}) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (forceTomorrow || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
