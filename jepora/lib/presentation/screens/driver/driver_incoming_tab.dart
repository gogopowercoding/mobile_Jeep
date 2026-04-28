import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/models.dart';
import '../../widgets/common/common_widgets.dart';

class DriverIncomingTab extends StatefulWidget {
  const DriverIncomingTab({super.key});

  @override
  State<DriverIncomingTab> createState() => _DriverIncomingTabState();
}

class _DriverIncomingTabState extends State<DriverIncomingTab> {
  List<OrderModel> _incoming = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchIncoming();
  }

  Future<void> _fetchIncoming() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient().dio.get('/orders/driver-incoming');
      if (res.data['success'] == true) {
        setState(() {
          _incoming = (res.data['data'] as List)
              .map((e) => OrderModel.fromJson(e))
              .toList();
        });
      }
    } catch (_) {} finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _respond(int orderId, String response, {String? note}) async {
    try {
      final res = await ApiClient().dio.post('/orders/respond', data: {
        'order_id': orderId,
        'response': response,
        if (note != null) 'note': note,
      });
      if (res.data['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response == 'accepted'
              ? '✅ Pesanan berhasil diterima!'
              : '❌ Pesanan ditolak'),
          backgroundColor: response == 'accepted'
              ? AppColors.success
              : AppColors.error,
        ));
        _fetchIncoming();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  void _showRejectDialog(int orderId) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tolak Pesanan', style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Yakin ingin menolak pesanan ini?',
                style: AppTextStyles.body),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                hintText: 'Alasan penolakan (opsional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _respond(orderId, 'rejected',
                  note: noteCtrl.text.trim().isEmpty
                      ? null
                      : noteCtrl.text.trim());
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pesanan Masuk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _fetchIncoming,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _incoming.isEmpty
              ? const EmptyState(
                  title: 'Tidak ada pesanan masuk',
                  subtitle: 'Pesanan baru dari admin akan muncul di sini',
                  icon: Icons.inbox_outlined,
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _fetchIncoming,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _incoming.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final order = _incoming[i];
                      return _IncomingOrderCard(
                        order: order,
                        onAccept: () => _respond(order.id, 'accepted'),
                        onReject: () => _showRejectDialog(order.id),
                      );
                    },
                  ),
                ),
    );
  }
}

// ─── INCOMING ORDER CARD ─────────────────────────────────────
class _IncomingOrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _IncomingOrderCard({
    required this.order,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.statusPending.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.statusPending.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.statusPending.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active_rounded,
                      color: AppColors.statusPending, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pesanan Baru #${order.id}',
                          style: AppTextStyles.label),
                      const Text('Menunggu konfirmasi Anda',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.statusPending,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Detail
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _DetailRow(icon: Icons.landscape_rounded,
                    label: 'Paket', value: order.packageName ?? '-'),
                const SizedBox(height: 8),
                _DetailRow(icon: Icons.calendar_today_rounded,
                    label: 'Tanggal', value: order.bookingDate),
                const SizedBox(height: 8),
                _DetailRow(
                  icon: Icons.payments_outlined,
                  label: 'Total',
                  value:
                      'Rp ${order.totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                ),
                if (order.latitude != null) ...[
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: Icons.location_on_rounded,
                    label: 'Lokasi',
                    value:
                        '${order.latitude!.toStringAsFixed(4)}, ${order.longitude!.toStringAsFixed(4)}',
                  ),
                ],
                if (order.notes != null && order.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _DetailRow(icon: Icons.notes_rounded,
                      label: 'Catatan', value: order.notes!),
                ],
              ],
            ),
          ),

          // Tombol
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.error, size: 18),
                    label: const Text('Tolak',
                        style: TextStyle(
                          color: AppColors.error,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        )),
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size(0, 46),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Terima Pesanan'),
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 46)),
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

// ─── DETAIL ROW ──────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        SizedBox(
            width: 64, child: Text(label, style: AppTextStyles.caption)),
        Expanded(child: Text(value, style: AppTextStyles.body)),
      ],
    );
  }
}