import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:jepora/data/services/auth_service.dart';
import 'package:jepora/data/services/api_services.dart';
import 'package:jepora/data/models/models.dart';
import 'package:jepora/presentation/widgets/common/common_widgets.dart';

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

// ─── ORDER CARD (dengan tombol Upload Bukti Bayar & Lacak Supir) ─────────
class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  /// Apakah status ini layak menampilkan tombol upload bukti bayar
  /// Sembunyikan jika sudah upload (waiting_confirmation) atau sudah lunas (paid)
  bool get _showUploadPayment =>
      order.status == 'pending' &&
      order.paymentStatus != 'paid' &&
      order.paymentStatus != 'waiting_confirmation';

  /// Bisa cancel jika status masih pending, belum upload bukti, dan belum paid
  bool get _canCancel =>
      order.status == 'pending' &&
      order.paymentStatus != 'paid' &&
      order.paymentStatus != 'waiting_confirmation';

  Future<void> _cancelOrder(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Batalkan Pesanan?',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        content: const Text('Pesanan yang dibatalkan tidak dapat dikembalikan.',
          style: TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak',
              style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Batalkan',
              style: TextStyle(fontFamily: 'Poppins',
                  color: AppColors.error, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      try {
        final res = await ApiClient().dio.post('/orders/update-status',
            data: {'order_id': order.id, 'status': 'cancelled'});
        if (!context.mounted) return;
        if (res.data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pesanan berhasil dibatalkan'),
                backgroundColor: AppColors.error));
          context.read<OrderService>().fetchOrders(
              context.read<AuthService>().user!.id);
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal membatalkan pesanan')));
        }
      }
    }
  }

  /// Apakah status ini layak menampilkan tombol lacak supir
  bool get _showTrackDriver =>
      (order.status == 'confirmed' || order.status == 'ongoing') &&
      order.driverName != null;

  String _formatDate(String raw) {
    try {
      return DateFormat('dd MMM yyyy', 'id').format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return raw;
    }
  }

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
                  value: _formatDate(order.bookingDate),
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
            if (_showUploadPayment || _showTrackDriver || _canCancel) ...[
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
                          arguments: order,
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
              // Tombol Cancel
              if (_canCancel) ...[
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _cancelOrder(context),
                    icon: const Icon(Icons.cancel_outlined,
                        size: 16, color: AppColors.error),
                    label: const Text('Batalkan Pesanan',
                      style: TextStyle(
                        fontFamily: 'Poppins', fontSize: 13,
                        color: AppColors.error, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
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
  bool _isConvertingCurrency = false;
  bool _currencyExpanded = false;

  // Voucher state
  final _voucherCtrl     = TextEditingController();
  Map<String, dynamic>? _appliedVoucher;
  double?               _discountAmount;
  bool                  _voucherLoading = false;
  String?               _voucherError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<PackageService>().fetchPackages();
      // Setelah packages load, trigger konversi jika ada paket pre-selected
      if (_selectedPkg != null && _selectedCurrency != 'IDR' && mounted) {
        final pkg = context.read<PackageService>().packages
            .where((p) => p.id == _selectedPkg)
            .firstOrNull;
        if (pkg != null) _convertCurrency(pkg.price, _selectedCurrency!);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg != null && _selectedPkg == null) {
      setState(() => _selectedPkg = arg as int);
    }
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

  Future<void> _convertCurrency(double price, String currency) async {
    if (currency == 'IDR') {
      setState(() => _convertedPrice = null);
      return;
    }
    setState(() => _isConvertingCurrency = true);
    final result = await CurrencyService.convert(
      amount: price, from: 'IDR', to: currency,
    );
    if (mounted) {
      setState(() {
        _convertedPrice = result != null ? (result['converted'] as num?)?.toDouble() : null;
        _isConvertingCurrency = false;
      });
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
      voucherId:   _appliedVoucher != null ? (_appliedVoucher!['id'] as int?) : null,
    );

    if (!mounted) return;
    if (order != null) {
      // Langsung ke halaman upload bukti bayar
      Navigator.pushReplacementNamed(
        context,
        '/upload-payment',
        arguments: order,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(orderService.error ?? 'Gagal membuat pesanan'),
          backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _applyVoucher(double price) async {
    final code = _voucherCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() { _voucherLoading = true; _voucherError = null; _appliedVoucher = null; _discountAmount = null; });
    try {
      final res = await ApiClient().dio.get('/vouchers/validate', queryParameters: {'code': code});
      if (res.data['success'] == true) {
        final v = res.data['voucher'] as Map<String, dynamic>;
        // MySQL decimal dikembalikan sebagai String di Node.js — parse manual
        double? parseNum(dynamic val) => val == null ? null : double.tryParse(val.toString());

        final minOrder = parseNum(v['min_order']);
        if (minOrder != null && price < minOrder) {
          final fmt = minOrder.toStringAsFixed(0).replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => m[1]! + '.');
          setState(() => _voucherError = 'Minimal order Rp $fmt');
          return;
        }
        double disc;
        if (v['type'] == 'percent') {
          disc = price * (parseNum(v['value']) ?? 0) / 100;
          final mx = parseNum(v['max_discount']);
          if (mx != null && disc > mx) disc = mx;
        } else {
          disc = parseNum(v['value']) ?? 0;
        }
        if (disc > price) disc = price;
        setState(() { _appliedVoucher = v; _discountAmount = disc; });
      } else {
        setState(() => _voucherError = res.data['message'] ?? 'Voucher tidak valid');
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final msg    = e.response?.data?['message'];
      if (status == 401) {
        setState(() => _voucherError = 'Sesi habis, silakan login ulang');
      } else if (status == 404) {
        setState(() => _voucherError = msg ?? 'Voucher tidak valid atau sudah kadaluarsa');
      } else {
        setState(() => _voucherError = msg ?? 'Gagal menghubungi server (${status ?? 'no connection'})');
      }
    } catch (e) {
      setState(() => _voucherError = 'Error: $e');
    } finally {
      if (mounted) setState(() => _voucherLoading = false);
    }
  }

  void _removeVoucher() => setState(() {
    _appliedVoucher = null; _discountAmount = null;
    _voucherError = null; _voucherCtrl.clear();
  });

  @override
  void dispose() {
    _notesCtrl.dispose();
    _voucherCtrl.dispose();
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
              const Text('Paket Wisata', style: AppTextStyles.label),
              const SizedBox(height: 8),
              // Jika paket sudah dipilih (dari halaman detail), tampilkan fixed — tidak bisa diganti
              if (_selectedPkg != null && selectedPkg != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          selectedPkg.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Jika belum ada paket dipilih (masuk manual), tampilkan dropdown
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider, width: 0.5),
                  ),
                  child: DropdownButtonFormField<int>(
                    value: _selectedPkg,
                    hint: const Text('Pilih paket', style: TextStyle(fontFamily: 'Poppins')),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    items: packages.packages.map((p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.name, style: AppTextStyles.body),
                    )).toList(),
                    onChanged: (v) {
                      setState(() { _selectedPkg = v; _convertedPrice = null; });
                      if (v != null && _selectedCurrency != null) {
                        final pkg = packages.packages.firstWhere((p) => p.id == v);
                        _convertCurrency(pkg.price, _selectedCurrency!);
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rp ${selectedPkg.price.toStringAsFixed(0).replaceAllMapped(
                                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                                  style: AppTextStyles.price,
                                ),
                                const SizedBox(height: 2),
                                if (_isConvertingCurrency)
                                  const SizedBox(
                                    height: 14,
                                    width: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: AppColors.primary,
                                    ),
                                  )
                                else if (_convertedPrice != null && _selectedCurrency != 'IDR')
                                  Text(
                                    '≈ $_selectedCurrency ${_convertedPrice!.toStringAsFixed(2)}',
                                    style: AppTextStyles.caption,
                                  ),
                              ],
                            ),
                          ),
                          // Tombol pilih mata uang
                          GestureDetector(
                            onTap: () => setState(() => _currencyExpanded = !_currencyExpanded),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.currency_exchange_rounded,
                                      size: 13, color: AppColors.primary),
                                  const SizedBox(width: 5),
                                  Text(
                                    _selectedCurrency ?? 'IDR',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Poppins',
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Icon(
                                    _currencyExpanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Panel pilih mata uang
                      if (_currencyExpanded) ...[
                        const SizedBox(height: 10),
                        const Divider(color: AppColors.divider, height: 1),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: ['IDR', 'USD', 'EUR'].map((c) {
                            final isActive = c == (_selectedCurrency ?? 'IDR');
                            return GestureDetector(
                              onTap: () {
                                final currency = c;
                                setState(() {
                                  _selectedCurrency = currency;
                                  _currencyExpanded = false;
                                  _convertedPrice = null;
                                });
                                _convertCurrency(selectedPkg.price, currency);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isActive ? AppColors.primary : AppColors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isActive ? AppColors.primary : AppColors.divider,
                                  ),
                                ),
                                child: Text(
                                  c,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Poppins',
                                    color: isActive ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
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

              const SizedBox(height: 20),

              // ── Voucher ─────────────────────────────────
              const Text('Kode Voucher (opsional)', style: AppTextStyles.label),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _voucherCtrl,
                      enabled: _appliedVoucher == null,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(fontSize: 14, fontFamily: 'Poppins',
                          color: AppColors.textPrimary, letterSpacing: 1.2),
                      decoration: InputDecoration(
                        hintText: 'Masukkan kode voucher',
                        hintStyle: const TextStyle(fontSize: 13, fontFamily: 'Poppins',
                            color: AppColors.textHint, letterSpacing: 0),
                        filled: true,
                        fillColor: _appliedVoucher == null ? AppColors.surface : AppColors.primaryLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.divider)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.divider)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primary.withOpacity(0.4))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 80,
                    height: 52,
                    child: _appliedVoucher == null
                        ? ElevatedButton(
                            onPressed: _voucherLoading ? null : () {
                              final pkg = context.read<PackageService>().packages
                                  .where((p) => p.id == _selectedPkg).firstOrNull;
                              if (pkg != null) _applyVoucher(pkg.price);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: EdgeInsets.zero,
                            ),
                            child: _voucherLoading
                                ? const SizedBox(width: 16, height: 16,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text('Pakai',
                                    style: TextStyle(fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13, color: Colors.white)),
                          )
                        : ElevatedButton(
                            onPressed: _removeVoucher,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error.withOpacity(0.1),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                      color: AppColors.error.withOpacity(0.4))),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text('Hapus',
                                style: TextStyle(fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13, color: AppColors.error)),
                          ),
                  ),
                ],
              ),

              if (_voucherError != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.error),
                  const SizedBox(width: 6),
                  Expanded(child: Text(_voucherError!, style: const TextStyle(
                      fontSize: 12, fontFamily: 'Poppins', color: AppColors.error))),
                ]),
              ],

              if (_appliedVoucher != null && _discountAmount != null) ...[
                const SizedBox(height: 10),
                Builder(builder: (ctx) {
                  final pkg = context.read<PackageService>().packages
                      .where((p) => p.id == _selectedPkg).firstOrNull;
                  if (pkg == null) return const SizedBox.shrink();
                  final fmt = (double v) => 'Rp ' + v.toStringAsFixed(0)
                      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => m[1]! + '.');
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                    ),
                    child: Column(children: [
                      Row(children: [
                        const Icon(Icons.local_offer_rounded, size: 15, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_appliedVoucher!['description'] ?? _appliedVoucher!['code'],
                          style: const TextStyle(fontSize: 12, fontFamily: 'Poppins',
                              color: AppColors.primary, fontWeight: FontWeight.w600))),
                      ]),
                      const Divider(height: 14, color: AppColors.divider),
                      _VoucherRow(label: 'Harga Paket', value: fmt(pkg.price)),
                      _VoucherRow(label: 'Diskon', value: '- ' + fmt(_discountAmount!), valueColor: AppColors.error),
                      const Divider(height: 10, color: AppColors.divider),
                      _VoucherRow(label: 'Total', value: fmt(pkg.price - _discountAmount!), bold: true),
                    ]),
                  );
                }),
              ],

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
// ─── ORDER DETAIL SCREEN ──────────────────────────────────────
/// Route: '/order-detail', arguments: int orderId
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  OrderModel? _order;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = ModalRoute.of(context)?.settings.arguments as int?;
    if (id != null) _load(id);
  }

  Future<void> _load(int id) async {
    setState(() => _isLoading = true);
    final orders = context.read<OrderService>().orders;
    // Cari dari cache dulu
    final cached = orders.where((o) => o.id == id).firstOrNull;
    if (cached != null) {
      setState(() { _order = cached; _isLoading = false; });
      return;
    }
    // Fallback: re-fetch semua pesanan
    final auth = context.read<AuthService>();
    if (auth.user != null) {
      await context.read<OrderService>().fetchOrders(auth.user!.id);
    }
    if (!mounted) return;
    final found = context.read<OrderService>().orders.where((o) => o.id == id).firstOrNull;
    setState(() { _order = found; _isLoading = false; });
  }

  String _formatDate(String raw) {
    try {
      return DateFormat('EEEE, dd MMMM yyyy', 'id').format(DateTime.parse(raw).toLocal());
    } catch (_) { return raw; }
  }

  String _formatPrice(double p) =>
      'Rp ${p.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _order == null
              ? const Center(child: Text('Pesanan tidak ditemukan'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final o = _order!;
    // Sembunyikan tombol upload & cancel jika sudah upload bukti (waiting_confirmation) atau lunas (paid)
    final showUpload = o.status == 'pending' &&
        o.paymentStatus != 'paid' &&
        o.paymentStatus != 'waiting_confirmation';
    final showTrack  = (o.status == 'confirmed' || o.status == 'ongoing') && o.driverName != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header status ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_car_rounded,
                      color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.packageName ?? 'Paket Wisata',
                          style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins', color: AppColors.textPrimary,
                          )),
                      const SizedBox(height: 2),
                      Text('Order #${o.id}', style: AppTextStyles.caption),
                    ],
                  ),
                ),
                StatusBadge(status: o.status),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Info ──────────────────────────────────────────
          _DetailSection(title: 'Informasi Booking', items: [
            _DetailItem(icon: Icons.calendar_today_rounded, label: 'Tanggal Booking', value: _formatDate(o.bookingDate)),
            _DetailItem(icon: Icons.payments_outlined,      label: 'Total Harga',     value: _formatPrice(o.totalPrice)),
            _DetailItem(icon: Icons.credit_card_rounded,    label: 'Status Bayar',    value: _paymentLabel(o.paymentStatus)),
            if (o.notes != null && o.notes!.isNotEmpty)
              _DetailItem(icon: Icons.notes_rounded, label: 'Catatan', value: o.notes!),
          ]),

          if (o.driverName != null) ...[
            const SizedBox(height: 16),
            _DetailSection(title: 'Info Supir', items: [
              _DetailItem(icon: Icons.person_rounded,  label: 'Nama Supir',  value: o.driverName!),
              if (o.driverPhone != null)
                _DetailItem(icon: Icons.phone_rounded, label: 'Telepon',     value: o.driverPhone!),
            ]),
          ],

          const SizedBox(height: 24),

          // ── Tombol aksi ───────────────────────────────────
          if (showUpload)
            PrimaryButton(
              text: 'Upload Bukti Pembayaran',
              icon: Icons.upload_rounded,
              onPressed: () => Navigator.pushNamed(
                context, '/upload-payment', arguments: o,
              ),
            ),

          if (showTrack) ...[
            if (showUpload) const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(
                context, '/driver-tracking', arguments: o.id,
              ),
              icon: const Icon(Icons.my_location_rounded, size: 18),
              label: const Text('Lacak Supir'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],

          // Tombol Cancel — hanya jika status pending, belum upload bukti, dan belum paid
          if (o.status == 'pending' &&
              o.paymentStatus != 'paid' &&
              o.paymentStatus != 'waiting_confirmation') ...[ 
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _confirmCancelFromDetail(context, o),
              icon: const Icon(Icons.cancel_outlined,
                  size: 18, color: AppColors.error),
              label: const Text('Batalkan Pesanan',
                style: TextStyle(fontFamily: 'Poppins',
                    color: AppColors.error, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _paymentLabel(String? status) {
    switch (status) {
      case 'paid':                  return 'Lunas ✓';
      case 'pending':               return 'Menunggu Pembayaran';
      case 'waiting_confirmation':  return 'Bukti Dikirim, Menunggu Konfirmasi Admin ⏳';
      default:                      return status ?? '-';
    }
  }

  Future<void> _confirmCancelFromDetail(
      BuildContext context, OrderModel o) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Batalkan Pesanan?',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        content: const Text('Pesanan yang dibatalkan tidak dapat dikembalikan.',
          style: TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak',
              style: TextStyle(fontFamily: 'Poppins',
                  color: AppColors.textSecondary))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Batalkan',
              style: TextStyle(fontFamily: 'Poppins',
                  color: AppColors.error, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      try {
        final res = await ApiClient().dio.post('/orders/update-status',
            data: {'order_id': o.id, 'status': 'cancelled'});
        if (!context.mounted) return;
        if (res.data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pesanan berhasil dibatalkan'),
                backgroundColor: AppColors.error));
          Navigator.pop(context);
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal membatalkan pesanan')));
        }
      }
    }
  }
}

// ── Detail Section ──────────────────────────────────────────
class _DetailSection extends StatelessWidget {
  final String title;
  final List<_DetailItem> items;
  const _DetailSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700,
            fontFamily: 'Poppins', color: AppColors.textPrimary,
          )),
          const SizedBox(height: 12),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(value, style: AppTextStyles.label),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Voucher Row ──────────────────────────────────────────────
class _VoucherRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;
  const _VoucherRow({required this.label, required this.value,
      this.valueColor, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontFamily: 'Poppins',
              color: bold ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 12, fontFamily: 'Poppins',
              color: valueColor ?? (bold ? AppColors.primary : AppColors.textPrimary),
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600)),
        ],
      ),
    );
  }
}