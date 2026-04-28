import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/presentation/widgets/common/common_widgets.dart';

class GamesTab extends StatefulWidget {
  const GamesTab({super.key});

  @override
  State<GamesTab> createState() => _GamesTabState();
}

class _GamesTabState extends State<GamesTab> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  int _score = 0;
  int _currentQ = 0;
  bool _answered = false;
  int? _selectedAnswer;
  bool _gameStarted = false;

  // Accelerometer: shake to refresh
  double _lastX = 0, _lastY = 0, _lastZ = 0;

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Kawah belerang terkenal di Dieng bernama?',
      'image': '🌋',
      'options': ['Kawah Ijen', 'Kawah Sikidang', 'Kawah Tangkuban', 'Kawah Bromo'],
      'answer': 1,
      'hint': 'Kawah ini dapat melompat-lompat seperti kijang!',
    },
    {
      'question': 'Bukit yang terkenal untuk melihat golden sunrise di Dieng?',
      'image': '🌄',
      'options': ['Bukit Sikunir', 'Bukit Bintang', 'Bukit Moko', 'Bukit Lawang'],
      'answer': 0,
      'hint': 'Namanya mengandung warna emas dalam bahasa Jawa',
    },
    {
      'question': 'Telaga berwarna-warni di Dieng disebut?',
      'image': '🏞️',
      'options': ['Telaga Sarangan', 'Telaga Menjer', 'Telaga Warna', 'Telaga Ngebel'],
      'answer': 2,
      'hint': 'Airnya bisa berubah warna karena kandungan belerang',
    },
    {
      'question': 'Candi peninggalan Hindu yang ada di Dieng bernama kompleks?',
      'image': '🛕',
      'options': ['Candi Borobudur', 'Candi Arjuna', 'Candi Prambanan', 'Candi Mendut'],
      'answer': 1,
      'hint': 'Nama candi ini diambil dari tokoh pewayangan Mahabharata',
    },
    {
      'question': 'Dieng terletak di ketinggian sekitar berapa mdpl?',
      'image': '⛰️',
      'options': ['1.200 mdpl', '1.800 mdpl', '2.093 mdpl', '2.500 mdpl'],
      'answer': 2,
      'hint': 'Hampir setinggi 2,1 km di atas permukaan laut',
    },
  ];

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300),
    );

    // Sensor accelerometer - shake untuk reset game
    accelerometerEventStream().listen((event) {
      double dx = (event.x - _lastX).abs();
      double dy = (event.y - _lastY).abs();
      double dz = (event.z - _lastZ).abs();
      if (dx + dy + dz > 25 && _gameStarted) {
        _resetGame();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎮 Game di-reset dengan shake!'),
            backgroundColor: AppColors.primary),
        );
      }
      _lastX = event.x; _lastY = event.y; _lastZ = event.z;
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _resetGame() {
    setState(() {
      _score = 0; _currentQ = 0;
      _answered = false; _selectedAnswer = null;
      _gameStarted = false;
    });
  }

  void _answer(int index) {
    if (_answered) return;
    final correct = _questions[_currentQ]['answer'] == index;
    setState(() {
      _answered = true;
      _selectedAnswer = index;
      if (correct) _score += 20;
    });
  }

  void _next() {
    if (_currentQ < _questions.length - 1) {
      setState(() {
        _currentQ++;
        _answered = false;
        _selectedAnswer = null;
      });
    } else {
      setState(() => _gameStarted = false);
      _showResult();
    }
  }

  void _showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_score >= 80 ? '🏆' : _score >= 60 ? '🥈' : '🎯',
              style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 12),
            Text('Skor kamu: $_score/100',
              style: AppTextStyles.h2, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              _score >= 80
                  ? 'Luar biasa! Kamu ahli wisata Dieng! 🎉\nKamu mendapat diskon 10%!'
                  : _score >= 60
                      ? 'Bagus! Terus belajar tentang Dieng!'
                      : 'Jangan menyerah, coba lagi!',
              style: AppTextStyles.bodyMuted,
              textAlign: TextAlign.center,
            ),
            if (_score >= 80) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('KODE DISKON: DIENG10',
                  style: TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.primaryDark,
                    fontFamily: 'Poppins', letterSpacing: 1,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              text: 'Main Lagi',
              onPressed: () { Navigator.pop(context); _resetGame(); },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_gameStarted) return _buildStartScreen();

    final q = _questions[_currentQ];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quiz Wisata Dieng'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Skor: $_score',
                  style: const TextStyle(
                    color: AppColors.primaryDark, fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentQ + 1) / _questions.length,
                backgroundColor: AppColors.divider,
                color: AppColors.primary,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text('${_currentQ + 1}/${_questions.length}',
                style: AppTextStyles.caption),
            ),
            const SizedBox(height: 20),

            // Question card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B8A4C), Color(0xFF39E07A)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(q['image'], style: const TextStyle(fontSize: 50)),
                  const SizedBox(height: 16),
                  Text(q['question'],
                    style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600,
                      color: Colors.white, fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Options
            Expanded(
              child: ListView.separated(
                itemCount: (q['options'] as List).length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final isCorrect = q['answer'] == i;
                  final isSelected = _selectedAnswer == i;

                  Color bgColor = AppColors.surface;
                  Color borderColor = AppColors.divider;
                  Color textColor = AppColors.textPrimary;
                  IconData? trailingIcon;

                  if (_answered) {
                    if (isCorrect) {
                      bgColor = AppColors.success.withOpacity(0.12);
                      borderColor = AppColors.success;
                      textColor = AppColors.success;
                      trailingIcon = Icons.check_circle_rounded;
                    } else if (isSelected) {
                      bgColor = AppColors.error.withOpacity(0.12);
                      borderColor = AppColors.error;
                      textColor = AppColors.error;
                      trailingIcon = Icons.cancel_rounded;
                    }
                  }

                  return GestureDetector(
                    onTap: () => _answer(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                ['A', 'B', 'C', 'D'][i],
                                style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark, fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(q['options'][i],
                              style: TextStyle(
                                fontSize: 14, color: textColor,
                                fontFamily: 'Poppins', fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (trailingIcon != null)
                            Icon(trailingIcon, color: textColor, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_answered) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(q['hint'], style: AppTextStyles.caption)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                text: _currentQ < _questions.length - 1 ? 'Soal Berikutnya →' : 'Lihat Hasil',
                onPressed: _next,
              ),
            ],
            const SizedBox(height: 8),
            Text('💡 Shake HP untuk reset game', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Games')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight, shape: BoxShape.circle,
                ),
                child: const Icon(Icons.quiz_rounded, size: 50, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text('Quiz Wisata Dieng', style: AppTextStyles.h2),
              const SizedBox(height: 8),
              const Text(
                'Uji pengetahuanmu tentang wisata Dieng!\nRaih skor tinggi untuk dapat diskon.',
                style: AppTextStyles.bodyMuted, textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatChip(icon: Icons.help_outline, label: '5 soal'),
                  const SizedBox(width: 10),
                  _StatChip(icon: Icons.star_outline, label: '20 poin/soal'),
                  const SizedBox(width: 10),
                  _StatChip(icon: Icons.card_giftcard, label: 'Diskon 10%'),
                ],
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Mulai Quiz!',
                icon: Icons.play_arrow_rounded,
                onPressed: () => setState(() => _gameStarted = true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primaryDark),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(
            fontSize: 11, color: AppColors.primaryDark,
            fontWeight: FontWeight.w600, fontFamily: 'Poppins',
          )),
        ],
      ),
    );
  }
}
