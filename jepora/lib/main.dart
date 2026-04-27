import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'data/services/auth_service.dart';
import 'data/services/api_services.dart';
import 'presentation/screens/auth/splash_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/screens/admin/admin_screen.dart';
import 'presentation/screens/driver/driver_screen.dart';
import 'presentation/screens/booking/booking_tab.dart';
import 'presentation/screens/profile/edit_profile_screen.dart';
import 'presentation/screens/profile/notifications_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ApiClient().init();
  runApp(const JeepOraApp());
}

class JeepOraApp extends StatelessWidget {
  const JeepOraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => PackageService()),
        ChangeNotifierProvider(create: (_) => OrderService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
      ],
      child: MaterialApp(
        title: 'JeepOra',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/':               (_) => const SplashScreen(),
          '/login':          (_) => const LoginScreen(),
          '/register':       (_) => const RegisterScreen(),
          // Pelanggan
          '/home':           (_) => const MainScreen(),
          '/create-booking': (_) => const CreateBookingScreen(),
          // Admin
          '/admin':          (_) => const AdminScreen(),
          // Supir
          '/driver':         (_) => const DriverScreen(),
          // Shared
          '/edit-profile':   (_) => const EditProfileScreen(),
          '/notifications':  (_) => const NotificationsScreen(),
        },
      ),
    );
  }
}
