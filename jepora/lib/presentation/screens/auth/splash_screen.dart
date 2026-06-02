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

    final auth = context.read<AuthService>();

    // Pastikan auth benar-benar selesai dicek
    await auth.init();

    if (!mounted) return;

    // Jika ada session tersimpan dan biometric aktif,
    // paksa user masuk lewat landing/login biometric dulu
    if (auth.hasSavedSession && auth.biometricEnabled) {
      Navigator.pushReplacementNamed(context, '/landing');
      return;
    }

    if (!auth.isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/landing');
      return;
    }

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