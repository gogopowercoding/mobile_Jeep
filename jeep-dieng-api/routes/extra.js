// routes/payments.js + routes/notifications.js (digabung dalam 1 file)
const express  = require('express');
const router   = express.Router();
const nRouter  = express.Router();
const { authenticate, authorize } = require('../middleware/auth');

const { getPaymentByOrder, convertCurrency, confirmPayment } = require('../controllers/paymentController');
const {
  getNotifications, markAsRead, markAllAsRead,
  createFeedback, getMyFeedback, updateFeedback, deleteFeedback, getAllFeedback,
} = require('../controllers/notificationController');

// ─── Payment Routes ───────────────────────────────────────────
router.get ('/:order_id',         authenticate,                  getPaymentByOrder);
router.post('/:order_id/confirm', authenticate, authorize('admin'), confirmPayment);
router.get ('/convert/rate',      convertCurrency); // public

// ─── Notification Routes ──────────────────────────────────────
nRouter.get ('/',             authenticate, getNotifications);
nRouter.put ('/read-all',     authenticate, markAllAsRead);
nRouter.put ('/:id/read',     authenticate, markAsRead);

// ─── Feedback Routes ──────────────────────────────────────────
// Urutan penting: route spesifik (/my, /all) HARUS sebelum /:id
nRouter.get   ('/feedback/my',   authenticate, authorize('pelanggan'), getMyFeedback);
nRouter.get   ('/feedback/all',  authenticate, authorize('admin'),     getAllFeedback);
nRouter.post  ('/feedback',      authenticate, authorize('pelanggan'), createFeedback);
nRouter.put   ('/feedback/:id',  authenticate, authorize('pelanggan'), updateFeedback);
nRouter.delete('/feedback/:id',  authenticate,                        deleteFeedback);

// ─── Exports ──────────────────────────────────────────────────
module.exports.paymentRouter      = router;
module.exports.notificationRouter = nRouter;