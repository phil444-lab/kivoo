import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _fcmToken;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get fcmToken => _fcmToken;

  /// Initialise le provider : demande le token FCM et le registre
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _notificationService.initialize();
    _fcmToken = await _notificationService.getTokenAndRegister();
    await loadNotifications();
    _isInitialized = true;
    notifyListeners();
  }

  /// Rafraîchit les notifications (appelé quand l'utilisateur se connecte)
  Future<void> refresh() async {
    // Ré-enregistrer le token FCM (nouvel utilisateur)
    _fcmToken = await _notificationService.getTokenAndRegister();
    await loadNotifications();
    notifyListeners();
  }

  /// Charge les notifications depuis le backend
  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    final result = await _notificationService.getNotifications();
    if (result != null) {
      final notificationsList = (result['notifications'] as List)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
      _notifications = notificationsList;
      _unreadCount = (result['unreadCount'] as num?)?.toInt() ?? 0;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Marque une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    final success = await _notificationService.markAsRead(notificationId);
    if (success) {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = AppNotification(
          id: _notifications[index].id,
          type: _notifications[index].type,
          title: _notifications[index].title,
          message: _notifications[index].message,
          data: _notifications[index].data,
          read: true,
          createdAt: _notifications[index].createdAt,
        );
        if (_unreadCount > 0) _unreadCount--;
        notifyListeners();
      }
    }
  }

  /// Marque toutes les notifications comme lues
  Future<void> markAllAsRead() async {
    final success = await _notificationService.markAllAsRead();
    if (success) {
      _notifications = _notifications
          .map((n) => AppNotification(
                id: n.id,
                type: n.type,
                title: n.title,
                message: n.message,
                data: n.data,
                read: true,
                createdAt: n.createdAt,
              ))
          .toList();
      _unreadCount = 0;
      notifyListeners();
    }
  }

  /// Rafraîchit le token FCM (appelé quand l'utilisateur se connecte)
  Future<void> refreshToken() async {
    _fcmToken = await _notificationService.getTokenAndRegister();
    notifyListeners();
  }
}