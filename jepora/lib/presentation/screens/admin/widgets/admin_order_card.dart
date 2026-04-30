import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/models/models.dart';
import 'package:jepora/data/services/api_services.dart';
import 'package:jepora/presentation/widgets/common/common_widgets.dart';

class AdminOrderCard extends StatelessWidget {
  final OrderModel order;
  final bool showActions;

  const AdminOrderCard({
    super.key,
    required this.order,
    this.showActions = false,
  });

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
          // ─── Header: ID + Status ───────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id} — ${order.packageName ?? "-"}',
                      style: AppTextStyles.label,
                    ),
                    const SizedBox(height: 2),
                    Text(order.bookingDate, style: AppTextStyles.caption),
                  ],
                ),
              ),
              StatusBadge(status: order.status),
            ],
          ),

          // ─── Info ringkas pelanggan ────────────────────
          if (order.customerName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(order.customerName!, style: AppTextStyles.caption),
                if (order.customerPhone != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.phone_outlined, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(order.customerPhone!, style: AppTextStyles.caption),
                ],
              ],
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),

          // ─── Tombol aksi ──────────────────────────────
          Row(
            children: [
              // Tombol Detail (selalu tampil)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showDetailSheet(context),
                  icon: const Icon(Icons.info_outline, size: 15),
                  label: const Text('Detail'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              // Tombol Batalkan (hanya jika status pending / confirmed)
              if (showActions &&
                  (order.status == 'pending' || order.status == 'confirmed')) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmCancel(context),
                    icon: const Icon(Icons.cancel_outlined,
                        size: 15, color: AppColors.error),
                    label: const Text('Batalkan',
                        style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: const BorderSide(color: AppColors.error),
                      textStyle: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),

          // ─── Assign driver (hanya jika pending) ───────
          if (showActions && order.status == 'pending') ...[
            const SizedBox(height: 8),
            _AssignDriverButton(orderId: order.id),
          ],
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  // Bottom Sheet: Detail Pesanan
  // ────────────────────────────────────────────────
  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderDetailSheet(order: order),
    );
  }

  // ────────────────────────────────────────────────
  // Dialog konfirmasi pembatalan
  // ────────────────────────────────────────────────
  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Pesanan?',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text(
          'Pesanan #${order.id} dari ${order.customerName ?? "pelanggan"} akan dibatalkan. Tindakan ini tidak dapat diurungkan.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tidak',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await context
                  .read<OrderService>()
                  .updateStatus(order.id, 'cancelled');
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pesanan berhasil dibatalkan'),
                    backgroundColor: AppColors.error,
                  ),
                );
                context.read<OrderService>().fetchAllOrders();
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// Bottom Sheet: Detail lengkap pesanan
// ══════════════════════════════════════════════════
class _OrderDetailSheet extends StatefulWidget {
  final OrderModel order;
  const _OrderDetailSheet({required this.order});

  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  Map<String, dynamic>? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final svc = context.read<OrderService>();
      final data = await svc.getOrderDetail(widget.order.id);
      if (mounted) setState(() { _detail = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    tooltip: 'Kembali',
                  ),
                  Expanded(
                    child: Text('Detail Pesanan #${widget.order.id}',
                        style: AppTextStyles.h3),
                  ),
                  StatusBadge(status: widget.order.status),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.divider),

