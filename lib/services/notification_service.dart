import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Background message handler ────────────────────────────────────────────
// MUST be a top-level function (not a class method) for FCM background handling.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // NOTE: Firebase is already initialised in main() before this runs.
  debugPrint('[FCM] Message reçu en arrière-plan: ${message.messageId}');
}

/// Centralized push notification service for Zehouse.
///
/// Responsibilities:
/// - Initialize Firebase Messaging (FCM)
/// - Request notification permissions (Android 13+, iOS)
/// - Display in-app banners via [FlutterLocalNotifications] when app is in foreground
/// - Save / refresh the FCM device token in Supabase (`user_profiles.fcm_token`)
/// - Expose [onNotificationTap] stream for navigation on tap
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Called when a notification is tapped — provides the payload string.
  /// Subscribe to this in your router/navigator to handle deep-links.
  final _onTapPayload = ValueNotifier<String?>('');

  ValueNotifier<String?> get onNotificationTap => _onTapPayload;

  // ─── Android notification channel ─────────────────────────────────────────
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'zehouse_high_importance', // id
    'Notifications Zehouse', // name
    description: 'Annonces, messages et alertes en temps réel',
    importance: Importance.high,
    playSound: true,
  );

  // ─── Initialisation ────────────────────────────────────────────────────────
  Future<void> init() async {
    // Skip on web — FCM web requires a service worker (separate setup)
    if (kIsWeb) return;

    // 1. Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Request permissions (iOS + Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint(
      '[FCM] Permission status: ${settings.authorizationStatus.name}',
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] Notifications refusées par l\'utilisateur.');
      return;
    }

    // 3. Setup flutter_local_notifications
    await _setupLocalNotifications();

    // 4. Foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. Tap handler when app is in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 6. Tap handler when app was terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // 7. Save FCM token to Supabase
    await _refreshAndSaveToken();

    // 8. Listen for token refresh
    _messaging.onTokenRefresh.listen(_saveTokenToSupabase);
  }

  // ─── Local notifications setup ─────────────────────────────────────────────
  Future<void> _setupLocalNotifications() async {
    // Create Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false, // already handled by FCM
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: darwinInit),
      onDidReceiveNotificationResponse: (details) {
        _onTapPayload.value = details.payload;
      },
    );

    // On iOS, show notifications in foreground as well
    if (!kIsWeb && Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  // ─── Foreground message → local notification ───────────────────────────────
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Message en foreground: ${message.notification?.title}');
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data['route'],
    );
  }

  // ─── Handle tap ───────────────────────────────────────────────────────────
  void _handleNotificationTap(RemoteMessage message) {
    final route = message.data['route'] as String?;
    debugPrint('[FCM] Notification tapée — route: $route');
    if (route != null) {
      _onTapPayload.value = route;
    }
  }

  // ─── FCM Token → Supabase ─────────────────────────────────────────────────
  Future<void> _refreshAndSaveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToSupabase(token);
      }
    } catch (e) {
      debugPrint('[FCM] Erreur récupération token: $e');
    }
  }

  Future<void> _saveTokenToSupabase(String token) async {
    debugPrint('[FCM] Token FCM: $token');
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client.from('user_profiles').upsert({
        'id': userId,
        'fcm_token': token,
        'fcm_token_updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');

      debugPrint('[FCM] Token sauvegardé dans Supabase pour user: $userId');
    } catch (e) {
      debugPrint('[FCM] Erreur sauvegarde token Supabase: $e');
    }
  }

  // ─── Public helpers ────────────────────────────────────────────────────────
  /// Call this after user logs in to refresh and save the FCM token.
  Future<void> onUserLogin() => _refreshAndSaveToken();

  /// Call this after user logs out to remove the FCM token from Supabase.
  Future<void> onUserLogout() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      await Supabase.instance.client
          .from('user_profiles')
          .update({'fcm_token': null, 'fcm_token_updated_at': null})
          .eq('id', userId);
    } catch (e) {
      debugPrint('[FCM] Erreur suppression token logout: $e');
    }
  }
}
