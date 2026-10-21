
import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/auth_screen.dart';
import '../providers/app_provider.dart';
import '../utils/strings.dart';

const localNotificationChannel = 'high_importance_channel';
const localNotificationChannelTitle = 'High Importance Notifications';
const localNotificationChannelDescription =
    'This channel is used for important notifications.';

class FCMService {
  FCMService._internal();

  static final FCMService _singleton = FCMService._internal();

  factory FCMService() => _singleton;

  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel channel =
  const AndroidNotificationChannel(
    localNotificationChannel,
    localNotificationChannelTitle,
    description: localNotificationChannelDescription,
    importance: Importance.max,
  );

  final AndroidInitializationSettings initializationSettingsAndroid =
  const AndroidInitializationSettings('@mipmap/ic_launcher');

  GlobalKey<NavigatorState>? navigatorKey;

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;

  bool _initialized = false;

  // -----------------------------------
  // INITIALIZE FCM
  // -----------------------------------

  Future<void> listenForMessages(
      SharedPreferences sharedPrefs,
      WidgetRef ref,
      ) async {
    if (_initialized) return;

    await initFlutterLocalNotification(sharedPrefs, ref);

    await registerChannel();

    await requestNotificationPermissionForIOS(sharedPrefs);

    await turnOnIOSForegroundNotification();

    await messaging.subscribeToTopic('phoosar');

    // Foreground notifications
    _foregroundSubscription =
        FirebaseMessaging.onMessage.listen((remoteMessage) async {
          debugPrint('FCM foreground notification received');

          final notification = remoteMessage.notification;

          if (notification == null) return;

          // On iOS, FCM displays the foreground notification
          // using the presentation options configured below.
          // Avoid displaying a second local notification.
          if (!Platform.isAndroid) return;

          final notificationDetails = NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          );

          await flutterLocalNotificationsPlugin.show(
            id: notification.hashCode,
            title: notification.title,
            body: notification.body,
            notificationDetails: notificationDetails,
            payload: remoteMessage.data['post_id']?.toString(),
          );
        });

    // Notification clicked while app is in background
    _openedAppSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen((message) async {
          debugPrint(
            'Notification opened: ${message.data['post_id']}',
          );

          await doNavigationLogic(sharedPrefs, ref);
        });

    // App opened from terminated state
    final initialMessage = await messaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint(
        'App launched from notification: '
            '${initialMessage.data['post_id']}',
      );

      await doNavigationLogic(sharedPrefs, ref);
    }

    _initialized = true;
  }

  // -----------------------------------
  // REQUEST NOTIFICATION PERMISSIONS
  // -----------------------------------

  Future<NotificationSettings> requestNotificationPermissionForIOS(
      SharedPreferences sharedPrefs,
      ) async {
    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint(
      'Notification permission: ${settings.authorizationStatus}',
    );

    try {
      final fcmToken = await messaging.getToken();

      if (fcmToken != null) {
        await sharedPrefs.setString('fcmToken', fcmToken);

        debugPrint('FCM token obtained');
      }
    } catch (error) {
      debugPrint('Unable to get FCM token: $error');
    }

    return settings;
  }

  // -----------------------------------
  // IOS FOREGROUND PRESENTATION
  // -----------------------------------

  Future<void> turnOnIOSForegroundNotification() async {
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // -----------------------------------
  // INITIALIZE LOCAL NOTIFICATIONS
  // -----------------------------------

  Future<void> initFlutterLocalNotification(
      SharedPreferences sharedPrefs,
      WidgetRef ref,
      ) async {
    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: const DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) async {
        await onTapLocalNotification(
          response,
          sharedPrefs,
          ref,
        );
      },
    );
  }

  // -----------------------------------
  // REGISTER ANDROID NOTIFICATION CHANNEL
  // -----------------------------------

  Future<void> registerChannel() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // -----------------------------------
  // LOCAL NOTIFICATION CLICK
  // -----------------------------------

  Future<void> onTapLocalNotification(
      NotificationResponse notificationResponse,
      SharedPreferences sharedPrefs,
      WidgetRef ref,
      ) async {
    debugPrint(
      'Local notification tapped: '
          '${notificationResponse.payload}',
    );

    await doNavigationLogic(sharedPrefs, ref);
  }

  // -----------------------------------
  // NAVIGATION LOGIC
  // -----------------------------------

  Future<void> doNavigationLogic(
      SharedPreferences sharedPrefs,
      WidgetRef ref,
      ) async {
    final token = sharedPrefs.getString(kTokenKey);

    if (token == null || token.isEmpty) {
      navigatorKey?.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => AuthScreen(),
        ),
            (route) => false,
      );

      return;
    }

    // Navigate to notification tab
    ref.read(dashboardProvider.notifier).setPosition(1);
  }

  // -----------------------------------
  // CLEAN UP STREAM LISTENERS
  // -----------------------------------

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedAppSubscription?.cancel();

    _foregroundSubscription = null;
    _openedAppSubscription = null;

    _initialized = false;
  }
}
