part of '../booking_tab.dart';

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
    final cached = _findOrderById(orders, id);
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
    final found = _findOrderById(context.read<OrderService>().orders, id);
    setState(() { _order = found; _isLoading = false; });
  }

  ///  Find order by ID
  OrderModel? _findOrderById(List<OrderModel> orders, int id) {
    try {
      return orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
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
