const db = require('../config/database');
const { createError, sendSuccess } = require('../middleware/errorHandler');

/**
 * GET /api/payments/:order_id
 * Detail pembayaran sebuah pesanan
 */
const getPaymentByOrder = async (req, res, next) => {
  try {
    const [rows] = await db.query(
      `SELECT py.*, o.user_id FROM payments py
       JOIN orders o ON py.order_id = o.id
       WHERE py.order_id = ?`,
      [req.params.order_id]
    );
    if (rows.length === 0) return next(createError('Data pembayaran tidak ditemukan', 404));

    // Pelanggan hanya boleh lihat miliknya
    if (req.user.role === 'pelanggan' && rows[0].user_id !== req.user.id) {
      return next(createError('Tidak diizinkan', 403));
    }
    return sendSuccess(res, rows[0]);
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/currency-convert
 * Query: ?amount=350000&from=IDR&to=USD
 * Menggunakan open.er-api.com (gratis, no key)
 */
const convertCurrency = async (req, res, next) => {
  try {
    const { amount, from = 'IDR', to = 'USD' } = req.query;

    if (!amount || isNaN(Number(amount))) {
      return next(createError('Parameter amount tidak valid', 422));
    }

    // Fetch exchange rates
    const response = await fetch(`https://open.er-api.com/v6/latest/${from}`);
    if (!response.ok) throw createError('Gagal mengambil data kurs', 503);

    const data = await response.json();

    if (data.result !== 'success') {
      throw createError('API kurs tidak tersedia saat ini', 503);
    }

    const rate = data.rates[to];
    if (!rate) return next(createError(`Mata uang ${to} tidak ditemukan`, 404));

    const converted = (Number(amount) * rate).toFixed(2);

    return sendSuccess(res, {
      from,
      to,
      amount:    Number(amount),
      rate,
      converted: Number(converted),
      updated:   data.time_last_update_utc,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/payments/:order_id/confirm   — admin only
 * Konfirmasi pembayaran manual (e.g. transfer)
 * Body: { payment_method }
 */
const confirmPayment = async (req, res, next) => {
  try {
    const { payment_method } = req.body;
    const { order_id } = req.params;

    const [rows] = await db.query(
      'SELECT id, order_id, payment_status FROM payments WHERE order_id = ?',
      [order_id]
    );
    if (rows.length === 0) return next(createError('Data pembayaran tidak ditemukan', 404));

    await db.query(
      `UPDATE payments
       SET payment_status = 'paid', payment_method = ?, paid_at = NOW()
       WHERE order_id = ?`,
      [payment_method || 'manual', order_id]
    );

    // Ambil user_id untuk notifikasi
    const [orders] = await db.query('SELECT user_id FROM orders WHERE id = ?', [order_id]);
    if (orders.length > 0) {
      await db.query(
        `INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)`,
        [orders[0].user_id, 'Pembayaran Dikonfirmasi 💳', 'Pembayaran Anda telah dikonfirmasi. Pesanan siap diproses.']
      );
    }

    return sendSuccess(res, null, 'Pembayaran berhasil dikonfirmasi');
  } catch (err) {
    next(err);
  }
};

module.exports = { getPaymentByOrder, convertCurrency, confirmPayment };
