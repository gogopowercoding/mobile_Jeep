import '../models/package_model.dart';

class RecommendationPreference {
  final String interest;
  final double maxBudget;
  final int preferredDuration;

  const RecommendationPreference({
    required this.interest,
    required this.maxBudget,
    required this.preferredDuration,
  });
}

class PackageRecommendation {
  final PackageModel package;
  final double score;
  final List<String> reasons;

  const PackageRecommendation({
    required this.package,
    required this.score,
    required this.reasons,
  });

  int get scorePercent => (score.clamp(0, 1) * 100).round();
}

/// Rekomendasi paket wisata berbasis AI/ML sederhana.
///
/// Metode yang digunakan adalah Content-Based Filtering dengan weighted scoring.
/// Setiap paket dibandingkan dengan preferensi user berdasarkan kata kunci wisata,
/// batas budget, durasi perjalanan, dan nilai ekonomis. Hasil dengan skor tertinggi
/// ditampilkan sebagai rekomendasi.
class PackageRecommendationService {
  static const Map<String, List<String>> _keywords = {
    'sunrise': ['sunrise', 'sikunir', 'pagi', 'matahari', 'golden'],
    'kawah': ['kawah', 'sikidang', 'vulkanik', 'gunung', 'belerang'],
    'telaga': ['telaga', 'warna', 'pengilon', 'danau', 'air'],
    'candi': ['candi', 'arjuna', 'sejarah', 'budaya', 'heritage'],
    'keluarga': ['keluarga', 'family', 'santai', 'anak', 'aman'],
    'hemat': ['hemat', 'murah', 'ekonomis', 'budget'],
    'lengkap': ['lengkap', 'full', 'all', 'komplit', 'premium'],
  };

  static const Map<String, String> interestLabels = {
    'sunrise': 'Sunrise',
    'kawah': 'Kawah',
    'telaga': 'Telaga',
    'candi': 'Candi',
    'keluarga': 'Keluarga',
    'hemat': 'Hemat',
    'lengkap': 'Lengkap',
  };

  static List<PackageRecommendation> recommend({
    required List<PackageModel> packages,
    required RecommendationPreference preference,
    int limit = 3,
  }) {
    if (packages.isEmpty) return [];

    final prices = packages.map((e) => e.price).where((e) => e > 0).toList();
    final minPrice = prices.isEmpty ? 0.0 : prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.isEmpty ? 1.0 : prices.reduce((a, b) => a > b ? a : b);
    final priceRange = (maxPrice - minPrice).abs() < 1 ? 1.0 : (maxPrice - minPrice);

    final scored = packages.map((package) {
      final text = '${package.name} ${package.description ?? ''}'.toLowerCase();
      final keywordScore = _interestScore(text, preference.interest);
      final budgetScore = _budgetScore(package.price, preference.maxBudget);
      final durationScore = _durationScore(package.duration, preference.preferredDuration);
      final valueScore = (1 - ((package.price - minPrice) / priceRange).clamp(0.0, 1.0)).toDouble();
      final scheduleBonus = (package.schedules != null && package.schedules!.isNotEmpty) ? 0.05 : 0.0;

      final score = (
        keywordScore * 0.40 +
        budgetScore * 0.28 +
        durationScore * 0.22 +
        valueScore * 0.10 +
        scheduleBonus
      ).clamp(0.0, 1.0).toDouble();

      return PackageRecommendation(
        package: package,
        score: score,
        reasons: _buildReasons(
          package: package,
          interest: preference.interest,
          keywordScore: keywordScore,
          budgetScore: budgetScore,
          durationScore: durationScore,
          valueScore: valueScore,
          maxBudget: preference.maxBudget,
        ),
      );
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored.take(limit).toList();
  }

  static double _interestScore(String text, String interest) {
    final keys = _keywords[interest] ?? const [];
    if (keys.isEmpty) return 0.45;

    var match = 0;
    for (final key in keys) {
      if (text.contains(key)) match++;
    }

    if (match == 0) return 0.25; // fallback agar paket tetap bisa direkomendasikan
    return (0.55 + (match / keys.length) * 0.45).clamp(0.0, 1.0).toDouble();
  }

  static double _budgetScore(double price, double maxBudget) {
    if (maxBudget <= 0 || price <= 0) return 0.5;
    if (price <= maxBudget) return 1;

    final overBudgetRatio = (price - maxBudget) / maxBudget;
    return (1 - overBudgetRatio).clamp(0.0, 1.0).toDouble();
  }

  static double _durationScore(int duration, int preferredDuration) {
    if (duration <= 0 || preferredDuration <= 0) return 0.5;

    final diffRatio = (duration - preferredDuration).abs() / preferredDuration;
    return (1 - diffRatio).clamp(0.0, 1.0).toDouble();
  }

  static List<String> _buildReasons({
    required PackageModel package,
    required String interest,
    required double keywordScore,
    required double budgetScore,
    required double durationScore,
    required double valueScore,
    required double maxBudget,
  }) {
    final label = interestLabels[interest] ?? interest;
    final reasons = <String>[];

    if (keywordScore >= 0.55) {
      reasons.add('Cocok untuk minat $label');
    }
    if (budgetScore >= 0.95 && package.price <= maxBudget) {
      reasons.add('Masuk budget');
    }
    if (durationScore >= 0.75) {
      reasons.add('Durasi mendekati pilihan');
    }
    if (valueScore >= 0.65) {
      reasons.add('Harga relatif ekonomis');
    }
    if (package.schedules != null && package.schedules!.isNotEmpty) {
      reasons.add('Jadwal tersedia');
    }

    if (reasons.isEmpty) {
      reasons.add('Skor kecocokan terbaik dari paket tersedia');
    }

    return reasons.take(3).toList();
  }
}
