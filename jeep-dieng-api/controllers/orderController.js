const db = require('../config/database');
const { createError, sendSuccess } = require('../middleware/errorHandler');

/**
 * POST /api/orders
 * Pelanggan membuat pesanan baru
 * Body: { package_id, booking_date, latitude, longitude, notes? }
 */
const createOrder = async (req, res, next) => {
  try {
    const { package_id, booking_date, latitude, longitude, notes } = req.body;
    const userId = req.user.id;

    const [pkgs] = await db.query(
      'SELECT id, name, price FROM packages WHERE id = ? AND is_active = 1',
      [package_id]
    );
    if (pkgs.length === 0) return next(createError('Paket tidak ditemukan', 404));

    const pkg = pkgs[0];

    const [result] = await db.query(
      `INSERT INTO orders
         (user_id, package_id, booking_date, total_price, status, latitude, longitude, notes)
       VALUES (?, ?, ?, ?, 'pending', ?, ?, ?)`,
      [userId, package_id, booking_date, pkg.price, latitude || null, longitude || null, notes || null]
    );

    const orderId = result.insertId;

    await db.query(
      `INSERT INTO payments (order_id, amount, currency, payment_status)
       VALUES (?, ?, 'IDR', 'pending')`,
      [orderId, pkg.price]
    );

    await db.query(
      `INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)`,
      [userId, 'Pesanan Diterima 🚙', `Pesanan paket "${pkg.name}" Anda telah kami terima dan sedang diproses admin.`]
    );

    const [order] = await db.query(
      `SELECT o.*, p.name AS package_name, p.price AS package_price
       FROM orders o JOIN packages p ON o.package_id = p.id
       WHERE o.id = ?`,
      [orderId]
    );

    return sendSuccess(res, order[0], 'Pesanan berhasil dibuat', 201);
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
         py.payment_method
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
 * POST /api/assign-driver — admin only
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

    const order = orders[0];

    await db.query(
      "UPDATE orders SET driver_id = ?, status = 'confirmed' WHERE id = ?",
      [driver_id, order_id]
    );

    await db.query(
      "UPDATE payments SET payment_status = 'paid', paid_at = NOW() WHERE order_id = ?",
      [order_id]
    );

    await db.query(
      `INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)`,
      [order.user_id, 'Pesanan Dikonfirmasi ✅', `Pesanan Anda telah dikonfirmasi. Supir Anda: ${drivers[0].name}`]
    );

    await db.query(
      `INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)`,
      [driver_id, 'Pesanan Baru 🚙', `Anda mendapat pesanan baru #${order_id}. Cek detail di aplikasi.`]
    );

    return sendSuccess(res, null, 'Supir berhasil di-assign');
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/update-status — supir & admin
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
 * PUT /api/orders/:id/location — pelanggan update lokasi real-time
 */
const updateOrderLocation = async (req, res, next) => {
  try {
    const { latitude, longitude } = req.body;
    const { id } = req.params;

    const [orders] = await db.query(
      'SELECT id, user_id FROM orders WHERE id = ?', [id]
    );
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
 * GET /api/drivers — admin only
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

// ─── ENDPOINT BARU ────────────────────────────────────────────

/**
 * POST /api/orders/upload-payment
 * Pelanggan upload bukti pembayaran (multipart/form-data)
 * Field: order_id (body), payment_proof (file)
 */
const uploadPaymentProof = async (req, res, next) => {
  try {
    const { order_id } = req.body;

    if (!order_id) return next(createError('order_id wajib diisi', 422));
    if (!req.file)  return next(createError('File bukti bayar wajib diupload', 422));

    // Validasi order milik pelanggan ini
    const [orders] = await db.query(
      'SELECT id, user_id, status FROM orders WHERE id = ?',
      [order_id]
    );
    if (orders.length === 0) return next(createError('Pesanan tidak ditemukan', 404));
    if (orders[0].user_id !== req.user.id) return next(createError('Tidak diizinkan', 403));

    const filename = req.file.filename;

    // Simpan nama file ke tabel payments
    await db.query(
      `UPDATE payments
       SET payment_proof = ?, payment_status = 'waiting_confirmation'
       WHERE order_id = ?`,
      [filename, order_id]
    );

    // Notifikasi ke admin (user_id = 1, sesuaikan jika perlu)
    const [admins] = await db.query(
      "SELECT id FROM users WHERE role = 'admin' AND is_active = 1 LIMIT 1"
    );
    if (admins.length > 0) {
      await db.query(
        `INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)`,
        [admins[0].id, 'Bukti Bayar Masuk 💳',
          `Pelanggan telah upload bukti bayar untuk pesanan #${order_id}. Silakan konfirmasi.`]
      );
    }

    return sendSuccess(res, { filename }, 'Bukti pembayaran berhasil diupload');
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/orders/:id/driver-location
 * Return lat/lng supir yang di-assign ke pesanan ini
 */
const getDriverLocation = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Validasi akses: pelanggan hanya boleh lihat pesanannya sendiri
    const [orders] = await db.query(
      `SELECT o.id, o.user_id, o.driver_id, o.status,
              u.latitude AS driver_lat,
              u.longitude AS driver_lng,
              u.name AS driver_name
       FROM orders o
       LEFT JOIN users u ON o.driver_id = u.id
       WHERE o.id = ?`,
      [id]
    );

    if (orders.length === 0) return next(createError('Pesanan tidak ditemukan', 404));

    const order = orders[0];

    if (req.user.role === 'pelanggan' && order.user_id !== req.user.id) {
      return next(createError('Tidak diizinkan', 403));
    }

    if (!order.driver_id) {
      return next(createError('Supir belum di-assign untuk pesanan ini', 404));
    }

    if (order.driver_lat == null || order.driver_lng == null) {
      return next(createError('Lokasi supir belum tersedia', 404));
    }

    return sendSuccess(res, {
      driver_id:   order.driver_id,
      driver_name: order.driver_name,
      latitude:    parseFloat(order.driver_lat),
      longitude:   parseFloat(order.driver_lng),
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  createOrder,
  getOrdersByUser,
  getOrderById,
  assignDriver,
  updateOrderStatus,
  updateOrderLocation,
  getDrivers,
  uploadPaymentProof,
  getDriverLocation,
};