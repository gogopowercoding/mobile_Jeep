class AppConstants {
  // Base URL - ganti sesuai IP server kamu
  // Emulator Android: 10.0.2.2
  // Device fisik: IP komputer kamu, misal 192.168.1.x
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // Storage keys
  static const String tokenKey       = 'auth_token';
  static const String userKey        = 'user_data';
  static const String biometricKey   = 'biometric_enabled';

  // Default currency
  static const String defaultCurrency = 'IDR';

  // Timeout
  static const int connectTimeout = 10000;
  static const int receiveTimeout = 10000;
}

class AppStrings {
  static const String appName      = 'JeepOra';
  static const String tagline      = 'Pesan Jeep Wisata Dieng, JeepOra solusinya';
  static const String noConnection = 'Tidak ada koneksi internet';
  static const String serverError  = 'Terjadi kesalahan pada server';
  static const String sessionExpired = 'Sesi kamu telah berakhir, silakan login kembali';
}
