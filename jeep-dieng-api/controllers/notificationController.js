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
 * Pelanggan kirim feedback baru
 * Body: { message, rating (1-5), order_id? }
 */
const createFeedback = async (req, res, next) => {
  try {
    const { message, rating, order_id } = req.body;

    if (!message || message.trim() === '') {
      return next(createError('Pesan feedback tidak boleh kosong', 422));
    }
    if (!rating || rating < 1 || rating > 5) {
      return next(createError('Rating harus antara 1 sampai 5', 422));
    }

    // Kalau ada order_id, pastikan order itu milik user ini
    if (order_id) {
      const [orders] = await db.query(
        'SELECT id FROM orders WHERE id = ? AND user_id = ?',
        [order_id, req.user.id]
      );
      if (orders.length === 0) {
        return next(createError('Pesanan tidak ditemukan atau bukan milik Anda', 404));
      }

      // Cek apakah sudah pernah feedback untuk order ini
      const [existing] = await db.query(
        'SELECT id FROM feedback WHERE order_id = ? AND user_id = ?',
        [order_id, req.user.id]
      );
      if (existing.length > 0) {
        return next(createError('Anda sudah memberikan feedback untuk pesanan ini', 409));
      }
    }

    const [result] = await db.query(
      `INSERT INTO feedback (user_id, order_id, message, rating)
       VALUES (?, ?, ?, ?)`,
      [req.user.id, order_id || null, message.trim(), rating]
    );

    const [created] = await db.query(
      `SELECT f.*, o.booking_date, p.name AS package_name
       FROM feedback f
       LEFT JOIN orders   o ON f.order_id   = o.id
       LEFT JOIN packages p ON o.package_id = p.id
       WHERE f.id = ?`,
      [result.insertId]
    );

    return sendSuccess(res, created[0], 'Feedback berhasil dikirim', 201);
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/feedback/my
 * Pelanggan lihat feedback miliknya sendiri
 */
const getMyFeedback = async (req, res, next) => {
  try {
    const [rows] = await db.query(
      `SELECT
         f.id,
         f.message,
         f.rating,
         f.created_at,
         f.order_id,
         o.booking_date,
         p.name AS package_name
       FROM feedback f
       LEFT JOIN orders   o ON f.order_id   = o.id
       LEFT JOIN packages p ON o.package_id = p.id
       WHERE f.user_id = ?
       ORDER BY f.created_at DESC`,
      [req.user.id]
    );
    return sendSuccess(res, rows);
  } catch (err) {
    next(err);
  }
};

/**
 * PUT /api/feedback/:id
 * Pelanggan edit feedback miliknya
 * Body: { message, rating }
 */
const updateFeedback = async (req, res, next) => {
  try {
    const { message, rating } = req.body;
    const feedbackId = req.params.id;

    if (!message || message.trim() === '') {
      return next(createError('Pesan feedback tidak boleh kosong', 422));
    }
    if (!rating || rating < 1 || rating > 5) {
      return next(createError('Rating harus antara 1 sampai 5', 422));
    }

    // Pastikan feedback milik user ini
    const [existing] = await db.query(
      'SELECT id, user_id FROM feedback WHERE id = ?',
      [feedbackId]
    );
    if (existing.length === 0) {
      return next(createError('Feedback tidak ditemukan', 404));
    }
    if (existing[0].user_id !== req.user.id) {
      return next(createError('Anda tidak berhak mengedit feedback ini', 403));
    }

    await db.query(
      'UPDATE feedback SET message = ?, rating = ? WHERE id = ?',
      [message.trim(), rating, feedbackId]
    );

    const [updated] = await db.query(
      `SELECT
         f.id, f.message, f.rating, f.created_at, f.order_id,
         o.booking_date,
         p.name AS package_name
       FROM feedback f
       LEFT JOIN orders   o ON f.order_id   = o.id
       LEFT JOIN packages p ON o.package_id = p.id
       WHERE f.id = ?`,
      [feedbackId]
    );

    return sendSuccess(res, updated[0], 'Feedback berhasil diperbarui');
  } catch (err) {
    next(err);
  }
};

/**
 * DELETE /api/feedback/:id
 * Pelanggan hapus feedback miliknya
 */
const deleteFeedback = async (req, res, next) => {
  try {
    const feedbackId = req.params.id;

    const [existing] = await db.query(
      'SELECT id, user_id FROM feedback WHERE id = ?',
      [feedbackId]
    );
    if (existing.length === 0) {
      return next(createError('Feedback tidak ditemukan', 404));
    }

    // Pelanggan hanya bisa hapus miliknya, admin bisa hapus semua
    if (req.user.role !== 'admin' && existing[0].user_id !== req.user.id) {
      return next(createError('Anda tidak berhak menghapus feedback ini', 403));
    }

    await db.query('DELETE FROM feedback WHERE id = ?', [feedbackId]);
    return sendSuccess(res, null, 'Feedback berhasil dihapus');
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/feedback/all
 * Admin: lihat semua feedback + statistik rata-rata rating
 */
const getAllFeedback = async (req, res, next) => {
  try {
    const [rows] = await db.query(
      `SELECT
         f.id,
         f.message,
         f.rating,
         f.created_at,
         f.order_id,
         u.name  AS user_name,
         o.booking_date,
         p.name  AS package_name
       FROM feedback f
       JOIN users u ON f.user_id = u.id
       LEFT JOIN orders   o ON f.order_id   = o.id
       LEFT JOIN packages p ON o.package_id = p.id
       ORDER BY f.created_at DESC`
    );
    const [stats] = await db.query(
      `SELECT
         COUNT(*)                    AS total,
         ROUND(AVG(rating), 2)       AS avg_rating,
         SUM(rating = 5)             AS bintang_5,
         SUM(rating = 4)             AS bintang_4,
         SUM(rating = 3)             AS bintang_3,
         SUM(rating = 2)             AS bintang_2,
         SUM(rating = 1)             AS bintang_1
       FROM feedback`
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
  getMyFeedback,
  updateFeedback,
  deleteFeedback,
  getAllFeedback,
};