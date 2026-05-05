import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class NavItemData {
  final IconData icon;
  final String label;
  final int badgeCount;

  const NavItemData({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
  });
}

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<NavItemData> items;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,  // ← GANTI jadi spaceEvenly
            children: List.generate(items.length, (i) {
              final item   = items[i];
              final active = currentIndex == i;
              return Expanded(  // ← WRAP dengan Expanded
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),  // ← TAMBAH margin
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),  // ← KURANGI padding (dari 16)
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primaryLight
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(item.icon,
                              size: 22,
                              color: active
                                  ? AppColors.primary
                                  : AppColors.textHint),
                            if (item.badgeCount > 0)
                              Positioned(
                                right: -6, top: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16, minHeight: 16),
                                  child: Text(
                                    item.badgeCount > 99
                                        ? '99+'
                                        : '${item.badgeCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Poppins',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(item.label,
                          style: TextStyle(
                            fontSize: 10,  // ← KURANGI dari 11
                            fontFamily: 'Poppins',
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: active
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                          overflow: TextOverflow.ellipsis,  // ← TAMBAH overflow handler
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}