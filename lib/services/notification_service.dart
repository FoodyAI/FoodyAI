import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'aws_service.dart';
import '../config/routes/navigation_service.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 Background message received: ${message.messageId}');
  print('📩 Title: ${message.notification?.title}');
  print('📩 Body: ${message.notification?.body}');
  print('📩 Data: ${message.data}');
}

/// Service class to handle Firebase Cloud Messaging (FCM)
/// Manages token registration, notification receiving, and user interactions
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final AWSService _awsService = AWSService();

  static const String _fcmTokenKey = 'fcm_token';
  String? _currentToken;
  bool _isInitialized = false;

  /// Initialize the notification service
  /// Should be called once during app startup
  Future<void> initialize({required String userId}) async {
    if (_isInitialized) {
      print('⚠️ NotificationService: Already initialized, skipping...');
      return;
    }

    try {
      print('🔄 NotificationService: Initializing...');

      // Request permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get and save FCM token
      await _handleToken(userId);

      // Listen for token refresh
      _listenToTokenRefresh(userId);

      // Setup message handlers
      _setupMessageHandlers();

      _isInitialized = true;
      print('✅ NotificationService: Initialized successfully');
    } catch (e) {
      print('❌ NotificationService: Initialization failed: $e');
    }
  }

  /// Request notification permissions from user
  Future<void> _requestPermissions() async {
    try {
      print('🔄 NotificationService: Requesting permissions...');

      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ NotificationService: User granted permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('✅ NotificationService: User granted provisional permission');
      } else {
        print('⚠️ NotificationService: User declined permission');
      }
    } catch (e) {
      print('❌ NotificationService: Error requesting permissions: $e');
    }
  }

  /// Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    try {
      print('🔄 NotificationService: Initializing local notifications...');

      // Android settings
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      print('✅ NotificationService: Local notifications initialized');
    } catch (e) {
      print('❌ NotificationService: Local notifications init failed: $e');
    }
  }

  /// Get FCM token and save it locally and to backend
  Future<void> _handleToken(String userId) async {
    try {
      print('🔄 NotificationService: Getting FCM token...');

      // Get the token
      final token = await _firebaseMessaging.getToken();

      if (token != null) {
        print('✅ NotificationService: FCM token received');
        print('📝 NotificationService: Token: $token');

        _currentToken = token;

        // Save token locally
        await _saveTokenLocally(token);

        // Send token to backend
        await _sendTokenToBackend(userId, token);
      } else {
        print('⚠️ NotificationService: FCM token is null');
      }
    } catch (e) {
      print('❌ NotificationService: Error handling token: $e');
    }
  }

  /// Save FCM token to local storage
  Future<void> _saveTokenLocally(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, token);
      print('✅ NotificationService: Token saved locally');
    } catch (e) {
      print('❌ NotificationService: Error saving token locally: $e');
    }
  }

  /// Get stored FCM token from local storage
  Future<String?> getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_fcmTokenKey);
    } catch (e) {
      print('❌ NotificationService: Error getting stored token: $e');
      return null;
    }
  }

  /// Send FCM token to AWS backend
  Future<void> _sendTokenToBackend(String userId, String token) async {
    try {
      print('🔄 NotificationService: Sending token to backend...');
      print('📝 NotificationService: User ID: $userId');

      final response = await _awsService.updateFCMToken(
        userId: userId,
        fcmToken: token,
      );

      if (response != null && response['success'] == true) {
        print('✅ NotificationService: Token sent to backend successfully');
      } else {
        print('⚠️ NotificationService: Failed to send token to backend');
      }
    } catch (e) {
      print('❌ NotificationService: Error sending token to backend: $e');
    }
  }

  /// Listen for token refresh events
  void _listenToTokenRefresh(String userId) {
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('🔄 NotificationService: Token refreshed');
      print('📝 NotificationService: New token: $newToken');

      _currentToken = newToken;
      _saveTokenLocally(newToken);
      _sendTokenToBackend(userId, newToken);
    });
  }

  /// Setup message handlers for foreground, background, and terminated states
  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background messages (app in background but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle notification that opened the app from terminated state
    _handleInitialMessage();
  }

  /// Handle messages when app is in foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📩 Foreground message received: ${message.messageId}');
    print('📩 Title: ${message.notification?.title}');
    print('📩 Body: ${message.notification?.body}');
    print('📩 Data: ${message.data}');

    // Show local notification when app is in foreground
    await _showLocalNotification(message);
  }

  /// Handle notification tap when app is in background
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('📩 Notification opened app from background: ${message.messageId}');
    print('📩 Data: ${message.data}');

    _handleNotificationNavigation(message.data);
  }

  /// Handle notification that opened the app from terminated state
  Future<void> _handleInitialMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();

    if (initialMessage != null) {
      print(
          '📩 Notification opened app from terminated: ${initialMessage.messageId}');
      print('📩 Data: ${initialMessage.data}');

      _handleNotificationNavigation(initialMessage.data);
    }
  }

  /// Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      // Android notification details
      const androidDetails = AndroidNotificationDetails(
        'foody_channel', // channel id
        'Foody Notifications', // channel name
        channelDescription: 'Notifications from Foody app',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        details,
        payload: message.data.toString(),
      );

      print('✅ NotificationService: Local notification shown');
    } catch (e) {
      print('❌ NotificationService: Error showing local notification: $e');
    }
  }

  /// Handle notification tap and navigate accordingly
  void _onNotificationTap(NotificationResponse response) {
    print('📩 Notification tapped');
    print('📩 Payload: ${response.payload}');

    // Parse payload and navigate
    // You can customize this based on your notification data structure
    if (response.payload != null) {
      // Example: parse payload and navigate to specific screen
      // For now, we'll just print it
      print('📝 NotificationService: Processing payload...');
    }
  }

  /// Handle navigation based on notification data
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    try {
      print('🔄 NotificationService: Handling navigation...');
      print('📝 NotificationService: Data: $data');

      // Example navigation logic based on notification type
      final type = data['type'];
      final screen = data['screen'];

      if (screen != null) {
        // Navigate to specific screen
        NavigationService.pushNamed(screen);
      } else if (type == 'food_reminder') {
        // Navigate to home screen
        NavigationService.pushNamed('/home');
      } else if (type == 'profile_update') {
        // Navigate to profile screen
        NavigationService.pushNamed('/profile');
      } else {
        // Default: navigate to home
        NavigationService.pushNamed('/home');
      }

      print('✅ NotificationService: Navigation handled');
    } catch (e) {
      print('❌ NotificationService: Error handling navigation: $e');
    }
  }

  /// Update notification preferences on the backend
  Future<bool> updateNotificationPreferences({
    required String userId,
    required bool notificationsEnabled,
  }) async {
    try {
      print('🔄 NotificationService: Updating preferences...');
      print('📝 NotificationService: Enabled: $notificationsEnabled');

      final response = await _awsService.updateNotificationPreferences(
        userId: userId,
        notificationsEnabled: notificationsEnabled,
      );

      if (response != null && response['success'] == true) {
        print('✅ NotificationService: Preferences updated successfully');
        return true;
      } else {
        print('⚠️ NotificationService: Failed to update preferences');
        return false;
      }
    } catch (e) {
      print('❌ NotificationService: Error updating preferences: $e');
      return false;
    }
  }

  /// Get current FCM token
  String? get currentToken => _currentToken;

  /// Check if notifications are enabled on device
  Future<bool> areNotificationsEnabled() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Request permissions again (useful for settings screen)
  Future<bool> requestPermissionsAgain() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Delete FCM token (useful for logout)
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _currentToken = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_fcmTokenKey);

      print('✅ NotificationService: Token deleted successfully');
    } catch (e) {
      print('❌ NotificationService: Error deleting token: $e');
    }
  }
}