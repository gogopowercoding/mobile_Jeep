import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:jepora/data/models/models.dart';
import '../../../core/network/api_client.dart';

class AdminScheduleForm extends StatefulWidget {
  const AdminScheduleForm({super.key});

  @override
  State<AdminScheduleForm> createState() => _AdminScheduleFormState();
}

class _AdminScheduleFormState extends State<AdminScheduleForm> {
  final _activityCtrl = TextEditingController();

  TimeOfDay? startTime;
  TimeOfDay? endTime;

  int dayNumber = 1;
  ScheduleModel? editData;
  int? packageId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    packageId = args['packageId'];
    editData = args['schedule'];

    if (editData != null) {
      _activityCtrl.text = editData!.activity;

      startTime = _parseTime(editData!.startTime);
      endTime =
          editData!.endTime != null ? _parseTime(editData!.endTime!) : null;

      dayNumber = editData!.dayNumber;
    }
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _format(TimeOfDay t) {
    return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00";
  }

  Future<void> _submit() async {
    final data = {
      "package_id": packageId,
      "day_number": dayNumber,
      "start_time": _format(startTime!),
      "end_time": endTime != null ? _format(endTime!) : null,
      "activity": _activityCtrl.text,
      "is_optional": 0,
      "sort_order": 0
    };

    if (editData == null) {
      await ApiClient().dio.post('/package-schedules', data: data);
    } else {
      await ApiClient()
          .dio
          .put('/package-schedules/${editData!.id}', data: data);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _pickTime(bool isStart) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (t != null) {
      setState(() {
        if (isStart) {
          startTime = t;
        } else {
          endTime = t;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(editData == null ? 'Tambah Jadwal' : 'Edit Jadwal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _activityCtrl,
              decoration: const InputDecoration(labelText: 'Aktivitas'),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _pickTime(true),
                    child: Text(startTime == null
                        ? 'Start'
                        : '${startTime!.format(context)}'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _pickTime(false),
                    child: Text(endTime == null
                        ? 'End'
                        : '${endTime!.format(context)}'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            DropdownButton<int>(
              value: dayNumber,
              items: List.generate(5, (i) => i + 1)
                  .map((e) =>
                      DropdownMenuItem(value: e, child: Text('Hari $e')))
                  .toList(),
              onChanged: (v) => setState(() => dayNumber = v!),
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: _submit,
              child: const Text('Simpan'),
            )
          ],
        ),
      ),
    );
  }
}