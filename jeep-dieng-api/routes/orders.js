// routes/orders.js
const express    = require('express');
const router     = express.Router();
const multer     = require('multer');
const path       = require('path');
const { authenticate } = require('../middleware/auth');
const {
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
} = require('../controllers/orderController');

// Multer config — simpan di uploads/payments/
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir = 'uploads/payments';
    require('fs').mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `payment_${Date.now()}${ext}`);
  },
});
const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  fileFilter: (req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png', 'image/jpg'];
    cb(null, allowed.includes(file.mimetype));
  },
});

// ── Routes spesifik HARUS di atas /:id agar tidak konflik ──
router.post('/',                        authenticate, createOrder);
router.post('/upload-payment',          authenticate, upload.single('payment_proof'), uploadPaymentProof);
router.post('/assign-driver',           authenticate, assignDriver);
router.post('/respond',                 authenticate, respondOrder);
router.post('/update-status',           authenticate, updateOrderStatus);
router.get('/drivers',                  authenticate, getDrivers);
router.get('/user/:user_id',            authenticate, getOrdersByUser);
router.get('/driver-active',            authenticate, getDriverActiveOrders);
router.get('/driver-incoming',          authenticate, getIncomingOrders);

// ── Routes dengan parameter :id — HARUS paling bawah ───────
router.get('/:id',                      authenticate, getOrderById);
router.put('/:id/location',             authenticate, updateOrderLocation);
router.get('/:id/driver-location',      authenticate, getDriverLocation);
router.put('/:id/driver-location',      authenticate, updateDriverLocation);

module.exports = router;