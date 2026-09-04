import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../localization/app_localizations.dart';

enum DailyNotificationPermissionResult { granted, denied, permanentlyDenied }

class DailyNotificationService {
  DailyNotificationService._();

  static final instance = DailyNotificationService._();

  static const _notificationId = 1001;
  static const _saleNotificationId = 1002;
  static const saleNotificationPayload = 'annual_subscription_sale';
  static const _channelId = 'daily_learning_reminder';
  static const _saleChannelId = 'annual_subscription_sale';
  static const _saleReminderDayPreferenceKey =
      'annual_subscription_sale_notification_day';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  Future<void>? _initialization;
  bool _initialized = false;
  bool _timeZoneInitialized = false;
  void Function()? _onSaleNotificationTap;
  bool _pendingSaleNotificationTap = false;
  bool _saleReminderEligible = false;
  bool _saleReminderArmed = false;
  bool _saleReminderArmInFlight = false;
  String? _saleReminderReservedDay;
  Timer? _saleReminderRefreshTimer;

  bool get _isMobilePlatform => Platform.isAndroid || Platform.isIOS;

  Future<void> initialize({void Function()? onSaleNotificationTap}) async {
    if (onSaleNotificationTap != null) {
      _onSaleNotificationTap = onSaleNotificationTap;
    }
    if (_initialized) return;
    final initialization = _initialization ??= _initialize();
    try {
      await initialization;
      _initialized = true;
    } on Object {
      if (identical(_initialization, initialization)) {
        _initialization = null;
      }
      rethrow;
    }
  }

  Future<void> _initialize() async {
    if (!_isMobilePlatform) return;

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
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final response = launchDetails?.notificationResponse;
    if (launchDetails?.didNotificationLaunchApp == true &&
        _isSaleNotificationResponse(response)) {
      _pendingSaleNotificationTap = true;
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    if (!_isSaleNotificationResponse(response)) return;
    // Keep the tap available for SplashScreen when the callback arrives while
    // the app is still booting.
    _pendingSaleNotificationTap = true;
    final handler = _onSaleNotificationTap;
    if (handler == null) {
      return;
    }
    handler();
  }

  bool _isSaleNotificationResponse(NotificationResponse? response) =>
      response != null &&
      (response.payload == saleNotificationPayload ||
          response.id == _saleNotificationId);

  /// Returns and clears a sale notification tap captured while the app was
  /// starting. The splash screen consumes this before selecting its normal
  /// startup destination.
  bool takePendingSaleNotificationTap() {
    final pending = _pendingSaleNotificationTap;
    _pendingSaleNotificationTap = false;
    return pending;
  }

  /// Marks the onboarding subscription screen as eligible for one follow-up
  /// sale notification when the app is sent to the background.
  void markOnboardingSubscriptionScreenVisible() {
    _saleReminderEligible = true;
  }

  void markOnboardingSubscriptionCompleted() {
    _saleReminderEligible = false;
    _saleReminderRefreshTimer?.cancel();
    _saleReminderRefreshTimer = null;
    unawaited(cancelAnnualSaleNotification().catchError((_) {}));
  }

  /// Arms a Store/OS-owned notification before the app can be force-killed.
  ///
  /// The refresh timer keeps moving the notification into the future while
  /// Flutter is alive. If the process is killed, the timer stops and the
  /// already scheduled notification remains owned by Android/iOS and fires.
  Future<void> armAnnualSaleNotification({
    required AppLocalizations localizations,
    Duration delay = const Duration(minutes: 1),
  }) async {
    if (!_isMobilePlatform || _saleReminderArmInFlight) return;
    final today = _calendarDayKey(DateTime.now());
    if (_saleReminderArmed && _saleReminderReservedDay == today) return;

    _saleReminderArmInFlight = true;
    try {
      final preferences = await SharedPreferences.getInstance();
      final reservedDay = preferences.getString(_saleReminderDayPreferenceKey);
      if (reservedDay == today) {
        _saleReminderReservedDay = today;
        _saleReminderEligible = false;
        _saleReminderArmed = false;
        return;
      }

      _saleReminderEligible = true;
      _saleReminderRefreshTimer?.cancel();

      await _scheduleAnnualSaleNotification(
        localizations: localizations,
        delay: delay,
      );
      final saved = await preferences.setString(
        _saleReminderDayPreferenceKey,
        today,
      );
      if (!saved) {
        await _plugin.cancel(id: _saleNotificationId);
        _saleReminderEligible = false;
        return;
      }

      _saleReminderReservedDay = today;
      _saleReminderArmed = true;
      if (!_saleReminderEligible) return;
      _startSaleReminderRefresh(localizations: localizations, delay: delay);
    } finally {
      _saleReminderArmInFlight = false;
    }
  }

  Future<void> _refreshAnnualSaleNotification({
    required AppLocalizations localizations,
    required Duration delay,
  }) async {
    if (!_saleReminderEligible || !_saleReminderArmed) return;
    try {
      await _scheduleAnnualSaleNotification(
        localizations: localizations,
        delay: delay,
      );
    } on Object {
      // Notification support is optional and will retry on the next refresh.
    }
  }

  void _startSaleReminderRefresh({
    required AppLocalizations localizations,
    required Duration delay,
  }) {
    _saleReminderRefreshTimer?.cancel();
    _saleReminderRefreshTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => unawaited(
        _refreshAnnualSaleNotification(
          localizations: localizations,
          delay: delay,
        ),
      ),
    );
  }

