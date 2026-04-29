import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../models/models.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/app_constants.dart';

class AuthService extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get biometricAvailable => _biometricAvailable;
  bool get biometricEnabled => _biometricEnabled;
  bool get isAdmin => _user?.role == 'admin';
  bool get isDriver => _user?.role == 'supir';
  bool get isCustomer => _user?.role == 'pelanggan';

  final _localAuth = LocalAuthentication();

  // Init: cek token tersimpan & status biometric
  Future<void> init() async {
    await _checkBiometric();
    await _loadSavedUser();
  }

  Future<void> _checkBiometric() async {
    try {
      _biometricAvailable = await _localAuth.canCheckBiometrics;
      final prefs = await SharedPreferences.getInstance();
      _biometricEnabled = prefs.getBool(AppConstants.biometricKey) ?? false;
    } catch (_) {
      _biometricAvailable = false;
    }
    notifyListeners();
  }

  Future<void> _loadSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.userKey);
    if (userJson != null) {
      _user = UserModel.fromJson(jsonDecode(userJson));
      notifyListeners();
    }
  }

  // ─── REGISTER ────────────────────────────────────────────────
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    _setLoading(true);
    try {
      final res = await ApiClient().dio.post('/register', data: {
        'name': name, 'email': email,
        'password': password, 'phone': phone,
      });
      if (res.data['success'] == true) {
        await _saveSession(res.data['data']);
        return true;
      }
      _error = res.data['message'];
      return false;
    } catch (e) {
      _error = extractErrorMessage(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── LOGIN ───────────────────────────────────────────────────
  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    try {
      final res = await ApiClient().dio.post('/login', data: {
        'email': email, 'password': password,
      });
      if (res.data['success'] == true) {
        await _saveSession(res.data['data']);
        return true;
      }
      _error = res.data['message'];
      return false;
    } catch (e) {
      _error = extractErrorMessage(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── BIOMETRIC LOGIN ─────────────────────────────────────────
  // Token disimpan di SharedPreferences, bukan data biometric
  // Biometric hanya sebagai "kunci" untuk membuka token yang sudah tersimpan
  Future<bool> loginWithBiometric() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      if (token == null) {
        _error = 'Belum ada sesi tersimpan. Login dengan email dulu.';
        notifyListeners();
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Gunakan biometric untuk masuk ke JeepOra',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        await _loadSavedUser();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Biometric tidak tersedia';
      notifyListeners();
      return false;
    }
  }

  // ─── TOGGLE BIOMETRIC ────────────────────────────────────────
  Future<void> toggleBiometric(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.biometricKey, enabled);
    _biometricEnabled = enabled;
    notifyListeners();
  }

  // ─── LOGOUT ──────────────────────────────────────────────────
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
    _user = null;
    notifyListeners();
  }

  // ─── UPDATE PROFILE ──────────────────────────────────────────
  Future<bool> updateProfile({
    required String name,
    String? phone,
    String? oldPassword,
    String? newPassword,
    File? avatarFile,
  }) async {
    _setLoading(true);
    try {
      // Pakai FormData agar bisa kirim file avatar sekaligus
      final formData = FormData.fromMap({
        'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (oldPassword != null) 'old_password': oldPassword,
        if (newPassword != null) 'new_password': newPassword,
        if (avatarFile != null)
          'avatar': await MultipartFile.fromFile(
            avatarFile.path,
            filename: 'avatar_${_user?.id}.jpg',
          ),
      });

      final res = await ApiClient().dio.put(
        '/profile',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (res.data['success'] == true) {
        final updated = UserModel.fromJson(res.data['data']);
        _user = updated;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.userKey, jsonEncode(updated.toJson()));
        notifyListeners();
        return true;
      }
      _error = res.data['message'];
      return false;
    } catch (e) {
      _error = extractErrorMessage(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, data['token']);
    _user = UserModel.fromJson(data['user']);
    await prefs.setString(AppConstants.userKey, jsonEncode(_user!.toJson()));
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}