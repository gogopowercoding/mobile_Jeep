import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/services/admin_notification_service.dart';
import 'package:jepora/presentation/widgets/common/app_bottom_navbar.dart';
import 'tabs/admin_notifications_screen.dart';
import 'tabs/admin_dashboard_tab.dart';
import 'tabs/admin_orders_tab.dart';
import 'tabs/admin_packages_tab.dart';
import 'tabs/admin_profile_tab.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _currentIndex = 0;

  static const _tabs = [
    AdminDashboardTab(),
    AdminOrdersTab(),
    AdminPackagesTab(),
    AdminProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final svc = context.read<AdminNotificationService>();
      svc.fetchNotifications();
      svc.startPolling();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifSvc = context.watch<AdminNotificationService>();
    final unread   = notifSvc.unreadCount;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('JeepOra Admin',
          style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700,
            color: AppColors.primary, fontFamily: 'Poppins',
          )),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: notifSvc,
                    child: const AdminNotificationsScreen(),
                  ),
                ),
              ).then((_) => notifSvc.fetchNotifications()),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: unread > 0
                          ? AppColors.error.withOpacity(0.08)
                          : AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      unread > 0
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_outlined,
                      color: unread > 0 ? AppColors.error : AppColors.primary,
                      size: 22,
                    ),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: -2, top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                            minWidth: 18, minHeight: 18),
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          style: const TextStyle(
                            color: Colors.white, fontSize: 9,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        items: const [
          NavItemData(icon: Icons.dashboard_rounded,  label: 'Dashboard'),
          NavItemData(icon: Icons.list_alt_rounded,   label: 'Pesanan'),
          NavItemData(icon: Icons.landscape_rounded,  label: 'Paket'),
          NavItemData(icon: Icons.person_rounded,     label: 'Profil'),
        ],
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}