import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_services.dart';
import '../../../data/models/models.dart';
import '../../widgets/common/common_widgets.dart';

class DriverActiveTab extends StatefulWidget {
  const DriverActiveTab({super.key});

  @override
  State<DriverActiveTab> createState() => _DriverActiveTabState();
}

class _DriverActiveTabState extends State<DriverActiveTab> {
  List<OrderModel> _activeOrders = [];
  bool _isLoading = false;

  // Lokasi driver real-time
  Timer? _locationTimer;
  Position? _driverPosition;
  int? _trackingOrderId; // order yang sedang di-track lokasinya ke pelanggan

  @override
  void initState() {
    super.initState();
    _fetchActiveOrders();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    // Minta izin lokasi
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return;
    }
    if (perm == LocationPermission.deniedForever) return;

    // Update lokasi tiap 10 detik
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        if (mounted) setState(() => _driverPosition = pos);

        // Kirim lokasi ke server untuk order yang sedang ongoing
        if (_trackingOrderId != null) {
          await ApiClient().dio.put('/orders/$_trackingOrderId/driver-location', data: {
            'latitude':  pos.latitude,
            'longitude': pos.longitude,
          });
        }
      } catch (_) {}
    });
  }

  Future<void> _fetchActiveOrders() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient().dio.get('/orders/driver-active');
      if (res.data['success'] == true) {
        final orders = (res.data['data'] as List)
            .map((e) => OrderModel.fromJson(e))
            .toList();
        setState(() => _activeOrders = orders);

        // Restore tracking jika ada order ongoing (misal setelah restart app)
        final ongoingOrder = orders.where((o) => o.status == 'ongoing').firstOrNull;
        if (ongoingOrder != null && _trackingOrderId == null) {
          setState(() => _trackingOrderId = ongoingOrder.id);
        }
      }
    } catch (_) {} finally {
      setState(() => _isLoading = false);
    }
  }

  /// Kirim lokasi langsung tanpa menunggu timer
  Future<void> _sendLocationNow(int orderId) async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) setState(() => _driverPosition = pos);
      await ApiClient().dio.put('/orders/$orderId/driver-location', data: {
        'latitude':  pos.latitude,
        'longitude': pos.longitude,
      });
    } catch (_) {}
  }

  Future<void> _updateStatus(int orderId, String status) async {
    final orderService = context.read<OrderService>();
    final ok = await orderService.updateStatus(orderId, status);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(status == 'ongoing'
            ? '🚙 Perjalanan dimulai! Lokasi Anda dipantau.'
            : '🏁 Perjalanan selesai!'),
        backgroundColor: AppColors.success,
      ));
      // Mulai/stop tracking lokasi driver
      setState(() {
        _trackingOrderId = status == 'ongoing' ? orderId : null;
      });
      // Kirim lokasi langsung sekarang (tidak nunggu timer 10 detik)
      if (status == 'ongoing') {
        _sendLocationNow(orderId);
      }
      _fetchActiveOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pesanan Aktif'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _fetchActiveOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _activeOrders.isEmpty
              ? const EmptyState(
                  title: 'Tidak ada pesanan aktif',
                  subtitle: 'Pesanan yang sudah Anda terima akan muncul di sini',
                  icon: Icons.directions_car_outlined,
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _fetchActiveOrders,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _activeOrders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) => _ActiveOrderCard(
                      order: _activeOrders[i],
                      onUpdateStatus: _updateStatus,
                    ),
                  ),
                ),
    );
  }
}

// ─── ACTIVE ORDER CARD ───────────────────────────────────────
class _ActiveOrderCard extends StatelessWidget {
  final OrderModel order;
  final Function(int, String) onUpdateStatus;

  const _ActiveOrderCard({
    required this.order,
    required this.onUpdateStatus,
  });

