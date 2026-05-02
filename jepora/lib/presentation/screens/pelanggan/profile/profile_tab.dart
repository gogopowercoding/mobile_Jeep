import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jepora/core/constants/app_constants.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/services/auth_service.dart';
import 'package:jepora/data/services/feedback_service.dart';
import 'package:jepora/presentation/screens/pelanggan/feedback/my_feedback_screen.dart';
import 'package:jepora/presentation/widgets/common/common_widgets.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  @override
  void initState() {
    super.initState();
    // Re-check biometric setiap kali halaman profil dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().recheckBiometric();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;
    final String baseUrl = AppConstants.baseUrl.replaceAll('/api', '');

    // Tentukan image provider untuk avatar
    ImageProvider? avatarImage;
    if (user?.avatar != null && user!.avatar!.isNotEmpty) {
      avatarImage = NetworkImage('$baseUrl/uploads/${user.avatar}');
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profil')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header profil ─────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B8A4C), Color(0xFF39E07A)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.white24,
                    backgroundImage: avatarImage,
                    child: avatarImage == null
                        ? Text(
                            user?.name.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              fontSize: 36, fontWeight: FontWeight.w700,
                              color: Colors.white, fontFamily: 'Poppins',
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(user?.name ?? '-',
                    style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700,
                      color: Colors.white, fontFamily: 'Poppins',
                    )),
                  const SizedBox(height: 4),
                  Text(user?.email ?? '-',
                    style: TextStyle(
                      fontSize: 13, color: Colors.white.withOpacity(0.8),
                      fontFamily: 'Poppins',
                    )),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user?.role == 'admin' ? '👑 Admin'
                          : user?.role == 'supir' ? '🚙 Supir'
                          : '🧳 Pelanggan',
                      style: const TextStyle(
                        fontSize: 12, color: Colors.white,
                        fontWeight: FontWeight.w600, fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _MenuSection(title: 'Akun', items: [
                    _MenuItem(
                      icon: Icons.person_outline_rounded,
                      label: 'Edit Profil',
                      onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                    ),
                    _MenuItem(
                      icon: Icons.notifications_outlined,
                      label: 'Notifikasi',
                      onTap: () => Navigator.pushNamed(context, '/notifications'),
                    ),
                  _MenuItem(
                  icon: Icons.fingerprint_rounded,
                  label: 'Biometric Login',
                  trailing: Switch(
                    value: auth.biometricEnabled,
                    onChanged: (v) async {
                      if (!auth.biometricAvailable) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Biometrik tidak tersedia di perangkat ini')),
                        );
                        return;
                      }
                      await auth.toggleBiometric(v);
                    },
                    activeColor: AppColors.primary,
                  ),
                  onTap: () => _showBiometricSheet(context, auth), // ← ubah ini
                ),
                  ]),

                  const SizedBox(height: 12),
                  _MenuSection(title: 'Riwayat', items: [
                    _MenuItem(
                      icon: Icons.history_rounded,
                      label: 'Riwayat Pesanan',
                      onTap: () => Navigator.pushNamed(context, '/orders'),
                    ),
                    _MenuItem(
                      icon: Icons.star_outline_rounded,
                      label: 'Feedback Saya',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider(
                            create: (_) => FeedbackService(),
                            child: const MyFeedbackScreen(),
                          ),
                        ),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 12),
                  _MenuSection(title: 'Lainnya', items: [
                    _MenuItem(
                      icon: Icons.logout_rounded,
                      label: 'Keluar',
                      isDestructive: true,
                      onTap: () => _confirmLogout(context, auth),
                    ),
                  ]),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar', style: AppTextStyles.h3),
        content: const Text('Yakin ingin keluar dari akun?', style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await auth.logout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
            },
            child: const Text('Keluar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

void _showBiometricSheet(BuildContext context, AuthService auth) {
  showModalBottomSheet(
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
          // Handle bar
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // Icon fingerprint animasi
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (_, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              width: 90, height: 90,
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

          // Judul & deskripsi
          Text(
            auth.biometricEnabled
                ? 'Biometric Aktif'
                : 'Aktifkan Biometric Login',
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

          // Tombol aksi
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: !auth.biometricAvailable
                  ? null
                  : () async {
                      await auth.toggleBiometric(!auth.biometricEnabled);
                      if (context.mounted) Navigator.pop(context);
                    },
              icon: Icon(
                auth.biometricEnabled
                    ? Icons.fingerprint_rounded
                    : Icons.fingerprint_rounded,
              ),
              label: Text(
                auth.biometricEnabled ? 'Nonaktifkan' : 'Aktifkan Sekarang',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: auth.biometricEnabled
                    ? AppColors.error
                    : AppColors.primary,
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

          // Tombol batal
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

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: AppTextStyles.caption),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider, width: 0.5),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast) const Divider(height: 1, color: AppColors.divider,
                    indent: 52, endIndent: 0),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDestructive;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.isDestructive = false,
    this.trailing,
  });

  

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: isDestructive
              ? AppColors.error.withOpacity(0.1)
              : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
          size: 18,
          color: isDestructive ? AppColors.error : AppColors.primary,
        ),
      ),
      title: Text(label,
        style: TextStyle(
          fontSize: 14, fontFamily: 'Poppins', fontWeight: FontWeight.w500,
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
        ),
      ),
      trailing: trailing ?? (onTap != null
          ? const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20)
          : null),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}