  Future<void> _scheduleAnnualSaleNotification({
    required AppLocalizations localizations,
    required Duration delay,
  }) async {
    if (!_saleReminderEligible) return;
    await initialize();
    if (!_saleReminderEligible) return;
    _ensureTimeZoneInitialized();
    final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);
    await _plugin.zonedSchedule(
      id: _saleNotificationId,
      title: localizations.text('notificationSaleTitle'),
      body: localizations.text('notificationSaleBody'),
      scheduledDate: scheduledDate,
      payload: saleNotificationPayload,
      notificationDetails: _saleNotificationDetails(localizations),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelAnnualSaleNotification() async {
    if (!_isMobilePlatform) return;
    _saleReminderEligible = false;
    _saleReminderArmed = false;
    _saleReminderRefreshTimer?.cancel();
    _saleReminderRefreshTimer = null;
    await initialize();
    await _plugin.cancel(id: _saleNotificationId);
  }

  void notifyAnnualSaleIfNeeded() {
    if (!_isMobilePlatform) return;
    // The notification was pre-scheduled by one of the final onboarding
    // screens. Stop moving it forward when the app leaves the foreground.
    if (!_saleReminderEligible || !_saleReminderArmed) return;
    _saleReminderRefreshTimer?.cancel();
    _saleReminderRefreshTimer = null;
  }

  Future<void> resumeAnnualSaleNotification({
    required AppLocalizations localizations,
    Duration delay = const Duration(minutes: 1),
  }) async {
    if (!_isMobilePlatform ||
        !_saleReminderEligible ||
        !_saleReminderArmed ||
        _saleReminderRefreshTimer != null) {
      return;
    }
    await initialize();
    final pendingNotifications = await _plugin.pendingNotificationRequests();
    final hasPendingSaleNotification = pendingNotifications.any(
      (notification) => notification.id == _saleNotificationId,
    );
    if (!hasPendingSaleNotification) {
      // The reserved notification has already been delivered or dismissed.
      // Do not create a second one on the same calendar day.
      _saleReminderEligible = false;
      _saleReminderArmed = false;
      return;
    }
    await _scheduleAnnualSaleNotification(
      localizations: localizations,
      delay: delay,
    );
    if (!_saleReminderEligible || !_saleReminderArmed) return;
    _startSaleReminderRefresh(localizations: localizations, delay: delay);
  }

  String _calendarDayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  NotificationDetails _saleNotificationDetails(AppLocalizations localizations) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _saleChannelId,
        localizations.text('notificationSaleChannelName'),
        channelDescription: localizations.text(
          'notificationSaleChannelDescription',
        ),
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  Future<DailyNotificationPermissionResult> requestPermission() async {
    await initialize();

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

  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    AppLocalizations? localizations,
  }) async {
    if (!_isMobilePlatform) return;
    await initialize();
    await cancelDaily();
    _ensureTimeZoneInitialized();

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

    final l10n = localizations ?? AppLocalizations.fallback();
    await _plugin.zonedSchedule(
      id: _notificationId,
      title: l10n.text('notificationStudyTitle'),
      body: l10n.text('notificationStudyBody'),
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          l10n.text('notificationChannelName'),
          channelDescription: l10n.text('notificationChannelDescription'),
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(
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
    if (!_isMobilePlatform) return;
    await initialize();
    await _plugin.cancel(id: _notificationId);
  }

  void _ensureTimeZoneInitialized() {
    if (_timeZoneInitialized) return;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    _timeZoneInitialized = true;
  }
}
