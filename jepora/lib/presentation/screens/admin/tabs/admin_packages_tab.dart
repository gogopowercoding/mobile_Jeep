import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jepora/core/constants/app_constants.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/models/models.dart';
import 'package:jepora/data/services/api_services.dart';
import 'package:jepora/presentation/widgets/common/common_widgets.dart';
import '../widgets/admin_package_icon.dart';

class AdminPackagesTab extends StatefulWidget {
  const AdminPackagesTab({super.key});

  @override
  State<AdminPackagesTab> createState() => _AdminPackagesTabState();
}

class _AdminPackagesTabState extends State<AdminPackagesTab> {
  // Hanya expand state di sini — data jadwal dibaca dari PackageService cache
  final Map<int, bool> _expandedMap = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PackageService>().fetchPackages();
    });
  }

  // ── Expand / collapse + lazy fetch jadwal ──────────────────
  Future<void> _toggleExpand(int packageId) async {
    final isExpanded = _expandedMap[packageId] ?? false;
    setState(() => _expandedMap[packageId] = !isExpanded);

    if (!isExpanded &&
        context.read<PackageService>().getSchedules(packageId).isEmpty) {
      await context.read<PackageService>().fetchSchedules(packageId);
    }
  }

  Future<void> _refreshSchedules(int packageId) async {
    await context.read<PackageService>().fetchSchedules(packageId);
  }

  // ── Navigasi paket ─────────────────────────────────────────
  void _goToAddPackage() {
    Navigator.pushNamed(context, '/admin/package-form').then((_) {
      context.read<PackageService>().fetchPackages();
    });
  }

  void _goToEditPackage(PackageModel pkg) {
    Navigator.pushNamed(context, '/admin/package-form', arguments: pkg)
        .then((_) => context.read<PackageService>().fetchPackages());
  }

  // ── Dialog hapus paket ─────────────────────────────────────
  Future<void> _confirmDeletePackage(PackageModel pkg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Paket',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text('Yakin ingin menghapus paket "${pkg.name}"?',
            style: const TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      // TODO: await context.read<PackageService>().deletePackage(pkg.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Paket "${pkg.name}" dihapus'),
            backgroundColor: AppColors.error),
      );
      context.read<PackageService>().fetchPackages();
    }
  }

  // ── Dialog hapus jadwal ────────────────────────────────────
  Future<void> _confirmDeleteSchedule(ScheduleModel s, int packageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Jadwal?',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text('Yakin ingin menghapus "${s.activity}"?',
            style: const TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Poppins')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus',
                style: TextStyle(color: AppColors.error, fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<PackageService>().deleteSchedule(s.id, packageId);
    }
  }

  String _shortTime(String t) => t.length >= 5 ? t.substring(0, 5) : t;

  @override
  Widget build(BuildContext context) {
    final packages = context.watch<PackageService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paket Wisata'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            tooltip: 'Tambah Paket',
            onPressed: _goToAddPackage,
          ),
        ],
      ),
      body: packages.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : packages.packages.isEmpty
              ? EmptyState(
                  title: 'Belum ada paket',
                  icon: Icons.landscape_outlined,
                  actionText: 'Tambah Paket',
                  onAction: _goToAddPackage,
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => packages.fetchPackages(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: packages.packages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final pkg = packages.packages[i];
                      final isExpanded = _expandedMap[pkg.id] ?? false;
                      final schedules = packages.getSchedules(pkg.id);
                      final isLoadingSchedule = packages.isScheduleLoading(pkg.id);

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
                            // ─── Header paket ────────────────────
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: pkg.image != null
                                      ? Image.network(
                                          '${AppConstants.baseUrl.replaceAll('/api', '')}/uploads/${pkg.image}',
                                          width: 54, height: 54, fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const AdminPackageIcon(),
                                        )
                                      : const AdminPackageIcon(),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(pkg.name, style: AppTextStyles.label),
                                      Text(
                                        'Rp ${pkg.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                                        style: AppTextStyles.price,
                                      ),
                                      Text('${pkg.duration} jam',
                                          style: AppTextStyles.caption),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      color: AppColors.info, size: 20),
                                  tooltip: 'Edit Paket',
                                  onPressed: () => _goToEditPackage(pkg),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      color: AppColors.error, size: 20),
                                  tooltip: 'Hapus Paket',
                                  onPressed: () => _confirmDeletePackage(pkg),
                                ),
                                IconButton(
                                  icon: Icon(
                                    isExpanded
                                        ? Icons.expand_less_rounded
                                        : Icons.expand_more_rounded,
                                    color: AppColors.textSecondary,
                                  ),
                                  tooltip: isExpanded ? 'Sembunyikan Jadwal' : 'Lihat Jadwal',
                                  onPressed: () => _toggleExpand(pkg.id),
                                ),
                              ],
                            ),

                            // ─── Jadwal (expandable) ─────────────
                            if (isExpanded) ...[
                              const Divider(height: 20, color: AppColors.divider),

                              if (isLoadingSchedule)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                        color: AppColors.primary, strokeWidth: 2),
                                  ),
                                )
                              else if (schedules.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: Text('Belum ada jadwal perjalanan',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontFamily: 'Poppins',
                                          color: AppColors.textSecondary)),
                                )
                              else
                                ...schedules.map((s) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 10, height: 10,
                                            decoration: const BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: AppColors.background,
                                                borderRadius: BorderRadius.circular(10),
                                                border:
                                                    Border.all(color: AppColors.divider),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Hari ${s.dayNumber}  •  ${_shortTime(s.startTime)}'
                                                    '${s.endTime != null && s.endTime!.isNotEmpty ? ' – ${_shortTime(s.endTime!)}' : ''}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      fontFamily: 'Poppins',
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(s.activity,
                                                      style: const TextStyle(
                                                          fontSize: 13,
                                                          fontFamily: 'Poppins',
                                                          color: AppColors.textPrimary)),
                                                  if (s.isOptional)
                                                    const Text('(Opsional)',
                                                        style: TextStyle(
                                                            fontSize: 11,
                                                            fontFamily: 'Poppins',
                                                            color: AppColors.textSecondary,
                                                            fontStyle: FontStyle.italic)),
                                                ],
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined,
                                                size: 18, color: AppColors.primary),
                                            tooltip: 'Edit Jadwal',
                                            onPressed: () async {
                                              final result =
                                                  await Navigator.pushNamed(
                                                context,
                                                '/admin-schedule-form',
                                                arguments: {
                                                  'packageId': pkg.id,
                                                  'schedule': s,
                                                },
                                              );
                                              if (result == true) {
                                                _refreshSchedules(pkg.id);
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline,
                                                size: 18, color: AppColors.error),
                                            tooltip: 'Hapus Jadwal',
                                            onPressed: () =>
                                                _confirmDeleteSchedule(s, pkg.id),
                                          ),
                                        ],
                                      ),
                                    )),

                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Tambah Jadwal',
                                      style: TextStyle(
                                          fontFamily: 'Poppins', fontSize: 13)),
                                  onPressed: () async {
                                    final result = await Navigator.pushNamed(
                                      context,
                                      '/admin-schedule-form',
                                      arguments: {'packageId': pkg.id},
                                    );
                                    if (result == true) _refreshSchedules(pkg.id);
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}