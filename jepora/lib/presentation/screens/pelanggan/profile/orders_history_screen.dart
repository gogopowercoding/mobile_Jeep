import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/models/order_model.dart';
import 'package:jepora/data/services/api_services.dart';
import 'package:jepora/data/services/auth_service.dart';
import 'package:jepora/presentation/widgets/common/common_widgets.dart';

/// Route: '/orders'
/// Menampilkan riwayat pesanan yang sudah berstatus 'completed'
class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({super.key});

  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth   = context.read<AuthService>();
      final orders = context.read<OrderService>();
      if (auth.user != null) {
        orders.fetchOrders(auth.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Pesanan'),
      ),
      body: Consumer<OrderService>(
        builder: (context, orders, _) {
          if (orders.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final completed = orders.orders
              .where((o) => o.status == 'completed')
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (completed.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.history_rounded,
                          size: 40, color: AppColors.primary),
                    ),
                    const SizedBox(height: 20),
                    const Text('Belum ada riwayat perjalanan',
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: AppColors.textPrimary,
                      )),
                    const SizedBox(height: 8),
                    const Text(
                      'Pesanan yang sudah selesai\nakan muncul di sini.',
                      style: AppTextStyles.bodyMuted,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () {
              final auth = context.read<AuthService>();
              return orders.fetchOrders(auth.user!.id);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: completed.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) => _HistoryCard(order: completed[i]),
            ),
          );
        },
      ),
    );
  }
}

// ─── History Card ─────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final OrderModel order;
  const _HistoryCard({required this.order});

  String _formatDate(String raw) {
    try {
      return DateFormat('dd MMM yyyy', 'id').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  String _formatPrice(double p) {
    return 'Rp ${p.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context, '/order-detail', arguments: order.id),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  const Text('Selesai',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: AppColors.primary,
                    )),
                  const Spacer(),
                  Text(
                    '#${order.id.toString().padLeft(5, '0')}',
                    style: const TextStyle(
                      fontSize: 12, fontFamily: 'Poppins',
                      color: AppColors.textHint,
                    )),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Gambar paket
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: order.packageImage != null
                        ? Image.network(
                            order.packageImage!,
                            width: 60, height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _placeholder(),
                          )
                        : _placeholder(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.packageName ?? 'Paket Wisata',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 12, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(_formatDate(order.bookingDate),
                            style: const TextStyle(
                              fontSize: 12, fontFamily: 'Poppins',
                              color: AppColors.textSecondary,
                            )),
                        ]),
                        const SizedBox(height: 4),
                        if (order.driverName != null)
                          Row(children: [
                            const Icon(Icons.person_rounded,
                                size: 12, color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Text(order.driverName!,
                              style: const TextStyle(
                                fontSize: 12, fontFamily: 'Poppins',
                                color: AppColors.textSecondary,
                              )),
                          ]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatPrice(order.totalPrice),
                        style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          color: AppColors.primary,
                        )),
                      const SizedBox(height: 4),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 12, color: AppColors.textHint),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 60, height: 60,
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: const Icon(Icons.landscape_rounded,
          color: AppColors.primary, size: 28),
    );
  }
}