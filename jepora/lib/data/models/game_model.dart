class GameScoreModel {
  final int id;
  final int score;
  final int timeSeconds;
  final int moves;
  final String difficulty;
  final String? rewardCode;
  final String createdAt;

  GameScoreModel({
    required this.id,
    required this.score,
    required this.timeSeconds,
    required this.moves,
    required this.difficulty,
    this.rewardCode,
    required this.createdAt,
  });

  factory GameScoreModel.fromJson(Map<String, dynamic> j) => GameScoreModel(
        id:          j['id'],
        score:       j['score']        ?? 0,
        timeSeconds: j['time_seconds'] ?? 0,
        moves:       j['moves']        ?? 0,
        difficulty:  j['difficulty']   ?? 'medium',
        rewardCode:  j['reward_code'],
        createdAt:   j['created_at']   ?? '',
      );
}

class GameResultModel {
  final int score;
  final int timeSeconds;
  final int moves;
  final String difficulty;
  final String? rewardCode;
  final int discount;
  final bool isNewBest;
  final int bestTime;
  final int bestScore;

  GameResultModel({
    required this.score,
    required this.timeSeconds,
    required this.moves,
    required this.difficulty,
    this.rewardCode,
    required this.discount,
    required this.isNewBest,
    required this.bestTime,
    required this.bestScore,
  });

  factory GameResultModel.fromJson(Map<String, dynamic> j) => GameResultModel(
        score:       j['score']        ?? 0,
        timeSeconds: j['time_seconds'] ?? 0,
        moves:       j['moves']        ?? 0,
        difficulty:  j['difficulty']   ?? 'medium',
        rewardCode:  j['reward_code'],
        discount:    j['discount']     ?? 0,
        isNewBest:   j['is_new_best']  ?? false,
        bestTime:    j['best_time']    ?? 0,
        bestScore:   j['best_score']   ?? 0,
      );
}

class LeaderboardEntry {
  final String name;
  final int score;
  final int timeSeconds;
  final int moves;
  final String difficulty;

  LeaderboardEntry({
    required this.name,
    required this.score,
    required this.timeSeconds,
    required this.moves,
    required this.difficulty,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        name:        j['name']         ?? '',
        score:       j['score']        ?? 0,
        timeSeconds: j['time_seconds'] ?? 0,
        moves:       j['moves']        ?? 0,
        difficulty:  j['difficulty']   ?? 'medium',
      );
}