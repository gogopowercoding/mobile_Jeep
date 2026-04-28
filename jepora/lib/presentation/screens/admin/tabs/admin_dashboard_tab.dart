import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/services/auth_service.dart';
import 'package:jepora/data/services/api_services.dart';
import 'package:jepora/presentation/widgets/common/common_widgets.dart';
import '../widgets/admin_stat_card.dart';
import '../widgets/admin_order_card.dart';

class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({super.key});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderService>().fetchAllOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthService>();
    final orders = context.watch<OrderService>();

    final pending   = orders.orders.where((o) => o.status == 'pending').length;
    final confirmed = orders.orders.where((o) => o.status == 'confirmed').length;
    final ongoing   = orders.orders.where((o) => o.status == 'ongoing').length;
    final completed = orders.orders.where((o) => o.status == 'completed').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => context.read<OrderService>().fetchAllOrders(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Greeting ────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Halo, ${auth.user?.name ?? 'Admin'} 👋',
                            style: AppTextStyles.h3),
                          const Text('Dashboard Admin JeepOra',
                            style: AppTextStyles.bodyMuted),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.admin_panel_settings_rounded,
                            color: AppColors.primaryDark, size: 16),
                          SizedBox(width: 4),
                          Text('Admin', style: TextStyle(
                            color: AppColors.primaryDark, fontSize: 12,
                            fontWeight: FontWeight.w600, fontFamily: 'Poppins',
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ─── Stat Cards ──────────────────────────
                const Text('Ringkasan Pesanan', style: AppTextStyles.label),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    AdminStatCard(label: 'Menunggu', value: '$pending',
                      color: AppColors.statusPending, icon: Icons.hourglass_empty_rounded),
                    AdminStatCard(label: 'Dikonfirmasi', value: '$confirmed',
                      color: AppColors.statusConfirmed, icon: Icons.check_circle_outline_rounded),
                    AdminStatCard(label: 'Berjalan', value: '$ongoing',
                      color: AppColors.statusOngoing, icon: Icons.directions_car_rounded),
                    AdminStatCard(label: 'Selesai', value: '$completed',
                      color: AppColors.statusCompleted, icon: Icons.flag_rounded),
                  ],
                ),
                const SizedBox(height: 24),

                // ─── Recent Orders ───────────────────────
                SectionHeader(
                  title: 'Pesanan Terbaru',
                  actionText: 'Lihat Semua',
                  onAction: () {},
                ),
                const SizedBox(height: 12),

                if (orders.isLoading)
                  const Center(child: CircularProgressIndicator(color: AppColors.primary))
                else if (orders.orders.isEmpty)
                  const EmptyState(title: 'Belum ada pesanan', icon: Icons.inbox_outlined)
                else
                  ...orders.orders.take(5).map((order) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AdminOrderCard(order: order),
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}