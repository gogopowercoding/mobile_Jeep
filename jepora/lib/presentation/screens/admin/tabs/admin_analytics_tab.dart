import 'package:flutter/material.dart';
import 'package:jepora/presentation/screens/admin/widgets/forecast_card_widget.dart';
import 'package:jepora/presentation/screens/admin/widgets/revenue_chart_widget.dart';
import 'package:jepora/presentation/screens/admin/widgets/season_card_widget.dart';
import 'package:jepora/presentation/screens/admin/widgets/growth_stat_card.dart';
import 'package:provider/provider.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/services/analytics_service.dart';
import 'package:jepora/presentation/widgets/common/common_widgets.dart';


class AdminAnalyticsTab extends StatefulWidget {
  const AdminAnalyticsTab({super.key});

  @override
  State<AdminAnalyticsTab> createState() => _AdminAnalyticsTabState();
}

class _AdminAnalyticsTabState extends State<AdminAnalyticsTab> {
  @override
  void initState() {
    super.initState();
    print('🟢 INIT STATE DIPANGGIL'); 
    Future.delayed(Duration.zero, () {
      print('🟡 Future.delayed dipanggil'); 
      if (mounted) {
        print('🔵 mounted = true, akan fetch analytics');
        context.read<AnalyticsService>().fetchAllAnalytics();
      } else {
        print('🔴 mounted = false, tidak akan fetch analytics'); 
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Analytics & Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () => context.read<AnalyticsService>().fetchAllAnalytics(),
          ),
        ],
      ),
      body: analytics.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () =>
                  context.read<AnalyticsService>().fetchAllAnalytics(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Growth Summary ──────────────────────────────
                    const Text('Ringkasan Pertumbuhan', style: AppTextStyles.h3),
                    const SizedBox(height: 12),
                    if (analytics.summary != null)
                      GrowthStatCard(summary: analytics.summary!)
                    else
                      const SizedBox(height: 100),

                    const SizedBox(height: 24),

                    // ── Revenue Chart ──────────────────────────────
                    const Text('Revenue 12 Bulan Terakhir',
                        style: AppTextStyles.h3),
                    const SizedBox(height: 12),
                    if (analytics.monthlyRevenue.isNotEmpty)
                      RevenueChartWidget(
                          revenue: analytics.monthlyRevenue)
                    else
                      const EmptyState(
                        title: 'Belum ada data',
                        icon: Icons.trending_up_rounded,
                      ),

                    const SizedBox(height: 24),

                    // ── Season Analysis ────────────────────────────
                    const Text('Analisis Musim Ramai/Sepi',
                        style: AppTextStyles.h3),
                    const SizedBox(height: 12),
                    if (analytics.seasonAnalysis.isNotEmpty)
                      Column(
                        children: analytics.seasonAnalysis
                            .map((season) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: SeasonCardWidget(season: season),
                            ))
                            .toList(),
                      )
                    else
                      const EmptyState(
                        title: 'Belum ada data musiman',
                        icon: Icons.calendar_month_rounded,
                      ),

                    const SizedBox(height: 24),

                    // ── Forecast ───────────────────────────────────
                    const Text('Prediksi Revenue Bulan Depan',
                        style: AppTextStyles.h3),
                    const SizedBox(height: 12),
                    if (analytics.forecast != null)
                      ForecastCardWidget(forecast: analytics.forecast!)
                    else
                      const EmptyState(
                        title: 'Belum ada prediksi',
                        icon: Icons.trending_up_rounded,
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}