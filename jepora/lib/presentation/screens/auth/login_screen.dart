import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/services/auth_service.dart';
import 'package:jepora/presentation/widgets/common/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
 
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
 
class _LoginScreenState extends State<LoginScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _emailCtrl   = TextEditingController();
  final _passwordCtrl = TextEditingController();
 
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    final ok = await auth.login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
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
        SnackBar(content: Text(auth.error ?? 'Login gagal'), backgroundColor: AppColors.error),
      );
    }
  }
 
  Future<void> _biometricLogin() async {
    final auth = context.read<AuthService>();
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
        SnackBar(content: Text(auth.error ?? 'Biometric gagal'), backgroundColor: AppColors.error),
      );
    }
  }
 
  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
 
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient hijau atas
          Container(
            height: MediaQuery.of(context).size.height * 0.42,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B8A4C), Color(0xFF39E07A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
 
          // Ilustrasi pegunungan (SVG/placeholder)
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.56,
            left: 0, right: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 80),
              painter: _MountainPainter(),
            ),
          ),
 
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                    child: Column(
                      children: [
                        const Text(
                          'JeepOra',
                          style: TextStyle(
                            fontSize: 32, fontWeight: FontWeight.w700,
                            color: Colors.white, fontFamily: 'Poppins',
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pesan Jeep Wisata Dieng, JeepOra solusinya',
                          style: TextStyle(
                            fontSize: 13, color: Colors.white.withOpacity(0.85),
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
 
                  const SizedBox(height: 40),
 
                  // Card form
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20, offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Login',
                            style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins', color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 20),
 
                          AppTextField(
                            hint: 'Masukkan email',
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            validator: (v) => v!.isEmpty ? 'Email wajib diisi' : null,
                          ),
                          const SizedBox(height: 14),
 
                          AppTextField(
                            hint: 'Masukkan password',
                            controller: _passwordCtrl,
                            isPassword: true,
                            prefixIcon: Icons.lock_outlined,
                            validator: (v) => v!.isEmpty ? 'Password wajib diisi' : null,
                          ),
                          const SizedBox(height: 8),
 
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: const Text('Lupa Password?',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13, fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
 
                          // Login button + biometric
                          Row(
                            children: [
                              Expanded(
                                child: PrimaryButton(
                                  text: 'Login',
                                  isLoading: auth.isLoading,
                                  onPressed: _login,
                                ),
                              ),
                              if (auth.biometricAvailable && auth.biometricEnabled) ...[
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: _biometricLogin,
                                  child: Container(
                                    width: 52, height: 52,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.fingerprint_rounded,
                                      color: AppColors.primary, size: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
 
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Belum punya akun? ',
                                style: TextStyle(fontSize: 13, fontFamily: 'Poppins',
                                  color: AppColors.textSecondary),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/register'),
                                child: const Text('Daftar Sekarang',
                                  style: TextStyle(
                                    fontSize: 13, fontFamily: 'Poppins',
                                    color: AppColors.primary, fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
 
// Painter untuk ilustrasi pegunungan sederhana
class _MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF2DBF6A).withOpacity(0.5);
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.2, size.height * 0.1)
      ..lineTo(size.width * 0.4, size.height * 0.6)
      ..lineTo(size.width * 0.6, size.height * 0.0)
      ..lineTo(size.width * 0.8, size.height * 0.5)
      ..lineTo(size.width, size.height * 0.2)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(_) => false;
}
 