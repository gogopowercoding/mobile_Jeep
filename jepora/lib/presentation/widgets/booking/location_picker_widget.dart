// lib/presentation/widgets/booking/location_picker_widget.dart

import 'package:flutter/material.dart';

import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/models/location_model.dart';

/// Widget yang ditampilkan di form CreateBookingScreen
/// untuk memilih titik penjemputan via peta interaktif.
///
/// Cara pakai:
/// ```dart
/// LocationPickerWidget(
///   location: _selectedLocation,
///   onChanged: (loc) => setState(() => _selectedLocation = loc),
/// )
/// ```
class LocationPickerWidget extends StatelessWidget {
  final LocationModel? location;
  final ValueChanged<LocationModel?> onChanged;

  /// Jika true, tampilkan border merah (validasi gagal)
  final bool hasError;

  const LocationPickerWidget({
    super.key,
    required this.location,
    required this.onChanged,
    this.hasError = false,
  });

  Future<void> _openPicker(BuildContext context) async {
    final result = await Navigator.pushNamed(context, '/location-picker');
    if (result is LocationModel) {
      onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPicked = location != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Card utama ────────────────────────────────────────────
        GestureDetector(
          onTap: () => _openPicker(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isPicked ? AppColors.primaryLight : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasError
                    ? AppColors.error
                    : isPicked
                        ? AppColors.primary
                        : AppColors.divider,
                width: isPicked ? 1.5 : 0.5,
              ),
            ),
            child: isPicked
                ? _PickedLocationContent(
                    location: location!,
                    onClear: () => onChanged(null),
                    onEdit: () => _openPicker(context),
                  )
                : _EmptyPickerContent(),
          ),
        ),

        // ── Pesan error validasi ──────────────────────────────────
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: const [
              Icon(Icons.error_outline_rounded,
                  size: 13, color: AppColors.error),
              SizedBox(width: 5),
              Text(
                'Pilih titik penjemputan terlebih dahulu',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'Poppins',
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── State: belum ada lokasi dipilih ─────────────────────────────────────
class _EmptyPickerContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Ikon peta
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.add_location_alt_outlined,
              color: AppColors.textHint, size: 22),
        ),
        const SizedBox(width: 12),

        // Teks panduan
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Pilih Titik Penjemputan',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Tap untuk membuka peta interaktif',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'Poppins',
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),

        // Arrow
        const Icon(Icons.chevron_right_rounded,
            color: AppColors.textHint, size: 20),
      ],
    );
  }
}

// ─── State: lokasi sudah dipilih ─────────────────────────────────────────
class _PickedLocationContent extends StatelessWidget {
  final LocationModel location;
  final VoidCallback onClear;
  final VoidCallback onEdit;

  const _PickedLocationContent({
    required this.location,
    required this.onClear,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row ─────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ikon pin aktif
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.place_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),

            // Alamat / koordinat
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama lokasi (alamat jika ada, koordinat jika tidak)
                  if (location.label != null && location.label!.isNotEmpty) ...[
                    Text(
                      location.label!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                  ],
                  // Koordinat selalu tampil
                  Text(
                    location.coordsString,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'Poppins',
                      color: AppColors.textSecondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),

            // Menu aksi (ubah / hapus)
            Column(
              children: [
                // Tombol ubah
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.edit_location_alt_rounded,
                            size: 12, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'Ubah',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Tombol hapus
                GestureDetector(
                  onTap: onClear,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.close_rounded,
                            size: 12, color: AppColors.error),
                        SizedBox(width: 4),
                        Text(
                          'Hapus',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // ── Mini map preview (koordinat visual) ────────────────
        const SizedBox(height: 10),
        const Divider(color: AppColors.divider, height: 1),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Titik penjemputan sudah dipilih',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'Poppins',
                  color: AppColors.primary.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}