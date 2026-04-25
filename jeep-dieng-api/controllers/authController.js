const bcrypt = require('bcryptjs');
const jwt    = require('jsonwebtoken');
const { validationResult } = require('express-validator');
const db     = require('../config/database');
const { createError, sendSuccess } = require('../middleware/errorHandler');

/**
 * POST /api/register
 * Body: { name, email, password, phone? }
 * Role default: pelanggan
 */
const register = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(422).json({ success: false, errors: errors.array() });
    }

    const { name, email, password, phone } = req.body;

    // Cek email duplikat
    const [existing] = await db.query(
      'SELECT id FROM users WHERE email = ?', [email]
    );
    if (existing.length > 0) {
      return next(createError('Email sudah terdaftar', 409));
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    const [result] = await db.query(
      `INSERT INTO users (name, email, password, phone, role)
       VALUES (?, ?, ?, ?, 'pelanggan')`,
      [name, email, hashedPassword, phone || null]
    );

    const userId = result.insertId;

    // Generate token
    const token = jwt.sign(
      { id: userId, name, email, role: 'pelanggan' },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    // Kirim notifikasi selamat datang
    await db.query(
      `INSERT INTO notifications (user_id, title, message)
       VALUES (?, 'Selamat Datang! 🎉', ?)`,
      [userId, `Halo ${name}, akun Anda berhasil dibuat. Selamat menjelajahi wisata Dieng!`]
    );

    return sendSuccess(res, {
      token,
      user: { id: userId, name, email, role: 'pelanggan' },
    }, 'Registrasi berhasil', 201);

  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/login
 * Body: { email, password }
 * Returns: { token, user }
 */
const login = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(422).json({ success: false, errors: errors.array() });
    }

    const { email, password } = req.body;

    const [rows] = await db.query(
      'SELECT id, name, email, password, role, is_active FROM users WHERE email = ?',
      [email]
    );

    if (rows.length === 0) {
      return next(createError('Email atau password salah', 401));
    }

    const user = rows[0];

    if (!user.is_active) {
      return next(createError('Akun Anda dinonaktifkan. Hubungi admin.', 403));
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return next(createError('Email atau password salah', 401));
    }

    const token = jwt.sign(
      { id: user.id, name: user.name, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    return sendSuccess(res, {
      token,
      user: { id: user.id, name: user.name, email: user.email, role: user.role },
    }, 'Login berhasil');

  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/profile
 * Mengembalikan profil user yang sedang login
 */
const getProfile = async (req, res, next) => {
  try {
    const [rows] = await db.query(
      'SELECT id, name, email, phone, role, avatar, created_at FROM users WHERE id = ?',
      [req.user.id]
    );
    if (rows.length === 0) return next(createError('User tidak ditemukan', 404));
    return sendSuccess(res, rows[0]);
  } catch (err) {
    next(err);
  }
};

/**
 * PUT /api/profile
 * Update profil lengkap: name, phone, avatar, password
 * Semua role bisa akses (pelanggan, admin, supir)
 * Body (form-data):
 *   name, phone, old_password?, new_password?, avatar? (file)
 */
const updateProfile = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { name, phone, old_password, new_password } = req.body;
    const avatar = req.file ? req.file.filename : undefined;

    // Ambil data user saat ini
    const [rows] = await db.query(
      'SELECT id, name, phone, password, avatar FROM users WHERE id = ?',
      [userId]
    );
    if (rows.length === 0) return next(createError('User tidak ditemukan', 404));
    const user = rows[0];

    // Validasi: name wajib ada
    if (!name || name.trim() === '') {
      return next(createError('Nama tidak boleh kosong', 422));
    }

    // Ganti password jika diminta
    let hashedPassword = user.password; // default tetap password lama
    if (new_password) {
      if (!old_password) {
        return next(createError('Password lama wajib diisi untuk mengganti password', 422));
      }
      if (new_password.length < 6) {
        return next(createError('Password baru minimal 6 karakter', 422));
      }

      const isOldPasswordValid = await bcrypt.compare(old_password, user.password);
      if (!isOldPasswordValid) {
        return next(createError('Password lama tidak sesuai', 401));
      }

      hashedPassword = await bcrypt.hash(new_password, 10);
    }

    // Susun field yang diupdate
    const fields = ['name = ?', 'phone = ?', 'password = ?'];
    const values = [name.trim(), phone || null, hashedPassword];

    if (avatar !== undefined) {
      fields.push('avatar = ?');
      values.push(avatar);
    }

    values.push(userId);

    await db.query(
      `UPDATE users SET ${fields.join(', ')} WHERE id = ?`,
      values
    );

    // Ambil data terbaru untuk response
    const [updated] = await db.query(
      'SELECT id, name, email, phone, role, avatar, created_at FROM users WHERE id = ?',
      [userId]
    );

    return sendSuccess(res, updated[0], 'Profil berhasil diperbarui');
  } catch (err) {
    next(err);
  }
};

module.exports = { register, login, getProfile, updateProfile };