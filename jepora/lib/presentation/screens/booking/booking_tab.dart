import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_services.dart';
import '../../../data/models/models.dart';
import '../../widgets/common/common_widgets.dart';
import 'package:intl/intl.dart';

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
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: orders.orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final order = orders.orders[i];
                      return _OrderCard(order: order);
                    },
                  ),
                ),
    );
  }
}

// ─── ORDER CARD (dengan tombol Upload Bukti Bayar & Lacak Supir) ─────────
class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  /// Apakah status ini layak menampilkan tombol upload bukti bayar
  bool get _showUploadPayment =>
      order.status == 'pending' && order.paymentStatus != 'paid';

  /// Apakah status ini layak menampilkan tombol lacak supir
  bool get _showTrackDriver =>
      (order.status == 'confirmed' || order.status == 'ongoing') &&
      order.driverName != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/order-detail', arguments: order.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 42, height: 42,
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
                      Text(order.packageName ?? 'Paket Wisata',
                        style: AppTextStyles.label),
                      Text('Order #${order.id}',
                        style: AppTextStyles.caption),
                    ],
                  ),
                ),
                StatusBadge(status: order.status),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 12),

            // ── Info Row ──────────────────────────────────────
            Row(
              children: [
                _InfoItem(
                  icon: Icons.calendar_today_rounded,
                  label: 'Tanggal',
                  value: order.bookingDate,
                ),
                const SizedBox(width: 20),
                _InfoItem(
                  icon: Icons.payments_outlined,
                  label: 'Total',
                  value: 'Rp ${order.totalPrice.toStringAsFixed(0).replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                ),
              ],
            ),

            if (order.driverName != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.person_rounded, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text('Supir: ${order.driverName}', style: AppTextStyles.caption),
                ],
              ),
            ],

            // ── Action Buttons ────────────────────────────────
            if (_showUploadPayment || _showTrackDriver) ...[
              const SizedBox(height: 12),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  // Tombol Upload Bukti Bayar
                  if (_showUploadPayment)
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.upload_rounded,
                        label: 'Upload Bukti Bayar',
                        color: AppColors.primary,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/upload-payment',
                          arguments: order.id,
                        ),
                      ),
                    ),

                  if (_showUploadPayment && _showTrackDriver)
                    const SizedBox(width: 10),

                  // Tombol Lacak Supir
                  if (_showTrackDriver)
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.my_location_rounded,
                        label: 'Lacak Supir',
                        color: AppColors.statusOngoing,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/driver-tracking',
                          arguments: order.id,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Tombol Aksi Kecil ────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontFamily: 'Poppins',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Info Item ────────────────────────────────────────────────
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption),
            Text(value, style: AppTextStyles.label),
          ],
        ),
      ],
    );
  }
}

// ─── CREATE BOOKING SCREEN ────────────────────────────────────
class CreateBookingScreen extends StatefulWidget {
  const CreateBookingScreen({super.key});

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _notesCtrl  = TextEditingController();
  int? _selectedPkg;
  DateTime? _selectedDate;
  double? _lat, _lng;
  bool _gettingLocation = false;
  String? _selectedCurrency = 'IDR';
  double? _convertedPrice;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PackageService>().fetchPackages();
    });
  }

  Future<void> _getLocation() async {
    setState(() => _gettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Layanan lokasi tidak aktif');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Izin lokasi ditolak');
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() { _lat = pos.latitude; _lng = pos.longitude; });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _gettingLocation = false);
    }
  }

  Future<void> _convertCurrency(double price) async {
    if (_selectedCurrency == 'IDR') {
      setState(() => _convertedPrice = null);
      return;
    }
    final result = await CurrencyService.convert(
      amount: price, from: 'IDR', to: _selectedCurrency!,
    );
    if (result != null && mounted) {
      setState(() => _convertedPrice = result['converted']);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal booking'), backgroundColor: AppColors.error),
      );
      return;
    }

    final orderService = context.read<OrderService>();
    final order = await orderService.createOrder(
      packageId:   _selectedPkg!,
      bookingDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
      latitude:    _lat,
      longitude:   _lng,
      notes:       _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    if (!mounted) return;
    if (order != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan berhasil dibuat!'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(orderService.error ?? 'Gagal membuat pesanan'),
          backgroundColor: AppColors.error),
      );
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final packages     = context.watch<PackageService>();
    final orderService = context.watch<OrderService>();
    final selectedPkg  = _selectedPkg != null
        ? packages.packages.firstWhere((p) => p.id == _selectedPkg,
            orElse: () => packages.packages.first)
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Buat Booking')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih Paket Wisata', style: AppTextStyles.label),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider, width: 0.5),
                ),
                child: DropdownButtonFormField<int>(
                  value: _selectedPkg,
                  hint: const Text('Pilih paket', style: TextStyle(fontFamily: 'Poppins')),
                  decoration: const InputDecoration(border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16)),
                  items: packages.packages.map((p) => DropdownMenuItem(
                    value: p.id,
                    child: Text(p.name, style: AppTextStyles.body),
                  )).toList(),
                  onChanged: (v) {
                    setState(() { _selectedPkg = v; _convertedPrice = null; });
                    if (v != null) {
                      final pkg = packages.packages.firstWhere((p) => p.id == v);
                      _convertCurrency(pkg.price);
                    }
                  },
                  validator: (v) => v == null ? 'Pilih paket wisata' : null,
                ),
              ),

              if (selectedPkg != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Rp ${selectedPkg.price.toStringAsFixed(0).replaceAllMapped(
                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                              style: AppTextStyles.price),
                            if (_convertedPrice != null)
                              Text('≈ $_selectedCurrency ${_convertedPrice!.toStringAsFixed(2)}',
                                style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      DropdownButton<String>(
                        value: _selectedCurrency,
                        underline: const SizedBox(),
                        items: ['IDR', 'USD', 'EUR'].map((c) => DropdownMenuItem(
                          value: c, child: Text(c, style: AppTextStyles.label),
                        )).toList(),
                        onChanged: (v) {
                          setState(() => _selectedCurrency = v);
                          if (selectedPkg != null) _convertCurrency(selectedPkg.price);
                        },
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              const Text('Tanggal Booking', style: AppTextStyles.label),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(primary: AppColors.primary),
                      ),
                      child: child!,
                    ),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: AppColors.textHint, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate != null
                            ? DateFormat('EEEE, dd MMMM yyyy', 'id').format(_selectedDate!)
                            : 'Pilih tanggal',
                        style: _selectedDate != null ? AppTextStyles.body : AppTextStyles.bodyMuted,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text('Lokasi Penjemputan', style: AppTextStyles.label),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _getLocation,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _lat != null ? AppColors.primaryLight : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _lat != null ? AppColors.primary : AppColors.divider,
                      width: _lat != null ? 1.5 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      _gettingLocation
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                          : Icon(Icons.my_location_rounded,
                              color: _lat != null ? AppColors.primary : AppColors.textHint, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _lat != null
                              ? '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'
                              : 'Tap untuk ambil lokasi GPS',
                          style: _lat != null ? AppTextStyles.body : AppTextStyles.bodyMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text('Catatan (opsional)', style: AppTextStyles.label),
              const SizedBox(height: 8),
              AppTextField(
                hint: 'Contoh: Jemput di hotel jam 05.00',
                controller: _notesCtrl,
                maxLines: 3,
              ),

              const SizedBox(height: 28),
              PrimaryButton(
                text: 'Konfirmasi Booking',
                isLoading: orderService.isLoading,
                onPressed: _submit,
                icon: Icons.check_circle_outline_rounded,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}