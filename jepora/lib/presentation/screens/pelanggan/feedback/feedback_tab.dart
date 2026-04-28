import 'package:flutter/material.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/services/api_services.dart';
import 'package:jepora/presentation/widgets/common/common_widgets.dart';

class FeedbackTab extends StatefulWidget {
  const FeedbackTab({super.key});

  @override
  State<FeedbackTab> createState() => _FeedbackTabState();
}

class _FeedbackTabState extends State<FeedbackTab> {
  final _messageCtrl = TextEditingController();
  int _rating = 5;
  bool _isLoading = false;
  bool _submitted = false;

  Future<void> _submit() async {
    if (_messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesan feedback tidak boleh kosong'),
          backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _isLoading = true);
    final ok = await FeedbackService.submit(
      message: _messageCtrl.text.trim(),
      rating: _rating,
    );
    setState(() { _isLoading = false; _submitted = ok; });
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terima kasih atas feedback kamu! 🙏'),
          backgroundColor: AppColors.success),
      );
      _messageCtrl.clear();
      setState(() { _rating = 5; _submitted = false; });
    }
  }

  @override
  void dispose() { _messageCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Feedback')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B8A4C), Color(0xFF39E07A)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💬', style: TextStyle(fontSize: 36)),
                  SizedBox(height: 8),
                  Text('Bagaimana pengalamanmu?',
                    style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: Colors.white, fontFamily: 'Poppins',
                    )),
                  SizedBox(height: 4),
                  Text('Ceritakan pengalaman wisata Dieng kamu',
                    style: TextStyle(
                      fontSize: 13, color: Colors.white70, fontFamily: 'Poppins',
                    )),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('Rating', style: AppTextStyles.label),
            const SizedBox(height: 10),
            Row(
              children: List.generate(5, (i) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AnimatedScale(
                      scale: _rating >= i + 1 ? 1.2 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        _rating >= i + 1 ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: _rating >= i + 1 ? AppColors.warning : AppColors.textHint,
                        size: 36,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            Text(
              _rating == 5 ? '⭐ Luar Biasa!'
                  : _rating == 4 ? '😊 Bagus!'
                  : _rating == 3 ? '😐 Cukup'
                  : _rating == 2 ? '😕 Kurang'
                  : '😞 Buruk',
              style: AppTextStyles.bodyMuted,
            ),

            const SizedBox(height: 20),
            const Text('Pesan', style: AppTextStyles.label),
            const SizedBox(height: 8),
            AppTextField(
              hint: 'Tulis pengalaman, saran, atau kritikmu di sini...',
              controller: _messageCtrl,
              maxLines: 5,
            ),

            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Kirim Feedback',
              isLoading: _isLoading,
              onPressed: _submit,
              icon: Icons.send_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
