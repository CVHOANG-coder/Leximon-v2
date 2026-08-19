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
  final _messagesController = StreamController<RemoteMessage>.broadcast();
  String? _activeTopic;

  Stream<RemoteMessage> get messages => _messagesController.stream;

  String topicForUser(String userCode) => 'user_${userCode.trim()}';

  Future<bool> subscribeToUserTopic(String userCode) async {
    final normalizedUserCode = userCode.trim();
    if (normalizedUserCode.isEmpty || !_supportsPushMessaging) return false;

    final topic = topicForUser(normalizedUserCode);
    if (_activeTopic == topic) return true;

    final messaging = await _loadMessaging();
    if (messaging == null) return false;

    try {
      final previousTopic = _activeTopic;
      if (previousTopic != null) {
        await messaging.unsubscribeFromTopic(previousTopic);
      }
      await messaging.subscribeToTopic(topic);
      _activeTopic = topic;
      _messageSubscription ??= FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );
      return true;
    } on Object catch (error, stackTrace) {
      debugPrint('Could not subscribe to FCM topic $topic: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
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
    await _messagesController.close();
  }
}
