import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:jepora/data/services/auth_service.dart';
import 'package:jepora/data/services/api_services.dart';
import 'package:jepora/data/models/models.dart';
import 'package:jepora/presentation/widgets/common/common_widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:jepora/data/models/location_model.dart';
import 'package:jepora/data/services/local_notification_service.dart';

part 'widgets/order_card.dart';
part 'screens/create_booking_screen.dart';
part 'screens/order_detail_screen.dart';

class BookingTab extends StatefulWidget {
  const BookingTab({super.key});

  @override
  State<BookingTab> createState() => _BookingTabState();
}

class _BookingTabState extends State<BookingTab> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      if (auth.user != null) {
        context.read<OrderService>().fetchOrders(auth.user!.id);
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderService>();
    final auth   = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pesanan Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            onPressed: () => Navigator.pushNamed(context, '/create-booking'),
          ),
        ],
      ),
      body: orders.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : orders.orders.isEmpty
              ? EmptyState(
                  title: 'Belum ada pesanan',
                  subtitle: 'Yuk buat pesanan jeep wisata pertamamu!',
                  icon: Icons.directions_car_outlined,
                  actionText: 'Booking Sekarang',
                  onAction: () => Navigator.pushNamed(context, '/create-booking'),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => orders.fetchOrders(auth.user!.id),
                  child: Builder(builder: (context) {
                    // Hanya tampilkan order yang belum selesai
                    final activeOrders = orders.orders
                        .where((o) => o.status != 'completed')
                        .toList();
                    if (activeOrders.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline_rounded,
                                  size: 64, color: AppColors.primary),
                              const SizedBox(height: 16),
                              const Text('Semua pesanan selesai!',
                                style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                  color: AppColors.textPrimary,
                                )),
                              const SizedBox(height: 8),
                              const Text('Lihat riwayat perjalananmu di Profil.',
                                style: AppTextStyles.bodyMuted,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              TextButton.icon(
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/orders'),
                                icon: const Icon(Icons.history_rounded,
                                    color: AppColors.primary),
                                label: const Text('Lihat Riwayat',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  )),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: activeOrders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        return _OrderCard(order: activeOrders[i]);
                      },
                    );
                  }),
                ),
    );
  }
}
