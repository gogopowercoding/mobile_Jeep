import 'package:flutter/material.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/models/analytics_model.dart';

class ForecastCardWidget extends StatelessWidget {
  final ForecastModel forecast;

  const ForecastCardWidget({super.key, required this.forecast});

  String _formatRupiah(double amount) => 'Rp ${amount
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.75) return AppColors.statusCompleted;
    if (confidence >= 0.5) return Colors.orange;
    return AppColors.error;
  }

  String _getConfidenceLabel(double confidence) {
    if (confidence >= 0.75) return 'Tinggi';
    if (confidence >= 0.5) return 'Sedang';
    return 'Rendah';
  }

  @override
  Widget build(BuildContext context) {
    final isTrendUp = forecast.trend == 'naik';
    final trendColor = isTrendUp ? AppColors.statusCompleted : AppColors.error;
    final trendIcon = isTrendUp ? Icons.trending_up_rounded : Icons.trending_down_rounded;
    final confidenceColor = _getConfidenceColor(forecast.confidence);
    final confidenceLabel = _getConfidenceLabel(forecast.confidence);
    final hasLowConfidence = forecast.confidence < 0.5;

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
          // HEADER SECTION
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.trending_up_rounded,
                    color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Prediksi Revenue',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        )),
                    const SizedBox(height: 2),
                    Text('Bulan Depan',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          color: AppColors.textSecondary.withOpacity(0.7),
                        )),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(trendIcon, color: trendColor, size: 20),
                  Text(isTrendUp ? 'Naik' : 'Turun',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        color: trendColor,
                      )),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),

          // WARNING SECTION (jika confidence rendah)
          if (hasLowConfidence) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.error.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_rounded,
                      color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Data belum cukup untuk prediksi akurat',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'Poppins',
                        color: AppColors.error,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // FORECAST VALUE & CONFIDENCE SECTION
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Estimasi Revenue',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          color: AppColors.textSecondary,
                        )),
                    const SizedBox(height: 4),
                    Text(_formatRupiah(forecast.nextMonthForecast),
                        style: const TextStyle(
                          fontSize: 20,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        )),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: confidenceColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: confidenceColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Confidence',
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'Poppins',
                          color: AppColors.textSecondary,
                        )),
                    const SizedBox(height: 4),
                    Text('${(forecast.confidence * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          color: confidenceColor,
                        )),
                    const SizedBox(height: 2),
                    Text(confidenceLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontFamily: 'Poppins',
                          color: confidenceColor.withOpacity(0.8),
                        )),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // CONFIDENCE PROGRESS BAR
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: forecast.confidence,
              minHeight: 6,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(confidenceColor),
            ),
          ),

          const SizedBox(height: 14),

          // BASELINE AVERAGE SECTION
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rata-rata Baseline',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'Poppins',
                          color: AppColors.textSecondary.withOpacity(0.7),
                        )),
                    const SizedBox(height: 2),
                    Text(_formatRupiah(forecast.nextMonthForecast),
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        )),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isTrendUp
                        ? AppColors.statusCompleted.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isTrendUp
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 12,
                        color: trendColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isTrendUp ? 'Meningkat' : 'Menurun',
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          color: trendColor,
                        ),
                      ),
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