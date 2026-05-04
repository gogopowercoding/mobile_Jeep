import 'package:flutter/material.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background gradient hijau ──
          Container(
            height: size.height * 0.62,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B8A4C), Color(0xFF39E07A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ── Langit biru di bagian atas ──
          Positioned(
            top: 0, left: 0, right: 0,
            height: size.height * 0.30,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6EC6F0), Color(0xFFAEE4FA)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // ── Awan ──
          Positioned(
            top: size.height * 0.06,
            left: size.width * 0.08,
            child: const _Cloud(width: 80, height: 28),
          ),
          Positioned(
            top: size.height * 0.09,
            right: size.width * 0.12,
            child: const _Cloud(width: 56, height: 20),
          ),

          // ── Burung ──
          Positioned(
            top: size.height * 0.13,
            left: size.width * 0.55,
            child: const _Bird(),
          ),

          // ── Ilustrasi pegunungan ──
          Positioned(
            top: size.height * 0.20,
            left: 0, right: 0,
            height: size.height * 0.42,
            child: CustomPaint(
              painter: _MountainPainter(),
            ),
          ),

          // ── Dekorasi bunga & semak ──
          Positioned(
            bottom: size.height * 0.36,
            right: size.width * 0.08,
            child: const _Flower(),
          ),
          Positioned(
            bottom: size.height * 0.37,
            left: size.width * 0.04,
            child: const _SmallBush(),
          ),

          // ── Konten utama ──
          SafeArea(
            child: Column(
              children: [
                // Logo & tagline
                Padding(
                  padding: const EdgeInsets.only(top: 28),
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: SlideTransition(
                      position: _slideUp,
                      child: Column(
                        children: [
                          const Text(
                            'JeepOra',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamily: 'TacOne',
                              letterSpacing: 1.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Pesan Jeep Wisata Dieng, JeepOra solusinya',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.90),
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Tombol bawah
                FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pushReplacementNamed(
                                      context, '/login'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF39E07A),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(52),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Biometric button
                              GestureDetector(
                                onTap: () {
                                  // Trigger biometric login langsung dari landing
                                  // Bisa dihubungkan ke AuthService jika diperlukan
                                },
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE6F9F0),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.fingerprint_rounded,
                                    color: Color(0xFF1B8A4C),
                                    size: 28,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Belum punya akun? ',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'Poppins',
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    Navigator.pushNamed(context, '/register'),
                                child: const Text(
                                  'Daftar Sekarang',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Painter pegunungan berlapis ──────────────────────────────────────────────
class _MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Layer belakang (gelap)
    final back = Paint()..color = const Color(0xFF1B6E3C).withOpacity(0.85);
    final pathBack = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.13, size.height * 0.38)
      ..lineTo(size.width * 0.25, size.height * 0.62)
      ..lineTo(size.width * 0.38, size.height * 0.15)
      ..lineTo(size.width * 0.52, size.height * 0.50)
      ..lineTo(size.width * 0.67, size.height * 0.05)
      ..lineTo(size.width * 0.80, size.height * 0.42)
      ..lineTo(size.width * 0.93, size.height * 0.22)
      ..lineTo(size.width, size.height * 0.32)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(pathBack, back);

    // Layer depan (lebih terang)
    final front = Paint()..color = const Color(0xFF2DBF6A).withOpacity(0.65);
    final pathFront = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.08, size.height * 0.55)
      ..lineTo(size.width * 0.20, size.height * 0.75)
      ..lineTo(size.width * 0.33, size.height * 0.30)
      ..lineTo(size.width * 0.46, size.height * 0.60)
      ..lineTo(size.width * 0.59, size.height * 0.18)
      ..lineTo(size.width * 0.72, size.height * 0.52)
      ..lineTo(size.width * 0.85, size.height * 0.34)
      ..lineTo(size.width, size.height * 0.48)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(pathFront, front);

    // Padang rumput
    final grass = Paint()..color = const Color(0xFF4CD471).withOpacity(0.5);
    final pathGrass = Path()
      ..moveTo(0, size.height * 0.82)
      ..quadraticBezierTo(
          size.width * 0.25, size.height * 0.72,
          size.width * 0.5, size.height * 0.80)
      ..quadraticBezierTo(
          size.width * 0.75, size.height * 0.88,
          size.width, size.height * 0.78)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(pathGrass, grass);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Widget awan ──────────────────────────────────────────────────────────────
class _Cloud extends StatelessWidget {
  final double width;
  final double height;
  const _Cloud({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _CloudPainter()),
    );
  }
}

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.88);
    canvas.drawCircle(
        Offset(size.width * 0.25, size.height * 0.6), size.height * 0.45, p);
    canvas.drawCircle(
        Offset(size.width * 0.50, size.height * 0.38), size.height * 0.55, p);
    canvas.drawCircle(
        Offset(size.width * 0.75, size.height * 0.55), size.height * 0.42, p);
    canvas.drawRect(
      Rect.fromLTRB(size.width * 0.15, size.height * 0.55,
          size.width * 0.85, size.height),
      p,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Widget burung ────────────────────────────────────────────────────────────
class _Bird extends StatelessWidget {
  const _Bird();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 14,
      child: CustomPaint(painter: _BirdPainter()),
    );
  }
}

class _BirdPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF334455)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final left = Path()
      ..moveTo(size.width * 0.5, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.25, 0, 0, size.height * 0.35);
    canvas.drawPath(left, p);

    final right = Path()
      ..moveTo(size.width * 0.5, size.height * 0.5)
      ..quadraticBezierTo(
          size.width * 0.75, 0, size.width, size.height * 0.35);
    canvas.drawPath(right, p);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Widget bunga ─────────────────────────────────────────────────────────────
class _Flower extends StatelessWidget {
  const _Flower();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _petal(Colors.white),
            const SizedBox(width: 2),
            _petal(const Color(0xFFFFC0CB)),
          ],
        ),
        Container(width: 2, height: 14, color: const Color(0xFF2DBF6A)),
      ],
    );
  }

  Widget _petal(Color color) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

// ── Widget semak kecil ────────────────────────────────────────────────────────
class _SmallBush extends StatelessWidget {
  const _SmallBush();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: const Color(0xFF3AD46A), shape: BoxShape.circle)),
        const SizedBox(width: 2),
        Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
                color: const Color(0xFF2DBF6A), shape: BoxShape.circle)),
        const SizedBox(width: 2),
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: const Color(0xFF3AD46A), shape: BoxShape.circle)),
      ],
    );
  }
}