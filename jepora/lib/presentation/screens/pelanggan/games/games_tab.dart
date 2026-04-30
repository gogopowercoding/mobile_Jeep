import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:jepora/core/theme/app_theme.dart';
import 'package:jepora/data/services/game_service.dart';
import 'package:jepora/data/models/game_model.dart';
import 'package:jepora/presentation/widgets/common/common_widgets.dart';

// ─── DATA KARTU ──────────────────────────────────────────────
class _CardData {
  final String emoji;
  final String name;
  final int pairId;
  bool isFlipped;
  bool isMatched;

  _CardData({
    required this.emoji,
    required this.name,
    required this.pairId,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

// 8 tempat wisata Dieng
const _destinations = [
  {'emoji': '🌋', 'name': 'Kawah\nSikidang'},
  {'emoji': '🌄', 'name': 'Sikunir\nSunrise'},
  {'emoji': '🏞️', 'name': 'Telaga\nWarna'},
  {'emoji': '🛕', 'name': 'Candi\nArjuna'},
  {'emoji': '🍵', 'name': 'Kebun\nTeh'},
  {'emoji': '🌊', 'name': 'Air Terjun\nSikarim'},
  {'emoji': '⛰️', 'name': 'Batu\nRatapan'},
  {'emoji': '🏔️', 'name': 'Swiss\nVan Java'},
];

// ─── DIFFICULTY CONFIG ───────────────────────────────────────
class _DiffConfig {
  final String label;
  final int gridSize;   // jumlah kartu total (harus genap)
  final int maxTime;    // detik untuk dapat reward
  final Color color;

  const _DiffConfig({
    required this.label,
    required this.gridSize,
    required this.maxTime,
    required this.color,
  });
}

const _difficulties = {
  'easy':   _DiffConfig(label: 'Mudah',   gridSize: 8,  maxTime: 60,  color: AppColors.success),
  'medium': _DiffConfig(label: 'Sedang',  gridSize: 12, maxTime: 90,  color: AppColors.statusPending),
  'hard':   _DiffConfig(label: 'Sulit',   gridSize: 16, maxTime: 120, color: AppColors.error),
};

// ─── MAIN GAMES TAB ──────────────────────────────────────────
class GamesTab extends StatelessWidget {
  const GamesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameService(),
      child: const _GamesTabContent(),
    );
  }
}

class _GamesTabContent extends StatefulWidget {
  const _GamesTabContent();

  @override
  State<_GamesTabContent> createState() => _GamesTabContentState();
}

class _GamesTabContentState extends State<_GamesTabContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameService>().fetchLeaderboard();
      context.read<GameService>().fetchMyScores();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Games'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(
            fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Main'),
            Tab(text: 'Skor Saya'),
            Tab(text: 'Leaderboard'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _PlayTab(),
          _MyScoresTab(),
          _LeaderboardTab(),
        ],
      ),
    );
  }
}

// ─── TAB MAIN ────────────────────────────────────────────────
class _PlayTab extends StatelessWidget {
  const _PlayTab();

