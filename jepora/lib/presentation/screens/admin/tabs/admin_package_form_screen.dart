import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/models/models.dart';
import '../../../../data/services/api_services.dart';
import '../../../widgets/common/common_widgets.dart';

/// Form tambah / edit paket wisata untuk admin
/// Route: '/admin/package-form'
/// arguments: PackageModel? (null = mode tambah, ada isi = mode edit)
class AdminPackageFormScreen extends StatefulWidget {
  const AdminPackageFormScreen({super.key});

  @override
  State<AdminPackageFormScreen> createState() => _AdminPackageFormScreenState();
}

class _AdminPackageFormScreenState extends State<AdminPackageFormScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _priceCtrl    = TextEditingController();
  final _durationCtrl = TextEditingController();

  PackageModel? _editPackage;
  File? _selectedImage;
  bool _isSubmitting = false;
  String? _error;
  bool get _isEdit => _editPackage != null;

  // ── Schedule state ──────────────────────────────────────────
  List<ScheduleModel> _schedules = [];
  bool _schedulesLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pkg = ModalRoute.of(context)?.settings.arguments as PackageModel?;
    if (pkg != null && _editPackage == null) {
      _editPackage = pkg;
      _nameCtrl.text     = pkg.name;
      _descCtrl.text     = pkg.description ?? '';
      _priceCtrl.text    = pkg.price.toStringAsFixed(0);
      _durationCtrl.text = pkg.duration.toString();

      // Load jadwal dari DB saat mode edit
      _loadSchedules(pkg.id);
    }
  }

  Future<void> _loadSchedules(int packageId) async {
    setState(() => _schedulesLoading = true);
    try {
      // Gunakan fetchPackageById karena endpoint /packages/:id
      // sudah include schedules dalam response (sama seperti screen pelanggan)
      final pkg = await context.read<PackageService>().fetchPackageById(packageId);
      if (mounted) {
        setState(() => _schedules = pkg?.schedules ?? []);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _schedulesLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                ),
                title: const Text('Ambil dari Kamera',
                  style: TextStyle(fontFamily: 'Poppins')),
                onTap: () async {
                  Navigator.pop(context);
                  final p = await picker.pickImage(
                      source: ImageSource.camera, imageQuality: 80);
                  if (p != null && mounted) {
                    setState(() => _selectedImage = File(p.path));
                  }
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.photo_library_rounded, color: AppColors.primary),
                ),
                title: const Text('Pilih dari Galeri',
                  style: TextStyle(fontFamily: 'Poppins')),
                onTap: () async {
                  Navigator.pop(context);
                  final p = await picker.pickImage(
                      source: ImageSource.gallery, imageQuality: 80);
                  if (p != null && mounted) {
                    setState(() => _selectedImage = File(p.path));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isSubmitting = true; _error = null; });

    try {
      final formData = FormData.fromMap({
        'name':        _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price':       double.parse(_priceCtrl.text.trim()),
        'duration':    int.parse(_durationCtrl.text.trim()),
        if (_selectedImage != null)
          'image': await MultipartFile.fromFile(
            _selectedImage!.path,
            filename: 'package_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
      });

      late final dynamic res;
      if (_isEdit) {
        res = await ApiClient().dio.put(
          '/packages/${_editPackage!.id}',
          data: formData,
        );
      } else {
        res = await ApiClient().dio.post('/packages', data: formData);
      }

      if (!mounted) return;

      if (res.data['success'] == true) {
        await context.read<PackageService>().fetchPackages();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit
                ? 'Paket berhasil diperbarui!'
                : 'Paket baru berhasil ditambahkan!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        setState(() => _error = res.data['message'] ?? 'Gagal menyimpan paket');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Terjadi kesalahan jaringan';
      setState(() => _error = msg);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // ── Schedule CRUD helpers ────────────────────────────────────

  /// Buka bottom sheet form tambah / edit jadwal, inline di halaman ini
  Future<void> _openScheduleSheet({ScheduleModel? existing}) async {
    if (_editPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Simpan paket terlebih dahulu sebelum menambah jadwal'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleSheet(
        packageId: _editPackage!.id,
        existing: existing,
      ),
    );

    if (result == true) {
      await _loadSchedules(_editPackage!.id);
    }
  }

  Future<void> _deleteSchedule(ScheduleModel s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Jadwal',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        content: Text('Hapus jadwal "${s.activity}"?',
          style: const TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal',
              style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus',
              style: TextStyle(fontFamily: 'Poppins', color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await context.read<PackageService>().deleteSchedule(s.id, _editPackage!.id);
      await _loadSchedules(_editPackage!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Paket' : 'Tambah Paket'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Foto paket ─────────────────────────────────
              const Text('Foto Paket',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  color: AppColors.textPrimary,
                )),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _selectedImage != null
                          ? AppColors.primary
                          : AppColors.divider,
                      width: _selectedImage != null ? 2 : 1,
                    ),
                  ),
                  child: _selectedImage != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: Image.file(_selectedImage!,
                                  fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 8, right: 8,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedImage = null),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded,
                                      size: 16, color: AppColors.error),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_photo_alternate_outlined,
                                  color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _isEdit && _editPackage?.image != null
                                  ? 'Tap untuk ganti foto'
                                  : 'Tap untuk tambah foto',
                              style: const TextStyle(
                                fontSize: 13,
                                fontFamily: 'Poppins',
                                color: AppColors.textHint,
                              )),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Nama paket ─────────────────────────────────
              _FormLabel('Nama Paket'),
              const SizedBox(height: 8),
              _FormField(
                controller: _nameCtrl,
                hint: 'Contoh: Paket Dieng Sunrise',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Nama paket wajib diisi' : null,
              ),

              const SizedBox(height: 16),

              // ── Deskripsi ──────────────────────────────────
              _FormLabel('Deskripsi'),
              const SizedBox(height: 8),
              _FormField(
                controller: _descCtrl,
                hint: 'Deskripsi singkat paket wisata...',
                maxLines: 4,
              ),

              const SizedBox(height: 16),

              // ── Harga & Durasi (row) ───────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FormLabel('Harga (Rp)'),
                        const SizedBox(height: 8),
                        _FormField(
                          controller: _priceCtrl,
                          hint: 'Contoh: 350000',
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Isi harga';
                            if (double.tryParse(v) == null) return 'Angka saja';
                            return null;
                          },
                          prefix: const Text('Rp ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              fontFamily: 'Poppins',
                            )),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FormLabel('Durasi (jam)'),
                        const SizedBox(height: 8),
                        _FormField(
                          controller: _durationCtrl,
                          hint: 'Contoh: 4',
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Isi durasi';
                            if (int.tryParse(v) == null) return 'Angka bulat';
                            return null;
                          },
                          suffix: const Text(' jam',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textHint,
                              fontFamily: 'Poppins',
                            )),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Error ──────────────────────────────────────
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            color: AppColors.error,
                          )),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              PrimaryButton(
                text: _isEdit ? 'Simpan Perubahan' : 'Tambah Paket',
                isLoading: _isSubmitting,
                icon: _isEdit
                    ? Icons.save_rounded
                    : Icons.add_circle_outline_rounded,
                onPressed: _submit,
              ),

              // ── Divider ────────────────────────────────────
              const SizedBox(height: 32),
              const Divider(thickness: 1, color: AppColors.divider),
              const SizedBox(height: 20),

              // ── Jadwal section ─────────────────────────────
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Jadwal Paket',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _openScheduleSheet(),
                    icon: const Icon(Icons.add_rounded, size: 18,
                        color: AppColors.primary),
                    label: const Text(
                      'Tambah',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      backgroundColor: AppColors.primaryLight,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),

              if (!_isEdit) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline_rounded,
                          size: 16, color: AppColors.textHint),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Simpan paket terlebih dahulu untuk dapat menambah jadwal.',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_isEdit) ...[
                const SizedBox(height: 12),
                if (_schedulesLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2),
                    ),
                  )
                else if (_schedules.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 36, color: AppColors.textHint),
                        SizedBox(height: 8),
                        Text(
                          'Belum ada jadwal',
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'Poppins',
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _schedules.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final s = _schedules[i];
                      return _ScheduleTile(
                        schedule: s,
                        onEdit: () => _openScheduleSheet(existing: s),
                        onDelete: () => _deleteSchedule(s),
                      );
                    },
                  ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Schedule Tile ────────────────────────────────────────────
