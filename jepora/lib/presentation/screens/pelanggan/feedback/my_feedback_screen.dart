import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/models/feedback_model.dart';
import 'package:jepora/data/services/feedback_service.dart';
import 'package:jepora/presentation/widgets/common/common_widgets.dart';

class MyFeedbackScreen extends StatefulWidget {
  const MyFeedbackScreen({super.key});

  @override
  State<MyFeedbackScreen> createState() => _MyFeedbackScreenState();
}

class _MyFeedbackScreenState extends State<MyFeedbackScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedbackService>().fetchMyFeedback();
    });
  }

  void _confirmDelete(BuildContext context, FeedbackModel fb) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Feedback', style: AppTextStyles.h3),
        content: const Text('Yakin ingin menghapus feedback ini?',
            style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await context.read<FeedbackService>().delete(fb.id);
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Feedback berhasil dihapus'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, FeedbackModel fb) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<FeedbackService>(),
        child: _EditFeedbackSheet(feedback: fb),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<FeedbackService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Feedback Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () => service.fetchMyFeedback(),
          ),
        ],
      ),
      body: service.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : service.myFeedbacks.isEmpty
              ? EmptyState(
                  title: 'Belum ada feedback',
                  subtitle: 'Feedback yang kamu kirim akan muncul di sini',
                  icon: Icons.rate_review_outlined,
                  actionText: 'Kirim Feedback',
                  onAction: () => Navigator.pop(context),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => service.fetchMyFeedback(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: service.myFeedbacks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final fb = service.myFeedbacks[i];
                      return _FeedbackCard(
                        feedback: fb,
                        onEdit: () => _showEditSheet(context, fb),
                        onDelete: () => _confirmDelete(context, fb),
                      );
                    },
                  ),
                ),
    );
  }
}

// ─── FEEDBACK CARD ────────────────────────────────────────────
class _FeedbackCard extends StatelessWidget {
  final FeedbackModel feedback;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FeedbackCard({
    required this.feedback,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw.split('T').first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.rate_review_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feedback.packageName ?? 'Feedback Umum',
                      style: AppTextStyles.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      feedback.bookingDate != null
                          ? 'Trip: ${feedback.bookingDate}'
                          : _formatDate(feedback.createdAt),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              // Menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.textHint, size: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined,
                          color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Text('Edit', style: TextStyle(fontFamily: 'Poppins')),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline_rounded,
                          color: AppColors.error, size: 18),
                      SizedBox(width: 8),
                      Text('Hapus',
                          style: TextStyle(
                              color: AppColors.error,
                              fontFamily: 'Poppins')),
                    ]),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),

          // Bintang
          Row(
            children: [
              ...List.generate(5, (i) => Icon(
                i < feedback.rating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: i < feedback.rating
                    ? AppColors.warning
                    : AppColors.textHint,
                size: 18,
              )),
              const SizedBox(width: 8),
              Text(
                _ratingLabel(feedback.rating),
                style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Pesan
          Text(feedback.message, style: AppTextStyles.body),

          // Tanggal kirim
          const SizedBox(height: 8),
          Text(
            'Dikirim: ${_formatDate(feedback.createdAt)}',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 5: return 'Luar Biasa!';
      case 4: return 'Bagus!';
      case 3: return 'Cukup';
      case 2: return 'Kurang';
      default: return 'Buruk';
    }
  }
}

// ─── BOTTOM SHEET EDIT ────────────────────────────────────────
class _EditFeedbackSheet extends StatefulWidget {
  final FeedbackModel feedback;

  const _EditFeedbackSheet({required this.feedback});

  @override
  State<_EditFeedbackSheet> createState() => _EditFeedbackSheetState();
}

class _EditFeedbackSheetState extends State<_EditFeedbackSheet> {
  late TextEditingController _msgCtrl;
  late int _rating;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _msgCtrl = TextEditingController(text: widget.feedback.message);
    _rating  = widget.feedback.rating;
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_msgCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pesan tidak boleh kosong'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    setState(() => _isLoading = true);
    final ok = await context.read<FeedbackService>().update(
      id:      widget.feedback.id,
      message: _msgCtrl.text.trim(),
      rating:  _rating,
    );
    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Feedback berhasil diperbarui ✅'
            : 'Gagal memperbarui feedback'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                const Expanded(
                  child: Text('Edit Feedback', style: AppTextStyles.h3)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textHint),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Rating
            const Text('Rating', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AnimatedScale(
                      scale: _rating >= i + 1 ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        _rating >= i + 1
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: _rating >= i + 1
                            ? AppColors.warning
                            : AppColors.textHint,
                        size: 32,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Pesan
            const Text('Pesan', style: AppTextStyles.label),
            const SizedBox(height: 8),
            AppTextField(
              hint: 'Tulis ulasan kamu...',
              controller: _msgCtrl,
              maxLines: 4,
            ),
            const SizedBox(height: 20),

            PrimaryButton(
              text: 'Simpan Perubahan',
              isLoading: _isLoading,
              onPressed: _save,
              icon: Icons.save_outlined,
            ),
          ],
        ),
      ),
    );
  }
}