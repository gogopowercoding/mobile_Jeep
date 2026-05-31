import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/controllers/notification_controller.dart';
import 'package:jepora/data/models/models.dart';
import 'package:jepora/presentation/widgets/common/common_widgets.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final NotificationController _controller = Get.find<NotificationController>();

  @override
  void initState() {
    super.initState();
    _controller.fetchNotifications();
  }

  IconData _getIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('pesanan baru') || t.contains('booking')) {
      return Icons.shopping_bag_outlined;
    }
    if (t.contains('pembayaran') || t.contains('bayar')) {
      return Icons.payments_outlined;
    }
    if (t.contains('menolak') || t.contains('tolak')) {
      return Icons.cancel_outlined;
    }
    if (t.contains('menerima') || t.contains('terima') || t.contains('acc')) {
      return Icons.check_circle_outline_rounded;
    }
    if (t.contains('selesai')) return Icons.flag_outlined;
    if (t.contains('berjalan') || t.contains('ongoing')) {
      return Icons.directions_car_outlined;
    }
    return Icons.notifications_outlined;
  }

  Color _getColor(String title) {
    final t = title.toLowerCase();
    if (t.contains('pesanan baru') || t.contains('booking')) {
      return AppColors.statusPending;
    }
    if (t.contains('pembayaran') || t.contains('bayar')) {
      return AppColors.statusConfirmed;
    }
    if (t.contains('menolak') || t.contains('tolak')) return AppColors.error;
    if (t.contains('menerima') || t.contains('terima') || t.contains('acc')) {
      return AppColors.success;
    }
    if (t.contains('selesai')) return AppColors.statusCompleted;
    if (t.contains('berjalan') || t.contains('ongoing')) {
      return AppColors.statusOngoing;
    }
    return AppColors.primary;
  }

  String _formatTime(DateTime createdAt) {
    final dt = createdAt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';

    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$day/$month/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final unreadCount = _controller.unreadCount;
      final notifications = _controller.notifications;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Row(
            children: [
              const Text('Notifikasi Admin'),
              if (unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$unreadCount baru',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ],
          ),
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
                        'Notifikasi pesanan, pembayaran, dan aktivitas sopir akan muncul di sini',
                    icon: Icons.notifications_none_rounded,
                  )
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _controller.fetchNotifications,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      itemBuilder: (ctx, i) {
                        final notif = notifications[i];
                        final color = _getColor(notif.title);
                        final icon = _getIcon(notif.title);

                        return _NotifCard(
                          notif: notif,
                          color: color,
                          icon: icon,
                          timeLabel: _formatTime(notif.createdAt),
                          onTap: () {
                            if (!notif.isRead) {
                              _controller.markAsRead(notif.id);
                            }
                          },
                        );
                      },
                    ),
                  ),
      );
    });
  }
}

class _NotifCard extends StatelessWidget {
  final NotificationModel notif;
  final Color color;
  final IconData icon;
  final String timeLabel;
  final VoidCallback onTap;

  const _NotifCard({
    required this.notif,
    required this.color,
    required this.icon,
    required this.timeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead ? AppColors.surface : color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notif.isRead ? AppColors.divider : color.withOpacity(0.35),
            width: notif.isRead ? 0.5 : 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(notif.isRead ? 0.1 : 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
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
                          notif.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                notif.isRead ? FontWeight.w500 : FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(notif.message, style: AppTextStyles.bodyMuted),
                  const SizedBox(height: 8),
                  Text(timeLabel, style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