class _ScheduleTile extends StatelessWidget {
  final ScheduleModel schedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ScheduleTile({
    required this.schedule,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final timeLabel = schedule.endTime != null
        ? '${schedule.startTime.substring(0, 5)} – ${schedule.endTime!.substring(0, 5)}'
        : schedule.startTime.substring(0, 5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                'H${schedule.dayNumber}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.activity,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 12, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'Poppins',
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded,
                size: 18, color: AppColors.primary),
            onPressed: onEdit,
            splashRadius: 20,
            tooltip: 'Edit jadwal',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 18, color: AppColors.error),
            onPressed: onDelete,
            splashRadius: 20,
            tooltip: 'Hapus jadwal',
          ),
        ],
      ),
    );
  }
}

// ─── Schedule Bottom Sheet ────────────────────────────────────
class _ScheduleSheet extends StatefulWidget {
  final int packageId;
  final ScheduleModel? existing;

  const _ScheduleSheet({required this.packageId, this.existing});

  @override
  State<_ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<_ScheduleSheet> {
  final _activityCtrl = TextEditingController();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int _dayNumber = 1;
  bool _isSaving = false;
  String? _sheetError;

  bool get _isEditMode => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _activityCtrl.text = e.activity;
      _startTime = _parseTime(e.startTime);
      _endTime = e.endTime != null ? _parseTime(e.endTime!) : null;
      _dayNumber = e.dayNumber;
    }
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(
        hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _pickTime(bool isStart) async {
    final t = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_startTime ?? TimeOfDay.now())
          : (_endTime ?? TimeOfDay.now()),
    );
    if (t != null) {
      setState(() {
        if (isStart) {
          _startTime = t;
        } else {
          _endTime = t;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_activityCtrl.text.trim().isEmpty) {
      setState(() => _sheetError = 'Aktivitas wajib diisi');
      return;
    }
    if (_startTime == null) {
      setState(() => _sheetError = 'Waktu mulai wajib dipilih');
      return;
    }

    setState(() { _isSaving = true; _sheetError = null; });

    final data = {
      'package_id': widget.packageId,
      'day_number': _dayNumber,
      'start_time': _formatTime(_startTime!),
      'end_time':   _endTime != null ? _formatTime(_endTime!) : null,
      'activity':   _activityCtrl.text.trim(),
      'is_optional': 0,
      'sort_order':  0,
    };

    try {
      bool ok;
      if (_isEditMode) {
        ok = await context
            .read<PackageService>()
            .updateSchedule(widget.existing!.id, data);
      } else {
        ok = await context.read<PackageService>().createSchedule(data);
      }

      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, true);
      } else {
        setState(() => _sheetError = 'Gagal menyimpan jadwal');
      }
    } catch (e) {
      setState(() => _sheetError = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _activityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPad),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            _isEditMode ? 'Edit Jadwal' : 'Tambah Jadwal',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Aktivitas
          const Text('Aktivitas',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: AppColors.textPrimary,
            )),
          const SizedBox(height: 6),
          TextFormField(
            controller: _activityCtrl,
            style: const TextStyle(
                fontSize: 14, fontFamily: 'Poppins', color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Contoh: Melihat Kawah Sikidang',
              hintStyle: const TextStyle(
                  fontSize: 13, fontFamily: 'Poppins', color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),

          const SizedBox(height: 14),

          // Waktu mulai & selesai
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Waktu Mulai',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: AppColors.textPrimary,
                      )),
                    const SizedBox(height: 6),
                    _TimeButton(
                      label: _startTime?.format(context) ?? 'Pilih waktu',
                      hasValue: _startTime != null,
                      onTap: () => _pickTime(true),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Waktu Selesai',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: AppColors.textPrimary,
                      )),
                    const SizedBox(height: 6),
                    _TimeButton(
                      label: _endTime?.format(context) ?? 'Opsional',
                      hasValue: _endTime != null,
                      onTap: () => _pickTime(false),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Hari ke-
          const Text('Hari ke-',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: AppColors.textPrimary,
            )),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _dayNumber,
                isExpanded: true,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  color: AppColors.textPrimary,
                ),
                items: List.generate(7, (i) => i + 1)
                    .map((d) => DropdownMenuItem(
                          value: d,
                          child: Text('Hari $d'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _dayNumber = v!),
              ),
            ),
          ),

          // Error
          if (_sheetError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 14, color: AppColors.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_sheetError!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        color: AppColors.error,
                      )),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(
                      _isEditMode ? 'Simpan Perubahan' : 'Tambah Jadwal',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      )),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final bool hasValue;
  final VoidCallback onTap;

  const _TimeButton({
    required this.label,
    required this.hasValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: hasValue ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 16,
              color: hasValue ? AppColors.primary : AppColors.textHint,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  color: hasValue ? AppColors.primary : AppColors.textHint,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────
class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
        color: AppColors.textPrimary,
      ));
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;
  final FormFieldValidator<String>? validator;
  final Widget? prefix;
  final Widget? suffix;

  const _FormField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixText: null,
        prefix: prefix,
        suffix: suffix,
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(
          fontSize: 13,
          fontFamily: 'Poppins',
          color: AppColors.textHint,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      style: const TextStyle(
        fontSize: 14,
        fontFamily: 'Poppins',
        color: AppColors.textPrimary,
      ),
    );
  }
}