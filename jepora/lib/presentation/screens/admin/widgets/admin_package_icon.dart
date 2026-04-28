import 'package:flutter/material.dart';
import 'package:jepora/core/theme/app_theme.dart';

class AdminPackageIcon extends StatelessWidget {
  const AdminPackageIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.landscape_rounded,
          color: AppColors.primary, size: 28),
    );
  }
}