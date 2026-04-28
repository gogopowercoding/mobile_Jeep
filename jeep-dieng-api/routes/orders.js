// routes/orders.js
const express = require('express');
const router  = express.Router();
const { authenticate, authorize } = require('../middleware/auth');
const {
  createOrder, getOrdersByUser, getOrderById,
  assignDriver, respondOrder, getIncomingOrders, getDriverActiveOrders,
  updateOrderStatus, updateOrderLocation, getDrivers,
} = require('../controllers/orderController');

router.post('/',                    authenticate, authorize('pelanggan'),       createOrder);
router.get ('/user/:user_id',       authenticate,                               getOrdersByUser);
router.get ('/drivers',             authenticate, authorize('admin'),            getDrivers);
router.get ('/driver-incoming',     authenticate, authorize('supir'),            getIncomingOrders);
router.get ('/driver-active',       authenticate, authorize('supir'),            getDriverActiveOrders);
router.get ('/:id',                 authenticate,                               getOrderById);
router.post('/assign-driver',       authenticate, authorize('admin'),            assignDriver);
router.post('/respond',             authenticate, authorize('supir'),            respondOrder);
router.post('/update-status',       authenticate, authorize('admin', 'supir'),   updateOrderStatus);
router.put ('/:id/location',        authenticate, authorize('pelanggan'),        updateOrderLocation);

module.exports = router;