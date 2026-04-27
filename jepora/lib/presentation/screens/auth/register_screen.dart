import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/services/auth_service.dart';
import 'package:jepora/presentation/widgets/common/common_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  bool _biometricOpt  = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    final ok = await auth.register(
      name:     _nameCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      phone:    _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      if (_biometricOpt) await auth.toggleBiometric(true);
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Registrasi gagal'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passwordCtrl.dispose(); _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text('Daftar Sekarang', style: AppTextStyles.h1),
              const SizedBox(height: 4),
              const Text('Tolong isi data dan buat akun', style: AppTextStyles.bodyMuted),
              const SizedBox(height: 28),

              AppTextField(
                hint: 'Masukkan nama',
                controller: _nameCtrl,
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 14),

              AppTextField(
                hint: 'Masukkan email',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: (v) {
                  if (v!.isEmpty) return 'Email wajib diisi';
                  if (!v.contains('@')) return 'Format email tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              AppTextField(
                hint: 'Masukkan password',
                controller: _passwordCtrl,
                isPassword: true,
                prefixIcon: Icons.lock_outlined,
                validator: (v) {
                  if (v!.isEmpty) return 'Password wajib diisi';
                  if (v.length < 6) return 'Password minimal 6 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text('Password minimal 6 karakter', style: AppTextStyles.caption),
              ),
              const SizedBox(height: 14),

              AppTextField(
                hint: 'Nomor telepon (opsional)',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 16),

              // Biometric option
              if (auth.biometricAvailable)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fingerprint_rounded, color: AppColors.primary, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Daftarkan biometric', style: AppTextStyles.label),
                            Text('Login lebih cepat dengan sidik jari', style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      Switch(
                        value: _biometricOpt,
                        onChanged: (v) => setState(() => _biometricOpt = v),
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 28),

              PrimaryButton(
                text: 'Daftar',
                isLoading: auth.isLoading,
                onPressed: _register,
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sudah punya akun? ', style: AppTextStyles.bodyMuted),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text('Masuk',
                      style: TextStyle(
                        fontSize: 14, color: AppColors.primary,
                        fontWeight: FontWeight.w600, fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
