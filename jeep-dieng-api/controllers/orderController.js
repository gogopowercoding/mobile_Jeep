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

    // Ambil harga paket
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

    // Buat record payment (pending)
    await db.query(
      `INSERT INTO payments (order_id, amount, currency, payment_status)
       VALUES (?, ?, 'IDR', 'pending')`,
      [orderId, pkg.price]
    );

    // Notifikasi ke pelanggan
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
 * Pelanggan melihat pesanan miliknya sendiri
 * Admin bisa lihat semua dengan GET /api/orders/user/all
 */
const getOrdersByUser = async (req, res, next) => {
  try {
    const { user_id } = req.params;
    const { status } = req.query;

    // Pelanggan hanya boleh lihat miliknya
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
 * Detail satu pesanan
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

    // Pelanggan hanya boleh lihat miliknya
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
 * POST /api/assign-driver   — admin only
 * Body: { order_id, driver_id }
 */
const assignDriver = async (req, res, next) => {
  try {
    const { order_id, driver_id } = req.body;

    // Validasi driver ada & rolnya 'supir'
    const [drivers] = await db.query(
      "SELECT id, name FROM users WHERE id = ? AND role = 'supir' AND is_active = 1",
      [driver_id]
    );
    if (drivers.length === 0) return next(createError('Supir tidak ditemukan atau tidak aktif', 404));

    // Validasi order ada
    const [orders] = await db.query('SELECT id, user_id, status FROM orders WHERE id = ?', [order_id]);
    if (orders.length === 0) return next(createError('Pesanan tidak ditemukan', 404));

    const order = orders[0];

    // Set driver_response ke 'pending' → supir belum ACC
    await db.query(
      "UPDATE orders SET driver_id = ?, status = 'confirmed', driver_response = 'pending' WHERE id = ?",
      [driver_id, order_id]
    );

    // Notifikasi ke supir — minta konfirmasi
    await db.query(
      `INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)`,
      [driver_id, 'Pesanan Baru Menunggu Konfirmasi 🚙',
       `Anda mendapat pesanan baru #${order_id}. Buka aplikasi untuk ACC atau tolak.`]
    );

    // Notifikasi ke pelanggan — masih menunggu supir ACC
    await db.query(
      `INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)`,
      [order.user_id, 'Pesanan Diproses ⏳',
       `Pesanan Anda sedang menunggu konfirmasi dari supir.`]
    );

    return sendSuccess(res, null, 'Supir berhasil di-assign, menunggu konfirmasi supir');
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/orders/respond   — supir only
 * Supir ACC atau TOLAK pesanan yang di-assign admin
 * Body: { order_id, response: 'accepted' | 'rejected', note? }
 */
const respondOrder = async (req, res, next) => {
  try {
    const { order_id, response, note } = req.body;

    if (!['accepted', 'rejected'].includes(response)) {
      return next(createError("Response harus 'accepted' atau 'rejected'", 422));
    }

    // Ambil data order
    const [orders] = await db.query(
      `SELECT o.*, u.name AS customer_name
       FROM orders o
       JOIN users u ON o.user_id = u.id
       WHERE o.id = ?`,
      [order_id]
    );
    if (orders.length === 0) return next(createError('Pesanan tidak ditemukan', 404));

    const order = orders[0];

    // Pastikan supir ini yang di-assign
    if (order.driver_id !== req.user.id) {
      return next(createError('Pesanan ini bukan milik Anda', 403));
    }

    // Pastikan status masih confirmed & driver_response masih pending
    if (order.status !== 'confirmed' || order.driver_response !== 'pending') {
      return next(createError('Pesanan ini sudah direspons sebelumnya', 422));
    }

    if (response === 'accepted') {
      // Supir ACC → update driver_response, konfirmasi pembayaran
      await db.query(
        `UPDATE orders SET driver_response = 'accepted', driver_response_note = ? WHERE id = ?`,
        [note || null, order_id]
      );

      // Update payment ke paid
      await db.query(
        "UPDATE payments SET payment_status = 'paid', paid_at = NOW() WHERE order_id = ?",
        [order_id]
      );

      // Notifikasi pelanggan — supir sudah ACC
      await db.query(
        `INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)`,
        [order.user_id, 'Supir Mengkonfirmasi Pesanan ✅',
         `Supir telah menerima pesanan Anda #${order_id}. Bersiaplah untuk keberangkatan!`]
      );

      return sendSuccess(res, null, 'Pesanan berhasil diterima');

    } else {
      // Supir TOLAK → kembalikan ke pending, lepas driver_id
      await db.query(
        `UPDATE orders
         SET driver_id = NULL, status = 'pending',
             driver_response = 'rejected', driver_response_note = ?
         WHERE id = ?`,
        [note || null, order_id]
      );

      // Notifikasi ke admin
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

      // Notifikasi ke pelanggan
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
 * GET /api/orders/driver-active   — supir only
 * Pesanan yang sudah di-ACC supir & sedang aktif (confirmed/ongoing)
 */
const getDriverActiveOrders = async (req, res, next) => {
  try {
    const [rows] = await db.query(
      `SELECT
         o.*,
         p.name  AS package_name,
         p.duration,
         u.name  AS customer_name,
         u.phone AS customer_phone
       FROM orders o
       JOIN packages p ON o.package_id = p.id
       JOIN users    u ON o.user_id    = u.id
       WHERE o.driver_id = ?
         AND o.driver_response = 'accepted'
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
 * GET /api/orders/driver-incoming   — supir only
 * Pesanan yang di-assign ke supir ini & belum di-ACC
 */
const getIncomingOrders = async (req, res, next) => {
  try {
    const [rows] = await db.query(
      `SELECT
         o.*,
         p.name  AS package_name,
         p.duration,
         u.name  AS customer_name,
         u.phone AS customer_phone
       FROM orders o
       JOIN packages p ON o.package_id = p.id
       JOIN users    u ON o.user_id    = u.id
       WHERE o.driver_id = ?
         AND o.status = 'confirmed'
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
 * POST /api/update-status   — supir & admin
 * Body: { order_id, status }
 * Status valid: 'ongoing' | 'completed' | 'cancelled'
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

    // Supir hanya bisa update pesanan yang di-assign ke dia
    if (req.user.role === 'supir' && order.driver_id !== req.user.id) {
      return next(createError('Tidak diizinkan update pesanan ini', 403));
    }

    await db.query('UPDATE orders SET status = ? WHERE id = ?', [status, order_id]);

    // Notifikasi ke pelanggan
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
 * PUT /api/orders/:id/location   — pelanggan update lokasi real-time
 * Body: { latitude, longitude }
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
 * GET /api/drivers   — admin only
 * Daftar semua supir aktif
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

module.exports = {
  createOrder,
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