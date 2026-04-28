const db = require('../config/database');
const { sendSuccess, createError } = require('../middleware/errorHandler');

// GET schedules by package
const getSchedulesByPackage = async (req, res, next) => {
  try {
    const packageId = req.params.id;

    const [rows] = await db.query(
      `SELECT * FROM package_schedules 
       WHERE package_id = ?
       ORDER BY day_number ASC, start_time ASC`,
      [packageId]
    );

    return sendSuccess(res, rows);
  } catch (err) {
    next(err);
  }
};

// CREATE schedule
const createSchedule = async (req, res, next) => {
  try {
    const packageId = req.params.id;
    const {
      day_number,
      start_time,
      end_time,
      activity,
      is_optional,
      sort_order
    } = req.body;

    const [result] = await db.query(
      `INSERT INTO package_schedules 
      (package_id, day_number, start_time, end_time, activity, is_optional, sort_order)
      VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        packageId,
        day_number,
        start_time,
        end_time || null,
        activity,
        is_optional || 0,
        sort_order || 0
      ]
    );

    return sendSuccess(res, { id: result.insertId }, 'Schedule berhasil ditambahkan', 201);
  } catch (err) {
    next(err);
  }
};

// UPDATE schedule
const updateSchedule = async (req, res, next) => {
  try {
    const {
      day_number,
      start_time,
      end_time,
      activity,
      is_optional,
      sort_order
    } = req.body;

    const [result] = await db.query(
      `UPDATE package_schedules SET
       day_number=?, start_time=?, end_time=?, activity=?, is_optional=?, sort_order=?
       WHERE id=?`,
      [
        day_number,
        start_time,
        end_time || null,
        activity,
        is_optional,
        sort_order,
        req.params.id
      ]
    );

    if (result.affectedRows === 0) {
      return next(createError('Schedule tidak ditemukan', 404));
    }

    return sendSuccess(res, null, 'Schedule berhasil diperbarui');
  } catch (err) {
    next(err);
  }
};

// DELETE schedule
const deleteSchedule = async (req, res, next) => {
  try {
    const [result] = await db.query(
      `DELETE FROM package_schedules WHERE id=?`,
      [req.params.id]
    );

    if (result.affectedRows === 0) {
      return next(createError('Schedule tidak ditemukan', 404));
    }

    return sendSuccess(res, null, 'Schedule berhasil dihapus');
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getSchedulesByPackage,
  createSchedule,
  updateSchedule,
  deleteSchedule
};