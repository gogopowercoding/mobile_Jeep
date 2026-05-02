import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/services/auth_service.dart';
import 'package:jepora/data/services/api_services.dart';
import 'home/home_tab.dart';
import 'booking/booking_tab.dart';
import 'games/games_tab.dart';
import 'feedback/feedback_tab.dart';
import 'profile/profile_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // ── Shake detection ──────────────────────────────────────────
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  double _lastX = 0, _lastY = 0, _lastZ = 0;
  DateTime _lastShake = DateTime.now();

  final List<Widget> _tabs = const [
    HomeTab(),
    BookingTab(),
    GamesTab(),
    FeedbackTab(),
    ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    _startShakeListener();
  }

  void _startShakeListener() {
    _accelSubscription = accelerometerEventStream().listen((event) {
      final dx = (event.x - _lastX).abs();
      final dy = (event.y - _lastY).abs();
      final dz = (event.z - _lastZ).abs();

      if (dx + dy + dz > 25) {
        final now = DateTime.now();
        if (now.difference(_lastShake).inSeconds >= 2) {
          _lastShake = now;
          _openChatbot();
        }
      }

      _lastX = event.x;
      _lastY = event.y;
      _lastZ = event.z;
    });
  }

  void _openChatbot() {
    if (!mounted) return;

    // Pastikan hanya aktif saat user login sebagai pelanggan
    final authService = context.read<AuthService>();
    if (!authService.isLoggedIn || !authService.isCustomer) return;

    Navigator.pushNamed(context, '/chatbot');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '🤖 JeepOra AI dibuka!',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  void dispose() {
    // Dispose listener agar tidak memory leak
    _accelSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifService = context.watch<NotificationService>();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16, offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isActive: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Booking',
                  isActive: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.sports_esports_rounded,
                  label: 'Games',
                  isActive: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  icon: Icons.star_rounded,
                  label: 'Feedback',
                  isActive: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isActive: _currentIndex == 4,
                  onTap: () => setState(() => _currentIndex = 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
              size: 22,
              color: isActive ? AppColors.primary : AppColors.textHint,
            ),
            const SizedBox(height: 3),
            Text(label,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'Poppins',
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}