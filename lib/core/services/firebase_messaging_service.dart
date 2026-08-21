import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Owns the FCM topic subscription for the authenticated user.
///
/// Firebase is optional for local/dev builds. A missing native Firebase
/// configuration must not prevent the app from starting or learning offline.
class FirebaseMessagingService {
  FirebaseMessagingService();

  FirebaseMessaging? _messaging;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  final _messagesController = StreamController<RemoteMessage>.broadcast();
  String? _activeTopic;
  String? _desiredTopic;
  Future<bool>? _subscriptionAttempt;

  Stream<RemoteMessage> get messages => _messagesController.stream;

  String topicForUser(String userCode) => 'user_${userCode.trim()}';

  Future<bool> subscribeToUserTopic(String userCode) async {
    final normalizedUserCode = userCode.trim();
    if (normalizedUserCode.isEmpty || !_supportsPushMessaging) return false;

    final topic = topicForUser(normalizedUserCode);
    _desiredTopic = topic;
    if (_activeTopic == topic) return true;

    final messaging = await _loadMessaging();
    if (messaging == null) return false;

    _listenForMessagingEvents(messaging);
    return _subscribeToDesiredTopic(messaging, waitForApnsToken: true);
  }

  void _listenForMessagingEvents(FirebaseMessaging messaging) {
    _messageSubscription ??= FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );
    _tokenRefreshSubscription ??= messaging.onTokenRefresh.listen(
      (_) {
        // The first FCM token on iOS is emitted only after APNs has supplied
        // its token. Retry a deferred topic subscription at that point.
        unawaited(
          _subscribeToDesiredTopic(
            messaging,
            waitForApnsToken: false,
            force: true,
          ),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Could not observe FCM token refreshes: $error');
        debugPrintStack(stackTrace: stackTrace);
      },
    );
  }

  Future<bool> _subscribeToDesiredTopic(
    FirebaseMessaging messaging, {
    required bool waitForApnsToken,
    bool force = false,
  }) async {
    final inProgress = _subscriptionAttempt;
    if (inProgress != null) return inProgress;

    final attempt = _performTopicSubscription(
      messaging,
      waitForApnsToken: waitForApnsToken,
      force: force,
    );
    _subscriptionAttempt = attempt;
    try {
      return await attempt;
    } finally {
      if (identical(_subscriptionAttempt, attempt)) {
        _subscriptionAttempt = null;
      }
    }
  }

  Future<bool> _performTopicSubscription(
    FirebaseMessaging messaging, {
    required bool waitForApnsToken,
    required bool force,
  }) async {
    final topic = _desiredTopic;
    if (topic == null) return false;
    if (!force && _activeTopic == topic) return true;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final apnsReady = await _isApnsTokenReady(
        messaging,
        wait: waitForApnsToken,
      );
      if (!apnsReady) {
        debugPrint(
          'FCM topic subscription for $topic is waiting for an APNs token.',
        );
        return false;
      }
    }

    try {
      final previousTopic = _activeTopic;
      if (previousTopic != null && previousTopic != topic) {
        await messaging.unsubscribeFromTopic(previousTopic);
        _activeTopic = null;
      }
      await messaging.subscribeToTopic(topic);
      _activeTopic = topic;
      return true;
    } on FirebaseException catch (error, stackTrace) {
      if (error.code == 'apns-token-not-set') {
        // APNs and FCM initialize asynchronously on iOS. onTokenRefresh will
        // retry this topic after the APNs token becomes available.
        debugPrint(
          'FCM topic subscription for $topic is waiting for an APNs token.',
        );
        return false;
      }
      debugPrint('Could not subscribe to FCM topic $topic: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    } on Object catch (error, stackTrace) {
      debugPrint('Could not subscribe to FCM topic $topic: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> _isApnsTokenReady(
    FirebaseMessaging messaging, {
    required bool wait,
  }) async {
    // The startup request is best-effort and runs in the background. A short
    // bounded retry handles the common race without delaying app navigation.
    final attempts = wait ? 8 : 1;
    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        final token = await messaging.getAPNSToken();
        if (token != null && token.isNotEmpty) return true;
      } on Object catch (error, stackTrace) {
        debugPrint('Could not read the APNs token: $error');
        debugPrintStack(stackTrace: stackTrace);
        return false;
      }
      if (attempt + 1 < attempts) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }
    return false;
  }

  Future<FirebaseMessaging?> _loadMessaging() async {
    if (_messaging != null) return _messaging;

    try {
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;
      return _messaging;
    } on FirebaseException catch (error, stackTrace) {
      // A native Firebase app may already be initialized by the host app.
      if (error.code == 'duplicate-app') {
        try {
          _messaging = FirebaseMessaging.instance;
          return _messaging;
        } on Object catch (instanceError, instanceStackTrace) {
          debugPrint('Could not access Firebase Messaging: $instanceError');
          debugPrintStack(stackTrace: instanceStackTrace);
        }
      }
      debugPrint('Firebase Messaging is unavailable: ${error.message}');
      debugPrintStack(stackTrace: stackTrace);
    } on Object catch (error, stackTrace) {
      debugPrint('Firebase Messaging is unavailable: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    return null;
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final topic = _activeTopic;
    if (topic == null) return;

    final sender = message.from;
    if (sender == null ||
        sender.isEmpty ||
        sender == topic ||
        sender == '/topics/$topic') {
      _messagesController.add(message);
    }
  }

  bool get _supportsPushMessaging =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> dispose() async {
    await _messageSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();
    await _messagesController.close();
  }
}
