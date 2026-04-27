import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late final Dio _dio;

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl:        AppConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      headers:        {'Content-Type': 'application/json'},
    ));

    // Interceptor: otomatis tambahkan token ke setiap request
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // Token expired → arahkan ke login
        if (error.response?.statusCode == 401) {
          // Handled di AuthService
        }
        return handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;
}

// Helper: ekstrak message dari response error Dio
String extractErrorMessage(dynamic error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Koneksi timeout. Periksa jaringan kamu.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke server.';
    }
  }
  return AppStrings.serverError;
}
