import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_services.dart';
import '../../../data/models/models.dart';
import '../../widgets/common/common_widgets.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    _AdminDashboardTab(),
    _AdminOrdersTab(),
    _AdminPackagesTab(),
    _AdminProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 16, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard',
                  isActive: _currentIndex == 0, onTap: () => setState(() => _currentIndex = 0)),
                _NavItem(icon: Icons.list_alt_rounded, label: 'Pesanan',
                  isActive: _currentIndex == 1, onTap: () => setState(() => _currentIndex = 1)),
                _NavItem(icon: Icons.landscape_rounded, label: 'Paket',
                  isActive: _currentIndex == 2, onTap: () => setState(() => _currentIndex = 2)),
                _NavItem(icon: Icons.person_rounded, label: 'Profil',
                  isActive: _currentIndex == 3, onTap: () => setState(() => _currentIndex = 3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── DASHBOARD TAB ───────────────────────────────────────────
class _AdminDashboardTab extends StatefulWidget {
  const _AdminDashboardTab();

  @override
  State<_AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<_AdminDashboardTab> {
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
                // Header
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

                // Stats grid
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
                    _StatCard(label: 'Menunggu', value: '$pending',
                      color: AppColors.statusPending, icon: Icons.hourglass_empty_rounded),
                    _StatCard(label: 'Dikonfirmasi', value: '$confirmed',
                      color: AppColors.statusConfirmed, icon: Icons.check_circle_outline_rounded),
                    _StatCard(label: 'Berjalan', value: '$ongoing',
                      color: AppColors.statusOngoing, icon: Icons.directions_car_rounded),
                    _StatCard(label: 'Selesai', value: '$completed',
                      color: AppColors.statusCompleted, icon: Icons.flag_rounded),
                  ],
                ),

                const SizedBox(height: 24),
                // Pesanan terbaru
                SectionHeader(
                  title: 'Pesanan Terbaru',
                  actionText: 'Lihat Semua',
                  onAction: () {},
                ),
                const SizedBox(height: 12),

                if (orders.isLoading)
                  const Center(child: CircularProgressIndicator(color: AppColors.primary))
                else if (orders.orders.isEmpty)
                  const EmptyState(title: 'Belum ada pesanan',
                    icon: Icons.inbox_outlined)
                else
                  ...orders.orders.take(5).map((order) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AdminOrderCard(order: order),
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── ORDERS TAB ──────────────────────────────────────────────
class _AdminOrdersTab extends StatefulWidget {
  const _AdminOrdersTab();

  @override
  State<_AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<_AdminOrdersTab> {
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
          // Filter chips
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
                          s == 'all' ? 'Semua'
                            : s == 'pending' ? 'Menunggu'
                            : s == 'confirmed' ? 'Dikonfirmasi'
                            : s == 'ongoing' ? 'Berjalan'
                            : s == 'completed' ? 'Selesai' : 'Dibatalkan',
                          style: TextStyle(
                            fontSize: 12, fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            color: _filterStatus == s ? AppColors.textOnPrimary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  )).toList(),
            ),
          ),

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
                          itemBuilder: (ctx, i) => _AdminOrderCard(
                            order: filtered[i], showActions: true),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── PACKAGES TAB ────────────────────────────────────────────
class _AdminPackagesTab extends StatefulWidget {
  const _AdminPackagesTab();

  @override
  State<_AdminPackagesTab> createState() => _AdminPackagesTabState();
}

class _AdminPackagesTabState extends State<_AdminPackagesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PackageService>().fetchPackages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final packages = context.watch<PackageService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paket Wisata'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            onPressed: () {}, // TODO: add package screen
          ),
        ],
      ),
      body: packages.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : packages.packages.isEmpty
              ? const EmptyState(title: 'Belum ada paket', icon: Icons.landscape_outlined)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: packages.packages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final pkg = packages.packages[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 54, height: 54,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.landscape_rounded,
                              color: AppColors.primary, size: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(pkg.name, style: AppTextStyles.label),
                                Text('Rp ${pkg.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                                  style: AppTextStyles.price),
                                Text('${pkg.duration} jam', style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                  color: AppColors.info, size: 20),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                  color: AppColors.error, size: 20),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

// ─── PROFILE TAB ─────────────────────────────────────────────
class _AdminProfileTab extends StatelessWidget {
  const _AdminProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profil Admin')),
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
                    auth.user?.name.substring(0, 1).toUpperCase() ?? 'A',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700,
                      color: Colors.white, fontFamily: 'Poppins'),
                  ),
                ),
                const SizedBox(height: 10),
                Text(auth.user?.name ?? '-', style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: Colors.white, fontFamily: 'Poppins')),
                const SizedBox(height: 4),
                const Text('👑 Administrator', style: TextStyle(
                  color: Colors.white70, fontFamily: 'Poppins', fontSize: 13)),
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

// ─── ADMIN ORDER CARD ────────────────────────────────────────
class _AdminOrderCard extends StatelessWidget {
  final OrderModel order;
  final bool showActions;
  const _AdminOrderCard({required this.order, this.showActions = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #${order.id} — ${order.packageName ?? "-"}',
                      style: AppTextStyles.label),
                    Text(order.bookingDate, style: AppTextStyles.caption),
                  ],
                ),
              ),
              StatusBadge(status: order.status),
            ],
          ),
          if (showActions && order.status == 'pending') ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 10),
            _AssignDriverButton(orderId: order.id),
          ],
        ],
      ),
    );
  }
}

class _AssignDriverButton extends StatefulWidget {
  final int orderId;
  const _AssignDriverButton({required this.orderId});

  @override
  State<_AssignDriverButton> createState() => _AssignDriverButtonState();
}

class _AssignDriverButtonState extends State<_AssignDriverButton> {
  int? _selectedDriver;

  @override
  Widget build(BuildContext context) {
    final orderService = context.watch<OrderService>();
    final drivers = orderService.drivers;

    if (drivers.isEmpty) {
      return TextButton(
        onPressed: () => orderService.fetchDrivers(),
        child: const Text('Muat daftar supir', style: TextStyle(color: AppColors.primary)),
      );
    }

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            value: _selectedDriver,
            hint: const Text('Pilih supir', style: TextStyle(fontSize: 13, fontFamily: 'Poppins')),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: drivers.map((d) => DropdownMenuItem(
              value: d.id,
              child: Text(d.name, style: AppTextStyles.body),
            )).toList(),
            onChanged: (v) => setState(() => _selectedDriver = v),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _selectedDriver == null ? null : () async {
            final ok = await orderService.assignDriver(widget.orderId, _selectedDriver!);
            if (ok && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Supir berhasil di-assign ✅'),
                  backgroundColor: AppColors.success),
              );
              orderService.fetchAllOrders();
            }
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(80, 42),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: const Text('Assign'),
        ),
      ],
    );
  }
}

// ─── SHARED WIDGETS ──────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
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
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                color: color, fontFamily: 'Poppins')),
              Text(label, style: AppTextStyles.caption),
            ],
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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