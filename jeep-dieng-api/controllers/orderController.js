const db = require('../config/database');
const path = require('path');
const fs = require('fs');
const { createError, sendSuccess } = require('../middleware/errorHandler');

/**
 * POST /api/orders
 * Body: { package_id, booking_date, latitude, longitude, notes?, voucher_id? }
 * CATATAN: field 'discount' dihapus dari body — kalkulasi dilakukan di backend
 */
const createOrder = async (req, res, next) => {
  try {
    const { package_id, booking_date, latitude, longitude, notes, voucher_id } = req.body;
    const userId = req.user.id;

    const [pkgs] = await db.query(
      'SELECT id, name, price FROM packages WHERE id = ? AND is_active = 1',
      [package_id]
    );
    if (pkgs.length === 0) return next(createError('Paket tidak ditemukan', 404));

    const pkg = pkgs[0];

    // Hitung total setelah diskon voucher — kalkulasi dilakukan di backend
    let totalPrice = parseFloat(pkg.price);
    let appliedDiscount = 0;
    let appliedVoucherId = null;

    if (voucher_id) {
      // Validasi voucher: aktif, belum kadaluarsa, belum habis kuota
      const [vouchers] = await db.query(
        `SELECT * FROM vouchers WHERE id = ? AND is_active = 1
         AND (valid_from IS NULL OR valid_from <= CURDATE())
         AND (valid_until IS NULL OR valid_until >= CURDATE())
         AND (usage_limit IS NULL OR used_count < usage_limit)`,
        [voucher_id]
      );

      if (vouchers.length > 0) {
        const v = vouchers[0];

        // Cek minimum order
        if (totalPrice >= parseFloat(v.min_order)) {
          if (v.type === 'percent') {
            appliedDiscount = (totalPrice * parseFloat(v.value)) / 100;
            // Terapkan batas maksimal diskon jika ada
            if (v.max_discount) {
              appliedDiscount = Math.min(appliedDiscount, parseFloat(v.max_discount));
            }
          } else {
            // type === 'fixed'
            appliedDiscount = parseFloat(v.value);
          }

          totalPrice = Math.max(0, totalPrice - appliedDiscount);
          appliedVoucherId = v.id;

          // Increment used_count
          await db.query(
            'UPDATE vouchers SET used_count = used_count + 1 WHERE id = ?',
            [v.id]
          );
        } else {
          // Order di bawah minimum, tolak voucher
          return next(
            createError(
              `Voucher hanya berlaku untuk order minimal Rp ${parseFloat(v.min_order).toLocaleString('id-ID')}`,
              422
            )
          );
        }
      } else {
        // Voucher tidak valid / sudah kadaluarsa / habis kuota
        return next(createError('Voucher tidak valid atau sudah kadaluarsa', 422));
      }
    }

    const [result] = await db.query(
      `INSERT INTO orders
         (user_id, package_id, booking_date, total_price, discount, voucher_id,
          status, latitude, longitude, notes)
       VALUES (?, ?, ?, ?, ?, ?, 'pending', ?, ?, ?)`,
      [userId, package_id, booking_date, totalPrice, appliedDiscount,
       appliedVoucherId, latitude || null, longitude || null, notes || null]
    );

    const orderId = result.insertId;

    await db.query(
      `INSERT INTO payments (order_id, amount, currency, payment_status)
       VALUES (?, ?, 'IDR', 'pending')`,
      [orderId, totalPrice]
    );

    await db.query(
      `INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)`,
      [userId, 'Pesanan Diterima 🚙',
       `Pesanan paket "${pkg.name}" Anda telah kami terima${appliedDiscount > 0 ? ` dengan diskon Rp ${appliedDiscount.toLocaleString('id-ID')}` : ''}.`]
    );

    const [order] = await db.query(
      `SELECT o.*, p.name AS package_name, p.price AS package_price
       FROM orders o JOIN packages p ON o.package_id = p.id WHERE o.id = ?`,
      [orderId]
    );

    return sendSuccess(res, order[0], 'Pesanan berhasil dibuat', 201);
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/orders/upload-payment
 * Upload bukti pembayaran (multipart/form-data)
 * Body: { order_id }, File: payment_proof
 */
const uploadPaymentProof = async (req, res, next) => {
  try {
    const { order_id } = req.body;
    const file = req.file;

    if (!file) return next(createError('File bukti pembayaran wajib diunggah', 422));
    if (!order_id) return next(createError('order_id wajib diisi', 422));

    // Validasi order milik user ini
    const [orders] = await db.query(
      'SELECT id, user_id, status FROM orders WHERE id = ?', [order_id]
    );
    if (orders.length === 0) return next(createError('Pesanan tidak ditemukan', 404));
    if (req.user.role === 'pelanggan' && orders[0].user_id !== req.user.id) {
      return next(createError('Tidak diizinkan', 403));
    }

    const imageUrl = `/uploads/payments/${file.filename}`;

    // Update payment record dengan bukti
    await db.query(
      `UPDATE payments
       SET payment_proof = ?, payment_status = 'waiting_confirmation', updated_at = NOW()
       WHERE order_id = ?`,
      [imageUrl, order_id]
    );

    // Notifikasi ke admin
    const [admins] = await db.query(
      "SELECT id FROM users WHERE role = 'admin' AND is_active = 1 LIMIT 1"
    );
    if (admins.length > 0) {
      await db.query(
        `INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)`,
        [admins[0].id, 'Bukti Pembayaran Masuk 💳',
         `Pelanggan telah mengunggah bukti pembayaran untuk pesanan #${order_id}. Harap verifikasi.`]
      );
    }

    return sendSuccess(res, { payment_proof: imageUrl },
      'Bukti pembayaran berhasil diunggah, menunggu konfirmasi admin');
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/orders/user/:user_id
 */
const getOrdersByUser = async (req, res, next) => {
  try {
    const { user_id } = req.params;
    const { status } = req.query;

    if (req.user.role === 'pelanggan' && String(req.user.id) !== user_id) {
      return next(createError('Tidak diizinkan', 403));
    }

    let query = `
      SELECT
        o.*,
        p.name   AS package_name,
        p.image  AS package_image,
        d.name   AS driver_name,
        d.phone  AS driver_phone,
        py.payment_status,
        py.amount AS payment_amount,
        py.payment_proof,
        py.currency
      FROM orders o
      JOIN packages p ON o.package_id = p.id
      LEFT JOIN users   d  ON o.driver_id  = d.id
      LEFT JOIN payments py ON o.id = py.order_id
    `;

    const params = [];
    if (user_id !== 'all') {
      query += ' WHERE o.user_id = ?';
      params.push(user_id);
      if (status) { query += ' AND o.status = ?'; params.push(status); }
    } else {
      if (status) { query += ' WHERE o.status = ?'; params.push(status); }
    }

    query += ' ORDER BY o.created_at DESC';
    const [rows] = await db.query(query, params);
    return sendSuccess(res, rows);
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/orders/:id
 */
const getOrderById = async (req, res, next) => {
  try {
    const [rows] = await db.query(
      `SELECT
         o.*,
         p.name  AS package_name,
         p.description AS package_desc,
         p.duration,
         p.image AS package_image,
         u.name  AS customer_name,
         u.phone AS customer_phone,
         d.name  AS driver_name,
         d.phone AS driver_phone,
         py.payment_status,
         py.amount   AS payment_amount,
         py.currency,
         py.payment_method,
         py.payment_proof
       FROM orders o
       JOIN packages  p  ON o.package_id = p.id
       JOIN users     u  ON o.user_id    = u.id
       LEFT JOIN users d  ON o.driver_id  = d.id
       LEFT JOIN payments py ON o.id = py.order_id
       WHERE o.id = ?`,
      [req.params.id]
    );
    if (rows.length === 0) return next(createError('Pesanan tidak ditemukan', 404));

    const order = rows[0];
    if (req.user.role === 'pelanggan' && order.user_id !== req.user.id) {
      return next(createError('Tidak diizinkan', 403));
    }
    return sendSuccess(res, order);
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/assign-driver  — admin only
 */
const assignDriver = async (req, res, next) => {
  try {
    const { order_id, driver_id } = req.body;

    const [drivers] = await db.query(
      "SELECT id, name FROM users WHERE id = ? AND role = 'supir' AND is_active = 1",
      [driver_id]
    );
    if (drivers.length === 0) return next(createError('Supir tidak ditemukan atau tidak aktif', 404));

    const [orders] = await db.query('SELECT id, user_id, status FROM orders WHERE id = ?', [order_id]);
    if (orders.length === 0) return next(createError('Pesanan tidak ditemukan', 404));

    await db.query(
      "UPDATE orders SET driver_id = ?, status = 'confirmed', driver_response = 'pending' WHERE id = ?",
      [driver_id, order_id]
    );

    await db.query(
      `INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)`,
      [driver_id, 'Pesanan Baru Menunggu Konfirmasi 🚙',
       `Anda mendapat pesanan baru #${order_id}. Buka aplikasi untuk ACC atau tolak.`]
    );

    await db.query(
      `INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)`,
      [orders[0].user_id, 'Pesanan Diproses ⏳',
       `Pesanan Anda sedang menunggu konfirmasi dari supir.`]
    );

    return sendSuccess(res, null, 'Supir berhasil di-assign, menunggu konfirmasi supir');
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/orders/respond  — supir only
 */
const respondOrder = async (req, res, next) => {
  try {
    const { order_id, response, note } = req.body;

    if (!['accepted', 'rejected'].includes(response)) {
      return next(createError("Response harus 'accepted' atau 'rejected'", 422));
    }

    const [orders] = await db.query(
      `SELECT o.*, u.name AS customer_name FROM orders o
       JOIN users u ON o.user_id = u.id WHERE o.id = ?`,
      [order_id]
    );
    if (orders.length === 0) return next(createError('Pesanan tidak ditemukan', 404));

    const order = orders[0];
    if (order.driver_id !== req.user.id) {
      return next(createError('Pesanan ini bukan milik Anda', 403));
    }
    if (order.status !== 'confirmed' || order.driver_response !== 'pending') {
      return next(createError('Pesanan ini sudah direspons sebelumnya', 422));
    }

    if (response === 'accepted') {
      await db.query(
        `UPDATE orders SET driver_response = 'accepted', driver_response_note = ? WHERE id = ?`,
        [note || null, order_id]
      );
      await db.query(
        "UPDATE payments SET payment_status = 'paid', paid_at = NOW() WHERE order_id = ?",
        [order_id]
      );
      await db.query(
        `INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)`,
        [order.user_id, 'Supir Mengkonfirmasi Pesanan ✅',
         `Supir telah menerima pesanan Anda #${order_id}. Bersiaplah untuk keberangkatan!`]
      );
      return sendSuccess(res, null, 'Pesanan berhasil diterima');
    } else {
      await db.query(
        `UPDATE orders SET driver_id = NULL, status = 'pending',
         driver_response = 'rejected', driver_response_note = ? WHERE id = ?`,
        [note || null, order_id]
      );
      const [admins] = await db.query(
        "SELECT id FROM users WHERE role = 'admin' AND is_active = 1 LIMIT 1"
      );
      if (admins.length > 0) {
        await db.query(
          `INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)`,
          [admins[0].id, 'Supir Menolak Pesanan ❌',
           `Supir ${req.user.name} menolak pesanan #${order_id}. Silakan assign supir lain.`]
        );
      }
      await db.query(
        `INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)`,
        [order.user_id, 'Pesanan Sedang Diproses Ulang 🔄',
         `Pesanan Anda #${order_id} sedang dicarikan supir baru. Mohon tunggu.`]
      );
      return sendSuccess(res, null, 'Pesanan berhasil ditolak');
    }
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/orders/driver-active  — supir only
 */
const getDriverActiveOrders = async (req, res, next) => {
  try {
    const [rows] = await db.query(
      `SELECT o.*, p.name AS package_name, p.duration,
              u.name AS customer_name, u.phone AS customer_phone
       FROM orders o
       JOIN packages p ON o.package_id = p.id
       JOIN users    u ON o.user_id    = u.id
       WHERE o.driver_id = ? AND o.driver_response = 'accepted'
         AND o.status IN ('confirmed', 'ongoing')
       ORDER BY o.created_at DESC`,
      [req.user.id]
    );
    return sendSuccess(res, rows);
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/orders/driver-incoming  — supir only
 */
const getIncomingOrders = async (req, res, next) => {
  try {
    const [rows] = await db.query(
      `SELECT o.*, p.name AS package_name, p.duration,
              u.name AS customer_name, u.phone AS customer_phone
       FROM orders o
       JOIN packages p ON o.package_id = p.id
       JOIN users    u ON o.user_id    = u.id
       WHERE o.driver_id = ? AND o.status = 'confirmed'
         AND o.driver_response = 'pending'
       ORDER BY o.created_at DESC`,
      [req.user.id]
    );
    return sendSuccess(res, rows);
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/update-status  — supir & admin
 */
const updateOrderStatus = async (req, res, next) => {
  try {
    const { order_id, status } = req.body;
    const allowed = ['ongoing', 'completed', 'cancelled'];

    if (!allowed.includes(status)) {
      return next(createError(`Status tidak valid. Pilihan: ${allowed.join(', ')}`, 422));
    }

    const [orders] = await db.query(
      'SELECT id, user_id, driver_id, status FROM orders WHERE id = ?', [order_id]
    );
    if (orders.length === 0) return next(createError('Pesanan tidak ditemukan', 404));

    const order = orders[0];
    if (req.user.role === 'supir' && order.driver_id !== req.user.id) {
      return next(createError('Tidak diizinkan update pesanan ini', 403));
    }

    await db.query('UPDATE orders SET status = ? WHERE id = ?', [status, order_id]);

    const statusMsg = {
      ongoing:   '🚙 Supir sedang dalam perjalanan menuju lokasi Anda!',
      completed: '🎉 Perjalanan wisata Anda telah selesai. Terima kasih!',
      cancelled: '❌ Pesanan Anda telah dibatalkan.',
    };

    await db.query(
      `INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)`,
      [order.user_id, 'Update Pesanan', statusMsg[status]]
    );

    return sendSuccess(res, null, `Status pesanan diperbarui menjadi: ${status}`);
  } catch (err) {
    next(err);
  }
};

/**
 * PUT /api/orders/:id/location  — pelanggan
 */
const updateOrderLocation = async (req, res, next) => {
  try {
    const { latitude, longitude } = req.body;
    const { id } = req.params;

    const [orders] = await db.query('SELECT id, user_id FROM orders WHERE id = ?', [id]);
    if (orders.length === 0) return next(createError('Pesanan tidak ditemukan', 404));
    if (orders[0].user_id !== req.user.id) return next(createError('Tidak diizinkan', 403));

    await db.query(
      'UPDATE orders SET latitude = ?, longitude = ? WHERE id = ?',
      [latitude, longitude, id]
    );

    return sendSuccess(res, { latitude, longitude }, 'Lokasi diperbarui');
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/drivers  — admin only
 */
const getDrivers = async (req, res, next) => {
  try {
    const [rows] = await db.query(
      "SELECT id, name, email, phone FROM users WHERE role = 'supir' AND is_active = 1"
    );
    return sendSuccess(res, rows);
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/orders/:id/driver-location  — pelanggan
 * Ambil lokasi supir terkini untuk ditampilkan di peta
 */
const getDriverLocation = async (req, res, next) => {
  try {
    const { id } = req.params;
    const [rows] = await db.query(
      'SELECT driver_lat AS latitude, driver_lng AS longitude FROM orders WHERE id = ?', [id]
    );
    if (rows.length === 0) return next(createError('Pesanan tidak ditemukan', 404));
    const { latitude, longitude } = rows[0];
    if (!latitude || !longitude) {
      return res.json({ success: true, data: null, message: 'Lokasi supir belum tersedia' });
    }
    return sendSuccess(res, { latitude, longitude });
  } catch (err) {
    next(err);
  }
};

/**
 * PUT /api/orders/:id/driver-location  — supir only
 * Supir update lokasi real-time saat perjalanan ongoing
 * Body: { latitude, longitude }
 */
const updateDriverLocation = async (req, res, next) => {
  try {
    const { latitude, longitude } = req.body;
    const { id } = req.params;

    const [orders] = await db.query(
      'SELECT id, driver_id, user_id, status FROM orders WHERE id = ?', [id]
    );
    if (orders.length === 0) return next(createError('Pesanan tidak ditemukan', 404));
    if (orders[0].driver_id !== req.user.id) return next(createError('Tidak diizinkan', 403));

    await db.query(
      'UPDATE orders SET driver_lat = ?, driver_lng = ? WHERE id = ?',
      [latitude, longitude, id]
    );

    return sendSuccess(res, { latitude, longitude }, 'Lokasi driver diperbarui');
  } catch (err) {
    next(err);
  }
};

module.exports = {
  createOrder,
  uploadPaymentProof,
  getDriverLocation,
  updateDriverLocation,
  getOrdersByUser,
  getOrderById,
  assignDriver,
  respondOrder,
  getIncomingOrders,
  getDriverActiveOrders,
  updateOrderStatus,
  updateOrderLocation,
  getDrivers,
};