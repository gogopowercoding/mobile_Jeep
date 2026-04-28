import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
 
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
 
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
 
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5)),
    );
    _controller.forward();
    _navigate();
  }
 
  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final auth = context.read<AuthService>();
    await auth.init();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }
 
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Jeep tire logo
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.textOnPrimary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.tire_repair_rounded,
                    size: 54,
                    color: AppColors.textOnPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'JeepOra',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOnPrimary,
                    fontFamily: 'Poppins',
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Wisata Dieng Tak Terlupakan',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textOnPrimary.withOpacity(0.8),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: 28, height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.textOnPrimary.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
 