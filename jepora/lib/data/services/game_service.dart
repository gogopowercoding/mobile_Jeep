import 'package:flutter/foundation.dart';
import 'package:jepora/core/network/api_client.dart';
import 'package:jepora/data/models/game_model.dart';

class GameService extends ChangeNotifier {
  List<GameScoreModel>    _myScores    = [];
  List<LeaderboardEntry>  _leaderboard = [];
  Map<String, dynamic>?   _myStats;
  bool _isLoading = false;

  List<GameScoreModel>   get myScores    => _myScores;
  List<LeaderboardEntry> get leaderboard => _leaderboard;
  Map<String, dynamic>?  get myStats     => _myStats;
  bool                   get isLoading   => _isLoading;

  // ─── SIMPAN SKOR ─────────────────────────────────────────────
  Future<GameResultModel?> saveScore({
    required int score,
    required int timeSeconds,
    required int moves,
    required String difficulty,
  }) async {
    try {
      final res = await ApiClient().dio.post('/game/score', data: {
        'score':        score,
        'time_seconds': timeSeconds,
        'moves':        moves,
        'difficulty':   difficulty,
      });
      if (res.data['success'] == true) {
        return GameResultModel.fromJson(res.data['data']);
      }
    } catch (e) {
      debugPrint('GameService.saveScore error: $e');
    }
    return null;
  }

  // ─── RIWAYAT SKOR SAYA ───────────────────────────────────────
  Future<void> fetchMyScores({String? difficulty}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiClient().dio.get('/game/scores/me',
        queryParameters: difficulty != null ? {'difficulty': difficulty} : null,
      );
      if (res.data['success'] == true) {
        _myStats  = res.data['data']['stats'];
        _myScores = (res.data['data']['scores'] as List)
            .map((e) => GameScoreModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint('GameService.fetchMyScores error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── LEADERBOARD ─────────────────────────────────────────────
  Future<void> fetchLeaderboard({String difficulty = 'medium'}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiClient().dio.get('/game/leaderboard',
        queryParameters: {'difficulty': difficulty},
      );
      if (res.data['success'] == true) {
        _leaderboard = (res.data['data'] as List)
            .map((e) => LeaderboardEntry.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint('GameService.fetchLeaderboard error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}