  String _formatRupiah(double amount) => 'Rp ${amount
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.directions_car_rounded,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order #${order.id}',
                              style: AppTextStyles.label),
                          Text(order.packageName ?? 'Paket Wisata',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    StatusBadge(status: order.status),
                  ],
                ),

                // Indikator lokasi aktif (jika sedang ongoing)
                if (order.status == 'ongoing') ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(children: [
                      Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text('Lokasi Anda sedang dibagikan ke pelanggan',
                        style: TextStyle(fontSize: 11, fontFamily: 'Poppins',
                            color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 12),

                // Info rows
                _InfoRow(icon: Icons.person_outline_rounded,
                    label: 'Pelanggan',
                    value: order.customerName ?? '-'),
                const SizedBox(height: 6),
                _InfoRow(icon: Icons.calendar_today_rounded,
                    label: 'Tanggal', value: order.bookingDate),
                const SizedBox(height: 6),
                _InfoRow(icon: Icons.payments_outlined,
                    label: 'Total', value: _formatRupiah(order.totalPrice)),
                if (order.notes != null && order.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _InfoRow(icon: Icons.notes_rounded,
                      label: 'Catatan', value: order.notes!),
                ],

                // Lokasi pelanggan
                if (order.latitude != null && order.longitude != null) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomerLocationMapScreen(order: order),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${order.latitude!.toStringAsFixed(5)}, ${order.longitude!.toStringAsFixed(5)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryDark,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          const Row(
                            children: [
                              Icon(Icons.map_rounded,
                                  color: AppColors.primary, size: 16),
                              SizedBox(width: 4),
                              Text('Lihat Peta',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                if (order.status == 'confirmed')
                  PrimaryButton(
                    text: 'Mulai Perjalanan',
                    icon: Icons.directions_car_rounded,
                    onPressed: () => onUpdateStatus(order.id, 'ongoing'),
                  ),
                if (order.status == 'ongoing')
                  ElevatedButton.icon(
                    icon: const Icon(Icons.flag_rounded, size: 18),
                    label: const Text('Selesaikan Perjalanan'),
                    onPressed: () => onUpdateStatus(order.id, 'completed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusCompleted,
                      minimumSize: const Size(double.infinity, 52),
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

// ─── INFO ROW ────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        SizedBox(
            width: 72, child: Text(label, style: AppTextStyles.caption)),
        Expanded(child: Text(value, style: AppTextStyles.body)),
      ],
    );
  }
}

// ─── CUSTOMER LOCATION MAP SCREEN ────────────────────────────
class CustomerLocationMapScreen extends StatefulWidget {
  final OrderModel order;

  const CustomerLocationMapScreen({super.key, required this.order});

  @override
  State<CustomerLocationMapScreen> createState() => _CustomerLocationMapScreenState();
}

class _CustomerLocationMapScreenState extends State<CustomerLocationMapScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  Position? _driverPosition;
  double? _headingDegrees;
  double? _bearingToCustomer;
  double? _distanceToCustomer; // jarak garis lurus untuk fallback

  // Route jalan real dari OSRM (mengikuti jalan, bukan garis lurus).
  List<LatLng> _routePoints = [];
  double? _routeDistanceMeters;
  double? _routeDurationSeconds;
  bool _isLoadingRoute = false;
  String? _routeError;

  bool _isLoadingLocation = true;

  double get _customerLat => widget.order.latitude!;
  double get _customerLng => widget.order.longitude!;

  @override
  void initState() {
    super.initState();
    _startCompassSensor();
    _loadDriverLocation();
  }

  @override
  void dispose() {
    _magnetometerSubscription?.cancel();
    super.dispose();
  }

  void _startCompassSensor() {
    _magnetometerSubscription = magnetometerEventStream().listen((event) {
      // Sensor kedua: magnetometer/compass. Heading dihitung dari medan magnet
      // pada sumbu X dan Y agar ikon kompas dapat berputar mengikuti arah HP.
      final heading = (math.atan2(event.y, event.x) * 180 / math.pi + 360) % 360;
      if (mounted) {
        setState(() => _headingDegrees = heading.toDouble());
      }
    });
  }

  Future<void> _loadDriverLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _isLoadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final bearing = _calculateBearing(
        position.latitude,
        position.longitude,
        _customerLat,
        _customerLng,
      );
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _customerLat,
        _customerLng,
      );

      if (mounted) {
        setState(() {
          _driverPosition = position;
          _bearingToCustomer = bearing;
          _distanceToCustomer = distance;
          _isLoadingLocation = false;
        });
      }

      // Setelah posisi sopir didapat, ambil rute jalan real dari OSRM.
      await _loadRoadRoute(
        LatLng(position.latitude, position.longitude),
        LatLng(_customerLat, _customerLng),
      );
    } catch (_) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _loadRoadRoute(LatLng driverPoint, LatLng customerPoint) async {
    if (mounted) {
      setState(() {
        _isLoadingRoute = true;
        _routeError = null;
      });
    }

    try {
      // OSRM memakai format longitude,latitude.
      final coordinates =
          '${driverPoint.longitude},${driverPoint.latitude};'
          '${customerPoint.longitude},${customerPoint.latitude}';

      final response = await Dio().get(
        'https://router.project-osrm.org/route/v1/driving/$coordinates',
        queryParameters: {
          'overview': 'full',
          'geometries': 'geojson',
          'steps': 'false',
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 12),
          sendTimeout: const Duration(seconds: 12),
        ),
      );

      final routes = response.data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        throw Exception('Rute tidak ditemukan');
      }

      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coords = geometry['coordinates'] as List;

      final points = coords.map((c) {
        final item = c as List;
        final lng = (item[0] as num).toDouble();
        final lat = (item[1] as num).toDouble();
        return LatLng(lat, lng);
      }).toList();

      if (mounted) {
        setState(() {
          _routePoints = points;
          _routeDistanceMeters = (route['distance'] as num?)?.toDouble();
          _routeDurationSeconds = (route['duration'] as num?)?.toDouble();
          _isLoadingRoute = false;
        });
      }
    } catch (_) {
      // Jika routing API gagal, aplikasi tetap menampilkan fallback garis lurus.
      if (mounted) {
        setState(() {
          _routePoints = [driverPoint, customerPoint];
          _routeDistanceMeters = null;
          _routeDurationSeconds = null;
          _routeError = 'Rute jalan gagal dimuat, memakai garis lurus sementara.';
          _isLoadingRoute = false;
        });
      }
    }
  }

  double _degreeToRadian(double degree) => degree * math.pi / 180;

  double _calculateBearing(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    final lat1 = _degreeToRadian(startLat);
    final lat2 = _degreeToRadian(endLat);
    final deltaLng = _degreeToRadian(endLng - startLng);

    final y = math.sin(deltaLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLng);

    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  String _directionLabel(double degree) {
    const labels = ['Utara', 'Timur Laut', 'Timur', 'Tenggara', 'Selatan', 'Barat Daya', 'Barat', 'Barat Laut'];
    final index = ((degree + 22.5) / 45).floor() % 8;
    return labels[index];
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '$minutes menit';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}j ${remainingMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final driverPoint = _driverPosition == null
        ? null
        : LatLng(_driverPosition!.latitude, _driverPosition!.longitude);
    final customerPoint = LatLng(_customerLat, _customerLng);
    final initialCenter = driverPoint ?? customerPoint;

    final heading = _headingDegrees ?? 0;
    final bearing = _bearingToCustomer ?? 0;
    final relativeDirection = ((bearing - heading) + 360) % 360;

    return Scaffold(
      appBar: AppBar(
        title: Text('Lokasi Pelanggan — Order #${widget.order.id}'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.jeepora.app',
              ),
              if (driverPoint != null && _routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      // Mengikuti rute jalan dari OSRM. Jika gagal, fallback-nya garis lurus.
                      points: _routePoints,
                      strokeWidth: 4,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: customerPoint,
                    width: 78,
                    height: 78,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_pin_rounded,
                              color: Colors.white, size: 26),
                        ),
                        const Text('Pelanggan',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                              fontFamily: 'Poppins',
                            )),
                      ],
                    ),
                  ),
                  if (driverPoint != null)
                    Marker(
                      point: driverPoint,
                      width: 78,
                      height: 78,
                      child: Column(
                        children: [
                          Transform.rotate(
                            angle: _degreeToRadian(heading),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: AppColors.info,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.navigation_rounded,
                                  color: Colors.white, size: 24),
                            ),
                          ),
                          const Text('Sopir',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.info,
                                fontFamily: 'Poppins',
                              )),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          if (_isLoadingRoute || _routeError != null)
            Positioned(
              left: 16,
              right: 16,
              top: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider, width: 0.5),
                ),
                child: Row(
                  children: [
                    Icon(
                      _routeError == null
                          ? Icons.route_rounded
                          : Icons.warning_amber_rounded,
                      size: 18,
                      color: _routeError == null
                          ? AppColors.primaryDark
                          : AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _routeError ?? 'Mengambil rute jalan real...',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Panel kompas arah jemput pelanggan.
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.divider, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 1.2),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Positioned(
                          top: 5,
                          child: Text('N',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                                fontFamily: 'Poppins',
                              )),
                        ),
                        Transform.rotate(
                          angle: _degreeToRadian(relativeDirection),
                          child: const Icon(Icons.navigation_rounded,
                              color: AppColors.primaryDark, size: 34),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Kompas Arah Jemput', style: AppTextStyles.label),
                        const SizedBox(height: 4),
                        Text(
                          _isLoadingLocation
                              ? 'Mengambil lokasi sopir...'
                              : 'Arahkan kendaraan ke ${_directionLabel(bearing)}',
                          style: AppTextStyles.body,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _routeDistanceMeters != null
                              ? 'Rute jalan ± ${_formatDistance(_routeDistanceMeters!)} • ${_formatDuration(_routeDurationSeconds ?? 0)}'
                              : _distanceToCustomer == null
                                  ? 'Heading HP: ${heading.toStringAsFixed(0)}°'
                                  : 'Jarak lurus ± ${_formatDistance(_distanceToCustomer!)} • Heading ${heading.toStringAsFixed(0)}°',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh lokasi sopir',
                    onPressed: _loadDriverLocation,
                    icon: const Icon(Icons.my_location_rounded,
                        color: AppColors.primaryDark),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
