import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/core/network/api_client.dart';
import 'package:jepora/data/models/models.dart';

/// Screen tracking lokasi supir real-time untuk pelanggan
/// Route: '/driver-tracking', arguments: OrderModel
class DriverTrackingScreen extends StatefulWidget {
  const DriverTrackingScreen({super.key});

  @override
  State<DriverTrackingScreen> createState() => _DriverTrackingScreenState();
}

class _DriverTrackingScreenState extends State<DriverTrackingScreen> {
  final MapController _mapController = MapController();
  Timer? _refreshTimer;

  LatLng? _driverLocation;
  LatLng? _customerLocation;
  bool _isLoading = true;
  String? _error;
  OrderModel? _order;

  // Status teks
  String _statusText = 'Memuat lokasi supir...';
  bool _isOnTheWay = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _order = ModalRoute.of(context)?.settings.arguments as OrderModel?;
    if (_order != null) {
      // Jika order punya lokasi pelanggan
      if (_order!.latitude != null && _order!.longitude != null) {
        _customerLocation = LatLng(_order!.latitude!, _order!.longitude!);
      }
      _fetchDriverLocation();
      // Refresh tiap 10 detik
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => _fetchDriverLocation(),
      );
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDriverLocation() async {
    if (_order == null) return;
    try {
      final res = await ApiClient().dio.get('/orders/${_order!.id}/driver-location');
      if (res.data['success'] == true && res.data['data'] != null) {
        final data = res.data['data'];
        final lat = double.tryParse(data['latitude'].toString());
        final lng = double.tryParse(data['longitude'].toString());
        if (lat != null && lng != null && mounted) {
          final newLoc = LatLng(lat, lng);
          setState(() {
            _driverLocation = newLoc;
            _isLoading = false;
            _isOnTheWay = true;
            _statusText = 'Supir sedang dalam perjalanan';
          });
          // Auto-center ke supir
          _mapController.move(newLoc, 14.0);
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _statusText = 'Menunggu supir memulai perjalanan...';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Gagal memuat lokasi';
          _statusText = 'Tidak dapat memuat lokasi';
        });
      }
    }
  }

  // Default center: Dieng Plateau
  static const LatLng _diengCenter = LatLng(-7.2108, 109.9204);

  LatLng get _mapCenter =>
      _driverLocation ?? _customerLocation ?? _diengCenter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lacak Supir'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded,
                color: AppColors.primary),
            tooltip: 'Pusat ke supir',
            onPressed: _driverLocation != null
                ? () => _mapController.move(_driverLocation!, 15.0)
                : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Status bar ───────────────────────────────────────
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isOnTheWay
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_statusText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    )),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),

          // ── Peta ─────────────────────────────────────────────
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _mapCenter,
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.jepora',
                ),

                // Marker supir
                if (_driverLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _driverLocation!,
                        width: 56,
                        height: 56,
                        child: _DriverMarker(),
                      ),
                    ],
                  ),

                // Marker pelanggan (lokasi jemput)
                if (_customerLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _customerLocation!,
                        width: 48,
                        height: 48,
                        child: _CustomerMarker(),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // ── Info card supir ──────────────────────────────────
          if (_order?.driverName != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_order!.driverName!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          )),
                        Text('Supir Anda',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            color: AppColors.textSecondary,
                          )),
                      ],
                    ),
                  ),
                  if (_order?.driverPhone != null)
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.phone_rounded,
                            color: AppColors.primary, size: 22),
                        tooltip: 'Hubungi supir',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Nomor supir: ${_order!.driverPhone}'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

          // Padding bawah
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// ─── Custom markers ───────────────────────────────────────────
class _DriverMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.directions_car_rounded,
          color: Colors.white, size: 26),
    );
  }
}

class _CustomerMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.info,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.info.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.person_pin_circle_rounded,
          color: Colors.white, size: 24),
    );
  }
}