  void _startGame(BuildContext context, String difficulty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<GameService>(),
          child: MemoryMatchGame(difficulty: difficulty),
        ),
      ),
    ).then((_) {
      // Refresh skor setelah kembali dari game
      context.read<GameService>().fetchMyScores();
      context.read<GameService>().fetchLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🃏', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 10),
                const Text('Memory Match\nWisata Dieng',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                    color: Colors.white, fontFamily: 'Poppins')),
                const SizedBox(height: 6),
                Text('Cocokkan pasangan kartu tempat wisata Dieng\nSelesai cepat = dapat diskon!',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85),
                    fontFamily: 'Poppins')),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text('Cara Bermain', style: AppTextStyles.label),
          const SizedBox(height: 12),
          _HowToCard(),

          const SizedBox(height: 24),
          const Text('Pilih Tingkat Kesulitan', style: AppTextStyles.label),
          const SizedBox(height: 12),

          ..._difficulties.entries.map((e) {
            final key    = e.key;
            final config = e.value;
            final pairs  = config.gridSize ~/ 2;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _startGame(context, key),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: config.color.withOpacity(0.4), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: config.color.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.grid_view_rounded,
                          color: config.color, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(config.label,
                              style: TextStyle(fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: config.color, fontFamily: 'Poppins')),
                            Text('$pairs pasang kartu • Reward < ${config.maxTime}s',
                              style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: config.color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Main',
                          style: TextStyle(fontSize: 13, color: Colors.white,
                            fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _HowToCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = [
      ('1', '👆', 'Tap kartu untuk membuka'),
      ('2', '🔍', 'Ingat posisi setiap kartu'),
      ('3', '✅', 'Cocokkan 2 kartu yang sama'),
      ('4', '🏆', 'Selesaikan semua pasangan'),
      ('5', '🎁', 'Selesai cepat = dapat diskon booking!'),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: steps.map((s) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 24, height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
                child: Center(child: Text(s.$1,
                  style: const TextStyle(fontSize: 11, color: Colors.white,
                    fontWeight: FontWeight.w700, fontFamily: 'Poppins'))),
              ),
              const SizedBox(width: 10),
              Text(s.$2, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(child: Text(s.$3, style: AppTextStyles.body)),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

// ─── MEMORY MATCH GAME ───────────────────────────────────────
class MemoryMatchGame extends StatefulWidget {
  final String difficulty;

  const MemoryMatchGame({super.key, required this.difficulty});

  @override
  State<MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends State<MemoryMatchGame>
    with TickerProviderStateMixin {
  late List<_CardData> _cards;
  late _DiffConfig _config;

  int? _firstIndex;
  int? _secondIndex;
  bool _isChecking  = false;
  bool _gameStarted = false;
  bool _gameWon     = false;

  int _moves      = 0;
  int _matches    = 0;
  int _score      = 0;
  int _timeElapsed = 0;
  Timer? _timer;

  late List<AnimationController> _flipControllers;
  late List<Animation<double>>   _flipAnimations;

  @override
  void initState() {
    super.initState();
    _config = _difficulties[widget.difficulty]!;
    _initGame();
  }

  void _initGame() {
    final pairs = _config.gridSize ~/ 2;
    final selected = List.from(_destinations)..shuffle(Random());
    final selectedPairs = selected.take(pairs).toList();

    // Duplikat & shuffle
    final cardList = <_CardData>[];
    for (int i = 0; i < selectedPairs.length; i++) {
      cardList.add(_CardData(
        emoji:  selectedPairs[i]['emoji']!,
        name:   selectedPairs[i]['name']!,
        pairId: i,
      ));
      cardList.add(_CardData(
        emoji:  selectedPairs[i]['emoji']!,
        name:   selectedPairs[i]['name']!,
        pairId: i,
      ));
    }
    cardList.shuffle(Random());
    _cards = cardList;

    // Init flip animations
    _flipControllers = List.generate(
      _cards.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
      ),
    );
    _flipAnimations = _flipControllers.map((ctrl) =>
      Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeInOut))).toList();

    _firstIndex   = null;
    _secondIndex  = null;
    _isChecking   = false;
    _gameStarted  = false;
    _gameWon      = false;
    _moves        = 0;
    _matches      = 0;
    _score        = 0;
    _timeElapsed  = 0;
    _timer?.cancel();
  }

  void _startTimer() {
    _gameStarted = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _timeElapsed++);
    });
  }

  void _onCardTap(int index) {
    if (_isChecking) return;
    if (_cards[index].isFlipped || _cards[index].isMatched) return;

    if (!_gameStarted) _startTimer();

    HapticFeedback.lightImpact();

    setState(() => _cards[index].isFlipped = true);
    _flipControllers[index].forward();

    if (_firstIndex == null) {
      _firstIndex = index;
    } else {
      _secondIndex = index;
      _moves++;
      _isChecking = true;
      _checkMatch();
    }
  }

  void _checkMatch() async {
    final i1 = _firstIndex!;
    final i2 = _secondIndex!;

    await Future.delayed(const Duration(milliseconds: 600));

    if (_cards[i1].pairId == _cards[i2].pairId) {
      // Match!
      HapticFeedback.mediumImpact();
      setState(() {
        _cards[i1].isMatched = true;
        _cards[i2].isMatched = true;
        _matches++;
        _score += _calcScore();
      });

      // Cek menang
      if (_matches == _config.gridSize ~/ 2) {
        _onWin();
      }
    } else {
      // Tidak cocok — tutup kembali
      await Future.delayed(const Duration(milliseconds: 400));
      setState(() {
        _cards[i1].isFlipped = false;
        _cards[i2].isFlipped = false;
      });
      _flipControllers[i1].reverse();
      _flipControllers[i2].reverse();
    }

    setState(() {
      _firstIndex  = null;
      _secondIndex = null;
      _isChecking  = false;
    });
  }

  int _calcScore() {
    // Skor lebih tinggi jika cepat dan sedikit percobaan
    int base = 100;
    if (_timeElapsed < 30) base = 150;
    else if (_timeElapsed < 60) base = 120;
    return base;
  }

  void _onWin() async {
    _timer?.cancel();
    HapticFeedback.heavyImpact();

    // Simpan ke backend
    final gameService = context.read<GameService>();
    final result = await gameService.saveScore(
      score:       _score,
      timeSeconds: _timeElapsed,
      moves:       _moves,
      difficulty:  widget.difficulty,
    );

    if (mounted) {
      setState(() => _gameWon = true);
      _showWinDialog(result);
    }
  }

  void _showWinDialog(GameResultModel? result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _WinDialog(
        score:      _score,
        time:       _timeElapsed,
        moves:      _moves,
        difficulty: widget.difficulty,
        result:     result,
        onPlayAgain: () {
          Navigator.pop(context);
          setState(() => _initGame());
        },
        onExit: () {
          Navigator.pop(context); // tutup dialog
          Navigator.pop(context); // kembali ke menu
        },
      ),
    );
  }

  void _resetGame() {
    setState(() => _initGame());
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final ctrl in _flipControllers) ctrl.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  int get _crossAxisCount {
    if (_config.gridSize == 8)  return 4; // 4x2
    if (_config.gridSize == 12) return 4; // 4x3
    return 4;                              // 4x4
  }

  @override
  Widget build(BuildContext context) {
    final pairs    = _config.gridSize ~/ 2;
    final progress = _matches / pairs;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Memory Match — ${_config.label}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _resetGame,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Status bar ────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(label: 'Waktu',  value: _formatTime(_timeElapsed),
                  icon: Icons.timer_outlined,
                  color: _timeElapsed > _config.maxTime
                      ? AppColors.error : AppColors.primary),
                _StatItem(label: 'Langkah', value: '$_moves',
                  icon: Icons.touch_app_outlined, color: AppColors.statusConfirmed),
                _StatItem(label: 'Pasang',  value: '$_matches/$pairs',
                  icon: Icons.check_circle_outline_rounded, color: AppColors.success),
                _StatItem(label: 'Skor',    value: '$_score',
                  icon: Icons.star_outline_rounded, color: AppColors.warning),
              ],
            ),
          ),

          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.divider,
                    color: AppColors.primary,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${(_matches * 100 ~/ pairs)}% selesai',
                  style: AppTextStyles.caption),
              ],
            ),
          ),

          // Reward hint
          if (!_gameWon)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _timeElapsed <= _config.maxTime
                      ? AppColors.primaryLight
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _timeElapsed <= _config.maxTime
                          ? Icons.card_giftcard_rounded
                          : Icons.timer_off_rounded,
                      size: 14,
                      color: _timeElapsed <= _config.maxTime
                          ? AppColors.primaryDark
                          : AppColors.error,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _timeElapsed <= _config.maxTime
                          ? 'Selesai dalam ${_config.maxTime - _timeElapsed}s lagi untuk dapat diskon!'
                          : 'Waktu reward habis, tapi tetap semangat!',
                      style: TextStyle(
                        fontSize: 11, fontFamily: 'Poppins',
                        color: _timeElapsed <= _config.maxTime
                            ? AppColors.primaryDark
                            : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Grid kartu ────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _crossAxisCount,
                  crossAxisSpacing: 8,
                  mainAxisSpacing:  8,
                  childAspectRatio: 0.85,
                ),
                itemCount: _cards.length,
                itemBuilder: (ctx, i) => _MemoryCard(
                  card:      _cards[i],
                  animation: _flipAnimations[i],
                  onTap:     () => _onCardTap(i),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── MEMORY CARD WIDGET ──────────────────────────────────────
class _MemoryCard extends StatelessWidget {
  final _CardData card;
  final Animation<double> animation;
  final VoidCallback onTap;

  const _MemoryCard({
    required this.card,
    required this.animation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, __) {
          final angle = animation.value * pi;
          final showFront = angle >= pi / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: showFront
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(pi),
                    child: _buildFront(),
                  )
                : _buildBack(),
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: card.isMatched
            ? AppColors.primaryLight
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: card.isMatched
              ? AppColors.primary
              : AppColors.divider,
          width: card.isMatched ? 2 : 0.5,
        ),
        boxShadow: card.isMatched
            ? [BoxShadow(color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8, spreadRadius: 1)]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (card.isMatched)
            const Icon(Icons.check_circle_rounded,
              color: AppColors.primary, size: 14),
          Text(card.emoji,
            style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(card.name,
            style: TextStyle(
              fontSize: 9,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: card.isMatched
                  ? AppColors.primaryDark
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B8A4C), Color(0xFF39E07A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1),
            blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: const Center(
        child: Text('🃏', style: TextStyle(fontSize: 28)),
      ),
    );
  }
}

// ─── WIN DIALOG ──────────────────────────────────────────────
class _WinDialog extends StatelessWidget {
  final int score, time, moves;
  final String difficulty;
  final GameResultModel? result;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  const _WinDialog({
    required this.score,
    required this.time,
    required this.moves,
    required this.difficulty,
    required this.result,
    required this.onPlayAgain,
    required this.onExit,
  });

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final hasReward = result?.rewardCode != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(hasReward ? '🏆' : '🎯',
              style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text(hasReward ? 'Luar Biasa!' : 'Selesai!',
              style: AppTextStyles.h2),
            const SizedBox(height: 4),
            Text(
              hasReward
                  ? 'Kamu menyelesaikan dalam waktu singkat!'
                  : 'Semua pasangan berhasil ditemukan!',
              style: AppTextStyles.bodyMuted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Stats
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ResultStat(label: 'Waktu',   value: _formatTime(time)),
                  _ResultStat(label: 'Langkah', value: '$moves'),
                  _ResultStat(label: 'Skor',    value: '$score'),
                ],
              ),
            ),

            // Reward
            if (hasReward) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.card_giftcard_rounded,
                          color: AppColors.primaryDark, size: 18),
                        SizedBox(width: 6),
                        Text('Kamu dapat diskon!',
                          style: TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                            fontFamily: 'Poppins')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        result!.rewardCode!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('Diskon ${result!.discount}% untuk booking berikutnya',
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center),
                  ],
                ),
              ),
            ],

            // New best
            if (result?.isNewBest == true) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events_rounded,
                      color: AppColors.warning, size: 18),
                    SizedBox(width: 6),
                    Text('Rekor baru! 🎉',
                      style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                        fontFamily: 'Poppins')),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onExit,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 46)),
                    child: const Text('Menu',
                      style: TextStyle(fontFamily: 'Poppins')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Main Lagi'),
                    onPressed: onPlayAgain,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 46)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String label, value;
  const _ResultStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20,
          fontWeight: FontWeight.w700, fontFamily: 'Poppins',
          color: AppColors.primary)),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

