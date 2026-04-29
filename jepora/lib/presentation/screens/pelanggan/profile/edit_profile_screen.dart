import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:jepora/core/constants/app_constants.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/services/auth_service.dart';
import 'package:jepora/presentation/widgets/common/common_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  bool _changePassword = false;

  File? _pickedAvatar;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().user;
    if (user != null) {
      _nameCtrl.text  = user.name;
      _phoneCtrl.text = user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _oldPassCtrl.dispose(); _newPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked != null) {
      setState(() => _pickedAvatar = File(picked.path));
    }
  }

  void _showImageSourceSheet() {
    final hasExisting = _pickedAvatar != null ||
        context.read<AuthService>().user?.avatar != null;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text('Pilih Foto Profil',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.photo_library_rounded, color: AppColors.primary),
                ),
                title: const Text('Pilih dari Galeri', style: AppTextStyles.body),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                ),
                title: const Text('Ambil Foto', style: AppTextStyles.body),
                onTap: () => _pickImage(ImageSource.camera),
              ),
              if (hasExisting)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFEBEB),
                    child: Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  ),
                  title: const Text('Hapus Foto', style: AppTextStyles.body),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _pickedAvatar = null);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();

    final ok = await auth.updateProfile(
      name:        _nameCtrl.text.trim(),
      phone:       _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      oldPassword: _changePassword ? _oldPassCtrl.text : null,
      newPassword: _changePassword ? _newPassCtrl.text : null,
      avatarFile:  _pickedAvatar,
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui ✅'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Gagal memperbarui profil'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildAvatar(AuthService auth) {
    final String? serverAvatar = auth.user?.avatar;
    final String baseUrl = AppConstants.baseUrl.replaceAll('/api', '');

    ImageProvider? bgImage;
    if (_pickedAvatar != null) {
      bgImage = FileImage(_pickedAvatar!);
    } else if (serverAvatar != null && serverAvatar.isNotEmpty) {
      bgImage = NetworkImage('$baseUrl/uploads/$serverAvatar');
    }

    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: bgImage,
            child: bgImage == null
                ? Text(
                    auth.user?.name.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      fontSize: 40, fontWeight: FontWeight.w700,
                      color: AppColors.primary, fontFamily: 'Poppins',
                    ),
                  )
                : null,
          ),
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Edit Profil')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _buildAvatar(auth)),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _showImageSourceSheet,
                  icon: const Icon(Icons.edit_rounded, size: 14),
                  label: const Text('Ganti Foto Profil',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                ),
              ),
              const SizedBox(height: 20),

              const Text('Nama Lengkap', style: AppTextStyles.label),
              const SizedBox(height: 8),
              AppTextField(
                hint: 'Masukkan nama lengkap',
                controller: _nameCtrl,
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              const Text('Nomor Telepon', style: AppTextStyles.label),
              const SizedBox(height: 8),
              AppTextField(
                hint: 'Masukkan nomor telepon',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: () => setState(() {
                  _changePassword = !_changePassword;
                  if (!_changePassword) {
                    _oldPassCtrl.clear();
                    _newPassCtrl.clear();
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _changePassword ? AppColors.primaryLight : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _changePassword ? AppColors.primary : AppColors.divider,
                      width: _changePassword ? 1.5 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline_rounded,
                        color: _changePassword ? AppColors.primary : AppColors.textHint),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Ganti Password', style: AppTextStyles.label),
                      ),
                      Icon(
                        _changePassword
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textHint,
                      ),
                    ],
                  ),
                ),
              ),

              if (_changePassword) ...[
                const SizedBox(height: 14),
                AppTextField(
                  hint: 'Password lama',
                  controller: _oldPassCtrl,
                  isPassword: true,
                  prefixIcon: Icons.lock_outlined,
                  validator: (v) {
                    if (_changePassword && (v == null || v.isEmpty)) {
                      return 'Password lama wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  hint: 'Password baru (min. 6 karakter)',
                  controller: _newPassCtrl,
                  isPassword: true,
                  prefixIcon: Icons.lock_reset_outlined,
                  validator: (v) {
                    if (_changePassword) {
                      if (v == null || v.isEmpty) return 'Password baru wajib diisi';
                      if (v.length < 6) return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 28),
              PrimaryButton(
                text: 'Simpan Perubahan',
                isLoading: auth.isLoading,
                onPressed: _save,
                icon: Icons.save_outlined,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}