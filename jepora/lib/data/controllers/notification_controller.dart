import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../models/models.dart';
import '../services/local_notification_service.dart';

/// Controller GetX khusus untuk fitur notifikasi.
///
/// Controller ini menggantikan pemakaian ChangeNotifier/Provider pada bagian
/// notifikasi saja. Fitur lain di project tetap aman memakai Provider.
class NotificationController extends GetxController {
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool isLoading = false.obs;
  final Rxn<String> error = Rxn<String>();

  Timer? _pollingTimer;
  bool _hasLoadedOnce = false;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  List<NotificationModel> get importantNotifs => notifications.where((n) {
        final title = n.title.toLowerCase();
        return title.contains('pesanan baru') ||
            title.contains('booking') ||
            title.contains('pembayaran') ||
            title.contains('bayar') ||
            title.contains('menolak') ||
            title.contains('menerima') ||
            title.contains('pending') ||
            !n.isRead;
      }).toList();

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  @override
  void onClose() {
    stopPolling();
    super.onClose();
  }

  Future<void> fetchNotifications({
    bool showLocalNotificationForNew = false,
  }) async {
    isLoading.value = true;
    error.value = null;

    final oldIds = notifications.map((n) => n.id).toSet();

    try {
      final res = await ApiClient().dio.get('/notifications');
      if (res.data['success'] == true) {
        final data = (res.data['data'] as List)
            .whereType<Map>()
            .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        // Local notification hanya dimunculkan untuk notifikasi baru setelah
        // data awal pernah dimuat. Ini mencegah semua notifikasi lama muncul
        // sekaligus saat aplikasi pertama kali dibuka.
        final shouldShowLocal = showLocalNotificationForNew || _hasLoadedOnce;
        if (shouldShowLocal) {
          for (final notif in data) {
            final isNew = !oldIds.contains(notif.id);
            if (isNew && !notif.isRead) {
              await LocalNotificationService().showNotification(
                id: notif.id,
                title: notif.title,
                body: notif.message,
                payload: notif.id.toString(),
              );
            }
          }
        }

        notifications.assignAll(data);
        _hasLoadedOnce = true;
      } else {
        error.value = res.data['message']?.toString() ?? 'Gagal memuat notifikasi';
      }
    } catch (e) {
      error.value = 'Gagal memuat notifikasi';
      if (kDebugMode) {
        print('Error fetching notifications with GetX: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await ApiClient().dio.put('/notifications/$id/read');
      final updated = notifications.map((n) {
        return n.id == id ? n.copyWith(isRead: true) : n;
      }).toList();
      notifications.assignAll(updated);
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as read with GetX: $e');
      }
    }
  }

  Future<void> markAllRead() async {
    try {
      await ApiClient().dio.put('/notifications/read-all');
      final updated = notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      notifications.assignAll(updated);
    } catch (e) {
      if (kDebugMode) {
        print('Error marking all notifications as read with GetX: $e');
      }
    }
  }

  void startPolling({Duration interval = const Duration(seconds: 30)}) {
    if (_pollingTimer != null) return;
    _pollingTimer = Timer.periodic(interval, (_) {
      fetchNotifications(showLocalNotificationForNew: true);
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }
}
