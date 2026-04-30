const db = require('../config/database');
const { sendSuccess, createError } = require('../middleware/errorHandler');

// Reward rules berdasarkan difficulty & waktu
const REWARD_RULES = {
  easy:   { maxTime: 60,  code: 'DIENG5',  discount: 5  },
  medium: { maxTime: 90,  code: 'DIENG10', discount: 10 },
  hard:   { maxTime: 120, code: 'DIENG15', discount: 15 },
};

/**
 * POST /api/game/score
 * Simpan skor setelah game selesai
 * Body: { score, time_seconds, moves, difficulty }
 */
const saveScore = async (req, res, next) => {
  try {
    const { score, time_seconds, moves, difficulty = 'medium' } = req.body;

    if (!score || !time_seconds || !moves) {
      return next(createError('Data skor tidak lengkap', 422));
    }

    // Tentukan reward
    const rule = REWARD_RULES[difficulty];
    let rewardCode = null;
    if (rule && time_seconds <= rule.maxTime) {
      rewardCode = rule.code;
    }

    const [result] = await db.query(
      `INSERT INTO game_scores
         (user_id, game_type, score, time_seconds, moves, difficulty, reward_code)
       VALUES (?, 'memory_match', ?, ?, ?, ?, ?)`,
      [req.user.id, score, time_seconds, moves, difficulty, rewardCode]
    );

    // Ambil best score user ini
    const [best] = await db.query(
      `SELECT MIN(time_seconds) AS best_time, MAX(score) AS best_score
       FROM game_scores
       WHERE user_id = ? AND game_type = 'memory_match' AND difficulty = ?`,
      [req.user.id, difficulty]
    );

    return sendSuccess(res, {
      id:          result.insertId,
      score,
      time_seconds,
      moves,
      difficulty,
      reward_code: rewardCode,
      discount:    rewardCode ? rule.discount : 0,
      is_new_best: best[0].best_time === time_seconds,
      best_time:   best[0].best_time,
      best_score:  best[0].best_score,
    }, rewardCode
      ? `Selamat! Kamu dapat diskon ${rule.discount}% — kode: ${rewardCode} 🎉`
      : 'Skor berhasil disimpan!',
    201);
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/game/scores/me
 * Riwayat skor milik user yang login
 * Query: ?difficulty=medium&limit=10
 */
const getMyScores = async (req, res, next) => {
  try {
    const { difficulty, limit = 10 } = req.query;

    let query = `
      SELECT id, score, time_seconds, moves, difficulty, reward_code, created_at
      FROM game_scores
      WHERE user_id = ? AND game_type = 'memory_match'
    `;
    const params = [req.user.id];

    if (difficulty) { query += ' AND difficulty = ?'; params.push(difficulty); }
    query += ' ORDER BY score DESC, time_seconds ASC LIMIT ?';
    params.push(Number(limit));

    const [rows] = await db.query(query, params);

    // Stats ringkasan
    const [stats] = await db.query(
      `SELECT
         COUNT(*)              AS total_games,
         MAX(score)            AS best_score,
         MIN(time_seconds)     AS best_time,
         ROUND(AVG(score), 0)  AS avg_score
       FROM game_scores
       WHERE user_id = ? AND game_type = 'memory_match'`,
      [req.user.id]
    );

    return sendSuccess(res, { stats: stats[0], scores: rows });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/game/leaderboard
 * Top 10 skor semua user
 * Query: ?difficulty=medium
 */
const getLeaderboard = async (req, res, next) => {
  try {
    const { difficulty = 'medium' } = req.query;

    const [rows] = await db.query(
      `SELECT
         u.name,
         gs.score,
         gs.time_seconds,
         gs.moves,
         gs.difficulty,
         gs.created_at
       FROM game_scores gs
       JOIN users u ON gs.user_id = u.id
       WHERE gs.game_type = 'memory_match'
         AND gs.difficulty = ?
       ORDER BY gs.score DESC, gs.time_seconds ASC
       LIMIT 10`,
      [difficulty]
    );

    return sendSuccess(res, rows);
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/game/rewards/check
 * Cek apakah user punya reward code aktif
 */
const checkReward = async (req, res, next) => {
  try {
    const [rows] = await db.query(
      `SELECT reward_code, difficulty, score, time_seconds, created_at
       FROM game_scores
       WHERE user_id = ?
         AND reward_code IS NOT NULL
         AND game_type = 'memory_match'
       ORDER BY created_at DESC
       LIMIT 5`,
      [req.user.id]
    );

    const rewards = rows.map(r => ({
      ...r,
      discount: REWARD_RULES[r.difficulty]?.discount || 0,
    }));

    return sendSuccess(res, rewards);
  } catch (err) {
    next(err);
  }
};

module.exports = { saveScore, getMyScores, getLeaderboard, checkReward };