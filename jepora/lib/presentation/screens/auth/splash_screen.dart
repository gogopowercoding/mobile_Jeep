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
    
    // Check if user sudah login (token tersimpan di SharedPreferences)
    if (auth.isLoggedIn) {
      // Route ke halaman sesuai role
      final role = auth.user?.role;
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else if (role == 'supir') {
        Navigator.pushReplacementNamed(context, '/driver');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      // Belum login → landing page
      Navigator.pushReplacementNamed(context, '/landing');
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