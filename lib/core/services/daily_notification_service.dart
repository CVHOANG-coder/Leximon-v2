import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

enum DailyNotificationPermissionResult { granted, denied, permanentlyDenied }

class DailyNotificationService {
  DailyNotificationService._();

  static final instance = DailyNotificationService._();

  static const _notificationId = 1001;
  static const _channelId = 'daily_learning_reminder';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    const androidSettings = AndroidInitializationSettings(
      'ic_stat_notification',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
    );
    _initialized = true;
  }

  Future<DailyNotificationPermissionResult> requestPermission() async {
    await _initialize();

    if (Platform.isAndroid) {
      final granted =
          await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
      return granted
          ? DailyNotificationPermissionResult.granted
          : DailyNotificationPermissionResult.denied;
    }
    if (Platform.isIOS) {
      final currentStatus = await Permission.notification.status;
      if (currentStatus.isGranted || currentStatus.isProvisional) {
        return DailyNotificationPermissionResult.granted;
      }
      if (currentStatus.isPermanentlyDenied) {
        return DailyNotificationPermissionResult.permanentlyDenied;
      }

      final requestedStatus = await Permission.notification.request();
      if (requestedStatus.isGranted || requestedStatus.isProvisional) {
        return DailyNotificationPermissionResult.granted;
      }
      return DailyNotificationPermissionResult.denied;
    }
    return DailyNotificationPermissionResult.granted;
  }

  Future<void> scheduleDaily({required int hour, required int minute}) async {
    await _initialize();
    await cancelDaily();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: _notificationId,
      title: 'Đến giờ học rồi! 📚',
      body: 'Dành vài phút ôn từ vựng cùng Leximon nhé.',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Nhắc học hằng ngày',
          channelDescription:
              'Thông báo nhắc bạn duy trì thói quen học từ vựng.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDaily() async {
    await _initialize();
    await _plugin.cancel(id: _notificationId);
  }
}
