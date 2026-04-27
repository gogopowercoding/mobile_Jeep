// routes/orders.js
const express = require('express');
const router  = express.Router();
const multer  = require('multer');
const path    = require('path');
const { authenticate, authorize } = require('../middleware/auth');
const {
  createOrder, getOrdersByUser, getOrderById,
  assignDriver, updateOrderStatus, updateOrderLocation,
  getDrivers, uploadPaymentProof, getDriverLocation,
} = require('../controllers/orderController');

// ─── Multer config untuk upload bukti bayar ──────────────────
const paymentStorage = multer.diskStorage({
  destination: (req, file, cb) =>
    cb(null, process.env.UPLOAD_PATH || './uploads'),
  filename: (req, file, cb) => {
    const ext  = path.extname(file.originalname);
    const name = `payment_${Date.now()}${ext}`;
    cb(null, name);
  },
});
const uploadPayment = multer({
  storage: paymentStorage,
  limits: { fileSize: Number(process.env.MAX_FILE_SIZE) || 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowed = /jpeg|jpg|png|pdf/;
    cb(null, allowed.test(path.extname(file.originalname).toLowerCase()));
  },
});

// ─── Routes ──────────────────────────────────────────────────
router.post('/',                authenticate, authorize('pelanggan'),        createOrder);
router.get ('/user/:user_id',   authenticate,                                getOrdersByUser);
router.get ('/drivers',         authenticate, authorize('admin'),            getDrivers);
router.get ('/:id',             authenticate,                                getOrderById);
router.post('/assign-driver',   authenticate, authorize('admin'),            assignDriver);
router.post('/update-status',   authenticate, authorize('admin', 'supir'),   updateOrderStatus);
router.put ('/:id/location',    authenticate, authorize('pelanggan'),        updateOrderLocation);

// ─── Endpoint baru ───────────────────────────────────────────
// POST /api/orders/upload-payment  — pelanggan upload bukti bayar
router.post(
  '/upload-payment',
  authenticate,
  authorize('pelanggan'),
  uploadPayment.single('payment_proof'),
  uploadPaymentProof,
);

// GET /api/orders/:id/driver-location  — return lat/lng supir
router.get(
  '/:id/driver-location',
  authenticate,
  getDriverLocation,
);

module.exports = router;