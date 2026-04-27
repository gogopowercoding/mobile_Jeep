import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_services.dart';
import '../../../data/models/models.dart';
import '../../widgets/common/common_widgets.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    _DriverOrdersTab(),
    _DriverProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
            blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.directions_car_rounded, label: 'Pesanan',
                  isActive: _currentIndex == 0, onTap: () => setState(() => _currentIndex = 0)),
                _NavItem(icon: Icons.person_rounded, label: 'Profil',
                  isActive: _currentIndex == 1, onTap: () => setState(() => _currentIndex = 1)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── DRIVER ORDERS TAB ───────────────────────────────────────
class _DriverOrdersTab extends StatefulWidget {
  const _DriverOrdersTab();

  @override
  State<_DriverOrdersTab> createState() => _DriverOrdersTabState();
}

class _DriverOrdersTabState extends State<_DriverOrdersTab> {
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

    // Filter hanya pesanan yang di-assign ke supir ini
    final myOrders = orders.orders
        .where((o) => o.status == 'confirmed' || o.status == 'ongoing')
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pesanan Saya'),
            Text('Supir: ${auth.user?.name ?? "-"}',
              style: AppTextStyles.caption),
          ],
        ),
      ),
      body: orders.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : myOrders.isEmpty
              ? const EmptyState(
                  title: 'Belum ada pesanan',
                  subtitle: 'Pesanan yang di-assign admin akan muncul di sini',
                  icon: Icons.directions_car_outlined,
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => orders.fetchOrders(auth.user!.id),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: myOrders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) => _DriverOrderCard(order: myOrders[i]),
                  ),
                ),
    );
  }
}

// ─── DRIVER ORDER CARD ───────────────────────────────────────
class _DriverOrderCard extends StatelessWidget {
  final OrderModel order;
  const _DriverOrderCard({required this.order});

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
                      child: const Icon(Icons.person_rounded,
                        color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order #${order.id}', style: AppTextStyles.label),
                          Text(order.packageName ?? 'Paket Wisata',
                            style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    StatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 12),

                // Info
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                      size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(order.bookingDate, style: AppTextStyles.caption),
                    const SizedBox(width: 16),
                    const Icon(Icons.payments_outlined,
                      size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text('Rp ${order.totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                      style: AppTextStyles.caption),
                  ],
                ),

                // Lokasi pelanggan
                if (order.latitude != null && order.longitude != null) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => _CustomerLocationMap(order: order))),
                    child: Container(
                      padding: const EdgeInsets.all(10),
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
                              style: const TextStyle(fontSize: 12,
                                color: AppColors.primaryDark, fontFamily: 'Poppins'),
                            ),
                          ),
                          const Text('Lihat Peta',
                            style: TextStyle(fontSize: 12, color: AppColors.primary,
                              fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action buttons
          if (order.status == 'confirmed' || order.status == 'ongoing')
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  if (order.status == 'confirmed')
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.directions_car_rounded, size: 16),
                        label: const Text('Mulai Perjalanan'),
                        onPressed: () => _updateStatus(context, order.id, 'ongoing'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 42)),
                      ),
                    ),
                  if (order.status == 'ongoing')
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.flag_rounded, size: 16),
                        label: const Text('Selesai'),
                        onPressed: () => _updateStatus(context, order.id, 'completed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.statusCompleted,
                          minimumSize: const Size(0, 42)),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, int orderId, String status) async {
    final orderService = context.read<OrderService>();
    final auth = context.read<AuthService>();
    final ok = await orderService.updateStatus(orderId, status);
    if (ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'ongoing'
            ? '🚙 Perjalanan dimulai!'
            : '🏁 Perjalanan selesai!'),
          backgroundColor: AppColors.success,
        ),
      );
      orderService.fetchOrders(auth.user!.id);
    }
  }
}

// ─── CUSTOMER LOCATION MAP ───────────────────────────────────
class _CustomerLocationMap extends StatelessWidget {
  final OrderModel order;
  const _CustomerLocationMap({required this.order});

  @override
  Widget build(BuildContext context) {
    final lat = order.latitude!;
    final lng = order.longitude!;

    return Scaffold(
      appBar: AppBar(title: Text('Lokasi Order #${order.id}')),
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
                width: 60, height: 60,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_pin_rounded,
                        color: Colors.white, size: 24),
                    ),
                    const Text('Pelanggan',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                        color: AppColors.primary, fontFamily: 'Poppins')),
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

// ─── DRIVER PROFILE TAB ──────────────────────────────────────
class _DriverProfileTab extends StatelessWidget {
  const _DriverProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profil Supir')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B8A4C), Color(0xFF39E07A)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white24,
                  child: Text(
                    auth.user?.name.substring(0, 1).toUpperCase() ?? 'S',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700,
                      color: Colors.white, fontFamily: 'Poppins'),
                  ),
                ),
                const SizedBox(height: 10),
                Text(auth.user?.name ?? '-',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                    color: Colors.white, fontFamily: 'Poppins')),
                const SizedBox(height: 4),
                const Text('🚙 Supir JeepOra',
                  style: TextStyle(color: Colors.white70, fontFamily: 'Poppins', fontSize: 13)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                  title: const Text('Edit Profil', style: AppTextStyles.body),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                  onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: AppColors.surface,
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                  title: const Text('Keluar', style: TextStyle(color: AppColors.error,
                    fontFamily: 'Poppins', fontSize: 14)),
                  onTap: () async {
                    await auth.logout();
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: AppColors.surface,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label,
    required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22,
              color: isActive ? AppColors.primary : AppColors.textHint),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(
              fontSize: 11, fontFamily: 'Poppins',
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppColors.primary : AppColors.textHint,
            )),
          ],
        ),
      ),
    );
  }
}