import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../../core/network/api_client.dart';

// ─── PACKAGE SERVICE ─────────────────────────────────────────
class PackageService extends ChangeNotifier {
  List<PackageModel> _packages = [];
  bool _isLoading = false;
  String? _error;

  List<PackageModel> get packages => _packages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPackages({String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiClient().dio.get('/packages',
        queryParameters: search != null ? {'search': search} : null,
      );
      if (res.data['success'] == true) {
        _packages = (res.data['data'] as List)
            .map((e) => PackageModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      _error = extractErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PackageModel?> fetchPackageById(int id) async {
    try {
      final res = await ApiClient().dio.get('/packages/$id');
      if (res.data['success'] == true) {
        return PackageModel.fromJson(res.data['data']);
      }
    } catch (e) {
      _error = extractErrorMessage(e);
    }
    return null;
  }
}

// ─── ORDER SERVICE ───────────────────────────────────────────
class OrderService extends ChangeNotifier {
  List<OrderModel> _orders = [];
  List<UserModel> _drivers = [];
  bool _isLoading = false;
  String? _error;

  List<OrderModel> get orders => _orders;
  List<UserModel> get drivers => _drivers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchOrders(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiClient().dio.get('/orders/user/$userId');
      if (res.data['success'] == true) {
        _orders = (res.data['data'] as List)
            .map((e) => OrderModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      _error = extractErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllOrders({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiClient().dio.get('/orders/user/all',
        queryParameters: status != null ? {'status': status} : null,
      );
      if (res.data['success'] == true) {
        _orders = (res.data['data'] as List)
            .map((e) => OrderModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      _error = extractErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OrderModel?> createOrder({
    required int packageId,
    required String bookingDate,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiClient().dio.post('/orders', data: {
        'package_id':   packageId,
        'booking_date': bookingDate,
        if (latitude != null)  'latitude':  latitude,
        if (longitude != null) 'longitude': longitude,
        if (notes != null)     'notes':     notes,
      });
      if (res.data['success'] == true) {
        return OrderModel.fromJson(res.data['data']);
      }
      _error = res.data['message'];
    } catch (e) {
      _error = extractErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  Future<bool> updateLocation(int orderId, double lat, double lng) async {
    try {
      final res = await ApiClient().dio.put('/orders/$orderId/location',
        data: {'latitude': lat, 'longitude': lng},
      );
      return res.data['success'] == true;
    } catch (_) { return false; }
  }

  Future<bool> updateStatus(int orderId, String status) async {
    try {
      final res = await ApiClient().dio.post('/orders/update-status',
        data: {'order_id': orderId, 'status': status},
      );
      return res.data['success'] == true;
    } catch (_) { return false; }
  }

  Future<bool> assignDriver(int orderId, int driverId) async {
    try {
      final res = await ApiClient().dio.post('/orders/assign-driver',
        data: {'order_id': orderId, 'driver_id': driverId},
      );
      return res.data['success'] == true;
    } catch (_) { return false; }
  }

  Future<void> fetchDrivers() async {
    try {
      final res = await ApiClient().dio.get('/orders/drivers');
      if (res.data['success'] == true) {
        _drivers = (res.data['data'] as List)
            .map((e) => UserModel.fromJson(e))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }
}

// ─── NOTIFICATION SERVICE ────────────────────────────────────
class NotificationService extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

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

  Future<void> markAllRead() async {
    try {
      await ApiClient().dio.put('/notifications/read-all');
      _notifications = _notifications
          .map((n) => NotificationModel(
                id: n.id, title: n.title, message: n.message,
                isRead: true, createdAt: n.createdAt))
          .toList();
      notifyListeners();
    } catch (_) {}
  }
}

// ─── CURRENCY SERVICE ────────────────────────────────────────
class CurrencyService {
  static Future<Map<String, dynamic>?> convert({
    required double amount,
    required String from,
    required String to,
  }) async {
    try {
      final res = await ApiClient().dio.get('/convert',
        queryParameters: {'amount': amount, 'from': from, 'to': to},
      );
      if (res.data['success'] == true) return res.data['data'];
    } catch (_) {}
    return null;
  }
}

// ─── FEEDBACK SERVICE ────────────────────────────────────────
class FeedbackService {
  static Future<bool> submit({
    required String message,
    required int rating,
    int? orderId,
  }) async {
    try {
      final res = await ApiClient().dio.post('/notifications/feedback', data: {
        'message': message,
        'rating':  rating,
        if (orderId != null) 'order_id': orderId,
      });
      return res.data['success'] == true;
    } catch (_) { return false; }
  }
}
