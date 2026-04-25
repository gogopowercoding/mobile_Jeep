const db = require('../config/database');
const { createError, sendSuccess } = require('../middleware/errorHandler');

// ─── NOTIFICATIONS ────────────────────────────────────────────

/**
 * GET /api/notifications
 * Notifikasi milik user yang login
 */
const getNotifications = async (req, res, next) => {
  try {
    const [rows] = await db.query(
      `SELECT * FROM notifications
       WHERE user_id = ?
       ORDER BY created_at DESC
       LIMIT 50`,
      [req.user.id]
    );
    return sendSuccess(res, rows);
  } catch (err) {
    next(err);
  }
};

/**
 * PUT /api/notifications/:id/read
 * Tandai satu notifikasi sebagai sudah dibaca
 */
const markAsRead = async (req, res, next) => {
  try {
    await db.query(
      'UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?',
      [req.params.id, req.user.id]
    );
    return sendSuccess(res, null, 'Notifikasi ditandai sudah dibaca');
  } catch (err) {
    next(err);
  }
};

/**
 * PUT /api/notifications/read-all
 * Tandai semua notifikasi sebagai sudah dibaca
 */
const markAllAsRead = async (req, res, next) => {
  try {
    await db.query(
      'UPDATE notifications SET is_read = 1 WHERE user_id = ?',
      [req.user.id]
    );
    return sendSuccess(res, null, 'Semua notifikasi ditandai sudah dibaca');
  } catch (err) {
    next(err);
  }
};

// ─── FEEDBACK ────────────────────────────────────────────────

/**
 * POST /api/feedback
 * Body: { message, rating (1-5), order_id? }
 */
const createFeedback = async (req, res, next) => {
  try {
    const { message, rating, order_id } = req.body;

    if (!rating || rating < 1 || rating > 5) {
      return next(createError('Rating harus antara 1 sampai 5', 422));
    }

    const [result] = await db.query(
      `INSERT INTO feedback (user_id, order_id, message, rating)
       VALUES (?, ?, ?, ?)`,
      [req.user.id, order_id || null, message, rating]
    );

    return sendSuccess(res, { id: result.insertId }, 'Feedback berhasil dikirim', 201);
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/feedback
 * Admin: lihat semua feedback + rata-rata rating
 */
const getAllFeedback = async (req, res, next) => {
  try {
    const [rows] = await db.query(
      `SELECT f.*, u.name AS user_name
       FROM feedback f
       JOIN users u ON f.user_id = u.id
       ORDER BY f.created_at DESC`
    );
    const [stats] = await db.query(
      `SELECT COUNT(*) AS total, ROUND(AVG(rating), 2) AS avg_rating FROM feedback`
    );
    return sendSuccess(res, { stats: stats[0], feedback: rows });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getNotifications,
  markAsRead,
  markAllAsRead,
  createFeedback,
  getAllFeedback,
};
