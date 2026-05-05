import 'package:flutter/material.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/models/analytics_model.dart';

class GrowthStatCard extends StatelessWidget {
  final AnalyticsSummaryModel summary;

  const GrowthStatCard({super.key, required this.summary});

  String _formatRupiah(double amount) => 'Rp ${amount
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    final isGrowthPositive = summary.growthRate >= 0;
    final growthColor =
        isGrowthPositive ? AppColors.statusCompleted : AppColors.error;
    final growthIcon = isGrowthPositive
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Month comparison
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bulan Ini',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        color: AppColors.textSecondary,
                      )),
                  const SizedBox(height: 4),
                  Text(_formatRupiah(summary.thisMonthRevenue),
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      )),
                  const SizedBox(height: 2),
                  Text('${summary.thisMonthOrders} pesanan',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'Poppins',
                        color: AppColors.textSecondary,
                      )),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Bulan Lalu',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        color: AppColors.textSecondary,
                      )),
                  const SizedBox(height: 4),
                  Text(_formatRupiah(summary.lastMonthRevenue),
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHint,
                      )),
                  const SizedBox(height: 2),
                  Text('${summary.lastMonthOrders} pesanan',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'Poppins',
                        color: AppColors.textSecondary,
                      )),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),

          // Growth indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: growthColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: growthColor.withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: growthColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(growthIcon, color: growthColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pertumbuhan Revenue',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            color: AppColors.textSecondary,
                          )),
                      const SizedBox(height: 2),
                      Text(
                          isGrowthPositive
                              ? '+${summary.growthRate.toStringAsFixed(1)}%'
                              : '${summary.growthRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            color: growthColor,
                          )),
                    ],
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