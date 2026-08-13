import 'dart:convert';
import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

/// Modèle de notification
class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.parse(
        (json['createdAt'] as String).replaceFirst(' ', 'T'),
      ),
    );
  }
}

/// Service de gestion des notifications push FCM
class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// Canal de notification Android (doit correspondre au backend)
  static const String androidChannelId = 'kivoo_default_channel';
  static const String androidChannelName = 'Notifications Kivoo';
  static const String androidChannelDescription =
      'Notifications de messages, favoris et alertes';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Récupère le token JWT stocké
  Future<String?> _getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Initialise les notifications push
  Future<void> initialize() async {
    // Initialiser le plugin de notifications locales (Android)
    await _initLocalNotifications();

    // Demander la permission (iOS + Android 13+)
    await _requestPermissions();

    // Gérer les notifications quand l'app est en arrière-plan / fermée
    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

    // Gérer les notifications quand l'app est au premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Notification reçue (premier plan): ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // Gérer quand l'utilisateur clique sur une notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📨 Notification ouverte: ${message.notification?.title}');
      _handleNotificationTap(message);
    });

    // Ré-enregistrer automatiquement le token quand il change
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      print('🔄 Token FCM rafraîchi: $newToken');
      await registerTokenOnBackend(newToken);
    });
  }

  /// Initialise le plugin de notifications locales
  Future<void> _initLocalNotifications() async {
    // Créer le canal de notification Android (requis pour Android 8.0+)
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          final data = jsonDecode(response.payload!);
          _handleNotificationTapData(data);
        }
      },
    );

    // Créer le canal de notification
    const channel = AndroidNotificationChannel(
      androidChannelId, // id: 'kivoo_default_channel'
      androidChannelName, // name: 'Notifications Kivoo'
      description: androidChannelDescription,
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Demande les permissions de notification (iOS + Android 13+)
  Future<void> _requestPermissions() async {
    // iOS : demande la permission
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Android 13+ (API 33+) : demande la permission POST_NOTIFICATIONS
    final androidImpl = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      print('📨 Permission notifications Android: $granted');
    }
  }

  /// Affiche une notification locale (pour le premier plan)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final data = message.data;

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannelId,
          androidChannelName,
          channelDescription: androidChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(data),
    );
  }

  /// Gestionnaire pour les messages en arrière-plan (isolate séparé)
  @pragma('vm:entry-point')
  static Future<void> _backgroundMessageHandler(RemoteMessage message) async {
    print('📨 Notification en arrière-plan: ${message.notification?.title}');
  }

  /// Récupère le token FCM actuel (sans l'enregistrer)
  Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('⚠️ Erreur lors de la récupération du token FCM: $e');
      return null;
    }
  }

  /// Récupère le token FCM et l'enregistre sur le backend
  Future<String?> getTokenAndRegister() async {
    try {
      print('🔑 Récupération du token FCM...');
      final token = await _firebaseMessaging.getToken();
      print('🔑 Token FCM obtenu: ${token != null ? '${token.substring(0, min(20, token.length))}...' : 'NULL'}');
      if (token != null) {
        final success = await registerTokenOnBackend(token);
        print('📨 Enregistrement du token sur le backend: $success');
      } else {
        print('⚠️ Token FCM est null');
      }
      return token;
    } catch (e) {
      print('⚠️ Erreur lors de la récupération du token FCM: $e');
      return null;
    }
  }

  /// Enregistre le token FCM sur le backend
  Future<bool> registerTokenOnBackend(String token) async {
    try {
      final authToken = await _getStoredToken();
      if (authToken == null) {
        print('⚠️ Token JWT non trouvé, impossible d\'enregistrer le token FCM');
        return false;
      }

      final uri = Uri.parse('${AppConstants.baseUrl}/notifications/push-token');
      print('📤 POST $uri');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'token': token,
          'platform': 'android',
        }),
      );

      print('📥 Statut: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('⚠️ Erreur lors de l\'enregistrement du token: $e');
      return false;
    }
  }

  /// Supprime le token FCM du backend
  Future<bool> unregisterToken(String token) async {
    try {
      final authToken = await _getStoredToken();
      if (authToken == null) return false;

      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/notifications/push-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'token': token}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('⚠️ Erreur lors de la suppression du token: $e');
      return false;
    }
  }

  /// Récupère les notifications de l'utilisateur
  Future<Map<String, dynamic>?> getNotifications({
    int page = 1,
    int limit = 30,
  }) async {
    try {
      final token = await _getStoredToken();
      if (token == null) return null;

      final uri = Uri.parse('${AppConstants.baseUrl}/notifications').replace(
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('⚠️ Erreur lors de la récupération des notifications: $e');
      return null;
    }
  }

  /// Marque une notification comme lue
  Future<bool> markAsRead(String notificationId) async {
    try {
      final token = await _getStoredToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('⚠️ Erreur lors du marquage de la notification: $e');
      return false;
    }
  }

  /// Marque toutes les notifications comme lues
  Future<bool> markAllAsRead() async {
    try {
      final token = await _getStoredToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/notifications/read-all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('⚠️ Erreur lors du marquage des notifications: $e');
      return false;
    }
  }

  /// Gère le clic sur une notification
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    _handleNotificationTapData(data);
  }

  /// Gère le clic sur une notification (données)
  void _handleNotificationTapData(Map<String, dynamic> data) {
    final type = data['type'];

    // À compléter : navigation selon le type de notification
    print('📨 Type de notification: $type');
  }
}