            // Content
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : _error != null
                      ? Center(
                          child: Text('Gagal memuat: $_error',
                              style: AppTextStyles.caption))
                      : ListView(
                          controller: ctrl,
                          padding: const EdgeInsets.all(16),
                          children: [
                            _SectionCard(
                              title: 'Informasi Paket',
                              icon: Icons.luggage_outlined,
                              children: [
                                _DetailRow('Nama Paket',
                                    _detail?['package_name'] ?? '-'),
                                _DetailRow('Deskripsi',
                                    _detail?['package_desc'] ?? '-'),
                                _DetailRow('Durasi',
                                    '${_detail?['duration'] ?? "-"} hari'),
                                _DetailRow('Tanggal',
                                    widget.order.bookingDate),
                                _DetailRow('Total Harga',
                                    'Rp ${_formatRupiah(widget.order.totalPrice)}'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _SectionCard(
                              title: 'Informasi Pelanggan',
                              icon: Icons.person_outline,
                              children: [
                                _DetailRow('Nama',
                                    _detail?['customer_name'] ?? '-'),
                                _DetailRow('No. HP',
                                    _detail?['customer_phone'] ?? '-'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _SectionCard(
                              title: 'Supir',
                              icon: Icons.drive_eta_outlined,
                              children: [
                                _DetailRow('Nama',
                                    _detail?['driver_name'] ?? 'Belum di-assign'),
                                _DetailRow('No. HP',
                                    _detail?['driver_phone'] ?? '-'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _SectionCard(
                              title: 'Pembayaran',
                              icon: Icons.payment_outlined,
                              children: [
                                _DetailRow('Status',
                                    _detail?['payment_status'] ?? '-'),
                                _DetailRow('Metode',
                                    _detail?['payment_method'] ?? '-'),
                                _DetailRow('Jumlah',
                                    'Rp ${_formatRupiah(double.tryParse(_detail?['payment_amount']?.toString() ?? '0') ?? 0)}'),
                                // ─── Bukti Pembayaran ───
                                if (_detail?['payment_proof'] != null) ...[
                                  const SizedBox(height: 10),
                                  const Text('Bukti Pembayaran',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary)),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => _showPaymentProof(context,
                                        _detail!['payment_proof']),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        _detail!['payment_proof'],
                                        height: 180,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Container(
                                          height: 80,
                                          color: AppColors.divider,
                                          child: const Center(
                                            child: Icon(
                                                Icons.broken_image_outlined,
                                                color:
                                                    AppColors.textSecondary),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('Ketuk gambar untuk memperbesar',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontFamily: 'Poppins',
                                          color: AppColors.textSecondary)),
                                ] else ...[
                                  const SizedBox(height: 8),
                                  const Row(
                                    children: [
                                      Icon(Icons.image_not_supported_outlined,
                                          size: 16,
                                          color: AppColors.textSecondary),
                                      SizedBox(width: 6),
                                      Text('Belum ada bukti pembayaran',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'Poppins',
                                              color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            if (widget.order.notes != null &&
                                widget.order.notes!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _SectionCard(
                                title: 'Catatan',
                                icon: Icons.notes_outlined,
                                children: [
                                  Text(widget.order.notes!,
                                      style: AppTextStyles.body),
                                ],
                              ),
                            ],
                            const SizedBox(height: 24),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentProof(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRupiah(double val) {
    final str = val.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}

// ══════════════════════════════════════════════════
// Widget Helpers
// ══════════════════════════════════════════════════
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard(
      {required this.title, required this.icon, required this.children});

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
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    color: AppColors.textSecondary)),
          ),
          const Text(': ',
              style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  color: AppColors.textSecondary)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// Assign Driver Button (tidak berubah dari semula)
// ══════════════════════════════════════════════════
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
        child: const Text('Muat daftar supir',
            style: TextStyle(color: AppColors.primary)),
      );
    }

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            value: _selectedDriver,
            hint: const Text('Pilih supir',
                style: TextStyle(fontSize: 13, fontFamily: 'Poppins')),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: drivers
                .map((d) => DropdownMenuItem(
                    value: d.id,
                    child: Text(d.name, style: AppTextStyles.body)))
                .toList(),
            onChanged: (v) => setState(() => _selectedDriver = v),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _selectedDriver == null
              ? null
              : () async {
                  final ok = await orderService.assignDriver(
                      widget.orderId, _selectedDriver!);
                  if (ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Supir berhasil di-assign ✅'),
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