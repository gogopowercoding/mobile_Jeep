import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_services.dart';
import '../../widgets/common/common_widgets.dart';
import '../../../core/constants/app_constants.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PackageService>().fetchPackages();
      context.read<NotificationService>().fetchNotifications();
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
    final notifs   = context.watch<NotificationService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      // ── FAB Chatbot ───────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/chatbot'),
        backgroundColor: AppColors.primary,
        tooltip: 'Tanya AI JeepOra',
        child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
      ),
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
                                color: AppColors.primary, fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ── Tombol Chatbot di AppBar ─────────────
                      IconButton(
                        icon: const Icon(Icons.smart_toy_outlined,
                          color: AppColors.textPrimary, size: 26),
                        tooltip: 'Chatbot',
                        onPressed: () => Navigator.pushNamed(context, '/chatbot'),
                      ),
                      // ── Notif icon ───────────────────────────
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined,
                              color: AppColors.textPrimary, size: 26),
                            onPressed: () => Navigator.pushNamed(context, '/notifications'),
                          ),
                          if (notifs.unreadCount > 0)
                            Positioned(
                              right: 8, top: 8,
                              child: Container(
                                width: 16, height: 16,
                                decoration: const BoxDecoration(
                                  color: AppColors.error, shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    notifs.unreadCount > 9 ? '9+' : '${notifs.unreadCount}',
                                    style: const TextStyle(
                                      fontSize: 9, color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
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
                                  // Booking button
                                  GestureDetector(
                                    onTap: () => Navigator.pushNamed(context, '/booking'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text('Booking Sekarang',
                                        style: TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.w700,
                                          color: AppColors.primaryDark, fontFamily: 'Poppins',
                                        )),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
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

              // ── Quick Access: Chatbot Banner ─────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/chatbot'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.smart_toy_rounded,
                              color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tanya AI JeepOra 🤖',
                                  style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary, fontFamily: 'Poppins',
                                  )),
                                Text('Tanya rekomendasi wisata, tips, atau info paket',
                                  style: TextStyle(
                                    fontSize: 11, color: AppColors.textHint,
                                    fontFamily: 'Poppins',
                                  )),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded,
                            size: 14, color: AppColors.textHint),
                        ],
                      ),
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
                    decoration: InputDecoration(
                      hintText: 'Pencarian',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                context.read<PackageService>().fetchPackages();
                              },
                            )
                          : null,
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

              // ── Paket Wisata ────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: SectionHeader(
                    title: 'Paket Wisata',
                    actionText: 'View all',
                    onAction: () => Navigator.pushNamed(context, '/packages'),
                  ),
                ),
              ),

              if (packages.isLoading)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: 3,
                      itemBuilder: (_, __) => Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: ShimmerBox(width: 160, height: 220, radius: 16),
                      ),
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
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 230,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: packages.packages.length,
                      itemBuilder: (ctx, i) {
                        final pkg = packages.packages[i];
                        return Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: SizedBox(
                            width: 160,
                            child: PackageCard(
                              name: pkg.name,
                              price: pkg.price,
                              duration: pkg.duration,
                              image: pkg.image,
                              onTap: () => Navigator.pushNamed(
                                context, '/package-detail',
                                arguments: pkg.id,
                              ),
                            ),
                          ),
                        );
                      },
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