import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/package_model.dart';
import '../models/schedule_model.dart';

/// Local database khusus untuk data Paket Wisata.
///
/// Hive di sini tidak menggantikan MySQL. Data utama tetap berasal dari backend,
/// sedangkan Hive dipakai sebagai cache lokal agar daftar/detail paket tetap bisa
/// ditampilkan ketika koneksi lambat atau offline.
class PackageCacheService {
  static const String boxName = 'package_cache';

  static const String _packagesKey = 'packages';
  static const String _packagesUpdatedAtKey = 'packages_updated_at';
  static const String _packageDetailPrefix = 'package_detail_';
  static const String _packageSchedulesPrefix = 'package_schedules_';

  /// Dipanggil sekali di main.dart sebelum runApp().
  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
  }

  static Box get _box => Hive.box(boxName);

  static Future<void> savePackages(List<PackageModel> packages) async {
    try {
      final encoded = packages.map((item) => item.toJson()).toList();
      await _box.put(_packagesKey, encoded);
      await _box.put(_packagesUpdatedAtKey, DateTime.now().toIso8601String());

      // Simpan juga detail per paket agar halaman detail punya fallback offline.
      for (final item in packages) {
        await savePackageDetail(item);
      }
    } catch (e) {
      debugPrint('Hive package cache savePackages error: $e');
    }
  }

  static List<PackageModel> getPackages({String? search}) {
    try {
      final raw = _box.get(_packagesKey);
      if (raw is! List) return [];

      final packages = raw
          .whereType<Map>()
          .map((item) => PackageModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      final keyword = search?.trim().toLowerCase();
      if (keyword == null || keyword.isEmpty) return packages;

      return packages.where((item) {
        final name = item.name.toLowerCase();
        final description = item.description?.toLowerCase() ?? '';
        return name.contains(keyword) || description.contains(keyword);
      }).toList();
    } catch (e) {
      debugPrint('Hive package cache getPackages error: $e');
      return [];
    }
  }

  static Future<void> savePackageDetail(PackageModel package) async {
    try {
      await _box.put('$_packageDetailPrefix${package.id}', package.toJson());
      if (package.schedules != null && package.schedules!.isNotEmpty) {
        await saveSchedules(package.id, package.schedules!);
      }
    } catch (e) {
      debugPrint('Hive package cache savePackageDetail error: $e');
    }
  }

  static PackageModel? getPackageDetail(int packageId) {
    try {
      final raw = _box.get('$_packageDetailPrefix$packageId');
      if (raw is Map) {
        return PackageModel.fromJson(Map<String, dynamic>.from(raw));
      }

      // Fallback: cari dari cache list paket.
      for (final item in getPackages()) {
        if (item.id == packageId) return item;
      }
    } catch (e) {
      debugPrint('Hive package cache getPackageDetail error: $e');
    }
    return null;
  }

  static Future<void> saveSchedules(
    int packageId,
    List<ScheduleModel> schedules,
  ) async {
    try {
      final encoded = schedules.map((item) => item.toJson()).toList();
      await _box.put('$_packageSchedulesPrefix$packageId', encoded);
    } catch (e) {
      debugPrint('Hive package cache saveSchedules error: $e');
    }
  }

  static List<ScheduleModel> getSchedules(int packageId) {
    try {
      final raw = _box.get('$_packageSchedulesPrefix$packageId');
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((item) => ScheduleModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }

      // Fallback: jadwal mungkin ikut tersimpan di detail paket.
      return getPackageDetail(packageId)?.schedules ?? [];
    } catch (e) {
      debugPrint('Hive package cache getSchedules error: $e');
      return [];
    }
  }

  static DateTime? get packagesUpdatedAt {
    try {
      final raw = _box.get(_packagesUpdatedAtKey);
      if (raw is String) return DateTime.tryParse(raw);
    } catch (_) {}
    return null;
  }

  static Future<void> clearPackages() async {
    try {
      final keys = _box.keys
          .where((key) => key == _packagesKey ||
              key == _packagesUpdatedAtKey ||
              key.toString().startsWith(_packageDetailPrefix) ||
              key.toString().startsWith(_packageSchedulesPrefix))
          .toList();
      await _box.deleteAll(keys);
    } catch (e) {
      debugPrint('Hive package cache clearPackages error: $e');
    }
  }
}
