import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'data/services/auth_service.dart';
import 'data/services/api_services.dart';
import 'presentation/screens/auth/splash_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/pelanggan/main_screen.dart';
import 'presentation/screens/admin/admin_screen.dart';
import 'presentation/screens/admin/admin_package_form_screen.dart';   
import 'presentation/screens/driver/driver_screen.dart';
import 'presentation/screens/pelanggan/booking/booking_tab.dart';
import 'presentation/screens/pelanggan/booking/upload_payment_screen.dart';     
import 'presentation/screens/pelanggan/booking/driver_tracking_screen.dart';    
import 'presentation/screens/pelanggan/package/package_detail_screen.dart';     
import 'presentation/screens/pelanggan/package/time_zone_converter_screen.dart';
import 'presentation/screens/pelanggan/chatbot/chatbot_screen.dart';            
import 'presentation/screens/pelanggan/profile/edit_profile_screen.dart';
import 'presentation/screens/pelanggan/profile/notifications_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'presentation/screens/admin/admin_schedule_form.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);
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
          // ── Auth ─────────────────────────────────────────────
          '/':                    (_) => const SplashScreen(),
          '/login':               (_) => const LoginScreen(),
          '/register':            (_) => const RegisterScreen(),

          // ── Pelanggan ─────────────────────────────────────────
          '/home':                (_) => const MainScreen(),
          '/create-booking':      (_) => const CreateBookingScreen(),
          '/upload-payment':      (_) => const UploadPaymentScreen(),       
          '/driver-tracking':     (_) => const DriverTrackingScreen(),      
          '/package-detail':      (_) => const PackageDetailScreen(),       
          '/timezone':            (_) => const TimeZoneConverterScreen(),    
          '/chatbot':             (_) => const ChatbotScreen(),             

          // ── Admin ─────────────────────────────────────────────
          '/admin':               (_) => const AdminScreen(),
          '/admin/package-form':  (_) => const AdminPackageFormScreen(),    
          '/admin-schedule-form': (c) => const AdminScheduleForm(),

          // ── Supir ─────────────────────────────────────────────
          '/driver':              (_) => const DriverScreen(),

          // ── Shared ───────────────────────────────────────────
          '/edit-profile':        (_) => const EditProfileScreen(),
          '/notifications':       (_) => const NotificationsScreen(),
        },
      ),
    );
  }
}
