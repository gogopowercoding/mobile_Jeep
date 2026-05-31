import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/controllers/notification_controller.dart';
import 'package:jepora/presentation/widgets/common/common_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationController _controller = Get.find<NotificationController>();

  String _formatDate(DateTime dateTime) {
    final dt = dateTime.toLocal();
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$day/$month/${dt.year}';
  }

  @override
  void initState() {
    super.initState();
    _controller.fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final notifications = _controller.notifications;
      final unreadCount = _controller.unreadCount;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Notifikasi'),
          actions: [
            if (unreadCount > 0)
              TextButton(
                onPressed: _controller.markAllRead,
                child: const Text(
                  'Baca Semua',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
              onPressed: _controller.fetchNotifications,
            ),
          ],
        ),
        body: _controller.isLoading.value
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : notifications.isEmpty
                ? const EmptyState(
                    title: 'Belum ada notifikasi',
                    subtitle:
                        'Notifikasi booking dan status perjalanan akan muncul di sini',
                    icon: Icons.notifications_none_rounded,
                  )
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _controller.fetchNotifications,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final n = notifications[i];
                        return GestureDetector(
                          onTap: () {
                            if (!n.isRead) _controller.markAsRead(n.id);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: n.isRead
                                  ? AppColors.surface
                                  : AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: n.isRead
                                    ? AppColors.divider
                                    : AppColors.primary.withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: n.isRead
                                        ? AppColors.primaryLight
                                        : AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.notifications_rounded,
                                    color: n.isRead
                                        ? AppColors.primary
                                        : Colors.white,
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
                                            child: Text(
                                              n.title,
                                              style: AppTextStyles.label,
                                            ),
                                          ),
                                          if (!n.isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: AppColors.primary,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(n.message,
                                          style: AppTextStyles.bodyMuted),
                                      const SizedBox(height: 6),
                                      Text(_formatDate(n.createdAt),
                                          style: AppTextStyles.caption),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      );
    });
  }
}
