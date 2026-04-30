import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_services.dart';
import '../../../data/models/models.dart';
import '../../widgets/common/common_widgets.dart';

class DriverActiveTab extends StatefulWidget {
  const DriverActiveTab({super.key});

  @override
  State<DriverActiveTab> createState() => _DriverActiveTabState();
}

class _DriverActiveTabState extends State<DriverActiveTab> {
  List<OrderModel> _activeOrders = [];
  bool _isLoading = false;

  // Lokasi driver real-time
  Timer? _locationTimer;
  Position? _driverPosition;
  int? _trackingOrderId; // order yang sedang di-track lokasinya ke pelanggan

  @override
  void initState() {
    super.initState();
    _fetchActiveOrders();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    // Minta izin lokasi
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return;
    }
    if (perm == LocationPermission.deniedForever) return;

    // Update lokasi tiap 10 detik
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        if (mounted) setState(() => _driverPosition = pos);

        // Kirim lokasi ke server untuk order yang sedang ongoing
        if (_trackingOrderId != null) {
          await ApiClient().dio.put('/orders/$_trackingOrderId/driver-location', data: {
            'latitude':  pos.latitude,
            'longitude': pos.longitude,
          });
        }
      } catch (_) {}
    });
  }

  Future<void> _fetchActiveOrders() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient().dio.get('/orders/driver-active');
      if (res.data['success'] == true) {
        final orders = (res.data['data'] as List)
            .map((e) => OrderModel.fromJson(e))
            .toList();
        setState(() => _activeOrders = orders);

        // Restore tracking jika ada order ongoing (misal setelah restart app)
        final ongoingOrder = orders.where((o) => o.status == 'ongoing').firstOrNull;
        if (ongoingOrder != null && _trackingOrderId == null) {
          setState(() => _trackingOrderId = ongoingOrder.id);
        }
      }
    } catch (_) {} finally {
      setState(() => _isLoading = false);
    }
  }

  /// Kirim lokasi langsung tanpa menunggu timer
  Future<void> _sendLocationNow(int orderId) async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) setState(() => _driverPosition = pos);
      await ApiClient().dio.put('/orders/$orderId/driver-location', data: {
        'latitude':  pos.latitude,
        'longitude': pos.longitude,
      });
    } catch (_) {}
  }

  Future<void> _updateStatus(int orderId, String status) async {
    final orderService = context.read<OrderService>();
    final ok = await orderService.updateStatus(orderId, status);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(status == 'ongoing'
            ? '🚙 Perjalanan dimulai! Lokasi Anda dipantau.'
            : '🏁 Perjalanan selesai!'),
        backgroundColor: AppColors.success,
      ));
      // Mulai/stop tracking lokasi driver
      setState(() {
        _trackingOrderId = status == 'ongoing' ? orderId : null;
      });
      // Kirim lokasi langsung sekarang (tidak nunggu timer 10 detik)
      if (status == 'ongoing') {
        _sendLocationNow(orderId);
      }
      _fetchActiveOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pesanan Aktif'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _fetchActiveOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _activeOrders.isEmpty
              ? const EmptyState(
                  title: 'Tidak ada pesanan aktif',
                  subtitle: 'Pesanan yang sudah Anda terima akan muncul di sini',
                  icon: Icons.directions_car_outlined,
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _fetchActiveOrders,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _activeOrders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) => _ActiveOrderCard(
                      order: _activeOrders[i],
                      onUpdateStatus: _updateStatus,
                    ),
                  ),
                ),
    );
  }
}

// ─── ACTIVE ORDER CARD ───────────────────────────────────────
class _ActiveOrderCard extends StatelessWidget {
  final OrderModel order;
  final Function(int, String) onUpdateStatus;

  const _ActiveOrderCard({
    required this.order,
    required this.onUpdateStatus,
  });

  String _formatRupiah(double amount) => 'Rp ${amount
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.directions_car_rounded,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order #${order.id}',
                              style: AppTextStyles.label),
                          Text(order.packageName ?? 'Paket Wisata',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    StatusBadge(status: order.status),
                  ],
                ),

                // Indikator lokasi aktif (jika sedang ongoing)
                if (order.status == 'ongoing') ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(children: [
                      Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text('Lokasi Anda sedang dibagikan ke pelanggan',
                        style: TextStyle(fontSize: 11, fontFamily: 'Poppins',
                            color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 12),

                // Info rows
                _InfoRow(icon: Icons.person_outline_rounded,
                    label: 'Pelanggan',
                    value: order.customerName ?? '-'),
                const SizedBox(height: 6),
                _InfoRow(icon: Icons.calendar_today_rounded,
                    label: 'Tanggal', value: order.bookingDate),
                const SizedBox(height: 6),
                _InfoRow(icon: Icons.payments_outlined,
                    label: 'Total', value: _formatRupiah(order.totalPrice)),
                if (order.notes != null && order.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _InfoRow(icon: Icons.notes_rounded,
                      label: 'Catatan', value: order.notes!),
                ],

                // Lokasi pelanggan
                if (order.latitude != null && order.longitude != null) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomerLocationMapScreen(order: order),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${order.latitude!.toStringAsFixed(5)}, ${order.longitude!.toStringAsFixed(5)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryDark,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          const Row(
                            children: [
                              Icon(Icons.map_rounded,
                                  color: AppColors.primary, size: 16),
                              SizedBox(width: 4),
                              Text('Lihat Peta',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                if (order.status == 'confirmed')
                  PrimaryButton(
                    text: 'Mulai Perjalanan',
                    icon: Icons.directions_car_rounded,
                    onPressed: () => onUpdateStatus(order.id, 'ongoing'),
                  ),
                if (order.status == 'ongoing')
                  ElevatedButton.icon(
                    icon: const Icon(Icons.flag_rounded, size: 18),
                    label: const Text('Selesaikan Perjalanan'),
                    onPressed: () => onUpdateStatus(order.id, 'completed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusCompleted,
                      minimumSize: const Size(double.infinity, 52),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── INFO ROW ────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        SizedBox(
            width: 72, child: Text(label, style: AppTextStyles.caption)),
        Expanded(child: Text(value, style: AppTextStyles.body)),
      ],
    );
  }
}

// ─── CUSTOMER LOCATION MAP SCREEN ────────────────────────────
class CustomerLocationMapScreen extends StatelessWidget {
  final OrderModel order;

  const CustomerLocationMapScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final lat = order.latitude!;
    final lng = order.longitude!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Lokasi Pelanggan — Order #${order.id}'),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(lat, lng),
          initialZoom: 15,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.jeepora.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(lat, lng),
                width: 70,
                height: 70,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_pin_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const Text('Pelanggan',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                          fontFamily: 'Poppins',
                        )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}