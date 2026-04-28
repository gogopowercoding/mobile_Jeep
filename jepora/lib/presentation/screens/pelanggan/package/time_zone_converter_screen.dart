import 'package:flutter/material.dart';
import 'package:jepora/core/theme/app_theme.dart';

/// Widget konversi zona waktu Indonesia + London
/// Tidak perlu backend — murni logika Dart
/// Bisa dipakai sebagai screen standalone atau embed di halaman lain
class TimeZoneConverterScreen extends StatefulWidget {
  const TimeZoneConverterScreen({super.key});

  @override
  State<TimeZoneConverterScreen> createState() =>
      _TimeZoneConverterScreenState();
}

class _TimeZoneConverterScreenState extends State<TimeZoneConverterScreen> {
  final TextEditingController _hourCtrl =
      TextEditingController(text: TimeOfDay.now().hour.toString().padLeft(2, '0'));
  final TextEditingController _minCtrl =
      TextEditingController(text: TimeOfDay.now().minute.toString().padLeft(2, '0'));

  String _fromZone = 'WIB';
  final List<_TimeZoneInfo> _zones = const [
    _TimeZoneInfo('WIB',    'Waktu Indonesia Barat',   7),
    _TimeZoneInfo('WITA',   'Waktu Indonesia Tengah',  8),
    _TimeZoneInfo('WIT',    'Waktu Indonesia Timur',   9),
    _TimeZoneInfo('London', 'British Time (BST/GMT)',  1), // BST (summer +1, winter 0)
  ];

  List<_ConvertedTime> _results = [];

  @override
  void initState() {
    super.initState();
    _convert();
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  void _convert() {
    final hour = int.tryParse(_hourCtrl.text) ?? 0;
    final minute = int.tryParse(_minCtrl.text) ?? 0;

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return;
    }

    final fromInfo = _zones.firstWhere((z) => z.code == _fromZone);
    // Konversi ke UTC dulu
    int utcMinutes = hour * 60 + minute - fromInfo.utcOffset * 60;

    final converted = _zones.map((zone) {
      int localMinutes = (utcMinutes + zone.utcOffset * 60) % (24 * 60);
      if (localMinutes < 0) localMinutes += 24 * 60;
      final h = localMinutes ~/ 60;
      final m = localMinutes % 60;
      return _ConvertedTime(zone: zone, hour: h, minute: m);
    }).toList();

    setState(() => _results = converted);
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Konversi Zona Waktu'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Input card ────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Masukkan Waktu',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                      color: AppColors.textPrimary,
                    )),
                  const SizedBox(height: 16),

                  // Jam : Menit
                  Row(
                    children: [
                      Expanded(
                        child: _TimeField(
                          controller: _hourCtrl,
                          label: 'Jam (0–23)',
                          onChanged: (_) => _convert(),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(':',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          )),
                      ),
                      Expanded(
                        child: _TimeField(
                          controller: _minCtrl,
                          label: 'Menit (0–59)',
                          onChanged: (_) => _convert(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Zona sumber
                  const Text('Dari zona waktu:',
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Poppins',
                      color: AppColors.textSecondary,
                    )),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _zones.map((z) {
                      final selected = _fromZone == z.code;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _fromZone = z.code);
                          _convert();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.divider,
                            ),
                          ),
                          child: Text(z.code,
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            )),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Hasil konversi ────────────────────────────────
            const Text('Hasil Konversi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
                color: AppColors.textPrimary,
              )),
            const SizedBox(height: 12),

            ..._results.map((r) {
              final isSource = r.zone.code == _fromZone;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSource
                      ? AppColors.primaryLight
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSource
                        ? AppColors.primary.withOpacity(0.3)
                        : AppColors.divider,
                    width: isSource ? 1.5 : 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSource
                            ? AppColors.primary
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(r.zone.code,
                          style: TextStyle(
                            fontSize: r.zone.code.length > 3 ? 10 : 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                            color: isSource
                                ? Colors.white
                                : AppColors.primary,
                          )),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.zone.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              color: AppColors.textSecondary,
                            )),
                          Text('UTC ${r.zone.utcOffset >= 0 ? '+' : ''}${r.zone.utcOffset}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'Poppins',
                              color: AppColors.textHint,
                            )),
                        ],
                      ),
                    ),
                    Text(
                      '${_pad(r.hour)}:${_pad(r.minute)}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        color: isSource
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (isSource)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.check_circle_rounded,
                            size: 18, color: AppColors.primary),
                      ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // ── Keterangan ────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(children: [
                    Icon(Icons.info_outline_rounded,
                        size: 14, color: AppColors.textHint),
                    SizedBox(width: 6),
                    Text('Keterangan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        color: AppColors.textSecondary,
                      )),
                  ]),
                  SizedBox(height: 6),
                  Text(
                    'WIB = UTC+7 • WITA = UTC+8 • WIT = UTC+9\n'
                    'London = UTC+1 (BST, April–Oktober) / UTC+0 (GMT, November–Maret)',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'Poppins',
                      color: AppColors.textHint,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Models ───────────────────────────────────────────────────
class _TimeZoneInfo {
  final String code;
  final String name;
  final int utcOffset;
  const _TimeZoneInfo(this.code, this.name, this.utcOffset);
}

class _ConvertedTime {
  final _TimeZoneInfo zone;
  final int hour;
  final int minute;
  const _ConvertedTime({required this.zone, required this.hour, required this.minute});
}

// ─── Text field helper ────────────────────────────────────────
class _TimeField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;

  const _TimeField({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 2,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 11,
          fontFamily: 'Poppins',
          color: AppColors.textHint,
        ),
        counterText: '',
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        fontFamily: 'Poppins',
        color: AppColors.primary,
      ),
    );
  }
}
