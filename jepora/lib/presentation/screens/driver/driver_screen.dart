import 'package:flutter/material.dart';
import '../../widgets/common/app_bottom_navbar.dart';
import 'driver_incoming_tab.dart';
import 'driver_active_tab.dart';
import 'driver_profile_tab.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  int _currentIndex = 0;

  static const _tabs = [
    DriverIncomingTab(),
    DriverActiveTab(),
    DriverProfileTab(),
  ];

  static const _navItems = [
    NavItemData(icon: Icons.notifications_active_rounded, label: 'Masuk'),
    NavItemData(icon: Icons.directions_car_rounded,       label: 'Aktif'),
    NavItemData(icon: Icons.person_rounded,               label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Jika tidak di tab pertama, balik ke tab pertama
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return false;
        }
        // Jika sudah di tab pertama, konfirmasi exit
        final exit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Keluar dari JeepOra Driver?'),
            content: const Text('Apakah Anda ingin keluar dari aplikasi?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Keluar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        return exit ?? false;
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: _currentIndex,
          items: _navItems,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}