import 'package:flutter/material.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/models/schedule_model.dart';

class PackageItineraryWidget extends StatelessWidget {
  final List<ScheduleModel> schedules;

  const PackageItineraryWidget({
    super.key,
    required this.schedules,
  });

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return const Text(
        'Belum ada jadwal perjalanan',
        style: TextStyle(
          fontSize: 13,
          fontFamily: 'Poppins',
          color: AppColors.textSecondary,
        ),
      );
    }

    // 🔥 Group berdasarkan hari
    final Map<int, List<ScheduleModel>> grouped = {};
    for (var s in schedules) {
      grouped.putIfAbsent(s.dayNumber, () => []).add(s);
    }

    // 🔥 Urutkan hari
    final sortedDays = grouped.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedDays.map((day) {
        final items = grouped[day]!..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Hari ─────────────────────
            Text(
              'Hari $day',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),

            // ── Timeline ────────────────────────
            Column(
              children: items.map((s) {
                return _TimelineItem(schedule: s);
              }).toList(),
            ),

            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }
}

// ─── Timeline Item ───────────────────────────────────────────
class _TimelineItem extends StatelessWidget {
  final ScheduleModel schedule;

  const _TimelineItem({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Garis timeline ────────────────────
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 2,
              height: 50,
              color: AppColors.divider,
            ),
          ],
        ),

        const SizedBox(width: 10),

        // ── Konten ────────────────────────────
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Waktu
                Text(
                  _formatTime(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),

                // Aktivitas
                Text(
                  schedule.activity,
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'Poppins',
                    color: AppColors.textPrimary,
                  ),
                ),

                // Optional label
                if (schedule.isOptional)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      '(Opsional)',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'Poppins',
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 🔥 Format waktu
  String _formatTime() {
    if (schedule.endTime != null && schedule.endTime!.isNotEmpty) {
      return '${_short(schedule.startTime)} - ${_short(schedule.endTime!)}';
    }
    return _short(schedule.startTime);
  }

  String _short(String time) {
    // dari 07:00:00 → 07:00
    return time.length >= 5 ? time.substring(0, 5) : time;
  }
}