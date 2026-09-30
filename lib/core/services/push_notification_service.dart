import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('FCM Background message: ${message.messageId} - ${message.notification?.title}');
}

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'alianza_chaclacayo_general',
    'Notificaciones Generales',
    description: 'Canal para anuncios, recordatorios de clases y comunicados importantes.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static Future<void> initialize() async {
    try {
      // 1. Initialize Firebase App
      await Firebase.initializeApp();

      // 2. Background messaging handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. Request permissions (Android 13+ & iOS)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('FCM Permission status: ${settings.authorizationStatus}');

      // 4. Configure local notifications for foreground display on Android
      if (!kIsWeb && Platform.isAndroid) {
        const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
        const initSettings = InitializationSettings(android: androidInit);

        await _localNotifications.initialize(initSettings);

        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_channel);
      }

      // 5. Subscribe device to church-wide announcement topics
      try {
        await _messaging.subscribeToTopic('todos');
        await _messaging.subscribeToTopic('anuncios');
      } catch (e) {
        debugPrint('Error subscribing to general topics: $e');
      }

      // 6. Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        final android = message.notification?.android;

        if (notification != null && !kIsWeb) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                icon: android?.smallIcon ?? '@mipmap/ic_launcher',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
              ),
            ),
            payload: message.data.toString(),
          );
        }
      });

      // 7. Get and sync initial token
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await _updateTokenInSupabase(token);
      }

      // 8. Refresh token listener
      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('FCM Token refreshed: $newToken');
        await _updateTokenInSupabase(newToken);
      });
    } catch (e) {
      debugPrint('Error initializing PushNotificationService: $e');
    }
  }

  /// Syncs FCM token to current logged-in user profile in Supabase
  static Future<void> syncUserToken([String? explicitUserId]) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _updateTokenInSupabase(token, explicitUserId);
      }
    } catch (e) {
      debugPrint('Error syncing FCM token: $e');
    }
  }

  static Future<void> _updateTokenInSupabase(String token, [String? explicitUserId]) async {
    try {
      final client = Supabase.instance.client;
      final userId = explicitUserId ?? client.auth.currentUser?.id;
      if (userId != null) {
        await client.from('profiles').update({
          'fcm_token': token,
        }).eq('id', userId);
      }
    } catch (e) {
      debugPrint('Error updating FCM token in Supabase: $e');
    }
  }

  /// Subscribes to a course specific topic (e.g. for enrolled students)
  static Future<void> subscribeToCourse(String courseId) async {
    try {
      final topic = 'curso_${courseId.replaceAll('-', '_')}';
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
      debugPrint('Error subscribing to course topic: $e');
    }
  }

  /// Unsubscribes from a course topic
  static Future<void> unsubscribeFromCourse(String courseId) async {
    try {
      final topic = 'curso_${courseId.replaceAll('-', '_')}';
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      debugPrint('Error unsubscribing from course topic: $e');
    }
  }

  /// Subscribes to network topic (e.g. dunamis, next, etc.)
  static Future<void> subscribeToNetwork(String network) async {
    try {
      final cleanNetwork = network.trim().toLowerCase().replaceAll(' ', '_');
      await _messaging.subscribeToTopic('red_$cleanNetwork');
    } catch (e) {
      debugPrint('Error subscribing to network topic: $e');
    }
  }
}
