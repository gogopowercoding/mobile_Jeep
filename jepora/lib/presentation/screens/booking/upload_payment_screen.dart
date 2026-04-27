import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/common/common_widgets.dart';

/// Screen upload bukti pembayaran
/// Route: '/upload-payment', arguments: int orderId
class UploadPaymentScreen extends StatefulWidget {
  const UploadPaymentScreen({super.key});

  @override
  State<UploadPaymentScreen> createState() => _UploadPaymentScreenState();
}

class _UploadPaymentScreenState extends State<UploadPaymentScreen> {
  File? _selectedImage;
  bool _isUploading = false;
  bool _isDone = false;
  String? _errorMsg;
  final ImagePicker _picker = ImagePicker();
  int? _orderId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _orderId = ModalRoute.of(context)?.settings.arguments as int?;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
          _isDone = false;
          _errorMsg = null;
        });
      }
    } catch (e) {
      setState(() => _errorMsg = 'Gagal memilih gambar: $e');
    }
  }

  Future<void> _upload() async {
    if (_selectedImage == null) return;
    if (_orderId == null) {
      setState(() => _errorMsg = 'Order ID tidak valid');
      return;
    }

    setState(() { _isUploading = true; _errorMsg = null; });

    try {
      final formData = FormData.fromMap({
        'order_id': _orderId,
        'payment_proof': await MultipartFile.fromFile(
          _selectedImage!.path,
          filename: 'payment_${_orderId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      final res = await ApiClient().dio.post(
        '/orders/upload-payment',
        data: formData,
      );

      if (!mounted) return;

      if (res.data['success'] == true) {
        setState(() { _isDone = true; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bukti pembayaran berhasil dikirim!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        setState(() => _errorMsg = res.data['message'] ?? 'Upload gagal');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal mengirim bukti pembayaran';
      setState(() => _errorMsg = msg);
    } catch (e) {
      setState(() => _errorMsg = 'Terjadi kesalahan: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Upload Bukti Bayar'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info order ────────────────────────────────────
            if (_orderId != null)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_outlined,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('Order #$_orderId',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: AppColors.primary,
                      )),
                  ],
                ),
              ),

            // ── Transfer info ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Informasi Transfer',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    )),
                  const SizedBox(height: 12),
                  _TransferRow(label: 'Bank',        value: 'BCA'),
                  _TransferRow(label: 'No. Rekening', value: '1234567890'),
                  _TransferRow(label: 'Atas Nama',   value: 'JeepOra Wisata'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Foto preview / picker ─────────────────────────
            const Text('Foto Bukti Pembayaran',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
                color: AppColors.textPrimary,
              )),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: _selectedImage == null ? () => _showPicker() : null,
              child: Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _selectedImage != null
                        ? AppColors.primary
                        : AppColors.divider,
                    width: _selectedImage != null ? 2 : 1,
                    style: _selectedImage == null
                        ? BorderStyle.solid
                        : BorderStyle.solid,
                  ),
                ),
                child: _selectedImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.upload_rounded,
                                size: 28, color: AppColors.primary),
                          ),
                          const SizedBox(height: 12),
                          const Text('Tap untuk pilih foto',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            )),
                          const SizedBox(height: 4),
                          const Text('JPG / PNG, maks 5MB',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              color: AppColors.textHint,
                            )),
                        ],
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.file(_selectedImage!, fit: BoxFit.cover),
                          ),
                          if (_isDone)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Center(
                                child: Icon(Icons.check_circle_rounded,
                                    size: 60, color: Colors.white),
                              ),
                            ),
                          if (!_isDone)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedImage = null),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded,
                                      size: 18, color: AppColors.error),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),

            // Ganti foto / pilih sumber
            if (_selectedImage != null && !_isDone) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('Kamera'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('Galeri'),
                    ),
                  ),
                ],
              ),
            ],

            if (_errorMsg != null) ...[
              const SizedBox(height: 12),
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
                      child: Text(_errorMsg!,
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

            if (_isDone)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 22),
                    SizedBox(width: 8),
                    Text('Bukti pembayaran berhasil dikirim!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: AppColors.success,
                      )),
                  ],
                ),
              )
            else
              PrimaryButton(
                text: _isUploading ? 'Mengirim...' : 'Kirim Bukti Pembayaran',
                isLoading: _isUploading,
                icon: Icons.send_rounded,
                onPressed: _selectedImage != null ? _upload : null,
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showPicker() {
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
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.photo_library_rounded, color: AppColors.primary),
                ),
                title: const Text('Pilih dari Galeri',
                  style: TextStyle(fontFamily: 'Poppins')),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Transfer Row ─────────────────────────────────────────────
class _TransferRow extends StatelessWidget {
  final String label;
  final String value;
  const _TransferRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'Poppins',
                color: AppColors.textSecondary,
              )),
          ),
          const Text(': ',
            style: TextStyle(color: AppColors.textHint)),
          Text(value,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            )),
        ],
      ),
    );
  }
}
