import 'package:flutter/material.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/services/auth_service.dart';

Future<void> showLogoutConfirmation(
  BuildContext context,
  AuthService auth,
) async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Keluar', style: AppTextStyles.h3),
      content: const Text(
        'Yakin ingin keluar dari akun?',
        style: AppTextStyles.body,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'Batal',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Keluar',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ],
    ),
  );

  if (shouldLogout != true || !context.mounted) return;

  await auth.logout();
  if (!context.mounted) return;
  Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
}

Future<void> showBiometricLoginSheet(
  BuildContext context,
  AuthService auth,
) async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (_, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: auth.biometricEnabled
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.divider.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fingerprint_rounded,
                size: 50,
                color: auth.biometricEnabled
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            auth.biometricEnabled ? 'Biometric Aktif' : 'Aktifkan Biometric Login',
            style: const TextStyle(
              fontSize: 18,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            auth.biometricEnabled
                ? 'Kamu bisa login menggunakan sidik jari tanpa perlu memasukkan password.'
                : 'Gunakan sidik jari untuk login lebih cepat dan aman.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Poppins',
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: !auth.biometricAvailable
                  ? null
                  : () async {
                      await auth.toggleBiometric(!auth.biometricEnabled);
                      if (context.mounted) Navigator.pop(context);
                    },
              icon: const Icon(Icons.fingerprint_rounded),
              label: Text(auth.biometricEnabled ? 'Nonaktifkan' : 'Aktifkan Sekarang'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    auth.biometricEnabled ? AppColors.error : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    ),
  );
}