// ─── STAT ITEM ───────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label, required this.value,
    required this.icon,  required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14,
          fontWeight: FontWeight.w700, color: color, fontFamily: 'Poppins')),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

// ─── TAB SKOR SAYA ───────────────────────────────────────────
class _MyScoresTab extends StatelessWidget {
  const _MyScoresTab();

  String _formatTime(int s) {
    final m = s ~/ 60;
    return m > 0 ? '${m}m ${s % 60}s' : '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<GameService>();

    if (svc.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (svc.myScores.isEmpty) {
      return const EmptyState(
        title: 'Belum ada skor',
        subtitle: 'Mainkan Memory Match untuk melihat skor kamu di sini',
        icon: Icons.sports_esports_outlined,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => svc.fetchMyScores(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats summary
          if (svc.myStats != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B8A4C), Color(0xFF39E07A)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryItem(
                    label: 'Total Main',
                    value: '${svc.myStats!['total_games'] ?? 0}',
                  ),
                  _SummaryItem(
                    label: 'Best Skor',
                    value: '${svc.myStats!['best_score'] ?? 0}',
                  ),
                  _SummaryItem(
                    label: 'Best Time',
                    value: _formatTime(
                        int.tryParse('${svc.myStats!['best_time'] ?? 0}') ?? 0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Score list
          ...svc.myScores.asMap().entries.map((e) {
            final i  = e.key;
            final sc = e.value;
            final diff = _difficulties[sc.difficulty];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider, width: 0.5),
              ),
              child: Row(
                children: [
                  // Rank
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: i == 0
                          ? AppColors.warning.withOpacity(0.15)
                          : AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : '${i+1}',
                        style: TextStyle(
                          fontSize: i < 3 ? 18 : 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Skor: ${sc.score}',
                              style: AppTextStyles.label),
                            const SizedBox(width: 8),
                            if (diff != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: diff.color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(diff.label,
                                  style: TextStyle(fontSize: 10,
                                    color: diff.color,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins')),
                              ),
                          ],
                        ),
                        Text(
                          '${_formatTime(sc.timeSeconds)} • ${sc.moves} langkah',
                          style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  if (sc.rewardCode != null)
                    Column(
                      children: [
                        const Icon(Icons.card_giftcard_rounded,
                          color: AppColors.primary, size: 18),
                        Text(sc.rewardCode!,
                          style: const TextStyle(fontSize: 9,
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins')),
                      ],
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label, value;
  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: const TextStyle(fontSize: 18,
        fontWeight: FontWeight.w700, color: Colors.white,
        fontFamily: 'Poppins')),
      Text(label, style: TextStyle(fontSize: 11,
        color: Colors.white.withOpacity(0.8), fontFamily: 'Poppins')),
    ],
  );
}

// ─── TAB LEADERBOARD ─────────────────────────────────────────
class _LeaderboardTab extends StatefulWidget {
  const _LeaderboardTab();

  @override
  State<_LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<_LeaderboardTab> {
  String _selected = 'medium';

  String _formatTime(int s) {
    final m = s ~/ 60;
    return m > 0 ? '${m}m ${s % 60}s' : '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<GameService>();

    return Column(
      children: [
        // Difficulty filter
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: _difficulties.entries.map((e) {
              final isActive = _selected == e.key;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selected = e.key);
                      svc.fetchLeaderboard(difficulty: e.key);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? e.value.color
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isActive
                              ? e.value.color
                              : AppColors.divider),
                      ),
                      child: Text(e.value.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12, fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? Colors.white
                              : AppColors.textSecondary,
                        )),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        Expanded(
          child: svc.isLoading
              ? const Center(child: CircularProgressIndicator(
                  color: AppColors.primary))
              : svc.leaderboard.isEmpty
                  ? const EmptyState(
                      title: 'Belum ada data',
                      subtitle: 'Jadilah yang pertama masuk leaderboard!',
                      icon: Icons.leaderboard_outlined,
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => svc.fetchLeaderboard(
                          difficulty: _selected),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: svc.leaderboard.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final entry = svc.leaderboard[i];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: i < 3
                                  ? AppColors.warning.withOpacity(0.05)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: i < 3
                                    ? AppColors.warning.withOpacity(0.3)
                                    : AppColors.divider,
                                width: i < 3 ? 1.5 : 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Medal
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    i == 0 ? '🥇'
                                        : i == 1 ? '🥈'
                                        : i == 2 ? '🥉'
                                        : '${i + 1}',
                                    style: TextStyle(
                                      fontSize: i < 3 ? 22 : 14,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(entry.name,
                                        style: AppTextStyles.label),
                                      Text(
                                        '${_formatTime(entry.timeSeconds)} • ${entry.moves} langkah',
                                        style: AppTextStyles.caption),
                                    ],
                                  ),
                                ),
                                Text('${entry.score}',
                                  style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    fontFamily: 'Poppins')),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}