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

// ─── Assign Driver Button ─────────────────────────────────────
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
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
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