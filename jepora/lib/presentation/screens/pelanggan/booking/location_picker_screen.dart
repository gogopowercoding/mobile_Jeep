// lib/presentation/screens/booking/location_picker_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/models/location_model.dart';
import 'dart:ui' as ui;


/// Layar fullscreen pilih titik penjemputan di peta.
/// Mengembalikan [LocationModel] via Navigator.pop().
///
/// Cara pakai:
/// ```dart
/// final result = await Navigator.pushNamed(context, '/location-picker');
/// if (result is LocationModel) { ... }
/// ```
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  // ── Default center: Gunung Merapi area (destinasi jeep wisata umum) ──
  static const LatLng _defaultCenter = LatLng(-7.540997, 110.445862);

  final MapController _mapController = MapController();

  LatLng? _pickedLatLng;
  String? _addressLabel;
  bool _isReverseGeocoding = false;
  bool _isGettingMyLocation = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // ── Ambil lokasi GPS saat ini ──────────────────────────────────────
  Future<void> _goToMyLocation() async {
    setState(() => _isGettingMyLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Aktifkan layanan lokasi terlebih dahulu');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Izin lokasi ditolak');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('Izin lokasi ditolak permanen. Buka Pengaturan.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final latLng = LatLng(pos.latitude, pos.longitude);
      _mapController.move(latLng, 16.0);
      await _onMapTap(latLng);
    } catch (e) {
      _showSnackBar('Gagal mendapatkan lokasi: $e');
    } finally {
      if (mounted) setState(() => _isGettingMyLocation = false);
    }
  }

  // ── Handler tap peta ───────────────────────────────────────────────
  Future<void> _onMapTap(LatLng latLng) async {
    setState(() {
      _pickedLatLng = latLng;
      _addressLabel = null;
      _isReverseGeocoding = true;
    });

    // Reverse geocoding untuk dapat nama jalan
    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final parts = <String>[
          if (p.name != null && p.name!.isNotEmpty && p.name != p.street) p.name!,
          if (p.street != null && p.street!.isNotEmpty) p.street!,
          if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality!,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
        ];
        setState(() => _addressLabel = parts.take(3).join(', '));
      }
    } catch (_) {
      // Gagal reverse geocode → tampilkan koordinat saja (sudah fallback di model)
    } finally {
      if (mounted) setState(() => _isReverseGeocoding = false);
    }
  }

  // ── Konfirmasi & kembali dengan lokasi terpilih ───────────────────
  void _confirmLocation() {
    if (_pickedLatLng == null) return;
    final result = LocationModel(
      latitude: _pickedLatLng!.latitude,
      longitude: _pickedLatLng!.longitude,
      label: _addressLabel,
    );
    Navigator.pop(context, result);
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(fontFamily: 'Poppins'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Peta ────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 13.0,
              minZoom: 5.0,
              maxZoom: 19.0,
              onTap: (tapPosition, latLng) => _onMapTap(latLng),
            ),
            children: [
              // Tile layer OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.jepora.app',
                maxZoom: 19,
              ),

              // Marker titik terpilih
              if (_pickedLatLng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _pickedLatLng!,
                      width: 56,
                      height: 72,
                      alignment: Alignment.topCenter,
                      child: _PinMarker(),
                    ),
                  ],
                ),
            ],
          ),

          // ── App Bar custom (transparan dengan blur) ──────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    // Tombol kembali
                    _MapButton(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.textPrimary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    // Title card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.touch_app_rounded,
                                size: 16, color: AppColors.primary),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tap peta untuk pilih titik jemput',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Tombol lokasi saya (kanan tengah) ───────────────────────
          Positioned(
            right: 16,
            bottom: _pickedLatLng != null ? 200 : 100,
            child: _MapButton(
              onTap: _isGettingMyLocation ? null : _goToMyLocation,
              child: _isGettingMyLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: AppColors.primary),
                    )
                  : const Icon(Icons.my_location_rounded,
                      color: AppColors.primary, size: 20),
            ),
          ),

          // ── Panel bawah: info lokasi terpilih + tombol konfirmasi ────
          if (_pickedLatLng != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomPanel(
                latLng: _pickedLatLng!,
                addressLabel: _addressLabel,
                isReverseGeocoding: _isReverseGeocoding,
                onConfirm: _confirmLocation,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Pin Marker Widget ────────────────────────────────────────────────────
class _PinMarker extends StatefulWidget {
  @override
  State<_PinMarker> createState() => _PinMarkerState();
}

class _PinMarkerState extends State<_PinMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _bounceAnim = Tween<double>(begin: -8, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.bounceOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _bounceAnim.value),
        child: Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ikon pin
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.directions_car_rounded,
                color: Colors.white, size: 20),
          ),
          // Ekor pin segitiga
          CustomPaint(
            size: const Size(16, 10),
            painter: _PinTailPainter(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ─── Pin Tail Painter ─────────────────────────────────────────────────────
class _PinTailPainter extends CustomPainter {
  final Color color;
  _PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinTailPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ─── Map Button (tombol bulat melayang di peta) ───────────────────────────
class _MapButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  const _MapButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ─── Bottom Panel ─────────────────────────────────────────────────────────
class _BottomPanel extends StatelessWidget {
  final LatLng latLng;
  final String? addressLabel;
  final bool isReverseGeocoding;
  final VoidCallback onConfirm;

  const _BottomPanel({
    required this.latLng,
    required this.addressLabel,
    required this.isReverseGeocoding,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Label "Titik Penjemputan"
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.place_rounded,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Titik Penjemputan Dipilih',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Alamat / koordinat
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: isReverseGeocoding
                ? Row(
                    children: const [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5, color: AppColors.primary),
                      ),
                      SizedBox(width: 10),
                      Text('Mencari nama lokasi…',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            color: AppColors.textSecondary,
                          )),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (addressLabel != null) ...[
                        Text(
                          addressLabel!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        '${latLng.latitude.toStringAsFixed(6)}, '
                        '${latLng.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'Poppins',
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 16),

          // Tombol Gunakan Lokasi Ini
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onConfirm,
              icon: const Icon(Icons.check_circle_rounded,
                  size: 18, color: Colors.white),
              label: const Text(
                'Gunakan Lokasi Ini',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}