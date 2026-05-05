import 'package:flutter/material.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/models/analytics_model.dart';

class SeasonCardWidget extends StatelessWidget {
  final SeasonAnalysisModel season;

  const SeasonCardWidget({super.key, required this.season});

  Color _getSeasonColor() {
    switch (season.season) {
      case 'ramai':
        return const Color(0xFFFF6B6B); // Red
      case 'sepi':
        return const Color(0xFF4ECDC4); // Teal
      default:
        return AppColors.primary; // Primary
    }
  }

  String _getSeasonEmoji() {
    switch (season.season) {
      case 'ramai':
        return '🔥'; // Hot/Busy
      case 'sepi':
        return '❄️'; // Cold/Quiet
      default:
        return '📊'; // Normal
    }
  }

  String _getSeasonLabel() {
    switch (season.season) {
      case 'ramai':
        return 'MUSIM RAMAI';
      case 'sepi':
        return 'MUSIM SEPI';
      default:
        return 'NORMAL';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getSeasonColor();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          // Season indicator
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(_getSeasonEmoji(), style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(season.monthName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(_getSeasonLabel(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          )),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${season.totalOrders} Orders',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  )),
              const SizedBox(height: 2),
              Text(
                  'Rp ${season.totalRevenue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: color,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}