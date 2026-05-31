import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../local/package_cache_service.dart';
import '../../core/network/api_client.dart';

// ─── PACKAGE SERVICE ─────────────────────────────────────────
class PackageService extends ChangeNotifier {
  List<PackageModel> _packages = [];
  bool _isLoading = false;
  String? _error;

  List<PackageModel> get packages => _packages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Cache jadwal per paket. Cache runtime ini juga disinkronkan ke Hive.
  final Map<int, List<ScheduleModel>> _scheduleCache = {};
  final Map<int, bool> _scheduleLoading = {};

  Map<int, List<ScheduleModel>> get scheduleCache => _scheduleCache;
  Map<int, bool> get scheduleLoading => _scheduleLoading;

  // ─── PACKAGES ─────────────────────────────
  Future<void> fetchPackages({String? search}) async {
    final cachedPackages = PackageCacheService.getPackages(search: search);
    final hasCachedData = cachedPackages.isNotEmpty;

    _error = null;
    _isLoading = !hasCachedData;

    // Tampilkan cache dulu supaya paket tetap muncul saat internet lambat/offline.
    if (hasCachedData) {
      _packages = cachedPackages;
    }
    notifyListeners();

    try {
      final res = await ApiClient().dio.get(
        '/packages',
        queryParameters: search != null && search.trim().isNotEmpty
            ? {'search': search.trim()}
            : null,
      );

      if (res.data['success'] == true) {
        final freshPackages = (res.data['data'] as List)
            .whereType<Map>()
            .map((e) => PackageModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        _packages = freshPackages;

        // Simpan daftar paket utama ke Hive. Untuk hasil pencarian, cache tetap
        // tidak ditimpa agar cache offline berisi daftar lengkap terakhir.
        if (search == null || search.trim().isEmpty) {
          await PackageCacheService.savePackages(freshPackages);
        } else {
          for (final item in freshPackages) {
            await PackageCacheService.savePackageDetail(item);
          }
        }
      } else {
        _error = res.data['message']?.toString();
      }
    } catch (e) {
      if (!hasCachedData) {
        _error = extractErrorMessage(e);
      } else {
        // Kalau cache tersedia, aplikasi tetap menampilkan paket offline.
        _error = null;
        debugPrint('Menampilkan cache paket wisata dari Hive: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── SCHEDULE (PER PACKAGE) ───────────────
  Future<List<ScheduleModel>> fetchSchedules(int packageId) async {
    final cachedSchedules = PackageCacheService.getSchedules(packageId);
    final hasCachedSchedules = cachedSchedules.isNotEmpty;

    if (hasCachedSchedules) {
      _scheduleCache[packageId] = cachedSchedules;
    }

    _scheduleLoading[packageId] = !hasCachedSchedules;
    notifyListeners();

    try {
      final res = await ApiClient().dio.get(
        '/packages/$packageId/schedules',
      );

      if (res.data['success'] == true) {
        final data = (res.data['data'] as List)
            .whereType<Map>()
            .map((e) => ScheduleModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        _scheduleCache[packageId] = data;
        await PackageCacheService.saveSchedules(packageId, data);
        return data;
      }
    } catch (e) {
      if (hasCachedSchedules) {
        debugPrint('Menampilkan cache jadwal paket dari Hive: $e');
        return cachedSchedules;
      }
      _error = extractErrorMessage(e);
    } finally {
      _scheduleLoading[packageId] = false;
      notifyListeners();
    }

    return hasCachedSchedules ? cachedSchedules : [];
  }

  bool isScheduleLoading(int packageId) =>
      _scheduleLoading[packageId] ?? false;

  List<ScheduleModel> getSchedules(int packageId) =>
      _scheduleCache[packageId] ?? PackageCacheService.getSchedules(packageId);

  // ─── DELETE SCHEDULE ─────────────────────
  Future<void> deleteSchedule(int id, int packageId) async {
    try {
      await ApiClient().dio.delete('/schedules/$id');

      _scheduleCache[packageId]?.removeWhere((e) => e.id == id);
      await PackageCacheService.saveSchedules(
        packageId,
        _scheduleCache[packageId] ?? [],
      );

      notifyListeners();
    } catch (e) {
      _error = extractErrorMessage(e);
    }
  }

  // ─── CRUD SCHEDULE ───────────────────────
  Future<bool> createSchedule(int packageId, Map<String, dynamic> data) async {
    try {
      final res = await ApiClient().dio.post(
        '/packages/$packageId/schedules',
        data: data,
      );
      final success = res.data['success'] == true;
      if (success) await fetchSchedules(packageId);
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateSchedule(int id, Map<String, dynamic> data) async {
    try {
      final res = await ApiClient().dio.put(
        '/schedules/$id',
        data: data,
      );
      return res.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // Detail paket dengan fallback cache Hive.
  Future<PackageModel?> fetchPackageById(int id) async {
    final cachedPackage = PackageCacheService.getPackageDetail(id);

    try {
      final res = await ApiClient().dio.get('/packages/$id');
      if (res.data['success'] == true) {
        final package = PackageModel.fromJson(
          Map<String, dynamic>.from(res.data['data'] as Map),
        );
        await PackageCacheService.savePackageDetail(package);
        if (package.schedules != null && package.schedules!.isNotEmpty) {
          _scheduleCache[id] = package.schedules!;
          await PackageCacheService.saveSchedules(id, package.schedules!);
          notifyListeners();
        }
        return package;
      }
    } catch (e) {
      if (cachedPackage != null) {
        debugPrint('Menampilkan cache detail paket dari Hive: $e');
        return cachedPackage;
      }
      _error = extractErrorMessage(e);
    }

    return cachedPackage;
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
      final res = await ApiClient().dio.get(
        '/orders',  // ← Endpoint general
        queryParameters: {'user_id': userId.toString()},
      );
      
      if (res.data['success'] == true) {
        _orders = (res.data['data'] as List)
            .map((e) => OrderModel.fromJson(e))
            .toList();
        debugPrint('✅ Orders loaded: ${_orders.length}');
      } else {
        _error = res.data['message'];
      }
    } catch (e) {
      _error = extractErrorMessage(e);
      debugPrint('❌ Error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  // FIX: backend sudah support user_id='all' di GET /orders/user/:user_id
  // sehingga endpoint /orders/user/all valid dan tidak perlu route baru
    Future<void> fetchAllOrders({String? status}) async {
      _isLoading = true;
      _error = null;
      notifyListeners();
      try {
        // ✅ Gunakan query parameter
        final res = await ApiClient().dio.get(
          '/orders',  // ← Ganti ke endpoint general
          queryParameters: {
            'user_id': 'all',  // ← Pass user_id sebagai query param
            if (status != null) 'status': status,
          },
        );
        
        debugPrint('✅ Response: ${res.statusCode}');
        
        if (res.data['success'] == true) {
          _orders = (res.data['data'] as List)
              .map((e) => OrderModel.fromJson(e))
              .toList();
          debugPrint('✅ Orders loaded: ${_orders.length}');
        } else {
          _error = res.data['message'];
        }
      } catch (e) {
        _error = extractErrorMessage(e);
        debugPrint('❌ Error: $_error');
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
    int? voucherId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiClient().dio.post('/orders', data: {
        'package_id':   packageId,
        'booking_date': bookingDate,
        if (latitude != null)   'latitude':   latitude,
        if (longitude != null)  'longitude':  longitude,
        if (notes != null)      'notes':      notes,
        if (voucherId != null)  'voucher_id': voucherId,
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

  /// GET /api/orders/:id — detail lengkap satu pesanan (termasuk bukti bayar)
  Future<Map<String, dynamic>?> getOrderDetail(int orderId) async {
    try {
      final res = await ApiClient().dio.get('/orders/$orderId');
      if (res.data['success'] == true) {
        return res.data['data'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
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
          .map((n) => n.copyWith(isRead: true))
          .toList();
      notifyListeners();
    } catch (_) {}
  }
}

// ─── CURRENCY SERVICE ────────────────────────────────────────
class CurrencyService {
  // FIX: endpoint disesuaikan dengan backend GET /payments/convert/rate
  static Future<Map<String, dynamic>?> convert({
    required double amount,
    required String from,
    required String to,
  }) async {
    try {
      final res = await ApiClient().dio.get(
        '/payments/convert/rate',
        queryParameters: {'amount': amount, 'from': from, 'to': to},
      );
      if (res.data['success'] == true) return res.data['data'];
    } catch (_) {}
    return null;
  }
}

// ─── CATATAN: FeedbackService dihapus dari file ini ──────────
// Gunakan FeedbackService dari:
// lib/data/services/feedback_service.dart
// (versi lengkap dengan ChangeNotifier dan full CRUD)
