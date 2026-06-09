import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jepora/core/constants/app_constants.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/services/auth_service.dart';
import 'package:jepora/data/services/feedback_service.dart';
import 'package:jepora/presentation/screens/pelanggan/feedback/my_feedback_screen.dart';
import 'package:jepora/presentation/widgets/common/profile_action_helpers.dart';

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
            // warna Header profil 
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
                  onTap: () => showBiometricLoginSheet(context, auth),
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
                      onTap: () => showLogoutConfirmation(context, auth),
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
        //warna editprofil background
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

  
//menuSection
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDestructive
              ? const Color(0xFFFFEAEA)
              : const Color(0xFFEAF7FF), // warna kotak icon
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDestructive
              ? const Color(0xFFE53935)
              : const Color(0xFF2196F3), // warna icon
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          color: isDestructive
              ? const Color(0xFFE53935)
              : const Color(0xFF333333), // warna teks
        ),
      ),
      trailing: trailing ??
          (onTap != null
              ? const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFB0B0B0), // warna panah kanan
                  size: 20,
                )
              : null),
    );
  }
}