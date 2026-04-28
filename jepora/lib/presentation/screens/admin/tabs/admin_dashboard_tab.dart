import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/services/auth_service.dart';
import 'package:jepora/data/services/api_services.dart';
import 'package:jepora/data/models/models.dart';
import 'package:jepora/presentation/widgets/common/common_widgets.dart';

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

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<OrderService>().fetchAllOrders(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text('Halo, ${auth.user?.name ?? 'Admin'} 👋',
              style: AppTextStyles.h3),
            const Text('Berikut ringkasan aktivitas hari ini',
              style: AppTextStyles.bodyMuted),
            const SizedBox(height: 20),

            // Stats
            const Text('Ringkasan Pesanan', style: AppTextStyles.label),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12, mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _StatCard(label: 'Menunggu', value: '$pending',
                  color: AppColors.statusPending,
                  icon: Icons.hourglass_empty_rounded),
                _StatCard(label: 'Dikonfirmasi', value: '$confirmed',
                  color: AppColors.statusConfirmed,
                  icon: Icons.check_circle_outline_rounded),
                _StatCard(label: 'Berjalan', value: '$ongoing',
                  color: AppColors.statusOngoing,
                  icon: Icons.directions_car_rounded),
                _StatCard(label: 'Selesai', value: '$completed',
                  color: AppColors.statusCompleted,
                  icon: Icons.flag_rounded),
              ],
            ),

            const SizedBox(height: 24),
            SectionHeader(title: 'Pesanan Terbaru'),
            const SizedBox(height: 12),

            if (orders.isLoading)
              const Center(child: CircularProgressIndicator(color: AppColors.primary))
            else if (orders.orders.isEmpty)
              const EmptyState(title: 'Belum ada pesanan', icon: Icons.inbox_outlined)
            else
              ...orders.orders.take(5).map((order) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DashboardOrderCard(order: order),
              )),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;

  const _StatCard({required this.label, required this.value,
    required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: TextStyle(fontSize: 22,
                fontWeight: FontWeight.w700, color: color, fontFamily: 'Poppins')),
              Text(label, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardOrderCard extends StatelessWidget {
  final OrderModel order;
  const _DashboardOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.directions_car_rounded,
              color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#${order.id} — ${order.packageName ?? "-"}',
                  style: AppTextStyles.label),
                Text(order.bookingDate, style: AppTextStyles.caption),
              ],
            ),
          ),
          StatusBadge(status: order.status),
        ],
      ),
    );
  }
}