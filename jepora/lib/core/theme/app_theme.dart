import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color primary        = Color(0xFF39E07A);
  static const Color primaryDark    = Color(0xFF1DB954);
  static const Color primaryLight   = Color(0xFFD6EED8);

  // Background
  static const Color background     = Color(0xFFF5F5F0);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color cardGreen      = Color(0xFFD6EED8);

  // Text
  static const Color textPrimary    = Color(0xFF1A1A1A);
  static const Color textSecondary  = Color(0xFF666666);
  static const Color textHint       = Color(0xFFAAAAAA);
  static const Color textOnPrimary  = Color(0xFF0A3020);

  // Status
  static const Color success        = Color(0xFF39E07A);
  static const Color warning        = Color(0xFFFFB800);
  static const Color error          = Color(0xFFE53935);
  static const Color info           = Color(0xFF2196F3);

  // Status order
  static const Color statusPending    = Color(0xFFFFB800);
  static const Color statusConfirmed  = Color(0xFF2196F3);
  static const Color statusOngoing    = Color(0xFF9C27B0);
  static const Color statusCompleted  = Color(0xFF39E07A);
  static const Color statusCancelled  = Color(0xFFE53935);

  // Misc
  static const Color divider        = Color(0xFFE8E8E8);
  static const Color shimmerBase    = Color(0xFFE8E8E8);
  static const Color shimmerHigh    = Color(0xFFF5F5F5);
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      surface: AppColors.surface,
      background: AppColors.background,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.divider),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(
        color: AppColors.textHint,
        fontSize: 14,
        fontFamily: 'Poppins',
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
    ),
    cardTheme:  CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider, width: 0.5),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textHint,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
      ),
    ),
  );
}

// Text Styles
class AppTextStyles {
  static const TextStyle h1 = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, fontFamily: 'Poppins',
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, fontFamily: 'Poppins',
  );
  static const TextStyle h3 = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, fontFamily: 'Poppins',
  );
  static const TextStyle body = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary, fontFamily: 'Poppins',
  );
  static const TextStyle bodyMuted = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, fontFamily: 'Poppins',
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, fontFamily: 'Poppins',
  );
  static const TextStyle label = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, fontFamily: 'Poppins',
  );
  static const TextStyle price = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w700,
    color: AppColors.primary, fontFamily: 'Poppins',
  );
}
