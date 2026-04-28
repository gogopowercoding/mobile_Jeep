import 'package:flutter/material.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/models/schedule_model.dart';

// ── Definisi zona waktu ──────────────────────────────────────
class _Zone {
  final String label;
  final int offsetFromWIB;
  const _Zone(this.label, this.offsetFromWIB);
}

const List<_Zone> _zones = [
  _Zone('WIB',    0),
  _Zone('WITA',   1),
  _Zone('WIT',    2),
  _Zone('London', -6), // UTC+1, selisih -6 dari WIB (UTC+7)
];

// ── Helper konversi waktu ────────────────────────────────────
String _short(String time) =>
    time.length >= 5 ? time.substring(0, 5) : time;

String _convertTime(String time, int offsetFromWIB) {
  final s = _short(time);
  final parts = s.split(':');
  if (parts.length < 2) return s;
  int h = (int.tryParse(parts[0]) ?? 0) + offsetFromWIB;
  h = ((h % 24) + 24) % 24;
  return '${h.toString().padLeft(2, '0')}:${parts[1]}';
}

String _buildTime(ScheduleModel schedule, int offset) {
  final start = _convertTime(schedule.startTime, offset);
  final hasEnd = schedule.endTime != null && schedule.endTime!.isNotEmpty;
  if (!hasEnd) return start;
  return '$start–${_convertTime(schedule.endTime!, offset)}';
}

// ─── Widget utama (Stateful — menyimpan zona aktif) ──────────
class PackageItineraryWidget extends StatefulWidget {
  final List<ScheduleModel> schedules;
  const PackageItineraryWidget({super.key, required this.schedules});

  @override
  State<PackageItineraryWidget> createState() => _PackageItineraryWidgetState();
}

class _PackageItineraryWidgetState extends State<PackageItineraryWidget> {
  _Zone _activeZone = _zones[0]; // default WIB
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.schedules.isEmpty) {
      return const Text(
        'Belum ada jadwal perjalanan',
        style: TextStyle(fontSize: 13, fontFamily: 'Poppins', color: AppColors.textSecondary),
      );
    }

    final Map<int, List<ScheduleModel>> grouped = {};
    for (var s in widget.schedules) {
      grouped.putIfAbsent(s.dayNumber, () => []).add(s);
    }
    final sortedDays = grouped.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Toggle zona — SATU di atas, semua item ikut ───────
        _ZoneToggle(
          activeZone: _activeZone,
          expanded: _expanded,
          onToggle: () => setState(() => _expanded = !_expanded),
          onSelect: (z) => setState(() { _activeZone = z; _expanded = false; }),
        ),

        const SizedBox(height: 12),

        // ── Timeline per hari ─────────────────────────────────
        ...sortedDays.map((day) {
          final items = grouped[day]!..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hari $day',
                style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins', color: AppColors.primary,
                )),
              const SizedBox(height: 8),
              ...items.map((s) => _TimelineItem(schedule: s, activeZone: _activeZone)),
              const SizedBox(height: 16),
            ],
          );
        }),
      ],
    );
  }
}

// ─── Toggle zona (di atas jadwal) ────────────────────────────
class _ZoneToggle extends StatelessWidget {
  final _Zone activeZone;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<_Zone> onSelect;

  const _ZoneToggle({
    required this.activeZone,
    required this.expanded,
    required this.onToggle,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Baris zona aktif + tombol ganti
        Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              'Zona waktu: ${activeZone.label}',
              style: const TextStyle(
                fontSize: 12, fontFamily: 'Poppins',
                color: AppColors.textSecondary, fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onToggle,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ganti',
                      style: const TextStyle(
                        fontSize: 11, fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600, color: AppColors.primary,
                      )),
                    const SizedBox(width: 2),
                    Icon(
                      expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      size: 14, color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Panel pilih zona
        if (expanded) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _zones.map((z) {
              final isActive = z.label == activeZone.label;
              return GestureDetector(
                onTap: () => onSelect(z),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? AppColors.primary : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    z.label,
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                      color: isActive ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

// ─── Timeline Item ────────────────────────────────────────────
class _TimelineItem extends StatelessWidget {
  final ScheduleModel schedule;
  final _Zone activeZone;

  const _TimelineItem({required this.schedule, required this.activeZone});

  @override
  Widget build(BuildContext context) {
    final timeStr = _buildTime(schedule, activeZone.offsetFromWIB);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Garis timeline
        Column(
          children: [
            Container(
              width: 10, height: 10,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            ),
            Container(width: 2, height: 50, color: AppColors.divider),
          ],
        ),
        const SizedBox(width: 10),

        // Konten
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
                Text(schedule.activity,
                  style: const TextStyle(
                    fontSize: 13, fontFamily: 'Poppins',
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600,
                  )),
                const SizedBox(height: 5),

                // Badge waktu sesuai zona aktif
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    '$timeStr ${activeZone.label}',
                    style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins', color: AppColors.primary,
                    ),
                  ),
                ),

                if (schedule.isOptional)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('(Opsional)',
                      style: TextStyle(
                        fontSize: 11, fontFamily: 'Poppins',
                        color: AppColors.textSecondary, fontStyle: FontStyle.italic,
                      )),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}