import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/services/api_services.dart';
import 'package:jepora/presentation/widgets/common/common_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationService>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<NotificationService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (service.unreadCount > 0)
            TextButton(
              onPressed: () => service.markAllRead(),
              child: const Text('Baca Semua',
                style: TextStyle(color: AppColors.primary, fontFamily: 'Poppins')),
            ),
        ],
      ),
      body: service.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : service.notifications.isEmpty
              ? const EmptyState(
                  title: 'Belum ada notifikasi',
                  subtitle: 'Notifikasi booking dan status perjalanan akan muncul di sini',
                  icon: Icons.notifications_none_rounded,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: service.notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final n = service.notifications[i];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: n.isRead ? AppColors.surface : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: n.isRead ? AppColors.divider : AppColors.primary.withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: n.isRead ? AppColors.primaryLight : AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.notifications_rounded,
                              color: n.isRead ? AppColors.primary : Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(n.title,
                                        style: AppTextStyles.label),
                                    ),
                                    if (!n.isRead)
                                      Container(
                                        width: 8, height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary, shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(n.message, style: AppTextStyles.bodyMuted),
                                const SizedBox(height: 6),
                                Text(n.createdAt.split('T').first,
                                  style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
