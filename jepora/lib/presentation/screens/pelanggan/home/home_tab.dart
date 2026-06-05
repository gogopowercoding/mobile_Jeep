import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/services/auth_service.dart';
import 'package:jepora/data/services/api_services.dart';
import 'package:jepora/data/services/package_recommendation_service.dart';
import 'package:jepora/data/models/package_model.dart';
import 'package:jepora/core/constants/app_constants.dart';
import 'package:jepora/data/controllers/notification_controller.dart';
import 'package:jepora/presentation/widgets/common/common_widgets.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _searchCtrl = TextEditingController();
  String _selectedInterest = 'sunrise';
  double _recommendationBudget = 500000;
  double _recommendationDuration = 6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PackageService>().fetchPackages();
      Get.find<NotificationController>().fetchNotifications();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthService>();
    final packages = context.watch<PackageService>();
    final notifs = Get.find<NotificationController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => context.read<PackageService>().fetchPackages(),
          child: CustomScrollView(
            slivers: [
              // ── AppBar ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('JeepOra',
                              style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w700,
                                color: AppColors.primary, fontFamily: 'TacOne',
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ── Notif icon dengan GetX ────────────────
                      Obx(() {
                        final unread = notifs.unreadCount;
                        return Stack(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.notifications_outlined,
                                color: AppColors.textPrimary,
                                size: 26,
                              ),
                              onPressed: () => Get.toNamed('/notifications'),
                            ),
                            if (unread > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      unread > 9 ? '9+' : '$unread',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // ── Hero banner ─────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1B8A4C), Color(0xFF39E07A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Jelajahi Keindahan',
                                style: TextStyle(
                                  fontSize: 14, color: Colors.white.withOpacity(0.9),
                                  fontFamily: 'Poppins',
                                )),
                              const Text('Dataran Tinggi',
                                style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w700,
                                  color: Colors.white, fontFamily: 'Poppins',
                                )),
                              const Text('Dieng',
                                style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w700,
                                  color: Color(0xFFD4FFE8), fontFamily: 'Poppins',
                                )),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  // Chatbot shortcut button di hero banner
                                  GestureDetector(
                                    onTap: () => Navigator.pushNamed(context, '/chatbot'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white24,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.white38),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.smart_toy_rounded,
                                            color: Colors.white, size: 14),
                                          SizedBox(width: 4),
                                          Text('Tanya AI',
                                            style: TextStyle(
                                              fontSize: 12, fontWeight: FontWeight.w600,
                                              color: Colors.white, fontFamily: 'Poppins',
                                            )),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.terrain_rounded, size: 70, color: Colors.white24),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Search ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(
                      fontSize: 14, fontFamily: 'Poppins', color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Pencarian paket wisata...',
                      hintStyle: const TextStyle(
                        fontSize: 14, fontFamily: 'Poppins', color: AppColors.textHint),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: AppColors.textHint),
                              onPressed: () {
                                _searchCtrl.clear();
                                context.read<PackageService>().fetchPackages();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFE8F5EE),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFB7DFCB), width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFB7DFCB), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: (v) =>
                        context.read<PackageService>().fetchPackages(search: v),
                    onChanged: (v) {
                      if (v.isEmpty) context.read<PackageService>().fetchPackages();
                      setState(() {});
                    },
                  ),
                ),
              ),

              // ── Rekomendasi AI/ML ───────────────────────────
              SliverToBoxAdapter(
                child: _AiPackageRecommendationSection(
                  packages: packages.packages,
                  selectedInterest: _selectedInterest,
                  budget: _recommendationBudget,
                  duration: _recommendationDuration.round(),
                  onInterestChanged: (value) => setState(() => _selectedInterest = value),
                  onBudgetChanged: (value) => setState(() => _recommendationBudget = value),
                  onDurationChanged: (value) => setState(() => _recommendationDuration = value),
                ),
              ),

              // ── Paket Wisata ────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: SectionHeader(
                    title: 'Paket Wisata',
                    onAction: () => Navigator.pushNamed(context, '/packages'),
                  ),
                ),
              ),

              if (packages.isLoading)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => ShimmerBox(width: double.infinity, height: 220, radius: 16),
                      childCount: 4,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.68,
                    ),
                  ),
                )
              else if (packages.packages.isEmpty)
                const SliverToBoxAdapter(
                  child: EmptyState(
                    title: 'Belum ada paket',
                    subtitle: 'Paket wisata akan segera hadir',
                    icon: Icons.landscape_outlined,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final pkg = packages.packages[i];
                        return PackageCard(
                          name: pkg.name,
                          price: pkg.price,
                          duration: pkg.duration,
                          image: pkg.image,
                          onTap: () => Navigator.pushNamed(
                            ctx, '/package-detail',
                            arguments: pkg.id,
                          ),
                          onBook: () => Navigator.pushNamed(
                            ctx, '/create-booking',
                            arguments: pkg.id,
                          ),
                        );
                      },
                      childCount: packages.packages.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.68,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)), // ruang FAB
            ],
          ),
        ),
      ),
    );
  }
}
// ─── AI / ML PACKAGE RECOMMENDATION SECTION ──────────────────
class _AiPackageRecommendationSection extends StatelessWidget {
  final List<PackageModel> packages;
  final String selectedInterest;
  final double budget;
  final int duration;
  final ValueChanged<String> onInterestChanged;
  final ValueChanged<double> onBudgetChanged;
  final ValueChanged<double> onDurationChanged;

