import 'package:flutter/material.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/models/analytics_model.dart';

class RevenueChartWidget extends StatelessWidget {
  final List<MonthlyRevenueModel> revenue;

  const RevenueChartWidget({super.key, required this.revenue});

  String _formatRupiah(double amount) => 'Rp ${amount
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    if (revenue.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxRevenue =
        revenue.map((r) => r.totalRevenue).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        children: [
          // ── Chart Bar ──────────────────────────────────
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: revenue.take(6).map((r) {
                final height = (r.totalRevenue / maxRevenue) * 150;
                final month = r.month.split('-')[1]; // MM dari YYYY-MM

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Tooltip
                      Tooltip(
                        message: _formatRupiah(r.totalRevenue),
                        child: Container(
                          width: 30,
                          height: height,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius:
                                const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bln $month',
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),

          // ── Detail Info ────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _InfoBox(
                  label: 'Total Orders',
                  value: revenue.fold<int>(
                      0, (sum, r) => sum + r.totalOrders).toString(),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoBox(
                  label: 'Total Revenue',
                  value: _formatRupiah(revenue.fold<double>(
                      0, (sum, r) => sum + r.totalRevenue)),
                  color: AppColors.statusCompleted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoBox(
                  label: 'Rata-rata Order',
                  value: _formatRupiah(revenue.fold<double>(
                          0, (sum, r) => sum + r.avgOrderValue) /
                      revenue.length),
                  color: AppColors.statusOngoing,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize: 10,
              fontFamily: 'Poppins',
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            )),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              color: color,
            )),
      ],
    );
  }
}