import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages FCM push notifications and email notification preferences.
class NotificationService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _pushEnabled = true;
  bool _emailEnabled = true;
  String? _fcmToken;
  String? _lastNotificationTitle;
  String? _lastNotificationBody;
  DateTime? _lastNotificationTime;

  bool get pushEnabled => _pushEnabled;
  bool get emailEnabled => _emailEnabled;
  String? get fcmToken => _fcmToken;
  String? get lastNotificationTitle => _lastNotificationTitle;
  String? get lastNotificationBody => _lastNotificationBody;
  DateTime? get lastNotificationTime => _lastNotificationTime;

  StreamSubscription<RemoteMessage>? _fcmSub;

  NotificationService() {
    _initPreferences();
  }

  Future<void> _initPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _pushEnabled = prefs.getBool('push_notifications_enabled') ?? true;
      _emailEnabled = prefs.getBool('email_notifications_enabled') ?? true;
      notifyListeners();

      if (_pushEnabled) {
        await setupFCM();
      }
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  Future<void> setupFCM() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        _fcmToken = await messaging.getToken();
        debugPrint('FCM Token: $_fcmToken');
        await syncTokenToFirestore();

        _fcmSub?.cancel();
        _fcmSub = FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
          _lastNotificationTitle = msg.notification?.title ?? 'M&S Electricals Notification';
          _lastNotificationBody = msg.notification?.body ?? 'You have a new update';
          _lastNotificationTime = DateTime.now();
          notifyListeners();
        });
      }
    } catch (e) {
      debugPrint('FCM setup non-fatal error: $e');
    }
  }

  Future<void> syncTokenToFirestore() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || _fcmToken == null) return;
    try {
      await _db.collection('users').doc(uid).set({
        'fcmToken': _fcmToken,
        'pushEnabled': _pushEnabled,
        'emailNotifyEnabled': _emailEnabled,
        'lastActiveAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error syncing token to firestore: $e');
    }
  }

  Future<void> setPushEnabled(bool enabled) async {
    _pushEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications_enabled', enabled);

    if (enabled) {
      await setupFCM();
    }
    await syncTokenToFirestore();
  }

  Future<void> setEmailEnabled(bool enabled) async {
    _emailEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('email_notifications_enabled', enabled);
    await syncTokenToFirestore();
  }

  /// Triggers a test notification locally for user validation
  void sendTestPushNotification({String? title, String? body}) {
    _lastNotificationTitle = title ?? '⚡ M&S Electricals Alert';
    _lastNotificationBody = body ?? 'Push notifications are active! You will receive live booking status updates.';
    _lastNotificationTime = DateTime.now();
    notifyListeners();
  }

  @override
  void dispose() {
    _fcmSub?.cancel();
    super.dispose();
  }
}
