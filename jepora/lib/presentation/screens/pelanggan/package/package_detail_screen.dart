import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/services/api_services.dart';
import 'package:jepora/data/models/models.dart';
import 'package:jepora/presentation/widgets/common/common_widgets.dart';
import 'package:jepora/presentation/widgets/common/package_itinerary_widget.dart';

/// Screen detail paket wisata
/// Route: '/package-detail', arguments: int packageId
class PackageDetailScreen extends StatefulWidget {
  const PackageDetailScreen({super.key});

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  PackageModel? _package;
  bool _isLoading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = ModalRoute.of(context)?.settings.arguments as int?;
    if (id != null) _load(id);
  }

  Future<void> _load(int id) async {
    setState(() { _isLoading = true; _error = null; });
    final pkg = await context.read<PackageService>().fetchPackageById(id);
    if (!mounted) return;
    setState(() {
      _package = pkg;
      _isLoading = false;
      _error = pkg == null ? 'Paket tidak ditemukan' : null;
    });
  }

  String _formatPrice(double price) {
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    )}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: AppTextStyles.body))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final pkg = _package!;
    return CustomScrollView(
      slivers: [
        // ── Hero image / App bar ──────────────────────────────
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          backgroundColor: AppColors.background,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.9),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: pkg.image != null
                ? Image.network(
                    pkg.image!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _PlaceholderImage(),
                  )
                : _PlaceholderImage(),
          ),
        ),

        // ── Content ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama & harga
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(pkg.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                            color: AppColors.textPrimary,
                          )),
                      ),
                      const SizedBox(width: 12),
                      Text(_formatPrice(pkg.price),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          color: AppColors.primary,
                        )),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Info chips
                  Wrap(
                    spacing: 10,
                    children: [
                      _InfoChip(
                        icon: Icons.schedule_rounded,
                        label: '${pkg.duration} jam',
                      ),
                      _InfoChip(
                        icon: Icons.directions_car_rounded,
                        label: 'Jeep 4WD',
                      ),
                      _InfoChip(
                        icon: Icons.group_rounded,
                        label: 'Maks 6 orang',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Deskripsi
                  if (pkg.description != null && pkg.description!.isNotEmpty) ...[
                    const Text('Deskripsi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        color: AppColors.textPrimary,
                      )),
                    const SizedBox(height: 8),
                    Text(pkg.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        color: AppColors.textSecondary,
                        height: 1.6,
                      )),
                    const SizedBox(height: 20),
                  ],

                  // Fasilitas (statis, bisa disesuaikan)
                  const Text('Fasilitas',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                      color: AppColors.textPrimary,
                    )),
                  const SizedBox(height: 12),
                  _FacilityGrid(),

                  const SizedBox(height: 20),

                  const Text(
                    'Jadwal Perjalanan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),

                  const SizedBox(height: 10),

                  PackageItineraryWidget(
                    schedules: pkg.schedules ?? [],
                  ),

                  // Syarat & ketentuan
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 16, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text('Info Penting',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins',
                                color: AppColors.primary,
                              )),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...[
                          'Pembayaran lunas sebelum keberangkatan',
                          'Booking minimal H-1 hari',
                          'Refund 50% jika dibatalkan H-3',
                          'Bawa jaket & alas kaki nyaman',
                        ].map((s) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                )),
                              Expanded(
                                child: Text(s,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Poppins',
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  )),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Tombol booking
                  PrimaryButton(
                    text: 'Booking Paket Ini',
                    icon: Icons.calendar_month_rounded,
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/create-booking',
                      arguments: pkg.id,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Placeholder Image ────────────────────────────────────────
class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryLight,
      child: const Center(
        child: Icon(Icons.terrain_rounded,
            size: 80, color: AppColors.primary),
      ),
    );
  }
}

// ─── Info Chip ────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'Poppins',
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            )),
        ],
      ),
    );
  }
}

// ─── Facility Grid ────────────────────────────────────────────
class _FacilityGrid extends StatelessWidget {
  final List<Map<String, dynamic>> _facilities = const [
    {'icon': Icons.directions_car_rounded, 'label': 'Jeep 4WD'},
    {'icon': Icons.person_rounded,         'label': 'Guide Lokal'},
    {'icon': Icons.local_parking_rounded,  'label': 'Tiket Masuk'},
    {'icon': Icons.camera_alt_rounded,     'label': 'Spot Foto'},
    {'icon': Icons.local_drink_rounded,    'label': 'Air Minum'},
    {'icon': Icons.headset_mic_rounded,    'label': 'CS Support'},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.2,
      ),
      itemCount: _facilities.length,
      itemBuilder: (_, i) {
        final f = _facilities[i];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider, width: 0.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(f['icon'] as IconData,
                  size: 24, color: AppColors.primary),
              const SizedBox(height: 6),
              Text(f['label'] as String,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'Poppins',
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
