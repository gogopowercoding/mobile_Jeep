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
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}