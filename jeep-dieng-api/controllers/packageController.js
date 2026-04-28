const db = require('../config/database');
const { createError, sendSuccess } = require('../middleware/errorHandler');

/**
 * GET /api/packages
 * Public. Mendukung query: ?search=dieng&min_price=100000&max_price=500000
 */
const getAllPackages = async (req, res, next) => {
  try {
    const { search, min_price, max_price } = req.query;
    let query  = 'SELECT * FROM packages WHERE is_active = 1';
    const params = [];

    if (search) {
      query += ' AND (name LIKE ? OR description LIKE ?)';
      params.push(`%${search}%`, `%${search}%`);
    }
    if (min_price) { query += ' AND price >= ?'; params.push(Number(min_price)); }
    if (max_price) { query += ' AND price <= ?'; params.push(Number(max_price)); }
    query += ' ORDER BY created_at DESC';

    const [rows] = await db.query(query, params);
    return sendSuccess(res, rows);
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/packages/:id
 */
const getPackageById = async (req, res, next) => {
  try {
    // 🔹 Ambil data package
    const [rows] = await db.query(
      'SELECT * FROM packages WHERE id = ? AND is_active = 1',
      [req.params.id]
    );

    if (rows.length === 0) {
      return next(createError('Paket tidak ditemukan', 404));
    }

    const packageData = rows[0];

    // 🔹 Ambil schedule berdasarkan package
    const [schedules] = await db.query(
      `SELECT id, day_number, start_time, end_time, activity, is_optional, sort_order
       FROM package_schedules
       WHERE package_id = ?
       ORDER BY day_number ASC, start_time ASC`,
      [req.params.id]
    );

    // 🔹 Gabungkan
    return sendSuccess(res, {
      ...packageData,
      schedules
    });

  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/packages   — admin only
 * Body: { name, description, price, duration, image? }
 */
const createPackage = async (req, res, next) => {
  try {
    const { name, description, price, duration } = req.body;
    const image = req.file ? req.file.filename : null;

    const [result] = await db.query(
      `INSERT INTO packages (name, description, price, duration, image)
       VALUES (?, ?, ?, ?, ?)`,
      [name, description || null, price, duration, image]
    );
    const [pkg] = await db.query('SELECT * FROM packages WHERE id = ?', [result.insertId]);
    return sendSuccess(res, pkg[0], 'Paket berhasil dibuat', 201);
  } catch (err) {
    next(err);
  }
};

/**
 * PUT /api/packages/:id   — admin only
 */
const updatePackage = async (req, res, next) => {
  try {
    const { name, description, price, duration } = req.body;
    const image = req.file ? req.file.filename : undefined;

    const fields = ['name = ?', 'description = ?', 'price = ?', 'duration = ?'];
    const values = [name, description || null, price, duration];

    if (image !== undefined) { fields.push('image = ?'); values.push(image); }
    values.push(req.params.id);

    const [result] = await db.query(
      `UPDATE packages SET ${fields.join(', ')} WHERE id = ?`, values
    );
    if (result.affectedRows === 0) return next(createError('Paket tidak ditemukan', 404));
    return sendSuccess(res, null, 'Paket berhasil diperbarui');
  } catch (err) {
    next(err);
  }
};

/**
 * DELETE /api/packages/:id   — admin only (soft delete)
 */
const deletePackage = async (req, res, next) => {
  try {
    const [result] = await db.query(
      'UPDATE packages SET is_active = 0 WHERE id = ?', [req.params.id]
    );
    if (result.affectedRows === 0) return next(createError('Paket tidak ditemukan', 404));
    return sendSuccess(res, null, 'Paket berhasil dihapus');
  } catch (err) {
    next(err);
  }
};

module.exports = { getAllPackages, getPackageById, createPackage, updatePackage, deletePackage };
