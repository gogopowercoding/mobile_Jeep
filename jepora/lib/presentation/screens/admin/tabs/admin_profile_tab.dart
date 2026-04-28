import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/services/auth_service.dart';

class AdminProfileTab extends StatelessWidget {
  const AdminProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
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
                    child: Text(
                      auth.user?.name.substring(0, 1).toUpperCase() ?? 'A',
                      style: const TextStyle(fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white, fontFamily: 'Poppins'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(auth.user?.name ?? '-',
                    style: const TextStyle(fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white, fontFamily: 'Poppins')),
                  const SizedBox(height: 4),
                  Text(auth.user?.email ?? '-',
                    style: TextStyle(fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                      fontFamily: 'Poppins')),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('👑 Administrator',
                      style: TextStyle(fontSize: 13, color: Colors.white,
                        fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildTile(
                    icon: Icons.person_outline_rounded,
                    label: 'Edit Profil',
                    onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                  ),
                  const SizedBox(height: 10),
                  _buildTile(
                    icon: Icons.people_outline_rounded,
                    label: 'Manajemen User',
                    onTap: () {},
                  ),
                  const SizedBox(height: 10),
                  _buildTile(
                    icon: Icons.bar_chart_rounded,
                    label: 'Laporan',
                    onTap: () {},
                  ),
                  const SizedBox(height: 10),
                  _buildTile(
                    icon: Icons.logout_rounded,
                    label: 'Keluar',
                    isDestructive: true,
                    onTap: () async {
                      await auth.logout();
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/login', (_) => false);
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: isDestructive
                ? AppColors.error.withOpacity(0.1)
                : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18,
            color: isDestructive ? AppColors.error : AppColors.primary),
        ),
        title: Text(label,
          style: TextStyle(fontSize: 14, fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            color: isDestructive ? AppColors.error : AppColors.textPrimary)),
        trailing: isDestructive
            ? null
            : const Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint, size: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}