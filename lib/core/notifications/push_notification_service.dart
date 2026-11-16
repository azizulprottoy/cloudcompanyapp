import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../features/notifications/controller/notification_center.dart';
import '../../features/notifications/repository/notification_repository.dart';
import '../auth/session_service.dart';

/// Background/terminated messages: the system tray shows them from the
/// `notification` payload, so nothing to do beyond starting Firebase.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Firebase Cloud Messaging for the app.
///
/// - Every device is on the 'public' topic (announcements, signed in or not).
/// - Signed in, the device's token is registered with the server, which puts
///   it on the user's own pushes and their role topic ('clients', ...).
/// - Signing out unregisters the token.
/// - Foreground pushes are shown with flutter_local_notifications (except for
///   the chat that's on screen); taps open the matching screen.
///
/// Needs Firebase config files (android/app/google-services.json and
/// ios/Runner/GoogleService-Info.plist, from `flutterfire configure`). Without
/// them push stays off and the in-app notification list still works.
class PushNotificationService extends GetxService {
  PushNotificationService({NotificationRepository? repository})
    : _repository = repository ?? NotificationRepository();

  static PushNotificationService get to => Get.find();

  static const publicTopic = 'public';
  static const _channel = AndroidNotificationChannel(
    'cloudcompany_default',
    'Cloud Company',
    description: 'Messages, project and task updates, and announcements',
    importance: Importance.high,
  );

  final NotificationRepository _repository;
  final _local = FlutterLocalNotificationsPlugin();

  /// False when Firebase isn't configured on this build.
  final enabled = false.obs;

  String? _token;

  /// "userId|token" last registered with the server.
  String? _registered;

  /// A tap that launched the app before any screen was ready.
  Map<String, String>? _pendingOpen;

  String get _platform => Platform.isIOS ? 'ios' : 'android';

  Future<PushNotificationService> init() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Push notifications off (Firebase not configured): $e');
      return this;
    }
    enabled.value = true;

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    await _initLocalNotifications();

    final messaging = FirebaseMessaging.instance;
    // Foreground pushes are shown by _onForeground, on both platforms.
    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );
    FirebaseMessaging.onMessage.listen(_onForeground);
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _open(_strings(m.data)));
    // FCM registration tokens, not the new installation IDs from register():
    // the server sends with firebase-admin multicast and topic subscriptions,
    // which both take tokens.
    // ignore: deprecated_member_use
    messaging.onTokenRefresh.listen((token) {
      _token = token;
      _syncToken();
    });

    final initial = await messaging.getInitialMessage();
    if (initial != null) _pendingOpen = _strings(initial.data);
    final launch = await _local.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      _pendingOpen ??= _decode(launch!.notificationResponse?.payload);
    }

    ever(SessionService.to.role, (_) => _syncToken());
    // Permission prompt and token fetch shouldn't hold up the first frame.
    unawaited(_start());
    return this;
  }

  Future<void> _start() async {
    final messaging = FirebaseMessaging.instance;
    try {
      await messaging.requestPermission();
      await messaging.subscribeToTopic(publicTopic);
      // ignore: deprecated_member_use
      _token = await messaging.getToken();
    } catch (e) {
      // iOS gives no token until APNs is ready; onTokenRefresh brings it later.
      debugPrint('FCM token unavailable: $e');
    }
    await _syncToken();
  }

  Future<void> _initLocalNotifications() async {
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (r) => _open(_decode(r.payload)),
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  /// Registers this device for the signed-in user, or unregisters it after
  /// sign-out. Safe to call any time; only talks to the server on a change.
  Future<void> _syncToken() async {
    final token = _token;
    if (token == null) return;
    final session = SessionService.to;
    try {
      if (session.isSignedIn) {
        final key = '${session.current.id}|$token';
        if (_registered == key) return;
        await _repository.registerDevice(token: token, platform: _platform);
        _registered = key;
      } else if (_registered != null) {
        _registered = null;
        await _repository.unregisterDevice(token: token, platform: _platform);
      }
    } catch (e) {
      debugPrint('Device token sync failed: $e');
    }
  }

  void _onForeground(RemoteMessage message) {
    final data = _strings(message.data);
    final center = NotificationCenter.to;
    final onScreenChat =
        data['type'] == 'chat' && data['roomId'] == center.activeChatRoom;
    center.onPush(data);
    final n = message.notification;
    if (n == null || onScreenChat) return;

    _local.show(
      id:
          message.messageId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: n.title,
      body: n.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(data),
    );
  }

  void _open(Map<String, String>? data) {
    if (data == null) return;
    final route = Get.currentRoute;
    if (route.isEmpty || route == AppRoutes.splash) {
      _pendingOpen = data;
      return;
    }
    NotificationCenter.to.openData(data);
  }

  /// Called once the first real screen is up (after the splash).
  void openPending() {
    final data = _pendingOpen;
    _pendingOpen = null;
    if (data != null) NotificationCenter.to.openData(data);
  }

  Map<String, String> _strings(Map<String, dynamic> data) =>
      data.map((k, v) => MapEntry(k, v?.toString() ?? ''));

  Map<String, String>? _decode(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final map = jsonDecode(payload);
      return map is Map ? _strings(Map<String, dynamic>.from(map)) : null;
    } catch (_) {
      return null;
    }
  }
}
