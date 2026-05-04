import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jepora/data/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // ✅ Pakai AuthService — bukan baca SharedPreferences langsung
    // Ini memastikan auth.init() selesai (biometric + loginTimestamp ter-load)
    // sebelum kita cek status login
    final auth = context.read<AuthService>();

    // Tunggu init selesai jika belum (AuthService.init() dipanggil di provider)
    // Beri sedikit jeda agar init() yang async selesai duluan
    int retry = 0;
    while (auth.user == null && auth.isLoading == false && retry < 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      retry++;
    }

    if (!mounted) return;

    if (!auth.isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/landing');
      return;
    }

    // ✅ Baca role dari AuthService, bukan dari prefs langsung
    final role = auth.user?.role;
    switch (role) {
      case 'admin':
        Navigator.pushReplacementNamed(context, '/admin');
        break;
      case 'supir':
        Navigator.pushReplacementNamed(context, '/driver');
        break;
      default:
        Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF63E56E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/JeepOra logo.png',
              width: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: Colors.black,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}