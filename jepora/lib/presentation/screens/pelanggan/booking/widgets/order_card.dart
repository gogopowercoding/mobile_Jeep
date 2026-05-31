part of '../booking_tab.dart';

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
          await LocalNotificationService().cancelBookingReminder(order.id);
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
