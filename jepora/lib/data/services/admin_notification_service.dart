import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../models/models.dart';
import 'local_notification_service.dart';

class AdminNotificationService extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Notifikasi penting untuk admin
  List<NotificationModel> get importantNotifs => _notifications.where((n) {
        final title = n.title.toLowerCase();
        return title.contains('pesanan baru') ||
            title.contains('pembayaran') ||
            title.contains('menolak') ||
            title.contains('menerima') ||
            title.contains('pending') ||
            !n.isRead;
      }).toList();

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiClient().dio.get('/notifications');
      if (res.data['success'] == true) {
        final newNotifications = (res.data['data'] as List)
            .map((e) => NotificationModel.fromJson(e))
            .toList();

        // Check untuk notifikasi baru yang belum dibaca
        for (var newNotif in newNotifications) {
          final existingNotif = _notifications.firstWhere(
            (n) => n.id == newNotif.id,
            orElse: () => NotificationModel(
              id: -1,
              title: '',
              message: '',
              isRead: true,
              createdAt: DateTime.now(),
            ),
          );

          // Jika notifikasi baru dan belum dibaca, tampilkan local notification
          if (existingNotif.id == -1 && !newNotif.isRead) {
            await LocalNotificationService().showNotification(
              id: newNotif.id,
              title: newNotif.title,
              body: newNotif.message,
              payload: newNotif.id.toString(),
            );
          }
        }

        _notifications = newNotifications;
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await ApiClient().dio.put('/notifications/$id/read');
      _notifications = _notifications.map((n) {
        if (n.id == id) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllRead() async {
    try {
      await ApiClient().dio.put('/notifications/read-all');
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error marking all notifications as read: $e');
    }
  }

  // Polling otomatis setiap 30 detik
  bool _isPolling = false;

  void startPolling() {
    if (_isPolling) return;
    _isPolling = true;
    Future.doWhile(() async {
      if (!_isPolling) return false;
      await Future.delayed(const Duration(seconds: 30));
      if (_isPolling) {
        await fetchNotifications();
      }
      return _isPolling;
    });
  }

  void stopPolling() {
    _isPolling = false;
  }
}
