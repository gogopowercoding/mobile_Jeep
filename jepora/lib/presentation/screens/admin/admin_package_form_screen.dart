import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/models.dart';
import '../../../data/services/api_services.dart';
import '../../widgets/common/common_widgets.dart';

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
        // Refresh list paket
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
              const SizedBox(height: 24),
            ],
          ),
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
