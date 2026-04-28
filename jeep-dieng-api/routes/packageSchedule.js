const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../middleware/auth');

const {
  getSchedulesByPackage,
  createSchedule,
  updateSchedule,
  deleteSchedule
} = require('../controllers/packageScheduleController');

// 🔹 Ambil semua schedule dari 1 package
router.get('/packages/:id/schedules', getSchedulesByPackage);

// 🔹 Tambah schedule ke package tertentu
router.post('/packages/:id/schedules', authenticate, authorize('admin'), createSchedule);

// 🔹 Update & delete tetap pakai id schedule
router.put('/schedules/:id', authenticate, authorize('admin'), updateSchedule);
router.delete('/schedules/:id', authenticate, authorize('admin'), deleteSchedule);

module.exports = router;