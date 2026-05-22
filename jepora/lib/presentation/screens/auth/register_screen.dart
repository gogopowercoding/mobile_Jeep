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
                  
                  // Regex untuk validasi email format
                  const emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
                  if (!RegExp(emailPattern).hasMatch(v)) {
                    return 'Format email tidak valid (contoh: user@gmail.com)';
                  }
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