  const _AiPackageRecommendationSection({
    required this.packages,
    required this.selectedInterest,
    required this.budget,
    required this.duration,
    required this.onInterestChanged,
    required this.onBudgetChanged,
    required this.onDurationChanged,
  });

  String _formatRupiah(double value) {
    return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    )}';
  }

  @override
  Widget build(BuildContext context) {
    final recommendations = PackageRecommendationService.recommend(
      packages: packages,
      preference: RecommendationPreference(
        interest: selectedInterest,
        maxBudget: budget,
        preferredDuration: duration,
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: AppColors.primaryDark, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rekomendasi AI/ML', style: AppTextStyles.h3),
                      SizedBox(height: 2),
                      Text(
                        'Content-Based Filtering dari minat, budget, dan durasi',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PackageRecommendationService.interestLabels.entries.map((entry) {
                final selected = selectedInterest == entry.key;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: selected,
                  onSelected: (_) => onInterestChanged(entry.key),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.textOnPrimary : AppColors.textPrimary,
                  ),
                  //warna pilihan minat
                  selectedColor: AppColors.primary,
                  backgroundColor: const Color(0xFFE8F5EE),
                  side: BorderSide(
                    color: selected ? AppColors.primary : const Color(0xFFB7DFCB),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            _PreferenceSlider(
              label: 'Budget maksimal',
              valueText: _formatRupiah(budget),
              value: budget,
              min: 100000,
              max: 1500000,
              divisions: 14,
              onChanged: onBudgetChanged,
            ),
            _PreferenceSlider(
              label: 'Durasi pilihan',
              valueText: '$duration jam',
              value: duration.toDouble(),
              min: 2,
              max: 12,
              divisions: 10,
              onChanged: onDurationChanged,
            ),
            const SizedBox(height: 8),
            if (recommendations.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Rekomendasi akan muncul setelah data paket berhasil dimuat.',
                  style: AppTextStyles.caption,
                ),
              )
            else
              SizedBox(
                height: 190,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recommendations.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final rec = recommendations[index];
                    return _RecommendationCard(
                      recommendation: rec,
                      onDetail: () => Navigator.pushNamed(
                        context,
                        '/package-detail',
                        arguments: rec.package.id,
                      ),
                      onBook: () => Navigator.pushNamed(
                        context,
                        '/create-booking',
                        arguments: rec.package.id,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceSlider extends StatelessWidget {
  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _PreferenceSlider({
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.caption),
            Text(valueText, style: AppTextStyles.label),
          ],
        ),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          label: valueText,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final PackageRecommendation recommendation;
  final VoidCallback onDetail;
  final VoidCallback onBook;

  const _RecommendationCard({
    required this.recommendation,
    required this.onDetail,
    required this.onBook,
  });

  String _formatRupiah(double value) {
    return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    )}';
  }

  @override
  Widget build(BuildContext context) {
    final package = recommendation.package;
    final imageUrl = package.image == null
        ? null
        : '${AppConstants.baseUrl.replaceAll('/api', '')}/uploads/${package.image}';

    return GestureDetector(
      onTap: onDetail,
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          //warna card rekomendasi
          color: const Color(0xFFE8F5EE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFB7DFCB)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl == null
                  ? _imagePlaceholder()
                  : Image.network(
                      imageUrl,
                      width: 74,
                      height: 118,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          //warna persenan
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${recommendation.scorePercent}% cocok',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textOnPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    package.name,
                    style: AppTextStyles.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(_formatRupiah(package.price), style: AppTextStyles.price),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('${package.duration} jam', style: AppTextStyles.caption),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Expanded(
                    child: Text(
                      recommendation.reasons.join(' • '),
                      style: AppTextStyles.caption,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    height: 30,
                    child: ElevatedButton(
                      onPressed: onBook,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(double.infinity, 30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: const Text(
                        'Booking',
                        style: TextStyle(fontSize: 11, fontFamily: 'Poppins'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        width: 74,
        height: 118,
        color: AppColors.primaryLight,
        child: const Icon(Icons.landscape_rounded,
            color: AppColors.primaryDark, size: 30),
      );
}
