// routes/payments.js
const express = require('express');
const router  = express.Router();
const { authenticate, authorize } = require('../middleware/auth');
const { getPaymentByOrder, convertCurrency, confirmPayment } = require('../controllers/paymentController');

router.get ('/:order_id',          authenticate, getPaymentByOrder);
router.post('/:order_id/confirm',  authenticate, authorize('admin'), confirmPayment);
router.get ('/convert/rate',       convertCurrency); // public - no auth needed

module.exports = router;

// ─────────────────────────────────────────────────────────────

// routes/notifications.js
const nRouter = require('express').Router();
const { authenticate: nAuth } = require('../middleware/auth');
const {
  getNotifications, markAsRead, markAllAsRead,
  createFeedback, getAllFeedback,
} = require('../controllers/notificationController');

// Notifications
nRouter.get ('/',              nAuth, getNotifications);
nRouter.put ('/read-all',      nAuth, markAllAsRead);
nRouter.put ('/:id/read',      nAuth, markAsRead);

// Feedback
nRouter.post('/feedback',      nAuth, createFeedback);
nRouter.get ('/feedback/all',  nAuth, require('../middleware/auth').authorize('admin'), getAllFeedback);

// Export keduanya
module.exports.paymentRouter      = router;
module.exports.notificationRouter = nRouter;
