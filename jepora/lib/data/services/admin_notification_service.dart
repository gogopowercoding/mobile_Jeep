import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../models/models.dart';

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
        _notifications = (res.data['data'] as List)
            .map((e) => NotificationModel.fromJson(e))
            .toList();
      }
    } catch (_) {} finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await ApiClient().dio.put('/notifications/$id/read');
      _notifications = _notifications.map((n) {
        if (n.id == id) {
          return NotificationModel(
            id: n.id, title: n.title, message: n.message,
            isRead: true, createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await ApiClient().dio.put('/notifications/read-all');
      _notifications = _notifications.map((n) => NotificationModel(
        id: n.id, title: n.title, message: n.message,
        isRead: true, createdAt: n.createdAt,
      )).toList();
      notifyListeners();
    } catch (_) {}
  }

  // Polling otomatis setiap 30 detik
  void startPolling() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));
      await fetchNotifications();
      return true;
    });
  }
}
