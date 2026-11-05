import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum NotificationChannelType {
  messages,
  requests,
  plans,
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  static NotificationService get instance => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  int _notificationCounter = 1000;
  final Set<String> _recentKeys = {};

  static const String channelMessagesId = 'tribex_squad_messages';
  static const String channelRequestsId = 'tribex_join_requests';
  static const String channelPlansId = 'tribex_plan_updates';

  /// Initializes the local notification plugin and configures Android notification channels.
  Future<void> initialize() async {
    if (kIsWeb) return;
    if (_isInitialized) return;

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidImpl = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidImpl != null) {
          // Channel 1: Messages
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              channelMessagesId,
              'Squad Messages',
              description: 'Notifications for new messages in squad chats',
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
            ),
          );

          // Channel 2: Join Requests
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              channelRequestsId,
              'Join Requests & Approvals',
              description: 'Alerts for plan join requests and squad approvals',
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
            ),
          );

          // Channel 3: Plan Updates
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              channelPlansId,
              'Plan Updates',
              description: 'Updates and alerts for upcoming plans and events',
              importance: Importance.defaultImportance,
              playSound: true,
              enableVibration: true,
            ),
          );
        }
      }

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully.');
    } catch (e) {
      debugPrint('NotificationService initialize error: $e');
    }
  }

  /// Explicitly requests runtime notification permissions (POST_NOTIFICATIONS on Android 13+ / iOS).
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidImpl = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidImpl?.requestNotificationsPermission();
        return granted ?? false;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosImpl = _localNotifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('NotificationService requestPermissions error: $e');
    }
    return false;
  }

  /// Returns true if the deduplication key should be dispatched, false if already recently dispatched.
  bool shouldDispatch(String? deduplicationKey) {
    if (deduplicationKey == null || deduplicationKey.isEmpty) return true;
    if (_recentKeys.contains(deduplicationKey)) {
      return false;
    }
    _recentKeys.add(deduplicationKey);
    Future.delayed(const Duration(seconds: 10), () {
      _recentKeys.remove(deduplicationKey);
    });
    return true;
  }

  /// Displays a native device notification on the appropriate notification channel.
  Future<void> showNotification({
    int? id,
    required String title,
    required String body,
    String? payload,
    NotificationChannelType channelType = NotificationChannelType.messages,
    String? deduplicationKey,
  }) async {
    if (kIsWeb) return;

    if (!_isInitialized) {
      await initialize();
    }

    if (!shouldDispatch(deduplicationKey)) {
      return; // Deduplicated
    }

    final notifId = id ?? (_notificationCounter++);

    String channelId;
    String channelName;
    Importance importance;
    Priority priority;

    switch (channelType) {
      case NotificationChannelType.messages:
        channelId = channelMessagesId;
        channelName = 'Squad Messages';
        importance = Importance.high;
        priority = Priority.high;
        break;
      case NotificationChannelType.requests:
        channelId = channelRequestsId;
        channelName = 'Join Requests & Approvals';
        importance = Importance.high;
        priority = Priority.high;
        break;
      case NotificationChannelType.plans:
        channelId = channelPlansId;
        channelName = 'Plan Updates';
        importance = Importance.defaultImportance;
        priority = Priority.defaultPriority;
        break;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'TribeX notifications',
      importance: importance,
      priority: priority,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    try {
      await _localNotifications.show(
        id: notifId,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint('NotificationService.showNotification error: $e');
    }
  }
}

