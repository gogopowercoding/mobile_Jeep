import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/services/auth_service.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().recheckBiometric();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _biometricLogin() async {
    final auth = context.read<AuthService>();

    if (!auth.biometricAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Biometrik tidak tersedia. Aktifkan di Profil setelah login.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!auth.biometricEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometrik belum diaktifkan. Login dengan email dulu.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final ok = await auth.loginWithBiometric();
    if (!mounted) return;

    if (ok) {
      final role = auth.user?.role;

      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else if (role == 'supir') {
        Navigator.pushReplacementNamed(context, '/driver');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Biometrik gagal, coba lagi'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FFF9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: Column(
                children: [
                  const Spacer(),

                  // Gambar utama dari assets/images
                  Image.asset(
                    'assets/icons/JeepOra logo.png',
                    width: 170,
                    height: 170,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'JeepOra',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B8A4C),
                      fontFamily: 'Poppins',
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Pesan Jeep Wisata Dieng dengan mudah dan cepat',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black.withOpacity(0.65),
                      fontFamily: 'Poppins',
                    ),
                  ),

                  const Spacer(),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF39E07A),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(54),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      GestureDetector(
                        onTap: _biometricLogin,
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: auth.biometricAvailable &&
                                    auth.biometricEnabled
                                ? const Color(0xFFE6F9F0)
                                : Colors.grey.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            Icons.fingerprint_rounded,
                            color: auth.biometricAvailable &&
                                    auth.biometricEnabled
                                ? const Color(0xFF1B8A4C)
                                : Colors.grey,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Belum punya akun? ',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Poppins',
                          color: Colors.black.withOpacity(0.65),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: const Text(
                          'Daftar Sekarang',
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'Poppins',
                            color: Color(0xFF1B8A4C),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 34),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}