import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/services/api_services.dart';
import 'package:jepora/presentation/widgets/common/common_widgets.dart';
import 'package:jepora/presentation/screens/admin/widgets/admin_order_card.dart';

class AdminOrdersTab extends StatefulWidget {
  const AdminOrdersTab({super.key});

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab> {
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderService>().fetchAllOrders();
      context.read<OrderService>().fetchDrivers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderService>();
    final filtered = _filterStatus == 'all'
        ? orders.orders
        : orders.orders.where((o) => o.status == _filterStatus).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Semua Pesanan')),
      body: Column(
        children: [
          // ─── Filter chips ────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: ['all', 'pending', 'confirmed', 'ongoing', 'completed', 'cancelled']
                  .map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _filterStatus = s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: _filterStatus == s ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _filterStatus == s ? AppColors.primary : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          s == 'all'       ? 'Semua'
                            : s == 'pending'    ? 'Menunggu'
                            : s == 'confirmed'  ? 'Dikonfirmasi'
                            : s == 'ongoing'    ? 'Berjalan'
                            : s == 'completed'  ? 'Selesai' : 'Dibatalkan',
                          style: TextStyle(
                            fontSize: 12, fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            color: _filterStatus == s
                                ? AppColors.textOnPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  )).toList(),
            ),
          ),

          // ─── List ────────────────────────────────
          Expanded(
            child: orders.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filtered.isEmpty
                    ? const EmptyState(title: 'Tidak ada pesanan', icon: Icons.inbox_outlined)
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () => orders.fetchAllOrders(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) =>
                              AdminOrderCard(order: filtered[i], showActions: true),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}